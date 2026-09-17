import 'package:device_info_plus/device_info_plus.dart';
import 'package:universal_platform/universal_platform.dart';

import '../device_constants.dart';
import '../device_services.dart';

/// How much headroom the device has. Coarse on purpose — the
/// platforms expose very different things, and the only question worth
/// asking across all of them is "should I do less".
enum DeviceResourceState {
  /// Plenty of room — the ordinary case.
  normal,

  /// A low-RAM device. Skip the expensive thing.
  low,

  /// The platform does not say.
  unknown,
}

/// Platform detection and platform-specific capability checks.
class PlatformUtils {
  PlatformUtils._();

  static final DeviceInfoPlugin _deviceInfo = DeviceInfoPlugin();

  // ─── Synchronous platform getters ─────────────────────────

  static bool get isIOS => UniversalPlatform.isIOS;
  static bool get isAndroid => UniversalPlatform.isAndroid;
  static bool get isWeb => UniversalPlatform.isWeb;
  static bool get isApple => UniversalPlatform.isApple;
  static bool get isLinux => UniversalPlatform.isLinux;
  static bool get isWindows => UniversalPlatform.isWindows;
  static bool get isMacOS => UniversalPlatform.isMacOS;
  static bool get isFuchsia => UniversalPlatform.isFuchsia;
  static bool get isDesktop => UniversalPlatform.isDesktop;
  static bool get isMobile => UniversalPlatform.isMobile;
  static bool get isDesktopOrWeb => UniversalPlatform.isDesktopOrWeb;

  static String get operatingSystem => UniversalPlatform.operatingSystem;

  // ─── Async capability checks ──────────────────────────────

  /// True when running on real hardware (false on emulator/simulator/web).
  static Future<bool> isPhysicalDevice() async {
    try {
      if (isAndroid) return (await _deviceInfo.androidInfo).isPhysicalDevice;
      if (isIOS) return (await _deviceInfo.iosInfo).isPhysicalDevice;
      return false;
    } catch (e, st) {
      deviceWarn('platform.isPhysicalDevice', e, st);
      return false;
    }
  }

  /// True if the device supports AR (ARCore on Android, ARKit on iOS).
  static Future<bool> supportsAR() async {
    try {
      if (isAndroid) {
        final info = await _deviceInfo.androidInfo;
        return info.version.sdkInt >= kMinAndroidSdkForAR;
      }
      if (isIOS) {
        final info = await _deviceInfo.iosInfo;
        final major = int.tryParse(info.systemVersion.split('.').first) ?? 0;
        return major >= kMinIOSVersionForAR;
      }
    } catch (e, st) {
      deviceWarn('platform.supportsAR', e, st);
    }
    return false;
  }

  /// Rough resource state.
  ///
  /// Named for what it actually reads. It was `getThermalState`
  /// returning the strings `'low'` / `'normal'` / `'unknown'`, and it
  /// has never measured temperature — Android's `isLowRamDevice` is a
  /// fact about the hardware, not about how hot it is right now, and
  /// iOS was hard-coded to `'normal'`. A caller acting on "thermal"
  /// was acting on a name that promised something nobody implemented.
  static Future<DeviceResourceState> getResourceState() async {
    try {
      if (isAndroid) {
        final info = await _deviceInfo.androidInfo;
        return info.isLowRamDevice
            ? DeviceResourceState.low
            : DeviceResourceState.normal;
      }
      if (isIOS) return DeviceResourceState.normal;
      return DeviceResourceState.unknown;
    } catch (e, st) {
      deviceWarn('platform.getResourceState', e, st);
      return DeviceResourceState.unknown;
    }
  }
}
