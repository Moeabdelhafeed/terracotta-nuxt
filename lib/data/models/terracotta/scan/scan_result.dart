import 'package:freezed_annotation/freezed_annotation.dart';

part 'scan_result.freezed.dart';
part 'scan_result.g.dart';

/// What the desk gets back from scanning a code.
///
/// ## The two-phase check-in
///
/// A booking for one person checks in on the first scan. A booking for
/// SEVERAL comes back `needs_count: true` and writes nothing — the desk
/// has to say how many of the party actually turned up, and scan again
/// with that number. Answering it wrong is not correctable by scanning
/// again, which is why the server refuses to guess.
///
/// **Every one of these is a 200.** `already_checked_in`, `needs_count`
/// and `checked_in` are all successes with different meanings; only a
/// bad code (404) or a booking that cannot be checked in (422) fails.
@freezed
abstract class ScanResult with _$ScanResult {
  const factory ScanResult({
    required int id,
    @JsonKey(name: 'user_name') String? userName,
    @JsonKey(name: 'workshop_id') int? workshopId,
    @JsonKey(name: 'workshop_slot_id') int? workshopSlotId,
    @JsonKey(name: 'workshop_title') String? workshopTitle,
    @JsonKey(name: 'people_count') @Default(1) int peopleCount,
    @JsonKey(name: 'checked_in_count') int? checkedInCount,

    /// They were already in. Scanning twice is not an error — a desk
    /// scans the same code twice all the time.
    @JsonKey(name: 'already_checked_in') @Default(false) bool alreadyCheckedIn,

    /// The server wrote NOTHING and wants a headcount. See the class
    /// note.
    @JsonKey(name: 'needs_count') @Default(false) bool needsCount,
  }) = _ScanResult;

  factory ScanResult.fromJson(Map<String, dynamic> json) =>
      _$ScanResultFromJson(json);
}
