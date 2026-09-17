// Package imports:
import 'package:freezed_annotation/freezed_annotation.dart';

// Project imports:
import '../core/api_image.dart';
import 'workshop_audience.dart';
import 'workshop_category.dart';
import 'workshop_own_pieces.dart';
import 'workshop_product.dart';
import 'workshop_type.dart';

part 'workshop_detail.freezed.dart';
part 'workshop_detail.g.dart';

/// One workshop in full — `GET /api/workshops/{id}`.
///
/// Byte-for-byte the same object as `Workshop` from the list endpoint,
/// with three keys appended: [longDescription], [gallery] and
/// [categories]. It is a separate type rather than a superset because
/// the flat JSON gives no nesting to embed the list shape into, and
/// because the booking flow genuinely needs the detail call — the
/// product catalog does not exist on the list endpoint.
///
/// **[color] IS PER-WORKSHOP, NOT PER-TYPE** — an admin sets the hex on
/// this individual row. See `Workshop` for the full note.
///
/// **EVERY MONETARY FIELD IS A DECIMAL STRING** ([price],
/// [celebrationPrice], and every product price under [categories]).
/// A `"0.00"` [price] does not mean free: on the catalog-driven types
/// the money is in the products. Price through
/// `POST /api/workshops/{id}/price` and render the returned quote.
///
/// **[longDescription] IS HTML**, not plain text — the live capture is
/// `"<p>Choose your jar and scent...</p>"`. Render it through an HTML
/// widget; dropping it into a `Text` shows the tags to the customer.
///
/// Nullability follows the live capture, with one deliberate loosening:
/// [longDescription] is nullable even though the single captured detail
/// has it, because it is free-text a CMS editor can leave blank and a
/// crash on the detail screen is not worth the tighter type.
/// [image] is null in the capture. [gallery] and [categories] are `[]`,
/// so their element shapes are inferred rather than observed — worth
/// re-checking against the first workshop that actually has photos.
@freezed
abstract class WorkshopDetail with _$WorkshopDetail {
  const factory WorkshopDetail({
    required int id,

    /// Which booking flow this workshop runs. Unknown CMS values parse
    /// to [WorkshopType.unknown] rather than throwing.
    @WorkshopTypeConverter() required WorkshopType type,

    /// Already-localized title for the requested locale.
    required String title,

    /// Plain-text teaser. The HTML body is [longDescription].
    required String shortDescription,

    /// Admin-set `#RRGGBB` for this specific workshop.
    required String color,

    /// Seat price, decimal string. `"0.00"` on the catalog types.
    required String price,

    /// Hard seat ceiling for one session across all bookings.
    required int capacityPerSession,

    /// Ceiling on `people_count` for a SINGLE booking.
    required int maxPeoplePerBooking,

    /// Session length in minutes.
    required int durationMinutes,

    /// Maps deep link for the studio. Open externally.
    ///
    /// NULLABLE — verified live on 2026-08-30. The CMS leaves it empty
    /// on a workshop that is not open for booking, and declared
    /// required it threw inside `fromJson` and took the whole payload
    /// with it. Show the map link only when there is one.
    String? locationUrl,

    /// Cost of the celebration add-on, decimal string.
    required String celebrationPrice,

    /// Cancellation cut-off in hours before the session. Ranges 1..24
    /// across the captured workshops — never hard-code it.
    required int cancellationWindowHours,

    /// WHO THE SESSION IS FOR — `mixed`, `women_only`, `men_only`,
    /// `couples`, `kids`, `families`.
    ///
    /// Nothing on the server checks a booking against it: the app never
    /// asks for anybody's gender, so the only thing standing between a
    /// customer and the wrong room is that they were able to READ this
    /// before booking. Show it on the card and on the detail.
    ///
    /// Absent or unrecognised reads as [WorkshopAudience.mixed], which
    /// is the default and what every workshop had before the field
    /// existed.
    @WorkshopAudienceConverter()
    @Default(WorkshopAudience.mixed)
    WorkshopAudience audience,

    /// HOW LONG THE STUDIO HOLDS A FINISHED PIECE, in days.
    ///
    /// Set per workshop, and 7 when the studio does not. A booking's
    /// `pickup_deadline` is computed from this rather than from a fixed
    /// week — so this is the number to promise BEFORE booking ("you
    /// will have N days to collect it") and the deadline is the date to
    /// show after the piece is ready.
    ///
    /// Information only: nothing is cancelled or refunded when it
    /// passes.
    @Default(7) int pieceWarningDays,

    /// Whether a finished piece can be shipped instead of collected.
    required bool hasDelivery,

    /// Cover image. Null in the live capture — render a placeholder.
    ApiImage? image,

    /// Minimum products per person. Null when the type has no catalog.
    int? minProductsPerPerson,

    /// Maximum products per person. Null when the type has no catalog.
    int? maxProductsPerPerson,

    // ---- detail-only keys ----
    /// HTML body copy. Render through an HTML widget, not `Text`.
    String? longDescription,

    /// Photo gallery for the detail hero/carousel. Empty in the live
    /// capture; defaults to empty so a missing key cannot throw.
    @Default(<ApiImage>[]) List<ApiImage> gallery,

    /// The two-level product catalog (category -> sub-category ->
    /// products). Empty for workshops with no catalog; defaults to
    /// empty so a missing key cannot throw.
    @Default(<WorkshopCategory>[]) List<WorkshopCategory> categories,

    /// The customer's own pieces, offered back to be painted.
    ///
    /// NULL on every workshop but a `paint_your_piece` one that
    /// `accepts_own_pieces` — and its `pieces` list is empty for a
    /// guest, who has made nothing. See [WorkshopOwnPieces].
    WorkshopOwnPieces? ownPieces,
  }) = _WorkshopDetail;

  const WorkshopDetail._();

  factory WorkshopDetail.fromJson(Map<String, dynamic> json) =>
      _$WorkshopDetailFromJson(json);

  /// True when the booking flow must show a product-selection step.
  ///
  /// Reads the catalog and the per-person bounds rather than [type], so
  /// a workshop type this build does not know about still gets the
  /// right flow.
  bool get requiresProductSelection =>
      categories.isNotEmpty ||
      minProductsPerPerson != null ||
      maxProductsPerPerson != null;

  /// Every product across the whole catalog tree, flattened — for
  /// resolving a picked `workshop_product_id` back to its title/price
  /// without walking two levels by hand.
  List<WorkshopProduct> get allProducts => [
    for (final category in categories)
      for (final sub in category.subCategories) ...sub.products,
  ];
}
