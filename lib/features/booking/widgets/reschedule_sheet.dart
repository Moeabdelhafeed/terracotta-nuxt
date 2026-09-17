import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/localization/strings/booking_strings.dart';
import '../../../core/tokens/extensions.dart';
import '../../../data/models/terracotta/workshop/workshop_slot.dart';
import '../../../shared/module/buttons/global_filled_button.dart';
import '../../../shared/module/list/global_list.dart';
import '../../_shared/skeleton_block.dart';
import '../../_shared/terracotta_cta_style.dart';
import '../cubits/booking_schedule_cubit.dart';
import '../cubits/booking_schedule_state.dart';
import 'schedule_pickers.dart';
import 'sheet_shell.dart';

/// «تغيير موعد» — move the booking.
///
/// `PUT /api/workshops/bookings/{booking}` — written as PUT; the
/// method-override interceptor turns it into the POST production
/// accepts.
///
/// **The SAME pickers the booking page uses**, not a second pair that
/// looks nearly like them. There used to be two sets — `DateStrip` /
/// `SlotList` here and `DateStripPicker` / `SessionList` on the
/// schedule page — and they had drifted: this sheet greyed a blocked
/// day where the page does not draw one at all, and it counted seats
/// without checking them against the party size. One set now.
///
/// The same conflict rule applies as on first booking: a slot the
/// customer already overlaps comes back with `has_conflict` and is
/// greyed. Rescheduling into one anyway is a 422.
class RescheduleSheet extends StatefulWidget {
  const RescheduleSheet({
    required this.days,
    required this.slots,
    this.people = 2,
    this.selectedDate,
    this.selectedSlotId,
    this.tint,
    this.onConfirm,
    this.onPickDate,
    this.loadingDays = false,
    this.loadingSlots = false,
    super.key,
  });

  /// The days the studio is open, from
  /// `GET /api/workshops/{workshop}/availability` by way of
  /// [_RescheduleHost].
  ///
  /// **REQUIRED, where it used to default to [RescheduleSample].** The
  /// default made an unbound sheet look like a working one: a caller
  /// that passed nothing got four days in June 2026 and a list of
  /// sessions, all of them real-shaped and none of them real. The
  /// binding landed and the defaults stayed behind it.
  final List<ScheduleDay> days;
  final List<WorkshopSlot> slots;

  /// The party already booked. A session with fewer seats left than
  /// this cannot take them and is greyed rather than tapped and
  /// refused.
  final int people;

  /// Where the booking stands TODAY — the sheet opens on it.
  ///
  /// This is a change, not a fresh booking: opening on an empty strip
  /// makes the customer find their own slot again before they can see
  /// what they are moving away from, and leaves «تغيير» dead until
  /// they do.
  final String? selectedDate;
  final int? selectedSlotId;

  /// The WORKSHOP's colour, as the schedule page tints the very same
  /// pickers with.
  final Color? tint;

  /// The chosen SESSION and the DAY it is on.
  ///
  /// `POST .../reschedule` takes both — a slot id is a weekly session
  /// rather than a date, so sending one without the other moves the
  /// booking to whichever day the server assumes.
  final void Function(int slotId, String date)? onConfirm;

  /// A day was chosen, so its SESSIONS have to be fetched — the
  /// calendar answers which days are blocked and nothing about what
  /// runs on them.
  final ValueChanged<String>? onPickDate;

  /// The calendar has not answered yet.
  ///
  /// **[days] is NOT evidence of that.** `scheduleDaysFor` builds the
  /// strip locally from today's date and only asks the server which of
  /// them are BLOCKED — so before the call returns it draws a full
  /// fortnight with nothing greyed, and the customer watched a row of
  /// perfectly good days turn unavailable underneath their finger. A
  /// skeleton says "not yet"; a wrong answer says "yes".
  final bool loadingDays;

  /// The chosen day's sessions are on their way. Same reason: an empty
  /// list reads as "no sessions that day", which is a real and
  /// different answer.
  final bool loadingSlots;

  @override
  State<RescheduleSheet> createState() => _RescheduleSheetState();
}

class _RescheduleSheetState extends State<RescheduleSheet> {
  late String? _date = widget.selectedDate;

  /// The slot the booking is on, or null until one is picked.
  ///
  /// **No fixture fallback.** It used to be
  /// `widget.selectedSlotId ?? RescheduleSample.currentSlotId` — so a
  /// sheet opened without a current slot started with id 62, a number
  /// out of a fixture, and «تغيير» was ENABLED on it. Pressing it
  /// would have sent that id to `PUT /api/workshops/bookings/{id}`:
  /// a booking moved to a session that has nothing to do with this
  /// workshop, or a 422, depending on what 62 happens to be.
  late int? _slot = widget.selectedSlotId;

