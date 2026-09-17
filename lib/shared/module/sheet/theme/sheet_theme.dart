import 'package:flutter/material.dart';

import '../sheet_models.dart';

/// App-wide [SheetStyle] via `ThemeData.extensions`. Per-call
/// `style:` always wins; see [SheetStyle.resolve] for the merge
/// order.
class GlobalSheetTheme extends ThemeExtension<GlobalSheetTheme> {
  const GlobalSheetTheme({this.style});

  final SheetStyle? style;

  static GlobalSheetTheme? maybeOf(BuildContext context) =>
      Theme.of(context).extension<GlobalSheetTheme>();

  @override
  GlobalSheetTheme copyWith({SheetStyle? style}) =>
      GlobalSheetTheme(style: style ?? this.style);

  @override
  GlobalSheetTheme lerp(ThemeExtension<GlobalSheetTheme>? other, double t) {
    if (other is! GlobalSheetTheme) return this;
    return GlobalSheetTheme(style: _lerpStyle(style, other.style, t));
  }

  static SheetStyle? _lerpStyle(SheetStyle? a, SheetStyle? b, double t) {
    if (a == null && b == null) return null;
    if (a == null) return b;
    if (b == null) return a;
    return SheetStyle(
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
      shadow: BoxShadow.lerpList(a.shadow, b.shadow, t),
      handleColor: Color.lerp(a.handleColor, b.handleColor, t),
      showHandle: t < 0.5 ? a.showHandle : b.showHandle,
      handleWidth: _lerpDouble(a.handleWidth, b.handleWidth, t),
      handleHeight: _lerpDouble(a.handleHeight, b.handleHeight, t),
      floating: t < 0.5 ? a.floating : b.floating,
      floatingMargin: EdgeInsets.lerp(a.floatingMargin, b.floatingMargin, t),
      useDeviceRadius: t < 0.5 ? a.useDeviceRadius : b.useDeviceRadius,
      hideBottomBorder: t < 0.5 ? a.hideBottomBorder : b.hideBottomBorder,
      barrierColor: Color.lerp(a.barrierColor, b.barrierColor, t),
      contentPadding: EdgeInsets.lerp(a.contentPadding, b.contentPadding, t),
      animationDuration: t < 0.5 ? a.animationDuration : b.animationDuration,
      animationCurve: t < 0.5 ? a.animationCurve : b.animationCurve,
      enableHaptic: t < 0.5 ? a.enableHaptic : b.enableHaptic,
    );
  }

  static double? _lerpDouble(double? a, double? b, double t) {
    if (a == null && b == null) return null;
    return (a ?? b!) + ((b ?? a!) - (a ?? b!)) * t;
  }
}
