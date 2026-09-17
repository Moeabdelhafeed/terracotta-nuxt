import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../utils/loggers/logger.dart';
import 'connectivity_config.dart';
import 'connectivity_probe.dart';
import 'connectivity_state.dart';
import 'connectivity_vpn_detector.dart';

/// Owns the entire connectivity story: connectivity_plus stream,
/// HEAD probe, VPN detection, app-resume re-probe, periodic
/// foreground probe (web), and the probe-failure circuit breaker.
///
/// Subscribers (banner, offline queue, error page hint) read
/// [ConnectivityState]. Snapshot fields:
/// - `verdict` — online | offline | probeUntrusted | unknown
/// - `online` (getter) — convenience for "should we make network calls?"
/// - `vpnDetected` — for [VpnPolicy.warn] / [VpnPolicy.block]
/// - `queuedActions` — set by `OfflineActionQueue` to surface a count
class ConnectivityCubit extends Cubit<ConnectivityState> {
  ConnectivityCubit({
    ConnectivityConfig? config,
    Connectivity? connectivity,
    ConnectivityProbe? probe,
    VpnDetector? vpnDetector,
  }) : _config = config ?? const ConnectivityConfig(),
       _connectivity = connectivity ?? Connectivity(),
       _probe = probe ?? ConnectivityProbe(),
       _vpnDetector = vpnDetector ?? const VpnDetector(),
       super(const ConnectivityState());

  ConnectivityConfig _config;
  final Connectivity _connectivity;
  final ConnectivityProbe _probe;
  final VpnDetector _vpnDetector;

  StreamSubscription<List<ConnectivityResult>>? _sub;
  AppLifecycleListener? _lifecycle;
  Timer? _periodicProbe;
  Timer? _backoffTimer;
  Timer? _bootGraceTimer;
  bool _started = false;
  bool _withinBootGrace = true;
  Duration _currentBackoff = Duration.zero;

  /// Debug-only verdict override. When non-null, [_evaluate] short-
  /// circuits and emits this verdict instead of consulting
  /// connectivity_plus / probe / VPN. Lets the debug overlay's
  /// connectivity simulator force any state for testing offline /
  /// captive-portal / VPN-block flows.
  ConnectivityVerdict? _debugVerdictOverride;

  /// Debug-only VPN flag override. `null` = use real detection.
  bool? _debugVpnOverride;

  ConnectivityVerdict? get debugVerdictOverride => _debugVerdictOverride;
  bool? get debugVpnOverride => _debugVpnOverride;
  bool get hasDebugOverride =>
      _debugVerdictOverride != null || _debugVpnOverride != null;

  ConnectivityConfig get config => _config;

  /// Live reconfig — used when Remote Config delivers a new policy /
  /// probe URL mid-session.
  void updateConfig(ConnectivityConfig next) {
    final restartPeriodic =
        next.probeIntervalForeground != _config.probeIntervalForeground;
    _config = next;
    if (restartPeriodic) _restartPeriodicProbe();
    // Re-evaluate immediately — VPN policy may have flipped, and the
    // current verdict may need to change without waiting for the next
    // probe cycle.
    unawaited(_evaluate());
  }

  void start() {
    if (_started) return;
    _started = true;

    _bootGraceTimer = Timer(_config.bootGracePeriod, () {
      _withinBootGrace = false;
      // Re-emit so the banner can stop suppressing offline once the
      // grace window ends.
      emit(state.copyWith());
    });

    _sub = _connectivity.onConnectivityChanged.listen(
      (results) {
        Logger.m.d('[Connectivity] stream: $results');
        unawaited(_evaluate(types: results));
      },
      onError: (Object e, StackTrace st) {
        Logger.m.e('[Connectivity] stream error', error: e, stackTrace: st);
      },
    );

    _lifecycle = AppLifecycleListener(
      onResume: () {
        Logger.m.d('[Connectivity] resume → re-probe');
        unawaited(_evaluate());
      },
    );

    _restartPeriodicProbe();

    // Initial check — don't wait for first connectivity_plus event.
    unawaited(_evaluate());
  }

  void _restartPeriodicProbe() {
    _periodicProbe?.cancel();
    final interval = _config.probeIntervalForeground;
    if (interval <= Duration.zero) return;
    // Probe is a no-op on web (CORS makes external HEAD pings fail —
    // see `ConnectivityProbe.ping`). Skip the timer too so we don't
    // waste cycles re-evaluating the same connectivity_plus signal.
    if (kIsWeb) return;
    // Mobile: light periodic re-check — catches captive portals
    // expiring + wifi-with-no-internet that connectivity_plus misses.
    _periodicProbe = Timer.periodic(interval, (_) {
      unawaited(_evaluate(periodic: true));
    });
  }

  /// Public hook for "Retry" buttons / interceptor failures. Forces a
  /// fresh evaluation right now.
  Future<void> reprobe() => _evaluate();

  /// Called by [OfflineActionQueue] (or any external accountant) to
  /// surface a queue-depth indicator on the banner.
  void setQueuedActions(int count) {
    if (state.queuedActions == count) return;
    emit(state.copyWith(queuedActions: count));
  }

  /// Force a specific verdict for debugging. Pass `null` to clear.
  /// While set, all evaluation paths short-circuit and emit the forced
  /// verdict directly.
  void debugForceVerdict(ConnectivityVerdict? verdict) {
    _debugVerdictOverride = verdict;
    unawaited(_evaluate());
  }

  /// Force VPN detection on/off for debugging. Pass `null` to clear.
  void debugForceVpn(bool? value) {
    _debugVpnOverride = value;
    unawaited(_evaluate());
  }

