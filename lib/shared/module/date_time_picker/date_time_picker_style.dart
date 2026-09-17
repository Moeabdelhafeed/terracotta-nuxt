import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../../core/animations/animation_presets.dart';
import 'date_time_picker_models.dart';
import 'picker_calendar_system.dart';

// ---------------------------------------------------------------------------
// Defaults — every hard-coded number the pickers draw with
// ---------------------------------------------------------------------------

/// The compile-time floor under [DateTimePickerStyle].
///
/// Sizes that a token can express are NOT here — they come from
/// `MyGlobalDateTimePickerTheme.build`, which reads `AppTokens` and so
/// tracks the window bucket. What is here is what a token cannot say:
/// the wheel geometry Cupertino needs, the opacities, the counts.
abstract final class DateTimePickerDefaults {
  // ─── Wheels ───────────────────────────────────────────────
  /// One row. Cupertino draws its selection band at exactly this
  /// height, so it is geometry rather than spacing.
  static const wheelItemExtent = 40.0;
  static const wheelMagnification = 1.2;
  static const wheelSqueeze = 1.0;
  static const wheelHeight = 220.0;

  /// The floor a wheel stops being readable under — three rows and
  /// the magnifier.
  static const wheelMinHeight = 150.0;

  /// The time half of a combined overlay, under the calendar.
  static const overlayTimeWheelHeight = 150.0;

  // ─── Header ───────────────────────────────────────────────
  static const headerHeight = 48.0;

  // ─── Calendar ─────────────────────────────────────────────
  static const dayCellSize = 40.0;
  static const dayCellMargin = 4.0;
  static const dayFontSize = 16.0;

  /// Smaller than the day numbers on purpose — the strip is a legend,
  /// not data, and at 16 it competed with the dates under it.
  static const weekdayLabelFontSize = 14.0;
  static const calendarHeaderFontSize = 16.0;
  static const arrowIconSize = 25.0;
  static const todayBorderWidth = 1.5;

  /// The keyboard's ring — heavier than today's border, because it is
  /// transient and has to be found at a glance.
  static const focusRingWidth = 2.5;

  /// How wide the week-number gutter is, as a fraction of a day cell.
  static const weekNumberColumnFactor = 0.7;
  static const disabledDayOpacity = 0.3;
  static const outsideDayOpacity = 0.25;
  static const weekdayLabelOpacity = 0.44;

  /// How far the range bar is tinted against the accent.
  static const rangeFillOpacity = 0.2;

  /// The CEILING on the month / year grid, not its height.
  ///
  /// Both grids size to their contents and scroll past it — a fixed box
  /// left a band of white under twelve months, and hid the tail of a
  /// long year list with no way to reach it.
  static const gridViewHeight = 280.0;
  static const gridColumns = 3;
  static const gridAspectRatio = 2.0;

  /// One year row, used to scroll the year grid to the focused year.
  static const yearRowExtent = 56.0;

  static const markerSize = 5.0;
  static const markerSpacing = 2.0;
  static const maxMarkers = 3;

  /// The tail after a range end. Deliberately a fixed tint rather
  /// than a palette colour — it means "not selected, but spoken
  /// for", which no status role covers.
  static const additionalDayColor = Color(0x42FF8686);

  // ─── Trigger ──────────────────────────────────────────────
  static const triggerBorderWidth = 1.0;
  static const triggerIconSize = 20.0;

  // ─── Overlay ──────────────────────────────────────────────
  static const overlayElevation = 10.0;

  /// No ceiling of its own — the SCREEN caps an anchored panel, and a
  /// number here would cap a calendar that had room to be whole. A
  /// caller that genuinely wants a fixed panel still sets one.
  static const overlayMaxHeight = double.infinity;

  /// The narrowest an anchored panel may be, whatever the trigger is.
  ///
  /// Seven columns at a readable cell is a physical floor rather than a
  /// taste, which is why it lives here and not in the bag: a panel
  /// pinned to a 120-point trigger drew a calendar 17 points per day
  /// wide, and the header overflowed by 28. It went up again when the
  /// neighbouring months began to peek in: they take a seventh of the
  /// width the seven columns used to have.
  static const overlayMinWidth = 328.0;
  static const overlayMinHeight = 100.0;
  static const overlayScreenMargin = 12.0;
  static const overlayShadowColor = Color(0x3D000000);

  /// The scale the panel grows FROM. Small — it is a reveal, not a
  /// pop.
  static const overlayScaleFrom = 0.95;

  // ─── Drag-to-sweep ────────────────────────────────────────
  /// How wide the page-turning strip at each edge is.
  static const edgeScrollZone = 28.0;

  /// How long a finger has to rest in the strip before it turns.
  static const edgeScrollDelay = Duration(milliseconds: 500);

  /// And how long before it may turn again — without it, one held
  /// finger flips through a year.
  static const edgeScrollCooldown = Duration(milliseconds: 800);

  // ─── Month flow ───────────────────────────────────────────
  /// How many points of the neighbouring months show at each side.
  ///
  /// Comfortably more than the inset it is spent out of, so it is most
  /// of a day cell rather than a hairline. What it costs the focused
  /// month is twice the difference between the two — around twenty
  /// points across seven columns, which is three points a column.
  static const monthPeek = 28.0;

  static const neighbourOpacity = 0.35;

  /// The fade band at a scrolled or paged surface's edges.
  static const edgeFadeSize = 16.0;

  /// The gap between months in the vertical list.
  static const monthListGap = 24.0;

  // ─── Clock face ───────────────────────────────────────────
  /// How wide the dial is, before the window clamps it.
  static const dialSize = 256.0;

  /// The ring the hour labels sit on, as a fraction of the radius.
  static const dialLabelRadius = 0.82;

  /// And the inner ring, for the second half of a 24-hour day.
  static const dialInnerLabelRadius = 0.55;

  /// The disc at the end of the hand.
  static const dialKnobRadius = 18.0;

  /// The dot at the middle.
  static const dialCentreRadius = 4.0;

  static const dialHandWidth = 2.0;

  // ─── Motion ───────────────────────────────────────────────
  static const overlayDuration = AppDurations.fast;
  static const viewSwitchDuration = AppDurations.normal;
  static const pageDuration = AppDurations.normal;
}

// ---------------------------------------------------------------------------
// DateTimePickerStyle — the themeable bag
// ---------------------------------------------------------------------------

