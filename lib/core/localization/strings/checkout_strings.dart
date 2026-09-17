import '../../../generated/l10n.dart';
import '../tr.dart';

/// Checkout — the quote breakdown shared by booking, shop, delivery and gift. VAT is INCLUSIVE: vatAmount is contained in total.
class CheckoutStrings {
  CheckoutStrings._();

  static String get title => Tr.t('checkout_title', S.current.checkout_title);

  static String get confirmAndPay =>
      Tr.t('checkout_confirm_and_pay', S.current.checkout_confirm_and_pay);

  static String get subtotal =>
      Tr.t('checkout_subtotal', S.current.checkout_subtotal);

  static String get discount =>
      Tr.t('checkout_discount', S.current.checkout_discount);

  static String get deliveryFee =>
      Tr.t('checkout_delivery_fee', S.current.checkout_delivery_fee);

  static String vat(String rate) =>
      Tr.t('checkout_vat', S.current.checkout_vat(rate));

  static String get total => Tr.t('checkout_total', S.current.checkout_total);

  static String get walletApplied =>
      Tr.t('checkout_wallet_applied', S.current.checkout_wallet_applied);

  static String get amountDue =>
      Tr.t('checkout_amount_due', S.current.checkout_amount_due);

  static String get alreadySettled =>
      Tr.t('checkout_already_settled', S.current.checkout_already_settled);

  static String get discountCode =>
      Tr.t('checkout_discount_code', S.current.checkout_discount_code);

  /// An EXAMPLE, and the spec's own — never the field's name, which is
  /// already the header above the box.
  static String get discountCodeHint => Tr.t(
    'checkout_discount_code_hint',
    S.current.checkout_discount_code_hint,
  );

  static String get apply => Tr.t('checkout_apply', S.current.checkout_apply);

  /// «مجاني» — a delivery fee of `"0.00"`.
  ///
  /// The zero is a real answer, not a missing one: the order cleared
  /// the studio's free-delivery threshold. Printing «٠ ريال» there
  /// makes the reader do the reading twice to learn they are not being
  /// charged.
  static String get free => Tr.t('checkout_free', S.current.checkout_free);

  /// «خصم ١٠٪» — what a percent code takes off.
  static String codeOffPercent(String value) => Tr.t(
    'checkout_code_off_percent',
    S.current.checkout_code_off_percent(value),
  );

  /// «خصم ٤٠ ريال» — what a fixed code takes off. [amount] arrives
  /// already priced, currency and all.
  static String codeOffFixed(String amount) => Tr.t(
    'checkout_code_off_fixed',
    S.current.checkout_code_off_fixed(amount),
  );

  /// «للطلبات فوق ٥٠٠ ريال» — the floor a code needs before it works.
  static String codeMinOrder(String amount) => Tr.t(
    'checkout_code_min_order',
    S.current.checkout_code_min_order(amount),
  );

  /// «ورشة صناعة كوبك من ٢ اشخاص» — the workshop's own line on the
  /// summary. NOT «اختر موعد», which is the heading of the screen
  /// before this one and says nothing about what is being paid for.
  static String workshopLine(String title, String people) => Tr.t(
    'checkout_workshop_line',
    S.current.checkout_workshop_line(title, people),
  );

  /// The wallet toggle.
  ///
  /// `use_wallet` on the quote is a BOOLEAN: the customer chooses
  /// WHETHER to spend their balance, not how much of it. The server
  /// applies as much as the booking costs and returns what it took —
  /// so a balance smaller than the total covers part of it and the
  /// rest is charged, with no arithmetic on this side.
  static String get useWallet =>
      Tr.t('checkout_use_wallet', S.current.checkout_use_wallet);

  static String walletCovers(String amount) =>
      Tr.t('checkout_wallet_covers', S.current.checkout_wallet_covers(amount));

  static String get leftToPay =>
      Tr.t('checkout_left_to_pay', S.current.checkout_left_to_pay);

  static String get payMethod =>
      Tr.t('checkout_pay_method', S.current.checkout_pay_method);

  /// ONE OPEN ORDER AT A TIME. `POST /api/shop/cart/checkout` refuses a
  /// second while one is still awaiting payment, and no retry of the
  /// checkout screen can satisfy it — the way out is the order that is
  /// already open, which is what [openOrderAction] offers.
  static String get openOrder =>
      Tr.t('checkout_open_order', S.current.checkout_open_order);

  static String get openOrderAction => Tr.t(
    'checkout_open_order_action',
    S.current.checkout_open_order_action,
  );

  /// `PAYMENT_HOLD_MINUTES` ran out. The seat, the wallet amount and
  /// the discount code's use all went back, so there is nothing to
  /// retry — the customer starts again.
  static String get holdExpired =>
      Tr.t('checkout_hold_expired', S.current.checkout_hold_expired);

  /// Said UNDER the address row as well as in a toast. A toast names
  /// the problem and then goes away; the row is where the problem is.
  static String get addressRequired => Tr.t(
    'checkout_address_required',
    S.current.checkout_address_required,
  );
}
