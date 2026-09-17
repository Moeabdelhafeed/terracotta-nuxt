import 'package:flutter/material.dart';

import '../../../core/animations/animation_presets.dart';

// ---------------------------------------------------------------------------
// Constants
// ---------------------------------------------------------------------------

/// Geometry and tolerances that only change when this module changes.
/// Anything an app would rebrand lives on [DividerStyle] instead.
abstract final class DividerDefaults {
  static const thickness = 1.0;

  /// A wave or zigzag is drawn thinner than a straight rule: the curve
  /// already reads as heavier than its stroke width suggests.
  static const waveThickness = 1.5;

  static const dashWidth = 6.0;
  static const dashGap = 4.0;

  /// A dot is a dash of zero length, so it needs its own gap to keep
  /// the rhythm even.
  static const dottedGap = 3.0;
  static const dottedWidth = 1.0;

  static const iconSize = 16.0;
  static const verticalHeight = 24.0;
  static const doubleLineGap = 3.0;

  static const waveAmplitude = 4.0;
  static const waveFrequency = 12.0;

  /// A zigzag needs more cycles than a wave to read as sharp rather
  /// than merely bent.
  static const zigzagFrequency = 16.0;

  /// Sampling step for the wave path, in logical pixels.
  static const waveStep = 1.0;

  /// How far the divider's colour sits from the secondary text colour.
  /// A rule that reads as loudly as a label competes with it.
  static const colorOpacity = 0.5;

  /// Room added around a TAPPABLE divider, so a 1dp line is not a 1dp
  /// target.
  static const tapPadding = 8.0;

  static const centerPaddingHorizontal = 12.0;

  static const expandablePadding = 8.0;
  static const expandableArrowSize = 18.0;
  static const expandableIconSize = 16.0;

  /// Half a turn — the arrow points one way when collapsed and the
  /// other when open.
  static const expandableArrowRotation = 0.5;

  static const expandAnimDuration = AppDurations.normal;
  static const animDuration = AppDurations.deliberate;

  /// The entrance runs in two beats: the rule draws itself, then the
  /// label fades in over the tail of it.
  static const animExpandInterval = Interval(
    0,
    0.7,
    curve: Curves.easeOutCubic,
  );
  static const animFadeInterval = Interval(0.5, 1, curve: Curves.easeIn);
}

// ---------------------------------------------------------------------------
// DividerLineStyle
// ---------------------------------------------------------------------------

/// How the line itself is drawn.
enum DividerLineStyle {
  solid,
  dashed,
  dotted,
  wave,
  zigzag;

  /// Whether this style needs the painter rather than a coloured box.
  bool get needsPainter => this != DividerLineStyle.solid;

  /// Whether the line leaves its own lane — a wave and a zigzag are
  /// taller than their stroke, so the box has to be too.
  bool get isCurved =>
      this == DividerLineStyle.wave || this == DividerLineStyle.zigzag;
}

// ---------------------------------------------------------------------------
// DividerStyle
// ---------------------------------------------------------------------------

/// Themeable styling bag for `GlobalDivider` — EVERY field nullable.
///
/// Resolution order, materialized once per build by `resolve`:
/// `caller > GlobalDividerTheme.style > DividerStyle.defaults > palette`.
///
/// Adding a themed field means touching five places: here, [mergedWith],
/// [copyWith], [ResolvedDividerStyle] and `GlobalDividerTheme.lerp`.
@immutable
class DividerStyle {
  const DividerStyle({
    this.thickness,
    this.color,
    this.gradient,
    this.indent,
    this.endIndent,
    this.spacing,
    this.dashWidth,
    this.dashGap,
    this.roundedCaps,
    this.textStyle,
    this.textPadding,
    this.iconSize,
    this.iconColor,
    this.verticalHeight,
    this.doubleLineGap,
    this.animationDuration,
    this.shadow,
    this.waveAmplitude,
    this.waveFrequency,
    this.tapPadding,
  });

  /// Compile-time floor. Colours are deliberately absent: they resolve
  /// from `context.<group>Colors` at build time so a rule tracks role,
  /// brightness and saturation.
  static const DividerStyle defaults = DividerStyle(
    thickness: DividerDefaults.thickness,
    indent: 0,
    endIndent: 0,
    spacing: 0,
    dashWidth: DividerDefaults.dashWidth,
    dashGap: DividerDefaults.dashGap,
    roundedCaps: false,
    textPadding: EdgeInsets.symmetric(
      horizontal: DividerDefaults.centerPaddingHorizontal,
    ),
    iconSize: DividerDefaults.iconSize,
    verticalHeight: DividerDefaults.verticalHeight,
    doubleLineGap: DividerDefaults.doubleLineGap,
    animationDuration: DividerDefaults.animDuration,
    waveAmplitude: DividerDefaults.waveAmplitude,
    waveFrequency: DividerDefaults.waveFrequency,
    tapPadding: DividerDefaults.tapPadding,
  );

  final double? thickness;
  final Color? color;
  final Gradient? gradient;

  /// Inset at the START of the line, and at the END. Both directional —
  /// they mirror in Arabic.
  final double? indent;
  final double? endIndent;

  /// Room added ACROSS the rule — vertical for a horizontal divider,
  /// horizontal for a vertical one.
  final double? spacing;

  final double? dashWidth;
  final double? dashGap;
  final bool? roundedCaps;

