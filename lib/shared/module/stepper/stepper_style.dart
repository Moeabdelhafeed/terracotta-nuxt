import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../../core/animations/animation_presets.dart';
import 'stepper_models.dart';

// ---------------------------------------------------------------------------
// Defaults — every hard-coded number the stepper draws with
// ---------------------------------------------------------------------------

/// The compile-time floor under [StepperStyle].
///
/// Sizes a token can express are NOT here — they come from
/// `MyGlobalStepperTheme.build`, which reads `AppTokens` and so tracks
/// the window bucket. What is here is what a token cannot say: the
/// geometry the layouts need, and the opacities.
abstract final class StepperDefaults {
  // ─── Indicator ────────────────────────────────────────────
  static const indicatorSize = 32.0;
  static const indicatorBorderWidth = 2.0;

  /// How much bigger the ACTIVE indicator is drawn.
  ///
  /// Every layout reserves `indicatorSize * activeScale` for the
  /// indicator column, so the row does not jump as the active step
  /// moves through it.
  static const activeIndicatorScale = 1.12;

  static const indicatorFontSize = 12.0;
  static const indicatorIconSize = 16.0;
  static const checkmarkSize = 15.0;
  static const errorIconSize = 15.0;

  static const indicatorShadowBlur = 8.0;
  static const indicatorShadowOpacity = 0.3;

  // ─── Connector ────────────────────────────────────────────
  static const connectorThickness = 2.0;
  static const connectorDashWidth = 4.0;
  static const connectorDashGap = 3.0;
  static const connectorLabelFontSize = 9.0;

  /// What a connector leaves BEYOND the indicator's resting edge.
  ///
  /// Nothing: the line meets the circle. The ACTIVE circle is drawn
  /// larger and covers the last two points of it, which is what makes
  /// the run read as one line with a bead on it rather than a row of
  /// separate dashes.
  ///
  /// Positive opens a gap; negative tucks the line under the
  /// indicators — `-indicatorSize / 2` puts it back to centre-to-centre,
  /// which is what a translucent custom indicator must NOT have.
  static const connectorInset = 0.0;

  /// The halo that lifts a connector label off the line it sits on.
  static const connectorLabelStroke = 4.0;

  /// What a connector's TRACK keeps of an explicitly-set connector
  /// colour — the unfilled part of a line the caller has coloured.
  static const connectorTrackOpacity = 0.2;

  // ─── Type ─────────────────────────────────────────────────
  static const titleFontSize = 13.0;
  static const subtitleFontSize = 11.0;
  static const timestampFontSize = 11.0;
  static const subtitleOpacity = 0.5;
  static const timestampOpacity = 0.45;

  /// What an untouched step's colour is, against the page.
  static const inactiveOpacity = 0.3;

  /// And a step nobody may reach.
  static const disabledColorOpacity = 0.15;
  static const disabledOpacity = 0.4;

  // ─── Layout ───────────────────────────────────────────────
  /// Between the indicator row and the titles under it.
  static const horizontalTitleGap = 10.0;

  /// Between the indicator column and the content beside it.
  static const verticalIndicatorGap = 14.0;

  static const contentPadTop = 10.0;
  static const contentPadBottom = 22.0;
  static const actionsPadTop = 14.0;
  static const subtitleGap = 2.0;
  static const actionsGap = 8.0;

  /// What a COLLAPSED step leaves between itself and the next one.
  static const collapsedGap = 8.0;

  /// The timestamp gutter in timeline mode.
  static const timelineTimestampWidth = 72.0;

  static const scrollableStepWidth = 120.0;

  /// The width the connector label's own box reserves in a vertical
  /// run, centred on the line.
  static const verticalLabelWidth = 40.0;

  // ─── Focus ────────────────────────────────────────────────
  /// The ring a KEYBOARD puts around the step it is on.
  ///
  /// It sits OUTSIDE the indicator rather than on its border, so a
  /// filled indicator and an outlined one show the same ring.
  static const focusRingWidth = 2.0;
  static const focusRingGap = 3.0;

