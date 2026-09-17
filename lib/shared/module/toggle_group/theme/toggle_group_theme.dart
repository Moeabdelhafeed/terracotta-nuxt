import 'package:flutter/material.dart';

import '../toggle_group_models.dart';

/// App-wide [ToggleGroupStyle] via `ThemeData.extensions`. Per-instance
/// `style:` always wins; see [ToggleGroupStyle.resolve] for the merge
/// order.
class GlobalToggleGroupTheme extends ThemeExtension<GlobalToggleGroupTheme> {
  const GlobalToggleGroupTheme({this.style});

  final ToggleGroupStyle? style;

  static GlobalToggleGroupTheme? maybeOf(BuildContext context) =>
      Theme.of(context).extension<GlobalToggleGroupTheme>();

  @override
  GlobalToggleGroupTheme copyWith({ToggleGroupStyle? style}) =>
      GlobalToggleGroupTheme(style: style ?? this.style);

  @override
  GlobalToggleGroupTheme lerp(
    ThemeExtension<GlobalToggleGroupTheme>? other,
    double t,
  ) {
    if (other is! GlobalToggleGroupTheme) return this;
    return GlobalToggleGroupTheme(style: _lerpStyle(style, other.style, t));
  }

  static ToggleGroupStyle? _lerpStyle(
    ToggleGroupStyle? a,
    ToggleGroupStyle? b,
    double t,
  ) {
    if (a == null && b == null) return null;
    if (a == null) return b;
    if (b == null) return a;
    return ToggleGroupStyle(
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
      unselectedColor: Color.lerp(a.unselectedColor, b.unselectedColor, t),
      unselectedForegroundColor: Color.lerp(
        a.unselectedForegroundColor,
        b.unselectedForegroundColor,
        t,
      ),
      disabledColor: Color.lerp(a.disabledColor, b.disabledColor, t),
      borderColor: Color.lerp(a.borderColor, b.borderColor, t),
      borderGradient: Gradient.lerp(a.borderGradient, b.borderGradient, t),
      borderWidth: _lerpDouble(a.borderWidth, b.borderWidth, t),
      borderRadius: BorderRadius.lerp(a.borderRadius, b.borderRadius, t),
      height: _lerpDouble(a.height, b.height, t),
      iconSize: _lerpDouble(a.iconSize, b.iconSize, t),
      iconSpacing: _lerpDouble(a.iconSpacing, b.iconSpacing, t),
      itemPadding: EdgeInsets.lerp(a.itemPadding, b.itemPadding, t),
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
      showDividers: t < 0.5 ? a.showDividers : b.showDividers,
      shadow: BoxShadow.lerpList(a.shadow, b.shadow, t),
      animationDuration: t < 0.5 ? a.animationDuration : b.animationDuration,
      animationCurve: t < 0.5 ? a.animationCurve : b.animationCurve,
      enableHaptic: t < 0.5 ? a.enableHaptic : b.enableHaptic,
      expandEqual: t < 0.5 ? a.expandEqual : b.expandEqual,
    );
  }

  static double? _lerpDouble(double? a, double? b, double t) {
    if (a == null && b == null) return null;
    return (a ?? b!) + ((b ?? a!) - (a ?? b!)) * t;
  }
}
