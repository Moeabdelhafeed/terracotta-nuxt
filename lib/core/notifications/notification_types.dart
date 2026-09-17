/// Category of notification. Drives channel selection (Android) +
/// category mapping (iOS) + router dispatch.
///
/// Extend this enum per your product's needs — each new case needs a
/// matching entry in [NotificationChannelsRegistry] and (usually) a
/// route handler registered with [NotificationRouter].
enum NotificationType {
  /// Order status changes, receipts, delivery updates — high-priority
  /// transactional signals the user expects to see.
  transactional,

  /// Chat / DM / mentions — high-priority personal messages.
  message,

  /// Marketing, promos, re-engagement — low-priority, easy to mute.
  promo,

  /// App updates, security alerts, critical infrastructure messages —
  /// highest priority, usually can't be muted.
  system,

  /// Fallback when the server didn't tell us the type — treated as
  /// default priority, no special routing.
  general,
}

/// Display priority. Maps to Android `Importance`/`Priority` and iOS
/// `interruptionLevel`. Set per notification, or inherited from the
/// channel/type default.
enum NotificationPriority {
  /// Silent, min importance. Android: IMPORTANCE_MIN. iOS: `passive`.
  low,

  /// Default — shows in shade, may or may not peek. Android:
  /// IMPORTANCE_DEFAULT.
  normal,

  /// Heads-up notification, sound by default. Android: IMPORTANCE_HIGH.
  /// iOS: `active`.
  high,

  /// Interrupts Do Not Disturb, strong presentation. Android:
  /// IMPORTANCE_MAX. iOS: `timeSensitive` (requires entitlement).
  max,
}

extension NotificationTypeX on NotificationType {
  /// Parse from a free-form string — usually comes from the FCM
  /// `data['type']` payload. Case-insensitive; unknown values fall
  /// back to [NotificationType.general].
  static NotificationType parse(String? raw) {
    if (raw == null) return NotificationType.general;
    return switch (raw.toLowerCase()) {
      'transactional' ||
      'transaction' ||
      'order' => NotificationType.transactional,
      'message' || 'chat' || 'dm' => NotificationType.message,
      'promo' || 'promotion' || 'marketing' => NotificationType.promo,
      'system' || 'alert' || 'security' => NotificationType.system,
      _ => NotificationType.general,
    };
  }

  /// Default priority for this type — individual notifications can
  /// override per [NotificationPayload.priority].
  NotificationPriority get defaultPriority => switch (this) {
    NotificationType.transactional => NotificationPriority.high,
    NotificationType.message => NotificationPriority.high,
    NotificationType.promo => NotificationPriority.low,
    NotificationType.system => NotificationPriority.max,
    NotificationType.general => NotificationPriority.normal,
  };
}
