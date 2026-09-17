import 'dart:async';

import 'package:go_router/go_router.dart';

import '../utils/loggers/logger.dart';
import 'notification_payload.dart';
import 'notification_permissions.dart';
import 'notification_preferences.dart';
import 'notification_router.dart';
import 'notification_types.dart';

/// Contract for a service that can display notifications. Concrete
/// implementations live in `data/notifications/`:
///  - `LocalNotificationService` — persistent OS notifications
///    (scheduled / foreground / background).
///  - `InAppNotificationService` — transient UI (toast/banner) shown
///    only while the app is foreground-active.
///  - Push platform adapters (FCM) plug in here too if they need to
///    display client-side when the OS hasn't already.
///
/// The [Notifications] facade dispatches to whichever is registered
/// for the target kind (`os` vs `inApp`).
abstract class NotificationDisplayService {
  Future<void> show(NotificationPayload payload);
  Future<void> schedule(NotificationPayload payload, {required DateTime at});
  Future<void> cancel(String id);
  Future<void> cancelAll();
  Future<List<String>> pendingIds();
}

/// Where to display a notification. Selected automatically by the
/// facade based on app state + payload type; override at the
/// callsite when needed.
enum NotificationDisplayTarget {
  /// OS-level notification (status bar, lock screen). Persists after
  /// the app is closed.
  system,

  /// In-app overlay (toast / banner). Only visible while the app is
  /// foreground-active; dismisses automatically.
  inApp,

  /// Automatic — facade picks `inApp` when the app is foreground and
  /// the payload type is a fit, else `system`.
  auto,
}

/// App-wide notification facade. Central surface for:
///  - **Display** — `show`, `schedule`, `cancel`.
///  - **Routing** — cold-start tap + runtime tap, via
///    [NotificationRouter].
///  - **Lifecycle streams** — `onTap`, `onDelivered` for analytics +
///    custom hooks.
///  - **Initial message** — payload that launched the app, consumed
///    once.
///
/// Feature code never touches FCM / flutter_local_notifications
/// directly — it goes through here.
///
/// ## Bootstrap
///
/// ```dart
/// // main.dart
/// await Notifications.initialize(
///   router: GoRouterConfig.router,
///   routes: {
///     NotificationType.transactional: (p) => '/orders/${p.data['order_id']}',
///     NotificationType.message: (p) => '/chat/${p.data['thread_id']}',
///   },
/// );
/// ```
///
/// Actual display services (local / in-app / FCM) register
/// themselves with [Notifications.registerSystemDisplay] /
/// [Notifications.registerInAppDisplay] during their own init — the
/// wiring happens in `data/notifications/notifications_config.dart`.
class Notifications {
  Notifications._();

  static NotificationDisplayService? _system;
  static NotificationDisplayService? _inApp;

  static final StreamController<NotificationPayload> _onTap =
      StreamController<NotificationPayload>.broadcast();
  static final StreamController<NotificationPayload> _onDelivered =
      StreamController<NotificationPayload>.broadcast();

  /// Payload that launched the app (notification tapped from
  /// terminated state). Set by FCMService on startup and consumed
  /// exactly once via [takeInitialPayload].
  static NotificationPayload? _initialPayload;

  // ─── Bootstrap ───────────────────────────────────────────────────

  /// One-shot setup. Binds the router, registers route handlers,
  /// loads persisted preferences, and requests permission.
  ///
  /// Concrete display services (local / in-app / FCM) are expected
  /// to have registered themselves via [registerSystemDisplay] /
  /// [registerInAppDisplay] before this runs — typically wired in
  /// `notifications_config.dart`.
  ///
  /// [requestPermission] defaults to false — explicit opt-in so you
  /// can choose the right moment in the UX to ask (iOS best
  /// practice: prompt at a point where the value is clear to the
  /// user).
  static Future<void> initialize({
    required GoRouter router,
    Map<NotificationType, NotificationRouteBuilder>? routes,
    bool requestPermission = false,
  }) async {
    NotificationPreferences.instance.load();
    if (routes != null) NotificationRouter.registerAll(routes);
    NotificationRouter.bind(router);

    if (requestPermission) {
      final status = await NotificationPermissions.request();
      Logger.m.i('[Notifications] permission status: ${status.name}');
    }
  }

  // ─── Display-service registration ────────────────────────────────

  static void registerSystemDisplay(NotificationDisplayService service) =>
      _system = service;
  static void registerInAppDisplay(NotificationDisplayService service) =>
      _inApp = service;

  /// Active system-level display service, or null if none wired.
  static NotificationDisplayService? get systemDisplay => _system;
  static NotificationDisplayService? get inAppDisplay => _inApp;

