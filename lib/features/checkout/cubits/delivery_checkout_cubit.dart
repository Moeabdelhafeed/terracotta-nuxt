import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/error/app_exception.dart';
import '../../../core/types/result.dart';
import '../../../data/api/calls/workshop_apis.dart';
import '../../../data/models/terracotta/account/address.dart';
import '../../../data/models/terracotta/booking/booking.dart';
import '../../../data/models/terracotta/core/price_quote.dart';

typedef DeliveryQuoteFetch =
    AsyncResult<PriceQuote> Function(
      String bookingId, {
      bool? useWallet,
      int? addressId,
      CancelToken? cancelToken,
      Duration? timeout,
    });

typedef DeliveryChoose =
    AsyncResult<Booking> Function(
      String bookingId, {
      required String method,
      int? addressId,
      double? lat,
      double? lng,
      String? phone,
      bool? useWallet,
      String? address,
      CancelToken? cancelToken,
      Duration? timeout,
    });

/// «الدفع» for delivering a finished piece.
///
/// ## TWO calls, not three
///
/// The booking flow is quote → hold → pay. This one is **quote →
/// choose**, and the choose call SETTLES it: there is no
/// `delivery/pay` endpoint, and `POST .../delivery` takes the wallet
/// flag itself. A screen written like the booking checkout would be
/// looking for a third call that does not exist.
///
/// ## The fee comes from the ADDRESS, never the pin
///
/// `delivery_zone_id` on the chosen address carries it, which is why
/// the address is picked before this page opens and why the quote is
/// re-asked whenever it changes. The map pin is for the driver.
///
/// **No discount code.** `GET .../delivery/quote` takes `use_wallet`
/// and `address_id` and nothing else — checked against the live
/// OpenAPI on 2026-09-08 — which is the wire saying what
/// `docs/api-contract.md` already says in words: a promo comes off the
/// goods and never off the delivery.
///
/// **`already_paid: true` means there is nothing left to settle.**
/// Switching to pickup and back is free; the fee is charged once and
/// never refunded.
///
/// **A `make_your_candle` booking 422s here** — that type has no
/// delivery step at all.
@immutable
class DeliveryCheckoutState {
  const DeliveryCheckoutState({
    this.quote,
    this.address,
    this.booking,
    this.useWallet = false,
    this.method = 0,
    this.loading = true,
    this.quoting = false,
    this.paying = false,
    this.error,
  });

  /// The server's answer. Null before the first one.
  final PriceQuote? quote;

  /// Where it is going — and the city that sets the fee.
  final Address? address;

  /// What the choose call answered, once it has.
  final Booking? booking;

  final bool useWallet;

  /// An index into `PaymentMethodRow.brands`.
  final int method;

  /// The FIRST quote, which has nothing to show.
  final bool loading;

  /// A re-quote. The figures on screen stay while it runs.
  final bool quoting;

  final bool paying;
  final AppException? error;

  /// The fee, as the server states it.
  ///
  /// The ADDRESS's own `delivery_fee` stands in until the quote lands —
  /// it is the zone's fee, which is the same number the quote returns
  /// for a delivery with nothing else on it, so the page is honest in
  /// the gap rather than showing «٠».
  String get fee => quote?.deliveryFee ?? address?.deliveryFee ?? '0.00';

  String get walletApplied => quote?.walletApplied ?? '0.00';

  String get amountDue => quote?.amountDue ?? fee;

  /// Nothing left to settle — the fee was charged on an earlier choice.
  bool get alreadyPaid => quote?.alreadyPaid ?? false;

  bool get canSubmit => quote != null && !loading && !quoting && !paying;

  DeliveryCheckoutState copyWith({
    PriceQuote? quote,
    Address? address,
    Booking? booking,
    bool? useWallet,
    int? method,
    bool? loading,
    bool? quoting,
    bool? paying,
    AppException? error,
    bool clearError = false,
  }) => DeliveryCheckoutState(
    quote: quote ?? this.quote,
    address: address ?? this.address,
    booking: booking ?? this.booking,
    useWallet: useWallet ?? this.useWallet,
    method: method ?? this.method,
    loading: loading ?? this.loading,
    quoting: quoting ?? this.quoting,
    paying: paying ?? this.paying,
    error: clearError ? null : error ?? this.error,
  );
}

class DeliveryCheckoutCubit extends Cubit<DeliveryCheckoutState> {
  DeliveryCheckoutCubit({
    required this.bookingId,
    Address? address,
    DeliveryQuoteFetch? quote,
    DeliveryChoose? choose,
  }) : _quote = quote ?? WorkshopApis.getDeliveryQuote,
       _choose = choose ?? WorkshopApis.chooseDelivery,
       super(DeliveryCheckoutState(address: address));

  final String bookingId;
  final DeliveryQuoteFetch _quote;
  final DeliveryChoose _choose;
  final _cancel = CancelToken();

  Future<void> load() => _refreshQuote(first: true);

  /// A different address is a different city, which is a different fee.
  void selectAddress(Address address) {
    emit(state.copyWith(address: address));
    unawaited(_refreshQuote());
  }

  void toggleWallet(bool on) {
    emit(state.copyWith(useWallet: on));
    unawaited(_refreshQuote());
  }

  void selectMethod(int index) => emit(state.copyWith(method: index));

  Future<void> _refreshQuote({bool first = false}) async {
    emit(state.copyWith(loading: first, quoting: !first, clearError: true));

    final result = await _quote(
      bookingId,
      useWallet: state.useWallet,
      addressId: state.address?.id,
      cancelToken: _cancel,
    );
    if (isClosed) return;

    switch (result) {
      case Success(:final value):
        emit(state.copyWith(quote: value, loading: false, quoting: false));
      case Failure(:final error):
        emit(state.copyWith(loading: false, quoting: false, error: error));
    }
  }

  /// CHOOSE, which is also the settle. Answers the booking when it
  /// went through.
  ///
  /// Sends the ADDRESS ID rather than a pin: the id carries the zone
  /// that carries the fee, and `lat`/`lng` are only required when there
  /// is no saved address to name.
  Future<Booking?> confirm() async {
    if (state.paying) return null;
    emit(state.copyWith(paying: true, clearError: true));

    final result = await _choose(
      bookingId,
      method: 'delivery',
      addressId: state.address?.id,
      useWallet: state.useWallet,
      cancelToken: _cancel,
    );
    if (isClosed) return null;

    switch (result) {
      case Success(:final value):
        emit(state.copyWith(paying: false, booking: value));
        return value;
      case Failure(:final error):
        emit(state.copyWith(paying: false, error: error));
        return null;
    }
  }

  @override
  Future<void> close() {
    _cancel.cancel('delivery checkout closed');
    return super.close();
  }
}
