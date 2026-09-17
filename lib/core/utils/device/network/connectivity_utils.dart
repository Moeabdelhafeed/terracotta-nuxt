import 'package:connectivity_plus/connectivity_plus.dart';

import '../_ttl_cache.dart';
import '../device_services.dart';

/// One-shot connectivity queries, cached.
///
/// **Relationship to `ConnectivityCubit`** (`lib/core/connectivity/`):
/// the cubit owns the *live* app-level verdict (online / offline / VPN
/// / recovery edges) and is the right pick for anything reactive. This
/// is the *direct-query* layer — a one-shot answer ("is this wifi
/// right now?") with no DI and no subscription, for bootstrap or a
/// stateless diagnostic page.
class ConnectivityUtils {
  ConnectivityUtils._();

  static final Connectivity _connectivity = Connectivity();
  static final TtlCache<List<ConnectivityResult>> _statusCache =
      TtlCache<List<ConnectivityResult>>(
        () => DeviceServices.policy.valueTtl,
      );

  /// Current connectivity types (wifi, mobile, ethernet, vpn, none…).
  ///
  /// **A failed probe is no longer cached as "offline".** The catch
  /// used to sit INSIDE the fetch, so its `[none]` fallback was
  /// written to the cache like a real reading — one flaky platform
  /// call and the app believed it was offline for the next thirty
  /// seconds, with no way to tell that answer from a true one. The
  /// fallback is still `[none]`, but nothing remembers it.
  static Future<List<ConnectivityResult>> getStatus({
    bool forceRefresh = false,
  }) => deviceGuard(
    'connectivity.getStatus',
    () => _statusCache.get(
      _connectivity.checkConnectivity,
      forceRefresh: forceRefresh,
    ),
    fallback: const [ConnectivityResult.none],
  );

  /// Last known status without triggering a fetch.
  static List<ConnectivityResult>? get cachedStatus => _statusCache.peek;

  static void invalidateCache() => _statusCache.invalidate();

  /// True if there is any active connection type.
  static Future<bool> hasConnection({bool forceRefresh = false}) async {
    final status = await getStatus(forceRefresh: forceRefresh);
    return status.isNotEmpty && !status.contains(ConnectivityResult.none);
  }

  static Future<bool> isWifi({bool forceRefresh = false}) async =>
      (await getStatus(
        forceRefresh: forceRefresh,
      )).contains(ConnectivityResult.wifi);

  static Future<bool> isMobile({bool forceRefresh = false}) async =>
      (await getStatus(
        forceRefresh: forceRefresh,
      )).contains(ConnectivityResult.mobile);

  /// Stream of connectivity changes.
  static Stream<List<ConnectivityResult>> get onStatusChanged =>
      _connectivity.onConnectivityChanged;
}
