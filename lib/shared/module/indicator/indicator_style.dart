import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'indicator_models.dart';

// ---------------------------------------------------------------------------
// Defaults — every number a dot row draws with
// ---------------------------------------------------------------------------

/// The compile-time floor under [DotIndicatorStyle].
///
/// Sizes a token can express are NOT here — they come from
/// `MyGlobalIndicatorTheme.build`, which reads `AppTokens` and so
/// tracks the window bucket. What is here is what a token cannot say:
/// the geometry of the effects, and the opacities.
abstract final class IndicatorDefaults {
  // ─── The dots ─────────────────────────────────────────────
  static const dotSize = 8.0;
  static const activeDotSize = 10.0;
  static const dotSpacing = 8.0;
  static const radius = 8.0;
  static const borderWidth = 0.0;

  // ─── Motion ───────────────────────────────────────────────
  static const duration = Duration(milliseconds: 280);
  static const curve = Curves.easeOutCubic;

  // ─── Per-effect geometry ──────────────────────────────────
  /// How long the active pill grows in `expanding`, as a multiple of
  /// [dotSize].
  static const expansionFactor = 3.5;

  /// And the shorter one `slide` uses: a marker covers roughly one dot
  /// plus a halo, where a long pill reads as misaligned against the
  /// rail of inactive dots behind it.
  static const slideMarkerFactor = 1.6;

  /// How far the old dot falls out — and the new one falls in — in
  /// `drop`, as a multiple of [dotSize].
  static const dropDistanceFactor = 1.8;

  /// The lowest the active dot dims to during a `flash`.
  static const flashMinOpacity = 0.35;

  static const splashRingWidth = 2.0;
  static const splashMaxRadiusFactor = 2.4;

  // ─── scrollingDots ────────────────────────────────────────
  static const scrollingDotsCenterScale = 1.4;

  /// Odd, so the active dot can sit dead centre.
  static const scrollingDotsVisibleCount = 5;

  /// The floor under an inactive dot's alpha, so an edge dot does not
  /// fade to nothing and pop as it crosses the boundary.
  static const scrollingDotsMinAlpha = 0.25;

  /// A transparent target around each dot. The edge ones shrink small,
  /// and without this they become unhittable.
  static const scrollingDotsHitZone = 28.0;

  // ─── The row's box ────────────────────────────────────────
  /// The headroom `jumping` arcs into, as a multiple of [dotSize].
  ///
  /// Reserved for EVERY effect, so swapping one for another does not
  /// shove whatever is above and below it up and down.
  static const reservedHeightFactor = 2.5;

  /// What an inactive colour is against the page.
  static const inactiveOpacity = 1.0;

  // ─── The story bar ────────────────────────────────────────
  static const storyHeight = 3.0;
  static const storySpacing = 4.0;
  static const storyRadius = 2.0;

  /// The rail behind a story segment — it sits over PHOTOGRAPHS, so it
  /// is white at low alpha rather than a palette colour.
  static const storyTrackOpacity = 0.25;
}

// ---------------------------------------------------------------------------
// The bag
// ---------------------------------------------------------------------------

/// Every knob a dot row has, all of it optional.
///
/// Resolution order is `caller > GlobalIndicatorTheme.dotStyle >
/// DotIndicatorStyle.defaults`, and the resolve is where the palette
/// and the reader's reduce-motion setting are applied.
@immutable
class DotIndicatorStyle {
  const DotIndicatorStyle({
    this.activeColor,
    this.inactiveColor,
    this.gradient,
    this.dotSize,
    this.activeDotSize,
    this.expansionFactor,
    this.slideMarkerFactor,
    this.dotSpacing,
    this.radius,
    this.duration,
    this.curve,
    this.shadow,
    this.scrollingDotsCenterScale,
    this.scrollingDotsVisibleCount,
    this.scrollingDotsMinAlpha,
    this.scrollingDotsFadeEdges,
    this.scrollingDotsHitZone,
    this.shape,
    this.splashRingColor,
    this.splashRingWidth,
    this.splashMaxRadiusFactor,
    this.dropDistanceFactor,
    this.flashMinOpacity,
    this.enableHaptic,
    this.respectReducedMotion,
    this.borderColor,
    this.borderWidth,
    this.paintStyle,
  });

