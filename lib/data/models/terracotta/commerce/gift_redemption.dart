// Package imports:
import 'package:freezed_annotation/freezed_annotation.dart';

part 'gift_redemption.freezed.dart';
part 'gift_redemption.g.dart';

/// What a claim credited — `POST /api/gifts/{token}/redeem`.
///
/// **Needs a session.** Verified live on 2026-09-10: without a bearer
/// it answers 401 «You need to sign in to do that.» — and in this app a
/// 401 is the session ENDING (`SessionExpiry` clears the token and
/// re-runs the guards). So this call must never be made until there is
/// an account behind it, or claiming a gift would sign the reader out
/// of one they had.
///
/// Single-use, and the purchaser cannot claim their own. Both refusals
/// come back as a 422 keyed on `errors.gift` with a localized message —
/// read it with `error.fieldError('gift')`.
///
/// Both fields are decimal STRINGS. [walletBalance] is the balance
/// AFTER the credit, which is the number worth showing: it answers
/// "what do I have now", where [amount] only repeats what the gift
/// said it was worth.
@freezed
abstract class GiftRedemption with _$GiftRedemption {
  const factory GiftRedemption({
    /// What the gift was worth, as a decimal string.
    required String amount,

    /// The wallet AFTER the credit landed. Decimal string.
    required String walletBalance,
  }) = _GiftRedemption;

  factory GiftRedemption.fromJson(Map<String, dynamic> json) =>
      _$GiftRedemptionFromJson(json);
}
