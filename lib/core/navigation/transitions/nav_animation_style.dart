import 'package:flutter/material.dart';

import '../../animations/animation_presets.dart';

// ---------------------------------------------------------------------------
// Defaults
// ---------------------------------------------------------------------------

/// The compile-time floor under [WidgetAnimation].
///
/// The app-wide layer is `MyGlobalNavAnimationTheme.build`, which sets
/// the house's duration and curve for every widget that animates on a
/// navigation event.
abstract final class NavAnimationDefaults {
  static const duration = AppDurations.slow;
  static const curve = Curves.easeOutCubic;
  static const delay = Duration.zero;

  /// How far a `slide*` preset travels, as a fraction of the widget.
  static const slideDistance = 1.0;

  /// The gentler travel a "half" entrance uses.
  static const shortSlideDistance = 0.5;

  /// What `scaleUp` / `scaleDown` reach for.
  static const bigScale = 0.5;

  /// And the subtler pair.
  static const smallScale = 0.8;
}

// ---------------------------------------------------------------------------
// The bag
// ---------------------------------------------------------------------------

/// One animation, played when a navigation event fires.
///
/// Slide, fade and scale compose — set any pair and they run together.
/// Every field is optional: what a caller leaves open falls through to
/// `GlobalNavAnimationTheme` and then to [NavAnimationDefaults].
@immutable
class WidgetAnimation {
  const WidgetAnimation({
    this.slideFrom,
    this.slideTo,
    this.fadeFrom,
    this.fadeTo,
    this.scaleFrom,
    this.scaleTo,
    this.duration,
    this.curve,
    this.delay,
    this.mirrorInRtl,
    this.respectReducedMotion,
  });

  /// Where the slide starts — `Offset(0, 1)` is "from below".
  final Offset? slideFrom;

  /// And where it ends. `Offset.zero` is the widget's own place.
  final Offset? slideTo;

  final double? fadeFrom;
  final double? fadeTo;
  final double? scaleFrom;
  final double? scaleTo;

  final Duration? duration;
  final Curve? curve;

  /// A wait before it starts, for staggering a column of them.
  final Duration? delay;

  /// Whether the HORIZONTAL travel follows the reading direction.
  ///
  /// The `start` / `end` presets set it; the `left` / `right` ones do
  /// not, because they name a side and a caller who asks for one means
  /// it. Same split the page transitions make.
  final bool? mirrorInRtl;

  /// Whether the reader's reduce-motion setting cancels it.
  ///
  /// True everywhere except an animation that IS the content.
  final bool? respectReducedMotion;

  /// Nothing answered.
  static const WidgetAnimation defaults = WidgetAnimation();

  // ─── Directional presets — they MIRROR ────────────────────
  /// In from the leading edge: the left in English, the right in
  /// Arabic.
  static const slideFromStart = WidgetAnimation(
    slideFrom: Offset(-NavAnimationDefaults.slideDistance, 0),
    slideTo: Offset.zero,
    fadeFrom: 0,
    fadeTo: 1,
    mirrorInRtl: true,
  );

  /// Out to the leading edge.
  static const slideToStart = WidgetAnimation(
    slideFrom: Offset.zero,
    slideTo: Offset(-NavAnimationDefaults.slideDistance, 0),
    fadeFrom: 1,
    fadeTo: 0,
    mirrorInRtl: true,
  );

  /// In from the trailing edge — where a pushed page comes from.
  static const slideFromEnd = WidgetAnimation(
    slideFrom: Offset(NavAnimationDefaults.slideDistance, 0),
    slideTo: Offset.zero,
    fadeFrom: 0,
    fadeTo: 1,
    mirrorInRtl: true,
  );

  /// Out to the trailing edge.
  static const slideToEnd = WidgetAnimation(
    slideFrom: Offset.zero,
    slideTo: Offset(NavAnimationDefaults.slideDistance, 0),
    fadeFrom: 1,
    fadeTo: 0,
    mirrorInRtl: true,
  );

  // ─── Physical presets — they do NOT ───────────────────────
  static const slideFromLeft = WidgetAnimation(
    slideFrom: Offset(-NavAnimationDefaults.slideDistance, 0),
    slideTo: Offset.zero,
    fadeFrom: 0,
    fadeTo: 1,
  );

  static const slideToLeft = WidgetAnimation(
    slideFrom: Offset.zero,
    slideTo: Offset(-NavAnimationDefaults.slideDistance, 0),
    fadeFrom: 1,
    fadeTo: 0,
  );

  static const slideFromRight = WidgetAnimation(
    slideFrom: Offset(NavAnimationDefaults.slideDistance, 0),
    slideTo: Offset.zero,
    fadeFrom: 0,
    fadeTo: 1,
  );

  static const slideToRight = WidgetAnimation(
    slideFrom: Offset.zero,
    slideTo: Offset(NavAnimationDefaults.slideDistance, 0),
    fadeFrom: 1,
    fadeTo: 0,
  );

  // ─── Vertical — no direction to mirror ────────────────────
  static const slideFromBottom = WidgetAnimation(
    slideFrom: Offset(0, NavAnimationDefaults.slideDistance),
    slideTo: Offset.zero,
    fadeFrom: 0,
    fadeTo: 1,
  );

  static const slideToBottom = WidgetAnimation(
    slideFrom: Offset.zero,
    slideTo: Offset(0, NavAnimationDefaults.slideDistance),
    fadeFrom: 1,
    fadeTo: 0,
  );

  static const slideFromTop = WidgetAnimation(
    slideFrom: Offset(0, -NavAnimationDefaults.slideDistance),
    slideTo: Offset.zero,
    fadeFrom: 0,
    fadeTo: 1,
  );

