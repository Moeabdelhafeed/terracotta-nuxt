import 'dart:async';

import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import '../../core/utils/loggers/logger.dart';
import 'remote_config_service.dart';

/// Keeps Remote Config live across the app — emits whenever values
/// change so any snapshot-style consumer (cubit, cached service) can
/// reseed itself.
///
/// Three live signals:
/// - **App resume** — `AppLifecycleListener.onResume` triggers a
///   `fetchAndActivate` whenever the user foregrounds the app.
/// - **RC push (mobile)** — `onConfigUpdated` stream fires whenever
///   the operator publishes a new config from the Firebase console.
/// - **Polling (web)** — periodic `fetchAndActivate` while the page is
///   open. Web SDK doesn't expose `onConfigUpdated`, so we poll.
///
/// Consumers subscribe to [updates] and reseed their state. Lazy
/// getters (`RemoteConfigService.X` read at use site) auto-reflect
/// the new values without any subscription — `activate()` swaps the
/// underlying map atomically.
///
/// Lifecycle: `start()` once on boot (after `RemoteConfigService.init`);
/// `dispose()` on teardown (rarely needed for a singleton).
class RemoteConfigWatcher {
  RemoteConfigWatcher({
    Duration pollInterval = const Duration(seconds: 10),
  }) : _pollInterval = pollInterval;

  final Duration _pollInterval;

  final StreamController<Set<String>> _controller =
      StreamController<Set<String>>.broadcast();

  /// Fires whenever an `activate()` succeeds. Payload = the set of
  /// changed keys when known (mobile push), or empty when unknown
  /// (web poll, app resume, manual refresh).
  Stream<Set<String>> get updates => _controller.stream;

  AppLifecycleListener? _lifecycle;
  StreamSubscription<RemoteConfigUpdate>? _rcSub;
  Timer? _poller;
  bool _started = false;

  void start() {
    if (_started) return;
    _started = true;

    // Web has no Firebase RC pipeline wired in this template — values
    // come from `.env` at compile time. The watcher's resume / poll /
    // push paths all funnel into `RemoteConfigService.refresh()`,
    // which short-circuits on web. Skip the wiring entirely so the
    // log doesn't fill with no-op refresh ticks.
    if (kIsWeb) return;

    // ─── Refresh on app resume ───────────────────────────────
    _lifecycle = AppLifecycleListener(
      onResume: () {
        Logger.m.d('[RC] resume → refresh');
        unawaited(_refreshAndEmit());
      },
    );

    // ─── Live updates ────────────────────────────────────────
    if (kIsWeb) {
      // Unreachable — short-circuit above. Kept for clarity in case
      // a web RC setup is wired later.
      _poller = Timer.periodic(_pollInterval, (_) {
        Logger.m.d('[RC] web poll → refresh');
        unawaited(_refreshAndEmit());
      });
    } else {
      try {
        _rcSub = FirebaseRemoteConfig.instance.onConfigUpdated.listen(
          (update) async {
            Logger.m.d('[RC] pushed: ${update.updatedKeys}');
            try {
              await FirebaseRemoteConfig.instance.activate();
              _emit(update.updatedKeys);
            } catch (e, st) {
              Logger.m.e('[RC] activate failed', error: e, stackTrace: st);
            }
          },
          onError: (Object e, StackTrace st) {
            Logger.m.e('[RC] onConfigUpdated error', error: e, stackTrace: st);
          },
        );
      } catch (e, st) {
        // Older Firebase / unsupported platform — silently degrade
        // (resume + manual refresh still work).
        Logger.m.w(
          '[RC] onConfigUpdated unavailable',
          error: e,
          stackTrace: st,
        );
      }
    }
  }

  /// Force a fetch + activate now, then emit. Use from retry buttons
  /// or anywhere a manual refresh is desired.
  Future<void> refresh() => _refreshAndEmit();

  Future<void> _refreshAndEmit() async {
    final ok = await RemoteConfigService.refresh();
    if (ok) _emit(const {});
  }

  void _emit(Set<String> keys) {
    if (_controller.isClosed) return;
    _controller.add(keys);
  }

  Future<void> dispose() async {
    _lifecycle?.dispose();
    _lifecycle = null;
    await _rcSub?.cancel();
    _rcSub = null;
    _poller?.cancel();
    _poller = null;
    await _controller.close();
    _started = false;
  }
}
