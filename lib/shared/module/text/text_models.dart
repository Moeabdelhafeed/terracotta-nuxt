import 'package:flutter/material.dart';

/// Per-character reveal step for `GlobalTypewriterText`. Module-local
/// because it is a cadence, not one of the shared transition presets.
const kTypewriterCharDuration = Duration(milliseconds: 50);

/// How long `GlobalCounterText` takes to roll to its new value — longer
/// than any UI transition on purpose, so the count is readable in flight.
const kCounterRollDuration = Duration(milliseconds: 1200);

/// Predefined text style presets based on Material Design typography.
enum TextPreset {
  displayLarge,
  displayMedium,
  displaySmall,
  headlineLarge,
  headlineMedium,
  headlineSmall,
  titleLarge,
  titleMedium,
  titleSmall,
  bodyLarge,
  bodyMedium,
  bodySmall,
  labelLarge,
  labelMedium,
  labelSmall,
}

/// Decoration applied to the text (underline, strikethrough, highlight).
enum TextDecorationType {
  none,
  underline,
  strikethrough,
  highlight,
  doubleUnderline,
}

/// Themeable styling bag for [GlobalText] — EVERY field nullable.
///
/// Resolution order, materialized once per build by [resolve]:
/// `caller > GlobalTextTheme.style > GlobalTextStyle.defaults >
/// `context.<group>Colors` / tokens.
///
/// Adding a themed field means touching five places: here,
/// [mergedWith], [copyWith], [ResolvedGlobalTextStyle], and
/// `GlobalTextTheme.lerp`.
@immutable
class GlobalTextStyle {
  const GlobalTextStyle({
    this.color,
    this.fontFamily,
    this.fontSize,
    this.fontWeight,
    this.fontStyle,
    this.letterSpacing,
    this.wordSpacing,
    this.height,
    this.gradient,
    this.decoration,
    this.decorationColor,
    this.highlightColor,
    this.highlightPadding,
    this.highlightBorderRadius,
    this.shadow,
    this.leadingIcon,
    this.trailingIcon,
    this.iconSize,
    this.iconColor,
    this.iconSpacing,
    this.strokeColor,
    this.strokeGradient,
    this.strokeWidth,
  });

  /// Compile-time floor. Colors are deliberately absent — they fall back
  /// to `context.<group>Colors` at resolve time so they track the active
  /// palette, role and saturation instead of freezing a constant.
  static const GlobalTextStyle defaults = GlobalTextStyle(
    decoration: TextDecorationType.none,
    highlightPadding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
    iconSize: 16,
    iconSpacing: 6,
    strokeWidth: 0,
  );

  /// Text color. Overridden by [gradient] when set.
  final Color? color;

  /// Font family override.
  ///
  /// Null means "whatever the resolved preset supplies", which is the
  /// per-locale family from `AppFonts`. Pin it only to render a sample
  /// in a family other than the active locale's.
  final String? fontFamily;

  /// Font size in logical pixels.
  final double? fontSize;

  /// Font weight.
  final FontWeight? fontWeight;

  /// Font style (normal or italic).
  final FontStyle? fontStyle;

  /// Letter spacing.
  final double? letterSpacing;

  /// Word spacing.
  final double? wordSpacing;

  /// Line height multiplier.
  final double? height;

  /// Gradient fill for the text. Overrides [color].
  final Gradient? gradient;

  /// Text decoration (underline, strikethrough, highlight).
  final TextDecorationType? decoration;

  /// Color for underline/strikethrough decoration.
  final Color? decorationColor;

  /// Background color for highlight decoration.
  final Color? highlightColor;

  /// Padding around highlight.
  final EdgeInsets? highlightPadding;

  /// Border radius for highlight.
  final BorderRadius? highlightBorderRadius;

  /// Text shadow.
  final List<Shadow>? shadow;

  /// Icon displayed before the text.
  final IconData? leadingIcon;

  /// Icon displayed after the text.
  final IconData? trailingIcon;

  /// Size of leading/trailing icons.
  final double? iconSize;

  /// Color of leading/trailing icons. Defaults to text color.
  final Color? iconColor;

