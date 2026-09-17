import 'package:flutter/material.dart';

import '../../../core/animations/animation_presets.dart';

export '../badge/badge_models.dart' show BadgePosition;

// ---------------------------------------------------------------------------
// Constants
// ---------------------------------------------------------------------------

/// Geometry that only changes when this module changes. Anything an app
/// would rebrand lives on [IconStyle] instead.
abstract final class IconDefaults {
  static const size = 24.0;

  /// Glyph and box for the factories that draw a container. The glyph is
  /// smaller than a bare icon: it has to leave room inside the box.
  static const containedSize = 20.0;
  static const containerSize = 40.0;

  static const backgroundOpacity = 1.0;

  /// A `badge` container is a TINT, not a fill — the glyph reads against
  /// it, so the colour arrives at a whisper.
  static const softBackgroundOpacity = 0.12;

  static const opacity = 1.0;

  static const roundedRadius = 8.0;

  /// Big enough to be a circle at any container size this takes.
  static const circleRadius = 999.0;

  static const borderWidth = 1.5;
  static const gradientBorderWidth = 1.5;
  static const gradientBlendMode = BlendMode.srcATop;

  /// How far a badge hangs off the icon's corner.
  static const badgeInset = 4.0;

  /// Room the stroke needs around the glyph. A stroked path is centred
  /// on the outline, so it reaches `strokeWidth / 2` beyond the glyph on
  /// every side — the box grows by one whole width.
  static const strokeSpread = 1.0;

  /// How much colour a disabled glyph keeps.
  static const disabledOpacity = 0.38;

  static const animationDuration = AppDurations.fast;
}

// ---------------------------------------------------------------------------
// IconContainerShape
// ---------------------------------------------------------------------------

/// Shape of the icon container background.
enum IconContainerShape {
  /// No container at all.
  none,
  circle,
  rounded,
  square;

  bool get isNone => this == IconContainerShape.none;
}

// ---------------------------------------------------------------------------
// IconStyle
// ---------------------------------------------------------------------------

/// Themeable styling bag for `GlobalIcon` — EVERY field nullable.
///
/// Resolution order, materialized once per build by `resolve`:
/// `caller > GlobalIconTheme.style > IconStyle.defaults > palette`.
///
/// Adding a themed field means touching five places: here, [mergedWith],
/// [copyWith], [ResolvedIconStyle] and `GlobalIconTheme.lerp`.
@immutable
class IconStyle {
  const IconStyle({
    this.color,
    this.size,
    this.backgroundColor,
    this.backgroundOpacity,
    this.containerSize,
    this.containerShape,
    this.borderRadius,
    this.border,
    this.borderColor,
    this.borderWidth,
    this.borderGradient,
    this.gradientBorderWidth,
    this.padding,
    this.gradient,
    this.gradientBlendMode,
    this.shadow,
    this.opacity,
    this.strokeWidth,
    this.strokeColor,
    this.strokeGradient,
    this.enableHaptic,
    this.animateIconChange,
    this.animationDuration,
    this.animationCurve,
  }) : assert(
         opacity == null || (opacity >= 0 && opacity <= 1),
         'Opacity must be between 0 and 1',
       ),
       assert(
         backgroundOpacity == null ||
             (backgroundOpacity >= 0 && backgroundOpacity <= 1),
         'Background opacity must be between 0 and 1',
       );

  /// Compile-time floor. Colours are deliberately absent: they resolve
  /// from the ambient `IconTheme` and `context.<group>Colors` at build
  /// time, so an icon tracks role, brightness and saturation.
  static const IconStyle defaults = IconStyle(
    size: IconDefaults.size,
    backgroundOpacity: IconDefaults.backgroundOpacity,
    containerShape: IconContainerShape.none,
    gradientBorderWidth: IconDefaults.gradientBorderWidth,
    gradientBlendMode: IconDefaults.gradientBlendMode,
    opacity: IconDefaults.opacity,
    enableHaptic: true,
    animateIconChange: false,
    animationDuration: IconDefaults.animationDuration,
    animationCurve: Curves.easeOutCubic,
  );

  /// Glyph colour. Null takes the ambient `IconTheme`, then the palette.
  final Color? color;

  /// Glyph size in logical pixels.
  final double? size;

  /// Background behind the glyph.
  final Color? backgroundColor;

  /// How much of [backgroundColor] arrives (0..1).
  final double? backgroundOpacity;

  /// Box size. Null wraps the glyph.
  final double? containerSize;

  /// Shape of the box.
  final IconContainerShape? containerShape;

  /// Explicit corner radius. Wins over [containerShape].
  final BorderRadius? borderRadius;