  /// The active dot or marker. Falls back to the brand accent.
  final Color? activeColor;

  /// The rest of them.
  final Color? inactiveColor;

  /// Wins over [activeColor] — paints the active dot with a gradient.
  final Gradient? gradient;

  final double? dotSize;

  /// The active dot's diameter for `scale`, `color` and `swap`.
  final double? activeDotSize;

  /// See [IndicatorDefaults.expansionFactor].
  final double? expansionFactor;

  /// See [IndicatorDefaults.slideMarkerFactor].
  final double? slideMarkerFactor;

  final double? dotSpacing;

  /// Below `dotSize / 2` the dots become rounded rectangles.
  final double? radius;

  final Duration? duration;
  final Curve? curve;

  /// Under the active dot or marker.
  final List<BoxShadow>? shadow;

  final double? scrollingDotsCenterScale;
  final int? scrollingDotsVisibleCount;
  final double? scrollingDotsMinAlpha;

  /// A soft fade at both ends of the strip, which says it scrolls and
  /// hides the pop as dots enter and leave.
  final bool? scrollingDotsFadeEdges;

  final double? scrollingDotsHitZone;

  /// The shape of every dot. Ignored when the caller supplies an
  /// `itemBuilder` — a custom widget IS the shape.
  final DotShape? shape;

  final Color? splashRingColor;
  final double? splashRingWidth;
  final double? splashMaxRadiusFactor;
  final double? dropDistanceFactor;
  final double? flashMinOpacity;

  /// A light tap on a dot tap.
  final bool? enableHaptic;

  /// Whether the reader's reduce-motion setting collapses the
  /// transition to an instant one.
  ///
  /// True everywhere except an indicator whose motion IS the content.
  final bool? respectReducedMotion;

  /// An outline on inactive dots. The active one is filled, so it wins.
  final Color? borderColor;
  final double? borderWidth;

  /// `fill` for solid dots, `stroke` for outlines — the active dot
  /// stays filled either way.
  final PaintingStyle? paintStyle;

  /// Nothing answered. The floor lives in [IndicatorDefaults].
  static const DotIndicatorStyle defaults = DotIndicatorStyle();

  /// Small, quiet, no motion to speak of — for a row of dots under
  /// content that should not compete with it.
  static const DotIndicatorStyle subtle = DotIndicatorStyle(
    dotSize: 6,
    activeDotSize: 6,
    dotSpacing: 6,
  );

  /// A long pill for the active page, the shape most onboarding flows
  /// use.
  static const DotIndicatorStyle pill = DotIndicatorStyle(
    shape: DotShape.pill,
    expansionFactor: 4,
  );

  /// Outlines, with only the active dot filled.
  static const DotIndicatorStyle outlined = DotIndicatorStyle(
    paintStyle: PaintingStyle.stroke,
    borderWidth: 1.5,
  );

