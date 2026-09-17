import 'package:flutter/material.dart';

import '../../../../core/extensions/theme_colors_extension.dart';
import '../scroll_in_style.dart';
import '../scrollable_models.dart';
import '../scrollable_style.dart';

/// App-wide defaults for the scroll shell.
///
/// The rebrand hook: set the edge fade, the progress strip and the
/// scroll-to-top button once, here, and every page shell in the app
/// follows — the showcase pages', the list's, the grid's.
@immutable
class GlobalScrollableTheme extends ThemeExtension<GlobalScrollableTheme> {
  const GlobalScrollableTheme({this.style, this.scrollInStyle});

  final ScrollableStyle? style;

  /// How a tile arrives when it scrolls into view. Its own bag: the
  /// list and the grid drive it, and it has nothing to do with the
  /// shell's chrome.
  final ScrollInStyle? scrollInStyle;

  static GlobalScrollableTheme? maybeOf(BuildContext context) =>
      Theme.of(context).extension<GlobalScrollableTheme>();

  @override
  GlobalScrollableTheme copyWith({
    ScrollableStyle? style,
    ScrollInStyle? scrollInStyle,
  }) => GlobalScrollableTheme(
    style: style ?? this.style,
    scrollInStyle: scrollInStyle ?? this.scrollInStyle,
  );

  @override
  GlobalScrollableTheme lerp(
    ThemeExtension<GlobalScrollableTheme>? other,
    double t,
  ) {
    if (other is! GlobalScrollableTheme) return this;
    // A bag of independent decisions, not a value with a midpoint —
    // half an `EdgeFadeMode.blur` means nothing. It SNAPS at the
    // halfway mark, which is what every other bag in this app does.
    return t < 0.5 ? this : other;
  }
}

/// Turns a caller's bag into one with every question answered.
extension ScrollableStyleResolve on ScrollableStyle? {
  /// `caller > GlobalScrollableTheme.style > ScrollableStyle.defaults`,
  /// then the palette and the reader's reduce-motion setting.
  ResolvedScrollableStyle resolve(BuildContext context) {
    final merged = ScrollableStyle.defaults
        .mergedWith(GlobalScrollableTheme.maybeOf(context)?.style)
        .mergedWith(this);

    final primary = context.primaryColors.primary;

    // The READER's setting, not the caller's: every one of these is
    // decoration over content that is already legible standing still.
    final respect = merged.respectReducedMotion ?? true;
    final still = respect && MediaQuery.disableAnimationsOf(context);

    return ResolvedScrollableStyle(
      edgeFade: (merged.edgeFade ?? EdgeFadeStyle.off).resolve(context),
      showScrollToTop: merged.showScrollToTop ?? false,
      scrollToTopThreshold:
          merged.scrollToTopThreshold ??
          ScrollableDefaults.scrollToTopThreshold,
      showScrollProgress: merged.showScrollProgress ?? false,
      progressColor: merged.progressColor ?? primary,
      progressThickness:
          merged.progressThickness ?? ScrollableDefaults.progressThickness,
      // A vertical page reads its progress at the TOP, like every
      // article on the web; a horizontal one has an app bar up there
      // and nothing under it, so the strip goes to the bottom.
      progressPlacement:
          merged.progressPlacement ?? ScrollProgressPlacement.top,
      mode: merged.mode ?? ScrollableMode.platform,
      boundaryBehavior: merged.boundaryBehavior ?? BoundaryBehavior.isolated,
      cacheExtent: merged.cacheExtent,
      keyboardDismissBehavior:
          merged.keyboardDismissBehavior ??
          ScrollViewKeyboardDismissBehavior.manual,
      fabSize: merged.fabSize ?? ScrollableDefaults.fabSize,
      fabMargin: merged.fabMargin ?? ScrollableDefaults.fabMargin,
      // ZERO, not short: an overlay that slides in quickly is still
      // motion the reader asked not to see.
      overlayDuration: still
          ? Duration.zero
          : (merged.overlayDuration ?? ScrollableDefaults.overlayDuration),
      scrollToTopDuration: still
          ? Duration.zero
          : (merged.scrollToTopDuration ??
                ScrollableDefaults.scrollToTopDuration),
      scrollToOffsetDuration: still
          ? Duration.zero
          : (merged.scrollToOffsetDuration ??
                ScrollableDefaults.scrollToOffsetDuration),
      // The smoothing IS the motion — under reduced motion the wheel
      // goes back to the framework's discrete step.
      smoothWheelScroll: !still && (merged.smoothWheelScroll ?? true),
      wheelMultiplier:
          merged.wheelMultiplier ?? ScrollableDefaults.wheelMultiplier,
      wheelSmoothness:
          merged.wheelSmoothness ?? ScrollableDefaults.wheelSmoothness,
      enableHaptic: merged.enableHaptic ?? true,
    );
  }
}

