import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';

import '../page_view_models.dart';

/// App-wide defaults for the page FAMILY — `GlobalPageView`,
/// `GlobalCarousel` and `GlobalCarouselView`.
///
/// One extension for the three, because they are the same control with
/// different chrome. Two would be two rebrand hooks that can disagree,
/// and a house that set an indicator on one and not the other would
/// get two different dots on one screen — the same argument the
/// collections' shared theme makes.
@immutable
class GlobalPageViewTheme extends ThemeExtension<GlobalPageViewTheme> {
  const GlobalPageViewTheme({this.style});

  final GlobalPageViewStyle? style;

  static GlobalPageViewTheme? maybeOf(BuildContext context) =>
      Theme.of(context).extension<GlobalPageViewTheme>();

  @override
  GlobalPageViewTheme copyWith({GlobalPageViewStyle? style}) =>
      GlobalPageViewTheme(style: style ?? this.style);

  @override
  GlobalPageViewTheme lerp(
    ThemeExtension<GlobalPageViewTheme>? other,
    double t,
  ) {
    if (other is! GlobalPageViewTheme) return this;
    return GlobalPageViewTheme(style: _lerpStyle(style, other.style, t));
  }

  /// Continuous fields interpolate; discrete ones SNAP at the midpoint
  /// — half a cube transition is not a thing, and neither is half a
  /// dot effect.
  static GlobalPageViewStyle? _lerpStyle(
    GlobalPageViewStyle? a,
    GlobalPageViewStyle? b,
    double t,
  ) {
    if (a == null && b == null) return null;
    final pick = t < 0.5 ? a : b;
    return GlobalPageViewStyle(
      indicatorBackground: Color.lerp(
        a?.indicatorBackground,
        b?.indicatorBackground,
        t,
      ),
      numberedActiveColor: Color.lerp(
        a?.numberedActiveColor,
        b?.numberedActiveColor,
        t,
      ),
      indicatorPadding: EdgeInsetsGeometry.lerp(
        a?.indicatorPadding,
        b?.indicatorPadding,
        t,
      ),
      indicatorPillPadding: EdgeInsetsGeometry.lerp(
        a?.indicatorPillPadding,
        b?.indicatorPillPadding,
        t,
      ),
      indicatorAlignment: AlignmentGeometry.lerp(
        a?.indicatorAlignment,
        b?.indicatorAlignment,
        t,
      ),
      indicatorPillRadius: lerpDouble(
        a?.indicatorPillRadius,
        b?.indicatorPillRadius,
        t,
      ),
      thumbTileWidth: lerpDouble(a?.thumbTileWidth, b?.thumbTileWidth, t),
      thumbStripPadding: lerpDouble(
        a?.thumbStripPadding,
        b?.thumbStripPadding,
        t,
      ),
      thumbStripHeight: lerpDouble(
        a?.thumbStripHeight,
        b?.thumbStripHeight,
        t,
      ),
      indicatorStyle: pick?.indicatorStyle,
      indicatorEffect: pick?.indicatorEffect,
      dotStyle: pick?.dotStyle,
      transition: pick?.transition,
      pageDuration: pick?.pageDuration,
      pageCurve: pick?.pageCurve,
      thumbScrollDuration: pick?.thumbScrollDuration,
      storyDuration: pick?.storyDuration,
      autoPlayInterval: pick?.autoPlayInterval,
      hoverPeekDuration: pick?.hoverPeekDuration,
      enableHaptic: pick?.enableHaptic,
      respectReducedMotion: pick?.respectReducedMotion,
    );
  }
}

extension PageViewStyleResolve on GlobalPageViewStyle {
  /// Stacks `caller > GlobalPageViewTheme.style > defaults`.
  ///
  /// No colours are filled in here: the indicator's own look belongs to
  /// `GlobalIndicatorTheme`, and this bag only says WHICH indicator and
  /// where it sits. A page view that filled in dot colours would be a
  /// second place to set them.
  ResolvedPageViewStyle resolve(BuildContext context) {
    final merged = GlobalPageViewStyle.defaults
        .mergedWith(GlobalPageViewTheme.maybeOf(context)?.style)
        .mergedWith(this);
    const floor = GlobalPageViewStyle.defaults;

    final respect = merged.respectReducedMotion ?? floor.respectReducedMotion!;
    final still = respect && MediaQuery.disableAnimationsOf(context);

    return ResolvedPageViewStyle(
      indicatorStyle: merged.indicatorStyle ?? floor.indicatorStyle!,
      indicatorEffect: merged.indicatorEffect ?? floor.indicatorEffect!,
      dotStyle: merged.dotStyle,
      indicatorPadding: merged.indicatorPadding ?? floor.indicatorPadding!,
      indicatorAlignment:
          merged.indicatorAlignment ?? floor.indicatorAlignment!,
      indicatorBackground: merged.indicatorBackground,
      indicatorPillRadius:
          merged.indicatorPillRadius ?? floor.indicatorPillRadius!,
      indicatorPillPadding:
          merged.indicatorPillPadding ?? floor.indicatorPillPadding!,
      numberedActiveColor: merged.numberedActiveColor,
      // SLIDE under reduced motion, not "none": the pages still have
      // to move, because moving between them IS the control. What goes
      // is the spinning, folding and scaling on the way.
      transition: still
          ? PageTransition.slide
          : (merged.transition ?? floor.transition!),
      pageDuration: still
          ? Duration.zero
          : (merged.pageDuration ?? floor.pageDuration!),
      pageCurve: merged.pageCurve ?? floor.pageCurve!,
      thumbScrollDuration: still
          ? Duration.zero
          : (merged.thumbScrollDuration ?? floor.thumbScrollDuration!),
      thumbTileWidth: merged.thumbTileWidth ?? floor.thumbTileWidth!,
      thumbStripPadding: merged.thumbStripPadding ?? floor.thumbStripPadding!,
      thumbStripHeight: merged.thumbStripHeight ?? floor.thumbStripHeight!,
      // NOT zeroed: the pace of the CONTENT. A reader who asked for
      // less motion has not asked for the story to flash past.
      storyDuration: merged.storyDuration ?? floor.storyDuration!,
      autoPlayInterval: merged.autoPlayInterval ?? floor.autoPlayInterval!,
      hoverPeekDuration: still
          ? Duration.zero
          : (merged.hoverPeekDuration ?? floor.hoverPeekDuration!),
      enableHaptic: merged.enableHaptic ?? floor.enableHaptic!,
      still: still,
    );
  }
}
