import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/error/app_exception.dart';
import '../../../core/types/result.dart';
import '../../../data/api/calls/content_apis.dart';
import '../../../data/api/calls/workshop_apis.dart';
import '../../../data/models/terracotta/booking/booking.dart';
import '../../../data/models/terracotta/content/discount_code.dart';
import '../../../data/models/terracotta/core/price_quote.dart';

typedef BookingQuoteFetch =
    AsyncResult<PriceQuote> Function(
      String workshopId, {
      required int workshopSlotId,
      required int peopleCount,
      String? bookingDate,
      bool? withCelebration,
      bool? useWallet,
      List<Map<String, dynamic>>? products,
      String? discountCode,
      CancelToken? cancelToken,
      Duration? timeout,
    });

typedef BookingCreate =
    AsyncResult<Booking> Function(
      String workshopId, {
      required int workshopSlotId,
      required String bookingDate,
      required int peopleCount,
      bool? withCelebration,
      bool? useWallet,
      List<Map<String, dynamic>>? products,
      String? discountCode,
      CancelToken? cancelToken,
      Duration? timeout,
    });

typedef BookingDiscountCodesFetch =
    AsyncResult<List<DiscountCode>> Function({
      CancelToken? cancelToken,
      Duration? timeout,
    });

typedef BookingPay =
    AsyncResult<Map<String, dynamic>> Function(
      String bookingId, {
      CancelToken? cancelToken,
      Duration? timeout,
    });

/// «الدفع» for a workshop booking — the three-step contract.
///
/// **QUOTE → HOLD → PAY**, and every screen in the app that takes money
/// runs it. `GET /api/workshops/{id}/price` creates nothing and holds
/// nothing; `POST .../bookings` reserves the seat, spends the wallet
/// and burns the discount code; `POST .../pay` settles what is left.
///
/// Two rules the shape of this cubit exists to keep:
///
///   * **`amount_due == "0.00"` settles on create.** The wallet or a
///     full discount covered it, the booking comes back `confirmed`,
///     and calling pay would be a second charge for nothing. [confirm]
///     reads the created booking rather than the quote to decide.
///   * **The hold expires**, in `PAYMENT_HOLD_MINUTES` (15). After that
///     `pay` answers 422 `api.payment_hold_expired` and the seat, the
///     wallet amount and the code's use go back. Nothing here retries
///     it: the customer starts again.
///
/// The total is never computed on this side. The server applies the
/// discount to the goods, adds the celebration, then lets the wallet
/// cover what it can — in that order — and anything summed here would
/// disagree with what is charged.
@immutable
class BookingCheckoutState {
  const BookingCheckoutState({
    this.quote,
    this.booking,
    this.celebration = false,
    this.useWallet = false,
    this.method = 0,
    this.discountCode,
    this.discountError,
    this.codes = const [],
    this.loading = true,
    this.quoting = false,
    this.paying = false,
    this.holdExpired = false,
    this.error,
  });

  /// The server's answer. Null before the first one.
  final PriceQuote? quote;

  /// What the hold created, once it has. Kept so a failed pay can be
  /// retried against the same booking rather than making a second.
  final Booking? booking;

  final bool celebration;
  final bool useWallet;

  /// An index into `PaymentMethodRow.brands`.
  final int method;

  final String? discountCode;
  final String? discountError;

  /// The promos worth OFFERING — public, live, and with room left for
  /// this customer. The server does that filtering, so a row here is a
  /// code they can use today; an empty list means there is nothing to
  /// advertise, not that codes do not exist.
  ///
  /// Empty for a guest too: `GET /api/discount-codes` is the caller's
  /// own list and answers 401 without a session. It is asked for only
  /// when there is an account — a 401 here would end the visit, since
  /// `SessionExpiry` treats one as the session closing.
  final List<DiscountCode> codes;

  /// The FIRST quote, which has nothing to show.
  final bool loading;

