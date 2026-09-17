import 'package:dio/dio.dart';

import '../../../core/constants/enums/api/request_type.dart';
import '../../../core/types/result.dart';
import '../../models/terracotta/commerce/gift.dart';
import '../../models/terracotta/commerce/gift_history.dart';
import '../../models/terracotta/commerce/gift_package.dart';
import '../../models/terracotta/commerce/gift_preview.dart';
import '../../models/terracotta/commerce/gift_redemption.dart';
import '../../models/terracotta/core/price_quote.dart';
import '../api_service.dart';
import '../endpoints/terracotta_endpoints.dart';

/// Gift API calls — buy a gift, share it, redeem it into a wallet.
///
/// Buying a gift is the same THREE steps every payable flow uses:
/// [getGiftQuote] prices it and creates nothing, [buyGift] creates it
/// UNPAID and reserves its code, [payGift] settles it.
///
/// Traps that live in this group specifically:
/// - **Money is a decimal STRING** (`"200.00"`), never a number. Keep it
///   as a string; never round-trip it through `double`.
/// - **`amount_due` of `"0.00"` means it ALREADY settled** (wallet or a
///   100% discount covered it). Check for that and skip [payGift].
/// - **[payGift] is idempotent** — a retry must not double-charge.
/// - **VAT is INCLUSIVE** — `vat_amount` is contained in `total_price`,
///   never added to it. Gifts carry no VAT on purchase anyway; the tax
///   lands on whatever the wallet is later spent on.
/// - **A discount code never reduces the delivery fee**, and it never
///   changes the gift's FACE VALUE either — a 200 gift bought for 180
///   still credits the recipient 200.
///
/// Every method returns an `AsyncResult<...>` — pattern-match at the
/// call site. Nothing here throws.
class GiftApis {
  GiftApis._();

  // ─── Per-endpoint log flags ───────────────────────────────

  static ApiLogConfig logGetMyGifts = kApiLogVerbose;
  static ApiLogConfig logGetGiftHistory = kApiLogVerbose;
  static ApiLogConfig logBuyGift = kApiLogVerbose;
  static ApiLogConfig logGetGiftQuote = kApiLogVerbose;
  static ApiLogConfig logPayGift = kApiLogVerbose;
  static ApiLogConfig logRedeemGift = kApiLogVerbose;
  static ApiLogConfig logGetGiftPackage = kApiLogVerbose;
  static ApiLogConfig logPreviewGift = kApiLogVerbose;

  // ─── Mock setup ───────────────────────────────────────────

  /// Token the [previewGift] mock is keyed to. The mock registry keys on
  /// the EXACT resolved path, so a `{token}` route can only be mocked
  /// for one token at a time.
  static const String mockGiftToken = '9c858901-8a57-4791-81fe-4c455b099bc9';

  /// Register mock responses for the GET endpoints in this class.
  /// Call once at app init when [ApiService.useMock] is true.
  static void installMocks() {
    ApiService.registerMock(
      endpoint: TerracottaEndpoints.gifts,
      type: RequestType.get,
      data: [
        {
          'id': 1,
          'recipient_name': 'Sara',
          'message': 'Happy birthday!',
          'recipient_phone': '+966500000000',
          'amount': '200.00',
          'subtotal': '200.00',
          'discount_amount': '0.00',
          'discount_code': null,
          'total_price': '200.00',
          'wallet_applied': '0.00',
          'amount_due': '200.00',
          'token': mockGiftToken,
          'share_url': 'https://app.terracotta.test/gift/$mockGiftToken',
          'is_redeemed': false,
          'redeemed_at': null,
          'created_at': '2026-08-16T12:00:00+00:00',
        },
      ],
    );
    ApiService.registerMock(
      endpoint: TerracottaEndpoints.giftPackage,
      type: RequestType.get,
      data: {'amount': '200.00', 'is_active': true},
    );
    ApiService.registerMock(
      endpoint: TerracottaEndpoints.gift(mockGiftToken),
      type: RequestType.get,
      data: {
        'recipient_name': 'Sara',
        'message': 'Happy birthday!',
        'amount': '200.00',
        'token': mockGiftToken,
        'is_redeemed': false,
        'redeemed_at': null,
      },
    );
  }