  final TextStyle? textStyle;
  final EdgeInsetsGeometry? textPadding;
  final double? iconSize;
  final Color? iconColor;

  /// Length of a vertical divider, which has no parent to stretch to.
  final double? verticalHeight;

  final double? doubleLineGap;
  final Duration? animationDuration;
  final BoxShadow? shadow;

  final double? waveAmplitude;
  final double? waveFrequency;

  /// Room added around a TAPPABLE divider so the target is reachable.
  final double? tapPadding;

  /// Field-by-field override — anything set on [other] wins.
  DividerStyle mergedWith(DividerStyle? other) {
    if (other == null) return this;
    return DividerStyle(
      thickness: other.thickness ?? thickness,
      color: other.color ?? color,
      gradient: other.gradient ?? gradient,
      indent: other.indent ?? indent,
      endIndent: other.endIndent ?? endIndent,
      spacing: other.spacing ?? spacing,
      dashWidth: other.dashWidth ?? dashWidth,
      dashGap: other.dashGap ?? dashGap,
      roundedCaps: other.roundedCaps ?? roundedCaps,
      textStyle: other.textStyle ?? textStyle,
      textPadding: other.textPadding ?? textPadding,
      iconSize: other.iconSize ?? iconSize,
      iconColor: other.iconColor ?? iconColor,
      verticalHeight: other.verticalHeight ?? verticalHeight,
      doubleLineGap: other.doubleLineGap ?? doubleLineGap,
      animationDuration: other.animationDuration ?? animationDuration,
      shadow: other.shadow ?? shadow,
      waveAmplitude: other.waveAmplitude ?? waveAmplitude,
      waveFrequency: other.waveFrequency ?? waveFrequency,
      tapPadding: other.tapPadding ?? tapPadding,
    );
  }

  DividerStyle copyWith({
    double? thickness,
    Color? color,
    Gradient? gradient,
    double? indent,
    double? endIndent,
    double? spacing,
    double? dashWidth,
    double? dashGap,
    bool? roundedCaps,
    TextStyle? textStyle,
    EdgeInsetsGeometry? textPadding,
    double? iconSize,
    Color? iconColor,
    double? verticalHeight,
    double? doubleLineGap,
    Duration? animationDuration,
    BoxShadow? shadow,
    double? waveAmplitude,
    double? waveFrequency,
    double? tapPadding,
  }) => DividerStyle(
    thickness: thickness ?? this.thickness,
    color: color ?? this.color,
    gradient: gradient ?? this.gradient,
    indent: indent ?? this.indent,
    endIndent: endIndent ?? this.endIndent,
    spacing: spacing ?? this.spacing,
    dashWidth: dashWidth ?? this.dashWidth,
    dashGap: dashGap ?? this.dashGap,
    roundedCaps: roundedCaps ?? this.roundedCaps,
    textStyle: textStyle ?? this.textStyle,
    textPadding: textPadding ?? this.textPadding,
    iconSize: iconSize ?? this.iconSize,
    iconColor: iconColor ?? this.iconColor,
    verticalHeight: verticalHeight ?? this.verticalHeight,
    doubleLineGap: doubleLineGap ?? this.doubleLineGap,
    animationDuration: animationDuration ?? this.animationDuration,
    shadow: shadow ?? this.shadow,
    waveAmplitude: waveAmplitude ?? this.waveAmplitude,
    waveFrequency: waveFrequency ?? this.waveFrequency,
    tapPadding: tapPadding ?? this.tapPadding,
  );
}

// ---------------------------------------------------------------------------
// ResolvedDividerStyle
// ---------------------------------------------------------------------------

/// [DividerStyle] after `caller > theme > defaults > palette`. Every
/// themed field is non-null, so build code reads `rs.color` with no
/// `??` ladder behind it.
@immutable
class ResolvedDividerStyle {
  const ResolvedDividerStyle({
    required this.thickness,
    required this.color,
    required this.indent,
    required this.endIndent,
    required this.spacing,
    required this.dashWidth,
    required this.dashGap,
    required this.roundedCaps,
    required this.textStyle,
    required this.textPadding,
    required this.iconSize,
    required this.iconColor,
    required this.verticalHeight,
    required this.doubleLineGap,
    required this.animationDuration,
    required this.waveAmplitude,
    required this.waveFrequency,
    required this.tapPadding,
    this.gradient,
    this.shadow,
  });

  final double thickness;
  final Color color;
  final Gradient? gradient;
  final double indent;
  final double endIndent;
  final double spacing;
  final double dashWidth;
  final double dashGap;
  final bool roundedCaps;
  final TextStyle textStyle;
  final EdgeInsetsGeometry textPadding;
  final double iconSize;
  final Color iconColor;
  final double verticalHeight;
  final double doubleLineGap;
  final Duration animationDuration;
  final BoxShadow? shadow;
  final double waveAmplitude;
  final double waveFrequency;
  final double tapPadding;

  /// Height of the box the line needs. A wave leaves its own lane, so
  /// its box is the stroke plus twice the amplitude.
  double extentFor(DividerLineStyle lineStyle) =>
      lineStyle.isCurved ? thickness + waveAmplitude * 2 : thickness;

  /// Whether a plain coloured box will do, or the painter is needed.
  bool needsPainter(DividerLineStyle lineStyle) =>
      lineStyle.needsPainter || gradient != null || roundedCaps;
}
