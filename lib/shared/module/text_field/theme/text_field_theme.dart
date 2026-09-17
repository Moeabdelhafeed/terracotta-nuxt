import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';

import '../models/text_field_style.dart';

/// App-wide visual defaults for [GlobalTextFormField].
///
/// Register on `ThemeData.extensions`:
/// ```dart
/// ThemeData(extensions: [
///   GlobalTextFieldTheme(
///     style: const TextFieldStyle(borderRadius: ..., fillColor: ...),
///     animationDuration: AppDurations.quick,
///   ),
/// ]);
/// ```
///
/// Resolution order at build time (see [TextFieldStyle.resolve]):
/// 1. Per-instance `TextFieldStyle` field (if non-null)
/// 2. This theme's [style] field of the same name (if non-null)
/// 3. Context-derived fallback / [TextFieldStyle.defaults].
///
/// The whole themeable surface lives on [style] (the text-field analogue
/// of `GlobalPopupTheme.surface`) so adopters rebrand every field in the
/// app at the theme layer instead of repeating overrides per call site.
@immutable
class GlobalTextFieldTheme extends ThemeExtension<GlobalTextFieldTheme> {
  const GlobalTextFieldTheme({this.style, this.animationDuration});

  /// Themeable visual bag. Every field nullable; merged per-field with the
  /// per-call style.
  final TextFieldStyle? style;

  /// Default duration for the field's micro-animations (shake, pulse,
  /// requirement reveal, strength bar). Currently advisory — surfaces read
  /// it where they accept a duration override.
  final Duration? animationDuration;

  static GlobalTextFieldTheme? maybeOf(BuildContext context) {
    return Theme.of(context).extension<GlobalTextFieldTheme>();
  }

  @override
  GlobalTextFieldTheme copyWith({
    TextFieldStyle? style,
    Duration? animationDuration,
  }) {
    return GlobalTextFieldTheme(
      style: style ?? this.style,
      animationDuration: animationDuration ?? this.animationDuration,
    );
  }

  @override
  GlobalTextFieldTheme lerp(
    ThemeExtension<GlobalTextFieldTheme>? other,
    double t,
  ) {
    if (other is! GlobalTextFieldTheme) return this;
    return GlobalTextFieldTheme(
      style: _lerpStyle(style, other.style, t),
      animationDuration: _lerpDuration(
        animationDuration,
        other.animationDuration,
        t,
      ),
    );
  }

  static Duration? _lerpDuration(Duration? a, Duration? b, double t) {
    if (a == null && b == null) return null;
    final aMicros = a?.inMicroseconds ?? b!.inMicroseconds;
    final bMicros = b?.inMicroseconds ?? a!.inMicroseconds;
    return Duration(
      microseconds: (lerpDouble(aMicros.toDouble(), bMicros.toDouble(), t) ?? 0)
          .round(),
    );
  }

  static TextFieldStyle? _lerpStyle(
    TextFieldStyle? a,
    TextFieldStyle? b,
    double t,
  ) {
    if (a == null && b == null) return null;
    if (a == null) return b;
    if (b == null) return a;
    return TextFieldStyle(
      borderRadius: BorderRadius.lerp(a.borderRadius, b.borderRadius, t),
      height: lerpDouble(a.height, b.height, t),
      contentPadding: EdgeInsetsGeometry.lerp(
        a.contentPadding,
        b.contentPadding,
        t,
      ),
      fillColor: Color.lerp(a.fillColor, b.fillColor, t),
      textColor: Color.lerp(a.textColor, b.textColor, t),
      iconColor: Color.lerp(a.iconColor, b.iconColor, t),
      border: TextFieldBorderStyle.lerp(a.border, b.border, t),
      enableBlur: t < 0.5 ? a.enableBlur : b.enableBlur,
      blurSigma: lerpDouble(a.blurSigma, b.blurSigma, t),
      hintStyle: TextStyle.lerp(a.hintStyle, b.hintStyle, t),
      charCountStyle: TextStyle.lerp(a.charCountStyle, b.charCountStyle, t),
      successColor: Color.lerp(a.successColor, b.successColor, t),
      strengthWeakColor: Color.lerp(
        a.strengthWeakColor,
        b.strengthWeakColor,
        t,
      ),
      strengthMediumColor: Color.lerp(
        a.strengthMediumColor,
        b.strengthMediumColor,
        t,
      ),
      strengthStrongColor: Color.lerp(
        a.strengthStrongColor,
        b.strengthStrongColor,
        t,
      ),
      counterWarningColor: Color.lerp(
        a.counterWarningColor,
        b.counterWarningColor,
        t,
      ),
      requirementPassedColor: Color.lerp(
        a.requirementPassedColor,
        b.requirementPassedColor,
        t,
      ),
      enableHaptic: t < 0.5 ? a.enableHaptic : b.enableHaptic,
    );
  }
}
