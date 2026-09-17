// Package imports:
import 'package:freezed_annotation/freezed_annotation.dart';

// Project imports:
import '../core/api_image.dart';

part 'workshop_product.freezed.dart';
part 'workshop_product.g.dart';

/// One pickable item in a workshop's catalog — the leaf of the
/// `categories[].sub_categories[].products[]` tree on
/// `GET /api/workshops/{id}`.
///
/// This is the bisque piece the customer paints, or the jar they pour a
/// candle into. It is NOT a shop product: it is only purchasable as part
/// of a booking, it has no stock or delivery fields, and it lives at a
/// different endpoint.
///
/// **[id] IS THE `workshop_product_id` YOU POST BACK.** The catalog
/// sends it as `id`; the booking payloads
/// (`GET /api/workshops/bookings`, `.../bookings/{id}`) echo the same
/// number back as `workshop_product_id`. Same integer, two names — do
/// not go looking for a `workshop_product_id` key here, and do not
/// confuse it with the shop's product ids.
///
/// **[price] IS A DECIMAL STRING** (`"10.00"`). This is the per-unit
/// price and it is ADDITIVE to the workshop's seat price: the live
/// booking for the candle workshop has a `"0.00"` seat price and a
/// `"22.00"` total, which is exactly these two products. Never sum
/// these as doubles — send the selection to
/// `POST /api/workshops/{id}/price` and display what comes back.
///
/// Nullability: [subtitle] is null on both captured products.
/// [images] is `[]` on both, so the element shape is inferred from the
/// rest of the API (`ApiImage`) rather than observed — the first
/// non-empty capture is worth re-checking.
@freezed
abstract class WorkshopProduct with _$WorkshopProduct {
  const factory WorkshopProduct({
    /// The catalog id. Echoed as `workshop_product_id` on bookings.
    required int id,

    /// Already-localized product name (`"Lavender Jar"`).
    ///
    /// NULLABLE — verified live on 2026-09-07, where the first real
    /// catalogue row on dev came back `"title": null`. Declared
    /// required it threw inside `fromJson` and took the WHOLE workshop
    /// detail with it: the catalogue screen showed its failure state
    /// for a workshop whose products were all there. The CMS lets an
    /// admin save a product with no name in the requested locale, so
    /// this is a state the app has to draw, not one to assert away.
    String? title,

    /// Per-unit price as a decimal string. Additive to the seat price.
    required String price,

    /// Secondary line. Null on every captured product.
    String? subtitle,

    /// Product photos. Empty on every captured product; defaults to an
    /// empty list so a missing or null key cannot throw.
    @Default(<ApiImage>[]) List<ApiImage> images,
  }) = _WorkshopProduct;

  const WorkshopProduct._();

  factory WorkshopProduct.fromJson(Map<String, dynamic> json) =>
      _$WorkshopProductFromJson(json);

  /// First image, or null when the CMS has not attached one. Paint it
  /// via `.display`, never `.url`.
  ApiImage? get primaryImage => images.isEmpty ? null : images.first;
}
