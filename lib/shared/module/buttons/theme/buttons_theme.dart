import 'package:flutter/material.dart';

import '../button_loading_style.dart';
import '../button_state_style.dart';
import '../label_overflow.dart';
import '../swipe_button_style.dart';

/// App-wide base [ButtonStateStyle] per button variant via
/// `ThemeData.extensions`. Per-call `style:` always wins — each widget
/// merges `theme base ← caller style` (caller's non-null fields
/// override) before its own state resolution.
class GlobalButtonsTheme extends ThemeExtension<GlobalButtonsTheme> {
  const GlobalButtonsTheme({
    this.filledStyle,
    this.outlinedStyle,
    this.textStyle,
    this.iconStyle,
    this.disabledStyle,
    this.loadingStyle,
    this.successStyle,
    this.errorStyle,
    this.debounceDuration,
    this.enableHaptic,
    this.labelOverflow,
    this.swipeStyle,
  });

  /// Base bag for [GlobalFilledButton].
  final ButtonStateStyle? filledStyle;

  /// Base bag for [GlobalOutlinedButton].
  final ButtonStateStyle? outlinedStyle;

  /// Base bag for [GlobalTextButton].
  final ButtonStateStyle? textStyle;

  /// Base bag for [GlobalIconButton].
  final ButtonStateStyle? iconStyle;

  /// Base bag for `GlobalSwipeButton`.
  ///
  /// A bag of its OWN type: a swipe button has a track, a thumb and a
  /// distance to travel, and none of that is expressible in the
  /// per-state bag the other four share. Its per-state bags
  /// (`disabledStyle` and friends) are still the app-wide ones above.
  final SwipeButtonStyle? swipeStyle;

  /// App-wide disabled bag, applied to every variant. Per-call
  /// `disabledStyle:` merges over it.
  final ButtonStateStyle? disabledStyle;

  /// App-wide loading bag — lets an app say "every button loads with
  /// LoadingType.circular" once instead of at each call site.
  final ButtonLoadingStyle? loadingStyle;

  /// App-wide completion bags. Merged UNDER the built-in defaults, so a
  /// partial override keeps the checkmark/X and status colours.
  final ButtonStateStyle? successStyle;
  final ButtonStateStyle? errorStyle;

  /// App-wide default debounce window — per-call `debounceDuration:`
  /// wins. The showcase pages repeat the same 800ms in four files.
  final Duration? debounceDuration;

  /// App-wide haptic gate — per-call `enableHaptic:` wins.
  final bool? enableHaptic;

  /// App-wide answer to "what does a label do when it does not fit".
  /// Per-call `labelOverflow:` wins; the floor is
  /// [LabelOverflow.marquee].
  final LabelOverflow? labelOverflow;

  static GlobalButtonsTheme? maybeOf(BuildContext context) =>
      Theme.of(context).extension<GlobalButtonsTheme>();

  @override
  GlobalButtonsTheme copyWith({
    ButtonStateStyle? filledStyle,
    ButtonStateStyle? outlinedStyle,
    ButtonStateStyle? textStyle,
    ButtonStateStyle? iconStyle,
    ButtonStateStyle? disabledStyle,
    ButtonLoadingStyle? loadingStyle,
    ButtonStateStyle? successStyle,
    ButtonStateStyle? errorStyle,
    Duration? debounceDuration,
    bool? enableHaptic,
    LabelOverflow? labelOverflow,
    SwipeButtonStyle? swipeStyle,
  }) => GlobalButtonsTheme(
    filledStyle: filledStyle ?? this.filledStyle,
    outlinedStyle: outlinedStyle ?? this.outlinedStyle,
    textStyle: textStyle ?? this.textStyle,
    iconStyle: iconStyle ?? this.iconStyle,
    disabledStyle: disabledStyle ?? this.disabledStyle,
    loadingStyle: loadingStyle ?? this.loadingStyle,
    successStyle: successStyle ?? this.successStyle,
    errorStyle: errorStyle ?? this.errorStyle,
    debounceDuration: debounceDuration ?? this.debounceDuration,
    enableHaptic: enableHaptic ?? this.enableHaptic,
    labelOverflow: labelOverflow ?? this.labelOverflow,
    swipeStyle: swipeStyle ?? this.swipeStyle,
  );

  @override
  GlobalButtonsTheme lerp(ThemeExtension<GlobalButtonsTheme>? other, double t) {
    if (other is! GlobalButtonsTheme) return this;
    return GlobalButtonsTheme(
      filledStyle: lerpStateStyle(filledStyle, other.filledStyle, t),
      outlinedStyle: lerpStateStyle(outlinedStyle, other.outlinedStyle, t),
      textStyle: lerpStateStyle(textStyle, other.textStyle, t),
      iconStyle: lerpStateStyle(iconStyle, other.iconStyle, t),
      disabledStyle: lerpStateStyle(disabledStyle, other.disabledStyle, t),
      loadingStyle: t < 0.5 ? loadingStyle : other.loadingStyle,
      successStyle: lerpStateStyle(successStyle, other.successStyle, t),
      errorStyle: lerpStateStyle(errorStyle, other.errorStyle, t),
      debounceDuration: t < 0.5 ? debounceDuration : other.debounceDuration,
      enableHaptic: t < 0.5 ? enableHaptic : other.enableHaptic,
      labelOverflow: t < 0.5 ? labelOverflow : other.labelOverflow,
      // SNAPS, like every other bag of independent decisions here —
      // half a `fillTrack` means nothing.
      swipeStyle: t < 0.5 ? swipeStyle : other.swipeStyle,
    );
  }

  static ButtonStateStyle? lerpStateStyle(
    ButtonStateStyle? a,
    ButtonStateStyle? b,
    double t,
  ) {
    if (a == null && b == null) return null;
    if (a == null) return b;
    if (b == null) return a;
    return ButtonStateStyle(
      text: t < 0.5 ? a.text : b.text,
      backgroundColor: Color.lerp(a.backgroundColor, b.backgroundColor, t),
      backgroundGradient: Gradient.lerp(
        a.backgroundGradient,
        b.backgroundGradient,
        t,
      ),
      foregroundColor: Color.lerp(a.foregroundColor, b.foregroundColor, t),
      borderRadius: BorderRadiusGeometry.lerp(
        a.borderRadius,
        b.borderRadius,
        t,
      ),
      padding: EdgeInsetsGeometry.lerp(a.padding, b.padding, t),
      elevation: _lerpDouble(a.elevation, b.elevation, t),
      shadowColor: Color.lerp(a.shadowColor, b.shadowColor, t),
      border: BorderSide.lerp(
        a.border ?? BorderSide.none,
        b.border ?? BorderSide.none,
        t,
      ),
      borderGradient: Gradient.lerp(a.borderGradient, b.borderGradient, t),
      leading: t < 0.5 ? a.leading : b.leading,
      trailing: t < 0.5 ? a.trailing : b.trailing,
      textStyle: TextStyle.lerp(a.textStyle, b.textStyle, t),
      width: _lerpDouble(a.width, b.width, t),
      height: _lerpDouble(a.height, b.height, t),
    );
  }

  static double? _lerpDouble(double? a, double? b, double t) {
    if (a == null && b == null) return null;
    return (a ?? b!) + ((b ?? a!) - (a ?? b!)) * t;
  }
}
