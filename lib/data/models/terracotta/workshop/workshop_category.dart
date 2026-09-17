// Package imports:
import 'package:freezed_annotation/freezed_annotation.dart';

// Project imports:
import 'workshop_sub_category.dart';

part 'workshop_category.freezed.dart';
part 'workshop_category.g.dart';

/// The top level of a workshop's product catalog — `categories[]` on
/// `GET /api/workshops/{id}`.
///
/// Only the detail payload carries this; the list endpoint
/// (`GET /api/workshops`) has no catalog at all, which is the practical
/// reason the booking flow must call the detail endpoint before it can
/// show a product step.
///
/// The tree is category -> [WorkshopSubCategory] -> `WorkshopProduct`,
/// always two levels — there are no products directly on a category.
///
/// An entire `categories` list is `[]` for `make_your_piece` workshops,
/// which have no catalog. Gate the product step on the list being
/// non-empty (or on `Workshop.requiresProductSelection`), not on the
/// workshop type string.
@freezed
abstract class WorkshopCategory with _$WorkshopCategory {
  const factory WorkshopCategory({
    required int id,

    /// Already-localized category name (`"Jars"`).
    required String title,

    /// Sub-groups holding the actual products. Defaults to empty so a
    /// missing or null key cannot throw.
    @Default(<WorkshopSubCategory>[]) List<WorkshopSubCategory> subCategories,
  }) = _WorkshopCategory;

  factory WorkshopCategory.fromJson(Map<String, dynamic> json) =>
      _$WorkshopCategoryFromJson(json);
}
