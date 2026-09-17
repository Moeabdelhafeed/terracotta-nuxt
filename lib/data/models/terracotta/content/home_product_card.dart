// Package imports:
import 'package:freezed_annotation/freezed_annotation.dart';

// Project imports:
import '../core/api_image.dart';
import '../shop/product.dart';

part 'home_product_card.freezed.dart';
part 'home_product_card.g.dart';

/// A product as a grid tile — the element shape of **both**
/// `data.featured_products` and `data.offers` in `GET /api/home`.
///
/// The two lists are the same seven-field shape and they **overlap**:
/// "Abbasi Cups 1" and "Small Vases 1" appear in both captures. Render
/// them as two independent rails; do not assume disjoint sets and do not
/// dedupe across them.
///
/// The identical shape is also `featured_products` / `offers` on
/// `GET /api/shop/home`, and it is a strict subset of the product
/// detail payload. When the shop group's model lands, promote one copy
/// to `terracotta/core/` rather than maintaining two.
///
/// **MONEY IS A DECIMAL STRING** (`"45.00"`) — never double, never num.
/// Float arithmetic rounds totals wrong; see `PriceQuote`.
///
/// **[salePrice] is the discounted price and [price] is the original.**
/// When [salePrice] is non-null, show it as the live price and strike
/// [price] through; the capture never sends a sale price higher than the
/// price. When it is null there is no discount — show [price] plain.
/// This is the only field in the shape that is ever null, and it is null
/// on two of the four featured products.
///
/// **[isFeatured] does not mean "in the featured list".** Two of the
/// five entries in `offers` carry `is_featured: true` — it is the CMS
/// flag on the product row, not this list's membership. Deriving the
/// rail from it produces the wrong grid; use the list the field came in.
///
/// [isFavorited] is per-user and `false` for every entry in the
/// unauthenticated capture. Expect it to be meaningful only on a
/// request that carries a token, and drive the heart from it.
@freezed
abstract class HomeProductCard with _$HomeProductCard {
  const factory HomeProductCard({
    /// Product id — what `GET /api/shop/products/{id}` and a
    /// `shop_product` banner's `link_target_id` use.
    required int id,

    /// Product name, already localized by the CMS.
    required String title,

    /// Original price. Decimal string.
    required String price,

    /// Discounted price, or null when not on sale. Decimal string.
    String? salePrice,

    /// Product thumbnail.
    ApiImage? image,

    /// The CMS "featured" flag on the product row — **not** a statement
    /// about which list this came in.
    required bool isFeatured,

    /// Whether the authenticated user has favourited it. Always false
    /// on an unauthenticated request.
    required bool isFavorited,

    /// Whether the studio has any of this to sell.
    required bool inStock,

    /// How many are left, or NULL when the CMS row tracks no stock —
    /// 13 of the 15 live products are untracked. Null means "no limit
    /// worth showing", NOT "none left"; that is [inStock].
    int? stock,

    /// The most one order may take: [stock] when tracked, a flat 100
    /// when not.
    required int maxQuantity,
  }) = _HomeProductCard;

  const HomeProductCard._();

  /// The same row, as a shop [Product].
  ///
  /// The two models carry exactly the same fields — the home payload
  /// and the shop payload describe one product two ways — so nothing
  /// here is invented. A guest's wishlist stores `Product`, and this
  /// is what lets a heart on the home rails be saved without a request
  /// the reader has no session for.
  Product toProduct() => Product(
    id: id,
    title: title,
    price: price,
    salePrice: salePrice,
    image: image,
    isFeatured: isFeatured,
    isFavorited: isFavorited,
    inStock: inStock,
    stock: stock,
    maxQuantity: maxQuantity,
  );

  factory HomeProductCard.fromJson(Map<String, dynamic> json) =>
      _$HomeProductCardFromJson(json);

  /// The price the customer actually pays — [salePrice] when on sale,
  /// otherwise [price]. Still a decimal string.
  String get effectivePrice => salePrice ?? price;

  /// Whether to strike [price] through and show a discount badge.
  bool get isOnSale => salePrice != null;
}
