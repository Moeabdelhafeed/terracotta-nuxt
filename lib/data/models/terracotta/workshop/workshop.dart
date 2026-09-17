// Package imports:
import 'package:freezed_annotation/freezed_annotation.dart';

// Project imports:
import '../core/api_image.dart';
import 'workshop_audience.dart';
import 'workshop_type.dart';

part 'workshop.freezed.dart';
part 'workshop.g.dart';

/// One bookable workshop as it appears in the list — `GET /api/workshops`.
///
/// This is the card shape: enough to render the grid and to gate the
/// booking form before the detail call. [WorkshopDetail] is the same
/// payload from `GET /api/workshops/{id}` plus `long_description`,
/// `gallery` and `categories`.
///
/// **[color] IS PER-WORKSHOP, NOT PER-TYPE.** An admin sets a hex string
/// (`"#f59e0b"`) on each individual workshop row in the CMS. Two
/// workshops of the same [type] carry different colours — the live
/// capture has two `make_your_piece` rows at `#f97316` and `#0ea5e9`.
/// Do NOT derive the card colour from [type] or from a local palette
/// keyed by type; read this field. It is a `#RRGGBB` string, so parse it
/// yourself (`int.parse(color.substring(1), radix: 16) | 0xFF000000`).
///
/// **EVERY MONETARY FIELD IS A DECIMAL STRING** — [price] and
/// [celebrationPrice] arrive as `"25.00"`, never a double. Binary floats
/// round totals wrong; keep them strings and price through
/// `POST /api/workshops/{id}/price` (see `PriceQuote`).
///
/// **[price] of `"0.00"` does not mean free.** The two catalog-driven
/// workshops in the live capture (`paint_your_piece`, `make_your_candle`)
/// have a `"0.00"` seat price because the cost is in the products the
/// customer picks — the booking sample for one of them still totals
/// `"22.00"`. Never show "Free" off this field alone; quote first.
///
/// Nullability follows the live captures:
/// - [image] is null on every workshop in every sample, so it is
///   nullable. Paint it via `image?.display`, never `image!.url`.
/// - [minProductsPerPerson] / [maxProductsPerPerson] are null on both
///   `make_your_piece` rows (that type has no catalog) and non-null on
///   the two catalog types. Treat null as "no product step".
/// - Everything else is present and non-null on all four captured rows.
@freezed
abstract class Workshop with _$Workshop {
  const factory Workshop({
    required int id,

    /// Which booking flow this workshop runs. Unknown CMS values parse
    /// to [WorkshopType.unknown] rather than throwing.
    @WorkshopTypeConverter() required WorkshopType type,

    /// Already-localized title for the requested locale. Display as-is.
    required String title,

    /// Plain-text teaser for the card. The HTML body lives on
    /// [WorkshopDetail.longDescription].
    required String shortDescription,

    /// Admin-set `#RRGGBB` for this specific workshop. See the class doc
    /// — this is not a per-type colour.
    required String color,

    /// Seat price, decimal string (`"25.00"`). `"0.00"` on the
    /// catalog-driven types; see the class doc.
    required String price,

    /// Hard seat ceiling for one session across all bookings.
    required int capacityPerSession,

    /// Ceiling on `people_count` for a SINGLE booking. Always <=
    /// [capacityPerSession]. Cap the seat stepper with this one.
    required int maxPeoplePerBooking,

    /// Session length in minutes — pair with a slot's `start_time` to
    /// show the end of the session.
    required int durationMinutes,

    /// Maps deep link for the studio. Open externally, not in a webview.
    ///
    /// NULLABLE — verified live on 2026-08-30. The CMS leaves it empty
    /// on a workshop that is not open for booking (`Make Your Own
    /// Vase`, id 3, on both the list and the detail), and declared
    /// required it threw a cast error inside `fromJson` that took the
    /// WHOLE list down: five workshops arrived and the page showed the
    /// failure state. Show the map link only when there is one.
    String? locationUrl,

    /// Cost of the celebration add-on, decimal string. Quoted even when
    /// the customer has not asked for it — check the booking's
    /// `has_celebration` before charging or displaying it. `"0.00"` here
    /// means the add-on is free, not that it is unavailable.
    required String celebrationPrice,

    /// Cancellation cut-off, in hours before the session. The live
    /// capture ranges 1..24 across workshops, so never hard-code 24.
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

    /// Whether a finished piece from this workshop can be shipped
    /// instead of collected. False means pickup only — hide the whole
    /// delivery step.
    required bool hasDelivery,

    /// Cover image. Null on every workshop in the live capture; render a
    /// placeholder rather than assuming it exists.
    ApiImage? image,

    /// Minimum products the customer must pick per person. Null on
    /// types with no catalog ([WorkshopType.makeYourPiece]).
    int? minProductsPerPerson,

    /// Maximum products the customer may pick per person. Null on types
    /// with no catalog.
    int? maxProductsPerPerson,

    /// The full description, as HTML.
    ///
    /// NOT on the wire yet — the list endpoint returns everything the
    /// expanded card shows EXCEPT this, so the backend is adding it.
    /// Declared now and read when it appears: with it, opening a card
    /// needs no second request at all; without it, the panel falls back
    /// to `GET /api/workshops/{id}`.
    ///
    /// Nullable rather than defaulted, because "absent" and "empty" are
    /// different answers — absent means ask the detail endpoint.
    String? longDescription,
  }) = _Workshop;

  const Workshop._();

  factory Workshop.fromJson(Map<String, dynamic> json) =>
      _$WorkshopFromJson(json);

  /// True when the booking flow must show a product-selection step —
  /// the workshop declares per-person product bounds.
  ///
  /// Reads the bounds rather than the [type] so a fourth CMS type that
  /// parses to [WorkshopType.unknown] still gets the right flow.
  bool get requiresProductSelection =>
      minProductsPerPerson != null || maxProductsPerPerson != null;
}
