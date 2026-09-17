import 'package:flutter/material.dart';

import '../../../core/animations/animation_presets.dart';

// ---------------------------------------------------------------------------
// Constants
// ---------------------------------------------------------------------------

/// Geometry and tolerances that only change when this module changes.
/// Anything an app would rebrand lives on [RatingStyle] instead.
abstract final class RatingDefaults {
  static const size = 28.0;
  static const spacing = 4.0;
  static const count = 5;
  static const animDuration = AppDurations.fast;

  /// How much of its colour a disabled row keeps.
  static const disabledOpacity = 0.5;

  static const countLabelSpacing = 8.0;

  /// Hover wash behind a star on pointer devices.
  static const hoverOpacity = 0.12;

  /// The focus ring. Stronger than Material's ~10% overlay for the same
  /// reason the tab bar's is: a row of stars on a transparent surface
  /// gives a faint wash nothing to read against.
  static const focusRingWidth = 2.0;
  static const focusRingOpacity = 0.9;

  /// Corner radius of the hover wash and the focus ring, as a FRACTION
  /// of the icon size — they have to track a star that can be 16dp or
  /// 64dp, and a fixed radius looks wrong at one end or the other.
  static const hoverRadiusFraction = 0.25;
  static const focusRadiusFraction = 0.33;

  /// Scale a star settles at when empty and when partly filled. Full
  /// stars stay at 1, so filling one is a small pop.
  static const emptyScale = 0.9;
  static const partialScale = 0.95;

  /// Overshoot of the star the user just picked, and how long it takes
  /// to go up and come back.
  static const popScale = 1.15;
  static const popDuration = AppDurations.quick;

  /// Share of the pop spent growing. The return is slower than the
  /// departure, which is what makes it read as a settle rather than a
  /// twitch.
  static const popRiseFraction = 40.0;
  static const popFallFraction = 60.0;

  /// Lift of the star under a dragging finger — the finger covers the
  /// stars it is choosing, so the target has to be legible around it.
  static const dragLiftScale = 1.12;

  /// Gap between one star's fill and the next when staggering.
  static const staggerStep = Duration(milliseconds: 45);

  /// Values closer than this count as equal. A rating is a coarse
  /// quantity; exact double comparison would fire callbacks on drift.
  static const epsilon = 0.01;
}

// ---------------------------------------------------------------------------
// RatingPrecision
// ---------------------------------------------------------------------------

/// Step the value snaps to.
enum RatingPrecision {
  /// Full steps only (1, 2, 3…).
  full(1),

  /// Half steps (0.5, 1.0, 1.5…).
  half(0.5),

  /// Quarter steps (0.25, 0.5, 0.75…).
  quarter(0.25);

  const RatingPrecision(this.step);

  /// Size of one step, which is also what a keyboard arrow moves.
  final double step;

  /// Snaps [raw] to the nearest step. For a value the user did not
  /// point at — a keyboard move, an incoming value.
  double snap(double raw) => (raw / step).roundToDouble() * step;

  /// Snaps [raw] UP to the next step.
  ///
  /// This is the one pointers use, and it is not the same question.
  /// Star three spans 2.0–3.0, so rounding a tap at 2.2 gives TWO stars
  /// — the user pressed the third star and watched the second one
  /// light. Ceiling gives the star under the finger, and at half
  /// precision it gives its left half then its right, which is what a
  /// half-star rating is for.
  double snapUp(double raw) => (raw / step).ceilToDouble() * step;
}

// ---------------------------------------------------------------------------
// RatingStyle
// ---------------------------------------------------------------------------

/// Themeable styling bag for `GlobalRating` — EVERY field nullable.
///
/// Resolution order, materialized once per build by `resolve`:
/// `caller > GlobalRatingTheme.style > RatingStyle.defaults > palette`.
///
/// Adding a themed field means touching five places: here, [mergedWith],
/// [copyWith], [ResolvedRatingStyle] and `GlobalRatingTheme.lerp`.
@immutable
class RatingStyle {
  const RatingStyle({
    this.size,
    this.spacing,
    this.ratedColor,
    this.unratedColor,
    this.halfRatedColor,
    this.disabledOpacity,
    this.ratedIcon,
    this.unratedIcon,
    this.halfRatedIcon,
    this.ratedWidget,
    this.unratedWidget,
    this.halfRatedWidget,
    this.ratedGradient,
    this.animationDuration,
    this.animationCurve,
    this.shadow,
    this.ratedShadow,
    this.enableHaptic,
    this.countLabelStyle,
    this.countLabelSpacing,
    this.hoverColor,
    this.focusColor,
    this.selectPop,
    this.selectPopScale,
    this.popDuration,
    this.fillCrossfade,
    this.dragLift,
    this.dragLiftScale,
    this.staggerFill,
    this.staggerClear,
    this.staggerStep,
  });

