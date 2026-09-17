import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:go_router/go_router.dart';

import '../../core/di/service_locator.dart';
import '../../core/notifications/notification_router.dart';
import '../../core/notifications/notification_types.dart';
import '../../core/notifications/notifications.dart';
import 'fcm_service.dart';
import 'in_app_notification_service.dart';
import 'local_notification_service.dart';
import 'notification_analytics.dart';
import 'notification_background_handler.dart';
import 'notification_history.dart';

// Re-export the type + builder typedef so the bootstrap call site can
// write `NotificationType.message` without a second import.
export '../../core/notifications/notification_router.dart'
    show NotificationRouteBuilder;
export '../../core/notifications/notification_types.dart' show NotificationType;

/// Single entry point for notification setup — parallel to
/// `realtime_config.dart` / `api_config.dart`. Call once from
/// `main.dart` after Firebase and the GoRouter are available:
///
/// ```dart
/// // main.dart
/// WidgetsFlutterBinding.ensureInitialized();
/// await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
/// FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
///
/// await NotificationsConfig.bootstrap(
///   router: GoRouterConfig.router,
///   routes: {
///     NotificationType.transactional: (p) => '/orders/${p.data['order_id']}',
///     NotificationType.message:       (p) => '/chat/${p.data['thread_id']}',
///     NotificationType.system:        (p) => '/notifications',
///   },
///   enableAnalytics: true,     // optional — logs delivery/tap events
///   enableHistory: true,       // optional — persists to SQLite inbox
/// );
/// ```
///
/// After this call:
///  - Local notification channels are registered on Android.
///  - FCM token lifecycle is live.
///  - Foreground pushes flow through [Notifications.show].
///  - Tapped notifications (cold / warm / hot) route via
///    [NotificationRouter].
class NotificationsConfig {
  const NotificationsConfig._();

  /// One-shot setup. Safe to call multiple times (idempotent in
  /// practice because each service's `init` is itself idempotent).
  static Future<void> bootstrap({
    required GoRouter router,
    Map<NotificationType, NotificationRouteBuilder>? routes,
    bool enableAnalytics = false,
    bool enableHistory = false,
  }) async {
    // 1. Register background handler *before* services init — FCM
    //    requires this to be wired up before the plugin spins up.
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    // 2. Core facade setup (router binding, route handlers, prefs).
    await Notifications.initialize(router: router, routes: routes);

    // 3. Display services register themselves with the facade on
    //    init — order doesn't matter, but local before fcm is nice
    //    because FCM's foreground flow calls into the facade.
    getIt.registerLazySingleton<LocalNotificationService>(
      () => LocalNotificationService(),
    );
    getIt.registerLazySingleton<InAppNotificationService>(
      () => InAppNotificationService(),
    );
    getIt.registerLazySingleton<FCMService>(() => FCMService());

    await getIt<LocalNotificationService>().init();
    await getIt<InAppNotificationService>().init();
    await getIt<FCMService>().init();

    // 4. Optional hooks.
    if (enableHistory) {
      getIt.registerLazySingleton<NotificationHistoryService>(
        () => NotificationHistoryService(),
      );
      await getIt<NotificationHistoryService>().init();
    }
    if (enableAnalytics) {
      NotificationAnalyticsHook.install();
    }
  }
}
