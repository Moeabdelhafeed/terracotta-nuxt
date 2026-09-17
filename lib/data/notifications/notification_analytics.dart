import 'dart:async';

import '../../core/analytics/analytics.dart';
import '../../core/notifications/notification_payload.dart';
import '../../core/notifications/notifications.dart';

/// Wires notification lifecycle events into the [Analytics] facade so
/// you get click-through rate, delivery volume, and tap-to-navigation
/// dashboards "for free" once you register a real analytics adapter.
///
/// Events emitted:
///  - `notification_delivered` — [Notifications.show] resolved and
///    the UI rendered a notification.
///  - `notification_tapped` — user interacted with a notification
///    (in-app toast, OS notification, or local).
///
/// Each event carries `type`, `id` (if present), and any extra data
/// keys from the payload (flattened with a `notif_` prefix).
///
/// Install once at bootstrap (see `notifications_config.dart`); the
/// hook is fire-and-forget, so shutdown is a no-op.
class NotificationAnalyticsHook {
  NotificationAnalyticsHook._();

  static StreamSubscription<NotificationPayload>? _tapSub;
  static StreamSubscription<NotificationPayload>? _deliveredSub;

  static void install() {
    _tapSub ??= Notifications.onTap.listen(_onTap);
    _deliveredSub ??= Notifications.onDelivered.listen(_onDelivered);
  }

  static void uninstall() {
    _tapSub?.cancel();
    _tapSub = null;
    _deliveredSub?.cancel();
    _deliveredSub = null;
  }

  static void _onDelivered(NotificationPayload p) {
    Analytics.logEvent('notification_delivered', _paramsFor(p));
  }

  static void _onTap(NotificationPayload p) {
    Analytics.logEvent('notification_tapped', _paramsFor(p));
  }

  static Map<String, Object?> _paramsFor(NotificationPayload p) {
    return {
      'type': p.type.name,
      if (p.id != null) 'id': p.id,
      'priority': p.effectivePriority.name,
      if (p.deepLink != null) 'deep_link': p.deepLink,
    };
  }
}
