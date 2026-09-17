import '../../../generated/l10n.dart';
import '../tr.dart';
import 'booking_strings.dart';

/// After the piece is fired — pickup or delivery, and the hold deadline.
class DeliveryStrings {
  DeliveryStrings._();

  static String get pieceReady =>
      Tr.t('delivery_piece_ready', S.current.delivery_piece_ready);

  static String get pieceReadyBody =>
      Tr.t('delivery_piece_ready_body', S.current.delivery_piece_ready_body);

  static String get deliver =>
      Tr.t('delivery_deliver', S.current.delivery_deliver);

  static String get pickup =>
      Tr.t('delivery_pickup', S.current.delivery_pickup);

  static String get paintIt =>
      Tr.t('delivery_paint_it', S.current.delivery_paint_it);

  /// Asked only when `paintable_at` names MORE THAN ONE workshop. The
  /// studio may run several sessions that take an own piece, and the
  /// server is the one that knows which — this app used to pick the
  /// first `paint_your_piece` in the catalogue and hope.
  static String get paintPickTitle => Tr.t(
    'delivery_paint_pick_title',
    S.current.delivery_paint_pick_title,
  );

  static String get phone => Tr.t('delivery_phone', S.current.delivery_phone);

  static String get warningTitle =>
      Tr.t('delivery_warning_title', S.current.delivery_warning_title);

  /// The hold window, in the biggest units still true — the studio
  /// keeps a piece for a fixed number of DAYS, but on the last one
  /// «٠ أيام» would read as "already gone" instead of "today".
  static String warningBody(int hours) => Tr.t(
    'delivery_warning_body',
    S.current.delivery_warning_body(BookingStrings.daysAndHours(hours)),
  );

  static String get feeLine =>
      Tr.t('delivery_fee_line', S.current.delivery_fee_line);

  static String get confirmAndPay =>
      Tr.t('delivery_confirm_and_pay', S.current.delivery_confirm_and_pay);

  static String get close => Tr.t('delivery_close', S.current.delivery_close);

  /// The handover leg's own status, as a word.
  ///
  /// A booking on this leg reads `completed` on its own `status` the
  /// whole way through — packing, on the road and delivered are three
  /// screens and ONE booking status. So the card shows THIS when there
  /// is one, and the booking status only when there is not.
  ///
  /// An unmodelled value draws NOTHING rather than printing
  /// `getting_ready` at a customer.
  static String? status(String wire) => switch (wire) {
    'awaiting_pickup' => Tr.t(
      'delivery_status_awaiting_pickup',
      S.current.delivery_status_awaiting_pickup,
    ),
    'getting_ready' => Tr.t(
      'delivery_status_getting_ready',
      S.current.delivery_status_getting_ready,
    ),
    'on_the_way' => Tr.t(
      'delivery_status_on_the_way',
      S.current.delivery_status_on_the_way,
    ),
    'completed' => Tr.t(
      'delivery_status_completed',
      S.current.delivery_status_completed,
    ),
    _ => null,
  };

  /// Choosing HOW a finished piece leaves the studio.
  ///
  /// Re-choosable right up until `delivery_status` reaches
  /// `completed` — the spec says so outright — so neither choice is
  /// ever phrased as final.
  static String get pickupConfirmTitle => Tr.t(
    'delivery_pickup_confirm_title',
    S.current.delivery_pickup_confirm_title,
  );
  static String get pickupConfirmBody => Tr.t(
    'delivery_pickup_confirm_body',
    S.current.delivery_pickup_confirm_body,
  );

  /// The same line when there IS money coming back, with the amount
  /// in it.
  ///
  /// **[amount] is `delivery_fee_wallet_applied`, never
  /// `delivery_fee`.** Choosing delivery only ever debits the WALLET
  /// slice — the remainder stays outstanding and nothing collects it —
  /// so a 50 fee against an empty wallet refunds nothing, and a screen
  /// promising 50 is a screen that lies to the customer who can least
  /// afford it. The plain body above is what they see instead.
  ///
  /// And it is CREDIT, not a refund to a card. Saying so here is the
  /// difference between a customer who knows where their money is and
  /// one who opens a dispute.
  static String pickupConfirmBodyRefund(String amount) => Tr.t(
    'delivery_pickup_confirm_body_refund',
    S.current.delivery_pickup_confirm_body_refund(amount),
  );

  static String pickupCredited(String amount) => Tr.t(
    'delivery_pickup_credited',
    S.current.delivery_pickup_credited(amount),
  );

  static String get pickupDone =>
      Tr.t('delivery_pickup_done', S.current.delivery_pickup_done);
  static String get pickupConfirmYes => Tr.t(
    'delivery_pickup_confirm_yes',
    S.current.delivery_pickup_confirm_yes,
  );

  static String get chosePickup =>
      Tr.t('delivery_chose_pickup', S.current.delivery_chose_pickup);
  static String get choseDelivery =>
      Tr.t('delivery_chose_delivery', S.current.delivery_chose_delivery);

  /// The OTHER option, once one is picked — worded as a switch rather
  /// than as a fresh choice, because that is what it is.
  static String get switchToDelivery => Tr.t(
    'delivery_switch_to_delivery',
    S.current.delivery_switch_to_delivery,
  );
  static String get switchToPickup => Tr.t(
    'delivery_switch_to_pickup',
    S.current.delivery_switch_to_pickup,
  );

  static String get whereTitle =>
      Tr.t('delivery_where_title', S.current.delivery_where_title);
  static String get changeAddress =>
      Tr.t('delivery_change_address', S.current.delivery_change_address);
  static String get addAddress =>
      Tr.t('delivery_add_address', S.current.delivery_add_address);
  static String get noAddress =>
      Tr.t('delivery_no_address', S.current.delivery_no_address);
  static String get continueToPayment =>
      Tr.t('delivery_continue', S.current.delivery_continue);
}