  static const slideToTop = WidgetAnimation(
    slideFrom: Offset.zero,
    slideTo: Offset(0, -NavAnimationDefaults.slideDistance),
    fadeFrom: 1,
    fadeTo: 0,
  );

  // ─── Fade and scale ───────────────────────────────────────
  static const fadeIn = WidgetAnimation(fadeFrom: 0, fadeTo: 1);
  static const fadeOut = WidgetAnimation(fadeFrom: 1, fadeTo: 0);

  static const scaleUp = WidgetAnimation(
    scaleFrom: NavAnimationDefaults.bigScale,
    scaleTo: 1,
    fadeFrom: 0,
    fadeTo: 1,
  );

  static const scaleDown = WidgetAnimation(
    scaleFrom: 1,
    scaleTo: NavAnimationDefaults.bigScale,
    fadeFrom: 1,
    fadeTo: 0,
  );

  static const scaleIn = WidgetAnimation(
    scaleFrom: NavAnimationDefaults.smallScale,
    scaleTo: 1,
    fadeFrom: 0,
    fadeTo: 1,
    curve: Curves.easeOutBack,
  );

  static const scaleOut = WidgetAnimation(
    scaleFrom: 1,
    scaleTo: NavAnimationDefaults.smallScale,
    fadeFrom: 1,
    fadeTo: 0,
    curve: Curves.easeIn,
  );

  /// Nothing moves. Distinct from a null animation, which means "this
  /// event is not handled": `none` handles it and does nothing.
  static const none = WidgetAnimation(duration: Duration.zero);

  /// `other` wins field by field; `null` on `other` keeps ours.
  WidgetAnimation mergedWith(WidgetAnimation? other) {
    if (other == null) return this;
    return WidgetAnimation(
      slideFrom: other.slideFrom ?? slideFrom,
      slideTo: other.slideTo ?? slideTo,
      fadeFrom: other.fadeFrom ?? fadeFrom,
      fadeTo: other.fadeTo ?? fadeTo,
      scaleFrom: other.scaleFrom ?? scaleFrom,
      scaleTo: other.scaleTo ?? scaleTo,
      duration: other.duration ?? duration,
      curve: other.curve ?? curve,
      delay: other.delay ?? delay,
      mirrorInRtl: other.mirrorInRtl ?? mirrorInRtl,
      respectReducedMotion: other.respectReducedMotion ?? respectReducedMotion,
    );
  }

  WidgetAnimation copyWith({
    Offset? slideFrom,
    Offset? slideTo,
    double? fadeFrom,
    double? fadeTo,
    double? scaleFrom,
    double? scaleTo,
    Duration? duration,
    Curve? curve,
    Duration? delay,
    bool? mirrorInRtl,
    bool? respectReducedMotion,
  }) => WidgetAnimation(
    slideFrom: slideFrom ?? this.slideFrom,
    slideTo: slideTo ?? this.slideTo,
    fadeFrom: fadeFrom ?? this.fadeFrom,
    fadeTo: fadeTo ?? this.fadeTo,
    scaleFrom: scaleFrom ?? this.scaleFrom,
    scaleTo: scaleTo ?? this.scaleTo,
    duration: duration ?? this.duration,
    curve: curve ?? this.curve,
    delay: delay ?? this.delay,
    mirrorInRtl: mirrorInRtl ?? this.mirrorInRtl,
    respectReducedMotion: respectReducedMotion ?? this.respectReducedMotion,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WidgetAnimation &&
          other.slideFrom == slideFrom &&
          other.slideTo == slideTo &&
          other.fadeFrom == fadeFrom &&
          other.fadeTo == fadeTo &&
          other.scaleFrom == scaleFrom &&
          other.scaleTo == scaleTo &&
          other.duration == duration &&
          other.curve == curve &&
          other.delay == delay &&
          other.mirrorInRtl == mirrorInRtl &&
          other.respectReducedMotion == respectReducedMotion;

  @override
  int get hashCode => Object.hash(
    slideFrom,
    slideTo,
    fadeFrom,
    fadeTo,
    scaleFrom,
    scaleTo,
    duration,
    curve,
    delay,
    mirrorInRtl,
    respectReducedMotion,
  );
}

// ---------------------------------------------------------------------------
// The bag with every question answered
// ---------------------------------------------------------------------------

/// What `NavigationAwareAnimation` actually plays.
///
/// Reduced motion and the reading direction are already folded in, so
/// the widget builds tweens and nothing else.
@immutable
class ResolvedWidgetAnimation {
  const ResolvedWidgetAnimation({
    required this.duration,
    required this.curve,
    required this.delay,
    this.slideFrom,
    this.slideTo,
    this.fadeFrom,
    this.fadeTo,
    this.scaleFrom,
    this.scaleTo,
  });

  final Duration duration;
  final Curve curve;
  final Duration delay;

  final Offset? slideFrom;
  final Offset? slideTo;
  final double? fadeFrom;
  final double? fadeTo;
  final double? scaleFrom;
  final double? scaleTo;

  bool get hasSlide => slideFrom != null && slideTo != null;
  bool get hasFade => fadeFrom != null && fadeTo != null;
  bool get hasScale => scaleFrom != null && scaleTo != null;

  /// Whether playing this would change anything on screen.
  ///
  /// A zero duration or no pair set means the widget can skip the
  /// controller entirely — which is what reduced motion resolves to.
  bool get isNoop =>
      duration == Duration.zero || (!hasSlide && !hasFade && !hasScale);

  /// Where the widget SITS before its entrance runs.
  ///
  /// Without this an entrance that fades in from zero paints one frame
  /// at full strength first, and a whole column of them flashes.
  double get restingOpacity => fadeFrom ?? 1;
}