/// The fade's own resolve, so a caller holding only an
/// [EdgeFadeStyle] — the list, the dropdown, the breadcrumbs — reaches
/// the same three layers.
extension EdgeFadeStyleResolve on EdgeFadeStyle? {
  ResolvedEdgeFadeStyle resolve(BuildContext context) {
    final merged = EdgeFadeStyle.defaults
        .mergedWith(GlobalScrollableTheme.maybeOf(context)?.style?.edgeFade)
        .mergedWith(this);

    final mode = merged.mode ?? EdgeFadeMode.none;

    final respect = merged.respectReducedMotion ?? true;
    final still = respect && MediaQuery.disableAnimationsOf(context);

    return ResolvedEdgeFadeStyle(
      mode: mode,
      size: merged.size ?? ScrollableDefaults.edgeFadeSize,
      // The scrim fades content into the PAGE, so it takes the page
      // colour; the inner shadow is a shadow, so it takes the scrim.
      // Both read Material's own surface colour and a raw
      // `Colors.black` before, which a rebrand could not move.
      color:
          merged.color ??
          switch (mode) {
            EdgeFadeMode.innerShadow => context.overlayColors.scrim.withValues(
              alpha: ScrollableDefaults.innerShadowOpacity,
            ),
            _ => context.backgroundColors.background,
          },
      smart: merged.smart ?? true,
      start: merged.start ?? true,
      end: merged.end ?? true,
      duration: still
          ? Duration.zero
          : (merged.duration ?? ScrollableDefaults.edgeFadeDuration),
    );
  }
}

/// The scroll-in animator's resolve.
extension ScrollInStyleResolve on ScrollInStyle? {
  /// `caller > GlobalScrollableTheme.scrollInStyle >
  /// ScrollInStyle.defaults`, then the reader's reduce-motion setting.
  ResolvedScrollInStyle resolve(BuildContext context) {
    final merged = ScrollInStyle.defaults
        .mergedWith(GlobalScrollableTheme.maybeOf(context)?.scrollInStyle)
        .mergedWith(this);

    // The READER's setting. An entry animation fires once per row and
    // a list has hundreds of rows, which makes this the most repeated
    // motion in the whole app — and nothing here reads any of it
    // before now, so a reader with reduce-motion on still watched
    // every row slide and scale into place.
    final respect = merged.respectReducedMotion ?? true;
    final still = respect && MediaQuery.disableAnimationsOf(context);

    return ResolvedScrollInStyle(
      // The SWITCH. A theme must not turn an entrance on for a list
      // that never asked for one, so this field is the caller's alone
      // when it is null on both layers.
      animation: merged.animation,
      // ZERO, not short: the tile is placed rather than raced into
      // position.
      duration: still
          ? Duration.zero
          : (merged.duration ?? ScrollInDefaults.duration),
      curve: merged.curve ?? ScrollInDefaults.curve,
      scaleCurve: merged.scaleCurve ?? ScrollInDefaults.scaleCurve,
      slideOffset: merged.slideOffset ?? ScrollInDefaults.slideOffset,
      threshold: merged.threshold ?? ScrollInDefaults.threshold,
      once: merged.once ?? true,
      // A cascade made instant is not a cascade, it is a delay before
      // something appears — which is worse than no cascade at all.
      stagger: still
          ? Duration.zero
          : (merged.stagger ?? ScrollInDefaults.stagger),
      staggerMode: merged.staggerMode ?? ScrollInStaggerMode.byOrder,
      staggerIdleReset:
          merged.staggerIdleReset ?? ScrollInDefaults.staggerIdleReset,
      staggerMaxQueue:
          merged.staggerMaxQueue ?? ScrollInDefaults.staggerMaxQueue,
      mode: merged.mode ?? ScrollInMode.oneShot,
      still: still,
    );
  }
}
