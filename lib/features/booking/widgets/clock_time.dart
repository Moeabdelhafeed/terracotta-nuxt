import 'package:intl/intl.dart';

/// A wire clock string — `"16:00"` — as the studio's own locale reads
/// it: «٤ م», «١١:٣٠ ص».
///
/// **NOT a `DateTime`.** The API sends Asia/Riyadh wall-clock strings,
/// and parsing one into a `DateTime` invites something downstream to
/// shift it into the device's zone. A workshop happens at the studio,
/// not wherever the customer is standing — so this builds a throwaway
/// date purely to reach `intl`'s formatter and never lets it out.
///
/// Minutes are dropped when they are zero: the studio books on the
/// hour and «٤:٠٠ م» is two characters of noise on every session in the
/// list.
String formatClock(String? wire, String locale) {
  if (wire == null || wire.isEmpty) return '';

  final parts = wire.split(':');
  if (parts.length < 2) return wire;

  final hour = int.tryParse(parts[0]);
  final minute = int.tryParse(parts[1]);
  if (hour == null || minute == null) return wire;

  // The date is arbitrary and never leaves this function.
  final at = DateTime(2000, 1, 1, hour, minute);
  final pattern = minute == 0 ? DateFormat.j(locale) : DateFormat.jm(locale);
  return pattern.format(at);
}

/// «الخميس ٣ سبتمبر» — a booking's DAY, in the language on screen.
///
/// [wire] is `Y-m-d` as the server wrote it, and Asia/Riyadh already —
/// the parse below builds a local `DateTime` only to hand `intl` its
/// three fields, and no instant ever leaves this function, so nothing
/// can be shifted by the reader's own zone.
///
/// Returns the raw string when it is not a date. A screen printing
/// `2026-09-14` is worse than one printing «الخميس ٣ سبتمبر» and
/// better than one that throws.
String formatBookingDate(String? wire, String locale) {
  if (wire == null || wire.isEmpty) return '';
  final day = DateTime.tryParse(wire);
  if (day == null) return wire;
  return DateFormat.MMMMEEEEd(locale).format(day);
}

/// A deadline as «١٣ سبتمبر · ٩ م» — the day and the time it falls on.
///
/// Asia/Riyadh as the server wrote it: the cancellation window is
/// measured on the STUDIO's clock, and re-expressing it in the
/// reader's would move the deadline by the offset between them.
///
/// Shared because three screens print the same instant — the schedule
/// page's warning, the checkout's policy note and the confirmation —
/// and a deadline that reads differently on each is a deadline the
/// reader cannot trust.
String formatDeadline(DateTime at, String locale) {
  final iso = studioTime(at).toIso8601String();
  return '${formatBookingDate(iso.split('T').first, locale)}'
      ' · '
      '${formatClock(iso.split('T').last.substring(0, 5), locale)}';
}

/// The studio's wall clock for an instant.
///
/// ## Why this exists at all
///
/// The workshops feature runs on ONE timezone —
/// `WORKSHOP_BUSINESS_TIMEZONE`, `Asia/Riyadh` — and every plain time
/// on the API (`start_time`, `booking_date`) is already in it, which
/// is why they are displayed untouched.
///
/// The TIMESTAMPS are the exception: `editable_until`, `created_at`
/// and `checked_in_at` arrive as instants with an offset, and
/// `DateTime.parse` normalises those to UTC. Printing one raw
/// therefore showed a deadline three hours early — a customer whose
/// window closed at 13:00 was told 10:00.
///
/// So an instant has to be put back on the studio's clock before it
/// can be read as a time of day.
///
/// ## The offset is a constant, and that is a real claim
///
/// Riyadh is UTC+3 all year and has never observed daylight saving.
/// A timezone database would be the general answer; for one country
/// that has never moved its clocks, this is the honest one — and it
/// is named rather than sprinkled, so the day that changes there is
/// one line.
DateTime studioTime(DateTime at) => at.toUtc().add(kStudioOffset);

/// Asia/Riyadh's offset from UTC. See [studioTime].
const Duration kStudioOffset = Duration(hours: 3);
