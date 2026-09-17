import 'package:flutter/material.dart';

import '../indicator/indicator_models.dart';
import '../indicator/indicator_style.dart';
import 'page_transitions.dart';

export 'page_transitions.dart' show PageTransition, applyPageTransition;

/// The floor for the page family — `GlobalPageView`, `GlobalCarousel`
/// and `GlobalCarouselView` all resolve against this.
abstract final class PageViewDefaults {
  /// How long a programmatic page change takes.
  static const pageDuration = Duration(milliseconds: 320);

  /// How long the thumbnail strip takes to bring the active tile in.
  static const thumbScrollDuration = Duration(milliseconds: 280);

  /// One thumbnail's width, and the strip's own padding and height.
  static const thumbTileWidth = 64.0;
  static const thumbStripPadding = 12.0;
  static const thumbStripHeight = 76.0;

  /// The pill behind the indicator, when one is asked for.
  static const indicatorPillRadius = 24.0;
  static const indicatorPillPadding = EdgeInsets.symmetric(
    horizontal: 12,
    vertical: 6,
  );

  static const indicatorPadding = EdgeInsets.all(12);
  static const indicatorAlignment = AlignmentDirectional.bottomCenter;

  /// How long a story segment runs when nothing says otherwise.
  static const storyDuration = Duration(seconds: 5);

  /// How long an auto-playing deck rests on a page.
  ///
  /// Long enough to read a banner and short enough that a reader who
  /// looked away has not missed the deck twice.
  static const autoPlayInterval = Duration(seconds: 5);

  /// How far a hover peeks the next page, and how long it takes.
  static const hoverPeekDuration = Duration(milliseconds: 220);

  static const enableHaptic = true;
  static const respectReducedMotion = true;
}

/// Display variant for the page family's built-in indicator. `dots`
/// delegates to `GlobalDotIndicator` with the configured
/// [DotIndicatorEffect] + [DotIndicatorStyle]. `numbered` renders a
/// `1 / N` fraction through `GlobalPageCounter`.
enum PageIndicatorStyle { dots, numbered }

/// Direction the entire page-view collapses toward on dismiss.
enum SwipeDismissDirection { up, down, left, right }

/// How a page view, a carousel or a carousel view looks and behaves.
///
/// ONE bag for the three, because they are the same control with
/// different chrome: two bags would be two rebrand hooks that can
/// disagree, and a house that set an indicator style on one and not
/// the other would get two different dots on one screen.
///
/// Every field is nullable — unanswered means "ask the theme, then the
/// floor". See `theme/page_view_theme.dart` for the resolve.
@immutable
class GlobalPageViewStyle {
  const GlobalPageViewStyle({
    this.indicatorStyle,
    this.indicatorEffect,
    this.dotStyle,
    this.indicatorPadding,
    this.indicatorAlignment,
    this.indicatorBackground,
    this.indicatorPillRadius,
    this.indicatorPillPadding,
    this.numberedActiveColor,
    this.transition,
    this.pageDuration,
    this.pageCurve,
    this.thumbScrollDuration,
    this.thumbTileWidth,
    this.thumbStripPadding,
    this.thumbStripHeight,
    this.storyDuration,
    this.autoPlayInterval,
    this.hoverPeekDuration,
    this.enableHaptic,
    this.respectReducedMotion,
  });

  /// The floor — the only place a compile-time constant lives.
  static const defaults = GlobalPageViewStyle(
    indicatorStyle: PageIndicatorStyle.dots,
    indicatorEffect: DotIndicatorEffect.scale,
    indicatorPadding: PageViewDefaults.indicatorPadding,
    indicatorAlignment: PageViewDefaults.indicatorAlignment,
    indicatorPillRadius: PageViewDefaults.indicatorPillRadius,
    indicatorPillPadding: PageViewDefaults.indicatorPillPadding,
    transition: PageTransition.slide,
    pageDuration: PageViewDefaults.pageDuration,
    pageCurve: Curves.easeOutCubic,
    thumbScrollDuration: PageViewDefaults.thumbScrollDuration,
    thumbTileWidth: PageViewDefaults.thumbTileWidth,
    thumbStripPadding: PageViewDefaults.thumbStripPadding,
    thumbStripHeight: PageViewDefaults.thumbStripHeight,
    storyDuration: PageViewDefaults.storyDuration,
    autoPlayInterval: PageViewDefaults.autoPlayInterval,
    hoverPeekDuration: PageViewDefaults.hoverPeekDuration,
    enableHaptic: PageViewDefaults.enableHaptic,
    respectReducedMotion: PageViewDefaults.respectReducedMotion,
  );

