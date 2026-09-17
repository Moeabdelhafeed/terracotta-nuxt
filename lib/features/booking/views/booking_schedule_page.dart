import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/colors/workshop_family_colors.dart';
import '../../../core/di/service_locator.dart';
import '../../../core/extensions/context_extensions.dart';
import '../../../core/extensions/theme_colors_extension.dart';
import '../../../core/localization/strings/auth_strings.dart';
import '../../../core/localization/strings/booking_strings.dart';
import '../../../core/localization/strings/checkout_strings.dart';
import '../../../core/localization/strings/common_strings.dart';
import '../../../core/tokens/extensions.dart';
import '../../../data/models/terracotta/workshop/workshop_slot.dart';
import '../../../shared/module/buttons/global_filled_button.dart';
import '../../../shared/module/dialog/global_dialog.dart';
import '../../../shared/module/empty_state/global_empty_state.dart';
import '../../../shared/module/scrollable/global_scrollable.dart';
import '../../_shared/screen_entrance.dart';
import '../../_shared/shared_hero.dart';
import '../../_shared/skeleton_block.dart';
import '../../_shared/terracotta_cta_style.dart';
import '../../_shared/terracotta_page_bar.dart';
import '../../checkout/views/booking_checkout_page.dart';
import '../../workshops/cubits/workshops_cubit.dart';
import '../../workshops/cubits/workshops_state.dart';
import '../cubits/booking_schedule_cubit.dart';
import '../cubits/booking_schedule_state.dart';
import '../widgets/schedule_pickers.dart';

/// «اختر موعد» — party size, then date, then slot.
///
/// Each step narrows the next, which is why they are laid out in that
/// order and why the CTA stays disabled until a slot is chosen.
///
/// `GET /api/workshops/{id}` then
/// `GET /api/workshops/{id}/availability?date=YYYY-MM-DD`.
///
/// A slot carrying `has_conflict` means the customer already holds an
/// overlapping booking — greyed exactly like a full one. Booking into
/// one anyway returns 422 keyed to `workshop_slot_id`, so the message
/// belongs under the slot list.
/// What the workshops tab hands the booking flow when its CTA is
/// pressed.
///
/// The FAMILY travels because the whole flow is themed by it — the
/// design re-tints every screen from here to the confirmation — and
/// deriving it again from the id would mean re-fetching the catalogue
/// the tab already has.
@immutable
class BookingScheduleArgs {
  const BookingScheduleArgs({
    required this.workshopId,
    required this.title,
    this.maxPeople = 1,
    this.people = 1,
    this.family = WorkshopFamily.makeYourPiece,
    this.wireColor,
  });

  final int workshopId;
  final String title;

  /// The workshop's own `max_people_per_booking`. The calendar's
  /// `max_available_seats` can be LOWER, and the strip runs to
  /// whichever is smaller.
  final int maxPeople;

  /// The party size to OPEN on, when the caller already knows it.
  ///
  /// «لوّن قطعتك» does: the people who made the pieces are the people
  /// coming back to paint them, and asking them to re-enter a number
  /// the booking already holds is asking a question twice. The
  /// workshops tab knows nothing about who is coming and leaves this
  /// at one.
  ///
  /// It is a STARTING POINT, not a floor — the calendar's own
  /// `max_available_seats` still narrows it, and the cubit clamps down
  /// to whatever is actually left.
  final int people;

  final WorkshopFamily family;

  /// The admin-set colour for this workshop, when the row carried one.
  final String? wireColor;
}

class BookingSchedulePage extends StatefulWidget {
  const BookingSchedulePage({
    this.args,
    this.family = WorkshopFamily.makeYourPiece,
    this.wireColor,
    this.cubit,
    super.key,
  });

  /// Everything the tab knew. Null after a hot restart, where a route
  /// extra does not survive — the page then falls back to [family] and
  /// [wireColor] rather than throwing.
  final BookingScheduleArgs? args;

  final WorkshopFamily family;
  final String? wireColor;

