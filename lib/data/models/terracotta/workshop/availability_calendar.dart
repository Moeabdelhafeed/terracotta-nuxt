// Package imports:
import 'package:freezed_annotation/freezed_annotation.dart';

part 'availability_calendar.freezed.dart';
part 'availability_calendar.g.dart';

/// What the date picker needs before a day is chosen — the CALENDAR
/// response of `GET /api/workshops/{id}/availability` (the month-range
/// form, as opposed to the per-day slots form that returns
/// `WorkshopSlot`s).
///
/// Two keys, and the whole booking calendar is drawn from them: grey out
/// every date in [blockedDates], and cap the seat stepper at
/// [maxAvailableSeats].
///
/// **[blockedDates] IS A DENY-LIST, NOT AN ALLOW-LIST.** Anything not in
/// it is bookable. Inverting this is the easy mistake and it shows an
/// empty calendar: the live capture blocks 25 of the next ~30 days, so a
/// wrong-way-round read looks plausible right up until the studio opens
/// up and the customer sees nothing.
///
/// **THE ENTRIES ARE BARE DATES, NOT TIMESTAMPS** — `"2026-08-26"`, no
/// time and no zone, kept as `String` on purpose. Parsing them to
/// `DateTime` makes them midnight in the DEVICE's zone, and a customer
/// east or west of Asia/Riyadh then gets the block landing on the wrong
/// square. Compare them as strings (format the picker's date to
/// `yyyy-MM-dd` and use [isBlocked]) rather than converting.
///
/// **[maxAvailableSeats] IS A RANGE-WIDE CEILING, NOT A PER-DAY COUNT.**
/// It is the largest seat count available across the whole queried
/// range — a specific open day may have fewer. It is safe as the upper
/// bound of a stepper, but never render it as "4 seats left on this
/// day"; the real per-day number comes from the slots call, and the
/// authoritative check is the price/booking call.
///
/// Both keys are present and non-null in the live capture.
@freezed
abstract class AvailabilityCalendar with _$AvailabilityCalendar {
  const factory AvailabilityCalendar({
    /// The largest bookable seat count anywhere in the queried range.
    /// Use as the stepper's max, not as a per-day remaining count.
    required int maxAvailableSeats,

    /// Bare `yyyy-MM-dd` dates that CANNOT be booked. Everything not
    /// listed is open. Defaults to empty so a missing or null key reads
    /// as "nothing blocked" rather than throwing.
    @Default(<String>[]) List<String> blockedDates,
  }) = _AvailabilityCalendar;

  const AvailabilityCalendar._();

  factory AvailabilityCalendar.fromJson(Map<String, dynamic> json) =>
      _$AvailabilityCalendarFromJson(json);

  /// True when [isoDate] (a bare `yyyy-MM-dd` string) is blocked.
  ///
  /// Takes a String, not a `DateTime`, so the caller is forced to decide
  /// which calendar day it means before asking — see the class doc.
  bool isBlocked(String isoDate) => blockedDates.contains(isoDate);
}
