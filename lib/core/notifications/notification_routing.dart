import 'dart:async';

import '../../data/services/navigation_service.dart';
import '../di/service_locator.dart';
import '../utils/loggers/logger.dart';
import 'notification_payload.dart';
import 'notifications.dart';

/// Where a tapped notification takes the reader.
///
/// ## The gap this closes
///
/// `FCMService` parsed every push, published it to
/// [Notifications.onTap] and stashed a cold-start one for
/// [Notifications.takeInitialPayload] — and **nothing in the app was
/// listening to either**. Every push opened the app on whatever screen
/// it was last on. The server does its half properly: `UserNotifier`
/// puts `type` in the data payload alongside the id it concerns
/// (`workshop_booking_id`, `shop_order_id`, `gift_id`), which is
/// exactly what a destination needs.
///
/// ## Two arrivals, one map
///
/// A tap on a RUNNING app (foreground or background) arrives on the
/// stream. A tap that LAUNCHED the app arrives through
/// `getInitialMessage`, before the router exists — so it is stashed
/// and claimed once the first screen is up. Both end here.
abstract final class NotificationRouting {
  const NotificationRouting._();

  static StreamSubscription<NotificationPayload>? _sub;

  /// Starts listening. Called once, from `bootstrap`.
  static void start() {
    _sub ??= Notifications.onTap.listen(_open);
  }

  /// Claims a notification that launched the app, if there was one.
  ///
  /// Called after the router is up — from the splash's hand-off, where
  /// there is somewhere to navigate TO. Reading it earlier throws the
  /// destination away.
  static void claimLaunchTap() {
    final payload = Notifications.takeInitialPayload();
    if (payload != null) _open(payload);
  }

  static void dispose() {
    _sub?.cancel();
    _sub = null;
  }

  /// The screen a push is about.
  ///
  /// Anything unrecognised opens the INBOX rather than nothing: the
  /// notification is in there whatever its type, so the reader still
  /// arrives somewhere that explains the tap.
  static void _open(NotificationPayload payload) {
    if (!getIt.isRegistered<NavigationService>()) return;
    final router = getIt<NavigationService>().router;
    final data = payload.data;

    // `data` values arrive as STRINGS — FCM's payload is a string map,
    // and `UserNotifier` casts every value on the way out.
    final bookingId = data['workshop_booking_id']?.toString();
    final orderId = data['shop_order_id']?.toString();

    try {
      if (bookingId != null && bookingId.isNotEmpty) {
        router.goNamed('workshops');
        router.pushNamed(
          'booking-detail',
          pathParameters: {'bookingId': bookingId},
        );
        return;
      }
      if (orderId != null && orderId.isNotEmpty) {
        router.goNamed('shop');
        router.pushNamed('my-orders');
        router.pushNamed(
          'order-detail',
          pathParameters: {'orderId': orderId},
        );
        return;
      }
      // A gift, a wallet credit, or a type this build does not know.
      router.pushNamed('notifications');
    } catch (e) {
      // A route that does not exist must not take the app down over a
      // notification — the reader tapped to READ something.
      Logger.m.w('[Notifications] could not open ${data['type']}: $e');
    }
  }
}
