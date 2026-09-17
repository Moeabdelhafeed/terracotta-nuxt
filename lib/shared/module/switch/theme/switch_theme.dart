import 'package:flutter/material.dart';

import '../switch_models.dart';

/// App-wide [SwitchStyle] via `ThemeData.extensions` — the analogue of
/// `GlobalCheckboxTheme` / `GlobalTextFieldTheme`. Per-instance `style:`
/// always wins; see [SwitchStyle.resolve] for the merge order.
///
/// ```dart
/// ThemeData(extensions: [
///   GlobalSwitchTheme(
///     style: SwitchStyle(elevation: 0, enableHaptic: false),
///   ),
/// ]);
/// ```
class GlobalSwitchTheme extends ThemeExtension<GlobalSwitchTheme> {
  const GlobalSwitchTheme({this.style});

  final SwitchStyle? style;

  static GlobalSwitchTheme? maybeOf(BuildContext context) =>
      Theme.of(context).extension<GlobalSwitchTheme>();

  @override
  GlobalSwitchTheme copyWith({SwitchStyle? style}) =>
      GlobalSwitchTheme(style: style ?? this.style);

  @override
  GlobalSwitchTheme lerp(ThemeExtension<GlobalSwitchTheme>? other, double t) {
    if (other is! GlobalSwitchTheme) return this;
    return GlobalSwitchTheme(style: _lerpStyle(style, other.style, t));
  }

  static SwitchStyle? _lerpStyle(SwitchStyle? a, SwitchStyle? b, double t) {
    if (a == null && b == null) return null;
    if (a == null) return b;
    if (b == null) return a;
    return SwitchStyle(
      width: _lerpDouble(a.width, b.width, t),
      height: _lerpDouble(a.height, b.height, t),
      thumbSize: _lerpDouble(a.thumbSize, b.thumbSize, t),
      padding: EdgeInsets.lerp(a.padding, b.padding, t),
      borderRadius: _lerpDouble(a.borderRadius, b.borderRadius, t),
      trackShape: t < 0.5 ? a.trackShape : b.trackShape,
      customTrackBorderRadius: BorderRadius.lerp(
        a.customTrackBorderRadius,
        b.customTrackBorderRadius,
        t,
      ),
      thumbShape: t < 0.5 ? a.thumbShape : b.thumbShape,
      customThumbBorderRadius: BorderRadius.lerp(
        a.customThumbBorderRadius,
        b.customThumbBorderRadius,
        t,
      ),
      activeColor: Color.lerp(a.activeColor, b.activeColor, t),
      inactiveColor: Color.lerp(a.inactiveColor, b.inactiveColor, t),
      gradient: Gradient.lerp(a.gradient, b.gradient, t),
      activeGradient: Gradient.lerp(a.activeGradient, b.activeGradient, t),
      inactiveGradient: Gradient.lerp(
        a.inactiveGradient,
        b.inactiveGradient,
        t,
      ),
      thumbColor: Color.lerp(a.thumbColor, b.thumbColor, t),
      activeThumbColor: Color.lerp(a.activeThumbColor, b.activeThumbColor, t),
      inactiveThumbColor: Color.lerp(
        a.inactiveThumbColor,
        b.inactiveThumbColor,
        t,
      ),
      thumbGradient: Gradient.lerp(a.thumbGradient, b.thumbGradient, t),
      activeThumbGradient: Gradient.lerp(
        a.activeThumbGradient,
        b.activeThumbGradient,
        t,
      ),
      inactiveThumbGradient: Gradient.lerp(
        a.inactiveThumbGradient,
        b.inactiveThumbGradient,
        t,
      ),
      borderWidth: _lerpDouble(a.borderWidth, b.borderWidth, t),
      borderColor: Color.lerp(a.borderColor, b.borderColor, t),
      activeBorderColor: Color.lerp(
        a.activeBorderColor,
        b.activeBorderColor,
        t,
      ),
      inactiveBorderColor: Color.lerp(
        a.inactiveBorderColor,
        b.inactiveBorderColor,
        t,
      ),
      borderGradient: Gradient.lerp(a.borderGradient, b.borderGradient, t),
      activeBorderGradient: Gradient.lerp(
        a.activeBorderGradient,
        b.activeBorderGradient,
        t,
      ),
      inactiveBorderGradient: Gradient.lerp(
        a.inactiveBorderGradient,
        b.inactiveBorderGradient,
        t,
      ),
      elevation: _lerpDouble(a.elevation, b.elevation, t),
      shadowColor: Color.lerp(a.shadowColor, b.shadowColor, t),
      thumbShadow: t < 0.5 ? a.thumbShadow : b.thumbShadow,
      animationDuration: t < 0.5 ? a.animationDuration : b.animationDuration,
      animationCurve: t < 0.5 ? a.animationCurve : b.animationCurve,
      animateThumbSize: t < 0.5 ? a.animateThumbSize : b.animateThumbSize,
      iconSize: _lerpDouble(a.iconSize, b.iconSize, t),
      iconColor: Color.lerp(a.iconColor, b.iconColor, t),
      activeIconColor: Color.lerp(a.activeIconColor, b.activeIconColor, t),
      inactiveIconColor: Color.lerp(
        a.inactiveIconColor,
        b.inactiveIconColor,
        t,
      ),
      labelStyle: TextStyle.lerp(a.labelStyle, b.labelStyle, t),
      trackLabelStyle: TextStyle.lerp(a.trackLabelStyle, b.trackLabelStyle, t),
      thumbTextStyle: TextStyle.lerp(a.thumbTextStyle, b.thumbTextStyle, t),
      enableHaptic: t < 0.5 ? a.enableHaptic : b.enableHaptic,
      hoverColor: Color.lerp(a.hoverColor, b.hoverColor, t),
      focusColor: Color.lerp(a.focusColor, b.focusColor, t),
      pulseColor: Color.lerp(a.pulseColor, b.pulseColor, t),
    );
  }

  static double? _lerpDouble(double? a, double? b, double t) {
    if (a == null && b == null) return null;
    return (a ?? b!) + ((b ?? a!) - (a ?? b!)) * t;
  }
}