/// How every date / time picker in this module LOOKS and behaves.
///
/// Every field is nullable so the three sources layer without a
/// default clobbering a theme: `caller > GlobalDateTimePickerTheme.style
/// > DateTimePickerStyle.defaults`. Resolved once per build into a
/// [ResolvedDateTimePickerStyle].
///
/// It replaces `CalendarStyle`, which was half the surface (the
/// calendar only), non-nullable, and read `Theme.of(context)` where it
/// fell back — so a rebrand reached the wheels and the triggers not at
/// all, and the calendar only through `colorScheme`.
@immutable
class DateTimePickerStyle {
  const DateTimePickerStyle({
    this.monthFlow,
    this.monthPeek,
    this.neighbourOpacity,
    this.edgeFadeSize,
    this.calendar,
    this.focusRingColor,
    this.showWeekNumbers,
    this.timeLayout,
    this.rangeLayout,
    this.dialSize,
    this.dialFaceColor,
    this.surfaceColor,
    this.radius,
    this.borderColor,
    this.borderWidth,
    this.shadow,
    this.triggerPadding,
    this.triggerRadius,
    this.triggerIconSize,
    this.triggerGap,
    this.triggerFillColor,
    this.triggerBorderColor,
    this.triggerActiveBorderColor,
    this.triggerBorderWidth,
    this.triggerTextStyle,
    this.triggerHintColor,
    this.triggerIconColor,
    this.wheelItemExtent,
    this.wheelMagnification,
    this.wheelSqueeze,
    this.wheelMagnifier,
    this.wheelHeight,
    this.wheelTextStyle,
    this.wheelSeparatorStyle,
    this.wheelSeparatorGap,
    this.wheelSelectionColor,
    this.headerPadding,
    this.headerHeight,
    this.headerTitleStyle,
    this.dayCellSize,
    this.dayCellMargin,
    this.dayRadius,
    this.dayShape,
    this.dayFontSize,
    this.dayFontWeight,
    this.dayTextColor,
    this.selectedDayColor,
    this.selectedDayTextColor,
    this.selectedDayShape,
    this.selectedDayFontWeight,
    this.selectedGradient,
    this.rangeFillColor,
    this.rangeTextColor,
    this.todayBorderColor,
    this.todayBorderWidth,
    this.todayTextColor,
    this.todayShape,
    this.todayFontWeight,
    this.disabledDayOpacity,
    this.outsideDayOpacity,
    this.weekdayLabelFontSize,
    this.weekdayLabelColor,
    this.calendarHeaderFontSize,
    this.calendarHeaderFontWeight,
    this.arrowIconSize,
    this.arrowColor,
    this.gridCellRadius,
    this.gridViewHeight,
    this.markerSize,
    this.markerSpacing,
    this.maxMarkers,
    this.additionalDayColor,
    this.overlayRadius,
    this.overlayElevation,
    this.overlayGap,
    this.overlayMaxHeight,
    this.overlayMinHeight,
    this.overlayScreenMargin,
    this.overlayShadowColor,
    this.overlayMatchTriggerWidth,
    this.showOutsideDays,
    this.showTodayHighlight,
    this.enableHaptic,
    this.enableDragSelect,
    this.enableSwipeMonths,
    this.enableEdgeScroll,
    this.overlayDuration,
    this.viewSwitchDuration,
    this.pageDuration,
  });

  /// The floor.
  ///
  /// Colours are absent on purpose — they resolve from the palette at
  /// build time so they track role, brightness and saturation, which a
  /// constant cannot. So are the token-shaped sizes, which
  /// `MyGlobalDateTimePickerTheme` fills from `AppTokens`.
  static const DateTimePickerStyle defaults = DateTimePickerStyle(
    wheelItemExtent: DateTimePickerDefaults.wheelItemExtent,
    wheelMagnification: DateTimePickerDefaults.wheelMagnification,
    wheelSqueeze: DateTimePickerDefaults.wheelSqueeze,
    wheelMagnifier: true,
    wheelHeight: DateTimePickerDefaults.wheelHeight,
    headerHeight: DateTimePickerDefaults.headerHeight,
    triggerIconSize: DateTimePickerDefaults.triggerIconSize,
    triggerBorderWidth: DateTimePickerDefaults.triggerBorderWidth,
    dayCellSize: DateTimePickerDefaults.dayCellSize,
    dayCellMargin: DateTimePickerDefaults.dayCellMargin,
    dayShape: BoxShape.rectangle,
    dayFontSize: DateTimePickerDefaults.dayFontSize,
    selectedDayFontWeight: FontWeight.w600,
    todayBorderWidth: DateTimePickerDefaults.todayBorderWidth,
    todayFontWeight: FontWeight.w700,
    disabledDayOpacity: DateTimePickerDefaults.disabledDayOpacity,
    outsideDayOpacity: DateTimePickerDefaults.outsideDayOpacity,
    weekdayLabelFontSize: DateTimePickerDefaults.weekdayLabelFontSize,
    calendarHeaderFontSize: DateTimePickerDefaults.calendarHeaderFontSize,
    calendarHeaderFontWeight: FontWeight.w700,
    arrowIconSize: DateTimePickerDefaults.arrowIconSize,
    gridViewHeight: DateTimePickerDefaults.gridViewHeight,
    markerSize: DateTimePickerDefaults.markerSize,
    markerSpacing: DateTimePickerDefaults.markerSpacing,
    maxMarkers: DateTimePickerDefaults.maxMarkers,
    additionalDayColor: DateTimePickerDefaults.additionalDayColor,
    overlayElevation: DateTimePickerDefaults.overlayElevation,
    overlayMaxHeight: DateTimePickerDefaults.overlayMaxHeight,
    overlayMinHeight: DateTimePickerDefaults.overlayMinHeight,
    overlayScreenMargin: DateTimePickerDefaults.overlayScreenMargin,
    overlayShadowColor: DateTimePickerDefaults.overlayShadowColor,
    overlayMatchTriggerWidth: true,
    showOutsideDays: false,
    showTodayHighlight: true,
    enableHaptic: true,
    enableDragSelect: true,
    enableSwipeMonths: true,
    enableEdgeScroll: true,
    overlayDuration: DateTimePickerDefaults.overlayDuration,
    viewSwitchDuration: DateTimePickerDefaults.viewSwitchDuration,
    pageDuration: DateTimePickerDefaults.pageDuration,
    timeLayout: TimePickerLayout.wheels,
    rangeLayout: RangePickerLayout.dialog,
    dialSize: DateTimePickerDefaults.dialSize,
    calendar: PickerCalendar.gregorian,
    showWeekNumbers: false,
    monthFlow: MonthFlow.paged,
    monthPeek: DateTimePickerDefaults.monthPeek,
    neighbourOpacity: DateTimePickerDefaults.neighbourOpacity,
    edgeFadeSize: DateTimePickerDefaults.edgeFadeSize,
  );

  // ─── Presets ──────────────────────────────────────────────
  //
  // A preset is a NAMED BAG. Everything it decides is what the bag
  // already carries, so it merges with a theme and loses to a
  // per-call override like any other bag, and adds no code path.

  /// A calendar inside a dense form or a narrow overlay.
  ///
  /// Smaller cells and type, no shadow, no drag-sweep: at 32 points a
  /// cell is under the 44-point target a SWEEP needs to stay
  /// accurate, and a mis-swept range is worse than two taps.
  static const DateTimePickerStyle compact = DateTimePickerStyle(
    dayCellSize: 32,
    dayCellMargin: 2,
    dayFontSize: 13,
    weekdayLabelFontSize: 12,
    calendarHeaderFontSize: 14,
    arrowIconSize: 20,
    gridViewHeight: 220,
    wheelItemExtent: 32,
    wheelHeight: DateTimePickerDefaults.wheelMinHeight,
    shadow: <BoxShadow>[],
    enableDragSelect: false,
  );

  /// Material's look: round day cells, no panel.
  ///
  /// A round cell cannot draw a continuous range bar, so the range
  /// reads as a row of discs rather than as one span. That is the
  /// trade — pick it for single-date pickers.
  static const DateTimePickerStyle circular = DateTimePickerStyle(
    dayShape: BoxShape.circle,
    shadow: <BoxShadow>[],
    borderColor: Colors.transparent,
    surfaceColor: Colors.transparent,
  );

