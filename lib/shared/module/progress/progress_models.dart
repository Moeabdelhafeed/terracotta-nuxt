import 'package:flutter/material.dart';

import '../../../core/animations/animation_presets.dart';
import '../../../core/localization/number_formatter.dart';

// ---------------------------------------------------------------------------
// Constants
// ---------------------------------------------------------------------------

/// Geometry and tolerances that only change when this module changes.
/// Anything an app would rebrand lives on [ProgressStyle] instead.
abstract final class ProgressDefaults {
  static const thickness = 6.0;
  static const animDuration = AppDurations.deliberate;
  static const indeterminateDuration = Duration(milliseconds: 2000);

  /// Natural size per shape, when the caller names none. A linear bar
  /// has none: it takes the width it is given.
  static const circularSize = 48.0;
  static const gaugeSize = 120.0;
  static const waveSize = 100.0;
  static const countdownSize = 80.0;
  static const countdownThickness = 5.0;

  /// A gauge is a HALF circle, so its box is wider than it is tall.
  static const gaugeHeightRatio = 0.6;

  /// How much of the fill colour the empty track keeps.
  static const trackOpacity = 0.15;

  static const labelPad = 8.0;
  static const labelFontSize = 13.0;
  static const labelFontWeight = FontWeight.w600;

  static const gaugeLabelFontSize = 20.0;
  static const gaugeLabelSubSize = 12.0;
  static const gaugeLabelSubOpacity = 0.5;

  static const innerShadowBlur = 3.0;
  static const innerShadowOpacity = 0.15;

  static const stepGap = 4.0;
  static const stepRadius = 4.0;
  static const stepLabelFontSize = 11.0;
  static const stepLabelPad = 6.0;
  static const stepLabelOpacity = 0.5;

  static const bufferOpacity = 0.3;
  static const tickOpacity = 0.2;
  static const tickCount = 10;
  static const tickWidth = 1.0;

  /// How long an indeterminate indicator waits before showing itself.
  ///
  /// Work that finishes in eighty milliseconds still flashed a spinner,
  /// and a flash is worse than nothing: it reads as a glitch rather
  /// than as loading. Zero here — it is the APP theme that sets a real
  /// grace period, so one line covers every spinner at once.
  static const appearAfter = Duration.zero;

  /// A sensible grace period for the app theme to set. Long enough that
  /// a fast round trip never flashes, short enough that a slow one does
  /// not feel unacknowledged.
  static const suggestedAppearAfter = Duration(milliseconds: 300);

  static const pulseDuration = AppDurations.shimmer;
  static const pulseMinOpacity = 0.6;

  static const waveSpeed = 2.0;
  static const waveAmplitude = 6.0;
  static const waveFrequency = 0.04;
  static const waveSecondLayerOpacity = 0.4;
  static const waveBorderWidth = 2.0;

  static const segmentLegendDotSize = 8.0;
  static const segmentLegendGap = 4.0;
  static const segmentLabelOpacity = 0.7;

  /// Flex is an int, so segment fractions are scaled before rounding.
  /// Three digits is a tenth of a percent — finer than anything a bar
  /// this size can show.
  static const segmentFlexScale = 1000;
}

// ---------------------------------------------------------------------------
// Enums
// ---------------------------------------------------------------------------

/// Type of progress indicator.
enum ProgressType {
  /// Horizontal bar.
  linear,

  /// Circular ring.
  circular,

  /// Semicircle gauge.
  gauge,

  /// Stepped progress (discrete steps).
  stepped,

  /// Multiple colored segments in one bar.
  multiSegment,

  /// Circular with animated wave fill (water level).
  waveFill,
}

/// Shape of the linear progress bar ends.
enum ProgressCapStyle { round, flat }

/// Position of the progress label.
enum ProgressLabelPosition {
  /// Before the progress bar (left side).
  start,

  /// After the progress bar (right side).
  end,
  center,
  top,
  bottom,
  inside,
}

/// A segment in a multi-segment progress bar.
@immutable
class ProgressSegment {
  const ProgressSegment({
    required this.value,
    required this.color,
    this.label,
  });

  /// Fraction of the total (0.0-1.0). All segments should sum to ≤ 1.0.
  final double value;

  /// Color of this segment.
  final Color color;

  /// Optional label for this segment.
  final String? label;
}

// ---------------------------------------------------------------------------
// ProgressStyle
// ---------------------------------------------------------------------------

