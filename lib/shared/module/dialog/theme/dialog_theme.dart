import 'package:flutter/material.dart';

import '../dialog_models.dart';

/// App-wide [DialogStyle] via `ThemeData.extensions`. Per-call
/// `style:` always wins; see [DialogStyle.resolve] for the merge
/// order.
class GlobalDialogTheme extends ThemeExtension<GlobalDialogTheme> {
  const GlobalDialogTheme({this.style});

  final DialogStyle? style;

  static GlobalDialogTheme? maybeOf(BuildContext context) =>
      Theme.of(context).extension<GlobalDialogTheme>();

  @override
  GlobalDialogTheme copyWith({DialogStyle? style}) =>
      GlobalDialogTheme(style: style ?? this.style);

  @override
  GlobalDialogTheme lerp(ThemeExtension<GlobalDialogTheme>? other, double t) {
    if (other is! GlobalDialogTheme) return this;
    return GlobalDialogTheme(style: _lerpStyle(style, other.style, t));
  }

  static DialogStyle? _lerpStyle(DialogStyle? a, DialogStyle? b, double t) {
    if (a == null && b == null) return null;
    if (a == null) return b;
    if (b == null) return a;
    return DialogStyle(
      backgroundColor: Color.lerp(a.backgroundColor, b.backgroundColor, t),
      backgroundGradient: Gradient.lerp(
        a.backgroundGradient,
        b.backgroundGradient,
        t,
      ),
      borderRadius: BorderRadius.lerp(a.borderRadius, b.borderRadius, t),
      border: t < 0.5 ? a.border : b.border,
      borderGradient: Gradient.lerp(a.borderGradient, b.borderGradient, t),
      borderWidth: _lerpDouble(a.borderWidth, b.borderWidth, t),
      maxWidth: _lerpDouble(a.maxWidth, b.maxWidth, t),
      maxHeight: _lerpDouble(a.maxHeight, b.maxHeight, t),
      padding: EdgeInsets.lerp(a.padding, b.padding, t),
      titleStyle: TextStyle.lerp(a.titleStyle, b.titleStyle, t),
      messageStyle: TextStyle.lerp(a.messageStyle, b.messageStyle, t),
      shadow: BoxShadow.lerpList(a.shadow, b.shadow, t),
      barrierColor: Color.lerp(a.barrierColor, b.barrierColor, t),
      animation: t < 0.5 ? a.animation : b.animation,
      animationDuration: t < 0.5 ? a.animationDuration : b.animationDuration,
      animationCurve: t < 0.5 ? a.animationCurve : b.animationCurve,
      dismissIndicator: t < 0.5 ? a.dismissIndicator : b.dismissIndicator,
      enableHaptic: t < 0.5 ? a.enableHaptic : b.enableHaptic,
    );
  }

  static double? _lerpDouble(double? a, double? b, double t) {
    if (a == null && b == null) return null;
    return (a ?? b!) + ((b ?? a!) - (a ?? b!)) * t;
  }
}