  /// `other` wins field by field; `null` on `other` keeps ours.
  DotIndicatorStyle mergedWith(DotIndicatorStyle? other) {
    if (other == null) return this;
    return DotIndicatorStyle(
      activeColor: other.activeColor ?? activeColor,
      inactiveColor: other.inactiveColor ?? inactiveColor,
      gradient: other.gradient ?? gradient,
      dotSize: other.dotSize ?? dotSize,
      activeDotSize: other.activeDotSize ?? activeDotSize,
      expansionFactor: other.expansionFactor ?? expansionFactor,
      slideMarkerFactor: other.slideMarkerFactor ?? slideMarkerFactor,
      dotSpacing: other.dotSpacing ?? dotSpacing,
      radius: other.radius ?? radius,
      duration: other.duration ?? duration,
      curve: other.curve ?? curve,
      shadow: other.shadow ?? shadow,
      scrollingDotsCenterScale:
          other.scrollingDotsCenterScale ?? scrollingDotsCenterScale,
      scrollingDotsVisibleCount:
          other.scrollingDotsVisibleCount ?? scrollingDotsVisibleCount,
      scrollingDotsMinAlpha:
          other.scrollingDotsMinAlpha ?? scrollingDotsMinAlpha,
      scrollingDotsFadeEdges:
          other.scrollingDotsFadeEdges ?? scrollingDotsFadeEdges,
      scrollingDotsHitZone: other.scrollingDotsHitZone ?? scrollingDotsHitZone,
      shape: other.shape ?? shape,
      splashRingColor: other.splashRingColor ?? splashRingColor,
      splashRingWidth: other.splashRingWidth ?? splashRingWidth,
      splashMaxRadiusFactor:
          other.splashMaxRadiusFactor ?? splashMaxRadiusFactor,
      dropDistanceFactor: other.dropDistanceFactor ?? dropDistanceFactor,
      flashMinOpacity: other.flashMinOpacity ?? flashMinOpacity,
      enableHaptic: other.enableHaptic ?? enableHaptic,
      respectReducedMotion: other.respectReducedMotion ?? respectReducedMotion,
      borderColor: other.borderColor ?? borderColor,
      borderWidth: other.borderWidth ?? borderWidth,
      paintStyle: other.paintStyle ?? paintStyle,
    );
  }