  /// Solid border, composed for you from [borderColor] / [borderWidth]
  /// unless you hand one over whole. Mutually exclusive with
  /// [borderGradient].
  final BoxBorder? border;

  /// Colour of that border. Null takes the palette's outline — which is
  /// the point of not writing `Colors.grey` here.
  final Color? borderColor;
  final double? borderWidth;

  /// Gradient border, which wins over [border].
  final Gradient? borderGradient;

  /// Its width. A solid border carries its own.
  final double? gradientBorderWidth;

  /// Inset around the glyph, inside the box.
  final EdgeInsets? padding;

  /// Gradient over the glyph's fill.
  final Gradient? gradient;
  final BlendMode? gradientBlendMode;

  /// Shadow under the box.
  final List<BoxShadow>? shadow;

  /// Opacity of the whole thing (0..1).
  final double? opacity;

  /// Outline around the glyph. Null draws none.
  final double? strokeWidth;
  final Color? strokeColor;

  /// Gradient for that outline, which wins over [strokeColor].
  final Gradient? strokeGradient;

  /// Whether a tap buzzes. Only reaches a tappable icon.
  final bool? enableHaptic;

  /// Whether swapping the glyph crossfades instead of cutting.
  ///
  /// Off by default: most icons never change, and a switcher that never
  /// switches is a widget layer every icon in the app would carry.
  final bool? animateIconChange;
  final Duration? animationDuration;
  final Curve? animationCurve;

  /// Field-by-field override — anything set on [other] wins.
  IconStyle mergedWith(IconStyle? other) {
    if (other == null) return this;
    return IconStyle(
      color: other.color ?? color,
      size: other.size ?? size,
      backgroundColor: other.backgroundColor ?? backgroundColor,
      backgroundOpacity: other.backgroundOpacity ?? backgroundOpacity,
      containerSize: other.containerSize ?? containerSize,
      containerShape: other.containerShape ?? containerShape,
      borderRadius: other.borderRadius ?? borderRadius,
      border: other.border ?? border,
      borderColor: other.borderColor ?? borderColor,
      borderWidth: other.borderWidth ?? borderWidth,
      borderGradient: other.borderGradient ?? borderGradient,
      gradientBorderWidth: other.gradientBorderWidth ?? gradientBorderWidth,
      padding: other.padding ?? padding,
      gradient: other.gradient ?? gradient,
      gradientBlendMode: other.gradientBlendMode ?? gradientBlendMode,
      shadow: other.shadow ?? shadow,
      opacity: other.opacity ?? opacity,
      strokeWidth: other.strokeWidth ?? strokeWidth,
      strokeColor: other.strokeColor ?? strokeColor,
      strokeGradient: other.strokeGradient ?? strokeGradient,
      enableHaptic: other.enableHaptic ?? enableHaptic,
      animateIconChange: other.animateIconChange ?? animateIconChange,
      animationDuration: other.animationDuration ?? animationDuration,
      animationCurve: other.animationCurve ?? animationCurve,
    );
  }

  IconStyle copyWith({
    Color? color,
    double? size,
    Color? backgroundColor,
    double? backgroundOpacity,
    double? containerSize,
    IconContainerShape? containerShape,
    BorderRadius? borderRadius,
    BoxBorder? border,
    Color? borderColor,
    double? borderWidth,
    Gradient? borderGradient,
    double? gradientBorderWidth,
    EdgeInsets? padding,
    Gradient? gradient,
    BlendMode? gradientBlendMode,
    List<BoxShadow>? shadow,
    double? opacity,
    double? strokeWidth,
    Color? strokeColor,
    Gradient? strokeGradient,
    bool? enableHaptic,
    bool? animateIconChange,
    Duration? animationDuration,
    Curve? animationCurve,
  }) => IconStyle(
    color: color ?? this.color,
    size: size ?? this.size,
    backgroundColor: backgroundColor ?? this.backgroundColor,
    backgroundOpacity: backgroundOpacity ?? this.backgroundOpacity,
    containerSize: containerSize ?? this.containerSize,
    containerShape: containerShape ?? this.containerShape,
    borderRadius: borderRadius ?? this.borderRadius,
    border: border ?? this.border,
    borderColor: borderColor ?? this.borderColor,
    borderWidth: borderWidth ?? this.borderWidth,
    borderGradient: borderGradient ?? this.borderGradient,
    gradientBorderWidth: gradientBorderWidth ?? this.gradientBorderWidth,
    padding: padding ?? this.padding,
    gradient: gradient ?? this.gradient,
    gradientBlendMode: gradientBlendMode ?? this.gradientBlendMode,
    shadow: shadow ?? this.shadow,
    opacity: opacity ?? this.opacity,
    strokeWidth: strokeWidth ?? this.strokeWidth,
    strokeColor: strokeColor ?? this.strokeColor,
    strokeGradient: strokeGradient ?? this.strokeGradient,
    enableHaptic: enableHaptic ?? this.enableHaptic,
    animateIconChange: animateIconChange ?? this.animateIconChange,
    animationDuration: animationDuration ?? this.animationDuration,
    animationCurve: animationCurve ?? this.animationCurve,
  );
}