  /// A re-quote. The figures on screen stay while it runs.
  final bool quoting;

  /// The hold and the settle, which are one press to the customer.
  final bool paying;

  /// `PAYMENT_HOLD_MINUTES` ran out between the hold and the settle.
  /// The seat, the wallet amount and the discount code's use all went
  /// back, so there is nothing here left to pay for — the customer
  /// starts again rather than pressing the same button.
  final bool holdExpired;

  final AppException? error;

  bool get canSubmit => quote != null && !quoting && !loading && !paying;

  /// What the celebration would cost, whether or not it is taken —
  /// the server quotes it either way so the screen can price the
  /// choice before it is made.
  String get celebrationPrice => quote?.celebrationPrice ?? '0.00';

  BookingCheckoutState copyWith({
    PriceQuote? quote,
    Booking? booking,
    bool? celebration,
    bool? useWallet,
    int? method,
    String? discountCode,
    String? discountError,
    List<DiscountCode>? codes,
    bool clearDiscountCode = false,
    bool clearDiscountError = false,
    bool? loading,
    bool? quoting,
    bool? paying,
    bool? holdExpired,
    bool clearBooking = false,
    AppException? error,
    bool clearError = false,
  }) => BookingCheckoutState(
    quote: quote ?? this.quote,
    booking: clearBooking ? null : booking ?? this.booking,
    celebration: celebration ?? this.celebration,
    useWallet: useWallet ?? this.useWallet,
    method: method ?? this.method,
    discountCode: clearDiscountCode ? null : discountCode ?? this.discountCode,
    discountError: clearDiscountError
        ? null
        : discountError ?? this.discountError,
    codes: codes ?? this.codes,
    loading: loading ?? this.loading,
    quoting: quoting ?? this.quoting,
    paying: paying ?? this.paying,
    holdExpired: holdExpired ?? this.holdExpired,
    error: clearError ? null : error ?? this.error,
  );
}

class BookingCheckoutCubit extends Cubit<BookingCheckoutState> {
  BookingCheckoutCubit({
    required this.workshopId,
    required this.workshopSlotId,
    required this.bookingDate,
    required this.peopleCount,
    this.products = const [],
    BookingQuoteFetch? quote,
    BookingCreate? create,
    BookingPay? pay,
    BookingDiscountCodesFetch? codes,
  }) : _quote = quote ?? WorkshopApis.getBookingPrice,
       _codes = codes ?? ContentApis.getDiscountCodes,
       _create = create ?? WorkshopApis.createBooking,
       _pay = pay ?? WorkshopApis.payBooking,
       super(const BookingCheckoutState());

  final String workshopId;
  final int workshopSlotId;

  /// `Y-m-d`, and the session's Asia/Riyadh wall clock.
  final String bookingDate;
  final int peopleCount;

  /// `{workshop_product_id, quantity}` or `{workshop_booking_piece_id}`
  /// per line. Empty on a flat-rate workshop, required on a catalogue
  /// one — where the seat price is `"0.00"` and the money is entirely
  /// in these.
  final List<Map<String, dynamic>> products;

  final BookingQuoteFetch _quote;
  final BookingDiscountCodesFetch _codes;
  final BookingCreate _create;
  final BookingPay _pay;
  final _cancel = CancelToken();

  /// The quote, and the promos to advertise beside it.
  ///
  /// [signedIn] gates the second one: the codes list is the caller's
  /// own and answers 401 to a guest, and a 401 anywhere is the session
  /// ending — which would throw a visitor off the very screen guest
  /// checkout exists to let them reach.
  Future<void> load({bool signedIn = false}) async {
    if (signedIn) unawaited(_loadCodes());
    await _refreshQuote(first: true);
  }

  /// Best-effort: a checkout that cannot list the promos still takes
  /// money, and a typed code still works.
  Future<void> _loadCodes() async {
    if (await _codes(cancelToken: _cancel) case Success(:final value)) {
      if (isClosed) return;
      emit(state.copyWith(codes: value));
    }
  }

