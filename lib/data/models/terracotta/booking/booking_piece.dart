import 'package:freezed_annotation/freezed_annotation.dart';

import '../core/api_image.dart';
import 'painting_session.dart';

part 'booking_piece.freezed.dart';
part 'booking_piece.g.dart';

/// One PIECE made in a session, and the photographs of it.
///
/// A piece is not a row the customer creates: it is a KEY. Photos
/// uploaded with the same `piece_keys` entry become one piece, so two
/// shots of «كوبي» are one cup photographed from both sides — and two
/// different cups the customer happened to call the same thing are
/// still two pieces. The label is only what they read.
///
/// It used to group by matching LABEL text, which is why keys exist:
/// two objects with the same name merged into one, and the second
/// could never be brought back to paint. The server still falls back
/// to label-matching when no keys are sent, kept only so older builds
/// keep working.
///
/// A piece made in a `make_your_piece` session can later be brought
/// back to a paint workshop, which is what [isAvailableToPaint]
/// answers: null [paintedInBookingId] means nobody has painted it yet.
@freezed
abstract class BookingPiece with _$BookingPiece {
  const factory BookingPiece({
    required int id,

    /// What the customer called it. Nullable: a piece can exist with
    /// no name on an older booking.
    String? label,

    /// The session it was MADE in — not necessarily this booking, when
    /// the piece is being read off a paint booking.
    @JsonKey(name: 'made_in_booking_id') int? madeInBookingId,

    /// `Y-m-d` of that session, printed as received.
    @JsonKey(name: 'made_on') String? madeOn,

    @Default(<ApiImage>[]) List<ApiImage> images,

    /// Whether it can still be booked into a paint workshop. False
    /// once it has been.
    @JsonKey(name: 'is_available_to_paint')
    @Default(true)
    bool isAvailableToPaint,

    /// Where it is going next, or null when it is going nowhere.
    ///
    /// While this is upcoming the collection countdown is OFF — see
    /// [PaintingSession].
    @JsonKey(name: 'painting_session') PaintingSession? paintingSession,
  }) = _BookingPiece;

  const BookingPiece._();

  factory BookingPiece.fromJson(Map<String, dynamic> json) =>
      _$BookingPieceFromJson(json);

  /// The studio is holding this one for a paint session the customer
  /// has already booked, so nothing should be asking them to collect
  /// it.
  bool get isWaitingToBePainted => paintingSession?.isUpcoming ?? false;
}
