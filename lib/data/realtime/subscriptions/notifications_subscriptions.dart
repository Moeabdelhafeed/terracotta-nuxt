import 'package:flutter/foundation.dart';

import '../../../core/error/app_exception.dart';
import '../../../core/realtime/realtime.dart';
import '../../../core/realtime/realtime_service.dart';
import '../../../core/types/result.dart';
import '../../../core/utils/loggers/logger.dart';
import '../auth/broadcasting_auth.dart';
import '../channels/notifications_channels.dart';

// ─── Example payload model ──────────────────────────────────────────
//
// Inline so this file works as a copy-paste template. For real apps,
// move `RealtimeNotification` into `data/model/notifications/` next to
// the REST model for the same domain.

/// Payload parsed from a `notification_received` event.
@immutable
class RealtimeNotification {
  const RealtimeNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.receivedAt,
  });

  factory RealtimeNotification.fromJson(Map<String, dynamic> json) {
    return RealtimeNotification(
      id: json['id'].toString(),
      title: json['title'] as String? ?? '',
      body: json['body'] as String? ?? '',
      receivedAt: json['received_at'] != null
          ? DateTime.parse(json['received_at'] as String)
          : DateTime.now(),
    );
  }

  final String id;
  final String title;
  final String body;
  final DateTime receivedAt;
}

// ─── Subscription helpers ───────────────────────────────────────────

/// Typed realtime subscriptions for the notifications domain. Same
/// role as `calls/*_apis.dart` for REST — wraps raw [Realtime] /
/// [Channel] primitives with domain-specific parsing.
///
/// Every helper returns `Future<Result<Stream<T>, AppException>>`:
/// the `Result` captures subscription failures (connection down,
/// auth rejected), the inner `Stream` emits typed events.
///
/// Individual event parse failures are logged via [Logger.m.w] and
/// the event is skipped — the subscription stays alive. If you want
/// parse failures to surface to the listener, chain `.resultified()`
/// on the returned stream (see `core/types/result.dart`).
class NotificationsRealtime {
  NotificationsRealtime._();

  /// Stream of new notifications for [userId]. Auth-required private
  /// channel; resolves tokens via [broadcastingAuth] unless a custom
  /// [auth] is passed.
  ///
  /// ```dart
  /// final result = await NotificationsRealtime.forUser(userId: 42);
  /// result.onSuccess((stream) {
  ///   stream.listen((notif) => ui.showToast(notif.title));
  /// });
  /// ```
  static Future<Result<Stream<RealtimeNotification>, AppException>> forUser({
    required int userId,
    AuthResolver? auth,
  }) async {
    final result = await Realtime.subscribe(
      NotificationsChannels.forUser(userId),
      auth: auth ?? broadcastingAuth,
    );
    return result.map(
      (channel) => _parseEvents(
        channel.on(NotificationsChannels.newEvent),
      ),
    );
  }

  /// Stream of app-wide announcements. Public channel, no auth.
  static Future<Result<Stream<RealtimeNotification>, AppException>>
  announcements() async {
    final result = await Realtime.subscribe(
      NotificationsChannels.announcements,
    );
    return result.map(
      (channel) => _parseEvents(
        channel.on(NotificationsChannels.newEvent),
      ),
    );
  }

  /// Parse + filter helper. Bad events are logged and dropped so one
  /// malformed payload doesn't take the whole subscription down.
  static Stream<RealtimeNotification> _parseEvents(Stream<RealtimeEvent> raw) {
    return raw
        .asyncMap<RealtimeNotification?>((event) async {
          try {
            return RealtimeNotification.fromJson(event.data);
          } catch (e) {
            Logger.m.w(
              '[Realtime] failed to parse notification: $e (payload: ${event.data})',
            );
            return null;
          }
        })
        .where((n) => n != null)
        .cast<RealtimeNotification>();
  }
}
