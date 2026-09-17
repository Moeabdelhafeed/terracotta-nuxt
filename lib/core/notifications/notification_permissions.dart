import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart' as ph;

import '../utils/device/info/platform_utils.dart';
import '../utils/loggers/logger.dart';

/// Typed result of a notification permission check or request.
enum NotificationPermissionStatus {
  /// User granted full permission.
  granted,

  /// User granted provisional permission (iOS only) — notifications
  /// arrive silently to the notification center, user can opt in to
  /// sounds/alerts from there.
  provisional,

  /// User declined or the OS hasn't asked yet.
  denied,

  /// Restricted by parental controls / MDM / device policy. Cannot
  /// be overridden by the user in-app; point them at [openSettings].
  restricted,

  /// Permanently denied after one-or-more user declines. On iOS the
  /// OS won't re-show the prompt; on Android 13+ it blocks after
  /// "don't ask again." Only [openSettings] can recover.
  permanentlyDenied,
}

/// Unified surface for notification permission state across:
///  - iOS APNS / FCM (`FirebaseMessaging.requestPermission`)
///  - Android 13+ runtime `POST_NOTIFICATIONS` permission
///  - Android 8–12 (always granted, doesn't need a prompt)
///  - Web (limited support — uses the FCM flow as best-effort)
///
/// Feature code should never touch `FirebaseMessaging.requestPermission`
/// directly. This class is the seam.
///
/// ```dart
/// final status = await NotificationPermissions.request();
/// if (status != NotificationPermissionStatus.granted) {
///   // show settings-deeplink UI
/// }
/// ```
class NotificationPermissions {
  const NotificationPermissions._();

  /// Current status without prompting.
  static Future<NotificationPermissionStatus> check() async {
    // Android 13+ uses permission_handler's notification permission
    // (backed by POST_NOTIFICATIONS). Older Android versions: always
    // granted (no runtime permission exists).
    if (kIsWeb) {
      final settings = await FirebaseMessaging.instance.getNotificationSettings();
      return _mapFcmStatus(settings.authorizationStatus);
    }

    if (PlatformUtils.isAndroid) {
      final status = await ph.Permission.notification.status;
      return _mapAndroidStatus(status);
    }

    // iOS / macOS — FCM has the canonical state.
    final settings = await FirebaseMessaging.instance.getNotificationSettings();
    return _mapFcmStatus(settings.authorizationStatus);
  }

  /// Prompt the user. Returns the final status after the prompt
  /// resolves. Idempotent — returns the existing status on platforms
  /// that don't re-prompt.
  static Future<NotificationPermissionStatus> request() async {
    if (!kIsWeb && PlatformUtils.isAndroid) {
      final result = await ph.Permission.notification.request();
      final mapped = _mapAndroidStatus(result);
      Logger.m.i(
        '[Notifications] Android permission: ${result.name} → ${mapped.name}',
      );
      return mapped;
    }

    final settings = await FirebaseMessaging.instance.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );
    final mapped = _mapFcmStatus(settings.authorizationStatus);
    Logger.m.i(
      '[Notifications] iOS permission: ${settings.authorizationStatus.name} → ${mapped.name}',
    );
    return mapped;
  }

  /// Open the OS settings app to the notification section for this
  /// app — the only recovery path from [permanentlyDenied].
  static Future<bool> openSettings() async {
    try {
      return await ph.openAppSettings();
    } catch (e) {
      Logger.m.w('[Notifications] openAppSettings failed: $e');
      return false;
    }
  }

  /// Convenience — true when notifications can be displayed.
  static Future<bool> isGranted() async {
    final s = await check();
    return s == NotificationPermissionStatus.granted || s == NotificationPermissionStatus.provisional;
  }

  static NotificationPermissionStatus _mapAndroidStatus(ph.PermissionStatus s) {
    return switch (s) {
      ph.PermissionStatus.granted => NotificationPermissionStatus.granted,
      ph.PermissionStatus.limited => NotificationPermissionStatus.provisional,
      ph.PermissionStatus.denied => NotificationPermissionStatus.denied,
      ph.PermissionStatus.restricted => NotificationPermissionStatus.restricted,
      ph.PermissionStatus.permanentlyDenied => NotificationPermissionStatus.permanentlyDenied,
      ph.PermissionStatus.provisional => NotificationPermissionStatus.provisional,
    };
  }

  static NotificationPermissionStatus _mapFcmStatus(AuthorizationStatus s) {
    return switch (s) {
      AuthorizationStatus.authorized => NotificationPermissionStatus.granted,
      AuthorizationStatus.provisional => NotificationPermissionStatus.provisional,
      AuthorizationStatus.denied => NotificationPermissionStatus.denied,
      AuthorizationStatus.notDetermined => NotificationPermissionStatus.denied,
      // ANDROID 13's "don't ask again", which
      // `firebase_messaging_platform_interface` grew in 4.10.0. It is
      // the same thing `permission_handler` calls
      // `permanentlyDenied`: the OS will not show the prompt again and
      // the only way back is the system settings screen — which is why
      // it maps to its own value rather than plain [denied], where the
      // app would keep offering a request that does nothing.
      AuthorizationStatus.deniedPermanently => NotificationPermissionStatus.permanentlyDenied,
    };
  }
}
