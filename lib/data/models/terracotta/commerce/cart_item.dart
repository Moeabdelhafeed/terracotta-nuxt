// Package imports:
import 'package:freezed_annotation/freezed_annotation.dart';

// Project imports:
import 'line_product.dart';

part 'cart_item.freezed.dart';
part 'cart_item.g.dart';

/// One line of the shopping cart — an element of `items` in
/// `GET /api/shop/cart`, and what `POST /api/shop/cart` adds.
///
/// **TRAP — [id] is the CART LINE id, not the product id.** The mutation
/// endpoints (`PATCH /api/shop/cart/{item}` to change quantity,
/// `DELETE /api/shop/cart/{item}` to remove) take THIS id. Sending
/// `product.id` there edits or deletes the wrong line, or 404s. The live
/// capture makes the mistake easy to miss: line `3` holds product `1`
/// and line `6` holds product `2`.
///
/// **[unitPrice] is the FROZEN price, `product.price` is the live one.**
/// The cart charges [unitPrice] × [quantity] = [lineTotal]. In the
/// capture the product lists at `"45.00"` with a `"35.00"` sale price
/// and the line's `unit_price` is `"35.00"` — display the line's number,
/// never recompute from the product.
///
/// [color] is a hex swatch string (`"#c96f4a"`) chosen from the
/// product's `colors` list, or null when the customer picked none — the
/// second line of the live capture has `"color": null`. Parse it as a
/// colour; it is not a name.
///
/// **There is NO `size` on a cart line.** The shop's variants are colour
/// only in the live API.
///
/// Every monetary field is a decimal string.
@freezed
abstract class CartItem with _$CartItem {
  const factory CartItem({
    /// Cart LINE id — the `{item}` of `/api/shop/cart/{item}`.
    required int id,

    /// Catalogue snapshot of what is on this line.
    required LineProduct product,

    /// Chosen colour as a hex string (`"#c96f4a"`), null when the
    /// customer picked none.
    String? color,

    /// How many. The cart's own endpoints clamp this to stock.
    required int quantity,

    /// Price of ONE unit, frozen when the line was created. Decimal
    /// string (`"35.00"`).
    required String unitPrice,

    /// [unitPrice] × [quantity] as computed by the server. Decimal
    /// string — do not recompute it in Dart floats.
    required String lineTotal,

    /// Whether the PIECE is still sellable, as of this read. A cart
    /// outlives the stock it was filled from.
    @Default(true) bool inStock,

    /// How many are left for this line right now, or null when the
    /// piece tracks no stock. `quantity > availableStock` is a line the
    /// customer cannot check out with — the whole reason the server
    /// sends it back on every cart read.
    int? availableStock,
  }) = _CartItem;

  factory CartItem.fromJson(Map<String, dynamic> json) =>
      _$CartItemFromJson(json);
}
