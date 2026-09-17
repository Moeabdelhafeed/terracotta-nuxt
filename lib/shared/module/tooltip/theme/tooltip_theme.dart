import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';

import '../../../../core/constants/sizes/app_sizes.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/extensions/theme_colors_extension.dart';
import '../tooltip_models.dart';

/// App-wide defaults for `GlobalTooltip`.
///
/// The rebrand hook: set the surface, type and timing of every tooltip
/// in the app once here.
@immutable
class GlobalTooltipTheme extends ThemeExtension<GlobalTooltipTheme> {
  const GlobalTooltipTheme({this.style});

  final TooltipStyle? style;

  static GlobalTooltipTheme? maybeOf(BuildContext context) =>
      Theme.of(context).extension<GlobalTooltipTheme>();

  @override
  GlobalTooltipTheme copyWith({TooltipStyle? style}) =>
      GlobalTooltipTheme(style: style ?? this.style);

  @override
  GlobalTooltipTheme lerp(ThemeExtension<GlobalTooltipTheme>? other, double t) {
    if (other is! GlobalTooltipTheme) return this;
    return GlobalTooltipTheme(style: _lerpStyle(style, other.style, t));
  }

  /// Continuous fields interpolate; discrete ones snap at the midpoint —
  /// half a duration is not a thing anyone wants mid-animation.
  static TooltipStyle? _lerpStyle(TooltipStyle? a, TooltipStyle? b, double t) {
    if (a == null && b == null) return null;
    final pick = t < 0.5 ? a : b;
    return TooltipStyle(
      backgroundColor: Color.lerp(a?.backgroundColor, b?.backgroundColor, t),
      foregroundColor: Color.lerp(a?.foregroundColor, b?.foregroundColor, t),
      gradient: Gradient.lerp(a?.gradient, b?.gradient, t),
      borderColor: Color.lerp(a?.borderColor, b?.borderColor, t),
      borderRadius: BorderRadius.lerp(a?.borderRadius, b?.borderRadius, t),
      textStyle: TextStyle.lerp(a?.textStyle, b?.textStyle, t),
      padding: EdgeInsetsGeometry.lerp(a?.padding, b?.padding, t),
      screenMargin: lerpDouble(a?.screenMargin, b?.screenMargin, t),
      verticalOffset: lerpDouble(a?.verticalOffset, b?.verticalOffset, t),
      shadow: BoxShadow.lerp(a?.shadow, b?.shadow, t),
      arrowSize: lerpDouble(a?.arrowSize, b?.arrowSize, t),
      maxWidth: lerpDouble(a?.maxWidth, b?.maxWidth, t),
      decoration: pick?.decoration,
      showDuration: pick?.showDuration,
      waitDuration: pick?.waitDuration,
    );
  }
}

extension TooltipStyleResolve on TooltipStyle {
  /// Stacks `caller > theme > defaults`, then fills colours from
  /// `context.<group>Colors`.
  ///
  /// [shape] is an argument because the offset depends on it and the
  /// bag cannot know it: a bubble stands further off the child than a
  /// rectangle, its arrow standing in the gap.
  ///
  /// The SIDE is deliberately not an argument. It used to be, to aim a
  /// `ShapeBorder`'s arrow — but the popup engine owns the side now and
  /// may flip it after this bag is built, so a side baked in here would
  /// be a lie half the time.
  ResolvedTooltipStyle resolve(
    BuildContext context, {
    TooltipShape shape = TooltipShape.rectangle,
  }) {
    final merged = TooltipStyle.defaults
        .mergedWith(GlobalTooltipTheme.maybeOf(context)?.style)
        .mergedWith(this);
    const floor = TooltipStyle.defaults;

    final isDark = context.isDarkMode;
    final bg = context.backgroundColors;

    // A tooltip is a surface ABOVE the page, so it inverts against it:
    // the near-black high-contrast primary on a light page, the raised
    // container on a dark one — where a black bubble would disappear.
    final background =
        merged.backgroundColor ??
        (isDark ? bg.container : context.primaryColors.primaryHighContrast);

    // `Colors.white` was hard-coded here for light mode — right against
    // a near-black bubble by accident, wrong for any brand that themes
    // the surface.
    final foreground = merged.foregroundColor ?? context.textColors.onPrimary;

    return ResolvedTooltipStyle(
      backgroundColor: background,
      foregroundColor: foreground,
      gradient: merged.gradient,
      // Only a DARK tooltip outlines itself: on a dark page its surface
      // and the page behind it are close enough to merge.
      borderColor:
          merged.borderColor ??
          (isDark
              ? bg.outline.withValues(alpha: TooltipDefaults.darkBorderOpacity)
              : null),
      borderRadius:
          merged.borderRadius ??
          BorderRadius.circular(AppSizes.inputFieldRadius / 2),
      decoration: merged.decoration,
      textStyle:
          merged.textStyle ??
          (context.textTheme.bodySmall ?? const TextStyle()).copyWith(
            color: foreground,
            fontWeight: FontWeight.w600,
            letterSpacing: TooltipDefaults.letterSpacing,
          ),
      padding: merged.padding ?? floor.padding!,
      screenMargin: merged.screenMargin ?? floor.screenMargin!,
      verticalOffset:
          merged.verticalOffset ??
          (shape.isBubble
              ? TooltipDefaults.bubbleVerticalOffset
              : TooltipDefaults.verticalOffset),
      shadow:
          merged.shadow ??
          BoxShadow(
            color: context.overlayColors.scrim.withValues(
              alpha: TooltipDefaults.shadowOpacity,
            ),
            blurRadius: TooltipDefaults.shadowBlur,
            offset: TooltipDefaults.shadowOffset,
          ),
      showDuration: merged.showDuration ?? floor.showDuration!,
      waitDuration: merged.waitDuration ?? floor.waitDuration!,
      arrowSize: merged.arrowSize ?? floor.arrowSize!,
      maxWidth: merged.maxWidth ?? floor.maxWidth!,
    );
  }
}
