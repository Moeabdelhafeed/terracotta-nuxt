import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';

import '../../../../core/extensions/theme_colors_extension.dart';
import '../icon_models.dart';

/// App-wide defaults for `GlobalIcon`.
///
/// The rebrand hook: set the glyph size, container treatment and border
/// weight of every icon in the app once here.
@immutable
class GlobalIconTheme extends ThemeExtension<GlobalIconTheme> {
  const GlobalIconTheme({this.style});

  final IconStyle? style;

  static GlobalIconTheme? maybeOf(BuildContext context) =>
      Theme.of(context).extension<GlobalIconTheme>();

  @override
  GlobalIconTheme copyWith({IconStyle? style}) =>
      GlobalIconTheme(style: style ?? this.style);

  @override
  GlobalIconTheme lerp(ThemeExtension<GlobalIconTheme>? other, double t) {
    if (other is! GlobalIconTheme) return this;
    return GlobalIconTheme(style: _lerpStyle(style, other.style, t));
  }

  /// Null-tolerant duration lerp — `lerpDuration` requires both sides.
  static Duration? _lerpDuration(Duration? a, Duration? b, double t) {
    if (a == null && b == null) return null;
    if (a == null || b == null) return t < 0.5 ? a : b;
    return Duration(
      microseconds:
          (a.inMicroseconds + (b.inMicroseconds - a.inMicroseconds) * t)
              .round(),
    );
  }

  /// Continuous fields interpolate; discrete ones snap at the midpoint.
  static IconStyle? _lerpStyle(IconStyle? a, IconStyle? b, double t) {
    if (a == null && b == null) return null;
    final pick = t < 0.5 ? a : b;
    return IconStyle(
      color: Color.lerp(a?.color, b?.color, t),
      size: lerpDouble(a?.size, b?.size, t),
      backgroundColor: Color.lerp(a?.backgroundColor, b?.backgroundColor, t),
      backgroundOpacity: lerpDouble(
        a?.backgroundOpacity,
        b?.backgroundOpacity,
        t,
      ),
      containerSize: lerpDouble(a?.containerSize, b?.containerSize, t),
      borderRadius: BorderRadius.lerp(a?.borderRadius, b?.borderRadius, t),
      border: BoxBorder.lerp(a?.border, b?.border, t),
      borderColor: Color.lerp(a?.borderColor, b?.borderColor, t),
      borderWidth: lerpDouble(a?.borderWidth, b?.borderWidth, t),
      gradientBorderWidth: lerpDouble(
        a?.gradientBorderWidth,
        b?.gradientBorderWidth,
        t,
      ),
      padding: EdgeInsets.lerp(a?.padding, b?.padding, t),
      opacity: lerpDouble(a?.opacity, b?.opacity, t),
      strokeWidth: lerpDouble(a?.strokeWidth, b?.strokeWidth, t),
      strokeColor: Color.lerp(a?.strokeColor, b?.strokeColor, t),
      animationDuration: _lerpDuration(
        a?.animationDuration,
        b?.animationDuration,
        t,
      ),
      shadow: BoxShadow.lerpList(a?.shadow, b?.shadow, t),
      // Gradients and blend modes do not interpolate meaningfully
      // between two different specs — snap.
      containerShape: pick?.containerShape,
      borderGradient: pick?.borderGradient,
      gradient: pick?.gradient,
      gradientBlendMode: pick?.gradientBlendMode,
      strokeGradient: pick?.strokeGradient,
      enableHaptic: pick?.enableHaptic,
      animateIconChange: pick?.animateIconChange,
      animationCurve: pick?.animationCurve,
    );
  }
}

extension IconStyleResolve on IconStyle {
  /// Stacks `caller > theme > defaults`, then fills colours from the
  /// ambient `IconTheme` and `context.<group>Colors`.
  ///
  /// The glyph colour asks the ambient `IconTheme` BEFORE the palette:
  /// an icon inside a button, an app bar or a selected list row is
  /// meant to take that surface's foreground, and a palette colour
  /// forced here would be the one thing on the surface ignoring it.
  ///
  /// [enabled] is an argument because the bag cannot know it and two
  /// colours depend on it: a disabled glyph and its container both drop
  /// to [IconDefaults.disabledOpacity], rather than the caller dimming
  /// the whole widget and leaving the semantics saying "button".
  ResolvedIconStyle resolve(BuildContext context, {bool enabled = true}) {
    final merged = IconStyle.defaults
        .mergedWith(GlobalIconTheme.maybeOf(context)?.style)
        .mergedWith(this);
    const floor = IconStyle.defaults;

    final bg = context.backgroundColors;

    Color dim(Color c) =>
        enabled ? c : c.withValues(alpha: c.a * IconDefaults.disabledOpacity);

    return ResolvedIconStyle(
      color: dim(
        merged.color ??
            IconTheme.of(context).color ??
            context.iconColors.secondary,
      ),
      size: merged.size ?? floor.size!,
      backgroundColor: merged.backgroundColor == null
          ? null
          : dim(merged.backgroundColor!),
      backgroundOpacity: merged.backgroundOpacity ?? floor.backgroundOpacity!,
      containerSize: merged.containerSize,
      containerShape: merged.containerShape ?? floor.containerShape!,
      borderRadius: merged.borderRadius,
      // A caller's whole border wins; otherwise one is composed, so the
      // colour can come from the palette instead of `Colors.grey`.
      border:
          merged.border ??
          (merged.borderColor != null || merged.borderWidth != null
              ? Border.all(
                  color: merged.borderColor ?? bg.outline,
                  width: merged.borderWidth ?? IconDefaults.borderWidth,
                )
              : null),
      borderGradient: merged.borderGradient,
      gradientBorderWidth:
          merged.gradientBorderWidth ?? floor.gradientBorderWidth!,
      padding: merged.padding,
      gradient: merged.gradient,
      gradientBlendMode: merged.gradientBlendMode ?? floor.gradientBlendMode!,
      shadow: merged.shadow,
      opacity: merged.opacity ?? floor.opacity!,
      strokeWidth: merged.strokeWidth,
      // `Colors.black` before — an outline that stayed black on a dark
      // page, where it is the page showing through that the outline is
      // supposed to imitate.
      strokeColor: merged.strokeColor ?? bg.background,
      strokeGradient: merged.strokeGradient,
      // The middle of a gradient-bordered box: the surface the icon
      // sits on, so the ring reads as a ring. `scaffoldBackground`
      // before, which is wrong the moment the icon is on a card.
      gradientBorderFill: bg.cardBackground,
      enableHaptic: merged.enableHaptic ?? floor.enableHaptic!,
      animateIconChange: merged.animateIconChange ?? floor.animateIconChange!,
      animationDuration: merged.animationDuration ?? floor.animationDuration!,
      animationCurve: merged.animationCurve ?? floor.animationCurve!,
    );
  }
}
