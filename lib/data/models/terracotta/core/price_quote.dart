// Package imports:
import 'package:freezed_annotation/freezed_annotation.dart';

part 'price_quote.freezed.dart';
part 'price_quote.g.dart';

/// The quote envelope — the priced result of the QUOTE step that every
/// payable flow in Terracotta runs before it creates anything.
///
/// The same shape comes back from all four:
/// - `POST /api/workshops/{id}/price` — booking seats + celebration
/// - `POST /api/shop/cart/quote` — the shop cart with delivery
/// - `POST /api/gifts/quote` — a gift purchase
/// - `POST /api/workshops/bookings/{id}/delivery/quote` — shipping a
///   finished piece
///
/// That identity is why one checkout screen renders all four: the common
/// core ([subtotal], [discountAmount], [totalPrice], [walletApplied],
/// [amountDue]) is present in every response, and the flow-specific keys
/// simply arrive null. A quote creates NOTHING and reserves NOTHING —
/// it is safe to re-request on every input change.
///
/// **EVERY MONETARY FIELD IS A DECIMAL STRING** (`"65.00"`), never a
/// double and never a num. Parse to `Decimal`/`BigInt` minor units if you
/// must do arithmetic; binary floats round `0.1 + 0.2` wrong and the
/// total you show will not match the total you are charged.
///
/// **VAT IS INCLUSIVE.** [vatAmount] is the tax already contained inside
/// [totalPrice] — it is disclosure, not a line to add. Adding it to
/// [totalPrice] overcharges the customer by the VAT twice. The
/// pre-tax figure, when you need one, is [totalExcludingVat].
///
/// **`amountDue == "0.00"` MEANS IT IS ALREADY SETTLED.** The wallet (see
/// [walletApplied]) or a 100% discount covered the whole thing. The
/// caller MUST skip the pay call entirely in that case — posting a
/// payment for zero either 422s or opens a payment sheet for nothing.
/// Check [isAlreadySettled] and go straight to create/confirm.
///
/// Nullability follows the live captures. Present in all three sampled
/// quotes → required. Absent from the gift quote → [vatRate],
/// [vatAmount], [totalExcludingVat] are nullable. Absent from the
/// workshop quote → [deliveryFee] is nullable. Flow-specific keys
/// ([deliveryZone], [giftValue], and the whole workshop block) are
/// nullable because only one flow ever sends them. [discountCode] is
/// null whenever no code was applied.
@freezed
abstract class PriceQuote with _$PriceQuote {
  const factory PriceQuote({
    // ---- common core: present in every quote ----
    /// Line-items total before delivery, discount, VAT and wallet.
    required String subtotal,

    /// Amount taken off by [discountCode]. `"0.00"` when none applied.
    required String discountAmount,

    /// What the customer pays. VAT-INCLUSIVE — do not add [vatAmount].
    required String totalPrice,

    /// Wallet credit consumed by this quote. `"0.00"` when none.
    required String walletApplied,

    /// [totalPrice] minus [walletApplied] — what the payment step
    /// charges. `"0.00"` means already settled; see [isAlreadySettled].
    required String amountDue,

    /// The discount code the quote was priced with. Null when no code
    /// was sent or the code did not apply.
    String? discountCode,

    // ---- tax block: absent from the gift quote ----
    /// VAT percentage as a decimal string (`"15.00"`, `"0.00"`).
    String? vatRate,

    /// VAT already INSIDE [totalPrice]. Display only. Never add it.
    String? vatAmount,

    /// [totalPrice] with the inclusive VAT backed out.
    String? totalExcludingVat,

    // ---- delivery: shop + gift quotes ----
    /// Shipping charge folded into [totalPrice]. Absent on the workshop
    /// booking quote, which has nothing to ship.
    String? deliveryFee,

    /// Human-readable zone the fee was priced for (`"Riyadh"`). Shop
    /// quote only.
    String? deliveryZone,

    // ---- gift flow only ----
    /// Face value of the gift being bought. Gift quote only.
    String? giftValue,

    // ---- workshop booking flow only ----
    /// Workshop being priced.
    int? workshopId,

    /// The specific dated slot being priced.
    int? workshopSlotId,

    /// Seats requested.
    int? peopleCount,

    /// Price of one seat.
    String? unitPrice,

    /// Whether the celebration add-on was included in this quote.
    bool? hasCelebration,

    /// Cost of the celebration add-on (quoted whether or not
    /// [hasCelebration] is true — check the flag before showing it).
    String? celebrationPrice,

    // ---- delivery flow only ----
    /// Whether the delivery fee has ALREADY been settled.
    ///
    /// The fee is charged once: switching a finished piece to pickup
    /// and back is free, and what was paid is never refunded. `true`
    /// means there is nothing left to take, and the screen says so
    /// instead of asking for the money a second time. Absent on every
    /// other quote.
    bool? alreadyPaid,
  }) = _PriceQuote;

  const PriceQuote._();

  factory PriceQuote.fromJson(Map<String, dynamic> json) =>
      _$PriceQuoteFromJson(json);

  /// Nothing left to charge — the wallet or a full discount covered it.
  ///
  /// When true the caller MUST NOT make the pay call; go straight to
  /// create/confirm. Paying `"0.00"` is an error, not a no-op.
  bool get isAlreadySettled => amountDue == '0.00';
}
