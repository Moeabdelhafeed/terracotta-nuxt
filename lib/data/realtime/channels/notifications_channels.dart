/// Channel-name constants for the notifications domain.
///
/// Same role as `endpoints/*_endpoints.dart` for REST — one place to
/// name-mangle channels so raw strings don't leak across feature code.
/// Scoping private/presence prefixes here also makes it obvious at a
/// glance whether auth is required.
class NotificationsChannels {
  const NotificationsChannels._();

  /// Per-user notification stream — private. Requires auth.
  static String forUser(int userId) => 'private-notifications.$userId';

  /// App-wide announcements — public, no auth.
  static const String announcements = 'announcements';

  // ─── Event names ─────────────────────────────────────────────

  /// New notification arrived. Payload shape: see `RealtimeNotification`.
  static const String newEvent = 'notification_received';

  /// Server flagged a notification as read from another device.
  static const String readEvent = 'notification_read';
}
