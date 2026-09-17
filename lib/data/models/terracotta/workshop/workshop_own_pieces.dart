import 'package:freezed_annotation/freezed_annotation.dart';

import '../core/api_image.dart';

part 'workshop_own_pieces.freezed.dart';
part 'workshop_own_pieces.g.dart';

/// The customer's OWN pieces, offered back to be painted —
/// `GET /api/workshops/{id}` → `own_pieces`.
///
/// Present only on a `paint_your_piece` workshop that
/// `accepts_own_pieces`; **null on every other workshop**, and its
/// [pieces] list is empty for anyone signed out.
///
/// A piece exists because of `piece_labels` on
/// `POST /api/workshops/bookings/{booking}/images`: photos sharing one
/// label are ONE object. That is the whole reason the studio can offer
/// a specific cup back — three angles of the same mug is one piece, not
/// three.
@freezed
abstract class WorkshopOwnPieces with _$WorkshopOwnPieces {
  const factory WorkshopOwnPieces({
    /// The flat rate for bringing one of your own, as a decimal STRING
    /// (`"60.00"`). It replaces a catalogue product's price on the
    /// line, and the customer pays it per piece.
    required String price,

    /// How many are available. The server counts them, so a paginated
    /// or trimmed [pieces] list still says the truth.
    @Default(0) int count,

    /// The pieces themselves, newest first. Empty for a guest.
    @Default(<WorkshopOwnPiece>[]) List<WorkshopOwnPiece> pieces,
  }) = _WorkshopOwnPieces;

  const WorkshopOwnPieces._();

  factory WorkshopOwnPieces.fromJson(Map<String, dynamic> json) =>
      _$WorkshopOwnPiecesFromJson(json);

  /// Whether there is anything to offer. A workshop that accepts own
  /// pieces from a customer who has none must not draw an empty rail.
  bool get hasAny => pieces.isNotEmpty;
}

/// One thing the customer made, waiting to be painted.
@freezed
abstract class WorkshopOwnPiece with _$WorkshopOwnPiece {
  const factory WorkshopOwnPiece({
    /// `workshop_booking_piece_id` — what a booking line names when it
    /// brings this piece back. Quantity is ignored for it: a specific
    /// object is always one.
    required int id,

    /// What the customer called it when they uploaded the photos —
    /// "Sara's mug". Nullable: the label is what groups the photos, and
    /// an older row may have none.
    String? label,

    /// The booking it was made in, and the day that was. Both are for
    /// telling two similar cups apart.
    int? madeInBookingId,
    String? madeOn,

    /// The photos of it. Empty is possible — a piece whose last photo
    /// was deleted is deleted too, but a trimmed payload can still say
    /// nothing.
    @Default(<ApiImage>[]) List<ApiImage> images,

    /// Whether it can still be booked in.
    ///
    /// False once it has been painted in another booking
    /// (`painted_in_booking_id` is set). The server refuses a claimed
    /// piece with `api.workshop_piece_unavailable`, so a screen that
    /// offers one is a screen that 422s.
    @Default(true) bool isAvailableToPaint,
  }) = _WorkshopOwnPiece;

  const WorkshopOwnPiece._();

  factory WorkshopOwnPiece.fromJson(Map<String, dynamic> json) =>
      _$WorkshopOwnPieceFromJson(json);

  /// First photo, or null. Paint it via `.display`, never `.url`.
  ApiImage? get primaryImage => images.isEmpty ? null : images.first;
}