  // ─── API methods ──────────────────────────────────────────

  /// Lists the gifts the caller has BOUGHT, paginated. Every money field
  /// is a decimal string; `amount_due` `"0.00"` means that gift already
  /// settled and needs no [payGift].
  static AsyncResult<List<Gift>> getMyGifts({
    int? page,
    int? perPage,
    CancelToken? cancelToken,
    Duration? timeout,
  }) => ApiService.call(
    () => ApiService().getList<Gift>(
      TerracottaEndpoints.gifts,
      queryParameters: {
        if (page != null) 'page': page,
        if (perPage != null) 'per_page': perPage,
      },
      fromJson: Gift.fromJson,
      logRequest: logGetMyGifts.request,
      logResponse: logGetMyGifts.response,
      cancelToken: cancelToken,
      timeout: timeout,
    ),
  );

  /// BOTH SIDES of gifting in one list — `GET /api/gifts/history`.
  ///
  /// What the caller BOUGHT and what they CLAIMED, newest first, over
  /// a `totals` block. Two row shapes, told apart by `direction` — see
  /// [GiftHistory].
  ///
  /// **[direction] narrows the LIST and never the totals**, which is
  /// what lets both sides be labelled before either is opened.
  ///
  /// **`per_page` is left off on purpose.** Omitted, the server sends
  /// the whole list; passed, `gifts` becomes Laravel's paginator
  /// object instead. The screen that reads this is half a sheet and a
  /// reader is not going to page through gifts in one — so it takes
  /// the lot and scrolls. [perPage] is here for a screen that one day
  /// does want pages; [GiftHistory.fromJson] reads either shape.
  ///
  /// Registered customers only. A guest gets 401, which this app reads
  /// as the session ending — so do not call it for one.
  static AsyncResult<GiftHistory> getGiftHistory({
    GiftDirection? direction,
    int? perPage,
    int? page,
    CancelToken? cancelToken,
    Duration? timeout,
  }) => ApiService.call(
    () => ApiService().get<GiftHistory>(
      TerracottaEndpoints.giftHistory,
      queryParameters: {
        if (direction != null) 'direction': direction.wire,
        if (perPage != null) 'per_page': perPage,
        if (page != null) 'page': page,
      },
      fromJson: GiftHistory.fromJson,
      logRequest: logGetGiftHistory.request,
      logResponse: logGetGiftHistory.response,
      cancelToken: cancelToken,
      timeout: timeout,
    ),
  );

  /// QUOTE step — prices a gift purchase. Creates NOTHING and reserves
  /// no code; only [buyGift] does that. Returns the same envelope every
  /// quote does (`subtotal`, `discount_amount`, `delivery_fee`,
  /// `total_price`, `wallet_applied`, `amount_due`, `gift_value`), all
  /// as decimal strings. `vat_amount`, when present, is already INSIDE
  /// `total_price` — never add the two.
  static AsyncResult<PriceQuote> getGiftQuote({
    bool? useWallet,
    String? discountCode,
    CancelToken? cancelToken,
    Duration? timeout,
  }) => ApiService.call(
    () => ApiService().post<PriceQuote>(
      TerracottaEndpoints.giftQuote,
      data: {
        if (useWallet != null) 'use_wallet': useWallet,
        if (discountCode != null) 'discount_code': discountCode,
      },
      fromJson: PriceQuote.fromJson,
      logRequest: logGetGiftQuote.request,
      logResponse: logGetGiftQuote.response,
      cancelToken: cancelToken,
      timeout: timeout,
    ),
  );

