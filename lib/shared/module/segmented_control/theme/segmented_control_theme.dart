import 'package:flutter/material.dart';

import '../segmented_control_models.dart';

/// App-wide [SegmentedStyle] via `ThemeData.extensions`. Per-instance
/// `style:` always wins; see [SegmentedStyle.resolve] for the merge
/// order.
class GlobalSegmentedControlTheme
    extends ThemeExtension<GlobalSegmentedControlTheme> {
  const GlobalSegmentedControlTheme({this.style});

  final SegmentedStyle? style;

  static GlobalSegmentedControlTheme? maybeOf(BuildContext context) =>
      Theme.of(context).extension<GlobalSegmentedControlTheme>();

  @override
  GlobalSegmentedControlTheme copyWith({SegmentedStyle? style}) =>
      GlobalSegmentedControlTheme(style: style ?? this.style);

  @override
  GlobalSegmentedControlTheme lerp(
    ThemeExtension<GlobalSegmentedControlTheme>? other,
    double t,
  ) {
    if (other is! GlobalSegmentedControlTheme) return this;
    return GlobalSegmentedControlTheme(
      style: _lerpStyle(style, other.style, t),
    );
  }

  static SegmentedStyle? _lerpStyle(
    SegmentedStyle? a,
    SegmentedStyle? b,
    double t,
  ) {
    if (a == null && b == null) return null;
    if (a == null) return b;
    if (b == null) return a;
    return SegmentedStyle(
      backgroundColor: Color.lerp(a.backgroundColor, b.backgroundColor, t),
      backgroundGradient: Gradient.lerp(
        a.backgroundGradient,
        b.backgroundGradient,
        t,
      ),
      selectedColor: Color.lerp(a.selectedColor, b.selectedColor, t),
      selectedGradient: Gradient.lerp(
        a.selectedGradient,
        b.selectedGradient,
        t,
      ),
      selectedForegroundColor: Color.lerp(
        a.selectedForegroundColor,
        b.selectedForegroundColor,
        t,
      ),
      unselectedForegroundColor: Color.lerp(
        a.unselectedForegroundColor,
        b.unselectedForegroundColor,
        t,
      ),
      disabledColor: Color.lerp(a.disabledColor, b.disabledColor, t),
      indicatorShadow: BoxShadow.lerpList(
        a.indicatorShadow,
        b.indicatorShadow,
        t,
      ),
      borderColor: Color.lerp(a.borderColor, b.borderColor, t),
      borderGradient: Gradient.lerp(a.borderGradient, b.borderGradient, t),
      borderWidth: _lerpDouble(a.borderWidth, b.borderWidth, t),
      borderRadius: BorderRadius.lerp(a.borderRadius, b.borderRadius, t),
      height: _lerpDouble(a.height, b.height, t),
      sizePreset: t < 0.5 ? a.sizePreset : b.sizePreset,
      segmentPadding: EdgeInsets.lerp(a.segmentPadding, b.segmentPadding, t),
      indicatorPadding: _lerpDouble(a.indicatorPadding, b.indicatorPadding, t),
      animationDuration: t < 0.5 ? a.animationDuration : b.animationDuration,
      animationCurve: t < 0.5 ? a.animationCurve : b.animationCurve,
      selectedTextStyle: TextStyle.lerp(
        a.selectedTextStyle,
        b.selectedTextStyle,
        t,
      ),
      unselectedTextStyle: TextStyle.lerp(
        a.unselectedTextStyle,
        b.unselectedTextStyle,
        t,
      ),
      iconSize: _lerpDouble(a.iconSize, b.iconSize, t),
      iconSpacing: _lerpDouble(a.iconSpacing, b.iconSpacing, t),
      expandEqual: t < 0.5 ? a.expandEqual : b.expandEqual,
      enableHaptic: t < 0.5 ? a.enableHaptic : b.enableHaptic,
      shadow: BoxShadow.lerpList(a.shadow, b.shadow, t),
    );
  }

  static double? _lerpDouble(double? a, double? b, double t) {
    if (a == null && b == null) return null;
    return (a ?? b!) + ((b ?? a!) - (a ?? b!)) * t;
  }
}
