import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';

import '../../../core/extensions/theme_colors_extension.dart';
import '../../../core/responsive/extensions.dart';
import '../../../core/tokens/extensions.dart';
import 'text_models.dart';

/// App-wide defaults for [GlobalText] and its siblings.
///
/// Built by `MyGlobalTextTheme.build(tokens:)` and wired into
/// `theme.dart`'s `extensions:` list, so a rebrand changes text
/// treatment in one place instead of at 70-odd call sites.
@immutable
class GlobalTextTheme extends ThemeExtension<GlobalTextTheme> {
  const GlobalTextTheme({this.style});

  final GlobalTextStyle? style;

  static GlobalTextTheme? maybeOf(BuildContext context) =>
      Theme.of(context).extension<GlobalTextTheme>();

  @override
  GlobalTextTheme copyWith({GlobalTextStyle? style}) =>
      GlobalTextTheme(style: style ?? this.style);

  @override
  GlobalTextTheme lerp(ThemeExtension<GlobalTextTheme>? other, double t) {
    if (other is! GlobalTextTheme) return this;
    return GlobalTextTheme(style: _lerpStyle(style, other.style, t));
  }

  /// Only the continuous fields interpolate; discrete ones (icons,
  /// decoration kind, weights) snap at the midpoint, which is what a
  /// theme crossfade should do with them.
  static GlobalTextStyle? _lerpStyle(
    GlobalTextStyle? a,
    GlobalTextStyle? b,
    double t,
  ) {
    if (a == null && b == null) return null;
    final pick = t < 0.5 ? a : b;
    return GlobalTextStyle(
      color: Color.lerp(a?.color, b?.color, t),
      // Discrete: half a font family is not a thing.
      fontFamily: pick?.fontFamily,
      fontSize: lerpDouble(a?.fontSize, b?.fontSize, t),
      fontWeight: pick?.fontWeight,
      fontStyle: pick?.fontStyle,
      letterSpacing: lerpDouble(a?.letterSpacing, b?.letterSpacing, t),
      wordSpacing: lerpDouble(a?.wordSpacing, b?.wordSpacing, t),
      height: lerpDouble(a?.height, b?.height, t),
      gradient: Gradient.lerp(a?.gradient, b?.gradient, t),
      decoration: pick?.decoration,
      decorationColor: Color.lerp(a?.decorationColor, b?.decorationColor, t),
      highlightColor: Color.lerp(a?.highlightColor, b?.highlightColor, t),
      highlightPadding: EdgeInsets.lerp(
        a?.highlightPadding,
        b?.highlightPadding,
        t,
      ),
      highlightBorderRadius: BorderRadius.lerp(
        a?.highlightBorderRadius,
        b?.highlightBorderRadius,
        t,
      ),
      shadow: pick?.shadow,
      leadingIcon: pick?.leadingIcon,
      trailingIcon: pick?.trailingIcon,
      iconSize: lerpDouble(a?.iconSize, b?.iconSize, t),
      iconColor: Color.lerp(a?.iconColor, b?.iconColor, t),
      iconSpacing: lerpDouble(a?.iconSpacing, b?.iconSpacing, t),
      strokeColor: Color.lerp(a?.strokeColor, b?.strokeColor, t),
      strokeGradient: Gradient.lerp(a?.strokeGradient, b?.strokeGradient, t),
      strokeWidth: lerpDouble(a?.strokeWidth, b?.strokeWidth, t),
    );
  }
}

/// Resolution entry point used by every widget in the module.
extension GlobalTextStyleResolve on GlobalTextStyle {
  /// Stacks `caller > theme > defaults`, then fills the remaining
  /// non-null guarantees from the context's palette and tokens.
  ResolvedGlobalTextStyle resolve(BuildContext context) {
    final merged = GlobalTextStyle.defaults
        .mergedWith(GlobalTextTheme.maybeOf(context)?.style)
        .mergedWith(this);

    // GlobalText also renders OUTSIDE the app shell — toast overlays,
    // pre-boot surfaces — where there is no BreakpointsProvider and the
    // token lookups would throw. Degrade to the compile-time floor
    // instead of making a text widget require the responsive stack.
    final tokens = context.maybeBreakpoints == null ? null : context.tokens;
    const floor = GlobalTextStyle.defaults;

    return ResolvedGlobalTextStyle(
      decoration: merged.decoration ?? TextDecorationType.none,
      highlightPadding:
          merged.highlightPadding ??
          (tokens == null
              ? floor.highlightPadding!
              : EdgeInsets.symmetric(
                  horizontal: tokens.spacing.xs,
                  vertical: tokens.spacing.xs / 2,
                )),
      highlightBorderRadius:
          merged.highlightBorderRadius ??
          BorderRadius.circular(tokens?.radii.xs ?? 4),
      // Tint from the live palette rather than a frozen constant, so it
      // tracks role + saturation like everything else.
      highlightColor:
          merged.highlightColor ??
          context.primaryColors.primary.withValues(alpha: 0.12),
      iconSize: merged.iconSize ?? tokens?.iconSizes.sm ?? floor.iconSize!,
      iconSpacing:
          merged.iconSpacing ?? tokens?.spacing.xs ?? floor.iconSpacing!,
      strokeWidth: merged.strokeWidth ?? 0,
      raw: merged,
    );
  }
}
