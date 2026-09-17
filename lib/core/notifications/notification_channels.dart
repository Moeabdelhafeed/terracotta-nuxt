import 'package:flutter/foundation.dart';

import '../localization/strings/notifications_strings.dart';
import 'notification_types.dart';

/// Configuration for a single Android notification channel (Android
/// 8+ requires these). The concrete `flutter_local_notifications`
/// channel is built from this at registration time — we keep the
/// config pure so this file has no plugin dependency.
///
/// iOS doesn't have channels per se; it has **categories** with
/// actions. [category] maps to the iOS category identifier when the
/// same notification type needs iOS actions.
@immutable
class NotificationChannelConfig {
  const NotificationChannelConfig({
    required this.id,
    required this.type,
    String? name,
    String? description,
    this.defaultPriority = NotificationPriority.normal,
    this.sound = true,
    this.vibration = true,
    this.lights = true,
    this.badge = true,
    this.iosCategory,
  }) : _name = name,
       _description = description;

  /// Stable machine ID. Android requires this to persist across
  /// installs — don't rename once shipped, or users' muted-state
  /// settings reset.
  final String id;

  final String? _name;
  final String? _description;

  /// Human-readable name shown in OS settings — localized at
  /// registration time (channels re-register with the current locale;
  /// [id] stays stable so user muted-state survives).
  String get name =>
      _name ??
      switch (id) {
        'transactional' => NotificationChannelStrings.transactionalName,
        'messages' => NotificationChannelStrings.messagesName,
        'promo' => NotificationChannelStrings.promoName,
        'system' => NotificationChannelStrings.systemName,
        'general' => NotificationChannelStrings.generalName,
        _ => id,
      };

  /// Description shown in OS settings — localized at registration time.
  String get description =>
      _description ??
      switch (id) {
        'transactional' => NotificationChannelStrings.transactionalDescription,
        'messages' => NotificationChannelStrings.messagesDescription,
        'promo' => NotificationChannelStrings.promoDescription,
        'system' => NotificationChannelStrings.systemDescription,
        'general' => NotificationChannelStrings.generalDescription,
        _ => '',
      };

  /// Which [NotificationType] feeds this channel. Many-to-one is
  /// legal (e.g. both `order` and `shipping` notifications could land
  /// in a `transactional` channel).
  final NotificationType type;

  final NotificationPriority defaultPriority;
  final bool sound;
  final bool vibration;
  final bool lights;
  final bool badge;

  /// iOS category identifier — configured on the server side via APNS
  /// `category` field and declared on the client via
  /// `UNNotificationCategory`. Leave null if you don't use iOS
  /// actions.
  final String? iosCategory;
}

/// Central registry of all notification channels used by the app.
/// Update this file to add a category — channel registration happens
/// once at app start (see data/notifications/local_notification_service).
///
/// ## How to add a channel
///
/// 1. Add a new [NotificationChannelConfig] to [all].
/// 2. If it's a new [NotificationType], extend the enum + handle
///    [NotificationTypeX.parse] + register a route in
///    [NotificationRouter].
/// 3. Server starts including `"type": "<new_type>"` in the FCM
///    `data` payload.
class NotificationChannelsRegistry {
  const NotificationChannelsRegistry._();

  static const NotificationChannelConfig transactional =
      NotificationChannelConfig(
        id: 'transactional',
        type: NotificationType.transactional,
        defaultPriority: NotificationPriority.high,
        iosCategory: 'TRANSACTIONAL',
      );

  static const NotificationChannelConfig messages = NotificationChannelConfig(
    id: 'messages',
    type: NotificationType.message,
    defaultPriority: NotificationPriority.high,
    iosCategory: 'MESSAGE',
  );

  static const NotificationChannelConfig promo = NotificationChannelConfig(
    id: 'promo',
    type: NotificationType.promo,
    defaultPriority: NotificationPriority.low,
    sound: false,
    vibration: false,
    lights: false,
    iosCategory: 'PROMO',
  );

  static const NotificationChannelConfig system = NotificationChannelConfig(
    id: 'system',
    type: NotificationType.system,
    defaultPriority: NotificationPriority.max,
    iosCategory: 'SYSTEM',
  );

  static const NotificationChannelConfig general = NotificationChannelConfig(
    id: 'general',
    type: NotificationType.general,
    iosCategory: 'GENERAL',
  );

  /// All channels the app registers at startup.
  static const List<NotificationChannelConfig> all = [
    transactional,
    messages,
    promo,
    system,
    general,
  ];

  /// Lookup by [NotificationType]. Falls back to [general] when no
  /// dedicated channel exists for the type.
  static NotificationChannelConfig forType(NotificationType type) {
    for (final c in all) {
      if (c.type == type) return c;
    }
    return general;
  }

  /// Lookup by channel ID. Useful when routing from the notification
  /// plugin's tap response (which carries only the channel ID).
  static NotificationChannelConfig? byId(String id) {
    for (final c in all) {
      if (c.id == id) return c;
    }
    return null;
  }
}
