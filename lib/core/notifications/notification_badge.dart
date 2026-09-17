import '../utils/loggers/logger.dart';

/// Manages the app-icon badge count ("unread" dot on iOS, number on
/// Android launchers that support it).
///
/// The template doesn't ship a concrete implementation because badge
/// support varies by package + launcher. Install one of the community
/// packages and subclass [NotificationBadgeService]:
///
/// - iOS — `flutter_local_notifications` can set the badge via its
///   `DarwinNotificationDetails(badgeNumber: ...)` field, or you can
///   call [`FlutterAppBadger`](https://pub.dev/packages/flutter_app_badger)
///   directly.
/// - Android — support depends on the launcher (Samsung, Xiaomi, and
///   a few others; not stock Android). Use `flutter_app_badger` or
///   `app_badge_plus`.
///
/// Example implementation using `flutter_app_badger`:
///
/// ```dart
/// class AppBadgerNotificationBadge extends NotificationBadgeService {
///   @override
///   Future<void> set(int count) async {
///     final supported = await FlutterAppBadger.isAppBadgeSupported();
///     if (!supported) return;
///     if (count == 0) {
///       FlutterAppBadger.removeBadge();
///     } else {
///       FlutterAppBadger.updateBadgeCount(count);
///     }
///   }
///
///   @override
///   Future<void> clear() => set(0);
/// }
///
/// NotificationBadge.register(AppBadgerNotificationBadge());
/// ```
abstract class NotificationBadgeService {
  const NotificationBadgeService();

  /// Set the badge to [count]. `0` clears.
  Future<void> set(int count);

  /// Shortcut for `set(0)`.
  Future<void> clear() => set(0);

  /// Best-effort count read — not all platforms expose this. Default
  /// returns null; implementations that can introspect should
  /// override.
  Future<int?> get() async => null;
}

/// Default — logs the call and does nothing. Safe to leave in place
/// if you don't care about icon badges.
class NoOpNotificationBadge extends NotificationBadgeService {
  const NoOpNotificationBadge();

  @override
  Future<void> set(int count) async {
    Logger.m.d(
      '[Notifications] badge.set($count) — no badge service registered',
    );
  }
}

/// Static facade for badge management. Register a concrete service
/// once during bootstrap; feature code calls the static helpers.
///
/// ```dart
/// NotificationBadge.register(AppBadgerNotificationBadge());
/// await NotificationBadge.set(3);
/// ```
class NotificationBadge {
  NotificationBadge._();

  static NotificationBadgeService _service = const NoOpNotificationBadge();
  static int _lastKnown = 0;

  /// Install a concrete badge service. Safe to call multiple times.
  static void register(NotificationBadgeService service) => _service = service;

  /// Restore the default no-op — used in tests + logout.
  static void reset() => _service = const NoOpNotificationBadge();

  /// Cached last value set via this facade. Doesn't reflect external
  /// modifications (other apps, system actions). For authoritative
  /// state call [fetch].
  static int get current => _lastKnown;

  static Future<void> set(int count) async {
    _lastKnown = count;
    await _service.set(count);
  }

  static Future<void> clear() async {
    _lastKnown = 0;
    await _service.clear();
  }

  static Future<void> increment([int by = 1]) => set(_lastKnown + by);

  static Future<void> decrement([int by = 1]) =>
      set((_lastKnown - by).clamp(0, 1 << 31));

  /// Ask the underlying service for the current value. Falls back to
  /// [current] when the service can't introspect.
  static Future<int> fetch() async {
    final v = await _service.get();
    if (v != null) _lastKnown = v;
    return _lastKnown;
  }
}