  // ─── Display ─────────────────────────────────────────────────────

  /// Show [payload] now. Consults [NotificationPreferences] first —
  /// suppressed / silenced according to user settings.
  ///
  /// [target] defaults to [NotificationDisplayTarget.auto] — the
  /// facade picks `inApp` for toast-worthy types while the app is
  /// active, else `system`.
  static Future<void> show(
    NotificationPayload payload, {
    NotificationDisplayTarget target = NotificationDisplayTarget.auto,
  }) async {
    final decision = NotificationPreferences.instance.evaluate(payload);
    switch (decision) {
      case NotificationPresentation.suppress:
        Logger.m.d('[Notifications] suppressed (${payload.type}) — prefs');
        return;
      case NotificationPresentation.silent:
        // Display-services honor the payload's priority; a silent
        // decision downshifts to `low` so sound/vibration drop.
        payload = payload.copyWith(priority: NotificationPriority.low);
      case NotificationPresentation.full:
        break;
    }

    final resolved = _resolveTarget(target, payload);
    final service = resolved == NotificationDisplayTarget.inApp
        ? _inApp
        : _system;
    if (service == null) {
      Logger.m.w(
        '[Notifications] no ${resolved.name} display service registered — dropping ${payload.type}',
      );
      return;
    }
    await service.show(payload);
    _onDelivered.add(payload);
  }

  /// Schedule [payload] for [at]. Always routed through the system
  /// display — in-app notifications can't survive app close.
  static Future<void> schedule(
    NotificationPayload payload, {
    required DateTime at,
  }) async {
    final service = _system;
    if (service == null) {
      Logger.m.w(
        '[Notifications] no system display service registered — cannot schedule',
      );
      return;
    }
    await service.schedule(payload, at: at);
  }

  /// Cancel a previously-shown or scheduled notification by its
  /// [id]. No-op if the id isn't tracked.
  static Future<void> cancel(String id) async {
    await _system?.cancel(id);
    await _inApp?.cancel(id);
  }

  static Future<void> cancelAll() async {
    await _system?.cancelAll();
    await _inApp?.cancelAll();
  }

  static Future<List<String>> pendingIds() async {
    final s = await _system?.pendingIds() ?? const [];
    final i = await _inApp?.pendingIds() ?? const [];
    return [...s, ...i];
  }

  // ─── Lifecycle streams ───────────────────────────────────────────

  /// Fires every time the user taps a notification (push or local).
  /// Dispatch to [NotificationRouter] already ran — this is for
  /// side-effects (analytics, marking read, etc.).
  static Stream<NotificationPayload> get onTap => _onTap.stream;

  /// Fires when a notification is displayed via [show]. Push
  /// notifications delivered directly by the OS (app in background)
  /// don't fire here — they're outside our pipeline.
  static Stream<NotificationPayload> get onDelivered => _onDelivered.stream;

  /// Internal — concrete services call this when the user taps.
  static void reportTap(NotificationPayload payload) {
    _onTap.add(payload);
    NotificationRouter.handle(payload);
  }

  /// Internal — concrete services call this to register a delivered
  /// event from a push that the OS displayed directly.
  static void reportDelivered(NotificationPayload payload) {
    _onDelivered.add(payload);
  }

  // ─── Initial payload (cold start) ────────────────────────────────

  /// Set by FCM service on startup if the app was launched by a
  /// notification tap. Read once via [takeInitialPayload]; subsequent
  /// calls return null.
  static void setInitialPayload(NotificationPayload payload) {
    _initialPayload = payload;
  }

  /// Returns the cold-start payload if any, then clears it. Call
  /// from your splash / home screen after GoRouter is ready.
  static NotificationPayload? takeInitialPayload() {
    final p = _initialPayload;
    _initialPayload = null;
    return p;
  }

  // ─── Permissions passthrough ─────────────────────────────────────

  static Future<NotificationPermissionStatus> checkPermission() =>
      NotificationPermissions.check();
  static Future<NotificationPermissionStatus> requestPermission() =>
      NotificationPermissions.request();

  // ─── Internal helpers ────────────────────────────────────────────

  static NotificationDisplayTarget _resolveTarget(
    NotificationDisplayTarget requested,
    NotificationPayload payload,
  ) {
    if (requested != NotificationDisplayTarget.auto) return requested;
    // Auto rule: in-app for toast-worthy types when the app is
    // active + foreground. Callers inside feature code can override
    // by passing an explicit target.
    final isToastWorthy =
        payload.type == NotificationType.message ||
        payload.type == NotificationType.transactional;
    if (isToastWorthy && _inApp != null) return NotificationDisplayTarget.inApp;
    return NotificationDisplayTarget.system;
  }
}
