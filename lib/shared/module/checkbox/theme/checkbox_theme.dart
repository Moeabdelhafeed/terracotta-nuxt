import 'package:flutter/material.dart';

import '../checkbox_models.dart';

/// App-wide [CheckboxStyle] via `ThemeData.extensions` — the analogue of
/// `GlobalTextFieldTheme` / `GlobalDropdownTheme`. Per-instance `style:`
/// always wins; see [CheckboxStyle.resolve] for the merge order.
///
/// ```dart
/// ThemeData(extensions: [
///   GlobalCheckboxTheme(
///     style: CheckboxStyle(size: 20, enableHaptic: false),
///   ),
/// ]);
/// ```
class GlobalCheckboxTheme extends ThemeExtension<GlobalCheckboxTheme> {
  const GlobalCheckboxTheme({this.style});

  final CheckboxStyle? style;

  static GlobalCheckboxTheme? maybeOf(BuildContext context) =>
      Theme.of(context).extension<GlobalCheckboxTheme>();

  @override
  GlobalCheckboxTheme copyWith({CheckboxStyle? style}) =>
      GlobalCheckboxTheme(style: style ?? this.style);

  @override
  GlobalCheckboxTheme lerp(
    ThemeExtension<GlobalCheckboxTheme>? other,
    double t,
  ) {
    if (other is! GlobalCheckboxTheme) return this;
    return GlobalCheckboxTheme(style: _lerpStyle(style, other.style, t));
  }

  static CheckboxStyle? _lerpStyle(
    CheckboxStyle? a,
    CheckboxStyle? b,
    double t,
  ) {
    if (a == null && b == null) return null;
    if (a == null) return b;
    if (b == null) return a;
    return CheckboxStyle(
      size: _lerpDouble(a.size, b.size, t),
      borderWidth: _lerpDouble(a.borderWidth, b.borderWidth, t),
      borderRadius: BorderRadius.lerp(a.borderRadius, b.borderRadius, t),
      checkedColor: Color.lerp(a.checkedColor, b.checkedColor, t),
      uncheckedColor: Color.lerp(a.uncheckedColor, b.uncheckedColor, t),
      checkColor: Color.lerp(a.checkColor, b.checkColor, t),
      borderColor: Color.lerp(a.borderColor, b.borderColor, t),
      checkedBorderColor: Color.lerp(
        a.checkedBorderColor,
        b.checkedBorderColor,
        t,
      ),
      disabledColor: Color.lerp(a.disabledColor, b.disabledColor, t),
      hoverColor: Color.lerp(a.hoverColor, b.hoverColor, t),
      focusColor: Color.lerp(a.focusColor, b.focusColor, t),
      checkedGradient: Gradient.lerp(a.checkedGradient, b.checkedGradient, t),
      borderGradient: Gradient.lerp(a.borderGradient, b.borderGradient, t),
      checkedBorderGradient: Gradient.lerp(
        a.checkedBorderGradient,
        b.checkedBorderGradient,
        t,
      ),
      shadow: BoxShadow.lerpList(a.shadow, b.shadow, t),
      checkedShadow: BoxShadow.lerpList(a.checkedShadow, b.checkedShadow, t),
      animationDuration: t < 0.5 ? a.animationDuration : b.animationDuration,
      animationCurve: t < 0.5 ? a.animationCurve : b.animationCurve,
      checkIcon: t < 0.5 ? a.checkIcon : b.checkIcon,
      indeterminateIcon: t < 0.5 ? a.indeterminateIcon : b.indeterminateIcon,
      iconSize: _lerpDouble(a.iconSize, b.iconSize, t),
      scaleOnTap: t < 0.5 ? a.scaleOnTap : b.scaleOnTap,
      enableHaptic: t < 0.5 ? a.enableHaptic : b.enableHaptic,
    );
  }

  static double? _lerpDouble(double? a, double? b, double t) {
    if (a == null && b == null) return null;
    return (a ?? b!) + ((b ?? a!) - (a ?? b!)) * t;
  }
}