  // ─── Motion ───────────────────────────────────────────────
  static const animationDuration = AppDurations.normal;

  /// How much of a connector's fill has run before the NEXT one in a
  /// multi-step jump starts. Near-continuous, rather than a queue of
  /// separate animations.
  static const sequentialOverlap = 0.75;
}

// ---------------------------------------------------------------------------
// The bag
// ---------------------------------------------------------------------------

/// Every knob [GlobalStepper] has, all of it optional.
///
/// Resolution order is `caller > GlobalStepperTheme.style >
/// StepperStyle.defaults`, and colours come from the palette at build
/// time rather than from `Theme.of(context).colorScheme` — a rebrand
/// used to move the app and leave the stepper where it was.
@immutable
class StepperStyle {
  const StepperStyle({
    this.activeColor,
    this.completedColor,
    this.inactiveColor,
    this.errorColor,
    this.disabledColor,
    this.surfaceColor,
    this.indicatorSize,
    this.indicatorBorderWidth,
    this.indicatorGradient,
    this.indicatorTextStyle,
    this.filledIndicator,
    this.showCheckmark,
    this.showStepNumber,
    this.connectorStyle,
    this.connectorThickness,
    this.connectorColor,
    this.connectorGradient,
    this.connectorInset,
    this.connectorDashWidth,
    this.connectorDashGap,
    this.connectorProgress,
    this.connectorLabelStyle,
    this.connectorBuilder,
    this.titleStyle,
    this.activeTitleStyle,
    this.subtitleStyle,
    this.timestampStyle,
    this.animated,
    this.animationDuration,
    this.sequentialAnimation,
    this.contentTransition,
    this.spacing,
    this.contentPadding,
    this.collapsible,
    this.scrollable,
    this.scrollableStepWidth,
    this.focusColor,
    this.focusRingWidth,
    this.enableHaptic,
    this.disabledOpacity,
  });

  // ─── Colours ──────────────────────────────────────────────
  /// The step the reader is ON.
  final Color? activeColor;

  /// The steps behind it.
  final Color? completedColor;

  /// The steps ahead of it.
  final Color? inactiveColor;

  final Color? errorColor;
  final Color? disabledColor;

  /// What the indicator's INTERIOR is painted with, and what a
  /// connector label strokes itself against.
  ///
  /// It is the page, not the card: the connector line runs BEHIND the
  /// indicator, and an interior that does not match what is behind it
  /// shows the line through the middle of the circle.
  final Color? surfaceColor;

  // ─── Indicator ────────────────────────────────────────────
  final double? indicatorSize;
  final double? indicatorBorderWidth;

  /// A gradient BORDER, drawn as a ring around the interior — not a
  /// fill. Ignored when [filledIndicator] has already claimed the
  /// circle.
  final Gradient? indicatorGradient;

  /// The number inside the circle.
  final TextStyle? indicatorTextStyle;

  /// Fill the circle instead of outlining it.
  final bool? filledIndicator;

  /// Whether a completed step swaps its number for a tick.
  final bool? showCheckmark;

  /// Whether an untouched step shows its number at all.
  final bool? showStepNumber;

  // ─── Connector ────────────────────────────────────────────
  final StepperConnectorStyle? connectorStyle;
  final double? connectorThickness;

  /// Colours the connector INDEPENDENTLY of the steps it joins — the
  /// filled part takes this, the unfilled part takes it at
  /// [StepperDefaults.connectorTrackOpacity].
  final Color? connectorColor;

  final Gradient? connectorGradient;

  /// The room a connector leaves beyond each indicator's resting edge.
  /// See [StepperDefaults.connectorInset].
  final double? connectorInset;

  final double? connectorDashWidth;
  final double? connectorDashGap;

  /// Per-connector fill, by the index of the step BEFORE it.
  ///
  /// For a stepper that is reporting something continuous — an upload,
  /// a delivery — rather than a step someone is standing on.
  final Map<int, double>? connectorProgress;

  final TextStyle? connectorLabelStyle;

