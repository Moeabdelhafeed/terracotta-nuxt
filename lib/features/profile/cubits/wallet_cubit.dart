import 'package:dio/dio.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/types/result.dart';
import '../../../data/api/calls/profile_apis.dart';
import '../../../data/models/terracotta/account/wallet_statement.dart';
import 'wallet_state.dart';

typedef WalletFetch =
    AsyncResult<WalletStatement> Function({
      int perPage,
      int? page,
      CancelToken? cancelToken,
    });

/// The customer's Terracotta balance.
///
/// ONE request, `GET /api/wallet/transactions`, which answers the
/// balance and the ledger together. Only the BALANCE is read here — the
/// wallet screen owns the rows, and `WalletTransaction`'s field names
/// are still unverified against a real one.
///
/// A `getIt` SINGLETON, like the other tab cubits: the profile tab is a
/// top-level route and `context.go` tears its `State` down, so a
/// page-owned cubit would re-request on every visit to a screen the
/// reader passes through constantly.
///
/// NOT `LocaleScopedLoad`, unlike every other tab cubit. That mixin
/// reloads when the language changes, which is right for copy the
/// SERVER translates and wrong for a decimal string: «150.00» reads the
/// same in both, so a language switch would buy a request and an
/// identical answer. [ensureLoaded] therefore takes no locale.
///
/// **The session already knows this number.** `POST /api/login` returns
/// `wallet_balance` on the user and `TerracottaUserMapping.toAppUser`
/// drops it. Reading it from there would be free but would go stale the
/// moment a booking spent any, and there is no `GET /api/profile` to
/// re-read it from — that route 404s. So it is fetched, and [refresh]
/// is what a pull on the profile page calls.
class WalletCubit extends Cubit<WalletState> {
  WalletCubit({WalletFetch? fetch})
    : _fetch = fetch ?? ProfileApis.getWalletTransactions,
      super(const WalletState());

  final WalletFetch _fetch;
  final _cancel = CancelToken();

  /// Whether there is a balance on screen to keep.
  bool get hasData => state.balance != null;

  /// The first load, and nothing after it.
  Future<void> ensureLoaded() => hasData ? Future.value() : load();

  /// The reader changed: a balance belongs to a person.
  ///
  /// A WHOLE new state, not a `copyWith` — `balance: null` there means
  /// "keep what you have", which is the one thing this must not do.
  /// The next `ensureLoaded` then asks, because `hasData` is false
  /// again. See `AccountScope`.
  void clear() => emit(const WalletState());

  Future<void> load() async {
    emit(state.copyWith(loading: true, clearError: true));

    // ONE row asked for, because the rows are not what this is for.
    // `per_page` goes out whatever the number: without it the server
    // answers the whole ledger as a bare array instead.
    final result = await _fetch(perPage: 1, cancelToken: _cancel);
    if (isClosed) return;

    switch (result) {
      case Success(:final value):
        emit(state.copyWith(balance: value.balance ?? '0.00', loading: false));
      case Failure(:final error):
        // The balance already on screen STAYS. A failed refresh is not
        // a reason to blank a number the customer was reading.
        emit(state.copyWith(loading: false, error: error));
    }
  }

  /// A pull on the profile page. Unconditional — a booking may have
  /// spent some since the last look.
  Future<void> refresh() => load();

  @override
  Future<void> close() {
    _cancel.cancel('wallet closed');
    return super.close();
  }
}
