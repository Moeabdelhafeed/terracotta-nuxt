import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';

import '../../../localization/strings/connectivity_strings.dart';
import '../device_services.dart';
import '../network/connectivity_utils.dart';

/// How good the connection is.
enum NetworkQuality {
  /// No connection at all.
  offline,

  /// Connected, but slow enough to feel broken.
  poor,

  /// Usable.
  fair,

  /// Comfortable.
  good,

  /// Fast.
  excellent,

  /// Not measured — the probe is switched off, or it failed.
  unknown;

  /// Localized, for display. It was hard-coded English on the enum.
  String get label => switch (this) {
    NetworkQuality.offline => ConnectivityStrings.qualityOffline,
    NetworkQuality.poor => ConnectivityStrings.qualityPoor,
    NetworkQuality.fair => ConnectivityStrings.qualityFair,
    NetworkQuality.good => ConnectivityStrings.qualityGood,
    NetworkQuality.excellent => ConnectivityStrings.qualityExcellent,
    NetworkQuality.unknown => ConnectivityStrings.qualityUnknown,
  };

  /// Whether there is a usable connection. `unknown` counts as
  /// connected: the probe not running is not evidence of being
  /// offline, and treating it as such blocks an app that works.
  bool get isConnected => this != NetworkQuality.offline;
}

/// Which pipe the device is on.
enum ConnectionType {
  offline,
  wifi,
  ethernet,
  mobile,
  vpn,
  other;

  String get label => switch (this) {
    ConnectionType.offline => ConnectivityStrings.typeOffline,
    ConnectionType.wifi => ConnectivityStrings.typeWifi,
    ConnectionType.ethernet => ConnectivityStrings.typeEthernet,
    ConnectionType.mobile => ConnectivityStrings.typeMobile,
    ConnectionType.vpn => ConnectivityStrings.typeVpn,
    ConnectionType.other => ConnectivityStrings.typeOther,
  };

  /// What to expect before measuring anything: a wire is fast, a
  /// radio is a coin toss.
  NetworkQuality get expectedQuality => switch (this) {
    ConnectionType.offline => NetworkQuality.offline,
    ConnectionType.wifi || ConnectionType.ethernet => NetworkQuality.good,
    ConnectionType.mobile || ConnectionType.vpn => NetworkQuality.fair,
    ConnectionType.other => NetworkQuality.unknown,
  };
}

/// Connection quality, by timing a TCP handshake against a known host.
/// Far cheaper than a speed test, and enough to decide whether to
/// fetch the big image.
///
/// **It reaches a third party**, which is why the host is in
/// [DevicePolicy] rather than in a mutable public static here — three
/// of them, assignable from anywhere, with no way to read back what an
/// app had set. An adopter with a backend should point this at it;
/// `DevicePolicy(pingHost: '')` turns the socket off entirely and
/// answers from the connection type alone.
class NetworkQualityUtils {
  NetworkQualityUtils._();

  /// Measure. Returns [NetworkQuality.offline] with no connectivity,
  /// otherwise times a connection to the configured host.
  static Future<NetworkQuality> measure() async {
    if (!await ConnectivityUtils.hasConnection()) return NetworkQuality.offline;

    final policy = DeviceServices.policy;
    // No host, or a platform with no raw sockets: fall back to what
    // the connection TYPE implies rather than reporting `unknown`,
    // which is what web used to get for every call.
    if (!policy.pingsHost || kIsWeb) {
      return (await getConnectionType()).expectedQuality;
    }

    final stopwatch = Stopwatch()..start();
    try {
      final socket = await Socket.connect(
        policy.pingHost,
        policy.pingPort,
        timeout: policy.pingTimeout,
      );
      stopwatch.stop();
      socket.destroy();
      return classifyLatency(stopwatch.elapsedMilliseconds);
    } catch (e) {
      stopwatch.stop();
      // Connectivity said yes and the handshake said no. That is a
      // captive portal, a firewall or a dying radio — poor, not
      // unknown.
      DeviceServices.capability('latencyProbe').markUnavailable(e);
      return NetworkQuality.poor;
    }
  }

  /// Which pipe, without measuring anything.
  static Future<ConnectionType> getConnectionType() async {
    final status = await ConnectivityUtils.getStatus();
    if (status.isEmpty || status.contains(ConnectivityResult.none)) {
      return ConnectionType.offline;
    }
    if (status.contains(ConnectivityResult.wifi)) return ConnectionType.wifi;
    if (status.contains(ConnectivityResult.ethernet)) {
      return ConnectionType.ethernet;
    }
    if (status.contains(ConnectivityResult.mobile)) {
      return ConnectionType.mobile;
    }
    if (status.contains(ConnectivityResult.vpn)) return ConnectionType.vpn;
    return ConnectionType.other;
  }

  /// The band a round-trip time falls in, per [DevicePolicy].
  @visibleForTesting
  static NetworkQuality classifyLatency(int ms) {
    final policy = DeviceServices.policy;
    if (ms < policy.excellentBelowMs) return NetworkQuality.excellent;
    if (ms < policy.goodBelowMs) return NetworkQuality.good;
    if (ms < policy.fairBelowMs) return NetworkQuality.fair;
    return NetworkQuality.poor;
  }
}
