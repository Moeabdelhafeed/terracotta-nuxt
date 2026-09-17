/// Animation effect for [GlobalDotIndicator]. Every variant renders
/// a row of dots — the difference is *how* the active state moves
/// or morphs between positions.
enum DotIndicatorEffect {
  /// Classic pagination dots. Inactive dots stay at [DotIndicatorStyle.dotSize];
  /// the active dot grows to [DotIndicatorStyle.activeDotSize] and tints.
  /// No motion between cells — each dot animates in place.
  scale,

  /// Active dot stretches sideways into a pill, anchored on the
  /// previous position, as the index advances (Instagram-style).
  worm,

  /// The active dot expands into a pill (longer than inactive dots).
  /// As the index changes, the old pill shrinks back into a dot and
  /// the new one expands.
  expanding,

  /// Inactive dots stay still. A single pill-shaped "marker" slides
  /// across the row over them — the marker is the only colored
  /// shape; dots remain in the inactive color.
  slide,

  /// Single dot bounces (parabolic arc) between adjacent positions
  /// on each index change.
  jumping,

  /// All dots stay the same size; only the active one tints.
  /// Cheap + minimal — used when motion would distract.
  color,

  /// Strip of dots scrolls horizontally so the active dot sits
  /// roughly centered. Surrounding dots shrink as they leave the
  /// center. Used for very long page counts (≥20).
  scrollingDots,

  /// Active dot and the one being replaced trade colors as the
  /// index advances. No size change.
  swap,

  /// Active dot pulses opacity (dim → bright) during the transition.
  /// Same size as inactive dots.
  flash,

  /// Active dot spins 360° as it slides between positions.
  /// Combines with [DotIndicatorStyle.shape] for the most fun.
  rotate,

  /// Active dot's shape morphs through `circle → square → circle`
  /// during the slide. Pairs with [DotShape.circle] only — overrides
  /// the shape mid-transition.
  morph,

  /// Old active dot drops out downward; new active dot drops in
  /// from above. Vertical motion.
  drop,

  /// Same as [scale] but uses an elastic spring curve — active dot
  /// overshoots then settles.
  bounce,

  /// Active dot emits an expanding ring on settle. Layered on top
  /// of the [scale] effect.
  splash,

  /// Inactive dots between [_from] and [_to] tint briefly in
  /// sequence as the active state cascades to its new position.
  chain,
}

/// Visual shape for individual dots.
enum DotShape {
  circle,
  square,
  diamond,
  pill,
  star,
}
