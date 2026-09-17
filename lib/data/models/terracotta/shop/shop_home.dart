// Package imports:
import 'package:freezed_annotation/freezed_annotation.dart';

// Project imports:
import 'product.dart';
import 'shop_category.dart';

part 'shop_home.freezed.dart';
part 'shop_home.g.dart';

/// The whole shop landing screen in one call — the `data` object of
/// `GET /api/shop/home`.
///
/// Three rails, no pagination, no cursor: the endpoint returns the
/// curated view and nothing else. Product paging happens later, in
/// `GET /api/shop/products`.
///
/// **[categories] ARE THE IMAGE-BEARING HALF.** Here each `ShopCategory`
/// carries its chip artwork but NOT its `sub_categories` — the drill-down
/// tree only ever comes from `GET /api/shop/categories`. See the trap
/// documented on `ShopCategory`; do not cache one over the other.
///
/// **[featuredProducts] AND [offers] ARE THE SAME SHAPE AND THEY
/// OVERLAP.** Both are plain product cards, and in the live capture two
/// products ("Abbasi Cups 1", "Small Vases 1") appear in BOTH lists.
/// Anything keyed by product id across the two rails — a hero
/// animation tag, a selection set, a favourite toggle — must key by
/// `(rail, id)` or it will collide mid-screen.
///
/// The two rails are curated on different axes: [featuredProducts] is
/// the CMS `is_featured` flag, while [offers] is simply every product
/// with a non-null `sale_price`. An offer is NOT necessarily featured —
/// three of the five live offers have `is_featured: false`.
///
/// All three keys are present in the capture; each defaults to empty so
/// a quiet merchandising week (no offers running) renders an absent key
/// as a hidden rail instead of throwing at parse time. Render a rail
/// only when its list is non-empty.
@freezed
abstract class ShopHome with _$ShopHome {
  const factory ShopHome({
    /// Category chips. Carry `image`, never `sub_categories`.
    @Default(<ShopCategory>[]) List<ShopCategory> categories,

    /// The CMS-flagged rail (`is_featured: true`).
    @Default(<Product>[]) List<Product> featuredProducts,

    /// Every product currently carrying a `sale_price`. May share
    /// members with [featuredProducts].
    @Default(<Product>[]) List<Product> offers,
  }) = _ShopHome;

  factory ShopHome.fromJson(Map<String, dynamic> json) =>
      _$ShopHomeFromJson(json);
}
