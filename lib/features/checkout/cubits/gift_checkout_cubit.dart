import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/error/app_exception.dart';
import '../../../core/types/result.dart';
import '../../../data/api/calls/content_apis.dart';
import '../../../data/api/calls/gift_apis.dart';
import '../../../data/models/terracotta/commerce/gift.dart';
import '../../../data/models/terracotta/commerce/gift_package.dart';
import '../../../data/models/terracotta/content/discount_code.dart';
import '../../../data/models/terracotta/core/price_quote.dart';
import '../../gift/data/gift_draft.dart';

typedef GiftPackageFetch =
    AsyncResult<GiftPackage> Function({
      CancelToken? cancelToken,
      Duration? timeout,
    });

typedef GiftQuoteFetch =
    AsyncResult<PriceQuote> Function({
      bool? useWallet,
      String? discountCode,
      CancelToken? cancelToken,
      Duration? timeout,
    });

typedef GiftBuy =
    AsyncResult<Gift> Function({
      required String recipientName,
      String? message,
      String? recipientPhone,
      bool? useWallet,
      String? discountCode,
      CancelToken? cancelToken,
      Duration? timeout,
    });

typedef GiftDiscountCodesFetch =
    AsyncResult<List<DiscountCode>> Function({
      CancelToken? cancelToken,
      Duration? timeout,
    });

typedef GiftPay =
    AsyncResult<Map<String, dynamic>> Function(
      String giftId, {
      CancelToken? cancelToken,
      Duration? timeout,
    });

/// «إهداء» — the same three-step contract the booking runs.
///
/// **QUOTE → HOLD → PAY.** `POST /api/gifts/quote` prices it and
/// reserves nothing; `POST /api/gifts` buys it UNPAID, mints the token
/// and the `share_url`, and spends the wallet amount and the discount
/// code's use right there; `POST /api/gifts/{id}/pay` settles what is
/// left — and is skipped entirely when the hold came back
/// `amount_due == "0.00"`.
///
/// **The face value is not the price.** `amount` is what the recipient
/// is credited and the studio sets it; `total_price` is what the buyer
/// pays, and a discount moves the second without touching the first.
@immutable
class GiftCheckoutState {
  const GiftCheckoutState({
    this.package,
    this.quote,
    this.gift,
    this.useWallet = false,
    this.method = 0,
    this.hasRecipient = false,
    this.discountCode,
    this.discountError,
    this.codes = const [],
    this.loading = true,
    this.quoting = false,
    this.paying = false,
    this.error,
  });

  /// The studio's own package — the face value, which the buyer does
  /// not choose. Null before it arrives.
  final GiftPackage? package;

  final PriceQuote? quote;

  /// The held gift, once there is one. Kept so a failed settle is
  /// retried against the SAME gift rather than buying a second.
  final Gift? gift;

  final bool useWallet;

  /// An index into `PaymentMethodRow.brands`.
  final int method;

  /// Whether there is someone to address the gift TO.
  ///
  /// `recipient_name` is the one thing `POST /api/gifts` requires — the
  /// note and the number are notes. After a hot restart the sheet's
  /// draft is gone with the route extra, and there is nothing to buy
  /// with, so the bar says so rather than failing on the press.
  final bool hasRecipient;

  final String? discountCode;

  /// The SERVER's words about the last code tried. A 422 on this route
  /// is keyed to `discount_code`, so it lands under the box it was
  /// typed in rather than as a toast.
  final String? discountError;

  /// The promos worth offering — public, live, and with room left for
  /// this customer. `GET /api/discount-codes` needs a session, and
  /// buying a gift already does.
  final List<DiscountCode> codes;

  final bool loading;
  final bool quoting;
  final bool paying;
  final AppException? error;

  /// What the recipient is credited. The package's figure until a quote
  /// restates it, `"0.00"` before either.
  String get faceValue => quote?.giftValue ?? package?.amount ?? '0.00';

  bool get canSubmit =>
      quote != null && hasRecipient && !loading && !quoting && !paying;

  GiftCheckoutState copyWith({
    GiftPackage? package,
    PriceQuote? quote,
    Gift? gift,
    bool? useWallet,
    int? method,
    bool? hasRecipient,
    String? discountCode,
    String? discountError,
    List<DiscountCode>? codes,
    bool clearDiscountCode = false,
    bool clearDiscountError = false,
    bool? loading,
    bool? quoting,
    bool? paying,
    AppException? error,
    bool clearError = false,
  }) => GiftCheckoutState(
    package: package ?? this.package,
    quote: quote ?? this.quote,
    gift: gift ?? this.gift,
    useWallet: useWallet ?? this.useWallet,
    method: method ?? this.method,
    hasRecipient: hasRecipient ?? this.hasRecipient,
    discountCode: clearDiscountCode ? null : discountCode ?? this.discountCode,
    discountError: clearDiscountError
        ? null
        : discountError ?? this.discountError,
    codes: codes ?? this.codes,
    loading: loading ?? this.loading,
    quoting: quoting ?? this.quoting,
    paying: paying ?? this.paying,
    error: clearError ? null : error ?? this.error,
  );
}

class GiftCheckoutCubit extends Cubit<GiftCheckoutState> {
  GiftCheckoutCubit({
    this.draft,
    GiftPackageFetch? package,
    GiftQuoteFetch? quote,
    GiftBuy? buy,
    GiftPay? pay,
    GiftDiscountCodesFetch? codes,
  }) : _package = package ?? GiftApis.getGiftPackage,
       _codes = codes ?? ContentApis.getDiscountCodes,
       _quote = quote ?? GiftApis.getGiftQuote,
       _buy = buy ?? GiftApis.buyGift,
       _pay = pay ?? GiftApis.payGift,
       super(
         GiftCheckoutState(hasRecipient: draft?.isComplete ?? false),
       );

