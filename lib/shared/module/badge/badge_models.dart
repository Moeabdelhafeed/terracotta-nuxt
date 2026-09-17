import 'package:flutter/material.dart';

import '../../../core/animations/animation_presets.dart';

// ---------------------------------------------------------------------------
// Constants
// ---------------------------------------------------------------------------

const kBadgeDefaultSize = 18.0;
const kBadgeDotSize = 10.0;
const kBadgeDefaultFontSize = 11.0;
const kBadgeDefaultBorderWidth = 2.0;
const kBadgeAnimDuration = AppDurations.quick;
const kBadgePulseDuration = Duration(milliseconds: 1200);
const kBadgeMaxCount = 99;

/// Horizontal padding a multi-digit count needs so "99+" does not touch
/// the pill's edges. A single digit is centred in the minimum box and
/// needs none.
const kBadgeCountHPad = 5.0;

/// Extra height a label pill carries over its font size, used to
/// estimate the corner offset before layout.
const kBadgeLabelHeightPad = 6.0;

/// Share of the badge that overhangs the child it is attached to.
///
/// A third: enough to read as attached to the corner rather than
/// floating beside it, and not so much that a two-digit count clips.
const kBadgeOverhangFraction = 3.0;

/// Scale a pulsing badge grows to at the top of its cycle, and the
/// opacity it dips to.
const kBadgePulseScale = 1.2;
const kBadgePulseMinOpacity = 0.7;

/// Label-pill geometry.
const kBadgeLabelHPad = 6.0;
const kBadgeLabelVPad = 2.0;
const kBadgeLabelRadius = 8.0;

/// Share of a badge's box its glyph fills, for [BadgeVariant.icon].
const kBadgeIconFraction = 0.65;

// ---------------------------------------------------------------------------
// BadgePosition
// ---------------------------------------------------------------------------

/// Corner the badge attaches to. Directional, so it mirrors in RTL.
enum BadgePosition { topEnd, topStart, bottomEnd, bottomStart }

// ---------------------------------------------------------------------------
// BadgeVariant
// ---------------------------------------------------------------------------

/// What the badge shows.
enum BadgeVariant {
  /// A count ("3", "99+").
  count,

  /// A bare dot, no content.
  dot,

  /// A short label ("NEW", "BETA").
  label,

  /// An icon.
  icon,

  /// A caller-supplied widget.
  custom,
}

// ---------------------------------------------------------------------------
// BadgeStyle
// ---------------------------------------------------------------------------

/// Themeable styling bag for [GlobalBadge] — EVERY field nullable.
///
/// Resolution order, materialized once per build by `resolve`:
/// `caller > GlobalBadgeTheme.style > BadgeStyle.defaults > palette`.
///
/// Adding a themed field means touching five places: here, [mergedWith],
/// [copyWith], `ResolvedBadgeStyle` and `GlobalBadgeTheme.lerp`.
@immutable
class BadgeStyle {
  const BadgeStyle({
    this.backgroundColor,
    this.backgroundGradient,
    this.foregroundColor,
    this.borderColor,
    this.borderWidth,
    this.fontSize,
    this.fontWeight,
    this.size,
    this.dotSize,
    this.padding,
    this.borderRadius,
    this.shadow,
    this.animationDuration,
    this.animationCurve,
    this.pulsate,
    this.hideWhenZero,
    this.maxCount,
    this.offset,
  });

  /// Compile-time floor. Colours are deliberately absent: they come from
  /// `context.<group>Colors` at resolve time so a badge tracks role,
  /// brightness and saturation. They used to be `Colors.red` and
  /// `Colors.white` — the same red on every palette an app might ship.
  static const BadgeStyle defaults = BadgeStyle(
    borderWidth: kBadgeDefaultBorderWidth,
    fontSize: kBadgeDefaultFontSize,
    fontWeight: FontWeight.w700,
    dotSize: kBadgeDotSize,
    animationDuration: kBadgeAnimDuration,
    animationCurve: Curves.easeOutCubic,
    pulsate: false,
    hideWhenZero: true,
    maxCount: kBadgeMaxCount,
    offset: Offset.zero,
  );

  /// Null takes `statusColors.error` — a badge is an alert.
  final Color? backgroundColor;

  /// Overrides [backgroundColor] when set.
  final Gradient? backgroundGradient;

  /// Null takes `textColors.onPrimary`.
  final Color? foregroundColor;

  /// Ring separating the badge from whatever it sits on. Null takes the
  /// page background, which is what makes the badge read as lifted off
  /// its child rather than drawn onto it.
  final Color? borderColor;

  final double? borderWidth;
  final double? fontSize;
  final FontWeight? fontWeight;

  /// Minimum box for a count or icon badge. Null takes
  /// [kBadgeDefaultSize].
  final double? size;

  final double? dotSize;
  final EdgeInsetsGeometry? padding;

  /// Null is a full pill.
  final BorderRadius? borderRadius;

  final List<BoxShadow>? shadow;
  final Duration? animationDuration;
  final Curve? animationCurve;

