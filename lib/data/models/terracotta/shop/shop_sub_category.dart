// Package imports:
import 'package:freezed_annotation/freezed_annotation.dart';

part 'shop_sub_category.freezed.dart';
part 'shop_sub_category.g.dart';

/// The middle link of the shop taxonomy: Category -> SubCategory ->
/// Product.
///
/// Nested inside every entry of `GET /api/shop/categories` as
/// `sub_categories`. It carries an id and a name and NOTHING else — no
/// image, no product count, no parent pointer. The category tree is
/// therefore two levels deep and fully delivered by that one call; there
/// is no `GET /api/shop/sub-categories` to page through.
///
/// [id] is what `GET /api/shop/products` filters on to list the products
/// underneath — the leaf of the chain. [title] is already localized for
/// the requested locale; display it as-is.
///
/// Both keys are present and non-null on all five sub-categories in the
/// live capture.
@freezed
abstract class ShopSubCategory with _$ShopSubCategory {
  const factory ShopSubCategory({
    /// Sub-category id — the filter value for the product listing.
    required int id,

    /// Already-localized display name (`"Abbasi Cups"`).
    required String title,
  }) = _ShopSubCategory;

  factory ShopSubCategory.fromJson(Map<String, dynamic> json) =>
      _$ShopSubCategoryFromJson(json);
}
