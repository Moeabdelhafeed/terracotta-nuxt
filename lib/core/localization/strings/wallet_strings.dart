import '../../../generated/l10n.dart';
import '../tr.dart';

/// «محفظتي» — the balance and the ledger behind it.
class WalletStrings {
  WalletStrings._();

  static String get emptyBody =>
      Tr.t('wallet_empty_body', S.current.wallet_empty_body);

  /// What a row SAYS, from its machine `reason`.
  ///
  /// The set is CLOSED and the server names every member —
  /// `WalletTransaction`'s own constants: `booking_payment`,
  /// `booking_cancelled`, `booking_rescheduled`, `booking_absent`,
  /// `booking_partial_no_show`, `delivery_fee`, `shop_order_payment`,
  /// `shop_order_cancelled`, `gift_purchase`, `gift_redeemed`,
  /// `admin_adjustment`.
  ///
  /// Two of them are written by nothing today — `booking_absent` and
  /// `booking_partial_no_show` are constants the refund rules stopped
  /// using, because a no-show is never refunded. They are mapped
  /// anyway: a row that does appear must not read as a machine key.
  ///
  /// The fallback stays for a key added after this build ships: a row
  /// saying «اضافة الى الرصيد» is still true, where a raw
  /// `some_new_reason` on screen is a bug the customer has to read.
  static String reason(String? reason, {required bool isCredit}) =>
      switch (reason) {
        'delivery_fee' => Tr.t(
          'wallet_reason_delivery_fee',
          S.current.wallet_reason_delivery_fee,
        ),
        'booking_cancelled' => Tr.t(
          'wallet_reason_booking_cancelled',
          S.current.wallet_reason_booking_cancelled,
        ),
        'booking_payment' => Tr.t(
          'wallet_reason_booking_payment',
          S.current.wallet_reason_booking_payment,
        ),
        'booking_rescheduled' => Tr.t(
          'wallet_reason_booking_rescheduled',
          S.current.wallet_reason_booking_rescheduled,
        ),
        // The refund rules no longer write these two, and a no-show is
        // never refunded — but the constants exist, so an old row can.
        'booking_absent' || 'booking_partial_no_show' => Tr.t(
          'wallet_reason_booking_absent',
          S.current.wallet_reason_booking_absent,
        ),
        'shop_order_payment' => Tr.t(
          'wallet_reason_order_payment',
          S.current.wallet_reason_order_payment,
        ),
        'shop_order_cancelled' => Tr.t(
          'wallet_reason_shop_order_cancelled',
          S.current.wallet_reason_shop_order_cancelled,
        ),
        'gift_purchase' => Tr.t(
          'wallet_reason_gift_purchase',
          S.current.wallet_reason_gift_purchase,
        ),
        'gift_redeemed' => Tr.t(
          'wallet_reason_gift',
          S.current.wallet_reason_gift,
        ),
        'admin_adjustment' => Tr.t(
          'wallet_reason_admin_adjustment',
          S.current.wallet_reason_admin_adjustment,
        ),
        _ => isCredit ? credit : debit,
      };

  static String get credit => Tr.t('wallet_credit', S.current.wallet_credit);

  static String get debit => Tr.t('wallet_debit', S.current.wallet_debit);

  /// The running balance the row left behind — the server sends it, so
  /// the ledger never has to be summed to show it.
  static String balanceAfter(String amount) =>
      Tr.t('wallet_balance_after', S.current.wallet_balance_after(amount));
}