  /// A counter instead of dots — for a deck too long to read as marks.
  static const numbered = GlobalPageViewStyle(
    indicatorStyle: PageIndicatorStyle.numbered,
  );

  /// No indicator chrome of its own: the caller is drawing one, or the
  /// page count is obvious from the content.
  static const bare = GlobalPageViewStyle(
    indicatorPadding: EdgeInsets.zero,
  );

  /// Dots or a counter.
  final PageIndicatorStyle? indicatorStyle;

  /// Which dot effect, when [indicatorStyle] is
  /// [PageIndicatorStyle.dots]. The EFFECTS themselves belong to
  /// `GlobalDotIndicator` — this only says which one to ask for.
  final DotIndicatorEffect? indicatorEffect;

  /// Passed straight through to `GlobalDotIndicator`, so what is not
  /// answered here falls through to `GlobalIndicatorTheme`.
  final DotIndicatorStyle? dotStyle;

  /// Padding around the indicator overlay.
  final EdgeInsetsGeometry? indicatorPadding;

  /// Where the indicator sits in the page view's `Stack`.
  final AlignmentGeometry? indicatorAlignment;

  /// A pill painted behind the indicator. Null draws none — over a
  /// photograph it is the difference between readable and not.
  final Color? indicatorBackground;

  /// The pill's corner.
  final double? indicatorPillRadius;

  /// The pill's padding.
  final EdgeInsetsGeometry? indicatorPillPadding;

  /// Text colour for [PageIndicatorStyle.numbered].
  final Color? numberedActiveColor;

  /// The transform between pages — slide / fade / scale / depth /
  /// parallax / cube / flip / coverflow / stack.
  final PageTransition? transition;

  /// How long a programmatic page change takes. Zero under reduced
  /// motion.
  final Duration? pageDuration;

  final Curve? pageCurve;

  /// How long the thumbnail strip takes to bring the active tile in.
  /// Zero under reduced motion.
  final Duration? thumbScrollDuration;

  final double? thumbTileWidth;
  final double? thumbStripPadding;
  final double? thumbStripHeight;

  /// How long a story segment runs when [GlobalPageView.storyDurations]
  /// says nothing.
  ///
  /// NOT zeroed by reduced motion: it is the pace of the CONTENT, and
  /// a reader who asked for less motion has not asked for the story to
  /// flash past.
  final Duration? storyDuration;

  /// How long an auto-playing deck rests on a page.
  ///
  /// NOT zeroed by reduced motion, for the same reason the story pace
  /// is not: it is how long the CONTENT stays, and a reader who asked
  /// for less motion has not asked to be given less time to read.
  final Duration? autoPlayInterval;

  /// How long a hover takes to peek the next page. Zero under reduced
  /// motion.
  final Duration? hoverPeekDuration;

  /// Whether a page change ticks. A swipe already has the page moving
  /// under the finger, so this is for the changes a finger did NOT
  /// make — a tap on the indicator, a keyboard arrow, a story
  /// advancing on its own.
  final bool? enableHaptic;

  final bool? respectReducedMotion;