  /// Spacing between icon and text.
  final double? iconSpacing;

  /// Stroke/outline color around the text.
  final Color? strokeColor;

  /// Gradient stroke around the text. Overrides [strokeColor].
  final Gradient? strokeGradient;

  /// Width of the stroke. 0 = no stroke.
  final double? strokeWidth;

  /// `other` wins field by field.
  GlobalTextStyle mergedWith(GlobalTextStyle? other) {
    if (other == null) return this;
    return GlobalTextStyle(
      color: other.color ?? color,
      fontFamily: other.fontFamily ?? fontFamily,
      fontSize: other.fontSize ?? fontSize,
      fontWeight: other.fontWeight ?? fontWeight,
      fontStyle: other.fontStyle ?? fontStyle,
      letterSpacing: other.letterSpacing ?? letterSpacing,
      wordSpacing: other.wordSpacing ?? wordSpacing,
      height: other.height ?? height,
      gradient: other.gradient ?? gradient,
      decoration: other.decoration ?? decoration,
      decorationColor: other.decorationColor ?? decorationColor,
      highlightColor: other.highlightColor ?? highlightColor,
      highlightPadding: other.highlightPadding ?? highlightPadding,
      highlightBorderRadius:
          other.highlightBorderRadius ?? highlightBorderRadius,
      shadow: other.shadow ?? shadow,
      leadingIcon: other.leadingIcon ?? leadingIcon,
      trailingIcon: other.trailingIcon ?? trailingIcon,
      iconSize: other.iconSize ?? iconSize,
      iconColor: other.iconColor ?? iconColor,
      iconSpacing: other.iconSpacing ?? iconSpacing,
      strokeColor: other.strokeColor ?? strokeColor,
      strokeGradient: other.strokeGradient ?? strokeGradient,
      strokeWidth: other.strokeWidth ?? strokeWidth,
    );
  }

  GlobalTextStyle copyWith({
    Color? color,
    String? fontFamily,
    double? fontSize,
    FontWeight? fontWeight,
    FontStyle? fontStyle,
    double? letterSpacing,
    double? wordSpacing,
    double? height,
    Gradient? gradient,
    TextDecorationType? decoration,
    Color? decorationColor,
    Color? highlightColor,
    EdgeInsets? highlightPadding,
    BorderRadius? highlightBorderRadius,
    List<Shadow>? shadow,
    IconData? leadingIcon,
    IconData? trailingIcon,
    double? iconSize,
    Color? iconColor,
    double? iconSpacing,
    Color? strokeColor,
    Gradient? strokeGradient,
    double? strokeWidth,
  }) {
    return GlobalTextStyle(
      color: color ?? this.color,
      fontFamily: fontFamily ?? this.fontFamily,
      fontSize: fontSize ?? this.fontSize,
      fontWeight: fontWeight ?? this.fontWeight,
      fontStyle: fontStyle ?? this.fontStyle,
      letterSpacing: letterSpacing ?? this.letterSpacing,
      wordSpacing: wordSpacing ?? this.wordSpacing,
      height: height ?? this.height,
      gradient: gradient ?? this.gradient,
      decoration: decoration ?? this.decoration,
      decorationColor: decorationColor ?? this.decorationColor,
      highlightColor: highlightColor ?? this.highlightColor,
      highlightPadding: highlightPadding ?? this.highlightPadding,
      highlightBorderRadius:
          highlightBorderRadius ?? this.highlightBorderRadius,
      shadow: shadow ?? this.shadow,
      leadingIcon: leadingIcon ?? this.leadingIcon,
      trailingIcon: trailingIcon ?? this.trailingIcon,
      iconSize: iconSize ?? this.iconSize,
      iconColor: iconColor ?? this.iconColor,
      iconSpacing: iconSpacing ?? this.iconSpacing,
      strokeColor: strokeColor ?? this.strokeColor,
      strokeGradient: strokeGradient ?? this.strokeGradient,
      strokeWidth: strokeWidth ?? this.strokeWidth,
    );
  }
}