  /// Replaces the line entirely. Gets the index, the fill, and both
  /// colours; the result is clipped along the run's axis.
  final Widget Function(
    BuildContext context,
    int index,
    double progress,
    Color activeColor,
    Color trackColor,
  )?
  connectorBuilder;

  // ─── Type ─────────────────────────────────────────────────
  final TextStyle? titleStyle;
  final TextStyle? activeTitleStyle;
  final TextStyle? subtitleStyle;

  /// The timeline's left gutter.
  final TextStyle? timestampStyle;

  // ─── Motion ───────────────────────────────────────────────
  final bool? animated;
  final Duration? animationDuration;

  /// Whether a jump of more than one step fills its connectors in
  /// order rather than all at once.
  final bool? sequentialAnimation;

  final StepContentTransition? contentTransition;

  // ─── Layout ───────────────────────────────────────────────
  /// EXTRA room between steps, on top of what the layout already
  /// leaves.
  final double? spacing;

  final EdgeInsets? contentPadding;

  /// Whether a completed step folds its subtitle and content away.
  final bool? collapsible;

  /// Whether a horizontal run scrolls instead of squeezing.
  final bool? scrollable;

  final double? scrollableStepWidth;

  // ─── Focus ────────────────────────────────────────────────
  final Color? focusColor;
  final double? focusRingWidth;

  // ─── Behaviour ────────────────────────────────────────────
  final bool? enableHaptic;
  final double? disabledOpacity;

  /// Nothing answered. The floor lives in [StepperDefaults] and the
  /// colours in `resolve`, so an empty bag is the whole default look.
  static const StepperStyle defaults = StepperStyle();

  /// No circles to speak of: a thin run of dots, for a stepper that is
  /// a position report rather than a control.
  static const StepperStyle bare = StepperStyle(
    indicatorSize: 12,
    showStepNumber: false,
    showCheckmark: false,
    filledIndicator: true,
    connectorThickness: 1,
  );

  /// Solid circles, a heavier line — the checkout look.
  static const StepperStyle prominent = StepperStyle(
    filledIndicator: true,
    connectorThickness: 3,
  );

  /// `other` wins field by field; `null` on `other` keeps ours.
  StepperStyle mergedWith(StepperStyle? other) {
    if (other == null) return this;
    return StepperStyle(
      activeColor: other.activeColor ?? activeColor,
      completedColor: other.completedColor ?? completedColor,
      inactiveColor: other.inactiveColor ?? inactiveColor,
      errorColor: other.errorColor ?? errorColor,
      disabledColor: other.disabledColor ?? disabledColor,
      surfaceColor: other.surfaceColor ?? surfaceColor,
      indicatorSize: other.indicatorSize ?? indicatorSize,
      indicatorBorderWidth: other.indicatorBorderWidth ?? indicatorBorderWidth,
      indicatorGradient: other.indicatorGradient ?? indicatorGradient,
      indicatorTextStyle: other.indicatorTextStyle ?? indicatorTextStyle,
      filledIndicator: other.filledIndicator ?? filledIndicator,
      showCheckmark: other.showCheckmark ?? showCheckmark,
      showStepNumber: other.showStepNumber ?? showStepNumber,
      connectorStyle: other.connectorStyle ?? connectorStyle,
      connectorThickness: other.connectorThickness ?? connectorThickness,
      connectorColor: other.connectorColor ?? connectorColor,
      connectorGradient: other.connectorGradient ?? connectorGradient,
      connectorInset: other.connectorInset ?? connectorInset,
      connectorDashWidth: other.connectorDashWidth ?? connectorDashWidth,
      connectorDashGap: other.connectorDashGap ?? connectorDashGap,
      connectorProgress: other.connectorProgress ?? connectorProgress,
      connectorLabelStyle: other.connectorLabelStyle ?? connectorLabelStyle,
      connectorBuilder: other.connectorBuilder ?? connectorBuilder,
      titleStyle: other.titleStyle ?? titleStyle,
      activeTitleStyle: other.activeTitleStyle ?? activeTitleStyle,
      subtitleStyle: other.subtitleStyle ?? subtitleStyle,
      timestampStyle: other.timestampStyle ?? timestampStyle,
      animated: other.animated ?? animated,
      animationDuration: other.animationDuration ?? animationDuration,
      sequentialAnimation: other.sequentialAnimation ?? sequentialAnimation,
      contentTransition: other.contentTransition ?? contentTransition,
      spacing: other.spacing ?? spacing,
      contentPadding: other.contentPadding ?? contentPadding,
      collapsible: other.collapsible ?? collapsible,
      scrollable: other.scrollable ?? scrollable,
      scrollableStepWidth: other.scrollableStepWidth ?? scrollableStepWidth,
      focusColor: other.focusColor ?? focusColor,
      focusRingWidth: other.focusRingWidth ?? focusRingWidth,
      enableHaptic: other.enableHaptic ?? enableHaptic,
      disabledOpacity: other.disabledOpacity ?? disabledOpacity,
    );
  }

