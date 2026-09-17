// Package imports:
import 'package:freezed_annotation/freezed_annotation.dart';

// Project imports:
import '../core/api_image.dart';
import 'product.dart';

part 'product_detail.freezed.dart';
part 'product_detail.g.dart';

/// A single product in full — the `data` object of
/// `GET /api/shop/products/{id}`.
///
/// A strict superset of the list shape: the seven `Product` keys arrive
/// here verbatim, plus the description, gallery, colours, dimensions,
/// taxonomy labels and the related rail. `Product` stays a separate
/// model because the listing endpoints send only that half; use
/// [toListItem] to hand a detail to a widget that takes a card.
///
/// **MONEY IS A DECIMAL STRING.** [price] / [salePrice] are `"45.00"` /
/// `"35.00"`. [salePrice] being non-null is the only offer flag there
/// is, and the cart charges `unit_price == "35.00"` for this product —
/// i.e. exactly [effectivePrice]. Never parse either to double.
///
/// **COLOURS ARE BARE HEX STRINGS AND THEY ARE THE VARIANT IDs.**
/// [colors] is `["#c96f4a", "#345a4a", "#2b2b2b"]` — a flat list of
/// strings with no id, no name and no per-colour image or price. The
/// cart echoes the chosen one back as `"color": "#c96f4a"`, so the
/// STRING ITSELF is what you post when adding to cart; there is nothing
/// else to send. `"color"` is nullable on a cart line, so a product with
/// an empty [colors] list is added without one. Six digits, no alpha —
/// convert with
/// `Color(int.parse(hex.substring(1), radix: 16) | 0xFF000000)`.
///
/// **SIZE IS NOT A VARIANT — IT IS THREE FLAT MEASUREMENTS.** There is
/// no `sizes` array and no size to choose: [height], [width] and
/// [length] are decimal strings (`"8.00"`, `"6.00"`, `"6.00"`)
/// describing the one and only SKU. They are informational copy for a
/// spec row, never a selector, and never money — but keep them String
/// anyway, both because that is what the wire sends and because
/// `"8.00"` must not become `8.0` in the label.
///
/// **[category] AND [subCategory] ARE NAMES, NOT IDs.** The payload
/// sends `"Cups"` / `"Abbasi Cups"` — display labels with no numeric id
/// attached. You CANNOT navigate from a detail page back to its category
/// listing from this response alone; match against the ids from
/// `GET /api/shop/categories`, or carry the id in from the screen the
/// user tapped through.
///
/// Nullability: [id], [title], [price], [isFeatured] and [isFavorited]
/// are structural and required. Everything else is optional CMS
/// content — [image] is proven nullable by the catalogue (product 6
/// ships `"image": null`), [salePrice] by ten of fifteen rows, and the
/// remaining descriptive fields are nullable because a half-filled CMS
/// row must render, not throw. The three lists default to empty for the
/// same reason.
@freezed
abstract class ProductDetail with _$ProductDetail {
  const factory ProductDetail({
    // ---- the `Product` half, sent verbatim ----
    /// Product id.
    required int id,

    /// Already-localized display name.
    required String title,

    /// List price as a decimal string (`"45.00"`).
    required String price,

    /// Offer price as a decimal string, or null when not on offer.
    String? salePrice,

    /// Primary/cover image. NULL on CMS rows with no image set — paint
    /// via `image?.display`, never `image.url`.
    ApiImage? image,

    /// CMS-curated home-rail flag.
    required bool isFeatured,

    /// Per-user favourite state at fetch time.
    required bool isFavorited,

    // ---- detail-only additions ----
    /// Long-form localized body copy. Plain text in the capture, not
    /// HTML or Markdown.
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

    String? description,

    /// The gallery. Includes the cover [image] as its first entry, so
    /// rendering both a hero and this list shows the cover twice —
    /// drive the pager from [images] alone.
    @Default(<ApiImage>[]) List<ApiImage> images,

    /// Selectable colourways as `#rrggbb` strings. The string is the
    /// variant identifier the cart takes; empty means no choice.
    @Default(<String>[]) List<String> colors,

    /// Height as a decimal string (`"8.00"`). A measurement, not a
    /// choice and not money.
    String? height,

    /// Width as a decimal string (`"6.00"`).
    String? width,

    /// Length as a decimal string (`"6.00"`).
    String? length,

    /// Parent category NAME (`"Cups"`) — no id travels with it.
    String? category,

    /// Sub-category NAME (`"Abbasi Cups"`) — no id travels with it.
    String? subCategory,

    /// The "you may also like" rail — plain list-shaped cards, so it
    /// feeds the same widget the catalogue grid uses.
    @Default(<Product>[]) List<Product> relatedProducts,
  }) = _ProductDetail;

  const ProductDetail._();

  /// The card-sized half of this, as a [Product].
  ///
  /// The detail payload is the product row plus everything extra —
  /// `// ---- the `Product` half, sent verbatim ----` above says so —
  /// and a guest's wishlist stores the row. This is what lets a heart
  /// on the detail page be saved without a request the reader has no
  /// session for.
  Product toProduct() => Product(
    id: id,
    title: title,
    price: price,
    salePrice: salePrice,
    image: image ?? (images.isEmpty ? null : images.first),
    isFeatured: isFeatured,
    isFavorited: isFavorited,
    inStock: inStock,
    stock: stock,
    maxQuantity: maxQuantity,
  );

  factory ProductDetail.fromJson(Map<String, dynamic> json) =>
      _$ProductDetailFromJson(json);

  /// Whether the product is on offer — i.e. the API sent a [salePrice].
  bool get isOnSale => salePrice != null;

  /// The price the customer actually pays, as a decimal string. Matches
  /// the `unit_price` the cart quotes for this product.
  String get effectivePrice => salePrice ?? price;

  /// The list-shaped half of this detail, for widgets that take a card.
  Product toListItem() => Product(
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
}