/// Themeable styling bag for `GlobalProgress` — EVERY field nullable.
///
/// Resolution order, materialized once per build by
/// `style.resolve(context, type:)`:
/// `caller > GlobalProgressTheme.style > ProgressStyle.defaults > palette`.
///
/// Adding a themed field means touching five places: here, [mergedWith],
/// [copyWith], [ResolvedProgressStyle] and `GlobalProgressTheme.lerp`.
@immutable
class ProgressStyle {
  const ProgressStyle({
    this.color,
    this.gradient,
    this.trackColor,
    this.trackGradient,
    this.trackOpacity,
    this.size,
    this.thickness,
    this.capStyle,
    this.borderRadius,
    this.showLabel,
    this.labelPosition,
    this.labelFormatter,
    this.labelStyle,
    this.sublabelStyle,
    this.stepLabelStyle,
    this.animated,
    this.animationDuration,
    this.animationCurve,
    this.indeterminate,
    this.indeterminateDuration,
    this.shadow,
    this.innerShadow,
    this.bufferColor,
    this.showTickMarks,
    this.tickCount,
    this.tickColor,
    this.tickWidth,
    this.pulse,
    this.colorThresholds,
    this.followTextDirection,
    this.appearAfter,
    this.stepGap,
  });

  /// Compile-time floor. Colours are deliberately absent: they resolve
  /// from `context.primaryColors` and friends at build time, so a bar
  /// tracks the palette, role, brightness and saturation.
  ///
  /// [size] is absent too — it depends on the SHAPE, which the bag does
  /// not know. `resolve` takes the type.
  static const ProgressStyle defaults = ProgressStyle(
    trackOpacity: ProgressDefaults.trackOpacity,
    thickness: ProgressDefaults.thickness,
    capStyle: ProgressCapStyle.round,
    showLabel: false,
    labelPosition: ProgressLabelPosition.end,
    animated: true,
    animationDuration: ProgressDefaults.animDuration,
    animationCurve: Curves.easeInOut,
    indeterminate: false,
    indeterminateDuration: ProgressDefaults.indeterminateDuration,
    innerShadow: false,
    showTickMarks: false,
    tickCount: ProgressDefaults.tickCount,
    tickWidth: ProgressDefaults.tickWidth,
    pulse: false,
    followTextDirection: true,
    appearAfter: ProgressDefaults.appearAfter,
    stepGap: ProgressDefaults.stepGap,
  );

  /// The fill. Null takes the palette's primary.
  final Color? color;

  /// Gradient fill, which wins over [color].
  final Gradient? gradient;

  /// The empty part. Null takes the fill at [trackOpacity].
  final Color? trackColor;
  final Gradient? trackGradient;
  final double? trackOpacity;

  /// Diameter for the round shapes; ignored by `linear`, which takes
  /// the width it is given.
  final double? size;

  final double? thickness;
  final ProgressCapStyle? capStyle;
  final BorderRadius? borderRadius;

  final bool? showLabel;
  final ProgressLabelPosition? labelPosition;
  final String Function(double value)? labelFormatter;

  /// The percentage read-out. Null takes the fill colour at the
  /// module's size and weight.
  final TextStyle? labelStyle;

  /// The gauge's second line.
  final TextStyle? sublabelStyle;

  /// A step's caption. The ACTIVE steps take the fill colour and a
  /// heavier weight on top of this.
  final TextStyle? stepLabelStyle;

  final bool? animated;
  final Duration? animationDuration;
  final Curve? animationCurve;

  final bool? indeterminate;
  final Duration? indeterminateDuration;

  final List<BoxShadow>? shadow;
  final bool? innerShadow;

  /// Colour of the buffer bar. Null takes the fill, faded.
  final Color? bufferColor;

  /// Show tick marks at intervals along the track.
  final bool? showTickMarks;
  final int? tickCount;
  final Color? tickColor;
  final double? tickWidth;

  /// Pulse/glow animation on the progress fill.
  final bool? pulse;

  /// Whether a bar fills from the START of the reading direction — so
  /// right-to-left in Arabic and Hebrew.
  ///
  /// ON. A bar that fills leftward in an RTL layout reads as DRAINING,
  /// because it empties toward the side you read from. Turn it off for
  /// the cases where the axis is not the reading order — a timeline
  /// pinned to wall-clock time, a chart axis, a media scrubber whose
  /// artwork does not mirror.
  ///
  /// Only the directional shapes honour it: `linear`, `gauge`,
  /// `stepped` and `multiSegment`. A ring and a droplet have no
  /// reading direction to follow, and Material does not mirror those
  /// either.
  final bool? followTextDirection;

  /// How long an INDETERMINATE indicator waits before appearing.
  ///
  /// Work that finishes inside this never shows a spinner at all. A
  /// flash of one is worse than no feedback: it reads as a glitch.
  /// Ignored by determinate shapes, which have something to say from
  /// the first frame.
  final Duration? appearAfter;

  /// Gap between the segments of a `stepped` bar.
  final double? stepGap;

