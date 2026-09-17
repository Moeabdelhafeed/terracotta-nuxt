import 'package:flutter/material.dart';

// ---------------------------------------------------------------------------
// Enums
// ---------------------------------------------------------------------------

/// Shape of the marks drawn at each division.
enum SliderTickShape {
  /// A dot.
  circle,

  /// A short bar crossing the track — easier to see on a thick one.
  line,
}

/// Shape of the bubble that follows the thumb while it is dragged.
enum SliderIndicatorShape {
  /// Flutter's own paddle.
  paddle,

  /// A rounded rectangle.
  rounded,

  /// A rounded rectangle with an arrow pointing back at the thumb.
  bubble,
}

// ---------------------------------------------------------------------------
// SliderTickStyle
// ---------------------------------------------------------------------------

/// How the division marks look.
///
/// A sub-bag rather than four fields on [SliderStyle], because ticks are
/// one cohesive decision — the same reason `EdgeFadeStyle` is its own
/// object in `scrollable/`. Every field is nullable, so a theme and a
/// caller layer here the way they layer everywhere else.
@immutable
class SliderTickStyle {
  const SliderTickStyle({
    this.color,
    this.activeColor,
    this.radius,
    this.shape,
  });

  /// Marks on the unfilled part of the track.
  final Color? color;

  /// Marks on the FILLED part, which sit on the accent and so need a
  /// colour that reads against it.
  final Color? activeColor;

  final double? radius;
  final SliderTickShape? shape;

  SliderTickStyle mergedWith(SliderTickStyle? other) {
    if (other == null) return this;
    return SliderTickStyle(
      color: other.color ?? color,
      activeColor: other.activeColor ?? activeColor,
      radius: other.radius ?? radius,
      shape: other.shape ?? shape,
    );
  }

  SliderTickStyle copyWith({
    Color? color,
    Color? activeColor,
    double? radius,
    SliderTickShape? shape,
  }) => SliderTickStyle(
    color: color ?? this.color,
    activeColor: activeColor ?? this.activeColor,
    radius: radius ?? this.radius,
    shape: shape ?? this.shape,
  );

  @override
  bool operator ==(Object other) =>
      other is SliderTickStyle &&
      other.color == color &&
      other.activeColor == activeColor &&
      other.radius == radius &&
      other.shape == shape;

  @override
  int get hashCode => Object.hash(color, activeColor, radius, shape);
}

/// [SliderTickStyle] with every question answered.
@immutable
class ResolvedSliderTickStyle {
  const ResolvedSliderTickStyle({
    required this.color,
    required this.activeColor,
    required this.radius,
    required this.shape,
  });

  final Color color;
  final Color activeColor;
  final double radius;
  final SliderTickShape shape;
}

// ---------------------------------------------------------------------------
// SliderIndicatorStyle
// ---------------------------------------------------------------------------

/// How the drag bubble looks.
@immutable
class SliderIndicatorStyle {
  const SliderIndicatorStyle({
    this.shape,
    this.color,
    this.gradient,
    this.textStyle,
    this.borderRadius,
    this.padding,
    this.arrowSize,
    this.verticalOffset,
  });

  final SliderIndicatorShape? shape;

  /// Solid fill. [gradient] wins over it.
  final Color? color;
  final Gradient? gradient;

  final TextStyle? textStyle;
  final double? borderRadius;
  final EdgeInsets? padding;

  /// The point on a [SliderIndicatorShape.bubble].
  final double? arrowSize;

  /// How far above the thumb it floats.
  final double? verticalOffset;

  SliderIndicatorStyle mergedWith(SliderIndicatorStyle? other) {
    if (other == null) return this;
    return SliderIndicatorStyle(
      shape: other.shape ?? shape,
      color: other.color ?? color,
      gradient: other.gradient ?? gradient,
      textStyle: other.textStyle ?? textStyle,
      borderRadius: other.borderRadius ?? borderRadius,
      padding: other.padding ?? padding,
      arrowSize: other.arrowSize ?? arrowSize,
      verticalOffset: other.verticalOffset ?? verticalOffset,
    );
  }

