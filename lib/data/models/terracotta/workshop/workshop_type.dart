// Package imports:
import 'package:freezed_annotation/freezed_annotation.dart';

/// What KIND of workshop this is — the `type` discriminator on every
/// workshop payload (`GET /api/workshops`, `GET /api/workshops/{id}`).
///
/// The three live values drive genuinely different booking flows, which
/// is why this is an enum and not a free string:
///
/// - [makeYourPiece] — throw and glaze on the wheel. No product catalog:
///   `min_products_per_person` / `max_products_per_person` come back
///   null, so the booking flow skips product selection entirely.
/// - [paintYourPiece] — pick a bisque piece from the catalog and paint
///   it. Product selection is REQUIRED and bounded by the per-person
///   min/max.
/// - [makeYourCandle] — pick a jar and a scent from the catalog. Same
///   product-selection step as [paintYourPiece], different catalog.
///
/// **[unknown] is not a server value — it is the crash guard.** The CMS
/// can add a fourth workshop type at any time and a shipped binary must
/// not throw at parse. [fromWire] maps anything it does not recognise
/// to [unknown]; render those with the generic layout rather than
/// assuming a catalog step.
enum WorkshopType {
  /// `"make_your_piece"` — wheel-thrown, no product catalog.
  makeYourPiece('make_your_piece'),

  /// `"paint_your_piece"` — pick a bisque piece, then paint it.
  paintYourPiece('paint_your_piece'),

  /// `"make_your_candle"` — pick a jar and scent, pour a candle.
  makeYourCandle('make_your_candle'),

  /// Not a server value. Anything the CMS adds that this build does not
  /// know about lands here instead of throwing.
  unknown('unknown');

  const WorkshopType(this.wire);

  /// The exact string the API sends and expects back.
  final String wire;

  /// Parse a wire string, falling back to [unknown] rather than
  /// throwing. Never `throw`s — a new CMS value must not kill the app.
  static WorkshopType fromWire(String? wire) => values.firstWhere(
    (type) => type.wire == wire,
    orElse: () => WorkshopType.unknown,
  );

  /// True when this type expects the user to pick products from the
  /// workshop catalog before the booking can be priced.
  bool get hasProductCatalog =>
      this == WorkshopType.paintYourPiece ||
      this == WorkshopType.makeYourCandle;
}

/// Routes `type` through [WorkshopType.fromWire] so an unrecognised
/// value degrades to [WorkshopType.unknown] instead of throwing.
///
/// Plain `@JsonValue` enum mapping would throw on a value the CMS adds
/// after this build ships; this converter cannot.
class WorkshopTypeConverter implements JsonConverter<WorkshopType, String?> {
  const WorkshopTypeConverter();

  @override
  WorkshopType fromJson(String? json) => WorkshopType.fromWire(json);

  @override
  String? toJson(WorkshopType object) => object.wire;
}
