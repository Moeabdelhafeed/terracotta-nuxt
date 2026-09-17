// Package imports:
import 'package:freezed_annotation/freezed_annotation.dart';

part 'gift_package.freezed.dart';
part 'gift_package.g.dart';

/// The single gift package on offer — `GET /api/gifts/package`.
/// Public: no auth needed, so the gift screen can price itself before
/// the customer signs in.
///
/// There is exactly ONE package, not a list: the studio sells gifts at
/// one fixed face value and toggles the whole feature on and off. Call
/// this before rendering the gift entry point.
///
/// **[isActive] false means gifting is SWITCHED OFF** — hide the gift
/// CTA entirely rather than letting the customer fill a form that
/// `POST /api/gifts` will reject.
///
/// [amount] is the face value as a decimal string (`"200.00"`), never a
/// double. It is the price before any promo code; what the customer
/// actually pays comes back from `POST /api/gifts/quote` as a
/// `PriceQuote` (where the same number reappears as `gift_value`).
@freezed
abstract class GiftPackage with _$GiftPackage {
  const factory GiftPackage({
    /// Face value of one gift, as a decimal string (`"200.00"`).
    required String amount,

    /// Whether gifting is currently on offer. False = hide the flow.
    required bool isActive,
  }) = _GiftPackage;

  factory GiftPackage.fromJson(Map<String, dynamic> json) =>
      _$GiftPackageFromJson(json);
}
