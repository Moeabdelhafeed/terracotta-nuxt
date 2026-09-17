// Package imports:
import 'package:freezed_annotation/freezed_annotation.dart';

// Project imports:
import '../core/api_image.dart';

part 'home_category.freezed.dart';
part 'home_category.g.dart';

/// A shop category tile as the home screen shows it — an element of
/// `data.categories` in `GET /api/home`.
///
/// **This is the trimmed card, not the full category.** `GET
/// /api/shop/categories` returns the same [id] and [title] with a
/// `sub_categories` list and no image; this one carries the [image] and
/// no children. They are different projections of one CMS row — join on
/// [id], do not expect one to substitute for the other.
///
/// The identical shape also comes back as `data.categories` from
/// `GET /api/shop/home`. If that endpoint's model lands with the same
/// three fields, promote one of them to `terracotta/core/` and delete
/// the other rather than letting the two drift.
///
/// **[image] IS NULLABLE, and that is not a nicety.** It was declared
/// required on the strength of four captures that all had one — and
/// the first category the studio saved without a picture took the
/// WHOLE home payload down with it: `ApiImage.fromJson(json['image']
/// as Map<String, dynamic>)` on a null threw inside `fromJson`, so
/// banners, offers and the rest never parsed either. `CLAUDE.md` says
/// it in one line: images are objects, and null when missing.
///
/// Paint `image?.display`, never `image.url`.
@freezed
abstract class HomeCategory with _$HomeCategory {
  const factory HomeCategory({
    /// CMS id — the value a `shop_category` banner's `link_target_id`
    /// points at, and the key to join against the full category list.
    required int id,

    /// Display name, already localized by the CMS ("Cups", "Vases").
    required String title,

    /// Category artwork.
    ApiImage? image,
  }) = _HomeCategory;

  factory HomeCategory.fromJson(Map<String, dynamic> json) =>
      _$HomeCategoryFromJson(json);
}
