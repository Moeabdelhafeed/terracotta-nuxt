import 'package:flutter/material.dart';

import '../../../core/notifications/notification_payload.dart';
import '../../../core/notifications/notification_types.dart';
import '../../../core/notifications/notifications.dart';
import '../../module/avatar/global_avatar.dart';
import '../../module/toast/global_toast.dart';

/// Shows a [NotificationPayload] as a toast, shaped by what KIND of
/// notification it is.
///
/// ## Why this is not in the toast module
///
/// It needs `NotificationPayload` and the `Notifications` facade —
/// domain knowledge a generic UI primitive has no business holding.
/// The module stays a way to show a message; this knows what a message
/// MEANS.
///
/// ## What it fixes
///
/// The in-app display used `title` and `body` and dropped the rest, so
/// a notification toast could not be opened (`deepLink` unused,
/// `Notifications.reportTap` never called), showed no image, and
/// carried no timestamp. It also mapped CATEGORY onto SEVERITY —
/// `system` rendered in error red whether it was a security alert or an
/// app-update notice, and a direct message rendered as "info", which a
/// direct message is not.
///
/// Category decides the shape; severity is a separate question that
/// only `system` and `transactional` actually answer.
class NotificationToast {
  const NotificationToast._();

  /// Shows [payload]. Tapping routes exactly as an OS notification tap
  /// would, through [Notifications.reportTap].
  static ToastHandle? show(NotificationPayload payload) {
    final shape = _shapeFor(payload.type);

    return GlobalToast.show(
      title: payload.title,
      description: payload.body,
      type: shape.severity,
      style: shape.variant,
      position: shape.position,
      duration: shape.duration,
      persistent: shape.persistent,
      showProgressBar: shape.persistent,
      icon: _leading(payload, shape),
      // The whole point: an in-app notification now opens what it is
      // about, instead of being a message the user cannot act on.
      onTap: () => Notifications.reportTap(payload),
      enableHaptic: shape.haptic,
    );
  }

  /// Avatar for a person, glyph for everything else.
  ///
  /// A message is FROM someone, and a face is how a reader tells one
  /// conversation from another at a glance — a severity icon on a DM
  /// says only "a notification happened".
  static Widget? _leading(NotificationPayload payload, _Shape shape) {
    if (shape.avatar && payload.image != null) {
      return GlobalAvatar(
        imageUrl: payload.image,
        name: payload.title,
        size: kNotificationToastAvatarSize,
      );
    }
    return null;
  }

  static _Shape _shapeFor(NotificationType type) => switch (type) {
    // Someone is talking to you. Personal, worth a nudge, and the
    // avatar is the point.
    NotificationType.message => const _Shape(
      severity: ToastType.info,
      variant: ToastVariant.filled,
      avatar: true,
      haptic: true,
    ),

    // Receipts, shipping, status. Genuinely a success signal, and long
    // enough to read an order number.
    NotificationType.transactional => const _Shape(
      severity: ToastType.success,
      variant: ToastVariant.vivid,
    ),

    // Security alerts and forced updates. Stays until acknowledged:
    // this is the one category where expiring unread is a failure, not
    // a convenience.
    NotificationType.system => const _Shape(
      severity: ToastType.warning,
      variant: ToastVariant.vivid,
      position: ToastPosition.top,
      persistent: true,
      haptic: true,
    ),

    // Marketing. Quiet by construction — a surface variant rather than
    // a saturated fill, and never a haptic; nothing here has earned a
    // buzz in someone's hand.
    NotificationType.promo => const _Shape(
      severity: ToastType.info,
      variant: ToastVariant.flat,
      duration: kNotificationToastPromoDuration,
    ),

    // The server did not say. Treat it as ordinary.
    NotificationType.general => const _Shape(
      severity: ToastType.info,
      variant: ToastVariant.filled,
    ),
  };
}

/// Size of the sender avatar on a message toast.
const kNotificationToastAvatarSize = 32.0;

/// Promos get the shortest useful window — the reader did not ask.
const kNotificationToastPromoDuration = Duration(seconds: 3);

/// How one category of notification presents itself.
@immutable
class _Shape {
  const _Shape({
    required this.severity,
    required this.variant,
    this.position = ToastPosition.bottom,
    this.duration,
    this.persistent = false,
    this.avatar = false,
    this.haptic = false,
  });

  final ToastType severity;
  final ToastVariant variant;
  final ToastPosition position;

  /// Null lets the toast size its own window to the text length.
  final Duration? duration;

  final bool persistent;
  final bool avatar;
  final bool haptic;
}