  @override
  Widget build(BuildContext context) {
    final tint = widget.tint ?? Theme.of(context).colorScheme.primary;

    return SheetShell(
      title: BookingStrings.rescheduleTitle,
      // PINNED to the foot. With the sessions list short, «تغيير» sat
      // in the middle of the panel with empty space beneath it.
      footer: GlobalFilledButton(
        text: BookingStrings.change,
        enabled: _slot != null,
        style: terracottaCtaStyle(
          showArrow: false,
        ).copyWith(backgroundColor: tint),
        onPressed: () {
          final slot = _slot;
          final date = _date;
          // CLOSE FIRST, then hand the choice over.
          //
          // The order was the other way round, and `onConfirm` now
          // opens a confirmation dialog — so the pop below fired one
          // frame later and took the TOPMOST route, which by then was
          // that dialog. It came back false, the move was abandoned,
          // and pressing «تغيير» did nothing at all.
          Navigator.of(context).pop();
          if (slot != null && date != null) {
            widget.onConfirm?.call(slot, date);
          }
        },
      ),
      children: [
        // EDGE TO EDGE. The strip sets its own leading inset and has
        // to scroll a day in from off-screen; padded by the shell too
        // it lost its first and last tile behind the gutter.
        if (widget.loadingDays)
          const SheetBleed(child: _DayStripSkeleton())
        else
          SheetBleed(
            child: DateStripPicker(
              days: widget.days,
              selected: _date,
              tint: tint,
              onSelect: (d) {
                setState(() {
                  _date = d;
                  // A slot id belongs to the day it was picked on.
                  _slot = null;
                });
                widget.onPickDate?.call(d);
              },
            ),
          ),
        SizedBox(height: context.spacing.lg),
        if (widget.loadingDays || widget.loadingSlots)
          const _SessionsSkeleton()
        else
          SessionList(
            slots: widget.slots,
            selectedId: _slot,
            // WHICH ONE IS ALREADY THEIRS. It comes back conflicting —
            // with itself — so without this the row for the booking
            // being MOVED said the reader had a clashing booking.
            currentId: widget.selectedSlotId,
            people: widget.people,
            tint: tint,
            onSelect: (slot) => setState(() => _slot = slot.workshopSlotId),
          ),
      ],
    );
  }
}

/// The day strip's shape, before the calendar has answered.
///
/// Sized from [DateStripPicker]'s own constants rather than guessed,
/// so the strip does not jump when the real days replace it.
class _DayStripSkeleton extends StatelessWidget {
  const _DayStripSkeleton();

  /// Enough to run off the edge at any phone width, which is what
  /// says the strip SCROLLS.
  static const _count = 5;

  @override
  Widget build(BuildContext context) {
    final spacing = context.spacing;

    return SizedBox(
      height: 108,
      // `GlobalList`, like the strip it stands in for — a raw
      // `ListView` here trips the adoption guards, and rightly: the
      // skeleton and the real thing should scroll the same way or the
      // swap between them shows.
      child: GlobalList<int>.static(
        items: List<int>.generate(_count, (i) => i),
        scrollDirection: Axis.horizontal,
        // Inert: there is nothing under the finger yet, and a strip
        // that scrolls to reveal more grey invites a second look at
        // nothing.
        physics: const NeverScrollableScrollPhysics(),
        style: ListStyle(
          padding: EdgeInsets.symmetric(horizontal: spacing.md),
        ),
        separatorBuilder: (_, _) => SizedBox(width: spacing.sm),
        itemBuilder: (_, _, _) => const SizedBox(
          width: DateStripPicker.tileWidth,
          child: SkeletonBlock(),
        ),
      ),
    );
  }
}

/// The sessions list's shape, before the day's sessions have arrived.
///
/// Three rows: fewer reads as "this day is nearly empty", which is a
/// real answer and not one this knows yet.
class _SessionsSkeleton extends StatelessWidget {
  const _SessionsSkeleton();

  @override
  Widget build(BuildContext context) {
    final spacing = context.spacing;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < 3; i++) ...[
          const SkeletonBlock(height: 72),
          SizedBox(height: spacing.sm),
        ],
      ],
    );
  }
}

/// Opens [RescheduleSheet] over the booking.
/// Opens «تغيير الموعد» on the workshop's REAL availability.
///
/// The sheet's shapes were always the wire's — `Y-m-d` days, a
/// `workshop_slot_id` that is not a row id, a blocked day and a full
/// session. What it lacked was a source: [RescheduleSample] stood in,
/// so the picker offered sessions that do not exist and «تغيير» threw
/// the choice away. This hosts a [BookingScheduleCubit] — the very
/// cubit the booking flow uses — so the same two endpoints answer for
/// both screens.
Future<void> showRescheduleSheet(
  BuildContext context, {
  required String workshopId,
  required int people,
  required void Function(int slotId, String date) onConfirm,
  String? selectedDate,
  int? selectedSlotId,
  Color? tint,
}) => showTerracottaSheet<void>(
  context,
  builder: (_) => _RescheduleHost(
    workshopId: workshopId,
    people: people,
    selectedDate: selectedDate,
    selectedSlotId: selectedSlotId,
    tint: tint,
    onConfirm: onConfirm,
  ),
);

