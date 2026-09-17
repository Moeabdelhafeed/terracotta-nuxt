// Package imports:
import 'package:freezed_annotation/freezed_annotation.dart';

// Project imports:
import 'cart_item.dart';

part 'cart.freezed.dart';
part 'cart.g.dart';

/// The customer's shopping cart — `GET /api/shop/cart`, and the body
/// echoed back by every cart mutation (`POST /api/shop/cart`,
/// `PATCH /api/shop/cart/{item}`, `DELETE /api/shop/cart/{item}`).
///
/// The cart has NO id of its own: it is the caller's single cart,
/// addressed only through the endpoint.
///
/// **TRAP — [totalPrice] is NOT what the customer pays.** It is the sum
/// of the line totals and nothing else: no delivery fee, no discount
/// code, no VAT, no wallet. The payable figure comes from
/// `POST /api/shop/cart/quote`, which returns a `PriceQuote` — that is
/// the number the checkout screen must show. In the live capture the
/// cart says `"130.00"` while the quote for the same cart says
/// `"150.00"` (delivery `"20.00"`). Showing [totalPrice] as "total"
/// under-quotes the customer by the delivery fee.
///
/// [items] carries a `@Default` rather than `required`: an empty cart is
/// the most common state in the app and must never be a parse crash,
/// whether the server sends `"items": []` or omits the key.
@freezed
abstract class Cart with _$Cart {
  const factory Cart({
    /// The lines, newest last. Empty for a fresh customer.
    @Default(<CartItem>[]) List<CartItem> items,

    /// Sum of the lines' `line_total` as a decimal string
    /// (`"130.00"`). Items only — see the class doc.
    required String totalPrice,
  }) = _Cart;

  const Cart._();

  factory Cart.fromJson(Map<String, dynamic> json) => _$CartFromJson(json);

  /// Nothing in the cart — render the empty state (the CMS ships an
  /// `empty_cart_image` in `/api/app-settings` for exactly this).
  bool get isEmpty => items.isEmpty;

  /// Total units across all lines — the number for the tab-bar badge.
  /// Distinct from `items.length`, which counts LINES.
  int get itemCount => items.fold<int>(0, (sum, item) => sum + item.quantity);
}
