import 'package:dio/dio.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/error/app_exception.dart';
import '../../../core/types/result.dart';
import '../../../data/api/calls/address_apis.dart';
import '../../../data/api/calls/content_apis.dart';
import '../../../data/api/calls/shop_apis.dart';
import '../../../data/models/terracotta/account/address.dart';
import '../../../data/models/terracotta/commerce/order.dart';
import '../../../data/models/terracotta/content/discount_code.dart';
import '../../../data/models/terracotta/core/price_quote.dart';
import '../../profile/cubits/addresses_cubit.dart';
import 'shop_checkout_state.dart';

typedef DiscountCodesFetch =
    AsyncResult<List<DiscountCode>> Function({
      CancelToken? cancelToken,
      Duration? timeout,
    });

typedef CheckoutPlace =
    AsyncResult<Order> Function({
      int? addressId,
      double? lat,
      double? lng,
      String? phone,
      bool? useWallet,
      String? discountCode,
      CancelToken? cancelToken,
      Duration? timeout,
    });

typedef OrderPay =
    AsyncResult<Map<String, dynamic>> Function(
      String orderId, {
      CancelToken? cancelToken,
      Duration? timeout,
    });

typedef CheckoutQuoteFetch =
    AsyncResult<PriceQuote> Function({
      bool? useWallet,
      String? discountCode,
      int? addressId,
      int? deliveryZoneId,
      CancelToken? cancelToken,
      Duration? timeout,
    });

/// «الدفع» for a shop order.
///
/// `POST /api/shop/cart/quote` on every change — the party's own words:
/// "Render the checkout screen from this: it returns the same numbers,
/// computed the same way, that `POST /shop/cart/checkout` will charge."
/// So the screen never computes a total, and every input that could
/// move one re-asks.
///
/// Three things move it: the ADDRESS (its city sets the delivery fee —
/// never the map pin), a DISCOUNT CODE (goods only, never delivery),
/// and the WALLET.
class ShopCheckoutCubit extends Cubit<ShopCheckoutState> {
  ShopCheckoutCubit({
    CheckoutQuoteFetch? quote,
    AddressesFetch? addresses,
    DiscountCodesFetch? codes,
    CheckoutPlace? place,
    OrderPay? pay,
  }) : _quote = quote ?? ShopApis.getCheckoutQuote,
       _addresses = addresses ?? AddressApis.getAddresses,
       _codes = codes ?? ContentApis.getDiscountCodes,
       _place = place ?? ShopApis.checkout,
       _pay = pay ?? ShopApis.payOrder,
       super(const ShopCheckoutState());

  final CheckoutQuoteFetch _quote;
  final AddressesFetch _addresses;
  final DiscountCodesFetch _codes;
  final CheckoutPlace _place;
  final OrderPay _pay;
  final _cancel = CancelToken();

  /// The addresses first, because the DEFAULT one is what the first
  /// quote is priced against — asking for a quote before knowing where
  /// it is going returns a fee for a city nobody chose.
  Future<void> load() async {
    emit(state.copyWith(loading: true, clearError: true));

    var chosen = state.addressId;
    if (await _addresses(cancelToken: _cancel) case Success(:final value)) {
      if (isClosed) return;
      final fallback =
          value.where((a) => a.isDefault).firstOrNull ?? value.firstOrNull;
      chosen ??= fallback?.id;
      emit(state.copyWith(addresses: value, addressId: chosen));
    }

    // Best-effort: a checkout that cannot list the promos still takes
    // money, and a typed code still works.
    if (await _codes(cancelToken: _cancel) case Success(:final value)) {
      if (isClosed) return;
      emit(state.copyWith(codes: value));
    }

    await _refreshQuote(first: true);
  }