  /// Pulses for attention. Skipped under reduced motion — a repeating
  /// scale is exactly what `disableAnimations` exists to stop.
  final bool? pulsate;

  /// A zero count hides the badge. [BadgeVariant.count] only.
  final bool? hideWhenZero;

  /// Above this, the badge reads "99+".
  final int? maxCount;

  /// Nudge from the corner.
  final Offset? offset;

  /// Field-by-field override — [other]'s non-null fields win.
  BadgeStyle mergedWith(BadgeStyle? other) {
    if (other == null) return this;
    return BadgeStyle(
      backgroundColor: other.backgroundColor ?? backgroundColor,
      backgroundGradient: other.backgroundGradient ?? backgroundGradient,
      foregroundColor: other.foregroundColor ?? foregroundColor,
      borderColor: other.borderColor ?? borderColor,
      borderWidth: other.borderWidth ?? borderWidth,
      fontSize: other.fontSize ?? fontSize,
      fontWeight: other.fontWeight ?? fontWeight,
      size: other.size ?? size,
      dotSize: other.dotSize ?? dotSize,
      padding: other.padding ?? padding,
      borderRadius: other.borderRadius ?? borderRadius,
      shadow: other.shadow ?? shadow,
      animationDuration: other.animationDuration ?? animationDuration,
      animationCurve: other.animationCurve ?? animationCurve,
      pulsate: other.pulsate ?? pulsate,
      hideWhenZero: other.hideWhenZero ?? hideWhenZero,
      maxCount: other.maxCount ?? maxCount,
      offset: other.offset ?? offset,
    );
  }

  BadgeStyle copyWith({
    Color? backgroundColor,
    Gradient? backgroundGradient,
    Color? foregroundColor,
    Color? borderColor,
    double? borderWidth,
    double? fontSize,
    FontWeight? fontWeight,
    double? size,
    double? dotSize,
    EdgeInsetsGeometry? padding,
    BorderRadius? borderRadius,
    List<BoxShadow>? shadow,
    Duration? animationDuration,
    Curve? animationCurve,
    bool? pulsate,
    bool? hideWhenZero,
    int? maxCount,
    Offset? offset,
  }) => BadgeStyle(
    backgroundColor: backgroundColor ?? this.backgroundColor,
    backgroundGradient: backgroundGradient ?? this.backgroundGradient,
    foregroundColor: foregroundColor ?? this.foregroundColor,
    borderColor: borderColor ?? this.borderColor,
    borderWidth: borderWidth ?? this.borderWidth,
    fontSize: fontSize ?? this.fontSize,
    fontWeight: fontWeight ?? this.fontWeight,
    size: size ?? this.size,
    dotSize: dotSize ?? this.dotSize,
    padding: padding ?? this.padding,
    borderRadius: borderRadius ?? this.borderRadius,
    shadow: shadow ?? this.shadow,
    animationDuration: animationDuration ?? this.animationDuration,
    animationCurve: animationCurve ?? this.animationCurve,
    pulsate: pulsate ?? this.pulsate,
    hideWhenZero: hideWhenZero ?? this.hideWhenZero,
    maxCount: maxCount ?? this.maxCount,
    offset: offset ?? this.offset,
  );
}

// ---------------------------------------------------------------------------
// ResolvedBadgeStyle
// ---------------------------------------------------------------------------

/// Materialized [BadgeStyle] — every themed field non-null.
@immutable
class ResolvedBadgeStyle {
  const ResolvedBadgeStyle({
    required this.backgroundColor,
    required this.foregroundColor,
    required this.borderColor,
    required this.borderWidth,
    required this.fontSize,
    required this.fontWeight,
    required this.size,
    required this.dotSize,
    required this.animationDuration,
    required this.animationCurve,
    required this.pulsate,
    required this.hideWhenZero,
    required this.maxCount,
    required this.offset,
    this.backgroundGradient,
    this.padding,
    this.borderRadius,
    this.shadow,
  });

  final Color backgroundColor;
  final Color foregroundColor;
  final Color borderColor;
  final double borderWidth;
  final double fontSize;
  final FontWeight fontWeight;

  /// Minimum box for a count or icon badge.
  final double size;

  final double dotSize;
  final Duration animationDuration;
  final Curve animationCurve;
  final bool pulsate;
  final bool hideWhenZero;
  final int maxCount;
  final Offset offset;

  // Genuinely opt-in — absent means "do not paint this at all".
  final Gradient? backgroundGradient;
  final EdgeInsetsGeometry? padding;
  final BorderRadius? borderRadius;
  final List<BoxShadow>? shadow;

  /// Painted extent of [variant], used to work out the corner overhang
  /// before the badge has been laid out.
  double extentFor(BadgeVariant variant) => switch (variant) {
    BadgeVariant.dot => dotSize,
    BadgeVariant.label => fontSize + kBadgeLabelHeightPad,
    BadgeVariant.count || BadgeVariant.icon || BadgeVariant.custom => size,
  };

  /// What the badge reads as a count, capped at [maxCount].
  String countText(int? count) =>
      (count ?? 0) > maxCount ? '$maxCount+' : '${count ?? 0}';
}
