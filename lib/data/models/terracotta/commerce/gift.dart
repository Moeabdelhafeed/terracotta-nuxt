// Package imports:
import 'package:freezed_annotation/freezed_annotation.dart';

part 'gift.freezed.dart';
part 'gift.g.dart';

/// A gift the caller has bought — an element of `GET /api/gifts`
/// (newest first) and the object `POST /api/gifts` returns. The same
/// shape backs `GET /api/gifts/{token}` (the public redeem lookup),
/// `POST /api/gifts/{gift}/pay` and `POST /api/gifts/{token}/redeem`.
///
/// A gift is store credit, not a product: redeeming it tops up the
/// recipient's wallet. It therefore has no items, no delivery block and
/// no VAT — the money fields are the whole story.
///
/// **[token] is the SECRET, and [shareUrl] embeds it.** The gift is
/// claimed by whoever holds the link (`.../gift/{token}`), which is why
/// the redeem endpoints are keyed by token rather than id — [id] only
/// works for the buyer's own `pay` call. Treat both as credentials: do
/// not log them, and do not surface them for an already-redeemed gift.
///
/// **[recipientName] / [message] / [recipientPhone] are NOTES, not
/// delivery.** The API sends nothing to the recipient; they are shown
/// on the redeem screen and kept for the buyer's own reference. The app
/// is responsible for actually sharing [shareUrl].
///
/// **[isRedeemed] and [redeemedAt] describe the CLAIM, [paymentStatus]
/// describes the PURCHASE, and they move independently.** The live
/// capture holds gifts that are `"payment_status": "unpaid"` and
/// `"is_redeemed": true` at the same time — do not render one from the
/// other.
///
/// Every monetary field is a decimal string (`"200.00"`), never a
/// double. [amount] is the face value; [totalPrice] is what the buyer
/// was charged after a promo code, and [amountDue] is what the payment
/// step still has to collect — see [isAlreadySettled].
///
/// Nullability: [message] and [recipientPhone] are optional at
/// creation (only `recipient_name` is required by `POST /api/gifts`),
/// [discountCode] and [redeemedAt] are null in the captures, and
/// [paymentStatus] / [paymentExpiresAt] are absent from the published
/// gift shape while every capture is in the same unpaid state.
@freezed
abstract class Gift with _$Gift {
  const factory Gift({
    /// Gift id — the `{gift}` of `POST /api/gifts/{gift}/pay`. NOT the
    /// redeem key; that is [token].
    required int id,

    /// Who it is for, as the buyer typed it. The only field
    /// `POST /api/gifts` requires.
    required String recipientName,

    /// Note shown on the redeem screen. Null when the buyer left it
    /// empty.
    String? message,

    /// Contact note for the buyer's own reference, E.164
    /// (`"+966500000000"`). The API does not message it.
    String? recipientPhone,

    /// Face value of the gift — what lands in the recipient's wallet.
    /// Decimal string.
    required String amount,

    /// Purchase subtotal before discount and wallet. Decimal string.
    required String subtotal,

    /// Taken off by [discountCode]. `"0.00"` when none.
    required String discountAmount,

    /// Promo code applied at purchase, null when none was used.
    String? discountCode,

    /// What the buyer was charged. Decimal string. Can be LESS than
    /// [amount] when a code applied — the recipient still receives
    /// [amount].
    required String totalPrice,

    /// Buyer's wallet credit consumed by this purchase.
    required String walletApplied,

    /// [totalPrice] minus [walletApplied] — what the pay call charges.
    required String amountDue,

    /// `"unpaid"` is the only value observed live. Kept a String
    /// rather than an enum until a capture shows the other spellings.
    String? paymentStatus,

    /// WHERE THE PURCHASE ITSELF GOT TO — `awaiting_payment`, `paid`
    /// or `cancelled`. Not the same question as [isRedeemed], which is
    /// about the CLAIM.
    ///
    /// `cancelled` means the buyer never paid and the hold lapsed: the
    /// link is dead and the gift cannot be revived, so nothing should
    /// offer to share it. Arrived with `GET /api/gifts/history` on
    /// 2026-09-16; read it through [isDead].
    String? status,

    /// Deadline for paying an unpaid gift. Full ISO-8601 with offset.
    DateTime? paymentExpiresAt,

    /// The claim secret — a UUID. Keys the redeem endpoints. Treat as
    /// a credential.
    required String token,

    /// The shareable claim link, `.../gift/{token}`. This is what the
    /// share sheet sends.
    required String shareUrl,

    /// Whether the gift has been claimed. Independent of payment.
    required bool isRedeemed,

    /// When it was claimed, null while unclaimed. Full ISO-8601.
    DateTime? redeemedAt,

    /// When the gift was bought. Full ISO-8601 with offset.
    required DateTime createdAt,
  }) = _Gift;

  const Gift._();

  factory Gift.fromJson(Map<String, dynamic> json) => _$GiftFromJson(json);

  /// Nothing left to charge — the wallet or a full discount covered it.
  /// Skip `POST /api/gifts/{gift}/pay` entirely when true.
  bool get isAlreadySettled => amountDue == '0.00';

  /// The hold lapsed unpaid — see [status]. The link is dead and the
  /// gift cannot be revived.
  bool get isDead => status == 'cancelled';

  /// Safe to show the share link: the gift is bought, still alive, and
  /// not yet claimed. Re-sharing a redeemed gift only confuses the
  /// recipient; re-sharing a cancelled one sends a dead link.
  bool get isShareable => !isRedeemed && !isDead;
}
