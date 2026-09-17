import 'package:flutter/material.dart';

import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/extensions/theme_colors_extension.dart';
import '../../../../core/tokens/extensions.dart';
import '../date_time_picker_models.dart';
import '../date_time_picker_style.dart';
import '../picker_calendar_system.dart';

/// App-wide defaults for every picker in `date_time_picker/`.
///
/// The rebrand hook: set the day cell's shape, the panel's corner and
/// what the wheels are made of once, here, and the wheel picker, the
/// range picker, the inline calendar and all four overlays follow.
///
/// One extension for the whole family rather than one each, because
/// they are one surface seen four ways — a calendar inside an overlay
/// inside a range picker has to agree with the calendar beside it, and
/// three bags could not.
@immutable
class GlobalDateTimePickerTheme
    extends ThemeExtension<GlobalDateTimePickerTheme> {
  const GlobalDateTimePickerTheme({this.style});

  final DateTimePickerStyle? style;

  static GlobalDateTimePickerTheme? maybeOf(BuildContext context) =>
      Theme.of(context).extension<GlobalDateTimePickerTheme>();

  @override
  GlobalDateTimePickerTheme copyWith({DateTimePickerStyle? style}) =>
      GlobalDateTimePickerTheme(style: style ?? this.style);

  @override
  GlobalDateTimePickerTheme lerp(
    ThemeExtension<GlobalDateTimePickerTheme>? other,
    double t,
  ) {
    if (other is! GlobalDateTimePickerTheme) return this;
    // A style is a bag of independent decisions, not a value with a
    // midpoint — half a `showOutsideDays` means nothing. It SNAPS at
    // the halfway mark, which is what every other bag in this app does.
    return t < 0.5 ? this : other;
  }
}

