import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';

import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/extensions/theme_colors_extension.dart';
import '../rating_models.dart';

/// App-wide defaults for `GlobalRating`.
///
/// The rebrand hook: set the star's shape, colour and size once here and
/// every rating in the app follows.
@immutable
class GlobalRatingTheme extends ThemeExtension<GlobalRatingTheme> {
  const GlobalRatingTheme({this.style});

  final RatingStyle? style;

  static GlobalRatingTheme? maybeOf(BuildContext context) =>
      Theme.of(context).extension<GlobalRatingTheme>();

  @override
  GlobalRatingTheme copyWith({RatingStyle? style}) =>
      GlobalRatingTheme(style: style ?? this.style);

  @override
  GlobalRatingTheme lerp(ThemeExtension<GlobalRatingTheme>? other, double t) {
    if (other is! GlobalRatingTheme) return this;
    return GlobalRatingTheme(style: _lerpStyle(style, other.style, t));
  }

  /// Continuous fields interpolate; discrete ones snap at the midpoint —
  /// half a star glyph is a different glyph, not a blend.
  static RatingStyle? _lerpStyle(RatingStyle? a, RatingStyle? b, double t) {
    if (a == null && b == null) return null;
    final pick = t < 0.5 ? a : b;
    return RatingStyle(
      size: lerpDouble(a?.size, b?.size, t),
      spacing: lerpDouble(a?.spacing, b?.spacing, t),
      ratedColor: Color.lerp(a?.ratedColor, b?.ratedColor, t),
      unratedColor: Color.lerp(a?.unratedColor, b?.unratedColor, t),
      halfRatedColor: Color.lerp(a?.halfRatedColor, b?.halfRatedColor, t),
      disabledOpacity: lerpDouble(a?.disabledOpacity, b?.disabledOpacity, t),
      ratedGradient: Gradient.lerp(a?.ratedGradient, b?.ratedGradient, t),
      shadow: BoxShadow.lerpList(a?.shadow, b?.shadow, t),
      ratedShadow: BoxShadow.lerpList(a?.ratedShadow, b?.ratedShadow, t),
      countLabelStyle: TextStyle.lerp(
        a?.countLabelStyle,
        b?.countLabelStyle,
        t,
      ),
      countLabelSpacing: lerpDouble(
        a?.countLabelSpacing,
        b?.countLabelSpacing,
        t,
      ),
      hoverColor: Color.lerp(a?.hoverColor, b?.hoverColor, t),
      focusColor: Color.lerp(a?.focusColor, b?.focusColor, t),
      selectPopScale: lerpDouble(a?.selectPopScale, b?.selectPopScale, t),
      dragLiftScale: lerpDouble(a?.dragLiftScale, b?.dragLiftScale, t),
      selectPop: pick?.selectPop,
      popDuration: pick?.popDuration,
      fillCrossfade: pick?.fillCrossfade,
      dragLift: pick?.dragLift,
      staggerFill: pick?.staggerFill,
      staggerClear: pick?.staggerClear,
      staggerStep: pick?.staggerStep,
      ratedIcon: pick?.ratedIcon,
      unratedIcon: pick?.unratedIcon,
      halfRatedIcon: pick?.halfRatedIcon,
      ratedWidget: pick?.ratedWidget,
      unratedWidget: pick?.unratedWidget,
      halfRatedWidget: pick?.halfRatedWidget,
      animationDuration: pick?.animationDuration,
      animationCurve: pick?.animationCurve,
      enableHaptic: pick?.enableHaptic,
    );
  }
}

extension RatingStyleResolve on RatingStyle {
  /// Stacks `caller > theme > defaults`, then fills colours from
  /// `context.<group>Colors` so a rating tracks the active palette, role
  /// and brightness.
  ///
  /// [disableAnimations] collapses the fill transition to zero rather
  /// than shortening it — a star arriving instantly is still the right
  /// star.
  ResolvedRatingStyle resolve(
    BuildContext context, {
    bool disableAnimations = false,
  }) {
    final merged = RatingStyle.defaults
        .mergedWith(GlobalRatingTheme.maybeOf(context)?.style)
        .mergedWith(this);
    const floor = RatingStyle.defaults;

    // A filled star is a POSITIVE signal, so it takes the status warning
    // colour — the palette's own amber — rather than `Colors.amber`,
    // which was the same yellow whatever the app shipped.
    final rated = merged.ratedColor ?? context.statusColors.warning;

    return ResolvedRatingStyle(
      size: merged.size ?? floor.size!,
      spacing: merged.spacing ?? floor.spacing!,
      ratedColor: rated,
      // The empty star is an OUTLINE, not a faded fill: at 25% alpha it
      // disappeared against a coloured card, which is where ratings
      // usually sit.
      unratedColor: merged.unratedColor ?? context.backgroundColors.outline,
      halfRatedColor: merged.halfRatedColor ?? rated,
      disabledOpacity: merged.disabledOpacity ?? floor.disabledOpacity!,
      ratedIcon: merged.ratedIcon ?? floor.ratedIcon!,
      unratedIcon: merged.unratedIcon ?? floor.unratedIcon!,
      halfRatedIcon: merged.halfRatedIcon ?? floor.halfRatedIcon!,
      animationDuration: disableAnimations
          ? Duration.zero
          : merged.animationDuration ?? floor.animationDuration!,
      animationCurve: merged.animationCurve ?? floor.animationCurve!,
      enableHaptic: merged.enableHaptic ?? floor.enableHaptic!,
      countLabelStyle:
          merged.countLabelStyle ??
          (context.textTheme.bodySmall ?? const TextStyle()).copyWith(
            color: context.textColors.secondary,
          ),
      countLabelSpacing: merged.countLabelSpacing ?? floor.countLabelSpacing!,
      hoverColor:
          merged.hoverColor ??
          rated.withValues(alpha: RatingDefaults.hoverOpacity),
      // The focus ring is nearly OPAQUE. It used to be the rated colour
      // at 12%, which on a row of amber stars is invisible — the same
      // finding as the tab bar's focus overlay, and the reason both are
      // deliberately louder than Material's default.
      focusColor:
          merged.focusColor ??
          context.primaryColors.primary.withValues(
            alpha: RatingDefaults.focusRingOpacity,
          ),
      // Reduced motion takes the FLOURISHES away and leaves the state.
      // A star still fills, it just does not travel to get there — the
      // same line the drawer's staggered entrance draws.
      selectPop: !disableAnimations && (merged.selectPop ?? floor.selectPop!),
      selectPopScale: merged.selectPopScale ?? floor.selectPopScale!,
      popDuration: merged.popDuration ?? floor.popDuration!,
      fillCrossfade:
          !disableAnimations && (merged.fillCrossfade ?? floor.fillCrossfade!),
      dragLift: !disableAnimations && (merged.dragLift ?? floor.dragLift!),
      dragLiftScale: merged.dragLiftScale ?? floor.dragLiftScale!,
      staggerFill:
          !disableAnimations && (merged.staggerFill ?? floor.staggerFill!),
      staggerClear:
          !disableAnimations && (merged.staggerClear ?? floor.staggerClear!),
      staggerStep: merged.staggerStep ?? floor.staggerStep!,
      ratedWidget: merged.ratedWidget,
      unratedWidget: merged.unratedWidget,
      halfRatedWidget: merged.halfRatedWidget,
      ratedGradient: merged.ratedGradient,
      shadow: merged.shadow,
      ratedShadow: merged.ratedShadow,
    );
  }
}