  Future<void> _refreshQuote({bool first = false}) async {
    emit(
      state.copyWith(
        loading: first,
        quoting: !first,
        clearError: true,
      ),
    );

    final result = await _quote(
      useWallet: state.useWallet,
      discountCode: state.discountCode,
      addressId: state.addressId,
      cancelToken: _cancel,
    );
    if (isClosed) return;

    switch (result) {
      case Success(:final value):
        emit(state.copyWith(quote: value, loading: false, quoting: false));
      case Failure(:final error):
        // A REJECTED CODE is not a broken screen. The server answers
        // 422 keyed to `discount_code`, so it lands under the box it
        // was typed in and the figures already on screen stay.
        final onField = error is ValidationException
            ? error.forField('discount_code')
            : null;
        if (onField != null) {
          emit(
            state.copyWith(
              discountError: onField,
              clearDiscountCode: true,
              loading: false,
              quoting: false,
            ),
          );
          // Without the code the previous figures are wrong, so ask
          // again for the ones that are right.
          await _refreshQuote();
          return;
        }
        emit(state.copyWith(loading: false, quoting: false, error: error));
    }
  }

  void selectAddress(Address address) {
    if (address.id == state.addressId) return;
    emit(state.copyWith(addressId: address.id));
    unawaitedQuote();
  }

  void selectMethod(int index) => emit(state.copyWith(method: index));

  void toggleWallet(bool on) {
    emit(state.copyWith(useWallet: on));
    unawaitedQuote();
  }

  /// Apply a code, or clear the one applied.
  void applyDiscount(String? code) {
    final trimmed = (code ?? '').trim();
    emit(
      state.copyWith(
        discountCode: trimmed.isEmpty ? null : trimmed,
        clearDiscountCode: trimmed.isEmpty,
        clearDiscountError: true,
      ),
    );
    unawaitedQuote();
  }

  /// The quote again, without waiting on it — every caller above is a
  /// tap handler.
  void unawaitedQuote() => _refreshQuote();

  /// The wire key the server answers when there is already an order
  /// awaiting payment. ONE AT A TIME is its rule, and no retry of this
  /// screen can satisfy it.
  static const openOrderKey = 'api.shop_order_already_awaiting_payment';

  /// HOLD, then SETTLE. Answers the order once it is paid for.
  ///
  /// The HELD order's own `amount_due` decides whether to pay: at
  /// `"0.00"` the wallet or a full discount already covered it and the
  /// pay call would be a charge for nothing. A retry pays the SAME
  /// order rather than making a second — which is also the only thing
  /// the server would accept, since one may be open at a time.
  Future<Order?> confirm() async {
    if (state.placing) return null;
    emit(state.copyWith(placing: true, openOrder: false, clearError: true));

    var order = state.order;
    if (order == null) {
      final held = await _place(
        addressId: state.addressId,
        useWallet: state.useWallet,
        discountCode: state.discountCode,
        cancelToken: _cancel,
      );
      if (isClosed) return null;

      switch (held) {
        case Success(:final value):
          order = value;
          emit(state.copyWith(order: value));
        case Failure(:final error):
          emit(
            state.copyWith(
              placing: false,
              // Not a retryable failure and not a field the customer
              // can fix: the way out is the order already open.
              openOrder: _isOpenOrder(error),
              error: error,
            ),
          );
          return null;
      }
    }

    // Settled on create — paying zero is an error, not a no-op.
    if (order.isAlreadySettled) {
      emit(state.copyWith(placing: false));
      return order;
    }

    switch (await _pay('${order.id}', cancelToken: _cancel)) {
      case Success():
        if (isClosed) return null;
        emit(state.copyWith(placing: false));
        return order;
      case Failure(:final error):
        if (isClosed) return null;
        // The order STAYS on the state. It is held and unpaid, and a
        // second checkout would be refused by the one-at-a-time rule
        // even if it were the right thing to do.
        emit(state.copyWith(placing: false, error: error));
        return null;
    }
  }

  /// Whether the refusal is the one-open-order rule.
  ///
  /// The key travels in the message on this route rather than under a
  /// field — there is no input to blame — so it is matched rather than
  /// read off `fieldErrors`.
  static bool _isOpenOrder(AppException error) =>
      error.message.contains(openOrderKey) ||
      (error.code?.contains(openOrderKey) ?? false);

  Future<void> refresh() => load();

  @override
  Future<void> close() {
    _cancel.cancel('shop checkout closed');
    return super.close();
  }
}