  /// Compile-time floor. Colours are deliberately absent: they resolve
  /// from `context.<group>Colors` at build time so a rating tracks role,
  /// brightness and saturation. `Colors.amber` used to be baked in here
  /// — the same yellow on every palette an app might ship.
  static const RatingStyle defaults = RatingStyle(
    size: RatingDefaults.size,
    spacing: RatingDefaults.spacing,
    disabledOpacity: RatingDefaults.disabledOpacity,
    ratedIcon: Icons.star_rounded,
    unratedIcon: Icons.star_border_rounded,
    halfRatedIcon: Icons.star_half_rounded,
    animationDuration: RatingDefaults.animDuration,
    animationCurve: Curves.easeOut,
    // TRUE, like every other interactive module. It defaulted to false,
    // so the app's own haptic preference never reached a star.
    enableHaptic: true,
    countLabelSpacing: RatingDefaults.countLabelSpacing,
    selectPop: true,
    selectPopScale: RatingDefaults.popScale,
    popDuration: RatingDefaults.popDuration,
    fillCrossfade: true,
    dragLift: true,
    dragLiftScale: RatingDefaults.dragLiftScale,
    // OFF. A stagger is a flourish for a "rate us" prompt; on a product
    // list it means fifty rows counting themselves up as you scroll.
    staggerFill: false,
    staggerClear: false,
    staggerStep: RatingDefaults.staggerStep,
  );

  /// Size of each icon.
  final double? size;

  /// Gap between icons.
  final double? spacing;

  /// Colour of rated (filled) icons.
  final Color? ratedColor;

  /// Colour of unrated (empty) icons.
  final Color? unratedColor;

  /// Colour of the partly-filled icon. Falls back to [ratedColor].
  final Color? halfRatedColor;

  /// How much colour a disabled row keeps.
  final double? disabledOpacity;

  final IconData? ratedIcon;
  final IconData? unratedIcon;
  final IconData? halfRatedIcon;

  /// Custom widget for the rated state. Outranks the icons.
  final Widget? ratedWidget;
  final Widget? unratedWidget;
  final Widget? halfRatedWidget;

  /// Gradient painted over rated icons via a `ShaderMask`.
  final Gradient? ratedGradient;

  final Duration? animationDuration;
  final Curve? animationCurve;

  /// Shadow under unrated icons.
  final List<BoxShadow>? shadow;

  /// Shadow under rated icons.
  final List<BoxShadow>? ratedShadow;

  /// Whether changing the value plays a haptic.
  final bool? enableHaptic;

  /// Type of the trailing count label.
  final TextStyle? countLabelStyle;

  /// Gap between the stars and the count label.
  final double? countLabelSpacing;

  /// Wash behind the star under the pointer.
  final Color? hoverColor;

  /// Focus ring colour.
  final Color? focusColor;

  /// Whether the star the USER just picked overshoots and settles.
  ///
  /// Only a user's own tap, drag or key press pops. A value arriving
  /// from outside settles quietly — otherwise a list of ratings pops
  /// every row as it scrolls into view.
  final bool? selectPop;

  /// How far that pop overshoots.
  final double? selectPopScale;

  /// How long it takes to go up and come back.
  final Duration? popDuration;

  /// Whether a star FILLS rather than swapping glyph. Off makes the
  /// rated icon appear on the frame the value lands.
  final bool? fillCrossfade;

  /// Whether the star under a dragging finger lifts.
  final bool? dragLift;

  /// How far it lifts.
  final double? dragLiftScale;

  /// Whether a rising value fills the stars one after another instead
  /// of all at once. Off by default.
  final bool? staggerFill;

