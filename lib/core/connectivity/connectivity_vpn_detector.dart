import 'dart:io' show NetworkInterface;

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';

import '../utils/loggers/logger.dart';

/// Best-effort VPN detection.
///
/// Two layers:
/// 1. `connectivity_plus` reports `ConnectivityResult.vpn` for some
///    OS-registered VPN profiles (iOS personal VPN, macOS, certain
///    Android configurations).
/// 2. Heuristic on `NetworkInterface.list()` — VPN drivers usually
///    register interfaces named `tun*`, `tap*`, `utun*`, `ppp*`,
///    `ipsec*`, `wg*` (WireGuard). Catches OpenVPN, WireGuard, IPsec,
///    and most consumer VPN apps.
///
/// Neither is bulletproof. DNS-only and routing-table VPNs slip
/// through. For stronger detection, hit your backend with `/me` and
/// compare the source IP against a known VPN IP database (MaxMind,
/// IPInfo, IPQS).
///
/// Web is unsupported — `dart:io` is not available, so we always
/// return false. Add a backend-side check when running on web.
class VpnDetector {
  const VpnDetector();

  Future<bool> isVpnActive(List<ConnectivityResult> types) async {
    if (types.contains(ConnectivityResult.vpn)) return true;
    if (kIsWeb) return false;
    return _hasVpnInterface();
  }

  Future<bool> _hasVpnInterface() async {
    try {
      final ifaces = await NetworkInterface.list(
        includeLoopback: false,
        includeLinkLocal: false,
      );
      for (final iface in ifaces) {
        final name = iface.name.toLowerCase();
        if (_vpnPrefixes.any(name.startsWith)) return true;
      }
      return false;
    } catch (e) {
      Logger.m.d('[Connectivity] VPN iface scan failed: $e');
      return false;
    }
  }

  static const List<String> _vpnPrefixes = [
    'tun',
    'tap',
    'utun',
    'ppp',
    'ipsec',
    'wg',
    'nordlynx',
  ];
}
