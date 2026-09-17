// Package imports:
import 'package:freezed_annotation/freezed_annotation.dart';

part 'wallet_transaction.freezed.dart';
part 'wallet_transaction.g.dart';

/// One row of the store-credit ledger —
/// `GET /api/wallet/transactions` → `data.transactions[]`.
///
/// The response wraps the list next to the current `balance`:
/// `{"balance": "0.00", "transactions": [...]}`. Newest first. Credits
/// are refunds, gifts and admin top-ups; debits are booking payments
/// and delivery fees.
///
/// **The shape is the SPEC's, not a live capture.** The dev account had
/// never transacted, so `transactions` came back `[]` and not one field
/// below has been seen on the wire. The names here are the ones the
/// server's own source defines — `{id, type, amount, reason,
/// workshop_booking_id, shop_order_id, balance_after, created_at}` —
/// and `test/terracotta/unverified_models_test.dart` pins them to that
/// contract. Everything but [id] stays nullable: a row that loses a
/// field must not take the wallet screen down with it.
///
/// **[amount] and [balanceAfter] ARE DECIMAL STRINGS** (`"15.00"`) like
/// every other monetary value in this API. Never doubles.
///
/// [balanceAfter] is the running balance immediately AFTER this row, so
/// the ledger reconstructs itself — never sum [amount] client-side to
/// derive a balance, and never sum it to check the wallet total against
/// `data.balance`.
///
/// [workshopBookingId] and [shopOrderId] are the tap targets: exactly
/// one of them is set on a transaction that came from an order, and
/// both are null on an admin top-up.
@freezed
abstract class WalletTransaction with _$WalletTransaction {
  const factory WalletTransaction({
    required int id,

    /// `"credit"` or `"debit"`. Read via [kind].
    String? type,

    /// Absolute value moved, as a DECIMAL STRING. The direction is in
    /// [type], not in a minus sign.
    String? amount,

    /// Why it moved (`"delivery_fee"`, `"booking_cancelled"`). An open,
    /// server-defined set — do not switch on it exhaustively.
    String? reason,

    /// Booking this row settled, when it came from one.
    int? workshopBookingId,

    /// Shop order this row settled, when it came from one.
    int? shopOrderId,

    /// Running balance right after this row, as a DECIMAL STRING.
    String? balanceAfter,

    DateTime? createdAt,
  }) = _WalletTransaction;

  const WalletTransaction._();

  factory WalletTransaction.fromJson(Map<String, dynamic> json) =>
      _$WalletTransactionFromJson(json);

  /// [type] resolved. Unknown or missing directions come back as
  /// [WalletTransactionKind.unknown] — render those neutrally rather
  /// than guessing a sign.
  WalletTransactionKind get kind => WalletTransactionKind.fromWire(type);
}

/// Which way the money moved on a wallet row.
enum WalletTransactionKind {
  /// Money INTO the wallet: refund, gift, admin top-up.
  credit('credit'),

  /// Money OUT of the wallet: booking payment, delivery fee.
  debit('debit'),

  /// A direction this build does not recognise, or a row that carried
  /// no `type` at all. Render the amount unsigned rather than picking a
  /// sign at random.
  unknown('unknown');

  const WalletTransactionKind(this.wire);

  /// The `type` value as it arrives from the API.
  final String wire;

  /// Resolves a wire value, falling back to [unknown] rather than
  /// throwing — the ledger has never been captured live, so a value
  /// outside this set is entirely possible and must not crash the
  /// wallet screen.
  static WalletTransactionKind fromWire(String? value) =>
      values.firstWhere((k) => k.wire == value, orElse: () => unknown);
}
