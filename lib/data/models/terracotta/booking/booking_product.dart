// Package imports:
import 'package:freezed_annotation/freezed_annotation.dart';

// Project imports:
import '../core/api_image.dart';

part 'booking_product.freezed.dart';
part 'booking_product.g.dart';

/// One catalogue item picked during a booking — an element of
/// `products[]` on `GET /api/workshops/bookings` and
/// `GET /api/workshops/bookings/{id}`.
///
/// These are the jars, bisque pieces and scents chosen at booking time
/// for the catalogue-priced workshop families (`make_your_candle`,
/// `paint_your_piece`). A `make_your_piece` booking has a flat seat
/// price and an empty `products[]`.
///
/// **This is a booking LINE, not the catalogue product.** [id] is
/// deliberately absent: the wire sends [workshopProductId], which
/// points at the product inside the workshop's `categories[]` tree
/// (`GET /api/workshops/{id}`), not at a row of its own. Two lines for
/// the same product do not appear — the server folds them into
/// [quantity].
///
/// **[unitPrice] IS A DECIMAL STRING** (`"10.00"`), never a double.
/// The line total is `unitPrice x quantity` in decimal arithmetic;
/// binary floats round it wrong. There is no `line_total` on the wire
/// for a booking product, unlike a shop order item.
///
/// **[title] IS NULLABLE, and that is not a rarity.** The CMS lets a
/// product be saved with no name in a locale, and the studio's first
/// real catalogue row has none in Arabic — so `GET
/// /api/workshops/bookings` answers `"title": null` to an
/// `Accept-Language: ar` request and the same row answers a name to an
/// English one. Declared required it threw inside `fromJson` and took
/// the WHOLE bookings list with it: switching the app to Arabic on a
/// screen showing a booking failed to parse, while switching back to
/// English worked. The same trap is documented for the workshop
/// catalogue in `docs/api-contract.md` §20; this is the booking side of
/// it. Draw «قطعة» when it is null.
///
/// Nullability from the live captures: [subtitle] and [image] are null
/// in every sampled line.
///
/// **[image] is a GUESS.** Every capture has `"image": null`, so the
/// shape was never observed. [ApiImage] is the bet because that is the
/// shape behind every other `image` key in this API, and the same
/// products carry `images: []` (a list of them) in the workshop
/// catalogue. If the server turns out to send a bare URL string here,
/// this one type is the only edit needed.
@freezed
abstract class BookingProduct with _$BookingProduct {
  const factory BookingProduct({
    /// The product inside the workshop's `categories[]` tree — NOT a
    /// line id and NOT unique per booking.
    ///
    /// NULL on a line that is one of the customer's OWN pieces brought
    /// back to be painted; [workshopBookingPieceId] names it instead.
    /// The two are mutually exclusive, which is the server's own rule
    /// for the `products[]` a booking is created with.
    int? workshopProductId,

    /// The customer's own piece, when the line is one. Null on a
    /// catalogue line.
    int? workshopBookingPieceId,

    /// Already-localized product name (`"Lavender Jar"`). Display
    /// as-is; do not look it up in the ARB. NULL when the CMS has no
    /// name for it in the requested locale — see the class doc.
    String? title,

    /// Secondary line under [title]. Null in every capture.
    String? subtitle,

    /// Thumbnail. Paint it via `image.display`, never `image.url`.
    /// Null in every capture — see the class doc.
    ApiImage? image,

    /// How many of this product the booking includes.
    required int quantity,

    /// Price of ONE unit, as a decimal string (`"10.00"`). Never a
    /// double.
    required String unitPrice,
  }) = _BookingProduct;

  factory BookingProduct.fromJson(Map<String, dynamic> json) =>
      _$BookingProductFromJson(json);
}
