import 'package:flutter/foundation.dart';

import '../utils/loggers/logger.dart';
import 'notification_permissions.dart';

/// ASKING FOR THE PERMISSION, once.
///
/// ## Why this exists
///
/// The template's `FCMService.init` deliberately does NOT prompt — it
/// checks, logs "not yet granted", and leaves the asking to whichever
/// feature can explain the value. Nothing in this app ever did, so on
/// Android 13+ `POST_NOTIFICATIONS` was never granted and the OS drew
/// nothing while the app was in the background. The push itself was
/// arriving the whole time — a foreground message logged fine, which
/// is what made it look like a delivery problem rather than a
/// permission one.
///
/// ## When it asks
///
/// From the home screen, which is the first thing the reader sees
/// after the splash — a permission sheet over a splash is a dialog
/// about an app they have not seen yet. Every push this backend sends
/// is about the reader's own booking or order, so the value is the
/// screen they are standing on.
///
/// ## Why no stored "already asked" flag
///
/// Both platforms answer without a dialog once the question is
/// settled: Android returns `permanentlyDenied` and iOS returns the
/// existing authorization, neither of which shows anything. A flag
/// would only add a way for the app's memory and the OS's to
/// disagree. The in-memory latch below is about not making the same
/// call on every rebuild, not about the prompt.
class NotificationOptIn {
  const NotificationOptIn._();

  /// Once per app RUN. `didChangeDependencies` fires again on every
  /// language change, and the check behind this is a platform channel
  /// round trip.
  static bool _asked = false;

  @visibleForTesting
  static void reset() => _asked = false;

  /// The seam a test uses instead of the platform channel.
  @visibleForTesting
  static Future<NotificationPermissionStatus> Function() check =
      NotificationPermissions.check;

  @visibleForTesting
  static Future<NotificationPermissionStatus> Function() request =
      NotificationPermissions.request;

  /// Ask, unless there is nothing to ask.
  ///
  /// Returns the status it settled on. Never throws: a permission this
  /// app could not obtain is a quieter app, not a broken one.
  static Future<NotificationPermissionStatus?> askOnce() async {
    if (_asked) return null;
    _asked = true;

    try {
      final current = await check();
      // Already answered, either way. `denied` on Android means "not
      // asked yet OR said no once"; the request call itself is what
      // tells those apart, and it draws nothing in the second case.
      if (current != NotificationPermissionStatus.denied) return current;

      final result = await request();
      Logger.m.i('[Notifications] opt-in asked → ${result.name}');
      return result;
    } on Object catch (e) {
      Logger.m.w('[Notifications] opt-in failed: $e');
      return null;
    }
  }
}