  DotIndicatorStyle copyWith({
    Color? activeColor,
    Color? inactiveColor,
    Gradient? gradient,
    double? dotSize,
    double? activeDotSize,
    double? expansionFactor,
    double? slideMarkerFactor,
    double? dotSpacing,
    double? radius,
    Duration? duration,
    Curve? curve,
    List<BoxShadow>? shadow,
    double? scrollingDotsCenterScale,
    int? scrollingDotsVisibleCount,
    double? scrollingDotsMinAlpha,
    bool? scrollingDotsFadeEdges,
    double? scrollingDotsHitZone,
    DotShape? shape,
    Color? splashRingColor,
    double? splashRingWidth,
    double? splashMaxRadiusFactor,
    double? dropDistanceFactor,
    double? flashMinOpacity,
    bool? enableHaptic,
    bool? respectReducedMotion,
    Color? borderColor,
    double? borderWidth,
    PaintingStyle? paintStyle,
  }) => DotIndicatorStyle(
    activeColor: activeColor ?? this.activeColor,
    inactiveColor: inactiveColor ?? this.inactiveColor,
    gradient: gradient ?? this.gradient,
    dotSize: dotSize ?? this.dotSize,
    activeDotSize: activeDotSize ?? this.activeDotSize,
    expansionFactor: expansionFactor ?? this.expansionFactor,
    slideMarkerFactor: slideMarkerFactor ?? this.slideMarkerFactor,
    dotSpacing: dotSpacing ?? this.dotSpacing,
    radius: radius ?? this.radius,
    duration: duration ?? this.duration,
    curve: curve ?? this.curve,
    shadow: shadow ?? this.shadow,
    scrollingDotsCenterScale:
        scrollingDotsCenterScale ?? this.scrollingDotsCenterScale,
    scrollingDotsVisibleCount:
        scrollingDotsVisibleCount ?? this.scrollingDotsVisibleCount,
    scrollingDotsMinAlpha: scrollingDotsMinAlpha ?? this.scrollingDotsMinAlpha,
    scrollingDotsFadeEdges:
        scrollingDotsFadeEdges ?? this.scrollingDotsFadeEdges,
    scrollingDotsHitZone: scrollingDotsHitZone ?? this.scrollingDotsHitZone,
    shape: shape ?? this.shape,
    splashRingColor: splashRingColor ?? this.splashRingColor,
    splashRingWidth: splashRingWidth ?? this.splashRingWidth,
    splashMaxRadiusFactor: splashMaxRadiusFactor ?? this.splashMaxRadiusFactor,
    dropDistanceFactor: dropDistanceFactor ?? this.dropDistanceFactor,
    flashMinOpacity: flashMinOpacity ?? this.flashMinOpacity,
    enableHaptic: enableHaptic ?? this.enableHaptic,
    respectReducedMotion: respectReducedMotion ?? this.respectReducedMotion,
    borderColor: borderColor ?? this.borderColor,
    borderWidth: borderWidth ?? this.borderWidth,
    paintStyle: paintStyle ?? this.paintStyle,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DotIndicatorStyle &&
          other.activeColor == activeColor &&
          other.inactiveColor == inactiveColor &&
          other.gradient == gradient &&
          other.dotSize == dotSize &&
          other.activeDotSize == activeDotSize &&
          other.expansionFactor == expansionFactor &&
          other.slideMarkerFactor == slideMarkerFactor &&
          other.dotSpacing == dotSpacing &&
          other.radius == radius &&
          other.duration == duration &&
          other.curve == curve &&
          listEquals(other.shadow, shadow) &&
          other.scrollingDotsCenterScale == scrollingDotsCenterScale &&
          other.scrollingDotsVisibleCount == scrollingDotsVisibleCount &&
          other.scrollingDotsMinAlpha == scrollingDotsMinAlpha &&
          other.scrollingDotsFadeEdges == scrollingDotsFadeEdges &&
          other.scrollingDotsHitZone == scrollingDotsHitZone &&
          other.shape == shape &&
          other.splashRingColor == splashRingColor &&
          other.splashRingWidth == splashRingWidth &&
          other.splashMaxRadiusFactor == splashMaxRadiusFactor &&
          other.dropDistanceFactor == dropDistanceFactor &&
          other.flashMinOpacity == flashMinOpacity &&
          other.enableHaptic == enableHaptic &&
          other.respectReducedMotion == respectReducedMotion &&
          other.borderColor == borderColor &&
          other.borderWidth == borderWidth &&
          other.paintStyle == paintStyle;

  @override
  int get hashCode => Object.hashAll([
    activeColor,
    inactiveColor,
    gradient,
    dotSize,
    activeDotSize,
    expansionFactor,
    slideMarkerFactor,
    dotSpacing,
    radius,
    duration,
    curve,
    shadow == null ? null : Object.hashAll(shadow!),
    scrollingDotsCenterScale,
    scrollingDotsVisibleCount,
    scrollingDotsMinAlpha,
    scrollingDotsFadeEdges,
    scrollingDotsHitZone,
    shape,
    splashRingColor,
    splashRingWidth,
    splashMaxRadiusFactor,
    dropDistanceFactor,
    flashMinOpacity,
    enableHaptic,
    respectReducedMotion,
    borderColor,
    borderWidth,
    paintStyle,
  ]);
}

// ---------------------------------------------------------------------------
// The bag with every question answered
// ---------------------------------------------------------------------------

/// What [GlobalDotIndicator] actually draws with.
@immutable
class ResolvedDotIndicatorStyle {
  const ResolvedDotIndicatorStyle({
    required this.activeColor,
    required this.inactiveColor,
    this.gradient,
    required this.dotSize,
    required this.activeDotSize,
    required this.expansionFactor,
    required this.slideMarkerFactor,
    required this.dotSpacing,
    required this.radius,
    required this.duration,
    required this.curve,
    this.shadow,
    required this.scrollingDotsCenterScale,
    required this.scrollingDotsVisibleCount,
    required this.scrollingDotsMinAlpha,
    required this.scrollingDotsFadeEdges,
    required this.scrollingDotsHitZone,
    required this.shape,
    required this.splashRingColor,
    required this.splashRingWidth,
    required this.splashMaxRadiusFactor,
    required this.dropDistanceFactor,
    required this.flashMinOpacity,
    required this.enableHaptic,
    this.borderColor,
    required this.borderWidth,
    required this.paintStyle,
  });