  /// What the sheet collected. Null after a hot restart, where a route
  /// extra does not survive — [confirm] refuses rather than buying a
  /// gift addressed to nobody.
  final GiftDraft? draft;

  final GiftPackageFetch _package;
  final GiftDiscountCodesFetch _codes;
  final GiftQuoteFetch _quote;
  final GiftBuy _buy;
  final GiftPay _pay;
  final _cancel = CancelToken();

  /// The face value and the first quote, together — the page needs both
  /// before it can show a figure, and neither depends on the other.
  Future<void> load() async {
    emit(state.copyWith(loading: true, clearError: true));

    // Both at once, and each awaited with its own type — a
    // `Future.wait` over two different payloads erases them to Object
    // and buys a cast for nothing.
    // Best-effort, and beside the other two: a checkout that cannot
    // list the promos still takes money, and a typed code still works.
    unawaited(_loadCodes());

    final asking = _package(cancelToken: _cancel);
    final pricing = _quote(
      useWallet: state.useWallet,
      discountCode: state.discountCode,
      cancelToken: _cancel,
    );

    // The PACKAGE failing is not the screen failing: the quote carries
    // `gift_value` too, so the amount is still known.
    if (await asking case Success(:final value)) {
      if (isClosed) return;
      emit(state.copyWith(package: value));
    }

    final quoted = await pricing;
    if (isClosed) return;

    switch (quoted) {
      case Success(:final value):
        emit(state.copyWith(quote: value, loading: false, quoting: false));
      case Failure(:final error):
        emit(state.copyWith(loading: false, quoting: false, error: error));
    }
  }

  Future<void> _loadCodes() async {
    if (await _codes(cancelToken: _cancel) case Success(:final value)) {
      if (isClosed) return;
      emit(state.copyWith(codes: value));
    }
  }

  /// Price this gift WITH the code — never
  /// `POST /discount-codes/validate`, which prices goods alone. The
  /// figure this screen shows has to be the one `POST /api/gifts` will
  /// charge.
  void applyDiscount(String? code) {
    final trimmed = (code ?? '').trim();
    emit(
      state.copyWith(
        discountCode: trimmed.isEmpty ? null : trimmed,
        clearDiscountCode: trimmed.isEmpty,
        clearDiscountError: true,
      ),
    );
    unawaited(_requote());
  }

  Future<void> _requote() async {
    emit(state.copyWith(quoting: true, clearError: true));

    final result = await _quote(
      useWallet: state.useWallet,
      discountCode: state.discountCode,
      cancelToken: _cancel,
    );
    if (isClosed) return;

    switch (result) {
      case Success(:final value):
        emit(state.copyWith(quote: value, quoting: false));
      case Failure(:final error):
        // A REJECTED CODE is not a broken screen: the 422 is keyed to
        // `discount_code`, so it lands under the box it was typed in
        // and the figures already on screen stay — then the quote is
        // re-asked without it, so what is shown is payable.
        final onField = error is ValidationException
            ? error.forField('discount_code')
            : null;
        if (onField != null) {
          emit(
            state.copyWith(
              discountError: onField,
              clearDiscountCode: true,
              quoting: false,
            ),
          );
          await _requote();
          return;
        }
        emit(state.copyWith(quoting: false, error: error));
    }
  }

  void toggleWallet(bool on) {
    emit(state.copyWith(useWallet: on));
    _requote();
  }

  void selectMethod(int index) => emit(state.copyWith(method: index));

  /// HOLD, then SETTLE. Answers the gift once it is paid for.
  ///
  /// The HELD gift's own `amount_due` decides whether to pay — not the
  /// quote's, because the two are asked at different moments and it is
  /// the hold that took the wallet.
  Future<Gift?> confirm() async {
    final notes = draft;
    if (state.paying || notes == null) return null;
    emit(state.copyWith(paying: true, clearError: true));

    var gift = state.gift;
    if (gift == null) {
      final held = await _buy(
        recipientName: notes.recipientName.trim(),
        message: (notes.message ?? '').trim().isEmpty
            ? null
            : notes.message!.trim(),
        recipientPhone: (notes.recipientPhone ?? '').trim().isEmpty
            ? null
            : notes.recipientPhone!.trim(),
        useWallet: state.useWallet,
        discountCode: state.discountCode,
        cancelToken: _cancel,
      );
      if (isClosed) return null;

      switch (held) {
        case Success(:final value):
          gift = value;
          emit(state.copyWith(gift: value));
        case Failure(:final error):
          emit(state.copyWith(paying: false, error: error));
          return null;
      }
    }

    // Settled on create — the wallet or a full discount covered it, and
    // paying zero is an error rather than a no-op.
    if (gift.isAlreadySettled) {
      emit(state.copyWith(paying: false));
      return gift;
    }

    switch (await _pay('${gift.id}', cancelToken: _cancel)) {
      case Success():
        if (isClosed) return null;
        emit(state.copyWith(paying: false));
        return gift;
      case Failure(:final error):
        if (isClosed) return null;
        // The gift STAYS on the state: it is bought and held, and a
        // second buy would be a second gift.
        emit(state.copyWith(paying: false, error: error));
        return null;
    }
  }

  @override
  Future<void> close() {
    _cancel.cancel('gift checkout closed');
    return super.close();
  }
}
