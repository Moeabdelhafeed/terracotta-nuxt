import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/extensions/context_extensions.dart';
import '../../../core/extensions/theme_colors_extension.dart';
import '../../../core/localization/number_formatter.dart';
import '../../../core/localization/strings/booking_strings.dart';
import '../../../core/tokens/extensions.dart';
import '../../../data/models/terracotta/workshop/workshop_slot.dart';
import '../../../shared/module/list/global_list.dart';
import '../../workshops/widgets/gift_backdrop.dart';
import '../cubits/booking_schedule_cubit.dart';
import 'clock_time.dart';

/// The three states every choice on this screen has.
///
/// Drawn once, here, because a date tile and a session row differ in
/// shape and not at all in what selected or unavailable MEAN — and the
/// design gives them the same three treatments.
enum PickState {
  /// Choosable, not chosen.
  open,

  /// Chosen. Wears the WORKSHOP's colour, with the drawn loop behind
  /// it — the app's one piece of texture for "this is the one".
  chosen,

  /// Not on offer: a blocked day, a full session, or one the customer
  /// already has a booking across.
  unavailable,
}

/// The card every choice sits in.
///
/// One widget so the three states cannot drift apart between the party
/// strip, the date strip and the session list.
class PickCard extends StatelessWidget {
  const PickCard({
    required this.state,
    required this.tint,
    required this.child,
    this.onTap,
    this.padding,
    this.backdropHeightFactor = 1,
    this.backdropWidthFactor = 1,
    this.backdropAlignment = AlignmentDirectional.center,
    super.key,
  });

  final PickState state;

  /// The workshop's own colour. Every active thing on this screen is
  /// painted in it — the flow is themed per workshop.
  final Color tint;

  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry? padding;

  /// How much of the card the drawn loop takes, and where it sits.
  ///
  /// A tile wears it whole. A session ROW is wide and short, and a loop
  /// stretched across all of it is a texture rather than a mark — so it
  /// is drawn at the end, around the seat count, which is the part the
  /// eye goes to.
  final double backdropHeightFactor;
  final double backdropWidthFactor;
  final AlignmentGeometry backdropAlignment;