/// Owns the availability the sheet picks from.
///
/// A widget rather than a call because the days and the sessions are
/// two requests: the calendar answers which days are blocked, and a
/// day's sessions are only asked for once that day is chosen.
class _RescheduleHost extends StatefulWidget {
  const _RescheduleHost({
    required this.workshopId,
    required this.people,
    required this.onConfirm,
    this.selectedDate,
    this.selectedSlotId,
    this.tint,
  });

  final String workshopId;
  final int people;
  final void Function(int slotId, String date) onConfirm;
  final String? selectedDate;
  final int? selectedSlotId;
  final Color? tint;

  @override
  State<_RescheduleHost> createState() => _RescheduleHostState();
}

class _RescheduleHostState extends State<_RescheduleHost> {
  late final BookingScheduleCubit _schedule = BookingScheduleCubit(
    workshopId: widget.workshopId,
    maxPeoplePerBooking: widget.people,
  );

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  /// The calendar, then the day the booking is on — so the sheet opens
  /// showing what it is moving AWAY from rather than an empty strip.
  Future<void> _load() async {
    await _schedule.load();
    final on = widget.selectedDate;
    if (on != null && mounted) await _schedule.selectDate(on);
  }

  @override
  void dispose() {
    unawaited(_schedule.close());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      BlocBuilder<BookingScheduleCubit, BookingScheduleState>(
        bloc: _schedule,
        builder: (context, state) => RescheduleSheet(
          days: scheduleDaysFor(
            context,
            blocked: state.blockedDates,
            count: BookingScheduleCubit.days,
          ),
          // THE STRIP IS BUILT LOCALLY and only the BLOCKED set comes
          // from the server, so `days` is never empty and cannot be
          // used to tell "not asked yet" from "asked and answered".
          // Before this, the sheet opened on a full fortnight with
          // nothing greyed and then greyed several of them a moment
          // later — the customer watched good days go bad under their
          // finger.
          loadingDays: state.loadingCalendar,
          // And the same for the day's sessions: an empty list reads
          // as "nothing runs that day", which is a real answer.
          //
          // The second half covers the GAP. `_load` awaits the
          // calendar and only then asks for the booking's own day, so
          // for the frame between the two `loadingSlots` is false and
          // `slots` is empty — and the list flashed "no sessions" on
          // its way to showing them. A day that is genuinely empty has
          // `state.date` set, so this does not swallow that answer.
          loadingSlots:
              state.loadingSlots ||
              (state.date == null && widget.selectedDate != null),
          slots: state.slots,
          people: widget.people,
          selectedDate: state.date ?? widget.selectedDate,
          selectedSlotId: widget.selectedSlotId,
          tint: widget.tint,
          onConfirm: widget.onConfirm,
          onPickDate: (d) => unawaited(_schedule.selectDate(d)),
        ),
      );
}

/// Placeholder availability, so «تغيير موعد» can be looked at before
/// `GET /api/workshops/{workshop}/availability` is wired.
///
/// Shaped like the real thing — `Y-m-d` dates, a `workshop_slot_id`
/// that is NOT the row id, a day the server has ruled out, and a
/// session that is full. Those last two are 422s if sent anyway.
class RescheduleSample {
  const RescheduleSample._();

  /// Where the booking stands today, so the sheet opens on it.
  static const currentDate = '2026-06-04';
  static const currentSlotId = 62;

  static const days = <ScheduleDay>[
    ScheduleDay(
      date: '2026-06-02',
      month: 'يونيو',
      day: '٢',
      weekday: 'الاحد',
    ),
    // Every fitting session that day is taken or conflicts, so the
    // server rules the whole day out — and `DateStripPicker` does not
    // DRAW a blocked day rather than greying one.
    ScheduleDay(
      date: '2026-06-03',
      month: 'يونيو',
      day: '٣',
      weekday: 'الاثنين',
      blocked: true,
    ),
    ScheduleDay(
      date: '2026-06-04',
      month: 'يونيو',
      day: '٤',
      weekday: 'الثلاثاء',
    ),
    ScheduleDay(
      date: '2026-06-05',
      month: 'يونيو',
      day: '٥',
      weekday: 'الاربعاء',
    ),
    ScheduleDay(
      date: '2026-06-06',
      month: 'يونيو',
      day: '٦',
      weekday: 'الخميس',
    ),
  ];

  static const slots = <WorkshopSlot>[
    WorkshopSlot(
      workshopSlotId: 61,
      startTime: '15:00',
      endTime: '16:00',
      capacity: 8,
      remaining: 6,
    ),
    WorkshopSlot(
      workshopSlotId: 62,
      startTime: '15:00',
      endTime: '16:00',
      capacity: 8,
      remaining: 6,
    ),
    // ONE seat left, and the party is two — greyed by the same rule
    // the booking page uses, not by a flag set here.
    WorkshopSlot(
      workshopSlotId: 63,
      startTime: '15:00',
      endTime: '16:00',
      capacity: 8,
      remaining: 1,
    ),
  ];
}