  /// Field-by-field: whatever `other` answers wins, and what it leaves
  /// null keeps this bag's answer.
  GlobalPageViewStyle mergedWith(GlobalPageViewStyle? other) {
    if (other == null) return this;
    return GlobalPageViewStyle(
      indicatorStyle: other.indicatorStyle ?? indicatorStyle,
      indicatorEffect: other.indicatorEffect ?? indicatorEffect,
      dotStyle: dotStyle == null
          ? other.dotStyle
          : dotStyle!.mergedWith(other.dotStyle),
      indicatorPadding: other.indicatorPadding ?? indicatorPadding,
      indicatorAlignment: other.indicatorAlignment ?? indicatorAlignment,
      indicatorBackground: other.indicatorBackground ?? indicatorBackground,
      indicatorPillRadius: other.indicatorPillRadius ?? indicatorPillRadius,
      indicatorPillPadding: other.indicatorPillPadding ?? indicatorPillPadding,
      numberedActiveColor: other.numberedActiveColor ?? numberedActiveColor,
      transition: other.transition ?? transition,
      pageDuration: other.pageDuration ?? pageDuration,
      pageCurve: other.pageCurve ?? pageCurve,
      thumbScrollDuration: other.thumbScrollDuration ?? thumbScrollDuration,
      thumbTileWidth: other.thumbTileWidth ?? thumbTileWidth,
      thumbStripPadding: other.thumbStripPadding ?? thumbStripPadding,
      thumbStripHeight: other.thumbStripHeight ?? thumbStripHeight,
      storyDuration: other.storyDuration ?? storyDuration,
      autoPlayInterval: other.autoPlayInterval ?? autoPlayInterval,
      hoverPeekDuration: other.hoverPeekDuration ?? hoverPeekDuration,
      enableHaptic: other.enableHaptic ?? enableHaptic,
      respectReducedMotion: other.respectReducedMotion ?? respectReducedMotion,
    );
  }

  GlobalPageViewStyle copyWith({
    PageIndicatorStyle? indicatorStyle,
    DotIndicatorEffect? indicatorEffect,
    DotIndicatorStyle? dotStyle,
    EdgeInsetsGeometry? indicatorPadding,
    AlignmentGeometry? indicatorAlignment,
    Color? indicatorBackground,
    double? indicatorPillRadius,
    EdgeInsetsGeometry? indicatorPillPadding,
    Color? numberedActiveColor,
    PageTransition? transition,
    Duration? pageDuration,
    Curve? pageCurve,
    Duration? thumbScrollDuration,
    double? thumbTileWidth,
    double? thumbStripPadding,
    double? thumbStripHeight,
    Duration? storyDuration,
    Duration? autoPlayInterval,
    Duration? hoverPeekDuration,
    bool? enableHaptic,
    bool? respectReducedMotion,
  }) => GlobalPageViewStyle(
    indicatorStyle: indicatorStyle ?? this.indicatorStyle,
    indicatorEffect: indicatorEffect ?? this.indicatorEffect,
    dotStyle: dotStyle ?? this.dotStyle,
    indicatorPadding: indicatorPadding ?? this.indicatorPadding,
    indicatorAlignment: indicatorAlignment ?? this.indicatorAlignment,
    indicatorBackground: indicatorBackground ?? this.indicatorBackground,
    indicatorPillRadius: indicatorPillRadius ?? this.indicatorPillRadius,
    indicatorPillPadding: indicatorPillPadding ?? this.indicatorPillPadding,
    numberedActiveColor: numberedActiveColor ?? this.numberedActiveColor,
    transition: transition ?? this.transition,
    pageDuration: pageDuration ?? this.pageDuration,
    pageCurve: pageCurve ?? this.pageCurve,
    thumbScrollDuration: thumbScrollDuration ?? this.thumbScrollDuration,
    thumbTileWidth: thumbTileWidth ?? this.thumbTileWidth,
    thumbStripPadding: thumbStripPadding ?? this.thumbStripPadding,
    thumbStripHeight: thumbStripHeight ?? this.thumbStripHeight,
    storyDuration: storyDuration ?? this.storyDuration,
    autoPlayInterval: autoPlayInterval ?? this.autoPlayInterval,
    hoverPeekDuration: hoverPeekDuration ?? this.hoverPeekDuration,
    enableHaptic: enableHaptic ?? this.enableHaptic,
    respectReducedMotion: respectReducedMotion ?? this.respectReducedMotion,
  );