  /// Colour thresholds — the fill changes colour with the value.
  /// Map of threshold (0.0-1.0) → colour; the LOWEST threshold at or
  /// above the value wins.
  /// Example: `{0.3: red, 0.6: orange, 1.0: green}`.
  final Map<double, Color>? colorThresholds;

  /// Field-by-field override — anything set on [other] wins.
  ProgressStyle mergedWith(ProgressStyle? other) {
    if (other == null) return this;
    return ProgressStyle(
      color: other.color ?? color,
      gradient: other.gradient ?? gradient,
      trackColor: other.trackColor ?? trackColor,
      trackGradient: other.trackGradient ?? trackGradient,
      trackOpacity: other.trackOpacity ?? trackOpacity,
      size: other.size ?? size,
      thickness: other.thickness ?? thickness,
      capStyle: other.capStyle ?? capStyle,
      borderRadius: other.borderRadius ?? borderRadius,
      showLabel: other.showLabel ?? showLabel,
      labelPosition: other.labelPosition ?? labelPosition,
      labelFormatter: other.labelFormatter ?? labelFormatter,
      labelStyle: other.labelStyle ?? labelStyle,
      sublabelStyle: other.sublabelStyle ?? sublabelStyle,
      stepLabelStyle: other.stepLabelStyle ?? stepLabelStyle,
      animated: other.animated ?? animated,
      animationDuration: other.animationDuration ?? animationDuration,
      animationCurve: other.animationCurve ?? animationCurve,
      indeterminate: other.indeterminate ?? indeterminate,
      indeterminateDuration:
          other.indeterminateDuration ?? indeterminateDuration,
      shadow: other.shadow ?? shadow,
      innerShadow: other.innerShadow ?? innerShadow,
      bufferColor: other.bufferColor ?? bufferColor,
      showTickMarks: other.showTickMarks ?? showTickMarks,
      tickCount: other.tickCount ?? tickCount,
      tickColor: other.tickColor ?? tickColor,
      tickWidth: other.tickWidth ?? tickWidth,
      pulse: other.pulse ?? pulse,
      colorThresholds: other.colorThresholds ?? colorThresholds,
      followTextDirection: other.followTextDirection ?? followTextDirection,
      appearAfter: other.appearAfter ?? appearAfter,
      stepGap: other.stepGap ?? stepGap,
    );
  }

  ProgressStyle copyWith({
    Color? color,
    Gradient? gradient,
    Color? trackColor,
    Gradient? trackGradient,
    double? trackOpacity,
    double? size,
    double? thickness,
    ProgressCapStyle? capStyle,
    BorderRadius? borderRadius,
    bool? showLabel,
    ProgressLabelPosition? labelPosition,
    String Function(double value)? labelFormatter,
    TextStyle? labelStyle,
    TextStyle? sublabelStyle,
    TextStyle? stepLabelStyle,
    bool? animated,
    Duration? animationDuration,
    Curve? animationCurve,
    bool? indeterminate,
    Duration? indeterminateDuration,
    List<BoxShadow>? shadow,
    bool? innerShadow,
    Color? bufferColor,
    bool? showTickMarks,
    int? tickCount,
    Color? tickColor,
    double? tickWidth,
    bool? pulse,
    Map<double, Color>? colorThresholds,
    bool? followTextDirection,
    Duration? appearAfter,
    double? stepGap,
  }) => ProgressStyle(
    color: color ?? this.color,
    gradient: gradient ?? this.gradient,
    trackColor: trackColor ?? this.trackColor,
    trackGradient: trackGradient ?? this.trackGradient,
    trackOpacity: trackOpacity ?? this.trackOpacity,
    size: size ?? this.size,
    thickness: thickness ?? this.thickness,
    capStyle: capStyle ?? this.capStyle,
    borderRadius: borderRadius ?? this.borderRadius,
    showLabel: showLabel ?? this.showLabel,
    labelPosition: labelPosition ?? this.labelPosition,
    labelFormatter: labelFormatter ?? this.labelFormatter,
    labelStyle: labelStyle ?? this.labelStyle,
    sublabelStyle: sublabelStyle ?? this.sublabelStyle,
    stepLabelStyle: stepLabelStyle ?? this.stepLabelStyle,
    animated: animated ?? this.animated,
    animationDuration: animationDuration ?? this.animationDuration,
    animationCurve: animationCurve ?? this.animationCurve,
    indeterminate: indeterminate ?? this.indeterminate,
    indeterminateDuration: indeterminateDuration ?? this.indeterminateDuration,
    shadow: shadow ?? this.shadow,
    innerShadow: innerShadow ?? this.innerShadow,
    bufferColor: bufferColor ?? this.bufferColor,
    showTickMarks: showTickMarks ?? this.showTickMarks,
    tickCount: tickCount ?? this.tickCount,
    tickColor: tickColor ?? this.tickColor,
    tickWidth: tickWidth ?? this.tickWidth,
    pulse: pulse ?? this.pulse,
    colorThresholds: colorThresholds ?? this.colorThresholds,
    followTextDirection: followTextDirection ?? this.followTextDirection,
    appearAfter: appearAfter ?? this.appearAfter,
    stepGap: stepGap ?? this.stepGap,
  );
}