/// Materialized [GlobalTextStyle] — every themed field non-null.
///
/// Build code reads this and never re-derives a fallback, so there is
/// exactly one place where "what colour is this text" is decided.
@immutable
class ResolvedGlobalTextStyle {
  const ResolvedGlobalTextStyle({
    required this.decoration,
    required this.highlightPadding,
    required this.highlightBorderRadius,
    required this.highlightColor,
    required this.iconSize,
    required this.iconSpacing,
    required this.strokeWidth,
    required this.raw,
  });

  final TextDecorationType decoration;
  final EdgeInsets highlightPadding;
  final BorderRadius highlightBorderRadius;
  final Color highlightColor;
  final double iconSize;
  final double iconSpacing;
  final double strokeWidth;

  /// The merged bag, for the genuinely opt-in fields (color, gradient,
  /// shadow, icons …) that stay null when nobody asked for them.
  final GlobalTextStyle raw;

  Color? get color => raw.color;
  String? get fontFamily => raw.fontFamily;
  double? get fontSize => raw.fontSize;
  FontWeight? get fontWeight => raw.fontWeight;
  FontStyle? get fontStyle => raw.fontStyle;
  double? get letterSpacing => raw.letterSpacing;
  double? get wordSpacing => raw.wordSpacing;
  double? get height => raw.height;
  Gradient? get gradient => raw.gradient;
  Color? get decorationColor => raw.decorationColor;
  List<Shadow>? get shadow => raw.shadow;
  IconData? get leadingIcon => raw.leadingIcon;
  IconData? get trailingIcon => raw.trailingIcon;
  Color? get iconColor => raw.iconColor;
  Color? get strokeColor => raw.strokeColor;
  Gradient? get strokeGradient => raw.strokeGradient;

  bool get hasStroke =>
      strokeWidth > 0 && (strokeColor != null || strokeGradient != null);
}

/// A segment of rich text with its own style overrides.
class TextSegment {
  const TextSegment(
    this.text, {
    this.color,
    this.fontWeight,
    this.fontStyle,
    this.fontSize,
    this.decoration,
    this.decorationColor,
    this.onTap,
  });

  /// The text content.
  final String text;

  /// Override color for this segment.
  final Color? color;

  /// Override weight for this segment.
  final FontWeight? fontWeight;

  /// Override style for this segment.
  final FontStyle? fontStyle;

  /// Override font size.
  final double? fontSize;

  /// Text decoration for this segment.
  final TextDecoration? decoration;

  /// Decoration color.
  final Color? decorationColor;

  /// Tap callback — makes this segment tappable (like a link).
  final VoidCallback? onTap;

  /// Bold segment shorthand.
  const TextSegment.bold(this.text, {this.color, this.fontSize, this.onTap})
    : fontWeight = FontWeight.w700,
      fontStyle = null,
      decoration = null,
      decorationColor = null;

  /// Italic segment shorthand.
  const TextSegment.italic(this.text, {this.color, this.fontSize, this.onTap})
    : fontWeight = null,
      fontStyle = FontStyle.italic,
      decoration = null,
      decorationColor = null;

  /// Link-styled segment shorthand.
  TextSegment.link(this.text, {this.color, this.onTap, this.fontSize})
    : fontWeight = null,
      fontStyle = null,
      decoration = TextDecoration.underline,
      decorationColor = color;
}

/// Built-in text animation types for [GlobalAnimatedText].
enum TextAnimation {
  /// Fade in from transparent.
  fadeIn,

  /// Fade out to transparent.
  fadeOut,

  /// Slide in from the left.
  slideLeft,

  /// Slide in from the right.
  slideRight,

  /// Slide in from the top.
  slideUp,

  /// Slide in from the bottom.
  slideDown,

  /// Scale up from small.
  scaleUp,

  /// Scale down from large.
  scaleDown,

  /// Rotate in (360 degrees).
  rotate,

  /// Combined fade + slide up.
  fadeSlideUp,

  /// Combined fade + slide down.
  fadeSlideDown,

  /// Combined fade + scale up.
  fadeScale,

  /// Bounce effect.
  bounce,

  /// Elastic spring effect.
  elastic,

  /// Flip horizontally.
  flipH,

  /// Flip vertically.
  flipV,

  /// Blur in from blurry to clear.
  blur,
}