  @override
  bool operator ==(Object other) =>
      other is GlobalPageViewStyle &&
      other.indicatorStyle == indicatorStyle &&
      other.indicatorEffect == indicatorEffect &&
      other.dotStyle == dotStyle &&
      other.indicatorPadding == indicatorPadding &&
      other.indicatorAlignment == indicatorAlignment &&
      other.indicatorBackground == indicatorBackground &&
      other.indicatorPillRadius == indicatorPillRadius &&
      other.indicatorPillPadding == indicatorPillPadding &&
      other.numberedActiveColor == numberedActiveColor &&
      other.transition == transition &&
      other.pageDuration == pageDuration &&
      other.pageCurve == pageCurve &&
      other.thumbScrollDuration == thumbScrollDuration &&
      other.thumbTileWidth == thumbTileWidth &&
      other.thumbStripPadding == thumbStripPadding &&
      other.thumbStripHeight == thumbStripHeight &&
      other.storyDuration == storyDuration &&
      other.autoPlayInterval == autoPlayInterval &&
      other.hoverPeekDuration == hoverPeekDuration &&
      other.enableHaptic == enableHaptic &&
      other.respectReducedMotion == respectReducedMotion;

  @override
  int get hashCode => Object.hashAll([
    indicatorStyle,
    indicatorEffect,
    dotStyle,
    indicatorPadding,
    indicatorAlignment,
    indicatorBackground,
    indicatorPillRadius,
    indicatorPillPadding,
    numberedActiveColor,
    transition,
    pageDuration,
    pageCurve,
    thumbScrollDuration,
    thumbTileWidth,
    thumbStripPadding,
    thumbStripHeight,
    storyDuration,
    autoPlayInterval,
    hoverPeekDuration,
    enableHaptic,
    respectReducedMotion,
  ]);
}

/// A [GlobalPageViewStyle] with every question answered.
@immutable
class ResolvedPageViewStyle {
  const ResolvedPageViewStyle({
    required this.indicatorStyle,
    required this.indicatorEffect,
    required this.dotStyle,
    required this.indicatorPadding,
    required this.indicatorAlignment,
    required this.indicatorBackground,
    required this.indicatorPillRadius,
    required this.indicatorPillPadding,
    required this.numberedActiveColor,
    required this.transition,
    required this.pageDuration,
    required this.pageCurve,
    required this.thumbScrollDuration,
    required this.thumbTileWidth,
    required this.thumbStripPadding,
    required this.thumbStripHeight,
    required this.storyDuration,
    required this.autoPlayInterval,
    required this.hoverPeekDuration,
    required this.enableHaptic,
    required this.still,
  });

  final PageIndicatorStyle indicatorStyle;
  final DotIndicatorEffect indicatorEffect;

  /// Still nullable AFTER the resolve: unset means the dot indicator
  /// answers from its OWN theme, which is where a dot's look belongs.
  final DotIndicatorStyle? dotStyle;

  final EdgeInsetsGeometry indicatorPadding;
  final AlignmentGeometry indicatorAlignment;

  /// Null draws no pill.
  final Color? indicatorBackground;

  final double indicatorPillRadius;
  final EdgeInsetsGeometry indicatorPillPadding;
  final Color? numberedActiveColor;

  /// Collapsed to [PageTransition.slide] under reduced motion — the
  /// pages still move, because that IS the control, but nothing spins
  /// or folds on the way.
  final PageTransition transition;

  /// Zero under reduced motion.
  final Duration pageDuration;

  final Curve pageCurve;

  /// Zero under reduced motion.
  final Duration thumbScrollDuration;

  final double thumbTileWidth;
  final double thumbStripPadding;
  final double thumbStripHeight;

  /// NOT zeroed: the pace of the content, not motion.
  final Duration storyDuration;

  /// NOT zeroed either — see [GlobalPageViewStyle.autoPlayInterval].
  final Duration autoPlayInterval;

  /// Zero under reduced motion.
  final Duration hoverPeekDuration;

  final bool enableHaptic;

  /// Whether the reader has asked for motion to stop.
  final bool still;
}
