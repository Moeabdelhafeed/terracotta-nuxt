import 'package:flutter/foundation.dart';

import '../../../core/error/app_exception.dart';
import '../../../data/models/terracotta/account/wallet_transaction.dart';

/// «محفظتي» — the balance and every row behind it.
///
/// Separate from `WalletState`, which the app-wide singleton keeps: that
/// one asks for a single row because all it wants is the balance for
/// the two checkout screens. This is the LEDGER, and it is page-owned.
@immutable
class WalletLedgerState {
  const WalletLedgerState({
    this.balance,
    this.rows = const [],
    this.loading = true,
    this.loadingMore = false,
    this.atEnd = false,
    this.page = 1,
    this.error,
  });

  /// A DECIMAL STRING (`"150.00"`), exactly as the server sent it.
  ///
  /// The AUTHORITATIVE figure. Never recomputed by summing [rows] —
  /// they are paginated, so the sum of what is loaded is not the
  /// balance.
  final String? balance;

  /// Newest first, as the server orders them.
  final List<WalletTransaction> rows;

  /// The FIRST load, which has nothing to show.
  final bool loading;

  /// A later page, which has the rows above it to keep.
  final bool loadingMore;

  /// Whether the last page came back short — there is nothing more to
  /// ask for.
  final bool atEnd;

  /// The last page asked for.
  final int page;

  final AppException? error;

  /// Whether there is anything on screen worth keeping through a
  /// failure.
  bool get hasData => balance != null;

  /// Whether the ledger is genuinely empty, as opposed to not loaded.
  bool get isEmpty => !loading && error == null && rows.isEmpty;

  WalletLedgerState copyWith({
    String? balance,
    List<WalletTransaction>? rows,
    bool? loading,
    bool? loadingMore,
    bool? atEnd,
    int? page,
    AppException? error,
    bool clearError = false,
  }) => WalletLedgerState(
    balance: balance ?? this.balance,
    rows: rows ?? this.rows,
    loading: loading ?? this.loading,
    loadingMore: loadingMore ?? this.loadingMore,
    atEnd: atEnd ?? this.atEnd,
    page: page ?? this.page,
    error: clearError ? null : error ?? this.error,
  );
}
