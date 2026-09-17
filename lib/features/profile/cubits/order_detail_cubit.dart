import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/error/app_exception.dart';
import '../../../core/types/result.dart';
import '../../../data/api/calls/shop_apis.dart';
import '../../../data/models/terracotta/commerce/order.dart';

typedef OrderFetch =
    AsyncResult<Order> Function(
      String orderId, {
      CancelToken? cancelToken,
      Duration? timeout,
    });

typedef OrderCancel =
    AsyncResult<Order> Function(
      String orderId, {
      CancelToken? cancelToken,
      Duration? timeout,
    });

typedef OrderPay =
    AsyncResult<Map<String, dynamic>> Function(
      String orderId, {
      CancelToken? cancelToken,
      Duration? timeout,
    });

/// One shop order — `GET /api/shop/orders/{order}`.
///
/// Two things can be done to it from here, and the SERVER decides which:
///
///   * **Pay**, while it is `awaiting_payment`. The hold runs out at
///     `payment_expires_at`, after which the server releases the order
///     and gives the wallet amount and the discount code's use back.
///     Skipped entirely when `amount_due` is `"0.00"` — the wallet or a
///     full discount already covered it, and paying zero is an error.
///   * **Cancel**, while [Order.canCancel] says so. That flag is
///     authoritative; deriving it from the status second-guesses a
///     window only the server knows. A cancel refunds to the WALLET,
///     never the card.
@immutable
class OrderDetailState {
  const OrderDetailState({
    this.order,
    this.loading = true,
    this.working = false,
    this.error,
  });

  final Order? order;

  /// The FIRST load, which has nothing to show.
  final bool loading;

  /// A pay or a cancel is in flight. Both are one press to the
  /// customer, and both must not be pressed twice.
  final bool working;

  final AppException? error;

  bool get hasData => order != null;

  /// Whether the pay CTA belongs on screen.
  ///
  /// Both halves: the server says it is still awaiting payment, AND
  /// there is something left to charge.
  bool get canPay =>
      order != null && order!.status.needsPayment && !order!.isAlreadySettled;

  /// The server's own verdict, never derived from the status.
  bool get canCancel => order?.canCancel ?? false;

  OrderDetailState copyWith({
    Order? order,
    bool? loading,
    bool? working,
    AppException? error,
    bool clearError = false,
  }) => OrderDetailState(
    order: order ?? this.order,
    loading: loading ?? this.loading,
    working: working ?? this.working,
    error: clearError ? null : error ?? this.error,
  );
}

class OrderDetailCubit extends Cubit<OrderDetailState> {
  OrderDetailCubit({
    required this.orderId,
    OrderFetch? fetch,
    OrderCancel? cancelOrder,
    OrderPay? pay,
  }) : _fetch = fetch ?? ShopApis.getOrder,
       _cancelOrder = cancelOrder ?? ShopApis.cancelOrder,
       _pay = pay ?? ShopApis.payOrder,
       super(const OrderDetailState());

  final String orderId;

  final OrderFetch _fetch;
  final OrderCancel _cancelOrder;
  final OrderPay _pay;
  final _cancel = CancelToken();

  Future<void> load() async {
    emit(state.copyWith(loading: true, clearError: true));

    switch (await _fetch(orderId, cancelToken: _cancel)) {
      case Success(:final value):
        if (isClosed) return;
        emit(state.copyWith(order: value, loading: false));
      case Failure(:final error):
        if (isClosed) return;
        // What is on screen STAYS. A failed refresh is not a reason to
        // blank an order the customer was reading.
        emit(state.copyWith(loading: false, error: error));
    }
  }

  Future<void> refresh() => load();

  /// Settle it. Answers whether it went.
  ///
  /// The pay call is IDEMPOTENT — a retry after a dropped response must
  /// not double-charge — so a resend is the correct recovery. The order
  /// is re-read afterwards rather than patched here: the server owns
  /// `payment_status`, and guessing it would put a stale word on screen
  /// the moment the studio changed the vocabulary.
  Future<bool> pay() async {
    final order = state.order;
    if (state.working || order == null) return false;

    // Nothing left to charge. The wallet or a full discount covered it,
    // and posting a payment for zero either 422s or opens a sheet for
    // nothing.
    if (order.isAlreadySettled) return true;

    emit(state.copyWith(working: true, clearError: true));

    switch (await _pay('${order.id}', cancelToken: _cancel)) {
      case Success():
        if (isClosed) return false;
        emit(state.copyWith(working: false));
        await load();
        return true;
      case Failure(:final error):
        if (isClosed) return false;
        emit(state.copyWith(working: false, error: error));
        return false;
    }
  }

  /// Cancel it. Answers whether it went.
  ///
  /// `DELETE /api/shop/orders/{order}` — written as DELETE and rewritten
  /// to POST with `X-HTTP-Method-Override` by the interceptor, because
  /// production blocks the verb.
  ///
  /// The answer IS the cancelled order, so nothing re-reads it.
  Future<bool> cancel() async {
    final order = state.order;
    if (state.working || order == null) return false;
    emit(state.copyWith(working: true, clearError: true));

    switch (await _cancelOrder('${order.id}', cancelToken: _cancel)) {
      case Success(:final value):
        if (isClosed) return false;
        emit(state.copyWith(order: value, working: false));
        return true;
      case Failure(:final error):
        if (isClosed) return false;
        emit(state.copyWith(working: false, error: error));
        return false;
    }
  }

  @override
  Future<void> close() {
    _cancel.cancel('order detail closed');
    return super.close();
  }
}
