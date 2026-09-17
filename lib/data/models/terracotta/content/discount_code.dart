import 'package:freezed_annotation/freezed_annotation.dart';

part 'discount_code.freezed.dart';
part 'discount_code.g.dart';

/// A promo code the studio is advertising — `GET /api/discount-codes`.
///
/// **The list is what this customer can still use.** The server returns
/// only PUBLIC codes that are active, started, unexpired and have room
/// left against both the overall usage limit and this customer's own —
/// so a code on the list is one they can type today. An empty list
/// means there is nothing to advertise, not that codes do not exist: a
/// private code still validates when typed.
///
/// **A code never touches the delivery fee.** The discount comes off
/// the goods subtotal, then delivery is added on top — so the free
/// delivery threshold is measured on the POST-discount total and a
/// promo cannot tip an order into free delivery it did not earn.
@freezed
abstract class DiscountCode with _$DiscountCode {
  const factory DiscountCode({
    /// Upper-cased by the server on save, and matched case-insensitively
    /// when typed.
    required String code,

    /// `percent` or `fixed`. Read via [isPercent] rather than switching
    /// on the string: a third kind added later must not crash a
    /// shipped build.
    required String type,

    /// A DECIMAL STRING either way — `"10.00"` is ten percent on a
    /// percent code and ten riyals on a fixed one.
    required String value,

    /// The ceiling on a percent code's discount. Null means none.
    String? maxDiscount,

    /// What the goods have to come to before the code applies. Null
    /// means any total. The server refuses below it with
    /// `api.discount_code_min_total_not_met`.
    String? minOrderTotal,

    /// When it stops working. Null is open-ended.
    DateTime? endsAt,
  }) = _DiscountCode;

  const DiscountCode._();

  factory DiscountCode.fromJson(Map<String, dynamic> json) =>
      _$DiscountCodeFromJson(json);

  bool get isPercent => type == 'percent';
}
