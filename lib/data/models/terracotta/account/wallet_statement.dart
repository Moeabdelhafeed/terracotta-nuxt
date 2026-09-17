import 'package:freezed_annotation/freezed_annotation.dart';

import '../core/paginated_rows.dart';
import 'wallet_transaction.dart';

part 'wallet_statement.freezed.dart';
part 'wallet_statement.g.dart';

/// `GET /api/wallet/transactions` — the balance and the ledger behind
/// it, in one call.
///
/// The payload is `{"balance": "0.00", "transactions": ...}`, and
/// `transactions` arrives in TWO shapes depending on what was asked
/// for — verified live on 2026-08-30:
///
///   * no `per_page` → a bare JSON array
///   * `per_page=20` → a LARAVEL PAGINATOR, rows at `transactions.data`
///
/// `ProfileApis.getWalletTransactions` always sends `per_page`, so the
/// paginator is the shape the app actually receives — and declared as a
/// list alone it threw `type '_Map<String, dynamic>' is not a subtype
/// of type 'List<dynamic>?'` inside `fromJson`, taking the BALANCE down
/// with it. [_readTransactions] reads either.
///
/// [balance] is a DECIMAL STRING like every other money field. It is
/// the authoritative figure — the checkout screens show it as
/// `رصيد تيراكوتا` and must not recompute it by summing the ledger,
/// which may be paginated.
///
/// [WalletTransaction]'s row shape is the SPEC's rather than a live
/// capture — see that class and
/// `test/terracotta/unverified_models_test.dart`.
@freezed
abstract class WalletStatement with _$WalletStatement {
  const factory WalletStatement({
    /// Decimal string, e.g. `"150.00"`.
    String? balance,
    @JsonKey(fromJson: _readTransactions)
    @Default(<WalletTransaction>[])
    List<WalletTransaction> transactions,
  }) = _WalletStatement;

  const WalletStatement._();

  factory WalletStatement.fromJson(Map<String, dynamic> json) =>
      _$WalletStatementFromJson(json);

  bool get hasCredit => (balance ?? '0.00') != '0.00';
}

List<WalletTransaction> _readTransactions(Object? json) =>
    readPaginatedRows(json, WalletTransaction.fromJson);
