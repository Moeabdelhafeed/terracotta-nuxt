// Package imports:
import 'package:freezed_annotation/freezed_annotation.dart';

// Project imports:
import '../core/api_image.dart';
import 'shop_sub_category.dart';

part 'shop_category.freezed.dart';
part 'shop_category.g.dart';

/// The top level of the shop taxonomy: Category -> SubCategory ->
/// Product.
///
/// **TRAP — THE TWO ENDPOINTS SEND DIFFERENT HALVES OF THIS SHAPE.**
/// The same four categories come back from both, but each drops what
/// the other carries:
/// - `GET /api/shop/categories` sends `id` + `title` +
///   `sub_categories`, and **no `image`**.
/// - `GET /api/shop/home` → `categories` sends `id` + `title` +
///   `image`, and **no `sub_categories`**.
///
/// That is why [image] is nullable and [subCategories] defaults to
/// empty: neither is a statement about the category, only about which
/// call you made. A home-fetched category with an empty
/// [subCategories] is NOT a leaf — re-fetch the categories endpoint
/// before deciding a drill-down has nothing under it, and do not cache
/// one response over the other or you will erase whichever half was
/// already loaded.
///
/// [id] is the filter value for `GET /api/shop/products`. [title] is
/// already localized for the requested locale — display it as-is, do
/// not look it up in the ARB.
///
/// [image] is the circular chip on the shop home; paint it via
/// `image!.display`, never `image.url` (relative, 404s).
@freezed
abstract class ShopCategory with _$ShopCategory {
  const factory ShopCategory({
    /// Category id — the filter value for the product listing.
    required int id,

    /// Already-localized display name (`"Incense Burners"`).
    required String title,

    /// Category chip artwork. Sent ONLY by the shop-home payload; the
    /// categories endpoint omits the key entirely.
    ApiImage? image,

    /// Children. Sent ONLY by `GET /api/shop/categories`; empty here
    /// means "this response did not carry them", not "none exist".
    @Default(<ShopSubCategory>[]) List<ShopSubCategory> subCategories,
  }) = _ShopCategory;

  factory ShopCategory.fromJson(Map<String, dynamic> json) =>
      _$ShopCategoryFromJson(json);
}