// ---------------------------------------------------------------------------
// ResolvedProgressStyle
// ---------------------------------------------------------------------------

/// [ProgressStyle] after `caller > theme > defaults > palette`, for ONE
/// shape. Every themed field is non-null, so build code reads
/// `rs.thickness` with no `??` ladder behind it.
@immutable
class ResolvedProgressStyle {
  const ResolvedProgressStyle({
    required this.color,
    required this.trackColor,
    required this.trackOpacity,
    required this.size,
    required this.thickness,
    required this.capStyle,
    required this.showLabel,
    required this.labelPosition,
    required this.labelStyle,
    required this.sublabelStyle,
    required this.stepLabelStyle,
    required this.animated,
    required this.animationDuration,
    required this.animationCurve,
    required this.indeterminate,
    required this.indeterminateDuration,
    required this.innerShadow,
    required this.bufferColor,
    required this.showTickMarks,
    required this.tickCount,
    required this.tickColor,
    required this.tickWidth,
    required this.pulse,
    required this.trackFollowsFill,
    required this.followTextDirection,
    required this.appearAfter,
    required this.stepGap,
    this.gradient,
    this.trackGradient,
    this.borderRadius,
    this.labelFormatter,
    this.shadow,
    this.colorThresholds,
  });

  /// The BASE fill. When [colorThresholds] is set the live colour comes
  /// from `colorFor(value)` instead — it depends on the value, which is
  /// not a styling decision and changes every frame.
  final Color color;
  final Color trackColor;
  final double trackOpacity;

  /// Whether [trackColor] was DERIVED from the fill rather than named.
  /// Decided by `resolve`, and the reason [trackFor] exists.
  final bool trackFollowsFill;

  /// Natural size for the round shapes; `null` for `linear`, which
  /// takes the width it is given.
  final double? size;

  final double thickness;
  final ProgressCapStyle capStyle;
  final bool showLabel;
  final ProgressLabelPosition labelPosition;
  final TextStyle labelStyle;
  final TextStyle sublabelStyle;
  final TextStyle stepLabelStyle;
  final bool animated;
  final Duration animationDuration;
  final Curve animationCurve;
  final bool indeterminate;
  final Duration indeterminateDuration;
  final bool innerShadow;
  final Color bufferColor;
  final bool showTickMarks;
  final int tickCount;
  final Color tickColor;
  final double tickWidth;
  final bool pulse;

  /// Whether the directional shapes mirror in an RTL layout.
  final bool followTextDirection;

  /// How long an indeterminate indicator waits before appearing.
  final Duration appearAfter;

  /// Gap between the segments of a `stepped` bar.
  final double stepGap;

  final Gradient? gradient;
  final Gradient? trackGradient;
  final BorderRadius? borderRadius;
  final String Function(double value)? labelFormatter;
  final List<BoxShadow>? shadow;
  final Map<double, Color>? colorThresholds;

  /// The fill at [value], honouring [colorThresholds].
  ///
  /// The LOWEST threshold at or above the value wins, so
  /// `{0.3: red, 0.6: orange, 1.0: green}` reads as "red up to 30%".
  /// A value above every threshold keeps the last one.
  Color colorFor(double value) {
    final thresholds = colorThresholds;
    if (thresholds == null || thresholds.isEmpty) return color;
    final sorted = thresholds.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));
    for (final entry in sorted) {
      if (value <= entry.key) return entry.value;
    }
    return sorted.last.value;
  }

  /// The track at [value].
  ///
  /// A DERIVED track has to follow the fill through its thresholds —
  /// otherwise a bar that turns red keeps a blue track behind it — and
  /// a track the caller named must not move at all.
  Color trackFor(double value) => trackFollowsFill
      ? colorFor(value).withValues(alpha: trackOpacity)
      : trackColor;

  /// The label read-out for [value].
  ///
  /// LOCALE-AWARE by default: `AppNumbers.percent` follows
  /// `Intl.getCurrentLocale`, so an Arabic locale gets Arabic-Indic
  /// digits and its own percent sign rather than `'${(v * 100).round()}%'`
  /// hard-coded in Western numerals with the symbol on the wrong side.
  String format(double value) =>
      labelFormatter?.call(value) ?? AppNumbers.percent(value);
}