  /// A cubit to use instead of making one — the seam a widget test
  /// needs, since the page loads on mount. Null in the app.
  final BookingScheduleCubit? cubit;

  /// The family this screen paints in: the one it was handed, else the
  /// default.
  WorkshopFamily get effectiveFamily => args?.family ?? family;
  String? get effectiveWireColor => args?.wireColor ?? wireColor;

  @override
  State<BookingSchedulePage> createState() => _BookingSchedulePageState();
}

class _BookingSchedulePageState extends State<BookingSchedulePage> {
  late final _schedule =
      (widget.cubit ??
            BookingScheduleCubit(
              workshopId: '${widget.args?.workshopId ?? 0}',
              maxPeoplePerBooking: widget.args?.maxPeople ?? 1,
              initialPeople: widget.args?.people ?? 1,
            ))
        ..load();

  /// The app's catalogue. Read for the workshop's NAME, which the
  /// server writes and therefore only re-says when it is asked again.
  late final _catalogue = getIt<WorkshopsCubit>();

  @override
  void dispose() {
    // Only what this page MADE. An injected one belongs to its test.
    if (widget.cubit == null) unawaited(_schedule.close());
    super.dispose();
  }

  /// The next fortnight, as the strip draws them.
  /// The run of days, shared with the reschedule sheet — see
  /// [scheduleDaysFor].
  List<ScheduleDay> _days(BookingScheduleState state) => scheduleDaysFor(
    context,
    blocked: state.blockedDates,
    count: BookingScheduleCubit.days,
  );

  /// The workshop's name, in the language on screen.
  ///
  /// From the catalogue when it has this row, else the one the tab
  /// handed over — which is right until the reader switches language.
  String get _title {
    final id = widget.args?.workshopId;
    final state = _catalogue.state;
    if (id != null && state is WorkshopsLoaded) {
      for (final workshop in state.workshops) {
        if (workshop.id == id) return workshop.title;
      }
    }
    return widget.args?.title ?? '';
  }

  /// The session the customer picked, if they have.
  WorkshopSlot? _selectedSlot(BookingScheduleState state) => state.slots
      .where((s) => s.workshopSlotId == state.selectedSlotId)
      .firstOrNull;

  /// Whether this workshop is priced from a catalogue, and so has one
  /// more step before payment.
  ///
  /// The workshop's own per-person product BOUNDS are the answer when
  /// the catalogue has this row: a fourth CMS type nobody has taught
  /// the app about still gets the right flow off them. The family is
  /// the fallback for the case the row is not loaded — after a hot
  /// restart, where the extra survives and the tab's fetch has not
  /// landed yet.
  bool get _catalogueStep {
    final id = widget.args?.workshopId;
    final state = _catalogue.state;
    if (id != null && state is WorkshopsLoaded) {
      for (final workshop in state.workshops) {
        if (workshop.id == id) return workshop.requiresProductSelection;
      }
    }
    return widget.effectiveFamily.needsCatalogue;
  }

  /// Everything this screen knows, packed for whatever comes next.
  ///
  /// The FACTS, not the sentence: composed here they would have
  /// arrived in THIS screen's language and stayed that way when the
  /// reader switched on the next one.
  BookingCheckoutArgs _args(BookingScheduleState state) => BookingCheckoutArgs(
    workshopId: widget.args?.workshopId ?? 0,
    title: _title,
    people: state.people,
    workshopSlotId: state.selectedSlotId,
    date: state.date,
    startTime: _selectedSlot(state)?.startTime,
    endTime: _selectedSlot(state)?.endTime,
    family: widget.effectiveFamily,
    wireColor: widget.effectiveWireColor,
    // The SESSION's own cancellation terms, carried to the screen that
    // takes the money — the window is measured back from this slot's
    // start, not from the workshop.
    // The studio's own wall clock, as strings — see
    // [ProductBrowseArgs]'s note on why this is not a `DateTime`.
    cancelUntilDate: _selectedSlot(state)?.cancelUntilDate,
    cancelUntilClock: _selectedSlot(state)?.cancelUntilClock,
    cancellable: _selectedSlot(state)?.isCancellable ?? true,
  );

