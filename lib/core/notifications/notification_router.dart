import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';

import '../navigation/deep_link_handler.dart';
import '../utils/loggers/logger.dart';
import 'notification_payload.dart';
import 'notification_types.dart';

/// Returns a route path for a notification payload, or null to let
/// the router fall through to the next strategy (explicit `deepLink`
/// on the payload, or a type-registered default).
typedef NotificationRouteBuilder =
    String? Function(NotificationPayload payload);

/// Translates tapped notifications into in-app navigation.
///
/// ## Resolution order
///
/// 1. **Per-type registered handler** — if a builder is registered
///    via [register] for the payload's [NotificationType], it runs
///    first. Returning null falls through.
/// 2. **Payload `deepLink`** — if the server sent a `deep_link`
///    field, route there directly.
/// 3. **Fall-through default** — if neither of the above resolves, do
///    nothing (notification tap becomes a no-op — app just comes to
///    foreground).
///
/// ## Cold-start queue
///
/// When the app is terminated and the user taps a notification, the
/// OS launches the app with an intent. The router isn't ready yet
/// (GoRouter hasn't mounted). Payloads arriving before [bind] is
/// called are queued and replayed once the router binds.
///
/// ## Usage
///
/// ```dart
/// // main.dart — register handlers once per type
/// NotificationRouter.register(NotificationType.transactional,
///   (p) => '/orders/${p.data['order_id']}');
/// NotificationRouter.register(NotificationType.message,
///   (p) => '/chat/${p.data['thread_id']}');
///
/// // Bind to GoRouter as soon as it's available — this also drains
/// // any queued cold-start payloads.
/// NotificationRouter.bind(GoRouterConfig.router);
///
/// // FCMService / LocalNotificationService call this on tap:
/// NotificationRouter.handle(payload);
/// ```
class NotificationRouter {
  NotificationRouter._();

  static final Map<NotificationType, NotificationRouteBuilder> _handlers = {};
  static GoRouter? _router;
  static final List<NotificationPayload> _pendingCold = [];

  /// Register a route builder for [type]. Only one builder per type
  /// — later registrations replace earlier ones (no chaining).
  static void register(
    NotificationType type,
    NotificationRouteBuilder builder,
  ) {
    _handlers[type] = builder;
  }

  /// Register builders for multiple types at once.
  static void registerAll(
    Map<NotificationType, NotificationRouteBuilder> builders,
  ) {
    _handlers.addAll(builders);
  }

  /// Remove the handler for [type].
  static void unregister(NotificationType type) => _handlers.remove(type);

  /// Drop all handlers — useful between tests or on logout when
  /// routes need to be re-derived for a different user role.
  static void clear() {
    _handlers.clear();
    _pendingCold.clear();
  }

  /// Bind the GoRouter to use for navigation. Also drains any
  /// queued cold-start payloads. Safe to call multiple times — the
  /// latest router wins.
  static void bind(GoRouter router) {
    _router = router;
    if (_pendingCold.isNotEmpty) {
      Logger.m.i(
        '[Notifications] draining ${_pendingCold.length} queued cold-start payload(s)',
      );
      final queued = List.of(_pendingCold);
      _pendingCold.clear();
      for (final p in queued) {
        _dispatch(p);
      }
    }
  }

  /// Handle a tapped notification. If the router isn't bound yet,
  /// the payload is queued and replayed on [bind].
  static void handle(NotificationPayload payload) {
    if (_router == null) {
      Logger.m.d('[Notifications] router not bound; queueing ${payload.type}');
      _pendingCold.add(payload);
      return;
    }
    _dispatch(payload);
  }

  static void _dispatch(NotificationPayload payload) {
    final route = _resolveRoute(payload);
    if (route == null) {
      Logger.m.d(
        '[Notifications] no route resolved for ${payload.type} (deepLink: ${payload.deepLink})',
      );
      return;
    }
    Logger.m.i('[Notifications] → $route (${payload.type})');
    try {
      _router!.go(route);
    } catch (e) {
      Logger.m.w('[Notifications] GoRouter.go($route) failed: $e');
    }
  }

  static String? _resolveRoute(NotificationPayload payload) {
    // 1. Type-registered handler.
    final handler = _handlers[payload.type];
    if (handler != null) {
      final route = handler(payload);
      if (route != null) return route;
    }

    // 2. Explicit deep link from payload — ran through DeepLinkHandler
    //    so any registered rewrites apply.
    final link = payload.deepLink;
    if (link != null && link.isNotEmpty) {
      try {
        return DeepLinkHandler.resolve(Uri.parse(link));
      } catch (_) {
        // Non-URI string — use as-is (relative paths work directly).
        return link;
      }
    }

    return null;
  }

  /// Exposed for tests — inspects the current handler map.
  @visibleForTesting
  static Map<NotificationType, NotificationRouteBuilder> get handlers =>
      Map.unmodifiable(_handlers);

  /// Exposed for tests — inspects the cold-start queue.
  @visibleForTesting
  static List<NotificationPayload> get pending =>
      List.unmodifiable(_pendingCold);
}
