// Package imports:
import 'package:freezed_annotation/freezed_annotation.dart';

// Project imports:
import '../core/api_image.dart';

part 'line_product.freezed.dart';
part 'line_product.g.dart';

/// The compact product shape the commerce lines embed — the `product`
/// object inside every cart line (`GET /api/shop/cart`) and every order
/// line (`GET /api/shop/orders`, `GET /api/shop/orders/{order}`,
/// `POST /api/shop/cart/checkout`).
///
/// It is the SAME seven-key summary the shop listing endpoints return
/// (`GET /api/shop/products`, `featured_products` in `/api/home` and
/// `/api/shop/home`, `related_products` in `/api/shop/products/{id}`).
/// It is declared here because the commerce group needs a type for the
/// nested object; if the shop group ever lands a product-summary model
/// with these exact fields, fold this into it rather than keeping two.
///
/// **It is a SNAPSHOT of the catalogue row, not the line's price.**
/// [price] / [salePrice] are what the product costs *today*; what the
/// customer is actually charged is the line's own `unit_price`, which
/// was frozen when the item entered the cart. On an old order the two
/// will disagree — render the line's `unit_price`, never [price].
///
/// [image] is nullable: the same product resource comes back with
/// `"image": null` in the `/api/shop/products` capture (a catalogue row
/// whose media has not been uploaded), so a required field here would
/// crash a cart the admin half-populated. Paint it via
/// `image?.display` — never `image!.url`, which is storage-relative and
/// 404s.
///
/// [salePrice] is null whenever the product is not discounted (cart
/// line 2 of the live capture). Money is a decimal string throughout —
/// see [effectivePrice].
@freezed
abstract class LineProduct with _$LineProduct {
  const factory LineProduct({
    /// Catalogue product id — this is what `/api/shop/products/{id}`
    /// and `/api/shop/favorites/{product}` take. It is NOT the cart or
    /// order line id.
    required int id,

    /// Already localized for the `Accept-Language` of the request.
    required String title,

    /// List price as a decimal string (`"45.00"`). Never a double.
    required String price,

    /// Discounted price as a decimal string, or null when not on sale.
    String? salePrice,

    /// Thumbnail. Nullable — see the class doc.
    ApiImage? image,

    /// Merchandising flag from the CMS.
    required bool isFeatured,

    /// Whether the CALLER has favourited it. Reflects the caller's
    /// account, so it flips after `POST/DELETE /api/shop/favorites`.
    required bool isFavorited,

    /// Whether the studio has any of this to sell — **null on an ORDER
    /// line**, where it would be meaningless: an order is a record of
    /// what was bought, not an offer to buy it again. The server sends
    /// it on every CART line. Null is "unknown", never "sold out".
    bool? inStock,

    /// How many are left, or NULL when the CMS row tracks no stock at
    /// all — 13 of the 15 live products are untracked. Null therefore
    /// means "no limit worth showing", NOT "none left"; that is
    /// [inStock].
    int? stock,

    /// The most one order may take: [stock] when it is tracked, and a
    /// flat 100 when it is not. Asking for more is a 422 either way —
    /// `errors.cart` names the piece and the number when stock is the
    /// reason, `errors.quantity` when the 100 cap is. Null on an order
    /// line, for the same reason as [inStock].
    int? maxQuantity,
  }) = _LineProduct;

  const LineProduct._();

  factory LineProduct.fromJson(Map<String, dynamic> json) =>
      _$LineProductFromJson(json);

  /// What the catalogue would charge for this product right now:
  /// [salePrice] when it is on sale, [price] otherwise.
  ///
  /// For an existing cart/order line, prefer the line's own
  /// `unit_price` — this getter is for re-add / "buy again" flows.
  String get effectivePrice => salePrice ?? price;

  /// True when the CMS is running a discount on this product.
  bool get isOnSale => salePrice != null;
}