  StepperStyle copyWith({
    Color? activeColor,
    Color? completedColor,
    Color? inactiveColor,
    Color? errorColor,
    Color? disabledColor,
    Color? surfaceColor,
    double? indicatorSize,
    double? indicatorBorderWidth,
    Gradient? indicatorGradient,
    TextStyle? indicatorTextStyle,
    bool? filledIndicator,
    bool? showCheckmark,
    bool? showStepNumber,
    StepperConnectorStyle? connectorStyle,
    double? connectorThickness,
    Color? connectorColor,
    Gradient? connectorGradient,
    double? connectorInset,
    double? connectorDashWidth,
    double? connectorDashGap,
    Map<int, double>? connectorProgress,
    TextStyle? connectorLabelStyle,
    Widget Function(
      BuildContext context,
      int index,
      double progress,
      Color activeColor,
      Color trackColor,
    )?
    connectorBuilder,
    TextStyle? titleStyle,
    TextStyle? activeTitleStyle,
    TextStyle? subtitleStyle,
    TextStyle? timestampStyle,
    bool? animated,
    Duration? animationDuration,
    bool? sequentialAnimation,
    StepContentTransition? contentTransition,
    double? spacing,
    EdgeInsets? contentPadding,
    bool? collapsible,
    bool? scrollable,
    double? scrollableStepWidth,
    Color? focusColor,
    double? focusRingWidth,
    bool? enableHaptic,
    double? disabledOpacity,
  }) => StepperStyle(
    activeColor: activeColor ?? this.activeColor,
    completedColor: completedColor ?? this.completedColor,
    inactiveColor: inactiveColor ?? this.inactiveColor,
    errorColor: errorColor ?? this.errorColor,
    disabledColor: disabledColor ?? this.disabledColor,
    surfaceColor: surfaceColor ?? this.surfaceColor,
    indicatorSize: indicatorSize ?? this.indicatorSize,
    indicatorBorderWidth: indicatorBorderWidth ?? this.indicatorBorderWidth,
    indicatorGradient: indicatorGradient ?? this.indicatorGradient,
    indicatorTextStyle: indicatorTextStyle ?? this.indicatorTextStyle,
    filledIndicator: filledIndicator ?? this.filledIndicator,
    showCheckmark: showCheckmark ?? this.showCheckmark,
    showStepNumber: showStepNumber ?? this.showStepNumber,
    connectorStyle: connectorStyle ?? this.connectorStyle,
    connectorThickness: connectorThickness ?? this.connectorThickness,
    connectorColor: connectorColor ?? this.connectorColor,
    connectorGradient: connectorGradient ?? this.connectorGradient,
    connectorInset: connectorInset ?? this.connectorInset,
    connectorDashWidth: connectorDashWidth ?? this.connectorDashWidth,
    connectorDashGap: connectorDashGap ?? this.connectorDashGap,
    connectorProgress: connectorProgress ?? this.connectorProgress,
    connectorLabelStyle: connectorLabelStyle ?? this.connectorLabelStyle,
    connectorBuilder: connectorBuilder ?? this.connectorBuilder,
    titleStyle: titleStyle ?? this.titleStyle,
    activeTitleStyle: activeTitleStyle ?? this.activeTitleStyle,
    subtitleStyle: subtitleStyle ?? this.subtitleStyle,
    timestampStyle: timestampStyle ?? this.timestampStyle,
    animated: animated ?? this.animated,
    animationDuration: animationDuration ?? this.animationDuration,
    sequentialAnimation: sequentialAnimation ?? this.sequentialAnimation,
    contentTransition: contentTransition ?? this.contentTransition,
    spacing: spacing ?? this.spacing,
    contentPadding: contentPadding ?? this.contentPadding,
    collapsible: collapsible ?? this.collapsible,
    scrollable: scrollable ?? this.scrollable,
    scrollableStepWidth: scrollableStepWidth ?? this.scrollableStepWidth,
    focusColor: focusColor ?? this.focusColor,
    focusRingWidth: focusRingWidth ?? this.focusRingWidth,
    enableHaptic: enableHaptic ?? this.enableHaptic,
    disabledOpacity: disabledOpacity ?? this.disabledOpacity,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is StepperStyle &&
          other.activeColor == activeColor &&
          other.completedColor == completedColor &&
          other.inactiveColor == inactiveColor &&
          other.errorColor == errorColor &&
          other.disabledColor == disabledColor &&
          other.surfaceColor == surfaceColor &&
          other.indicatorSize == indicatorSize &&
          other.indicatorBorderWidth == indicatorBorderWidth &&
          other.indicatorGradient == indicatorGradient &&
          other.indicatorTextStyle == indicatorTextStyle &&
          other.filledIndicator == filledIndicator &&
          other.showCheckmark == showCheckmark &&
          other.showStepNumber == showStepNumber &&
          other.connectorStyle == connectorStyle &&
          other.connectorThickness == connectorThickness &&
          other.connectorColor == connectorColor &&
          other.connectorGradient == connectorGradient &&
          other.connectorInset == connectorInset &&
          other.connectorDashWidth == connectorDashWidth &&
          other.connectorDashGap == connectorDashGap &&
          mapEquals(other.connectorProgress, connectorProgress) &&
          other.connectorLabelStyle == connectorLabelStyle &&
          other.connectorBuilder == connectorBuilder &&
          other.titleStyle == titleStyle &&
          other.activeTitleStyle == activeTitleStyle &&
          other.subtitleStyle == subtitleStyle &&
          other.timestampStyle == timestampStyle &&
          other.animated == animated &&
          other.animationDuration == animationDuration &&
          other.sequentialAnimation == sequentialAnimation &&
          other.contentTransition == contentTransition &&
          other.spacing == spacing &&
          other.contentPadding == contentPadding &&
          other.collapsible == collapsible &&
          other.scrollable == scrollable &&
          other.scrollableStepWidth == scrollableStepWidth &&
          other.focusColor == focusColor &&
          other.focusRingWidth == focusRingWidth &&
          other.enableHaptic == enableHaptic &&
          other.disabledOpacity == disabledOpacity;

  @override
  int get hashCode => Object.hashAll([
    activeColor,
    completedColor,
    inactiveColor,
    errorColor,
    disabledColor,
    surfaceColor,
    indicatorSize,
    indicatorBorderWidth,
    indicatorGradient,
    indicatorTextStyle,
    filledIndicator,
    showCheckmark,
    showStepNumber,
    connectorStyle,
    connectorThickness,
    connectorColor,
    connectorGradient,
    connectorInset,
    connectorDashWidth,
    connectorDashGap,
    connectorLabelStyle,
    connectorBuilder,
    titleStyle,
    activeTitleStyle,
    subtitleStyle,
    timestampStyle,
    animated,
    animationDuration,
    sequentialAnimation,
    contentTransition,
    spacing,
    contentPadding,
    collapsible,
    scrollable,
    scrollableStepWidth,
    focusColor,
    focusRingWidth,
    enableHaptic,
    disabledOpacity,
  ]);
}

// ---------------------------------------------------------------------------
// The bag with every question answered
// ---------------------------------------------------------------------------

/// What [GlobalStepper] actually draws with.
///
/// Produced by `StepperStyle.resolve(context)`. Nothing here is
/// nullable except what is genuinely optional — a gradient, a custom
/// connector, an explicit per-connector fill.
@immutable
class ResolvedStepperStyle {
  const ResolvedStepperStyle({
    required this.activeColor,
    required this.completedColor,
    required this.inactiveColor,
    required this.errorColor,
    required this.disabledColor,
    required this.surfaceColor,
    required this.indicatorSize,
    required this.indicatorBorderWidth,
    this.indicatorGradient,
    required this.indicatorTextStyle,
    required this.filledIndicator,
    required this.showCheckmark,
    required this.showStepNumber,
    required this.connectorStyle,
    required this.connectorThickness,
    this.connectorColor,
    this.connectorGradient,
    required this.connectorInset,
    required this.connectorDashWidth,
    required this.connectorDashGap,
    this.connectorProgress,
    required this.connectorLabelStyle,
    this.connectorBuilder,
    required this.titleStyle,
    required this.activeTitleStyle,
    required this.subtitleStyle,
    required this.timestampStyle,
    required this.animated,
    required this.animationDuration,
    required this.sequentialAnimation,
    required this.contentTransition,
    required this.spacing,
    required this.contentPadding,
    required this.collapsible,
    required this.scrollable,
    required this.scrollableStepWidth,
    required this.focusColor,
    required this.focusRingWidth,
    required this.enableHaptic,
    required this.disabledOpacity,
  });

