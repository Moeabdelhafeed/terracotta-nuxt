import 'package:dio/dio.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/types/result.dart';
import '../../../data/api/calls/profile_apis.dart';
import 'wallet_cubit.dart';
import 'wallet_ledger_state.dart';

/// The store-credit ledger — `GET /api/wallet/transactions`.
///
/// ONE request answers the balance and the rows together, so the page
/// never has to ask twice or reconcile two numbers.
///
/// PAGE-OWNED, unlike [WalletCubit]. That one is a `getIt` singleton
/// asking for a single row, because the only thing the checkout screens
/// want from the wallet is the balance; this one wants the ledger and
/// dies with the screen showing it.
///
/// **`balance_after` is on every row**, which is what makes the ledger
/// independently reconstructable — the client never sums [amount] to
/// derive a balance, and the spec says so outright.
class WalletLedgerCubit extends Cubit<WalletLedgerState> {
  WalletLedgerCubit({WalletFetch? fetch})
    : _fetch = fetch ?? ProfileApis.getWalletTransactions,
      super(const WalletLedgerState());

  final WalletFetch _fetch;
  final _cancel = CancelToken();

  /// How many rows a page holds. The request MUST carry `per_page`
  /// whatever the number: without it the server answers the whole
  /// ledger as a bare array instead of a paginator.
  static const pageSize = 20;

  Future<void> load() async {
    emit(state.copyWith(loading: true, clearError: true));

    switch (await _fetch(perPage: pageSize, page: 1, cancelToken: _cancel)) {
      case Success(:final value):
        if (isClosed) return;
        emit(
          state.copyWith(
            balance: value.balance ?? '0.00',
            rows: value.transactions,
            page: 1,
            atEnd: value.transactions.length < pageSize,
            loading: false,
          ),
        );
      case Failure(:final error):
        if (isClosed) return;
        // What is already on screen STAYS. A failed refresh is not a
        // reason to blank a ledger the customer was reading.
        emit(state.copyWith(loading: false, error: error));
    }
  }

  /// The next page, appended.
  ///
  /// Refused while one is already in flight, and once the server has
  /// answered short — a ledger that keeps asking past its end spends a
  /// request per scroll for nothing.
  Future<void> loadMore() async {
    if (state.loadingMore || state.atEnd || state.loading) return;
    emit(state.copyWith(loadingMore: true));

    final next = state.page + 1;
    switch (await _fetch(perPage: pageSize, page: next, cancelToken: _cancel)) {
      case Success(:final value):
        if (isClosed) return;
        emit(
          state.copyWith(
            rows: [...state.rows, ...value.transactions],
            page: next,
            atEnd: value.transactions.length < pageSize,
            loadingMore: false,
          ),
        );
      case Failure(:final error):
        if (isClosed) return;
        emit(state.copyWith(loadingMore: false, error: error));
    }
  }

  /// A pull on the page. Unconditional — a booking may have spent some
  /// since the last look.
  Future<void> refresh() => load();

  @override
  Future<void> close() {
    _cancel.cancel('wallet ledger closed');
    return super.close();
  }
}