  /// Clear all debug overrides + re-evaluate from real sources.
  void debugClearOverrides() {
    _debugVerdictOverride = null;
    _debugVpnOverride = null;
    unawaited(_evaluate());
  }

  Future<void> _evaluate({
    List<ConnectivityResult>? types,
    bool periodic = false,
  }) async {
    // Debug override path — skip every real source and emit directly.
    // VPN+block policy still coerces the override down to offline so
    // the dev's "force online" choice doesn't bypass the gate that
    // production code is meant to honor.
    if (_debugVerdictOverride != null) {
      final forced = _debugVerdictOverride!;
      final vpn = _debugVpnOverride ?? state.vpnDetected;
      final coerced =
          (forced == ConnectivityVerdict.online &&
              vpn &&
              _config.vpnPolicy == VpnPolicy.block)
          ? ConnectivityVerdict.offline
          : forced;
      _commit(
        verdict: coerced,
        source: ConnectivitySource.connectivityOnly,
        vpn: vpn,
        probeFailures: 0,
      );
      return;
    }

    final resolvedTypes =
        types ??
        await _connectivity.checkConnectivity().catchError(
          (Object e) {
            Logger.m.d('[Connectivity] checkConnectivity threw: $e');
            return <ConnectivityResult>[ConnectivityResult.none];
          },
        );

    final hasLink =
        !resolvedTypes.contains(ConnectivityResult.none) &&
        resolvedTypes.isNotEmpty;
    // Debug VPN override wins over real detection so the simulator's
    // "force VPN" toggle works in the real evaluation path too — not
    // only when the verdict override is also set.
    final vpn =
        _debugVpnOverride ?? await _vpnDetector.isVpnActive(resolvedTypes);

    if (!hasLink) {
      _commit(
        verdict: ConnectivityVerdict.offline,
        source: ConnectivitySource.connectivityOnly,
        vpn: vpn,
        probeFailures: 0,
      );
      return;
    }

    // Probe to catch captive portals / blocked DNS / wifi-with-no-net.
    final probeOk = await _probe.ping(
      url: _config.probeUrl,
      timeout: _config.probeTimeout,
    );

    if (probeOk) {
      _currentBackoff = Duration.zero;
      _backoffTimer?.cancel();
      _commit(
        verdict: _verdictFor(online: true, vpn: vpn),
        source: vpn
            ? ConnectivitySource.vpn
            : ConnectivitySource.probeAuthoritative,
        vpn: vpn,
        probeFailures: 0,
      );
      return;
    }

    final nextStreak = state.probeFailures + 1;
    if (nextStreak >= _config.maxProbeFailures) {
      // Probe URL itself looks broken — distrust it. Fall back to
      // connectivity_plus's word.
      _scheduleBackoffReprobe();
      _commit(
        verdict: ConnectivityVerdict.probeUntrusted,
        source: ConnectivitySource.probeFallback,
        vpn: vpn,
        probeFailures: nextStreak,
      );
      return;
    }

    _commit(
      verdict: ConnectivityVerdict.offline,
      source: ConnectivitySource.probeAuthoritative,
      vpn: vpn,
      probeFailures: nextStreak,
    );
  }

  ConnectivityVerdict _verdictFor({required bool online, required bool vpn}) {
    if (!online) return ConnectivityVerdict.offline;
    if (vpn && _config.vpnPolicy == VpnPolicy.block) {
      // Block policy: surface as offline so callers gating on
      // [ConnectivityState.online] refuse to make calls.
      return ConnectivityVerdict.offline;
    }
    return ConnectivityVerdict.online;
  }

  void _commit({
    required ConnectivityVerdict verdict,
    required ConnectivitySource source,
    required bool vpn,
    required int probeFailures,
  }) {
    final wasOffline =
        state.verdict == ConnectivityVerdict.offline ||
        state.verdict == ConnectivityVerdict.unknown;
    final isOnlineNow =
        verdict == ConnectivityVerdict.online ||
        verdict == ConnectivityVerdict.probeUntrusted;
    final justRecovered =
        wasOffline &&
        isOnlineNow &&
        state.verdict != ConnectivityVerdict.unknown;

    final next = state.copyWith(
      verdict: verdict,
      source: source,
      vpnDetected: vpn,
      probeFailures: probeFailures,
      lastChange: DateTime.now(),
      justRecovered: justRecovered,
    );
    emit(next);

    if (justRecovered) {
      // Auto-clear the recovery flag so the banner's "Back online"
      // toast self-dismisses.
      Future.delayed(_config.backOnlineToastDuration, () {
        if (isClosed) return;
        if (!state.justRecovered) return;
        emit(state.copyWith(justRecovered: false));
      });
    }
  }

  void _scheduleBackoffReprobe() {
    _backoffTimer?.cancel();
    final next = _currentBackoff == Duration.zero
        ? _config.probeBackoffStart
        : Duration(
            milliseconds: (_currentBackoff.inMilliseconds * 2).clamp(
              0,
              _config.probeBackoffMax.inMilliseconds,
            ),
          );
    _currentBackoff = next;
    _backoffTimer = Timer(next, () => unawaited(_evaluate()));
  }

  /// Banner suppresses itself before the boot grace expires so the
  /// app doesn't flash "offline" during the cold-start probe.
  bool get withinBootGrace => _withinBootGrace;

  @override
  Future<void> close() async {
    await _sub?.cancel();
    _sub = null;
    _lifecycle?.dispose();
    _lifecycle = null;
    _periodicProbe?.cancel();
    _periodicProbe = null;
    _backoffTimer?.cancel();
    _backoffTimer = null;
    _bootGraceTimer?.cancel();
    _bootGraceTimer = null;
    _started = false;
    return super.close();
  }
}
