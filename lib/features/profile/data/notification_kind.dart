import 'package:flutter/material.dart';

import '../../../core/extensions/theme_colors_extension.dart';
import '../../../data/models/terracotta/account/app_notification.dart';

/// How urgently a notification wants to be read.
///
/// This is the axis the inbox filters on, because it is the one the
/// reader actually has: "what needs me" against "what happened". The
/// CATEGORY — booking, order, wallet — is already in the words of every
/// row, and filtering by it would only re-say them.
enum NotificationTone {
  /// Something was lost, refused or ran out. Reads in the error ramp.
  urgent,

  /// Something is coming and the reader has to be somewhere. Amber.
  reminder,

  /// Something went right — booked, paid, delivered, credited.
  good,

  /// Everything else. The default for a `type` this app has not met.
  info,
}

/// What a notification IS, worked out from its `type`.
///
/// ## Why this matches on parts of the string
///
/// `type` is an OPEN set defined by the backend — see
/// [AppNotification]. Four were live on 2026-09-10
/// (`workshop_booking_confirmed`, `workshop_booking_cancelled`,
/// `workshop_booking_reminder`, `shop_order_confirmed`), the API docs
/// name a fifth (`shop_order_out_for_delivery`) and a sixth
/// (`gift_redeemed`), and the group's own description promises "order
/// and booking updates, session reminders, wallet and gift activity" —
/// so there are more the app has never seen, and a `switch` over exact
/// strings would meet each new one as a blank grey row.
///
/// So the PREFIX decides where a tap goes (`workshop_booking_*` opens a
/// booking, `shop_order_*` opens an order) and a keyword in the rest
/// decides the tone. A `workshop_booking_rescheduled` nobody has
/// written yet still lands on the booking it belongs to, with a sane
/// colour, on the day the backend ships it.
///
/// Nothing here reads [AppNotification.title] or [body]: those are
/// server-rendered prose in whatever language the account had at the
/// time, and matching on words would break the moment one is reworded.
@immutable
class NotificationKind {
  const NotificationKind({
    required this.tone,
    required this.icon,
    this.routeName,
    this.pathKey,
    this.dataKey,
  });

  final NotificationTone tone;
  final IconData icon;

  /// The route a tap opens, or null when there is nothing to open.
  final String? routeName;

  /// The path parameter that route asks for — `bookingId`, `orderId`.
  final String? pathKey;

  /// The key in [AppNotification.data] holding the id for it.
  final String? dataKey;

  /// The kind of one notification.
  factory NotificationKind.of(AppNotification n) {
    final type = n.type;
    final tone = _toneOf(type);

    if (type.startsWith('workshop_booking')) {
      return NotificationKind(
        tone: tone,
        icon: _bookingIcon(tone),
        routeName: 'booking-detail',
        pathKey: 'bookingId',
        dataKey: 'workshop_booking_id',
      );
    }
    if (type.startsWith('shop_order')) {
      return NotificationKind(
        tone: tone,
        icon: _orderIcon(tone),
        routeName: 'order-detail',
        pathKey: 'orderId',
        dataKey: 'shop_order_id',
      );
    }
    if (type.contains('gift')) {
      return NotificationKind(
        tone: tone,
        icon: Icons.card_giftcard_rounded,
        // The wallet, not a gift screen: a redeemed gift IS wallet
        // credit, and that is the page that proves it arrived.
        routeName: 'wallet',
      );
    }
    if (type.contains('wallet')) {
      return NotificationKind(
        tone: tone,
        icon: Icons.account_balance_wallet_rounded,
        routeName: 'wallet',
      );
    }

    return NotificationKind(tone: tone, icon: Icons.notifications_rounded);
  }

  /// The id this row opens, or null when it carries none.
  ///
  /// A routing miss returns null rather than throwing — a `data` bag
  /// that is absent, missing the key or holding something that is not
  /// an int must leave the row un-tappable, not crash the inbox.
  String? idIn(AppNotification n) {
    final key = dataKey;
    if (key == null) return null;
    return n.routeId(key)?.toString();
  }

  /// Whether a tap has somewhere to go.
  ///
  /// A route that takes no id (the wallet) is openable on its own; one
  /// that does needs the id to be there.
  bool opens(AppNotification n) =>
      routeName != null && (dataKey == null || idIn(n) != null);

  Color color(BuildContext context) => switch (tone) {
    NotificationTone.urgent => context.statusColors.error,
    NotificationTone.reminder => context.statusColors.warning,
    NotificationTone.good => context.statusColors.success,
    NotificationTone.info => context.statusColors.info,
  };

  /// Keyword, not exact match — see the class doc.
  static NotificationTone _toneOf(String type) {
    bool has(String word) => type.contains(word);

    if (has('cancel') ||
        has('fail') ||
        has('expire') ||
        has('overdue') ||
        has('reject') ||
        has('absent') ||
        has('refus')) {
      return NotificationTone.urgent;
    }
    if (has('remind') ||
        has('upcoming') ||
        has('soon') ||
        has('pending') ||
        has('awaiting') ||
        has('preparing')) {
      return NotificationTone.reminder;
    }
    if (has('confirm') ||
        has('complete') ||
        has('deliver') ||
        has('ready') ||
        has('redeem') ||
        has('credit') ||
        has('paid') ||
        has('received')) {
      return NotificationTone.good;
    }
    return NotificationTone.info;
  }

  static IconData _bookingIcon(NotificationTone tone) => switch (tone) {
    NotificationTone.urgent => Icons.event_busy_rounded,
    NotificationTone.reminder => Icons.alarm_rounded,
    NotificationTone.good => Icons.event_available_rounded,
    NotificationTone.info => Icons.event_note_rounded,
  };

  static IconData _orderIcon(NotificationTone tone) => switch (tone) {
    NotificationTone.urgent => Icons.remove_shopping_cart_rounded,
    NotificationTone.reminder => Icons.inventory_2_rounded,
    NotificationTone.good => Icons.local_shipping_rounded,
    NotificationTone.info => Icons.receipt_long_rounded,
  };
}
