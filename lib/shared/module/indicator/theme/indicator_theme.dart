import 'package:flutter/material.dart';

import '../../../../core/extensions/theme_colors_extension.dart';
import '../indicator_models.dart';
import '../indicator_style.dart';

/// App-wide defaults for the indicator family.
///
/// The rebrand hook: set the dots' size, spacing and motion once, here,
/// and every pagination row in the app follows — the page view's, the
/// onboarding flow's, the carousel's.
@immutable
class GlobalIndicatorTheme extends ThemeExtension<GlobalIndicatorTheme> {
  const GlobalIndicatorTheme({this.dotStyle, this.storyStyle});

  final DotIndicatorStyle? dotStyle;

  /// The story bar is a different widget with different needs, and it
  /// lives over PHOTOGRAPHS rather than over the page.
  final StoryIndicatorStyle? storyStyle;

  static GlobalIndicatorTheme? maybeOf(BuildContext context) =>
      Theme.of(context).extension<GlobalIndicatorTheme>();

  @override
  GlobalIndicatorTheme copyWith({
    DotIndicatorStyle? dotStyle,
    StoryIndicatorStyle? storyStyle,
  }) => GlobalIndicatorTheme(
    dotStyle: dotStyle ?? this.dotStyle,
    storyStyle: storyStyle ?? this.storyStyle,
  );

  @override
  GlobalIndicatorTheme lerp(
    ThemeExtension<GlobalIndicatorTheme>? other,
    double t,
  ) {
    if (other is! GlobalIndicatorTheme) return this;
    // A bag of independent decisions, not a value with a midpoint —
    // half a `DotShape.star` means nothing. It SNAPS at the halfway
    // mark, which is what every other bag in this app does.
    return t < 0.5 ? this : other;
  }
}

/// Turns a caller's bag into one with every question answered.
extension DotIndicatorStyleResolve on DotIndicatorStyle {
  /// `caller > GlobalIndicatorTheme.dotStyle > DotIndicatorStyle.defaults`,
  /// then the palette and the reader's reduce-motion setting.
  ///
  /// It read `Theme.of(context).colorScheme` for both colours, so a
  /// rebrand moved the app and left the dots on Material's seed.
  ResolvedDotIndicatorStyle resolve(BuildContext context) {
    final merged = DotIndicatorStyle.defaults
        .mergedWith(GlobalIndicatorTheme.maybeOf(context)?.dotStyle)
        .mergedWith(this);

    final active = merged.activeColor ?? context.primaryColors.primary;

    // The READER's setting. A row of dots re-animates on every page
    // change, which is the most frequently repeated motion in a
    // carousel or an onboarding flow.
    final respect = merged.respectReducedMotion ?? true;
    final still = respect && MediaQuery.disableAnimationsOf(context);

    return ResolvedDotIndicatorStyle(
      activeColor: active,
      inactiveColor:
          merged.inactiveColor ?? context.backgroundColors.outlineVariant,
      gradient: merged.gradient,
      dotSize: merged.dotSize ?? IndicatorDefaults.dotSize,
      activeDotSize: merged.activeDotSize ?? IndicatorDefaults.activeDotSize,
      expansionFactor:
          merged.expansionFactor ?? IndicatorDefaults.expansionFactor,
      slideMarkerFactor:
          merged.slideMarkerFactor ?? IndicatorDefaults.slideMarkerFactor,
      dotSpacing: merged.dotSpacing ?? IndicatorDefaults.dotSpacing,
      radius: merged.radius ?? IndicatorDefaults.radius,
      // ZERO, not short: every effect then lands on its end state in
      // one frame instead of racing there.
      duration: still
          ? Duration.zero
          : (merged.duration ?? IndicatorDefaults.duration),
      curve: merged.curve ?? IndicatorDefaults.curve,
      shadow: merged.shadow,
      scrollingDotsCenterScale:
          merged.scrollingDotsCenterScale ??
          IndicatorDefaults.scrollingDotsCenterScale,
      scrollingDotsVisibleCount:
          merged.scrollingDotsVisibleCount ??
          IndicatorDefaults.scrollingDotsVisibleCount,
      scrollingDotsMinAlpha:
          merged.scrollingDotsMinAlpha ??
          IndicatorDefaults.scrollingDotsMinAlpha,
      scrollingDotsFadeEdges: merged.scrollingDotsFadeEdges ?? true,
      scrollingDotsHitZone:
          merged.scrollingDotsHitZone ?? IndicatorDefaults.scrollingDotsHitZone,
      shape: merged.shape ?? DotShape.circle,
      // The ring is the accent unless asked otherwise — it is the
      // active dot's own splash.
      splashRingColor: merged.splashRingColor ?? active,
      splashRingWidth:
          merged.splashRingWidth ?? IndicatorDefaults.splashRingWidth,
      splashMaxRadiusFactor:
          merged.splashMaxRadiusFactor ??
          IndicatorDefaults.splashMaxRadiusFactor,
      dropDistanceFactor:
          merged.dropDistanceFactor ?? IndicatorDefaults.dropDistanceFactor,
      flashMinOpacity:
          merged.flashMinOpacity ?? IndicatorDefaults.flashMinOpacity,
      enableHaptic: merged.enableHaptic ?? true,
      borderColor: merged.borderColor,
      borderWidth: merged.borderWidth ?? IndicatorDefaults.borderWidth,
      paintStyle: merged.paintStyle ?? PaintingStyle.fill,
    );
  }
}

/// The story bar's own resolve.
extension StoryIndicatorStyleResolve on StoryIndicatorStyle {
  ResolvedStoryIndicatorStyle resolve(BuildContext context) {
    final merged = StoryIndicatorStyle.defaults
        .mergedWith(GlobalIndicatorTheme.maybeOf(context)?.storyStyle)
        .mergedWith(this);

    return ResolvedStoryIndicatorStyle(
      // WHITE, not a palette colour, and deliberately: a story bar
      // sits over arbitrary photographs, the same call the video and
      // scanner modules make about controls over media.
      activeColor: merged.activeColor ?? const Color(0xFFFFFFFF),
      inactiveColor:
          merged.inactiveColor ??
          const Color(0xFFFFFFFF).withValues(
            alpha: IndicatorDefaults.storyTrackOpacity,
          ),
      height: merged.height ?? IndicatorDefaults.storyHeight,
      spacing: merged.spacing ?? IndicatorDefaults.storySpacing,
      radius: merged.radius ?? IndicatorDefaults.storyRadius,
      enableHaptic: merged.enableHaptic ?? true,
    );
  }
}