/// Turns a caller's bag into one with every question answered.
extension DateTimePickerStyleResolve on DateTimePickerStyle {
  /// `caller > GlobalDateTimePickerTheme.style >
  /// DateTimePickerStyle.defaults`, then the colours from the palette.
  ///
  /// Colours resolve HERE and not in `defaults`, because a constant
  /// cannot track role, brightness or saturation — and this module drew
  /// three of them (`Colors.white` on a selected day, `Colors.grey` in
  /// the panel shadow, `Colors.black26` under the overlay) that a
  /// light-primary brand made unreadable.
  ResolvedDateTimePickerStyle resolve(BuildContext context) {
    final merged = DateTimePickerStyle.defaults
        .mergedWith(GlobalDateTimePickerTheme.maybeOf(context)?.style)
        .mergedWith(this);

    final primary = context.primaryColors.primary;
    final text = context.textColors;
    final bg = context.backgroundColors;
    final spacing = context.spacing;
    final radii = context.radii;
    final textTheme = context.textTheme;

    final dayShape = merged.dayShape ?? BoxShape.rectangle;

    return ResolvedDateTimePickerStyle(
      // ─── Surface ───────────────────────────────────────────
      surfaceColor: merged.surfaceColor ?? bg.container,
      radius: merged.radius ?? radii.lg,
      borderColor: merged.borderColor ?? bg.outline.withValues(alpha: 0.2),
      borderWidth:
          merged.borderWidth ?? DateTimePickerDefaults.triggerBorderWidth,
      shadow:
          merged.shadow ??
          <BoxShadow>[
            BoxShadow(
              color: bg.outline.withValues(alpha: 0.1),
              blurRadius: 20,
            ),
          ],

      // ─── Trigger ───────────────────────────────────────────
      triggerPadding:
          merged.triggerPadding ??
          EdgeInsetsDirectional.symmetric(
            horizontal: spacing.md,
            vertical: spacing.sm,
          ),
      triggerRadius: merged.triggerRadius ?? radii.md,
      triggerIconSize:
          merged.triggerIconSize ?? DateTimePickerDefaults.triggerIconSize,
      triggerGap: merged.triggerGap ?? spacing.sm,
      triggerFillColor: merged.triggerFillColor ?? bg.inputBackground,
      triggerBorderColor:
          merged.triggerBorderColor ?? bg.outline.withValues(alpha: 0.3),
      triggerActiveBorderColor: merged.triggerActiveBorderColor ?? primary,
      triggerBorderWidth:
          merged.triggerBorderWidth ??
          DateTimePickerDefaults.triggerBorderWidth,
      triggerTextStyle:
          merged.triggerTextStyle ??
          (textTheme.bodyMedium ?? const TextStyle()).copyWith(
            color: text.primary,
          ),
      triggerHintColor: merged.triggerHintColor ?? text.disabled,
      triggerIconColor: merged.triggerIconColor ?? context.iconColors.secondary,

      // ─── Wheels ────────────────────────────────────────────
      wheelItemExtent:
          merged.wheelItemExtent ?? DateTimePickerDefaults.wheelItemExtent,
      wheelMagnification:
          merged.wheelMagnification ??
          DateTimePickerDefaults.wheelMagnification,
      wheelSqueeze: merged.wheelSqueeze ?? DateTimePickerDefaults.wheelSqueeze,
      wheelMagnifier: merged.wheelMagnifier ?? true,
      wheelHeight: merged.wheelHeight ?? DateTimePickerDefaults.wheelHeight,
      wheelTextStyle:
          merged.wheelTextStyle ??
          (textTheme.bodyLarge ?? const TextStyle()).copyWith(
            color: text.primary,
            // Digits that do not shift the row as they change. A
            // proportional `1` is narrower than a `0`, and a wheel of
            // times jittered horizontally while it spun.
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
      wheelSeparatorStyle:
          merged.wheelSeparatorStyle ??
          (textTheme.headlineSmall ?? const TextStyle()).copyWith(
            fontWeight: FontWeight.bold,
            color: text.secondary,
          ),
      wheelSeparatorGap: merged.wheelSeparatorGap ?? spacing.sm,
      wheelSelectionColor:
          merged.wheelSelectionColor ?? primary.withValues(alpha: 0.08),

      // ─── Wheel header ──────────────────────────────────────
      headerPadding: merged.headerPadding ?? spacing.sm,
      headerHeight: merged.headerHeight ?? DateTimePickerDefaults.headerHeight,
      headerTitleStyle:
          merged.headerTitleStyle ??
          (textTheme.titleSmall ?? const TextStyle()).copyWith(
            fontWeight: FontWeight.w600,
            color: text.primary,
          ),

      // ─── Calendar ──────────────────────────────────────────
      dayCellSize: merged.dayCellSize ?? DateTimePickerDefaults.dayCellSize,
      dayCellMargin:
          merged.dayCellMargin ?? DateTimePickerDefaults.dayCellMargin,
      dayRadius: merged.dayRadius ?? radii.lg,
      dayShape: dayShape,
      dayFontSize: merged.dayFontSize ?? DateTimePickerDefaults.dayFontSize,
      dayFontWeight: merged.dayFontWeight ?? FontWeight.w400,
      dayTextColor: merged.dayTextColor ?? text.primary,
      selectedDayColor: merged.selectedDayColor ?? primary,
      // NOT `Colors.white`: the palette knows what reads on the accent,
      // and a yellow or lime brand does not answer white.
      selectedDayTextColor: merged.selectedDayTextColor ?? text.onPrimary,
      selectedDayShape: merged.selectedDayShape ?? dayShape,
      selectedDayFontWeight: merged.selectedDayFontWeight ?? FontWeight.w600,
      selectedGradient: merged.selectedGradient,
      rangeFillColor:
          merged.rangeFillColor ??
          primary.withValues(alpha: DateTimePickerDefaults.rangeFillOpacity),
      rangeTextColor: merged.rangeTextColor ?? text.primary,
      todayBorderColor: merged.todayBorderColor ?? primary,
      todayBorderWidth:
          merged.todayBorderWidth ?? DateTimePickerDefaults.todayBorderWidth,
      todayTextColor: merged.todayTextColor ?? primary,
      todayShape: merged.todayShape ?? dayShape,
      todayFontWeight: merged.todayFontWeight ?? FontWeight.w700,
      disabledDayOpacity:
          merged.disabledDayOpacity ??
          DateTimePickerDefaults.disabledDayOpacity,
      outsideDayOpacity:
          merged.outsideDayOpacity ?? DateTimePickerDefaults.outsideDayOpacity,
      weekdayLabelFontSize:
          merged.weekdayLabelFontSize ??
          DateTimePickerDefaults.weekdayLabelFontSize,
      weekdayLabelColor:
          merged.weekdayLabelColor ??
          text.primary.withValues(
            alpha: DateTimePickerDefaults.weekdayLabelOpacity,
          ),
      calendarHeaderFontSize:
          merged.calendarHeaderFontSize ??
          DateTimePickerDefaults.calendarHeaderFontSize,
      calendarHeaderFontWeight:
          merged.calendarHeaderFontWeight ?? FontWeight.w700,
      arrowIconSize:
          merged.arrowIconSize ?? DateTimePickerDefaults.arrowIconSize,
      arrowColor: merged.arrowColor ?? primary,
      gridCellRadius: merged.gridCellRadius ?? radii.md,
      gridViewHeight:
          merged.gridViewHeight ?? DateTimePickerDefaults.gridViewHeight,
      markerSize: merged.markerSize ?? DateTimePickerDefaults.markerSize,
      markerSpacing:
          merged.markerSpacing ?? DateTimePickerDefaults.markerSpacing,
      maxMarkers: merged.maxMarkers ?? DateTimePickerDefaults.maxMarkers,
      additionalDayColor:
          merged.additionalDayColor ??
          DateTimePickerDefaults.additionalDayColor,

      // ─── Overlay ───────────────────────────────────────────
      overlayRadius: merged.overlayRadius ?? radii.lg,
      overlayElevation:
          merged.overlayElevation ?? DateTimePickerDefaults.overlayElevation,
      overlayGap: merged.overlayGap ?? spacing.sm,
      overlayMaxHeight:
          merged.overlayMaxHeight ?? DateTimePickerDefaults.overlayMaxHeight,
      overlayMinHeight:
          merged.overlayMinHeight ?? DateTimePickerDefaults.overlayMinHeight,
      overlayScreenMargin:
          merged.overlayScreenMargin ??
          DateTimePickerDefaults.overlayScreenMargin,
      overlayShadowColor:
          merged.overlayShadowColor ??
          DateTimePickerDefaults.overlayShadowColor,
      overlayMatchTriggerWidth: merged.overlayMatchTriggerWidth ?? true,

      // ─── Behaviour ─────────────────────────────────────────
      showOutsideDays: merged.showOutsideDays ?? false,
      showTodayHighlight: merged.showTodayHighlight ?? true,
      enableHaptic: merged.enableHaptic ?? true,
      enableDragSelect: merged.enableDragSelect ?? true,
      enableSwipeMonths: merged.enableSwipeMonths ?? true,
      enableEdgeScroll: merged.enableEdgeScroll ?? true,

      // ─── Layout ────────────────────────────────────────────
      timeLayout: merged.timeLayout ?? TimePickerLayout.wheels,
      rangeLayout: merged.rangeLayout ?? RangePickerLayout.dialog,
      dialSize: merged.dialSize ?? DateTimePickerDefaults.dialSize,
      dialFaceColor: merged.dialFaceColor ?? primary.withValues(alpha: 0.08),
      calendar: merged.calendar ?? PickerCalendar.gregorian,
      focusRingColor: merged.focusRingColor ?? primary,
      showWeekNumbers: merged.showWeekNumbers ?? false,
      monthFlow: merged.monthFlow ?? MonthFlow.paged,
      monthPeek: merged.monthPeek ?? DateTimePickerDefaults.monthPeek,
      neighbourOpacity:
          merged.neighbourOpacity ?? DateTimePickerDefaults.neighbourOpacity,
      edgeFadeSize: merged.edgeFadeSize ?? DateTimePickerDefaults.edgeFadeSize,

      // ─── Motion ────────────────────────────────────────────
      overlayDuration:
          merged.overlayDuration ?? DateTimePickerDefaults.overlayDuration,
      viewSwitchDuration:
          merged.viewSwitchDuration ??
          DateTimePickerDefaults.viewSwitchDuration,
      pageDuration: merged.pageDuration ?? DateTimePickerDefaults.pageDuration,
    );
  }
}
