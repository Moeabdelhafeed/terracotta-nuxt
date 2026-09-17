// Package imports:
import 'package:freezed_annotation/freezed_annotation.dart';

// Project imports:
import '../core/api_image.dart';

part 'product.freezed.dart';
part 'product.g.dart';

/// One product as it appears in a LIST — the repeated card of the shop.
///
/// The identical seven keys come back from every listing surface:
/// - `GET /api/shop/products` — the catalogue
/// - `GET /api/shop/home` — both `featured_products` and `offers`
/// - `GET /api/shop/products/{id}` — the `related_products` rail
/// - `GET /api/home` — the app home reuses this exact block
///
/// This is the LIST shape ONLY. `GET /api/shop/products/{id}` returns a
/// superset (gallery, colours, dimensions, description, related rail)
/// modelled as `ProductDetail`. Do not stretch this one to cover both —
/// a card built from a list response has no gallery to show.
///
/// **MONEY IS A DECIMAL STRING.** [price] and [salePrice] arrive as
/// `"45.00"` / `"35.00"`, never as numbers. Keep them String all the way
/// to the label; parsing to double to "format" it re-introduces the
/// rounding the API went out of its way to avoid.
///
/// **[salePrice] IS THE OFFER FLAG.** It is null on 10 of the 15
/// products in the live catalogue and non-null on every entry of the
/// home `offers` list — that is what makes something an offer. There is
/// no separate `is_on_sale` boolean. Read [isOnSale] / [effectivePrice]
/// rather than comparing the two strings yourself.
///
/// **[image] CAN BE NULL** — product 6 ("Espresso Cups 3") ships with
/// `"image": null` in the live catalogue while every other row has one.
/// A grid that assumes a thumbnail crashes on that single row. Paint it
/// through `image?.display` (never `image.url`, which is relative and
/// 404s) and fall back to a placeholder.
///
/// [isFeatured] and [isFavorited] are present and non-null on every
/// captured product. [isFavorited] is per-user state, so it goes stale
/// the moment the favourites endpoint is hit — refresh the list or patch
/// the item locally after a toggle.
@freezed
abstract class Product with _$Product {
  const factory Product({
    /// Product id — the path segment for `GET /api/shop/products/{id}`
    /// and the identifier the cart and favourites endpoints take.
    required int id,

    /// Already-localized display name for the requested locale.
    required String title,

    /// List price as a decimal string (`"45.00"`). Never a double.
    required String price,

    /// Discounted price as a decimal string (`"35.00"`), or null when
    /// the product is not on offer. Non-null is what makes it an offer.
    String? salePrice,

    /// Card thumbnail. NULL for CMS rows whose image has not been set —
    /// render through `image?.display` with a placeholder fallback.
    ApiImage? image,

    /// CMS-curated flag driving the home `featured_products` rail.
    /// Independent of [salePrice] — a product can be featured, on
    /// offer, both, or neither.
    required bool isFeatured,

    /// Per-user favourite state at the time this list was fetched.
    required bool isFavorited,

    /// Whether the studio has any of this to sell. False is a piece the
    /// card must not offer an add button for.
    required bool inStock,

    /// How many are left, or NULL when the CMS row tracks no stock at
    /// all — 13 of the 15 live products are untracked. Null therefore
    /// means "no limit worth showing", NOT "none left"; that is
    /// [inStock].
    int? stock,

    /// The most one order may take: [stock] when it is tracked, and a
    /// flat 100 when it is not. Asking for more is a 422 either way —
    /// `errors.cart` names the piece and the number when stock is the
    /// reason, `errors.quantity` when the 100 cap is.
    required int maxQuantity,
  }) = _Product;

  const Product._();

  factory Product.fromJson(Map<String, dynamic> json) =>
      _$ProductFromJson(json);

  /// Whether the product is on offer — i.e. the API sent a [salePrice].
  bool get isOnSale => salePrice != null;

  /// The price the customer actually pays, as a decimal string.
  ///
  /// [salePrice] when on offer, [price] otherwise. Show [price] struck
  /// through beside it only when [isOnSale] is true.
  String get effectivePrice => salePrice ?? price;
}
