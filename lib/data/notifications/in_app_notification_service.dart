import '../../core/notifications/notification_payload.dart';
import '../../core/notifications/notifications.dart';
import '../../core/utils/loggers/logger.dart';
import '../../shared/common/toasts/notification_toast.dart';
import '../../shared/module/toast/global_toast.dart';

/// In-app [NotificationDisplayService] that renders through the
/// existing [GlobalToast] module instead of the OS notification shade.
///
/// When to use in-app vs system:
///  - **In-app** — the user is actively looking at the screen;
///    blowing up a heads-up OS notification on top of their view
///    feels shouty. A quieter toast is nicer.
///  - **System** — app is backgrounded, or the notification carries
///    info the user needs even after the app closes.
///
/// The [Notifications] facade decides which to call in `auto` mode
/// (the default). This class registers itself as the "in-app"
/// display during init.
///
/// ## Tap handling
/// [NotificationToast] wires the toast's `onTap` to
/// [Notifications.reportTap], so an in-app tap routes exactly like a
/// real OS notification tap.
///
/// ## Scheduling / cancel
/// Toasts are transient by design — scheduling ahead of time or
/// cancelling specific toasts doesn't really make sense. Those
/// methods log and no-op; use the local notification service for
/// persistent + scheduled flows.
class InAppNotificationService implements NotificationDisplayService {
  Future<InAppNotificationService> init() async {
    Notifications.registerInAppDisplay(this);
    Logger.m.i('[Notifications] InAppNotificationService ready');
    return this;
  }

  @override
  Future<void> show(NotificationPayload payload) async {
    // Shape, tap routing and timing all live in NotificationToast. This
    // used to map the five categories onto four severity colours and
    // drop everything else the payload carried — the deep link, the
    // image, the timestamp — so an in-app notification could be read
    // but never opened.
    NotificationToast.show(payload);
  }

  @override
  Future<void> schedule(
    NotificationPayload payload, {
    required DateTime at,
  }) async {
    Logger.m.w(
      '[Notifications] in-app scheduling is not supported — use LocalNotificationService for scheduled flows',
    );
  }

  @override
  Future<void> cancel(String id) async {
    // Toasts self-dismiss on duration; no cancel by id.
  }

  @override
  Future<void> cancelAll() async {
    GlobalToast.dismissAll();
  }

  @override
  Future<List<String>> pendingIds() async => const [];
}