  /// No panel at all — for a picker already inside a card or sheet.
  static const DateTimePickerStyle flat = DateTimePickerStyle(
    shadow: <BoxShadow>[],
    borderColor: Colors.transparent,
    surfaceColor: Colors.transparent,
    borderWidth: 0,
  );

  // ─── Surface — the panel behind the wheels, the calendar and the overlay.

  /// The panel's fill. Falls back to `backgroundColors.container` —
  /// a picker sits ABOVE the page, the same argument
  /// `GlobalContainer` makes for its own fill.
  final Color? surfaceColor;

  /// The panel's corner.
  final double? radius;

  final Color? borderColor;

  final double? borderWidth;

  /// `null` asks for the house shadow; `const []` is a FLAT panel.
  /// Collapsing the two makes flat impossible to ask for — the same
  /// rule `ContainerStyle.shadow` follows.
  final List<BoxShadow>? shadow;

  // ─── Trigger — the button that opens a dialog or an overlay.

  final EdgeInsetsGeometry? triggerPadding;

  final double? triggerRadius;

  final double? triggerIconSize;

  /// Glyph to label.
  final double? triggerGap;

  final Color? triggerFillColor;

  final Color? triggerBorderColor;

  /// The border while the overlay is open.
  final Color? triggerActiveBorderColor;

  final double? triggerBorderWidth;

  final TextStyle? triggerTextStyle;

  /// The label when there is no value yet.
  final Color? triggerHintColor;

  final Color? triggerIconColor;

  // ─── Wheels.

  final double? wheelItemExtent;

  final double? wheelMagnification;

  final double? wheelSqueeze;

  /// The lens over the selected row.
  final bool? wheelMagnifier;

  /// The inline wheel picker's height, header excluded.
  final double? wheelHeight;

  final TextStyle? wheelTextStyle;

  /// The `/` and `:` between wheels.
  final TextStyle? wheelSeparatorStyle;

  final double? wheelSeparatorGap;

  /// The band behind the selected row. Cupertino paints its own
  /// grey; this one tracks the palette.
  final Color? wheelSelectionColor;

  // ─── Wheel header — the cancel / title / done row.

  final double? headerPadding;

  final double? headerHeight;

  final TextStyle? headerTitleStyle;

  // ─── Calendar.

  final double? dayCellSize;

  final double? dayCellMargin;

  /// The corner a day cell rounds by when [dayShape] is a rectangle.
  /// Range ends round only on their outer side, so this is also the
  /// radius the bar's two ends wear.
  final double? dayRadius;

  final BoxShape? dayShape;

  final double? dayFontSize;

  final FontWeight? dayFontWeight;

  final Color? dayTextColor;

  final Color? selectedDayColor;

  /// Falls back to `textColors.onPrimary`, not `Colors.white` — a
  /// light-primary brand had white-on-yellow days.
  final Color? selectedDayTextColor;

  /// Falls back to [dayShape].
  final BoxShape? selectedDayShape;

  final FontWeight? selectedDayFontWeight;

  /// Painted INSTEAD of [selectedDayColor] when set. Stays nullable
  /// through resolution — a flat fill is a legitimate answer.
  final Gradient? selectedGradient;

  /// The bar between the two ends.
  final Color? rangeFillColor;

  final Color? rangeTextColor;

  final Color? todayBorderColor;

  final double? todayBorderWidth;

  final Color? todayTextColor;

  /// Falls back to [dayShape].
  final BoxShape? todayShape;

  final FontWeight? todayFontWeight;

  final double? disabledDayOpacity;

  /// Days from the neighbouring months, when they are shown.
  final double? outsideDayOpacity;

  final double? weekdayLabelFontSize;

  final Color? weekdayLabelColor;

  /// The month + year line.
  final double? calendarHeaderFontSize;

  final FontWeight? calendarHeaderFontWeight;

  final double? arrowIconSize;

  final Color? arrowColor;

  /// The month-grid and year-grid cells.
  final double? gridCellRadius;

  /// How tall the month / year grid is. It is a FIXED height, and
  /// short windows clamp it — see the module's CLAUDE.md.
  final double? gridViewHeight;

  final double? markerSize;

  final double? markerSpacing;

  /// How many dots one day can show before the rest are dropped.
  final int? maxMarkers;

  /// The tail after the range's end, drawn when `additionalDays` is
  /// set. A hotel's checkout day, a rental's grace period.
  final Color? additionalDayColor;

  // ─── Overlay.

  final double? overlayRadius;

  final double? overlayElevation;

  /// Between the trigger and the panel.
  final double? overlayGap;

  final double? overlayMaxHeight;

  final double? overlayMinHeight;

  /// How close the panel may come to the screen's edge.
  final double? overlayScreenMargin;

  final Color? overlayShadowColor;

  /// Whether the panel is exactly as wide as the trigger. Off lets a
  /// calendar keep its own width under a narrow field, which is the
  /// only way seven columns fit.
  final bool? overlayMatchTriggerWidth;

  // ─── Behaviour.

  /// Grey days from the neighbouring months in the empty cells.
  final bool? showOutsideDays;

  final bool? showTodayHighlight;

  final bool? enableHaptic;

  /// Long-press and drag across the grid to sweep a range. Ignored
  /// in single-select — there is no range to sweep.
  final bool? enableDragSelect;

  final bool? enableSwipeMonths;

  /// While sweeping, holding at an edge turns the page. Costs a
  /// timer and a cooldown; off makes a drag stay in its month.
  final bool? enableEdgeScroll;

  // ─── Layout.

  /// Spinning wheels, or a clock face. Wheels set a time in one
  /// gesture per part; a dial is faster to read back and is what a
  /// phone's own alarm looks like.
  final TimePickerLayout? timeLayout;

  /// A modal, or a page of its own. A range on a phone wants the
  /// room — the modal's calendar and its two dates leave a month grid
  /// squeezed between them.
  final RangePickerLayout? rangeLayout;

  /// The clock face, across.
  final double? dialSize;

  /// The disc the hours sit on.
  final Color? dialFaceColor;

  /// The ring around the day the KEYBOARD is on.
  ///
  /// A separate thing from the selection and from today: it says where
  /// the arrow keys will act, which is information neither of the other
  /// two carries.
  final Color? focusRingColor;

  /// A leading column of ISO week numbers.
  ///
  /// Off. It costs a column of width, and outside the businesses that
  /// plan by week number nobody reads it.
  final bool? showWeekNumbers;

  /// Which calendar the month grid counts in.
  ///
  /// The value a picker reports is always a `DateTime`, whichever
  /// calendar drew it — only the counting changes. The WHEELS stay
  /// Gregorian; see the module's CLAUDE.md.
  final PickerCalendar? calendar;

  /// One month swiped sideways, or a vertical list of them.
  final MonthFlow? monthFlow;

  /// How many POINTS of the neighbouring months show at each side.
  ///
  /// A month with nothing either side of it gives no sense of where it
  /// sits; a sliver of the one before and the one after does, and is
  /// the affordance that says the grid swipes at all. Zero pins one
  /// month to the view.
  ///
  /// It is a length, not a fraction of the view, because it is spent
  /// out of the panel's own horizontal INSET rather than out of the
  /// grid: at the default the focused month is within a couple of
  /// points of the width it has with no peek at all. A fraction made it
  /// look as though switching the peek on added padding, because it
  /// took its slice from the seven columns.
  final double? monthPeek;

