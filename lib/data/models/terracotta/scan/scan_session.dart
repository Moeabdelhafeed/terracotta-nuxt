import 'package:freezed_annotation/freezed_annotation.dart';

part 'scan_session.freezed.dart';
part 'scan_session.g.dart';

/// One booking on the desk's list for a session.
@freezed
abstract class ScanBooking with _$ScanBooking {
  const factory ScanBooking({
    required int id,
    @JsonKey(name: 'user_name') String? userName,
    @JsonKey(name: 'people_count') @Default(1) int peopleCount,
    @Default('confirmed') String status,

    /// When the desk checked them in. Null until they arrive.
    @JsonKey(name: 'checked_in_at') DateTime? checkedInAt,

    /// How many of the party actually turned up — null until asked,
    /// and never more than [peopleCount].
    @JsonKey(name: 'checked_in_count') int? checkedInCount,

    @JsonKey(name: 'has_celebration') @Default(false) bool hasCelebration,

    /// How many pieces this booking has PHOTOGRAPHED so far.
    @JsonKey(name: 'pieces_count') @Default(0) int piecesCount,

    /// How many it is expected to end up with — one per person who
    /// actually checked in for `make_your_piece`, and the quantity of
    /// products bought for `paint_your_piece` / `make_your_candle`.
    ///
    /// A GUIDE on the wheel and a CEILING in the other two: one person
    /// can freely make three things, but a key past the number of
    /// objects paid for answers 422.
    @JsonKey(name: 'expected_piece_count') int? expectedPieceCount,
  }) = _ScanBooking;

  const ScanBooking._();

  factory ScanBooking.fromJson(Map<String, dynamic> json) =>
      _$ScanBookingFromJson(json);

  /// Somebody the desk has to go and find before Finish runs.
  ///
  /// Photos can only be uploaded while a booking is `attending`. Once
  /// Finish moves it on, **no piece can ever be added to it again** —
  /// so this is the last moment the studio can do anything about it,
  /// which is why the warning hangs off that button and nowhere else.
  bool get isMissingPieces =>
      status == 'attending' &&
      expectedPieceCount != null &&
      piecesCount < expectedPieceCount!;
}

/// A session the desk is running today, and everyone booked onto it.
///
/// Built from the BOOKINGS, so a session nobody booked does not appear
/// — which is the difference between this and the CMS's day view, and
/// the right answer for a desk: there is nobody to check in.
@freezed
abstract class ScanSession with _$ScanSession {
  const factory ScanSession({
    @JsonKey(name: 'workshop_id') required int workshopId,
    @JsonKey(name: 'workshop_slot_id') required int workshopSlotId,
    @JsonKey(name: 'workshop_title') String? workshopTitle,

    /// Asia/Riyadh, printed as received — the studio's clock is the one
    /// the session runs on.
    @JsonKey(name: 'start_time') String? startTime,
    @JsonKey(name: 'end_time') String? endTime,

    int? capacity,

    /// Heads booked onto it, which is not the same as bookings.
    @JsonKey(name: 'total_people') @Default(0) int totalPeople,

    /// **BOOKINGS checked in, not people.** The scanner API counts rows
    /// here where the CMS counts heads — the two numbers differ the
    /// moment a party of three arrives as two.
    @JsonKey(name: 'checked_in_count') @Default(0) int checkedInCount,

    /// Whether anyone is still holding a seat — `Start` finalises
    /// attendance and marks everyone unscanned as absent.
    @JsonKey(name: 'can_start') @Default(false) bool canStart,

    /// Whether anyone is attending, so the session can be finished.
    @JsonKey(name: 'can_finish') @Default(false) bool canFinish,

    /// **False once the session has been finished.** Every check-in
    /// against it then answers 422 — it makes no difference that the
    /// customer is standing at the desk.
    ///
    /// Defaults TRUE so a server that has not grown the field yet
    /// behaves as it always did, rather than locking a working desk
    /// out of its own scanner.
    @JsonKey(name: 'can_check_in') @Default(true) bool canCheckIn,

    /// When Finish ran. Null while the session is still open.
    @JsonKey(name: 'session_finished_at') DateTime? sessionFinishedAt,

    @Default(<ScanBooking>[]) List<ScanBooking> bookings,
  }) = _ScanSession;

  const ScanSession._();

  factory ScanSession.fromJson(Map<String, dynamic> json) =>
      _$ScanSessionFromJson(json);

  /// Everyone still short of their pieces, in the order they are
  /// listed.
  ///
  /// The desk needs NAMES, not a number: "3 bookings" does not tell
  /// them who to go and look for.
  List<ScanBooking> get missingPieces => [
    for (final booking in bookings)
      if (booking.isMissingPieces) booking,
  ];
}

/// The whole day.
@freezed
abstract class ScanDay with _$ScanDay {
  const factory ScanDay({
    /// `Y-m-d`, the day these sessions belong to.
    String? date,
    @Default(<ScanSession>[]) List<ScanSession> sessions,
  }) = _ScanDay;

  factory ScanDay.fromJson(Map<String, dynamic> json) =>
      _$ScanDayFromJson(json);
}