  final Color activeColor;
  final Color inactiveColor;
  final Gradient? gradient;
  final double dotSize;
  final double activeDotSize;
  final double expansionFactor;
  final double slideMarkerFactor;
  final double dotSpacing;
  final double radius;
  final Duration duration;
  final Curve curve;
  final List<BoxShadow>? shadow;
  final double scrollingDotsCenterScale;
  final int scrollingDotsVisibleCount;
  final double scrollingDotsMinAlpha;
  final bool scrollingDotsFadeEdges;
  final double scrollingDotsHitZone;
  final DotShape shape;
  final Color splashRingColor;
  final double splashRingWidth;
  final double splashMaxRadiusFactor;
  final double dropDistanceFactor;
  final double flashMinOpacity;
  final bool enableHaptic;
  final Color? borderColor;
  final double borderWidth;
  final PaintingStyle paintStyle;

  /// Whether a transition still moves.
  ///
  /// Reduced motion resolves [duration] to zero, and every effect then
  /// lands on its end state in one frame rather than animating there.
  bool get isInstant => duration == Duration.zero;

  /// The height the row reserves whatever the effect is, so swapping
  /// one for another does not shove its neighbours around.
  double get reservedHeight {
    final arc = dotSize * IndicatorDefaults.reservedHeightFactor;
    final scrolling = dotSize * scrollingDotsCenterScale + 4;
    return arc > activeDotSize
        ? (arc > scrolling ? arc : scrolling)
        : (activeDotSize > scrolling ? activeDotSize : scrolling);
  }
}

// ---------------------------------------------------------------------------
// The story bar
// ---------------------------------------------------------------------------

/// Every knob [GlobalStoryIndicator] has.
@immutable
class StoryIndicatorStyle {
  const StoryIndicatorStyle({
    this.activeColor,
    this.inactiveColor,
    this.height,
    this.spacing,
    this.radius,
    this.enableHaptic,
  });

  final Color? activeColor;
  final Color? inactiveColor;
  final double? height;
  final double? spacing;
  final double? radius;
  final bool? enableHaptic;

  static const StoryIndicatorStyle defaults = StoryIndicatorStyle();

  StoryIndicatorStyle mergedWith(StoryIndicatorStyle? other) {
    if (other == null) return this;
    return StoryIndicatorStyle(
      activeColor: other.activeColor ?? activeColor,
      inactiveColor: other.inactiveColor ?? inactiveColor,
      height: other.height ?? height,
      spacing: other.spacing ?? spacing,
      radius: other.radius ?? radius,
      enableHaptic: other.enableHaptic ?? enableHaptic,
    );
  }

  StoryIndicatorStyle copyWith({
    Color? activeColor,
    Color? inactiveColor,
    double? height,
    double? spacing,
    double? radius,
    bool? enableHaptic,
  }) => StoryIndicatorStyle(
    activeColor: activeColor ?? this.activeColor,
    inactiveColor: inactiveColor ?? this.inactiveColor,
    height: height ?? this.height,
    spacing: spacing ?? this.spacing,
    radius: radius ?? this.radius,
    enableHaptic: enableHaptic ?? this.enableHaptic,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is StoryIndicatorStyle &&
          other.activeColor == activeColor &&
          other.inactiveColor == inactiveColor &&
          other.height == height &&
          other.spacing == spacing &&
          other.radius == radius &&
          other.enableHaptic == enableHaptic;

  @override
  int get hashCode => Object.hash(
    activeColor,
    inactiveColor,
    height,
    spacing,
    radius,
    enableHaptic,
  );
}

/// What [GlobalStoryIndicator] draws with.
@immutable
class ResolvedStoryIndicatorStyle {
  const ResolvedStoryIndicatorStyle({
    required this.activeColor,
    required this.inactiveColor,
    required this.height,
    required this.spacing,
    required this.radius,
    required this.enableHaptic,
  });

  final Color activeColor;
  final Color inactiveColor;
  final double height;
  final double spacing;
  final double radius;
  final bool enableHaptic;
}