  /// How far a peeking month is dimmed. It is context, not content.
  final double? neighbourOpacity;

  /// The band a scrolled or paged surface fades over at its edges.
  final double? edgeFadeSize;

  // ─── Motion.

  final Duration? overlayDuration;

  /// Days ↔ months ↔ years.
  final Duration? viewSwitchDuration;

  /// One month to the next.
  final Duration? pageDuration;

  /// [other] wins field by field. Null means "did not say", which is
  /// what lets a caller override one thing without restating a theme.
  DateTimePickerStyle mergedWith(DateTimePickerStyle? other) {
    if (other == null) return this;
    return DateTimePickerStyle(
      surfaceColor: other.surfaceColor ?? surfaceColor,
      radius: other.radius ?? radius,
      borderColor: other.borderColor ?? borderColor,
      borderWidth: other.borderWidth ?? borderWidth,
      shadow: other.shadow ?? shadow,
      triggerPadding: other.triggerPadding ?? triggerPadding,
      triggerRadius: other.triggerRadius ?? triggerRadius,
      triggerIconSize: other.triggerIconSize ?? triggerIconSize,
      triggerGap: other.triggerGap ?? triggerGap,
      triggerFillColor: other.triggerFillColor ?? triggerFillColor,
      triggerBorderColor: other.triggerBorderColor ?? triggerBorderColor,
      triggerActiveBorderColor:
          other.triggerActiveBorderColor ?? triggerActiveBorderColor,
      triggerBorderWidth: other.triggerBorderWidth ?? triggerBorderWidth,
      triggerTextStyle: other.triggerTextStyle ?? triggerTextStyle,
      triggerHintColor: other.triggerHintColor ?? triggerHintColor,
      triggerIconColor: other.triggerIconColor ?? triggerIconColor,
      wheelItemExtent: other.wheelItemExtent ?? wheelItemExtent,
      wheelMagnification: other.wheelMagnification ?? wheelMagnification,
      wheelSqueeze: other.wheelSqueeze ?? wheelSqueeze,
      wheelMagnifier: other.wheelMagnifier ?? wheelMagnifier,
      wheelHeight: other.wheelHeight ?? wheelHeight,
      wheelTextStyle: other.wheelTextStyle ?? wheelTextStyle,
      wheelSeparatorStyle: other.wheelSeparatorStyle ?? wheelSeparatorStyle,
      wheelSeparatorGap: other.wheelSeparatorGap ?? wheelSeparatorGap,
      wheelSelectionColor: other.wheelSelectionColor ?? wheelSelectionColor,
      headerPadding: other.headerPadding ?? headerPadding,
      headerHeight: other.headerHeight ?? headerHeight,
      headerTitleStyle: other.headerTitleStyle ?? headerTitleStyle,
      dayCellSize: other.dayCellSize ?? dayCellSize,
      dayCellMargin: other.dayCellMargin ?? dayCellMargin,
      dayRadius: other.dayRadius ?? dayRadius,
      dayShape: other.dayShape ?? dayShape,
      dayFontSize: other.dayFontSize ?? dayFontSize,
      dayFontWeight: other.dayFontWeight ?? dayFontWeight,
      dayTextColor: other.dayTextColor ?? dayTextColor,
      selectedDayColor: other.selectedDayColor ?? selectedDayColor,
      selectedDayTextColor: other.selectedDayTextColor ?? selectedDayTextColor,
      selectedDayShape: other.selectedDayShape ?? selectedDayShape,
      selectedDayFontWeight:
          other.selectedDayFontWeight ?? selectedDayFontWeight,
      selectedGradient: other.selectedGradient ?? selectedGradient,
      rangeFillColor: other.rangeFillColor ?? rangeFillColor,
      rangeTextColor: other.rangeTextColor ?? rangeTextColor,
      todayBorderColor: other.todayBorderColor ?? todayBorderColor,
      todayBorderWidth: other.todayBorderWidth ?? todayBorderWidth,
      todayTextColor: other.todayTextColor ?? todayTextColor,
      todayShape: other.todayShape ?? todayShape,
      todayFontWeight: other.todayFontWeight ?? todayFontWeight,
      disabledDayOpacity: other.disabledDayOpacity ?? disabledDayOpacity,
      outsideDayOpacity: other.outsideDayOpacity ?? outsideDayOpacity,
      weekdayLabelFontSize: other.weekdayLabelFontSize ?? weekdayLabelFontSize,
      weekdayLabelColor: other.weekdayLabelColor ?? weekdayLabelColor,
      calendarHeaderFontSize:
          other.calendarHeaderFontSize ?? calendarHeaderFontSize,
      calendarHeaderFontWeight:
          other.calendarHeaderFontWeight ?? calendarHeaderFontWeight,
      arrowIconSize: other.arrowIconSize ?? arrowIconSize,
      arrowColor: other.arrowColor ?? arrowColor,
      gridCellRadius: other.gridCellRadius ?? gridCellRadius,
      gridViewHeight: other.gridViewHeight ?? gridViewHeight,
      markerSize: other.markerSize ?? markerSize,
      markerSpacing: other.markerSpacing ?? markerSpacing,
      maxMarkers: other.maxMarkers ?? maxMarkers,
      additionalDayColor: other.additionalDayColor ?? additionalDayColor,
      overlayRadius: other.overlayRadius ?? overlayRadius,
      overlayElevation: other.overlayElevation ?? overlayElevation,
      overlayGap: other.overlayGap ?? overlayGap,
      overlayMaxHeight: other.overlayMaxHeight ?? overlayMaxHeight,
      overlayMinHeight: other.overlayMinHeight ?? overlayMinHeight,
      overlayScreenMargin: other.overlayScreenMargin ?? overlayScreenMargin,
      overlayShadowColor: other.overlayShadowColor ?? overlayShadowColor,
      overlayMatchTriggerWidth:
          other.overlayMatchTriggerWidth ?? overlayMatchTriggerWidth,
      showOutsideDays: other.showOutsideDays ?? showOutsideDays,
      showTodayHighlight: other.showTodayHighlight ?? showTodayHighlight,
      enableHaptic: other.enableHaptic ?? enableHaptic,
      enableDragSelect: other.enableDragSelect ?? enableDragSelect,
      enableSwipeMonths: other.enableSwipeMonths ?? enableSwipeMonths,
      enableEdgeScroll: other.enableEdgeScroll ?? enableEdgeScroll,
      overlayDuration: other.overlayDuration ?? overlayDuration,
      viewSwitchDuration: other.viewSwitchDuration ?? viewSwitchDuration,
      pageDuration: other.pageDuration ?? pageDuration,
      timeLayout: other.timeLayout ?? timeLayout,
      rangeLayout: other.rangeLayout ?? rangeLayout,
      dialSize: other.dialSize ?? dialSize,
      dialFaceColor: other.dialFaceColor ?? dialFaceColor,
      calendar: other.calendar ?? calendar,
      focusRingColor: other.focusRingColor ?? focusRingColor,
      showWeekNumbers: other.showWeekNumbers ?? showWeekNumbers,
      monthFlow: other.monthFlow ?? monthFlow,
      monthPeek: other.monthPeek ?? monthPeek,
      neighbourOpacity: other.neighbourOpacity ?? neighbourOpacity,
      edgeFadeSize: other.edgeFadeSize ?? edgeFadeSize,
    );
  }