  final Color activeColor;
  final Color completedColor;
  final Color inactiveColor;
  final Color errorColor;
  final Color disabledColor;
  final Color surfaceColor;

  final double indicatorSize;
  final double indicatorBorderWidth;
  final Gradient? indicatorGradient;
  final TextStyle indicatorTextStyle;
  final bool filledIndicator;
  final bool showCheckmark;
  final bool showStepNumber;

  final StepperConnectorStyle connectorStyle;
  final double connectorThickness;

  /// Still nullable AFTER resolution: "unset" is a real answer here —
  /// it means the connector takes the colour of the steps it joins,
  /// which changes per connector and so cannot be one colour.
  final Color? connectorColor;

  final Gradient? connectorGradient;
  final double connectorInset;
  final double connectorDashWidth;
  final double connectorDashGap;
  final Map<int, double>? connectorProgress;
  final TextStyle connectorLabelStyle;
  final Widget Function(
    BuildContext context,
    int index,
    double progress,
    Color activeColor,
    Color trackColor,
  )?
  connectorBuilder;

  final TextStyle titleStyle;
  final TextStyle activeTitleStyle;
  final TextStyle subtitleStyle;
  final TextStyle timestampStyle;

  final bool animated;
  final Duration animationDuration;
  final bool sequentialAnimation;
  final StepContentTransition contentTransition;

  final double spacing;
  final EdgeInsets contentPadding;
  final bool collapsible;
  final bool scrollable;
  final double scrollableStepWidth;

  final Color focusColor;
  final double focusRingWidth;

  final bool enableHaptic;
  final double disabledOpacity;

  /// The room every layout reserves for an indicator — the resting
  /// size plus what the active one grows by.
  double get indicatorExtent =>
      indicatorSize * StepperDefaults.activeIndicatorScale;

  /// How far a connector starts from the CENTRE of an indicator: its
  /// resting radius, plus whatever gap was asked for.
  double get connectorStart => indicatorSize / 2 + connectorInset;

  /// And how far down a vertical run — measured from the TOP of the
  /// indicator rather than its centre.
  double get connectorTop => indicatorSize + connectorInset;

  /// Zero when the caller asked for no motion, so every
  /// `AnimatedFoo` in the tree becomes an instant one.
  Duration get effectiveDuration =>
      animated ? animationDuration : Duration.zero;
}
