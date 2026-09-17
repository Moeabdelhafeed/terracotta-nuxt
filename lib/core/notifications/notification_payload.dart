import 'dart:convert';

import 'package:flutter/foundation.dart';

import 'notification_types.dart';

/// Typed notification payload — the thing that flows from FCM /
/// scheduler into [NotificationRouter]. Replaces the untyped
/// `Map<String, dynamic>` fishing that wire-level APIs force on you.
///
/// ## Wire format (what the backend should send)
///
/// Each notification's `data` field should include at minimum:
///
/// ```json
/// {
///   "type": "order",              // → NotificationType.transactional
///   "title": "Order shipped",
///   "body": "Your order #42 is on the way",
///   "image": "https://...",       // optional, rich notification
///   "deep_link": "/orders/42",    // optional, direct nav hint
///   "click_action": "open_order"  // optional, legacy FCM compat
/// }
/// ```
///
/// Anything extra flows through [data] verbatim — route handlers
/// read IDs, ref codes, etc. from there.
@immutable
class NotificationPayload {
  const NotificationPayload({
    required this.type,
    required this.title,
    required this.body,
    this.id,
    this.image,
    this.deepLink,
    this.clickAction,
    this.priority,
    this.data = const {},
    this.receivedAt,
  });

  /// Category — drives channel selection and router dispatch.
  final NotificationType type;

  /// Optional server-side ID. Used for deduping across retries and
  /// for cancel/schedule operations.
  final String? id;

  final String title;
  final String body;

  /// Rich-notification image URL (large image shown below body).
  final String? image;

  /// Direct navigation hint — if present, router uses this instead of
  /// dispatching to a registered handler. Falls through to registered
  /// handlers when null.
  final String? deepLink;

  /// FCM-legacy `click_action` field. Rarely used; most teams prefer
  /// [deepLink].
  final String? clickAction;

  /// Override for the notification's priority. Falls through to
  /// [NotificationTypeX.defaultPriority] when null.
  final NotificationPriority? priority;

  /// The rest of the data payload — extra fields beyond the canonical
  /// shape. Route handlers pull their required IDs / context from
  /// here.
  final Map<String, dynamic> data;

  /// When the notification arrived (client-side). Useful for
  /// in-app inbox / analytics.
  final DateTime? receivedAt;

  /// Effective priority — caller override if set, else type default.
  NotificationPriority get effectivePriority =>
      priority ?? type.defaultPriority;

  /// Parse a raw data map (e.g. `RemoteMessage.data`). Missing fields
  /// get sensible defaults.
  ///
  /// Pass `messageNotification` to let the FCM `notification` block
  /// fill in `title`/`body` when the data-only payload didn't include
  /// them (mixed `notification + data` messages are common).
  factory NotificationPayload.fromData(
    Map<String, dynamic> raw, {
    String? fallbackTitle,
    String? fallbackBody,
  }) {
    return NotificationPayload(
      type: NotificationTypeX.parse(raw['type']?.toString()),
      id: raw['id']?.toString() ?? raw['notification_id']?.toString(),
      title: raw['title']?.toString() ?? fallbackTitle ?? '',
      body: raw['body']?.toString() ?? fallbackBody ?? '',
      image: raw['image']?.toString() ?? raw['image_url']?.toString(),
      deepLink: raw['deep_link']?.toString() ?? raw['link']?.toString(),
      clickAction: raw['click_action']?.toString(),
      priority: _parsePriority(raw['priority']?.toString()),
      data: raw,
      receivedAt: DateTime.now(),
    );
  }

  /// Parse a local-notification tap payload string — the JSON we
  /// shoved into the `payload` field when scheduling.
  static NotificationPayload? tryFromPayloadString(String? payload) {
    if (payload == null || payload.isEmpty) return null;
    try {
      final decoded = jsonDecode(payload);
      if (decoded is Map<String, dynamic>) {
        return NotificationPayload.fromData(decoded);
      }
    } catch (_) {
      // Not JSON — ignore; caller treats it as opaque.
    }
    return null;
  }

  /// Serialize to a JSON string for the local-notification `payload`
  /// field. Round-trips via [tryFromPayloadString].
  String encode() => jsonEncode(data);

  NotificationPayload copyWith({
    NotificationType? type,
    String? id,
    String? title,
    String? body,
    String? image,
    String? deepLink,
    String? clickAction,
    NotificationPriority? priority,
    Map<String, dynamic>? data,
    DateTime? receivedAt,
  }) {
    return NotificationPayload(
      type: type ?? this.type,
      id: id ?? this.id,
      title: title ?? this.title,
      body: body ?? this.body,
      image: image ?? this.image,
      deepLink: deepLink ?? this.deepLink,
      clickAction: clickAction ?? this.clickAction,
      priority: priority ?? this.priority,
      data: data ?? this.data,
      receivedAt: receivedAt ?? this.receivedAt,
    );
  }

  @override
  String toString() =>
      'NotificationPayload($type, "$title", deepLink: $deepLink)';
}

NotificationPriority? _parsePriority(String? raw) {
  if (raw == null) return null;
  return switch (raw.toLowerCase()) {
    'low' || 'min' => NotificationPriority.low,
    'default' || 'normal' => NotificationPriority.normal,
    'high' => NotificationPriority.high,
    'max' || 'critical' || 'time_sensitive' => NotificationPriority.max,
    _ => null,
  };
}
