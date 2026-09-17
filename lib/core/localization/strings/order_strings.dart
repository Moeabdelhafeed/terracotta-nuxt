import '../../../data/models/terracotta/commerce/order_status.dart';
import '../../../generated/l10n.dart';
import '../tr.dart';

/// «طلباتي» — a shop order, in the customer's words.
class OrderStrings {
  OrderStrings._();

  /// «طلب رقم ١٢». The id, never the database row said out loud.
  static String number(String id) =>
      Tr.t('order_number', S.current.order_number(id));

  static String placedOn(String date) =>
      Tr.t('order_placed_on', S.current.order_placed_on(date));

  /// The count and the unit pluralise TOGETHER — gluing a number to a
  /// fixed word gives «١ قطع», which is wrong in both languages.
  static String items(int count) =>
      Tr.t('order_items_count', S.current.order_items_count(count));

  /// Where the order got to.
  ///
  /// Mapped, never printed raw: the wire sends `awaiting_payment`,
  /// `pending`, `preparing`, `out_for_delivery`, `completed` and
  /// `cancelled`. A value this build does not know reads as "being
  /// processed" — which is the honest answer to the customer's actual
  /// question, and better than showing them a machine key.
  static String status(OrderStatus status) => switch (status) {
    OrderStatus.awaitingPayment => Tr.t(
      'order_status_awaiting_payment',
      S.current.order_status_awaiting_payment,
    ),
    OrderStatus.pending => Tr.t(
      'order_status_pending',
      S.current.order_status_pending,
    ),
    OrderStatus.preparing => Tr.t(
      'order_status_preparing',
      S.current.order_status_preparing,
    ),
    OrderStatus.outForDelivery => Tr.t(
      'order_status_out_for_delivery',
      S.current.order_status_out_for_delivery,
    ),
    OrderStatus.completed => Tr.t(
      'order_status_completed',
      S.current.order_status_completed,
    ),
    OrderStatus.cancelled => Tr.t(
      'order_status_cancelled',
      S.current.order_status_cancelled,
    ),
    OrderStatus.unknown => Tr.t(
      'order_status_unknown',
      S.current.order_status_unknown,
    ),
  };

  // ─── the detail page ──────────────────────────────────────

  static String get itemsHeading =>
      Tr.t('order_items_heading', S.current.order_items_heading);

  static String get deliveryHeading =>
      Tr.t('order_delivery_heading', S.current.order_delivery_heading);

  static String get deliveryTo =>
      Tr.t('order_delivery_to', S.current.order_delivery_to);

  static String get deliveryNotes =>
      Tr.t('order_delivery_notes', S.current.order_delivery_notes);

  static String get shortAddress =>
      Tr.t('order_short_address', S.current.order_short_address);

  /// «٢ × ٦٥ ريال» — the count and the UNIT price, so the line total
  /// beside it is checkable rather than asserted.
  static String quantity(int count, String price) =>
      Tr.t('order_quantity', S.current.order_quantity(count, price));

  static String get payNow => Tr.t('order_pay_now', S.current.order_pay_now);

  /// The hold on an unpaid order runs out. After that the server
  /// releases it and the wallet amount goes back.
  static String payBefore(String time) =>
      Tr.t('order_pay_before', S.current.order_pay_before(time));

  static String get cancel => Tr.t('order_cancel', S.current.order_cancel);

  static String get cancelTitle =>
      Tr.t('order_cancel_title', S.current.order_cancel_title);

  /// A cancel refunds to the WALLET, not the card — so the copy does
  /// not promise a card refund it cannot make.
  static String get cancelBody =>
      Tr.t('order_cancel_body', S.current.order_cancel_body);

  /// What actually came back, said AFTER the cancel rather than
  /// promised before it.
  ///
  /// **`refunded_amount`, as received.** The app has no business
  /// computing this: `null` there is not zero — it means nothing was
  /// ever paid, an abandoned `awaiting_payment` hold — and the two are
  /// different facts. The wire and the change note disagree about
  /// whether a paid order refunds the whole `total_price` or only the
  /// `wallet_applied` slice, which is exactly why this prints the
  /// server's own number and the sentence before it promises none.
  static String cancelRefunded(String amount) => Tr.t(
    'order_cancel_refunded',
    S.current.order_cancel_refunded(amount),
  );

  static String get cancelYes =>
      Tr.t('order_cancel_yes', S.current.order_cancel_yes);

  static String get cancelNo =>
      Tr.t('order_cancel_no', S.current.order_cancel_no);

  static String cancelledOn(String date) =>
      Tr.t('order_cancelled_on', S.current.order_cancelled_on(date));

  static String get notFound =>
      Tr.t('order_not_found', S.current.order_not_found);

  /// `amount_due` is `"0.00"` — the wallet or a full discount covered
  /// it, and there is nothing left to charge.
  static String get settled => Tr.t('order_settled', S.current.order_settled);

  // ─── «تم تأكيد طلبك !» ────────────────────────────────────
  //
  // The booking flow's celebration has a twin here. A shop payment
  // used to land straight on «طلباتي» with a list that looked no
  // different from the one before the money moved.

  static String get confirmedTitle =>
      Tr.t('order_confirmed_title', S.current.order_confirmed_title);

  static String get confirmedBody =>
      Tr.t('order_confirmed_body', S.current.order_confirmed_body);

  /// The one control on that screen.
  static String get track => Tr.t('order_track', S.current.order_track);
}