  /// The catalogue families choose pieces first; the same bag travels
  /// on from there, so the checkout asks for none of it again either
  /// way.
  Future<void> _continue(BookingScheduleState state) async {
    // TOLD BEFORE THE MONEY MOVES.
    //
    // A workshop's cancellation window is measured back from the
    // SESSION's start, so the same workshop is cancellable on next
    // week's slot and not on tomorrow's — `is_non_cancellable` on the
    // availability row is the server saying which. Finding that out
    // after paying, on a detail page with no «الغاء» button, is the
    // version of this the customer would rightly complain about.
    final slot = _selectedSlot(state);
    if (slot != null && !slot.isCancellable) {
      final sure = await GlobalDialog.confirm(
        context: context,
        title: BookingStrings.noCancelTitle,
        message: BookingStrings.noCancelBody,
        confirmText: BookingStrings.noCancelConfirm,
      );
      if (!sure || !mounted) return;
    }

    final args = _args(state);
    if (_catalogueStep) {
      context.pushNamed(
        'piece-selection',
        pathParameters: {'workshopId': '${args.workshopId}'},
        extra: args,
      );
      return;
    }
    context.pushNamed('booking-checkout', extra: args);
  }

  @override
  Widget build(BuildContext context) {
    final spacing = context.spacing;
    final fam = WorkshopFamilyColors.resolve(
      family: widget.effectiveFamily,
      isDark: context.isDarkMode,
      wireColor: widget.effectiveWireColor,
    );

    // The catalogue is watched for the TITLE — server written, so it
    // re-says itself when the catalogue is re-asked, which is what a
    // language change does — and for the workshop's product bounds,
    // which decide what the CTA at the foot leads to.
    return BlocBuilder<WorkshopsCubit, WorkshopsState>(
      bloc: _catalogue,
      builder: (context, _) => Scaffold(
        backgroundColor: context.backgroundColors.scaffoldBackground,
        appBar: TerracottaPageBar(title: _title),
        body: BlocBuilder<BookingScheduleCubit, BookingScheduleState>(
          bloc: _schedule,
          builder: (context, state) => GlobalScrollable(
            // The CALLER has to ask, or a page shorter than the viewport
            // drops the drag recogniser.
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              // STAGGERED as the page settles — the rows arrive one after
              // another rather than the whole block appearing at once.
              children: ScreenEntrance.stage([
                // No heading over the party strip: the tiles say
                // «اشخاص» on every one of them, and a title repeating the
                // word above them was the page telling you twice.
                SizedBox(height: spacing.md),
                // The strips run EDGE TO EDGE and pad their own contents,
                // so the page gutters each block instead of the whole
                // column — a padded rail clips its last tile.
                if (state.loadingCalendar)
                  const _StripSkeleton()
                else if (state.maxPeople < 1)
                  _Gutter(
                    child: GlobalEmptyState(
                      icon: Icons.event_busy_rounded,
                      title: BookingStrings.fullUp,
                      variant: EmptyStateVariant.compact,
                    ),
                  )
                else
                  PartySizeStrip(
                    sizes: state.partySizes,
                    selected: state.people,
                    tint: fam.primary,
                    onSelect: (n) => unawaited(_schedule.selectPeople(n)),
                  ),

                SizedBox(height: spacing.lg),
                _Heading(text: BookingStrings.pickSlot),
                SizedBox(height: spacing.sm),
                if (state.loadingCalendar)
                  const _StripSkeleton()
                else
                  DateStripPicker(
                    days: _days(state),
                    selected: state.date,
                    tint: fam.primary,
                    onSelect: (d) => unawaited(_schedule.selectDate(d)),
                  ),

                SizedBox(height: spacing.lg),
                _Gutter(
                  child: _Sessions(
                    state: state,
                    tint: fam.primary,
                    onSelect: _schedule.selectSlot,
                  ),
                ),

                SizedBox(height: spacing.xxl),
              ]),
            ),
          ),
        ),
        // PINNED. The list of sessions is as long as the day is, and a
        // button at the foot of it is one the customer has to go
        // looking for.
        bottomNavigationBar:
            BlocBuilder<BookingScheduleCubit, BookingScheduleState>(
              bloc: _schedule,
              builder: (context, state) => Material(
                color: context.backgroundColors.scaffoldBackground,
                child: SafeArea(
                  top: false,
                  child: Padding(
                    padding: EdgeInsetsDirectional.fromSTEB(
                      spacing.md,
                      spacing.sm,
                      spacing.md,
                      spacing.sm,
                    ),
                    child: SharedHero(
                      tag: HeroTag.bookingCta,
                      exitsWithRoute: true,
                      child: GlobalFilledButton(
                        // A catalogue family is not done choosing yet —
                        // «التالي» leads to the pieces, and the price is
                        // only knowable after them. Everyone else pays now.
                        text: _catalogueStep
                            ? CommonStrings.next
                            : CheckoutStrings.title,
                        enabled: state.canContinue,
                        onPressed: () => unawaited(_continue(state)),
                        // The auth CTA's shape — the same bar the sign-in
                        // button uses, in the WORKSHOP's colour.
                        style: terracottaCtaStyle().copyWith(
                          backgroundColor: fam.primary,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
      ),
    );
  }
}

/// The page's side gutter, applied per block — the strips run to both
/// screen edges and inset their own contents.
class _Gutter extends StatelessWidget {
  const _Gutter({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.symmetric(horizontal: context.spacing.md),
    child: child,
  );
}

class _Heading extends StatelessWidget {
  const _Heading({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) => _Gutter(
    child: Text(
      text,
      style: context.textTheme.titleLarge?.copyWith(
        color: context.textColors.primary,
        fontWeight: FontWeight.w600,
      ),
    ),
  );
}

/// The sessions on the chosen day, or the reason there are none.
class _Sessions extends StatelessWidget {
  const _Sessions({
    required this.state,
    required this.tint,
    required this.onSelect,
  });

  final BookingScheduleState state;
  final Color tint;
  final ValueChanged<WorkshopSlot> onSelect;

  @override
  Widget build(BuildContext context) {
    if (state.date == null) return const SizedBox.shrink();
    if (state.loadingSlots) return const _SessionSkeleton();

    if (state.slots.isEmpty) {
      return GlobalEmptyState(
        icon: state.error != null
            ? Icons.wifi_off_rounded
            : Icons.schedule_rounded,
        title: state.error != null
            ? AuthStrings.errorGeneric
            : BookingStrings.noSlots,
        variant: EmptyStateVariant.compact,
      );
    }

    return SessionList(
      slots: state.slots,
      selectedId: state.selectedSlotId,
      people: state.people,
      tint: tint,
      onSelect: onSelect,
    );
  }
}

class _StripSkeleton extends StatelessWidget {
  const _StripSkeleton();

  @override
  Widget build(BuildContext context) {
    // Four fixed cards that do not scroll and never will — a viewport
    // and a scroll machine for that is a `ListView` pretending, and the
    // adoption guards are right to call it out. Laid out unbounded and
    // CLIPPED, which is the only part of the list this ever used.
    return SizedBox(
      height: 96,
      child: ClipRect(
        child: OverflowBox(
          alignment: AlignmentDirectional.centerStart,
          maxWidth: double.infinity,
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: context.spacing.md),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (var i = 0; i < 4; i++) ...[
                  if (i > 0) SizedBox(width: context.spacing.sm),
                  // The DATE strip's own width — a placeholder that
                  // does not match the thing it stands in for makes
                  // the row jump when the answer lands.
                  const SizedBox(
                    width: DateStripPicker.tileWidth,
                    child: SkeletonBlock(),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SessionSkeleton extends StatelessWidget {
  const _SessionSkeleton();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < 3; i++) ...[
          const SizedBox(
            height: 64,
            child: SkeletonBlock(),
          ),
          SizedBox(height: context.spacing.sm),
        ],
      ],
    );
  }
}
