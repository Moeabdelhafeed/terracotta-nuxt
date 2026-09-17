import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/error/app_exception.dart';
import '../../../core/types/result.dart';
import '../../../data/api/calls/gift_apis.dart';
import '../../../data/models/terracotta/commerce/gift_preview.dart';
import '../../../data/models/terracotta/commerce/gift_redemption.dart';

typedef GiftPreviewFetch =
    AsyncResult<GiftPreview> Function(
      String token, {
      CancelToken? cancelToken,
      Duration? timeout,
    });

typedef GiftRedeemCall =
    AsyncResult<GiftRedemption> Function(
      String token, {
      CancelToken? cancelToken,
      Duration? timeout,
    });

/// One gift, seen through its share token.
@immutable
class GiftClaimState {
  const GiftClaimState({
    this.gift,
    this.redeemed,
    this.loading = true,
    this.claiming = false,
    this.error,
    this.refusal,
  });

  /// What the server says the gift is. Null until the first answer.
  final GiftPreview? gift;

  /// What the claim credited. Non-null only after a successful one,
  /// and it is what turns the screen into a receipt.
  final GiftRedemption? redeemed;

  /// The FIRST load, which has nothing to show.
  final bool loading;

  /// A claim is in flight. The button must not fire twice: the second
  /// call is the one that comes back "already redeemed".
  final bool claiming;

  /// The load failed and there is nothing on screen.
  final AppException? error;

  /// The server REFUSED the claim, in its own words.
  ///
  /// Told apart from [error] because it is not a failure to retry: the
  /// gift was already claimed, was never paid for, belongs to the
  /// reader, or gifting is switched off. Every one of those comes back
  /// as a 422 keyed on `errors.gift`, and the sentence the server
  /// wrote is already localized.
  final String? refusal;

  bool get isClaimed => redeemed != null;

  GiftClaimState copyWith({
    GiftPreview? gift,
    GiftRedemption? redeemed,
    bool? loading,
    bool? claiming,
    AppException? error,
    String? refusal,
    bool clearError = false,
    bool clearRefusal = false,
  }) => GiftClaimState(
    gift: gift ?? this.gift,
    redeemed: redeemed ?? this.redeemed,
    loading: loading ?? this.loading,
    claiming: claiming ?? this.claiming,
    error: clearError ? null : error ?? this.error,
    refusal: clearRefusal ? null : refusal ?? this.refusal,
  );
}

/// Opening a gift someone sent, and claiming it.
///
/// ## Two calls, and only one of them needs an account
///
/// `GET /api/gifts/{token}` is PUBLIC — verified live: an unknown
/// token answers 404, not 401 — because the recipient usually has no
/// account when they first open the link. `POST
/// /api/gifts/{token}/redeem` needs one, and answers 401 without it.
///
/// **That 401 is why [claim] must never be called without a session.**
/// In this app a 401 is the session ENDING: `SessionExpiry` clears the
/// token and re-runs the guards. Claiming while signed out would
/// therefore not merely fail — it would sign out a reader who was
/// holding a perfectly good session for a different account, or evict
/// a guest mid-browse. The screen gates the button on `AuthGate`; this
/// class assumes it did.
///
/// ## A refusal is not an error
///
/// Already redeemed, never paid, your own gift, gifting switched off:
/// all four are a 422 keyed on `errors.gift` with a sentence the
/// server has already localized. They are shown as they arrived, and
/// the gift is then RE-FETCHED — the refusal usually means the state
/// on screen is out of date, and the reload is what makes the screen
/// agree with it.
class GiftClaimCubit extends Cubit<GiftClaimState> {
  GiftClaimCubit({
    required this.token,
    GiftPreviewFetch? preview,
    GiftRedeemCall? redeem,
  }) : _preview = preview ?? GiftApis.previewGift,
       _redeem = redeem ?? GiftApis.redeemGift,
       super(const GiftClaimState());

  /// The share token out of the link.
  final String token;

  final GiftPreviewFetch _preview;
  final GiftRedeemCall _redeem;
  final _cancel = CancelToken();

  /// Fetch the gift. Public — no session needed.
  Future<void> load() async {
    emit(state.copyWith(loading: true, clearError: true));

    switch (await _preview(token, cancelToken: _cancel)) {
      case Success(:final value):
        if (isClosed) return;
        emit(state.copyWith(gift: value, loading: false, clearError: true));
      case Failure(:final error):
        if (isClosed) return;
        // A failed RELOAD keeps the gift already on screen — the
        // reader is looking at it, and a refusal that arrived a moment
        // ago is the reason this ran.
        emit(state.copyWith(loading: false, error: error));
    }
  }

  /// Claim it into the caller's wallet.
  ///
  /// **The caller must have checked for a session first** — see the
  /// class doc for what a 401 does here.
  Future<void> claim() async {
    if (state.claiming || state.isClaimed) return;
    emit(state.copyWith(claiming: true, clearRefusal: true));

    switch (await _redeem(token, cancelToken: _cancel)) {
      case Success(:final value):
        if (isClosed) return;
        emit(state.copyWith(redeemed: value, claiming: false));
      case Failure(:final error):
        if (isClosed) return;
        // The server's own sentence when it named the input, its
        // general message otherwise. Never a key.
        emit(
          state.copyWith(
            claiming: false,
            refusal: error.fieldError('gift') ?? error.message,
          ),
        );
        // AND ASK AGAIN. A refusal almost always means the screen is
        // out of date — someone else claimed it, or it was never paid
        // for — so the gift is re-read and the button disappears on
        // its own rather than inviting a second identical failure.
        await load();
    }
  }

  @override
  Future<void> close() {
    _cancel.cancel('gift claim closed');
    return super.close();
  }
}
