// Package imports:
import 'package:freezed_annotation/freezed_annotation.dart';

// Project imports:
import 'line_product.dart';

part 'order_item.freezed.dart';
part 'order_item.g.dart';

/// One line of a placed order — an element of `items` in
/// `GET /api/shop/orders`, `GET /api/shop/orders/{order}` and the
/// order returned by `POST /api/shop/cart/checkout`.
///
/// Field-for-field identical to a `CartItem` (checkout copies the cart
/// lines), and kept as its own type because the two ids mean different
/// things and are used against different endpoints: an [id] here is an
/// ORDER line and addresses nothing — orders are immutable, there is no
/// `/api/shop/orders/{order}/items/{item}`. Only the whole order can be
/// cancelled (`DELETE /api/shop/orders/{order}`). Never feed this id to
/// `/api/shop/cart/{item}`.
///
/// **[unitPrice] is the historical price, and this is where it matters
/// most.** [product] is re-serialized from the CATALOGUE at read time,
/// so a product the studio has since repriced or discounted shows new
/// numbers in [product] while the money the customer actually paid
/// stays in [unitPrice] / [lineTotal]. Receipts render the line, never
/// the product.
///
/// [color] is a hex swatch (`"#c96f4a"`); it is non-null in every
/// captured order but typed nullable because a line whose product has
/// no colours is created with `"color": null` (the cart capture shows
/// exactly that shape).
@freezed
abstract class OrderItem with _$OrderItem {
  const factory OrderItem({
    /// Order line id. Identifies the row, addresses no endpoint.
    required int id,

    /// Catalogue snapshot at READ time — not the price paid.
    required LineProduct product,

    /// Units ordered.
    required int quantity,

    /// Price of one unit at the moment of checkout. Decimal string.
    required String unitPrice,

    /// Chosen colour as a hex string, null when the product had none.
    String? color,

    /// [unitPrice] × [quantity], server-computed. Decimal string.
    required String lineTotal,
  }) = _OrderItem;

  factory OrderItem.fromJson(Map<String, dynamic> json) =>
      _$OrderItemFromJson(json);
}