  SliderIndicatorStyle copyWith({
    SliderIndicatorShape? shape,
    Color? color,
    Gradient? gradient,
    TextStyle? textStyle,
    double? borderRadius,
    EdgeInsets? padding,
    double? arrowSize,
    double? verticalOffset,
  }) => SliderIndicatorStyle(
    shape: shape ?? this.shape,
    color: color ?? this.color,
    gradient: gradient ?? this.gradient,
    textStyle: textStyle ?? this.textStyle,
    borderRadius: borderRadius ?? this.borderRadius,
    padding: padding ?? this.padding,
    arrowSize: arrowSize ?? this.arrowSize,
    verticalOffset: verticalOffset ?? this.verticalOffset,
  );

  @override
  bool operator ==(Object other) =>
      other is SliderIndicatorStyle &&
      other.shape == shape &&
      other.color == color &&
      other.gradient == gradient &&
      other.textStyle == textStyle &&
      other.borderRadius == borderRadius &&
      other.padding == padding &&
      other.arrowSize == arrowSize &&
      other.verticalOffset == verticalOffset;

  @override
  int get hashCode => Object.hash(
    shape,
    color,
    gradient,
    textStyle,
    borderRadius,
    padding,
    arrowSize,
    verticalOffset,
  );
}

/// [SliderIndicatorStyle] with every question answered.
///
/// [gradient] stays nullable — a flat fill is a legitimate answer, and
/// collapsing it into a one-stop gradient would cost a shader for
/// nothing.
@immutable
class ResolvedSliderIndicatorStyle {
  const ResolvedSliderIndicatorStyle({
    required this.shape,
    required this.color,
    required this.textStyle,
    required this.borderRadius,
    required this.padding,
    required this.arrowSize,
    required this.verticalOffset,
    this.gradient,
  });

  final SliderIndicatorShape shape;
  final Color color;
  final Gradient? gradient;
  final TextStyle textStyle;
  final double borderRadius;
  final EdgeInsets padding;
  final double arrowSize;
  final double verticalOffset;
}

// ---------------------------------------------------------------------------
// SliderMath — the arithmetic, without a widget
// ---------------------------------------------------------------------------

/// What the slider works out about its own value.
///
/// Pure and named, because none of it could be tested where it was: a
/// slider needs a laid-out `RenderBox` and a gesture, so a division
/// miscount or a mirrored fill only ever showed up on a device.
abstract final class SliderMath {
  /// Which division [value] sits on, or null when the slider is
  /// continuous.
  ///
  /// Used to decide when to tick: a haptic on every pixel of a drag is
  /// a buzz, and one per STEP is the thing a discrete slider is for.
  static int? divisionIndex(
    double value, {
    required double min,
    required double max,
    int? divisions,
  }) {
    if (divisions == null || divisions <= 0 || max <= min) return null;
    final t = ((value - min) / (max - min)).clamp(0.0, 1.0);
    return (t * divisions).round();
  }

  /// [value] as a fraction of the track, 0 at [min] and 1 at [max].
  static double fraction(
    double value, {
    required double min,
    required double max,
  }) => max <= min ? 0 : ((value - min) / (max - min)).clamp(0.0, 1.0);

  /// The filled span of a track running from [trackLeft] to
  /// [trackRight], for a thumb at [thumbX].
  ///
  /// RTL fills from the RIGHT. The gradient painters took the left edge
  /// as the origin unconditionally, so an Arabic slider drew its fill
  /// on the empty side — and the `textDirection` they were handed went
  /// unread in all six paint methods.
  static ({double start, double end}) activeSpan({
    required double trackLeft,
    required double trackRight,
    required double thumbX,
    required bool rtl,
  }) =>
      rtl ? (start: thumbX, end: trackRight) : (start: trackLeft, end: thumbX);

  /// Whether a tick at [tickX] is on the filled side of [thumbX].
  static bool tickIsActive({
    required double tickX,
    required double thumbX,
    required bool rtl,
  }) => rtl ? tickX >= thumbX : tickX <= thumbX;
}
