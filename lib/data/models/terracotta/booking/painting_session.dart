import 'package:freezed_annotation/freezed_annotation.dart';

part 'painting_session.freezed.dart';
part 'painting_session.g.dart';

/// The paint workshop a piece is already booked into.
///
/// Null on a piece that is not going anywhere. While [isUpcoming] is
/// true the studio is HOLDING that piece for the session the customer
/// booked, so the collection countdown stops — the server sends
/// `pickup_deadline: null` and keeps `is_pickup_overdue` false for
/// exactly this reason. Before that, the app would go on telling
/// somebody to come and collect a piece they had already arranged to
/// paint, and eventually that they were late.
///
/// [isUpcoming] goes false once the session has run: the piece is
/// painted, not waiting.
@freezed
abstract class PaintingSession with _$PaintingSession {
  const factory PaintingSession({
    @JsonKey(name: 'booking_id') int? bookingId,

    /// `Y-m-d`, the studio's clock. Printed as received.
    String? date,

    @JsonKey(name: 'workshop_title') String? workshopTitle,

    @JsonKey(name: 'is_upcoming') @Default(false) bool isUpcoming,
  }) = _PaintingSession;

  factory PaintingSession.fromJson(Map<String, dynamic> json) =>
      _$PaintingSessionFromJson(json);
}