// ---------------------------------------------------------------------------
// ResolvedIconStyle
// ---------------------------------------------------------------------------

/// [IconStyle] after `caller > theme > defaults > palette`. Every themed
/// field is non-null, so build code reads `rs.size` with no `??` ladder
/// behind it.
@immutable
class ResolvedIconStyle {
  const ResolvedIconStyle({
    required this.color,
    required this.size,
    required this.backgroundOpacity,
    required this.containerShape,
    required this.gradientBorderWidth,
    required this.gradientBlendMode,
    required this.opacity,
    required this.enableHaptic,
    required this.animateIconChange,
    required this.animationDuration,
    required this.animationCurve,
    required this.strokeColor,
    required this.gradientBorderFill,
    this.backgroundColor,
    this.containerSize,
    this.borderRadius,
    this.border,
    this.borderGradient,
    this.padding,
    this.gradient,
    this.shadow,
    this.strokeWidth,
    this.strokeGradient,
  });

  final Color color;
  final double size;
  final double backgroundOpacity;
  final IconContainerShape containerShape;
  final double gradientBorderWidth;
  final BlendMode gradientBlendMode;
  final double opacity;
  final bool enableHaptic;

  final bool animateIconChange;
  final Duration animationDuration;
  final Curve animationCurve;

  /// Only paints when [strokeWidth] is set.
  final Color strokeColor;

  /// What fills the middle of a gradient-bordered box when the caller
  /// named no background — the surface the icon sits on, so the ring
  /// reads as a ring rather than a disc.
  final Color gradientBorderFill;

  final Color? backgroundColor;
  final double? containerSize;
  final BorderRadius? borderRadius;
  final BoxBorder? border;
  final Gradient? borderGradient;
  final EdgeInsets? padding;
  final Gradient? gradient;
  final List<BoxShadow>? shadow;
  final double? strokeWidth;
  final Gradient? strokeGradient;

  /// Whether anything is drawn behind the glyph at all.
  bool get hasContainer =>
      backgroundColor != null ||
      border != null ||
      borderGradient != null ||
      containerSize != null ||
      !containerShape.isNone;

  /// [backgroundColor] SCALED by [backgroundOpacity].
  ///
  /// Scaled, not overwritten. `withValues(alpha: backgroundOpacity)`
  /// threw away the alpha the caller had already put on the colour, so
  /// `backgroundColor: Colors.blue.withValues(alpha: 0.1)` — the way
  /// every tinted icon in this app is written — painted a fully opaque
  /// disc, and a glyph in the same blue disappeared into it.
  Color? get fillColor => backgroundColor?.withValues(alpha: _fillAlpha);

  double get _fillAlpha => (backgroundColor?.a ?? 1) * backgroundOpacity;

  /// Corner radius for the box, from the explicit one or the shape.
  BorderRadius get effectiveBorderRadius {
    if (borderRadius != null) return borderRadius!;
    return switch (containerShape) {
      IconContainerShape.none => BorderRadius.zero,
      IconContainerShape.circle => BorderRadius.circular(
        IconDefaults.circleRadius,
      ),
      IconContainerShape.rounded => BorderRadius.circular(
        IconDefaults.roundedRadius,
      ),
      IconContainerShape.square => BorderRadius.zero,
    };
  }

  /// Box the stroked glyph needs. A stroked path is centred on the
  /// outline, so it reaches half a width beyond the glyph on each side.
  double get strokedSize =>
      size + (strokeWidth ?? 0) * IconDefaults.strokeSpread;

  /// Whether [opacity] can be folded into the colours instead of being
  /// painted as a layer.
  ///
  /// An `Opacity` widget costs a `saveLayer` on what is usually a leaf
  /// in a list. Folding it into the alpha of every colour this draws is
  /// free — but only when every one of them IS a colour: a gradient has
  /// its own stops, and a badge is somebody else's subtree.
  bool get foldsOpacity =>
      gradient == null && strokeGradient == null && borderGradient == null;

  /// [c] at this bag's [opacity], for the fold above.
  Color faded(Color c) => opacity >= 1 ? c : c.withValues(alpha: c.a * opacity);
}
