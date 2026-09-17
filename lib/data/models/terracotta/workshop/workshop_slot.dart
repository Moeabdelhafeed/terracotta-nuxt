// Package imports:
import 'package:freezed_annotation/freezed_annotation.dart';

part 'workshop_slot.freezed.dart';
part 'workshop_slot.g.dart';

/// One bookable session on a chosen day — an element of the
/// availability SLOTS response for a workshop
/// (`GET /api/workshops/{id}/availability`, queried with a date).
///
/// **THE CAPTURE FOR THIS ENDPOINT IS AN EMPTY LIST.** The live sample
/// is `{"data": []}` — the studio had no open slots on the queried day —
/// so no slot object was ever observed. The four fields below come from
/// the endpoint contract and are corroborated by the booking payloads
/// (`GET /api/workshops/bookings`), which echo `workshop_slot_id`,
/// `start_time` and `end_time` with these exact names and formats. Any
/// OTHER key this endpoint sends (a per-slot seat count, a date, a
/// sold-out flag) is currently unmodelled and will be silently dropped —
/// re-derive this model against the first non-empty capture before
/// trusting it for a seat-count UI.
///
/// **IT IS KEYED `workshop_slot_id`, NOT `id`.** Every other model in
/// this API uses a bare `id`; this one does not. A `Slot.id` field would
/// parse to null and every booking would post a null slot. The value is
/// what `POST /api/workshops/{id}/price` and the booking create call
/// take as `workshop_slot_id`.
///
/// **[startTime] / [endTime] ARE CLOCK STRINGS IN ASIA/RIYADH, NOT
/// TIMESTAMPS.** They arrive as `"13:00"` / `"14:30"` — no date, no
/// offset, no zone. `DateTime.parse("13:00")` THROWS, and constructing a
/// local `DateTime` from them silently reinterprets studio time as the
/// device's zone, which shows the wrong session to anyone travelling.
/// Keep them strings, display them as-is, and if you must compute
/// (a countdown, a sort) combine them with the booking date in
/// Asia/Riyadh explicitly.
///
/// **[hasConflict] IS ABOUT THE CUSTOMER, NOT THE STUDIO.** True means
/// THIS signed-in customer already has a booking that overlaps this
/// slot — the slot itself is open and other people can take it. Show it
/// as "you are already booked at this time", not "unavailable", and do
/// not hide the row: hiding it makes the customer think the studio is
/// closed. It is nullable here (never observed); read it through
/// [isConflicting], which defaults a missing flag to false.
@freezed
abstract class WorkshopSlot with _$WorkshopSlot {
  const factory WorkshopSlot({
    /// The slot identity — sent as `workshop_slot_id`, NOT `id`. This
    /// is the value the price and booking-create calls take.
    required int workshopSlotId,

    /// Session start as an Asia/Riyadh CLOCK string (`"13:00"`).
    /// Never a `DateTime` — see the class doc.
    String? startTime,

    /// Session end as an Asia/Riyadh CLOCK string (`"14:30"`).
    /// Never a `DateTime` — see the class doc.
    String? endTime,

    /// Total seats in the session.
    int? capacity,

    /// Seats already taken.
    int? booked,

    /// Seats left — this is the number the picker shows the customer
    /// ("٤ / ٦ مقاعد"). Do NOT recompute it from capacity - booked; a
    /// held-but-unpaid booking occupies a seat and the server accounts
    /// for that here.
    int? remaining,

    /// The session is at capacity. Grey it out.
    bool? isFull,

    /// True when the signed-in customer already has an overlapping
    /// booking. Read it through [isConflicting].
    bool? hasConflict,

    /// **Whether booking THIS session can ever be cancelled.**
    ///
    /// Per slot, not per workshop: a workshop's
    /// `cancellation_window_hours` is measured back from the session's
    /// own start, so the same workshop is cancellable on next week's
    /// session and not on tomorrow's. Probed live on 2026-09-09 — the
    /// availability rows carry it alongside [cancelUntil].
    ///
    /// The booking screens read it BEFORE the money moves, because
    /// afterwards is too late to be told. `can_cancel` on the created
    /// booking is the same rule looked at from the other side.
    bool? isNonCancellable,

    /// The deadline, **as the server wrote it** — an ISO string with
    /// the studio's offset, `2026-09-10T13:00:00+03:00`.
    ///
    /// KEPT AS A STRING on purpose, like every other time on this API.
    /// `DateTime.parse` converts an offset-bearing string to UTC, so
    /// parsing this to display it turned 13:00 in Riyadh into 10:00
    /// and the app told a customer their deadline was three hours
    /// earlier than it is. The studio's wall clock is the one that
    /// counts; read it with [cancelUntilLabel], and compare instants
    /// with [cancelUntilAt].
    @JsonKey(name: 'cancel_until') String? cancelUntil,
  }) = _WorkshopSlot;

  const WorkshopSlot._();

  factory WorkshopSlot.fromJson(Map<String, dynamic> json) =>
      _$WorkshopSlotFromJson(json);

  /// [hasConflict] with a missing flag treated as "no conflict".
  ///
  /// The absence of the key must not read as a conflict — that would
  /// grey out every slot on a payload shape we have not observed.
  bool get isConflicting => hasConflict ?? false;

  /// Whether a booking on this session could be called off later.
  ///
  /// Absent means yes: an older server that does not send the key has
  /// not said no, and warning about a restriction nobody imposed is
  /// worse than staying quiet.
  ///
  /// A deadline already in the PAST counts as no — the server works
  /// this out too, but a screen sitting open across the boundary
  /// would otherwise go on offering a right that has lapsed.
  bool get isCancellable {
    if (isNonCancellable ?? false) return false;
    final at = cancelUntilAt;
    return at == null || at.isAfter(DateTime.now());
  }

  /// The deadline as a real INSTANT, for comparisons.
  ///
  /// This is where converting to UTC is right: two instants compared
  /// are the same answer wherever the reader is standing.
  DateTime? get cancelUntilAt {
    final raw = cancelUntil;
    if (raw == null || raw.isEmpty) return null;
    return DateTime.tryParse(raw);
  }

  /// The date part of the deadline on the STUDIO's clock, `Y-m-d`.
  String? get cancelUntilDate => cancelUntil?.split('T').firstOrNull;

  /// And the time part, `HH:mm` — the wall clock the studio runs on,
  /// which is what the customer is told.
  String? get cancelUntilClock {
    final raw = cancelUntil;
    if (raw == null || !raw.contains('T')) return null;
    final time = raw.split('T').last;
    return time.length < 5 ? null : time.substring(0, 5);
  }

  /// The session is at capacity.
  bool get isAtCapacity => isFull ?? false;

  /// Seats left, defaulting to none rather than to "plenty" — an
  /// unknown count must not read as bookable.
  int get seatsLeft => remaining ?? 0;

  /// Whether the picker may offer this slot at all.
  ///
  /// A full slot and a conflicting slot look identical to the customer
  /// (both greyed out) but mean different things: full is "someone else
  /// took it", conflicting is "you are already booked then". The design
  /// greys both; the reason belongs in the tooltip.
  bool get isSelectable => !isAtCapacity && !isConflicting && seatsLeft > 0;

  /// `"13:00 - 14:30"`, or just the start when the end is missing, or
  /// null when neither was sent. Display-only; do not parse it back.
  String? get timeRange {
    final start = startTime;
    final end = endTime;
    if (start == null) return null;
    return end == null ? start : '$start - $end';
  }
}
