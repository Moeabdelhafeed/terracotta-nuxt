import 'package:package_info_plus/package_info_plus.dart';

import '../_ttl_cache.dart';
import '../device_services.dart';

/// Typed app info — reads from `package_info_plus`.
class AppInfoData {
  const AppInfoData({
    required this.appName,
    required this.packageName,
    required this.version,
    required this.buildNumber,
    this.buildSignature,
    this.installerStore,
  });

  /// Display name of the app (e.g. "Flutter Base App").
  final String appName;

  /// Package/bundle ID (e.g. "com.example.app").
  final String packageName;

  /// Version string (e.g. "1.2.3").
  final String version;

  /// Build number (e.g. "42").
  final String buildNumber;

  /// Android signing signature (null on other platforms).
  final String? buildSignature;

  /// Source of install (e.g. "com.android.vending", null on iOS/web).
  final String? installerStore;

  /// Full version for display: "1.2.3 (42)".
  String get fullVersion => '$version ($buildNumber)';

  static const AppInfoData unknown = AppInfoData(
    appName: 'unknown',
    packageName: 'unknown',
    version: 'unknown',
    buildNumber: 'unknown',
  );
}

/// Current app metadata (name, version, package) with long TTL cache.
class AppInfoUtils {
  AppInfoUtils._();

  static final TtlCache<AppInfoData> _cache = TtlCache<AppInfoData>(
    () => DeviceServices.policy.infoTtl,
  );

  /// Full app info. Cached for [DevicePolicy.infoTtl].
  static Future<AppInfoData> getInfo({bool forceRefresh = false}) {
    return _cache.get(_fetch, forceRefresh: forceRefresh);
  }

  /// Convenience: just the version string.
  static Future<String> getVersion() async => (await getInfo()).version;

  /// Convenience: just the build number.
  static Future<String> getBuildNumber() async => (await getInfo()).buildNumber;

  /// Convenience: full version "1.2.3 (42)".
  static Future<String> getFullVersion() async => (await getInfo()).fullVersion;

  /// Convenience: package/bundle ID.
  static Future<String> getPackageName() async => (await getInfo()).packageName;

  /// Last known info without triggering a fetch.
  static AppInfoData? get cachedInfo => _cache.peek;

  /// Invalidate the cache (rare — app info rarely changes while app is running).
  static void invalidateCache() => _cache.invalidate();

  static Future<AppInfoData> _fetch() async {
    try {
      final info = await PackageInfo.fromPlatform();
      return AppInfoData(
        appName: info.appName,
        packageName: info.packageName,
        version: info.version,
        buildNumber: info.buildNumber,
        buildSignature: info.buildSignature.isEmpty
            ? null
            : info.buildSignature,
        installerStore: info.installerStore,
      );
    } catch (e, st) {
      deviceWarn('appInfo.fetch', e, st);
      return AppInfoData.unknown;
    }
  }
}