  /// CREATE step — buys a gift UNPAID and reserves its code and
  /// `share_url`. The wallet amount and the discount-code use are
  /// consumed HERE, at hold time, not at pay time; an abandoned hold
  /// expires and gives them back.
  ///
  /// The returned numbers must match [getGiftQuote] field for field. If
  /// `amount_due` comes back `"0.00"` the gift already settled — skip
  /// [payGift] entirely. Otherwise settle it with [payGift].
  ///
  /// A discount does not change the gift's face value: `amount` is what
  /// the recipient will be credited, `total_price` is what the buyer
  /// pays.
  static AsyncResult<Gift> buyGift({
    required String recipientName,
    String? message,
    String? recipientPhone,
    bool? useWallet,
    String? discountCode,
    CancelToken? cancelToken,
    Duration? timeout,
  }) => ApiService.call(
    () => ApiService().post<Gift>(
      TerracottaEndpoints.gifts,
      data: {
        'recipient_name': recipientName,
        if (message != null) 'message': message,
        if (recipientPhone != null) 'recipient_phone': recipientPhone,
        if (useWallet != null) 'use_wallet': useWallet,
        if (discountCode != null) 'discount_code': discountCode,
      },
      fromJson: Gift.fromJson,
      logRequest: logBuyGift.request,
      logResponse: logBuyGift.response,
      cancelToken: cancelToken,
      timeout: timeout,
    ),
  );

  /// PAY step — settles a gift held by [buyGift], keyed by its numeric
  /// gift id (NOT the share token). Idempotent: calling it twice must
  /// not double-charge, so a retry after a dropped response is safe.
  ///
  /// Do not call it at all when [buyGift] returned `amount_due`
  /// `"0.00"` — that gift already settled.
  static AsyncResult<Map<String, dynamic>> payGift(
    String giftId, {
    CancelToken? cancelToken,
    Duration? timeout,
  }) => ApiService.call(
    () => ApiService().post<Map<String, dynamic>>(
      TerracottaEndpoints.giftPay(giftId),
      fromJson: (json) => json,
      logRequest: logPayGift.request,
      logResponse: logPayGift.response,
      cancelToken: cancelToken,
      timeout: timeout,
    ),
  );

  /// Redeems a gift into the CALLER's wallet using the share token —
  /// this credits the recipient, not the buyer, so it must run under
  /// the recipient's session. Returns the credited `amount` and the new
  /// `wallet_balance`, both decimal strings.
  static AsyncResult<GiftRedemption> redeemGift(
    String token, {
    CancelToken? cancelToken,
    Duration? timeout,
  }) => ApiService.call(
    () => ApiService().post<GiftRedemption>(
      TerracottaEndpoints.giftRedeem(token),
      fromJson: GiftRedemption.fromJson,
      logRequest: logRedeemGift.request,
      logResponse: logRedeemGift.response,
      cancelToken: cancelToken,
      timeout: timeout,
    ),
  );

  /// PUBLIC — the gift package's face value and whether gifting is
  /// switched on at all. Fetch before drawing any gift screen and hide
  /// the flow when `is_active` is false. `amount` is a decimal string.
  static AsyncResult<GiftPackage> getGiftPackage({
    CancelToken? cancelToken,
    Duration? timeout,
  }) => ApiService.call(
    () => ApiService().get<GiftPackage>(
      TerracottaEndpoints.giftPackage,
      fromJson: GiftPackage.fromJson,
      logRequest: logGetGiftPackage.request,
      logResponse: logGetGiftPackage.response,
      cancelToken: cancelToken,
      timeout: timeout,
    ),
  );

  /// PUBLIC — what the recipient sees when they open a `share_url`. No
  /// account is needed to VIEW a gift; redeeming it via [redeemGift]
  /// does need one, because it credits a wallet.
  static AsyncResult<GiftPreview> previewGift(
    String token, {
    CancelToken? cancelToken,
    Duration? timeout,
  }) => ApiService.call(
    () => ApiService().get<GiftPreview>(
      TerracottaEndpoints.gift(token),
      fromJson: GiftPreview.fromJson,
      logRequest: logPreviewGift.request,
      logResponse: logPreviewGift.response,
      cancelToken: cancelToken,
      timeout: timeout,
    ),
  );
}