  Future<void> _refreshQuote({bool first = false}) async {
    emit(state.copyWith(loading: first, quoting: !first, clearError: true));

    final result = await _quote(
      workshopId,
      workshopSlotId: workshopSlotId,
      peopleCount: peopleCount,
      bookingDate: bookingDate,
      withCelebration: state.celebration,
      useWallet: state.useWallet,
      products: products.isEmpty ? null : products,
      discountCode: state.discountCode,
      cancelToken: _cancel,
    );
    if (isClosed) return;

    switch (result) {
      case Success(:final value):
        emit(state.copyWith(quote: value, loading: false, quoting: false));
      case Failure(:final error):
        // A REJECTED CODE is not a broken screen: the 422 is keyed to
        // `discount_code`, so it lands under the box it was typed in
        // and the figures already on screen stay.
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
          await _refreshQuote();
          return;
        }
        emit(state.copyWith(loading: false, quoting: false, error: error));
    }
  }

  void toggleCelebration(bool on) {
    emit(state.copyWith(celebration: on));
    unawaitedQuote();
  }

  void toggleWallet(bool on) {
    emit(state.copyWith(useWallet: on));
    unawaitedQuote();
  }

  void selectMethod(int index) => emit(state.copyWith(method: index));

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

  void unawaitedQuote() => _refreshQuote();

  /// HOLD, then SETTLE. Answers the booking when it is confirmed.
  ///
  /// The created booking's own `amount_due` decides whether to pay: at
  /// `"0.00"` the server already settled it, and a pay call would be a
  /// charge for nothing. A booking that was already made and only
  /// failed to settle is paid again rather than re-created — that is
  /// what stops a retry becoming a second seat.
  Future<Booking?> confirm() async {
    if (state.paying) return null;
    emit(state.copyWith(paying: true, holdExpired: false, clearError: true));

    var booking = state.booking;
    if (booking == null) {
      final held = await _create(
        workshopId,
        workshopSlotId: workshopSlotId,
        bookingDate: bookingDate,
        peopleCount: peopleCount,
        withCelebration: state.celebration,
        useWallet: state.useWallet,
        products: products.isEmpty ? null : products,
        discountCode: state.discountCode,
        cancelToken: _cancel,
      );
      if (isClosed) return null;

      switch (held) {
        case Success(:final value):
          booking = value;
          emit(state.copyWith(booking: value));
        case Failure(:final error):
          emit(state.copyWith(paying: false, error: error));
          return null;
      }
    }

    // Settled on create — the wallet or a full discount covered it.
    if (booking.isAlreadySettled) {
      emit(state.copyWith(paying: false));
      return booking;
    }

    switch (await _pay('${booking.id}', cancelToken: _cancel)) {
      case Success():
        if (isClosed) return null;
        emit(state.copyWith(paying: false));
        return booking;
      case Failure(:final error):
        if (isClosed) return null;
        // A hold that RAN OUT is gone: the seat, the wallet amount and
        // the code's use all went back, so keeping the booking would
        // let the customer retry a settle against nothing. Any other
        // failure keeps it, because the seat is still held and a
        // second create would take a second one.
        final expired = _isHoldExpired(error);
        emit(
          state.copyWith(
            paying: false,
            holdExpired: expired,
            clearBooking: expired,
            error: error,
          ),
        );
        return null;
    }
  }

  /// The wire key for a hold that ran out.
  static const holdExpiredKey = 'api.payment_hold_expired';

  static bool _isHoldExpired(AppException error) =>
      error.message.contains(holdExpiredKey) ||
      (error.code?.contains(holdExpiredKey) ?? false) ||
      (error.anyFieldError?.contains(holdExpiredKey) ?? false);

  @override
  Future<void> close() {
    _cancel.cancel('booking checkout closed');
    return super.close();
  }
}
