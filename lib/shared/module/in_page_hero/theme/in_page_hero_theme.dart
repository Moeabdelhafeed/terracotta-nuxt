import 'package:flutter/material.dart';

import '../in_page_hero_style.dart';

/// App-wide defaults for [InPageHero] flights.
///
/// The rebrand hook: set the house's flight duration, curve and shadow
/// once, here, and every in-page hero follows.
@immutable
class GlobalInPageHeroTheme extends ThemeExtension<GlobalInPageHeroTheme> {
  const GlobalInPageHeroTheme({this.style});

  final InPageHeroStyle? style;

  static GlobalInPageHeroTheme? maybeOf(BuildContext context) =>
      Theme.of(context).extension<GlobalInPageHeroTheme>();

  @override
  GlobalInPageHeroTheme copyWith({InPageHeroStyle? style}) =>
      GlobalInPageHeroTheme(style: style ?? this.style);

  @override
  GlobalInPageHeroTheme lerp(
    ThemeExtension<GlobalInPageHeroTheme>? other,
    double t,
  ) {
    if (other is! GlobalInPageHeroTheme) return this;
    // A bag of independent decisions, not a value with a midpoint. It
    // SNAPS at the halfway mark, like every other bag in this app.
    return t < 0.5 ? this : other;
  }
}

/// Turns a caller's bag into one with every question answered.
extension InPageHeroStyleResolve on InPageHeroStyle {
  /// `caller > GlobalInPageHeroTheme.style > InPageHeroStyle.defaults`,
  /// then the one thing only a `BuildContext` knows.
  ResolvedInPageHeroStyle resolve(BuildContext context) {
    final merged = InPageHeroStyle.defaults
        .mergedWith(GlobalInPageHeroTheme.maybeOf(context)?.style)
        .mergedWith(this);

    // The READER's setting. A box that flies across the page is the
    // largest motion this module has, and it had no opinion about
    // whether the reader wanted it.
    final respect = merged.respectReducedMotion ?? true;
    final still = respect && MediaQuery.disableAnimationsOf(context);

    return ResolvedInPageHeroStyle(
      // ZERO, not short: the flight is then skipped WHOLE rather than
      // run for no frames — an overlay that inserts and removes itself
      // in one frame still flickers.
      duration: still
          ? Duration.zero
          : (merged.duration ?? InPageHeroDefaults.duration),
      curve: merged.curve ?? InPageHeroDefaults.curve,
      crossfadeStart:
          merged.crossfadeStart ?? InPageHeroDefaults.crossfadeStart,
      crossfadeSpan: merged.crossfadeSpan ?? InPageHeroDefaults.crossfadeSpan,
      // Top-CENTRE: a collapsing endpoint folds toward the corner its
      // content starts at, and centring keeps a card's contents from
      // sliding sideways as the box narrows.
      collapseAlignment:
          merged.collapseAlignment ?? AlignmentDirectional.topCenter,
      flightShadow: merged.flightShadow,
    );
  }
}
