import 'package:flutter/material.dart';

import '../radio_models.dart';

/// App-wide [RadioStyle] via `ThemeData.extensions` — the analogue of
/// `GlobalCheckboxTheme` / `GlobalSwitchTheme`. Per-instance `style:`
/// always wins; see [RadioStyle.resolve] for the merge order.
///
/// ```dart
/// ThemeData(extensions: [
///   GlobalRadioTheme(
///     style: RadioStyle(size: 20, enableHaptic: false),
///   ),
/// ]);
/// ```
class GlobalRadioTheme extends ThemeExtension<GlobalRadioTheme> {
  const GlobalRadioTheme({this.style});

  final RadioStyle? style;

  static GlobalRadioTheme? maybeOf(BuildContext context) =>
      Theme.of(context).extension<GlobalRadioTheme>();

  @override
  GlobalRadioTheme copyWith({RadioStyle? style}) =>
      GlobalRadioTheme(style: style ?? this.style);

  @override
  GlobalRadioTheme lerp(ThemeExtension<GlobalRadioTheme>? other, double t) {
    if (other is! GlobalRadioTheme) return this;
    return GlobalRadioTheme(style: _lerpStyle(style, other.style, t));
  }

  static RadioStyle? _lerpStyle(RadioStyle? a, RadioStyle? b, double t) {
    if (a == null && b == null) return null;
    if (a == null) return b;
    if (b == null) return a;
    return RadioStyle(
      size: _lerpDouble(a.size, b.size, t),
      borderWidth: _lerpDouble(a.borderWidth, b.borderWidth, t),
      selectedColor: Color.lerp(a.selectedColor, b.selectedColor, t),
      unselectedColor: Color.lerp(a.unselectedColor, b.unselectedColor, t),
      dotColor: Color.lerp(a.dotColor, b.dotColor, t),
      borderColor: Color.lerp(a.borderColor, b.borderColor, t),
      selectedBorderColor: Color.lerp(
        a.selectedBorderColor,
        b.selectedBorderColor,
        t,
      ),
      disabledColor: Color.lerp(a.disabledColor, b.disabledColor, t),
      hoverColor: Color.lerp(a.hoverColor, b.hoverColor, t),
      focusColor: Color.lerp(a.focusColor, b.focusColor, t),
      selectedGradient: Gradient.lerp(
        a.selectedGradient,
        b.selectedGradient,
        t,
      ),
      borderGradient: Gradient.lerp(a.borderGradient, b.borderGradient, t),
      selectedBorderGradient: Gradient.lerp(
        a.selectedBorderGradient,
        b.selectedBorderGradient,
        t,
      ),
      shadow: BoxShadow.lerpList(a.shadow, b.shadow, t),
      selectedShadow: BoxShadow.lerpList(a.selectedShadow, b.selectedShadow, t),
      animationDuration: t < 0.5 ? a.animationDuration : b.animationDuration,
      animationCurve: t < 0.5 ? a.animationCurve : b.animationCurve,
      scaleOnTap: t < 0.5 ? a.scaleOnTap : b.scaleOnTap,
      enableHaptic: t < 0.5 ? a.enableHaptic : b.enableHaptic,
      dotScale: _lerpDouble(a.dotScale, b.dotScale, t),
      checkIcon: t < 0.5 ? a.checkIcon : b.checkIcon,
      checkIconSize: _lerpDouble(a.checkIconSize, b.checkIconSize, t),
    );
  }

  static double? _lerpDouble(double? a, double? b, double t) {
    if (a == null && b == null) return null;
    return (a ?? b!) + ((b ?? a!) - (a ?? b!)) * t;
  }
}