  DateTimePickerStyle copyWith({
    Color? surfaceColor,
    double? radius,
    Color? borderColor,
    double? borderWidth,
    List<BoxShadow>? shadow,
    EdgeInsetsGeometry? triggerPadding,
    double? triggerRadius,
    double? triggerIconSize,
    double? triggerGap,
    Color? triggerFillColor,
    Color? triggerBorderColor,
    Color? triggerActiveBorderColor,
    double? triggerBorderWidth,
    TextStyle? triggerTextStyle,
    Color? triggerHintColor,
    Color? triggerIconColor,
    double? wheelItemExtent,
    double? wheelMagnification,
    double? wheelSqueeze,
    bool? wheelMagnifier,
    double? wheelHeight,
    TextStyle? wheelTextStyle,
    TextStyle? wheelSeparatorStyle,
    double? wheelSeparatorGap,
    Color? wheelSelectionColor,
    double? headerPadding,
    double? headerHeight,
    TextStyle? headerTitleStyle,
    double? dayCellSize,
    double? dayCellMargin,
    double? dayRadius,
    BoxShape? dayShape,
    double? dayFontSize,
    FontWeight? dayFontWeight,
    Color? dayTextColor,
    Color? selectedDayColor,
    Color? selectedDayTextColor,
    BoxShape? selectedDayShape,
    FontWeight? selectedDayFontWeight,
    Gradient? selectedGradient,
    Color? rangeFillColor,
    Color? rangeTextColor,
    Color? todayBorderColor,
    double? todayBorderWidth,
    Color? todayTextColor,
    BoxShape? todayShape,
    FontWeight? todayFontWeight,
    double? disabledDayOpacity,
    double? outsideDayOpacity,
    double? weekdayLabelFontSize,
    Color? weekdayLabelColor,
    double? calendarHeaderFontSize,
    FontWeight? calendarHeaderFontWeight,
    double? arrowIconSize,
    Color? arrowColor,
    double? gridCellRadius,
    double? gridViewHeight,
    double? markerSize,
    double? markerSpacing,
    int? maxMarkers,
    Color? additionalDayColor,
    double? overlayRadius,
    double? overlayElevation,
    double? overlayGap,
    double? overlayMaxHeight,
    double? overlayMinHeight,
    double? overlayScreenMargin,
    Color? overlayShadowColor,
    bool? overlayMatchTriggerWidth,
    bool? showOutsideDays,
    bool? showTodayHighlight,
    bool? enableHaptic,
    bool? enableDragSelect,
    bool? enableSwipeMonths,
    bool? enableEdgeScroll,
    Duration? overlayDuration,
    Duration? viewSwitchDuration,
    Duration? pageDuration,
    TimePickerLayout? timeLayout,
    RangePickerLayout? rangeLayout,
    double? dialSize,
    Color? dialFaceColor,
    PickerCalendar? calendar,
    Color? focusRingColor,
    bool? showWeekNumbers,
    MonthFlow? monthFlow,
    double? monthPeek,
    double? neighbourOpacity,
    double? edgeFadeSize,
  }) => DateTimePickerStyle(
    surfaceColor: surfaceColor ?? this.surfaceColor,
    radius: radius ?? this.radius,
    borderColor: borderColor ?? this.borderColor,
    borderWidth: borderWidth ?? this.borderWidth,
    shadow: shadow ?? this.shadow,
    triggerPadding: triggerPadding ?? this.triggerPadding,
    triggerRadius: triggerRadius ?? this.triggerRadius,
    triggerIconSize: triggerIconSize ?? this.triggerIconSize,
    triggerGap: triggerGap ?? this.triggerGap,
    triggerFillColor: triggerFillColor ?? this.triggerFillColor,
    triggerBorderColor: triggerBorderColor ?? this.triggerBorderColor,
    triggerActiveBorderColor:
        triggerActiveBorderColor ?? this.triggerActiveBorderColor,
    triggerBorderWidth: triggerBorderWidth ?? this.triggerBorderWidth,
    triggerTextStyle: triggerTextStyle ?? this.triggerTextStyle,
    triggerHintColor: triggerHintColor ?? this.triggerHintColor,
    triggerIconColor: triggerIconColor ?? this.triggerIconColor,
    wheelItemExtent: wheelItemExtent ?? this.wheelItemExtent,
    wheelMagnification: wheelMagnification ?? this.wheelMagnification,
    wheelSqueeze: wheelSqueeze ?? this.wheelSqueeze,
    wheelMagnifier: wheelMagnifier ?? this.wheelMagnifier,
    wheelHeight: wheelHeight ?? this.wheelHeight,
    wheelTextStyle: wheelTextStyle ?? this.wheelTextStyle,
    wheelSeparatorStyle: wheelSeparatorStyle ?? this.wheelSeparatorStyle,
    wheelSeparatorGap: wheelSeparatorGap ?? this.wheelSeparatorGap,
    wheelSelectionColor: wheelSelectionColor ?? this.wheelSelectionColor,
    headerPadding: headerPadding ?? this.headerPadding,
    headerHeight: headerHeight ?? this.headerHeight,
    headerTitleStyle: headerTitleStyle ?? this.headerTitleStyle,
    dayCellSize: dayCellSize ?? this.dayCellSize,
    dayCellMargin: dayCellMargin ?? this.dayCellMargin,
    dayRadius: dayRadius ?? this.dayRadius,
    dayShape: dayShape ?? this.dayShape,
    dayFontSize: dayFontSize ?? this.dayFontSize,
    dayFontWeight: dayFontWeight ?? this.dayFontWeight,
    dayTextColor: dayTextColor ?? this.dayTextColor,
    selectedDayColor: selectedDayColor ?? this.selectedDayColor,
    selectedDayTextColor: selectedDayTextColor ?? this.selectedDayTextColor,
    selectedDayShape: selectedDayShape ?? this.selectedDayShape,
    selectedDayFontWeight: selectedDayFontWeight ?? this.selectedDayFontWeight,
    selectedGradient: selectedGradient ?? this.selectedGradient,
    rangeFillColor: rangeFillColor ?? this.rangeFillColor,
    rangeTextColor: rangeTextColor ?? this.rangeTextColor,
    todayBorderColor: todayBorderColor ?? this.todayBorderColor,
    todayBorderWidth: todayBorderWidth ?? this.todayBorderWidth,
    todayTextColor: todayTextColor ?? this.todayTextColor,
    todayShape: todayShape ?? this.todayShape,
    todayFontWeight: todayFontWeight ?? this.todayFontWeight,
    disabledDayOpacity: disabledDayOpacity ?? this.disabledDayOpacity,
    outsideDayOpacity: outsideDayOpacity ?? this.outsideDayOpacity,
    weekdayLabelFontSize: weekdayLabelFontSize ?? this.weekdayLabelFontSize,
    weekdayLabelColor: weekdayLabelColor ?? this.weekdayLabelColor,
    calendarHeaderFontSize:
        calendarHeaderFontSize ?? this.calendarHeaderFontSize,
    calendarHeaderFontWeight:
        calendarHeaderFontWeight ?? this.calendarHeaderFontWeight,
    arrowIconSize: arrowIconSize ?? this.arrowIconSize,
    arrowColor: arrowColor ?? this.arrowColor,
    gridCellRadius: gridCellRadius ?? this.gridCellRadius,
    gridViewHeight: gridViewHeight ?? this.gridViewHeight,
    markerSize: markerSize ?? this.markerSize,
    markerSpacing: markerSpacing ?? this.markerSpacing,
    maxMarkers: maxMarkers ?? this.maxMarkers,
    additionalDayColor: additionalDayColor ?? this.additionalDayColor,
    overlayRadius: overlayRadius ?? this.overlayRadius,
    overlayElevation: overlayElevation ?? this.overlayElevation,
    overlayGap: overlayGap ?? this.overlayGap,
    overlayMaxHeight: overlayMaxHeight ?? this.overlayMaxHeight,
    overlayMinHeight: overlayMinHeight ?? this.overlayMinHeight,
    overlayScreenMargin: overlayScreenMargin ?? this.overlayScreenMargin,
    overlayShadowColor: overlayShadowColor ?? this.overlayShadowColor,
    overlayMatchTriggerWidth:
        overlayMatchTriggerWidth ?? this.overlayMatchTriggerWidth,
    showOutsideDays: showOutsideDays ?? this.showOutsideDays,
    showTodayHighlight: showTodayHighlight ?? this.showTodayHighlight,
    enableHaptic: enableHaptic ?? this.enableHaptic,
    enableDragSelect: enableDragSelect ?? this.enableDragSelect,
    enableSwipeMonths: enableSwipeMonths ?? this.enableSwipeMonths,
    enableEdgeScroll: enableEdgeScroll ?? this.enableEdgeScroll,
    overlayDuration: overlayDuration ?? this.overlayDuration,
    viewSwitchDuration: viewSwitchDuration ?? this.viewSwitchDuration,
    pageDuration: pageDuration ?? this.pageDuration,
    timeLayout: timeLayout ?? this.timeLayout,
    rangeLayout: rangeLayout ?? this.rangeLayout,
    dialSize: dialSize ?? this.dialSize,
    dialFaceColor: dialFaceColor ?? this.dialFaceColor,
    calendar: calendar ?? this.calendar,
    focusRingColor: focusRingColor ?? this.focusRingColor,
    showWeekNumbers: showWeekNumbers ?? this.showWeekNumbers,
    monthFlow: monthFlow ?? this.monthFlow,
    monthPeek: monthPeek ?? this.monthPeek,
    neighbourOpacity: neighbourOpacity ?? this.neighbourOpacity,
    edgeFadeSize: edgeFadeSize ?? this.edgeFadeSize,
  );