  @override
  Widget build(BuildContext context) {
    final chosen = state == PickState.chosen;
    final unavailable = state == PickState.unavailable;

    final background = switch (state) {
      PickState.chosen => tint,
      PickState.unavailable => context.backgroundColors.container,
      PickState.open => context.backgroundColors.cardBackground,
    };

    return Material(
      color: background,
      borderRadius: BorderRadius.circular(context.radii.md),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        // An unavailable choice is not a control. Null rather than a
        // callback that returns early, so it does not ripple either.
        onTap: unavailable ? null : onTap,
        child: DecoratedBox(
          decoration: BoxDecoration(
            border: chosen
                ? null
                : Border.all(
                    color: unavailable
                        ? Colors.transparent
                        : context.primaryColors.border,
                  ),
            borderRadius: BorderRadius.circular(context.radii.md),
          ),
          child: Stack(
            children: [
              if (chosen)
                Positioned.fill(
                  child: Align(
                    alignment: backdropAlignment,
                    child: FractionallySizedBox(
                      heightFactor: backdropHeightFactor,
                      widthFactor: backdropWidthFactor,
                      // SQUARE, and `contain` inside it.
                      //
                      // The art is a loop; given a wide short box and
                      // told to cover, it crops to the hollow middle and
                      // the rings come out cut. Kept square it stays a
                      // ring wherever it is anchored.
                      child: AspectRatio(
                        aspectRatio: 1,
                        child: GiftBackdrop(
                          tint: context.textColors.onPrimary.withValues(
                            alpha: 0.35,
                          ),
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                  ),
                ),
              Padding(
                padding: padding ?? EdgeInsets.all(context.spacing.sm),
                child: child,
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// The ink a card's contents read in.
  static Color inkFor(BuildContext context, PickState state) => switch (state) {
    PickState.chosen => context.textColors.onPrimary,
    PickState.unavailable => context.textColors.disabled,
    PickState.open => context.textColors.primary,
  };
}

/// «٢ اشخاص» — how many are coming.
///
/// Only the sizes that can ACTUALLY be booked are drawn: the strip runs
/// to the lower of the workshop's own ceiling and what is left on the
/// calendar. A workshop that seats eight with three free shows three
/// tiles, not eight with five that fail at checkout.
class PartySizeStrip extends StatelessWidget {
  const PartySizeStrip({
    required this.sizes,
    required this.selected,
    required this.tint,
    required this.onSelect,
    super.key,
  });

  final List<int> sizes;
  final int selected;
  final Color tint;
  final ValueChanged<int> onSelect;

  static const _tileWidth = 84.0;
  static const _height = 96.0;

  @override
  Widget build(BuildContext context) {
    final spacing = context.spacing;

    return SizedBox(
      height: _height,
      child: GlobalList<int>.static(
        items: sizes,
        scrollDirection: Axis.horizontal,
        // EDGE TO EDGE, insetting its own contents. Padded from outside
        // the last tile is clipped with nowhere to scroll into.
        style: ListStyle(
          padding: EdgeInsets.symmetric(horizontal: spacing.md),
        ),
        separatorBuilder: (_, _) => SizedBox(width: spacing.sm),
        itemBuilder: (context, size, index) {
          final state = size == selected ? PickState.chosen : PickState.open;
          final ink = PickCard.inkFor(context, state);

          return SizedBox(
            width: _tileWidth,
            child: PickCard(
              state: state,
              tint: tint,
              onTap: () => onSelect(size),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                // A Stack hands its non-positioned child LOOSE
                // constraints, so the column shrank to its widest word
                // and the Stack then parked it at the start corner —
                // the contents read as left-aligned in a centred tile.
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    textAlign: TextAlign.center,
                    // Localized digits — plain `ar` formats in Western
                    // ones.
                    AppNumbers.localizeDigits('$size'),
                    style: context.textTheme.titleLarge?.copyWith(
                      color: ink,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(height: spacing.xs),
                  Text(
                    // «شخص» for one, not «اشخاص» — "1 people" is not a
                    // thing anybody says, in either language.
                    BookingStrings.peopleUnit(size),
                    textAlign: TextAlign.center,
                    style: context.textTheme.labelSmall?.copyWith(color: ink),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

/// One day on the strip — «يونيو ٤ الثلاثاء».
@immutable
class ScheduleDay {
  const ScheduleDay({
    required this.date,
    required this.month,
    required this.day,
    required this.weekday,
    this.blocked = false,
  });

  /// `Y-m-d`, the value the API takes.
  final String date;

  final String month;
  final String day;
  final String weekday;

  /// The server will not take this day for the party currently chosen.
  final bool blocked;
}

/// «اختر موعد» — the days that can actually be booked.
///
/// A blocked day is NOT DRAWN. Greying it made the strip mostly dead
/// tiles the customer had to read past — and which days are blocked
/// changes with the party size, so the strip is already re-computed on
/// every choice above it. Same rule as the party strip, which only ever
/// offers sizes that fit.
/// The run of days a picker lays out, with the server's vetoes on it.
///
/// Built HERE rather than on the wire: the calendar endpoint answers
/// which days are BLOCKED, not which exist, so the run is the app's to
/// lay out and the server's to veto.
///
/// Shared, because two screens pick a date for the same booking — the
/// schedule page and the reschedule sheet — and a second copy of this
/// is a second place for the run to drift.
List<ScheduleDay> scheduleDaysFor(
  BuildContext context, {
  required Set<String> blocked,
  required int count,
}) {
  final locale = Localizations.localeOf(context).toString();
  final month = DateFormat.MMMM(locale);
  final weekday = DateFormat.EEEE(locale);
  final today = DateTime.now();

  return [
    for (var i = 0; i < count; i++)
      () {
        final day = DateTime(today.year, today.month, today.day + i);
        final iso = DateFormat('yyyy-MM-dd').format(day);
        return ScheduleDay(
          date: iso,
          month: month.format(day),
          day: AppNumbers.localizeDigits('${day.day}'),
          weekday: weekday.format(day),
          blocked: blocked.contains(iso),
        );
      }(),
  ];
}

class DateStripPicker extends StatelessWidget {
  const DateStripPicker({
    required this.days,
    required this.selected,
    required this.tint,
    required this.onSelect,
    super.key,
  });

  final List<ScheduleDay> days;

  /// `Y-m-d`, or null before a day is chosen.
  final String? selected;

  final Color tint;
  final ValueChanged<String> onSelect;

  /// WIDER than the party-size tile beside it, which holds one digit.
  /// A day holds three things — the weekday, the number and the month
  /// — and at 84 the longest weekday in either language had to shrink
  /// to fit its own tile.
  static const tileWidth = 104.0;
  static const _height = 108.0;

  @override
  Widget build(BuildContext context) {
    final spacing = context.spacing;
    final open = [
      for (final day in days)
        if (!day.blocked) day,
    ];

    return SizedBox(
      height: _height,
      child: GlobalList<ScheduleDay>.static(
        items: open,
        scrollDirection: Axis.horizontal,
        style: ListStyle(
          padding: EdgeInsets.symmetric(horizontal: spacing.md),
        ),
        separatorBuilder: (_, _) => SizedBox(width: spacing.sm),
        itemBuilder: (context, day, index) {
          final state = day.date == selected
              ? PickState.chosen
              : PickState.open;
          final ink = PickCard.inkFor(context, state);

          return SizedBox(
            width: tileWidth,
            child: PickCard(
              state: state,
              tint: tint,
              onTap: () => onSelect(day.date),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    day.month,
                    textAlign: TextAlign.center,
                    style: context.textTheme.labelSmall?.copyWith(color: ink),
                  ),
                  SizedBox(height: spacing.xs),
                  Text(
                    day.day,
                    textAlign: TextAlign.center,
                    style: context.textTheme.titleLarge?.copyWith(
                      color: ink,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(height: spacing.xs),
                  Text(
                    day.weekday,
                    maxLines: 1,
                    textAlign: TextAlign.center,
                    overflow: TextOverflow.ellipsis,
                    style: context.textTheme.labelSmall?.copyWith(color: ink),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

/// The sessions on the chosen day.
///
/// A FULL session and one the customer already has a booking across are
/// drawn the same: both refuse the booking with a 422, so both are
/// greyed rather than tapped and rejected.
class SessionList extends StatelessWidget {
  const SessionList({
    required this.slots,
    required this.selectedId,
    required this.people,
    required this.tint,
    required this.onSelect,
    this.currentId,
    super.key,
  });

  final List<WorkshopSlot> slots;

  /// How many are coming — a session with fewer seats left than this
  /// cannot take them, and is greyed rather than tapped and refused.
  final int people;
  final int? selectedId;

  /// The slot the booking is ALREADY on, when this list is being used
  /// to move one. It comes back with `has_conflict` — the booking it
  /// clashes with is itself — so without knowing which one it is, the
  /// row says the reader has a clashing booking, which is true and
  /// useless on the sheet for moving exactly that booking.
  final int? currentId;

  final Color tint;
  final ValueChanged<WorkshopSlot> onSelect;

  @override
  Widget build(BuildContext context) {
    final spacing = context.spacing;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final slot in slots) ...[
          _SessionRow(
            slot: slot,
            isCurrent: currentId != null && slot.workshopSlotId == currentId,
            state: !BookingScheduleCubit.canTake(slot, people)
                ? PickState.unavailable
                : slot.workshopSlotId == selectedId
                ? PickState.chosen
                : PickState.open,
            tint: tint,
            onTap: () => onSelect(slot),
          ),
          SizedBox(height: spacing.sm),
        ],
      ],
    );
  }
}

class _SessionRow extends StatelessWidget {
  const _SessionRow({
    required this.slot,
    required this.state,
    required this.tint,
    required this.onTap,
    this.isCurrent = false,
  });

  final WorkshopSlot slot;

  /// This is the booking's own slot — see [SessionList.currentId].
  final bool isCurrent;

  final PickState state;
  final Color tint;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ink = PickCard.inkFor(context, state);
    final spacing = context.spacing;
    final locale = Localizations.localeOf(context).toString();

    return PickCard(
      state: state,
      tint: tint,
      onTap: onTap,
      // At the END, over the seat count — the part of a wide, short row
      // the eye goes to. Stretched across the whole row the loop is a
      // texture rather than a mark.
      backdropAlignment: AlignmentDirectional.centerEnd,
      backdropWidthFactor: 0.2,
      padding: EdgeInsets.symmetric(
        horizontal: spacing.md,
        vertical: spacing.lg,
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              // Asia/Riyadh, shown EXACTLY as sent. A workshop happens
              // at the studio, not wherever the customer is standing.
              BookingStrings.slotLabel(
                // «١٦:٠٠» is a wire value, not something to read. The
                // times stay Asia/Riyadh — only their SHAPE changes.
                formatClock(slot.startTime, locale),
                formatClock(slot.endTime, locale),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: context.textTheme.bodyMedium?.copyWith(color: ink),
            ),
          ),
          SizedBox(width: spacing.sm),
          Text(
            // WHY IT CANNOT BE PICKED, when the reason is the reader's
            // own diary.
            //
            // `has_conflict` means they already hold an overlapping
            // booking, and the server refuses this one with a 422. The
            // row was drawn exactly like every other unpickable slot
            // and still showed its seat count — so a session with «٢
            // من ٨» free looked available and was not, and nothing on
            // screen said the clash was with something they had booked
            // themselves.
            isCurrent
                // ITS OWN BOOKING is what it clashes with, and the
                // reader is here to move it.
                ? BookingStrings.slotCurrent
                : slot.isConflicting
                ? BookingStrings.slotConflict
                : BookingStrings.slotSeats(
                    // BOOKED of capacity — «٠ من ٨» is an empty
                    // session and «٨ من ٨» a full one. It read
                    // `remaining` first, which made an empty session
                    // look full.
                    AppNumbers.localizeDigits('${slot.booked ?? 0}'),
                    AppNumbers.localizeDigits('${slot.capacity ?? 0}'),
                  ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: context.textTheme.labelMedium?.copyWith(
              color: ink,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
