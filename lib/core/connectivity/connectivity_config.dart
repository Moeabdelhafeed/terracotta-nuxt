import 'package:flutter/foundation.dart';

/// How the cubit should treat a detected VPN connection.
enum VpnPolicy {
  /// Treat as connected. No banner. Default.
  allow,

  /// Show a soft banner ("VPN detected, may impact experience"); still
  /// considered online.
  warn,

  /// Show a hard banner ("Disable VPN to continue") and treat as
  /// offline-equivalent for any caller reading [ConnectivityState.online].
  block;

  static VpnPolicy fromString(String? raw) {
    switch ((raw ?? '').trim().toLowerCase()) {
      case 'warn':
        return VpnPolicy.warn;
      case 'block':
        return VpnPolicy.block;
      case 'allow':
      default:
        return VpnPolicy.allow;
    }
  }
}

/// Tunables for the connectivity stack. RC-driven where it makes sense
/// (probe URL / interval / VPN policy); compile-time everywhere else.
@immutable
class ConnectivityConfig {
  const ConnectivityConfig({
    this.probeUrl = 'https://www.gstatic.com/generate_204',
    this.probeTimeout = const Duration(seconds: 5),
    this.probeIntervalForeground = const Duration(seconds: 30),
    this.maxProbeFailures = 3,
    this.probeBackoffStart = const Duration(seconds: 30),
    this.probeBackoffMax = const Duration(minutes: 5),
    this.bootGracePeriod = const Duration(milliseconds: 1500),
    this.backOnlineToastDuration = const Duration(seconds: 2),
    this.vpnPolicy = VpnPolicy.allow,
  });

  /// Endpoint to HEAD on. Anything that returns quickly + tiny bytes.
  /// `gstatic.com/generate_204` is Google's captive portal canary —
  /// returns 204, no body, served from edge. Good default.
  final String probeUrl;

  final Duration probeTimeout;

  /// On web (where `navigator.onLine` lies) and as a periodic
  /// background sanity check on mobile. Skipped when app is hidden.
  final Duration probeIntervalForeground;

  /// Probe failure streak threshold. Below this, probe failure
  /// overrides connectivity_plus and we go offline. Above it, we
  /// distrust the probe (URL itself probably down) and trust
  /// connectivity_plus instead.
  final int maxProbeFailures;

  final Duration probeBackoffStart;
  final Duration probeBackoffMax;

  /// Time after boot before the offline banner is allowed to show.
  /// Avoids a flash during cold-start probing.
  final Duration bootGracePeriod;

  /// How long the "Back online" success banner stays before
  /// auto-dismissing.
  final Duration backOnlineToastDuration;

  final VpnPolicy vpnPolicy;

  ConnectivityConfig copyWith({
    String? probeUrl,
    Duration? probeTimeout,
    Duration? probeIntervalForeground,
    int? maxProbeFailures,
    Duration? probeBackoffStart,
    Duration? probeBackoffMax,
    Duration? bootGracePeriod,
    Duration? backOnlineToastDuration,
    VpnPolicy? vpnPolicy,
  }) {
    return ConnectivityConfig(
      probeUrl: probeUrl ?? this.probeUrl,
      probeTimeout: probeTimeout ?? this.probeTimeout,
      probeIntervalForeground:
          probeIntervalForeground ?? this.probeIntervalForeground,
      maxProbeFailures: maxProbeFailures ?? this.maxProbeFailures,
      probeBackoffStart: probeBackoffStart ?? this.probeBackoffStart,
      probeBackoffMax: probeBackoffMax ?? this.probeBackoffMax,
      bootGracePeriod: bootGracePeriod ?? this.bootGracePeriod,
      backOnlineToastDuration:
          backOnlineToastDuration ?? this.backOnlineToastDuration,
      vpnPolicy: vpnPolicy ?? this.vpnPolicy,
    );
  }
}
