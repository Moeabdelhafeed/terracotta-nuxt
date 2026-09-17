// Package imports:
import 'package:freezed_annotation/freezed_annotation.dart';

// Project imports:
import 'workshop_product.dart';

part 'workshop_sub_category.freezed.dart';
part 'workshop_sub_category.g.dart';

/// The middle level of a workshop's catalog tree —
/// `categories[].sub_categories[]` on `GET /api/workshops/{id}`.
///
/// The catalog is exactly TWO levels deep (category -> sub-category ->
/// products); products never hang off a category directly, so a UI that
/// renders this tree can hard-code the depth. In the live capture the
/// category `"Jars"` holds one sub-category `"Scented Jars"` holding two
/// products, meaning a single-sub-category tree is normal — collapse the
/// level rather than showing a group header of one.
///
/// [products] can legitimately be empty (a sub-category the CMS has not
/// stocked yet); skip empty groups instead of rendering a blank section.
@freezed
abstract class WorkshopSubCategory with _$WorkshopSubCategory {
  const factory WorkshopSubCategory({
    required int id,

    /// Already-localized group name (`"Scented Jars"`).
    required String title,

    /// The pickable items. Defaults to empty so a missing or null key
    /// cannot throw.
    @Default(<WorkshopProduct>[]) List<WorkshopProduct> products,
  }) = _WorkshopSubCategory;

  factory WorkshopSubCategory.fromJson(Map<String, dynamic> json) =>
      _$WorkshopSubCategoryFromJson(json);
}
