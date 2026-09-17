import 'package:device_info_plus/device_info_plus.dart';

import '../_ttl_cache.dart';
import '../device_services.dart';
import '../info/platform_utils.dart';

/// Typed device info model — stable across platforms.
class DeviceInfoData {
  const DeviceInfoData({
    required this.model,
    required this.osVersion,
    required this.deviceId,
    this.brand,
    this.manufacturer,
    this.name,
    this.browserName,
    this.userAgent,
  });

  final String model;
  final String osVersion;
  final String deviceId;
  final String? brand;
  final String? manufacturer;
  final String? name;
  final String? browserName;
  final String? userAgent;

  Map<String, dynamic> toJson() => {
    'model': model,
    'osVersion': osVersion,
    'deviceId': deviceId,
    'brand': ?brand,
    'manufacturer': ?manufacturer,
    'name': ?name,
    'browserName': ?browserName,
    'userAgent': ?userAgent,
  };

  static const DeviceInfoData unknown = DeviceInfoData(
    model: 'unknown',
    osVersion: 'unknown',
    deviceId: 'unknown',
  );
}

/// Device info (model, OS, ID, etc.) with long TTL cache.
class DeviceInfoUtils {
  DeviceInfoUtils._();

  static final DeviceInfoPlugin _plugin = DeviceInfoPlugin();
  static final TtlCache<DeviceInfoData> _cache = TtlCache<DeviceInfoData>(
    () => DeviceServices.policy.infoTtl,
  );

  /// Full device info. Cached for [DevicePolicy.infoTtl].
  static Future<DeviceInfoData> getInfo({bool forceRefresh = false}) {
    return _cache.get(_fetch, forceRefresh: forceRefresh);
  }

  /// Unique device identifier.
  static Future<String> getDeviceId({bool forceRefresh = false}) async {
    final info = await getInfo(forceRefresh: forceRefresh);
    return info.deviceId;
  }

  /// Last known info without triggering a fetch.
  static DeviceInfoData? get cachedInfo => _cache.peek;

  /// Invalidate the cache.
  static void invalidateCache() => _cache.invalidate();

  static Future<DeviceInfoData> _fetch() async {
    try {
      if (PlatformUtils.isAndroid) {
        final info = await _plugin.androidInfo;
        return DeviceInfoData(
          model: info.model,
          osVersion: info.version.release,
          deviceId: info.id,
          brand: info.brand,
          manufacturer: info.manufacturer,
        );
      }
      if (PlatformUtils.isIOS) {
        final info = await _plugin.iosInfo;
        return DeviceInfoData(
          model: info.model,
          osVersion: info.systemVersion,
          deviceId: info.identifierForVendor ?? 'unknown',
          name: info.name,
        );
      }
      if (PlatformUtils.isWeb) {
        final info = await _plugin.webBrowserInfo;
        return DeviceInfoData(
          model: info.browserName.name,
          osVersion: info.platform ?? 'unknown',
          deviceId: info.userAgent ?? 'unknown',
          browserName: info.browserName.name,
          userAgent: info.userAgent,
        );
      }
      return DeviceInfoData.unknown;
    } catch (e, st) {
      deviceWarn('deviceInfo.fetch', e, st);
      return DeviceInfoData.unknown;
    }
  }
}
