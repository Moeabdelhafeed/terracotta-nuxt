import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/error/app_exception.dart';
import '../../../core/types/result.dart';
import '../../../data/api/calls/shop_apis.dart';
import '../../../data/models/terracotta/commerce/order.dart';

typedef OrdersFetch =
    AsyncResult<List<Order>> Function({
      int? perPage,
      int? page,
      CancelToken? cancelToken,
      Duration? timeout,
    });

/// «طلباتي» — the caller's own shop orders, newest first.
///
/// **[perPage] is never sent.** A numeric `per_page` swaps `data` for a
/// Laravel paginator and moves the rows to `data.data`, which the
/// list handler behind `getOrders` does not read — the same trap
/// `getProducts` carries. The whole history comes back in one array
/// instead, which is what this screen wants anyway.
@immutable
class OrdersState {
  const OrdersState({
    this.orders = const [],
    this.loading = true,
    this.error,
  });

  final List<Order> orders;

  /// The FIRST load, which has nothing to show.
  final bool loading;

  final AppException? error;

  bool get hasData => orders.isNotEmpty;

  /// Nothing to show and nothing went wrong — the customer has simply
  /// not bought anything. Told apart from a failure, because the two
  /// are different sentences.
  bool get isEmpty => orders.isEmpty && !loading;

  OrdersState copyWith({
    List<Order>? orders,
    bool? loading,
    AppException? error,
    bool clearError = false,
  }) => OrdersState(
    orders: orders ?? this.orders,
    loading: loading ?? this.loading,
    error: clearError ? null : error ?? this.error,
  );
}

class OrdersCubit extends Cubit<OrdersState> {
  OrdersCubit({OrdersFetch? fetch})
    : _fetch = fetch ?? ShopApis.getOrders,
      super(const OrdersState());

  final OrdersFetch _fetch;
  final _cancel = CancelToken();

  Future<void> load() async {
    emit(state.copyWith(loading: true, clearError: true));

    switch (await _fetch(cancelToken: _cancel)) {
      case Success(:final value):
        if (isClosed) return;
        emit(state.copyWith(orders: value, loading: false));
      case Failure(:final error):
        if (isClosed) return;
        // What is on screen STAYS. A failed refresh is not a reason to
        // blank a list the customer was reading.
        emit(state.copyWith(loading: false, error: error));
    }
  }

  /// A pull. Unconditional — an order may have moved since the last
  /// look, which is most of why anyone opens this screen.
  Future<void> refresh() => load();

  @override
  Future<void> close() {
    _cancel.cancel('orders closed');
    return super.close();
  }
}