  @override
  bool operator ==(Object other) =>
      other is DateTimePickerStyle &&
      other.surfaceColor == surfaceColor &&
      other.radius == radius &&
      other.borderColor == borderColor &&
      other.borderWidth == borderWidth &&
      listEquals(other.shadow, shadow) &&
      other.triggerPadding == triggerPadding &&
      other.triggerRadius == triggerRadius &&
      other.triggerIconSize == triggerIconSize &&
      other.triggerGap == triggerGap &&
      other.triggerFillColor == triggerFillColor &&
      other.triggerBorderColor == triggerBorderColor &&
      other.triggerActiveBorderColor == triggerActiveBorderColor &&
      other.triggerBorderWidth == triggerBorderWidth &&
      other.triggerTextStyle == triggerTextStyle &&
      other.triggerHintColor == triggerHintColor &&
      other.triggerIconColor == triggerIconColor &&
      other.wheelItemExtent == wheelItemExtent &&
      other.wheelMagnification == wheelMagnification &&
      other.wheelSqueeze == wheelSqueeze &&
      other.wheelMagnifier == wheelMagnifier &&
      other.wheelHeight == wheelHeight &&
      other.wheelTextStyle == wheelTextStyle &&
      other.wheelSeparatorStyle == wheelSeparatorStyle &&
      other.wheelSeparatorGap == wheelSeparatorGap &&
      other.wheelSelectionColor == wheelSelectionColor &&
      other.headerPadding == headerPadding &&
      other.headerHeight == headerHeight &&
      other.headerTitleStyle == headerTitleStyle &&
      other.dayCellSize == dayCellSize &&
      other.dayCellMargin == dayCellMargin &&
      other.dayRadius == dayRadius &&
      other.dayShape == dayShape &&
      other.dayFontSize == dayFontSize &&
      other.dayFontWeight == dayFontWeight &&
      other.dayTextColor == dayTextColor &&
      other.selectedDayColor == selectedDayColor &&
      other.selectedDayTextColor == selectedDayTextColor &&
      other.selectedDayShape == selectedDayShape &&
      other.selectedDayFontWeight == selectedDayFontWeight &&
      other.selectedGradient == selectedGradient &&
      other.rangeFillColor == rangeFillColor &&
      other.rangeTextColor == rangeTextColor &&
      other.todayBorderColor == todayBorderColor &&
      other.todayBorderWidth == todayBorderWidth &&
      other.todayTextColor == todayTextColor &&
      other.todayShape == todayShape &&
      other.todayFontWeight == todayFontWeight &&
      other.disabledDayOpacity == disabledDayOpacity &&
      other.outsideDayOpacity == outsideDayOpacity &&
      other.weekdayLabelFontSize == weekdayLabelFontSize &&
      other.weekdayLabelColor == weekdayLabelColor &&
      other.calendarHeaderFontSize == calendarHeaderFontSize &&
      other.calendarHeaderFontWeight == calendarHeaderFontWeight &&
      other.arrowIconSize == arrowIconSize &&
      other.arrowColor == arrowColor &&
      other.gridCellRadius == gridCellRadius &&
      other.gridViewHeight == gridViewHeight &&
      other.markerSize == markerSize &&
      other.markerSpacing == markerSpacing &&
      other.maxMarkers == maxMarkers &&
      other.additionalDayColor == additionalDayColor &&
      other.overlayRadius == overlayRadius &&
      other.overlayElevation == overlayElevation &&
      other.overlayGap == overlayGap &&
      other.overlayMaxHeight == overlayMaxHeight &&
      other.overlayMinHeight == overlayMinHeight &&
      other.overlayScreenMargin == overlayScreenMargin &&
      other.overlayShadowColor == overlayShadowColor &&
      other.overlayMatchTriggerWidth == overlayMatchTriggerWidth &&
      other.showOutsideDays == showOutsideDays &&
      other.showTodayHighlight == showTodayHighlight &&
      other.enableHaptic == enableHaptic &&
      other.enableDragSelect == enableDragSelect &&
      other.enableSwipeMonths == enableSwipeMonths &&
      other.enableEdgeScroll == enableEdgeScroll &&
      other.overlayDuration == overlayDuration &&
      other.viewSwitchDuration == viewSwitchDuration &&
      other.pageDuration == pageDuration &&
      other.timeLayout == timeLayout &&
      other.rangeLayout == rangeLayout &&
      other.dialSize == dialSize &&
      other.dialFaceColor == dialFaceColor &&
      other.calendar == calendar &&
      other.focusRingColor == focusRingColor &&
      other.showWeekNumbers == showWeekNumbers &&
      other.monthFlow == monthFlow &&
      other.monthPeek == monthPeek &&
      other.neighbourOpacity == neighbourOpacity &&
      other.edgeFadeSize == edgeFadeSize;