  /// Whether a value dropping to zero empties the stars in reverse.
  /// Off by default.
  final bool? staggerClear;

  /// Gap between one star and the next while staggering.
  final Duration? staggerStep;

  /// Field-by-field override — anything set on [other] wins.
  RatingStyle mergedWith(RatingStyle? other) {
    if (other == null) return this;
    return RatingStyle(
      size: other.size ?? size,
      spacing: other.spacing ?? spacing,
      ratedColor: other.ratedColor ?? ratedColor,
      unratedColor: other.unratedColor ?? unratedColor,
      halfRatedColor: other.halfRatedColor ?? halfRatedColor,
      disabledOpacity: other.disabledOpacity ?? disabledOpacity,
      ratedIcon: other.ratedIcon ?? ratedIcon,
      unratedIcon: other.unratedIcon ?? unratedIcon,
      halfRatedIcon: other.halfRatedIcon ?? halfRatedIcon,
      ratedWidget: other.ratedWidget ?? ratedWidget,
      unratedWidget: other.unratedWidget ?? unratedWidget,
      halfRatedWidget: other.halfRatedWidget ?? halfRatedWidget,
      ratedGradient: other.ratedGradient ?? ratedGradient,
      animationDuration: other.animationDuration ?? animationDuration,
      animationCurve: other.animationCurve ?? animationCurve,
      shadow: other.shadow ?? shadow,
      ratedShadow: other.ratedShadow ?? ratedShadow,
      enableHaptic: other.enableHaptic ?? enableHaptic,
      countLabelStyle: other.countLabelStyle ?? countLabelStyle,
      countLabelSpacing: other.countLabelSpacing ?? countLabelSpacing,
      hoverColor: other.hoverColor ?? hoverColor,
      focusColor: other.focusColor ?? focusColor,
      selectPop: other.selectPop ?? selectPop,
      selectPopScale: other.selectPopScale ?? selectPopScale,
      popDuration: other.popDuration ?? popDuration,
      fillCrossfade: other.fillCrossfade ?? fillCrossfade,
      dragLift: other.dragLift ?? dragLift,
      dragLiftScale: other.dragLiftScale ?? dragLiftScale,
      staggerFill: other.staggerFill ?? staggerFill,
      staggerClear: other.staggerClear ?? staggerClear,
      staggerStep: other.staggerStep ?? staggerStep,
    );
  }

  RatingStyle copyWith({
    double? size,
    double? spacing,
    Color? ratedColor,
    Color? unratedColor,
    Color? halfRatedColor,
    double? disabledOpacity,
    IconData? ratedIcon,
    IconData? unratedIcon,
    IconData? halfRatedIcon,
    Widget? ratedWidget,
    Widget? unratedWidget,
    Widget? halfRatedWidget,
    Gradient? ratedGradient,
    Duration? animationDuration,
    Curve? animationCurve,
    List<BoxShadow>? shadow,
    List<BoxShadow>? ratedShadow,
    bool? enableHaptic,
    TextStyle? countLabelStyle,
    double? countLabelSpacing,
    Color? hoverColor,
    Color? focusColor,
    bool? selectPop,
    double? selectPopScale,
    Duration? popDuration,
    bool? fillCrossfade,
    bool? dragLift,
    double? dragLiftScale,
    bool? staggerFill,
    bool? staggerClear,
    Duration? staggerStep,
  }) => RatingStyle(
    size: size ?? this.size,
    spacing: spacing ?? this.spacing,
    ratedColor: ratedColor ?? this.ratedColor,
    unratedColor: unratedColor ?? this.unratedColor,
    halfRatedColor: halfRatedColor ?? this.halfRatedColor,
    disabledOpacity: disabledOpacity ?? this.disabledOpacity,
    ratedIcon: ratedIcon ?? this.ratedIcon,
    unratedIcon: unratedIcon ?? this.unratedIcon,
    halfRatedIcon: halfRatedIcon ?? this.halfRatedIcon,
    ratedWidget: ratedWidget ?? this.ratedWidget,
    unratedWidget: unratedWidget ?? this.unratedWidget,
    halfRatedWidget: halfRatedWidget ?? this.halfRatedWidget,
    ratedGradient: ratedGradient ?? this.ratedGradient,
    animationDuration: animationDuration ?? this.animationDuration,
    animationCurve: animationCurve ?? this.animationCurve,
    shadow: shadow ?? this.shadow,
    ratedShadow: ratedShadow ?? this.ratedShadow,
    enableHaptic: enableHaptic ?? this.enableHaptic,
    countLabelStyle: countLabelStyle ?? this.countLabelStyle,
    countLabelSpacing: countLabelSpacing ?? this.countLabelSpacing,
    hoverColor: hoverColor ?? this.hoverColor,
    focusColor: focusColor ?? this.focusColor,
    selectPop: selectPop ?? this.selectPop,
    selectPopScale: selectPopScale ?? this.selectPopScale,
    popDuration: popDuration ?? this.popDuration,
    fillCrossfade: fillCrossfade ?? this.fillCrossfade,
    dragLift: dragLift ?? this.dragLift,
    dragLiftScale: dragLiftScale ?? this.dragLiftScale,
    staggerFill: staggerFill ?? this.staggerFill,
    staggerClear: staggerClear ?? this.staggerClear,
    staggerStep: staggerStep ?? this.staggerStep,
  );
}

