import 'package:permission_handler/permission_handler.dart';

import '../../../constants/enums/app/permission_status.dart';
import '../device_services.dart';

/// Centralized permission management — wraps `permission_handler` with the
/// project's [AppPermissionStatus] enum.
///
/// ```dart
/// final status = await PermissionUtils.check(Permission.camera);
/// if (status.canRequest) {
///   final granted = await PermissionUtils.request(Permission.camera);
/// } else if (status.requiresSettings) {
///   await PermissionUtils.openSystemSettings();
/// }
/// ```
class PermissionUtils {
  PermissionUtils._();

  /// Check current status without requesting.
  static Future<AppPermissionStatus> check(Permission permission) =>
      deviceGuard(
        'permission.check',
        () async => _map(await permission.status),
        fallback: AppPermissionStatus.unknown,
      );

  /// Request permission from the user. Skips the prompt if already granted.
  static Future<AppPermissionStatus> request(Permission permission) =>
      deviceGuard('permission.request', () async {
        if (await permission.status.isGranted) {
          return AppPermissionStatus.granted;
        }
        return _map(await permission.request());
      }, fallback: AppPermissionStatus.unknown);

  /// Request multiple permissions in a single prompt (Android only — iOS
  /// shows them sequentially).
  static Future<Map<Permission, AppPermissionStatus>> requestMultiple(
    List<Permission> permissions,
  ) async {
    return deviceGuard(
      'permission.requestMultiple',
      () async =>
          (await permissions.request()).map((k, v) => MapEntry(k, _map(v))),
      fallback: {for (final p in permissions) p: AppPermissionStatus.unknown},
    );
  }

  /// Open the app's settings page (where the user can grant permanently
  /// denied permissions).
  static Future<bool> openSystemSettings() => deviceGuard(
    'permission.openSystemSettings',
    openAppSettings,
    fallback: false,
  );

  /// Convenience: true if a permission is currently granted.
  static Future<bool> isGranted(Permission permission) async {
    final status = await check(permission);
    return status.isGranted;
  }

  // ─── Mapping ──────────────────────────────────────────────

  static AppPermissionStatus _map(PermissionStatus status) {
    switch (status) {
      case PermissionStatus.granted:
      case PermissionStatus.limited:
      case PermissionStatus.provisional:
        return AppPermissionStatus.granted;
      case PermissionStatus.denied:
        return AppPermissionStatus.denied;
      case PermissionStatus.permanentlyDenied:
        return AppPermissionStatus.permanentlyDenied;
      case PermissionStatus.restricted:
        return AppPermissionStatus.restricted;
    }
  }
}