  @override
  int get hashCode => Object.hashAll(<Object?>[
    surfaceColor,
    radius,
    borderColor,
    borderWidth,
    shadow == null ? null : Object.hashAll(shadow!),
    triggerPadding,
    triggerRadius,
    triggerIconSize,
    triggerGap,
    triggerFillColor,
    triggerBorderColor,
    triggerActiveBorderColor,
    triggerBorderWidth,
    triggerTextStyle,
    triggerHintColor,
    triggerIconColor,
    wheelItemExtent,
    wheelMagnification,
    wheelSqueeze,
    wheelMagnifier,
    wheelHeight,
    wheelTextStyle,
    wheelSeparatorStyle,
    wheelSeparatorGap,
    wheelSelectionColor,
    headerPadding,
    headerHeight,
    headerTitleStyle,
    dayCellSize,
    dayCellMargin,
    dayRadius,
    dayShape,
    dayFontSize,
    dayFontWeight,
    dayTextColor,
    selectedDayColor,
    selectedDayTextColor,
    selectedDayShape,
    selectedDayFontWeight,
    selectedGradient,
    rangeFillColor,
    rangeTextColor,
    todayBorderColor,
    todayBorderWidth,
    todayTextColor,
    todayShape,
    todayFontWeight,
    disabledDayOpacity,
    outsideDayOpacity,
    weekdayLabelFontSize,
    weekdayLabelColor,
    calendarHeaderFontSize,
    calendarHeaderFontWeight,
    arrowIconSize,
    arrowColor,
    gridCellRadius,
    gridViewHeight,
    markerSize,
    markerSpacing,
    maxMarkers,
    additionalDayColor,
    overlayRadius,
    overlayElevation,
    overlayGap,
    overlayMaxHeight,
    overlayMinHeight,
    overlayScreenMargin,
    overlayShadowColor,
    overlayMatchTriggerWidth,
    showOutsideDays,
    showTodayHighlight,
    enableHaptic,
    enableDragSelect,
    enableSwipeMonths,
    enableEdgeScroll,
    overlayDuration,
    viewSwitchDuration,
    pageDuration,
    timeLayout,
    rangeLayout,
    dialSize,
    dialFaceColor,
    calendar,
    focusRingColor,
    showWeekNumbers,
    monthFlow,
    monthPeek,
    neighbourOpacity,
    edgeFadeSize,
  ]);
}

// ---------------------------------------------------------------------------
// ResolvedDateTimePickerStyle — the bag with every question answered
// ---------------------------------------------------------------------------

/// What the widgets actually read. Built once per build by
/// `DateTimePickerStyleResolve.resolve`, and held on the STATE rather
/// than in a `late` field — a picker can be laid out before its first
/// paint, and a `late` bag throws there.
@immutable
class ResolvedDateTimePickerStyle {
  const ResolvedDateTimePickerStyle({
    required this.surfaceColor,
    required this.radius,
    required this.borderColor,
    required this.borderWidth,
    required this.shadow,
    required this.triggerPadding,
    required this.triggerRadius,
    required this.triggerIconSize,
    required this.triggerGap,
    required this.triggerFillColor,
    required this.triggerBorderColor,
    required this.triggerActiveBorderColor,
    required this.triggerBorderWidth,
    required this.triggerTextStyle,
    required this.triggerHintColor,
    required this.triggerIconColor,
    required this.wheelItemExtent,
    required this.wheelMagnification,
    required this.wheelSqueeze,
    required this.wheelMagnifier,
    required this.wheelHeight,
    required this.wheelTextStyle,
    required this.wheelSeparatorStyle,
    required this.wheelSeparatorGap,
    required this.wheelSelectionColor,
    required this.headerPadding,
    required this.headerHeight,
    required this.headerTitleStyle,
    required this.dayCellSize,
    required this.dayCellMargin,
    required this.dayRadius,
    required this.dayShape,
    required this.dayFontSize,
    required this.dayFontWeight,
    required this.dayTextColor,
    required this.selectedDayColor,
    required this.selectedDayTextColor,
    required this.selectedDayShape,
    required this.selectedDayFontWeight,
    this.selectedGradient,
    required this.rangeFillColor,
    required this.rangeTextColor,
    required this.todayBorderColor,
    required this.todayBorderWidth,
    required this.todayTextColor,
    required this.todayShape,
    required this.todayFontWeight,
    required this.disabledDayOpacity,
    required this.outsideDayOpacity,
    required this.weekdayLabelFontSize,
    required this.weekdayLabelColor,
    required this.calendarHeaderFontSize,
    required this.calendarHeaderFontWeight,
    required this.arrowIconSize,
    required this.arrowColor,
    required this.gridCellRadius,
    required this.gridViewHeight,
    required this.markerSize,
    required this.markerSpacing,
    required this.maxMarkers,
    required this.additionalDayColor,
    required this.overlayRadius,
    required this.overlayElevation,
    required this.overlayGap,
    required this.overlayMaxHeight,
    required this.overlayMinHeight,
    required this.overlayScreenMargin,
    required this.overlayShadowColor,
    required this.overlayMatchTriggerWidth,
    required this.showOutsideDays,
    required this.showTodayHighlight,
    required this.enableHaptic,
    required this.enableDragSelect,
    required this.enableSwipeMonths,
    required this.enableEdgeScroll,
    required this.overlayDuration,
    required this.viewSwitchDuration,
    required this.pageDuration,
    required this.timeLayout,
    required this.rangeLayout,
    required this.dialSize,
    required this.dialFaceColor,
    required this.calendar,
    required this.focusRingColor,
    required this.showWeekNumbers,
    required this.monthFlow,
    required this.monthPeek,
    required this.neighbourOpacity,
    required this.edgeFadeSize,
  });

