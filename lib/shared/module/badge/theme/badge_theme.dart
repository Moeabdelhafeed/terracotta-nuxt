import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';

import '../../../../core/extensions/theme_colors_extension.dart';
import '../badge_models.dart';

/// App-wide defaults for [GlobalBadge].
///
/// The rebrand hook: set the badge's colour, shape and size once here
/// and every unread marker in the app follows — which is the point of
/// having one badge rather than four.
@immutable
class GlobalBadgeTheme extends ThemeExtension<GlobalBadgeTheme> {
  const GlobalBadgeTheme({this.style});

  final BadgeStyle? style;

  static GlobalBadgeTheme? maybeOf(BuildContext context) =>
      Theme.of(context).extension<GlobalBadgeTheme>();

  @override
  GlobalBadgeTheme copyWith({BadgeStyle? style}) =>
      GlobalBadgeTheme(style: style ?? this.style);

  @override
  GlobalBadgeTheme lerp(ThemeExtension<GlobalBadgeTheme>? other, double t) {
    if (other is! GlobalBadgeTheme) return this;
    return GlobalBadgeTheme(style: _lerpStyle(style, other.style, t));
  }

  /// Continuous fields interpolate; discrete ones snap at the midpoint —
  /// half a `pulsate` is not a thing.
  static BadgeStyle? _lerpStyle(BadgeStyle? a, BadgeStyle? b, double t) {
    if (a == null && b == null) return null;
    final pick = t < 0.5 ? a : b;
    return BadgeStyle(
      backgroundColor: Color.lerp(a?.backgroundColor, b?.backgroundColor, t),
      backgroundGradient: Gradient.lerp(
        a?.backgroundGradient,
        b?.backgroundGradient,
        t,
      ),
      foregroundColor: Color.lerp(a?.foregroundColor, b?.foregroundColor, t),
      borderColor: Color.lerp(a?.borderColor, b?.borderColor, t),
      borderWidth: lerpDouble(a?.borderWidth, b?.borderWidth, t),
      fontSize: lerpDouble(a?.fontSize, b?.fontSize, t),
      fontWeight: FontWeight.lerp(a?.fontWeight, b?.fontWeight, t),
      size: lerpDouble(a?.size, b?.size, t),
      dotSize: lerpDouble(a?.dotSize, b?.dotSize, t),
      padding: EdgeInsetsGeometry.lerp(a?.padding, b?.padding, t),
      borderRadius: BorderRadius.lerp(a?.borderRadius, b?.borderRadius, t),
      shadow: BoxShadow.lerpList(a?.shadow, b?.shadow, t),
      offset: Offset.lerp(a?.offset, b?.offset, t),
      animationDuration: pick?.animationDuration,
      animationCurve: pick?.animationCurve,
      pulsate: pick?.pulsate,
      hideWhenZero: pick?.hideWhenZero,
      maxCount: pick?.maxCount,
    );
  }
}

extension BadgeStyleResolve on BadgeStyle {
  /// Stacks `caller > theme > defaults`, then fills colours from
  /// `context.<group>Colors` so a badge tracks the active palette, role
  /// and brightness.
  ResolvedBadgeStyle resolve(BuildContext context) {
    final merged = BadgeStyle.defaults
        .mergedWith(GlobalBadgeTheme.maybeOf(context)?.style)
        .mergedWith(this);
    const floor = BadgeStyle.defaults;

    return ResolvedBadgeStyle(
      // A badge is an ALERT, so it takes the status colour rather than
      // the brand one — and `Colors.red` before that, which was the same
      // red whatever palette the app shipped.
      backgroundColor: merged.backgroundColor ?? context.statusColors.error,
      foregroundColor: merged.foregroundColor ?? context.textColors.onPrimary,
      // The ring is what lifts the badge off whatever it is pinned to,
      // so it matches the PAGE rather than the child.
      borderColor: merged.borderColor ?? context.backgroundColors.background,
      borderWidth: merged.borderWidth ?? floor.borderWidth!,
      fontSize: merged.fontSize ?? floor.fontSize!,
      fontWeight: merged.fontWeight ?? floor.fontWeight!,
      size: merged.size ?? kBadgeDefaultSize,
      dotSize: merged.dotSize ?? floor.dotSize!,
      animationDuration: merged.animationDuration ?? floor.animationDuration!,
      animationCurve: merged.animationCurve ?? floor.animationCurve!,
      pulsate: merged.pulsate ?? floor.pulsate!,
      hideWhenZero: merged.hideWhenZero ?? floor.hideWhenZero!,
      maxCount: merged.maxCount ?? floor.maxCount!,
      offset: merged.offset ?? floor.offset!,
      backgroundGradient: merged.backgroundGradient,
      padding: merged.padding,
      borderRadius: merged.borderRadius,
      shadow: merged.shadow,
    );
  }
}
