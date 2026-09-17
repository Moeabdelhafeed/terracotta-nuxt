import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';

import '../device_services.dart';

/// Location permission + service status, and a one-shot fix.
class LocationUtils {
  LocationUtils._();

  /// True if location services (GPS) are on at the OS level.
  static Future<bool> isEnabled() => deviceGuard(
    'location.isEnabled',
    Geolocator.isLocationServiceEnabled,
    fallback: false,
  );

  /// Current permission status, without prompting.
  static Future<PermissionStatus> getPermissionStatus() => deviceGuard(
    'location.getPermissionStatus',
    () => Permission.location.status,
    fallback: PermissionStatus.denied,
  );

  static Future<bool> hasPermission() async =>
      (await getPermissionStatus()).isGranted;

  /// Ask for location permission. Skips the prompt if already granted.
  static Future<bool> requestPermission() => deviceGuard(
    'location.requestPermission',
    () async {
      if (await Permission.location.status.isGranted) return true;
      return (await Permission.location.request()).isGranted;
    },
    fallback: false,
  );

  /// Open the system's location settings.
  static Future<bool> openSettings() => deviceGuard(
    'location.openSettings',
    Geolocator.openLocationSettings,
    fallback: false,
  );

  /// Open this app's permission page — where a permanently denied
  /// permission can be granted back.
  static Future<bool> openAppPermissionSettings() => deviceGuard(
    'location.openAppPermissionSettings',
    openAppSettings,
    fallback: false,
  );

  /// The device's current position, requesting permission and
  /// confirming GPS on the way. Null when unavailable or denied —
  /// never throws.
  static Future<Position?> currentPosition({
    LocationAccuracy accuracy = LocationAccuracy.medium,
  }) => deviceGuard('location.currentPosition', () async {
    if (!await isEnabled()) return null;
    if (!await requestPermission()) return null;
    return Geolocator.getCurrentPosition(
      locationSettings: LocationSettings(accuracy: accuracy),
    );
  }, fallback: null);
}