  final Color surfaceColor;
  final double radius;
  final Color borderColor;
  final double borderWidth;
  final List<BoxShadow> shadow;
  final EdgeInsetsGeometry triggerPadding;
  final double triggerRadius;
  final double triggerIconSize;
  final double triggerGap;
  final Color triggerFillColor;
  final Color triggerBorderColor;
  final Color triggerActiveBorderColor;
  final double triggerBorderWidth;
  final TextStyle triggerTextStyle;
  final Color triggerHintColor;
  final Color triggerIconColor;
  final double wheelItemExtent;
  final double wheelMagnification;
  final double wheelSqueeze;
  final bool wheelMagnifier;
  final double wheelHeight;
  final TextStyle wheelTextStyle;
  final TextStyle wheelSeparatorStyle;
  final double wheelSeparatorGap;
  final Color wheelSelectionColor;
  final double headerPadding;
  final double headerHeight;
  final TextStyle headerTitleStyle;
  final double dayCellSize;
  final double dayCellMargin;
  final double dayRadius;
  final BoxShape dayShape;
  final double dayFontSize;
  final FontWeight dayFontWeight;
  final Color dayTextColor;
  final Color selectedDayColor;
  final Color selectedDayTextColor;
  final BoxShape selectedDayShape;
  final FontWeight selectedDayFontWeight;
  final Gradient? selectedGradient;
  final Color rangeFillColor;
  final Color rangeTextColor;
  final Color todayBorderColor;
  final double todayBorderWidth;
  final Color todayTextColor;
  final BoxShape todayShape;
  final FontWeight todayFontWeight;
  final double disabledDayOpacity;
  final double outsideDayOpacity;
  final double weekdayLabelFontSize;
  final Color weekdayLabelColor;
  final double calendarHeaderFontSize;
  final FontWeight calendarHeaderFontWeight;
  final double arrowIconSize;
  final Color arrowColor;
  final double gridCellRadius;
  final double gridViewHeight;
  final double markerSize;
  final double markerSpacing;
  final int maxMarkers;
  final Color additionalDayColor;
  final double overlayRadius;
  final double overlayElevation;
  final double overlayGap;
  final double overlayMaxHeight;
  final double overlayMinHeight;
  final double overlayScreenMargin;
  final Color overlayShadowColor;
  final bool overlayMatchTriggerWidth;
  final bool showOutsideDays;
  final bool showTodayHighlight;
  final bool enableHaptic;
  final bool enableDragSelect;
  final bool enableSwipeMonths;
  final bool enableEdgeScroll;
  final Duration overlayDuration;
  final Duration viewSwitchDuration;
  final Duration pageDuration;
  final TimePickerLayout timeLayout;
  final RangePickerLayout rangeLayout;
  final double dialSize;
  final Color dialFaceColor;
  final PickerCalendar calendar;
  final Color focusRingColor;
  final bool showWeekNumbers;
  final MonthFlow monthFlow;
  final double monthPeek;
  final double neighbourOpacity;
  final double edgeFadeSize;

  /// A light-theme bag for code that has no `BuildContext` — painters,
  /// pure-geometry tests. NOT a runtime path: everything that builds
  /// goes through `resolve`.
  static const ResolvedDateTimePickerStyle fallback =
      ResolvedDateTimePickerStyle(
        surfaceColor: Color(0xFFFFFFFF),
        radius: 16,
        borderColor: Color(0x33000000),
        borderWidth: DateTimePickerDefaults.triggerBorderWidth,
        shadow: <BoxShadow>[],
        triggerPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        triggerRadius: 12,
        triggerIconSize: DateTimePickerDefaults.triggerIconSize,
        triggerGap: 12,
        triggerFillColor: Color(0xFFFFFFFF),
        triggerBorderColor: Color(0x33000000),
        triggerActiveBorderColor: Color(0xFF1565C0),
        triggerBorderWidth: DateTimePickerDefaults.triggerBorderWidth,
        triggerTextStyle: TextStyle(fontSize: 14),
        triggerHintColor: Color(0x80000000),
        triggerIconColor: Color(0x99000000),
        wheelItemExtent: DateTimePickerDefaults.wheelItemExtent,
        wheelMagnification: DateTimePickerDefaults.wheelMagnification,
        wheelSqueeze: DateTimePickerDefaults.wheelSqueeze,
        wheelMagnifier: true,
        wheelHeight: DateTimePickerDefaults.wheelHeight,
        wheelTextStyle: TextStyle(fontSize: 16),
        wheelSeparatorStyle: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
        ),
        wheelSeparatorGap: 8,
        wheelSelectionColor: Color(0x1F000000),
        headerPadding: 12,
        headerHeight: DateTimePickerDefaults.headerHeight,
        headerTitleStyle: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        dayCellSize: DateTimePickerDefaults.dayCellSize,
        dayCellMargin: DateTimePickerDefaults.dayCellMargin,
        dayRadius: 16,
        dayShape: BoxShape.rectangle,
        dayFontSize: DateTimePickerDefaults.dayFontSize,
        dayFontWeight: FontWeight.w400,
        dayTextColor: Color(0xFF1A1A1A),
        selectedDayColor: Color(0xFF1565C0),
        selectedDayTextColor: Color(0xFFFFFFFF),
        selectedDayShape: BoxShape.rectangle,
        selectedDayFontWeight: FontWeight.w600,
        rangeFillColor: Color(0x331565C0),
        rangeTextColor: Color(0xFF1A1A1A),
        todayBorderColor: Color(0xFF1565C0),
        todayBorderWidth: DateTimePickerDefaults.todayBorderWidth,
        todayTextColor: Color(0xFF1565C0),
        todayShape: BoxShape.rectangle,
        todayFontWeight: FontWeight.w700,
        disabledDayOpacity: DateTimePickerDefaults.disabledDayOpacity,
        outsideDayOpacity: DateTimePickerDefaults.outsideDayOpacity,
        weekdayLabelFontSize: DateTimePickerDefaults.weekdayLabelFontSize,
        weekdayLabelColor: Color(0x70000000),
        calendarHeaderFontSize: DateTimePickerDefaults.calendarHeaderFontSize,
        calendarHeaderFontWeight: FontWeight.w700,
        arrowIconSize: DateTimePickerDefaults.arrowIconSize,
        arrowColor: Color(0xFF1565C0),
        gridCellRadius: 12,
        gridViewHeight: DateTimePickerDefaults.gridViewHeight,
        markerSize: DateTimePickerDefaults.markerSize,
        markerSpacing: DateTimePickerDefaults.markerSpacing,
        maxMarkers: DateTimePickerDefaults.maxMarkers,
        additionalDayColor: DateTimePickerDefaults.additionalDayColor,
        overlayRadius: 16,
        overlayElevation: DateTimePickerDefaults.overlayElevation,
        overlayGap: 8,
        overlayMaxHeight: DateTimePickerDefaults.overlayMaxHeight,
        overlayMinHeight: DateTimePickerDefaults.overlayMinHeight,
        overlayScreenMargin: DateTimePickerDefaults.overlayScreenMargin,
        overlayShadowColor: DateTimePickerDefaults.overlayShadowColor,
        overlayMatchTriggerWidth: true,
        showOutsideDays: false,
        showTodayHighlight: true,
        enableHaptic: true,
        enableDragSelect: true,
        enableSwipeMonths: true,
        enableEdgeScroll: true,
        overlayDuration: DateTimePickerDefaults.overlayDuration,
        viewSwitchDuration: DateTimePickerDefaults.viewSwitchDuration,
        pageDuration: DateTimePickerDefaults.pageDuration,
        timeLayout: TimePickerLayout.wheels,
        rangeLayout: RangePickerLayout.dialog,
        dialSize: DateTimePickerDefaults.dialSize,
        dialFaceColor: Color(0x141565C0),
        calendar: PickerCalendar.gregorian,
        focusRingColor: Color(0xFF1565C0),
        showWeekNumbers: false,
        monthFlow: MonthFlow.paged,
        monthPeek: DateTimePickerDefaults.monthPeek,
        neighbourOpacity: DateTimePickerDefaults.neighbourOpacity,
        edgeFadeSize: DateTimePickerDefaults.edgeFadeSize,
      );

  /// The day cell's corner, as a shape.
  BorderRadius get dayBorderRadius => BorderRadius.circular(dayRadius);

  /// How this bag's calendar counts months and days.
  PickerCalendarSystem get calendarSystem => calendar.system;

  /// One calendar row: the cell plus the margin above and below it.
  double get rowExtent => dayCellSize + dayCellMargin * 2;
}