// ---------------------------------------------------------------------------
// ResolvedRatingStyle
// ---------------------------------------------------------------------------

/// [RatingStyle] after `caller > theme > defaults > palette`. Every
/// themed field is non-null, so build code reads `rs.ratedColor` with no
/// `?? Colors.amber` behind it.
@immutable
class ResolvedRatingStyle {
  const ResolvedRatingStyle({
    required this.size,
    required this.spacing,
    required this.ratedColor,
    required this.unratedColor,
    required this.halfRatedColor,
    required this.disabledOpacity,
    required this.ratedIcon,
    required this.unratedIcon,
    required this.halfRatedIcon,
    required this.animationDuration,
    required this.animationCurve,
    required this.enableHaptic,
    required this.countLabelStyle,
    required this.countLabelSpacing,
    required this.hoverColor,
    required this.focusColor,
    required this.selectPop,
    required this.selectPopScale,
    required this.popDuration,
    required this.fillCrossfade,
    required this.dragLift,
    required this.dragLiftScale,
    required this.staggerFill,
    required this.staggerClear,
    required this.staggerStep,
    this.ratedWidget,
    this.unratedWidget,
    this.halfRatedWidget,
    this.ratedGradient,
    this.shadow,
    this.ratedShadow,
  });

  final double size;
  final double spacing;
  final Color ratedColor;
  final Color unratedColor;
  final Color halfRatedColor;
  final double disabledOpacity;
  final IconData ratedIcon;
  final IconData unratedIcon;
  final IconData halfRatedIcon;
  final Duration animationDuration;
  final Curve animationCurve;
  final bool enableHaptic;
  final TextStyle countLabelStyle;
  final double countLabelSpacing;
  final Color hoverColor;
  final Color focusColor;
  final bool selectPop;
  final double selectPopScale;
  final Duration popDuration;
  final bool fillCrossfade;
  final bool dragLift;
  final double dragLiftScale;
  final bool staggerFill;
  final bool staggerClear;
  final Duration staggerStep;
  final Widget? ratedWidget;
  final Widget? unratedWidget;
  final Widget? halfRatedWidget;
  final Gradient? ratedGradient;
  final List<BoxShadow>? shadow;
  final List<BoxShadow>? ratedShadow;

  /// Width one star occupies including its trailing gap. The pointer
  /// maths runs on this, so it is derived HERE rather than at three
  /// call sites that could drift apart.
  double get itemExtent => size + spacing;

  /// Width of a whole row of [count] stars. The last star carries no
  /// trailing gap.
  double widthFor(int count) =>
      count * size + (count > 1 ? (count - 1) * spacing : 0);

  /// Delay before star [index] takes its new fill.
  ///
  /// [reversed] runs the wave from the last star back, which is what
  /// makes clearing read as undoing rather than as a second rating.
  Duration staggerDelay(int index, int count, {required bool reversed}) =>
      staggerStep * (reversed ? count - 1 - index : index);

  double get hoverRadius => size * RatingDefaults.hoverRadiusFraction;
  double get focusRadius => size * RatingDefaults.focusRadiusFraction;
}
