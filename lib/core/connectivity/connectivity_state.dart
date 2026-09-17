import 'package:flutter/foundation.dart';

/// Source-of-truth tier for the current online verdict. Used to decide
/// what wording the banner should show and whether to hide entirely.
enum ConnectivityVerdict {
  /// Cubit just started; no signal yet. Banner stays hidden until the
  /// boot grace period expires.
  unknown,

  /// Both connectivity_plus and the probe agree we're online.
  online,

  /// connectivity_plus reports no link OR probe fails repeatedly while
  /// connectivity_plus reports online (captive portal / blocked DNS).
  offline,

  /// connectivity_plus says online but probe URL itself is sustained
  /// down (≥ [ConnectivityConfig.maxProbeFailures]). We can't tell —
  /// trust connectivity_plus and stop screaming "offline".
  probeUntrusted,
}

/// Why we landed on the current verdict. Surfaced in debug, used for
/// logs / metrics.
enum ConnectivitySource {
  unknown,
  connectivityOnly,
  probeAuthoritative,
  probeFallback,
  vpn,
}

@immutable
class ConnectivityState {
  const ConnectivityState({
    this.verdict = ConnectivityVerdict.unknown,
    this.source = ConnectivitySource.unknown,
    this.vpnDetected = false,
    this.probeFailures = 0,
    this.queuedActions = 0,
    this.lastChange,
    this.justRecovered = false,
  });

  final ConnectivityVerdict verdict;
  final ConnectivitySource source;
  final bool vpnDetected;
  final int probeFailures;

  /// How many actions are sitting in the offline replay queue. Used by
  /// the banner to surface "(N) queued — will retry when online".
  final int queuedActions;

  /// Wall-clock of last verdict change. Banner uses this to know when
  /// to auto-dismiss the "Back online" success state.
  final DateTime? lastChange;

  /// Set true on the single emit where we transition offline → online,
  /// then cleared. The banner uses this edge to flash the success
  /// state for [ConnectivityConfig.backOnlineToastDuration].
  final bool justRecovered;

  /// True if the app should *behave* as connected for the purposes of
  /// network calls. VPN with `block` policy collapses this to false
  /// even if the network is technically up.
  bool get online =>
      verdict == ConnectivityVerdict.online ||
      verdict == ConnectivityVerdict.probeUntrusted;

  bool get offline => verdict == ConnectivityVerdict.offline;

  ConnectivityState copyWith({
    ConnectivityVerdict? verdict,
    ConnectivitySource? source,
    bool? vpnDetected,
    int? probeFailures,
    int? queuedActions,
    DateTime? lastChange,
    bool? justRecovered,
  }) {
    return ConnectivityState(
      verdict: verdict ?? this.verdict,
      source: source ?? this.source,
      vpnDetected: vpnDetected ?? this.vpnDetected,
      probeFailures: probeFailures ?? this.probeFailures,
      queuedActions: queuedActions ?? this.queuedActions,
      lastChange: lastChange ?? this.lastChange,
      justRecovered: justRecovered ?? this.justRecovered,
    );
  }
}
