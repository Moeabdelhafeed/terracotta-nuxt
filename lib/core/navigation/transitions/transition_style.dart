import 'package:flutter/material.dart';

import '../../animations/animation_presets.dart';

// ---------------------------------------------------------------------------
// Types
// ---------------------------------------------------------------------------

/// How a page arrives.
///
/// Two families, and the difference matters in Arabic:
///
/// * The **physical** ones — [slideFromRight], [slideFromLeft],
///   [slideFromTop], [slideFromBottom] — name a SIDE, and do exactly
///   what they say in every language. A caller who asks for "from the
///   right" gets the right.
/// * The **directional** ones — [slideFromStart], [slideFromEnd] — and
///   every `morph*`, which describe a MOTION rather than a side, mirror
///   with the reading direction. Forward navigation enters from the
///   right in English and from the left in Arabic, the way the platform
///   itself does.
enum TransitionType {
  /// No animation — instant page change.
  none,

  /// Simple crossfade.
  fade,

  /// Zoom in.
  scale,

  /// From the physical right, whatever the language.
  slideFromRight,

  /// From the physical left, whatever the language.
  slideFromLeft,

  /// From the physical top.
  slideFromTop,

  /// From the physical bottom (modal style).
  slideFromBottom,

  /// From the LEADING edge — left in English, right in Arabic.
  slideFromStart,

  /// From the TRAILING edge — right in English, left in Arabic. The
  /// platform's own forward-navigation direction.
  slideFromEnd,

  /// Morph: slide + scale + fade, with the outgoing page moving too.
  morphScale,

  /// Morph: staggered slide + scale + fade.
  morphSlide,

  /// Morph: fade + subtle scale.
  morphFade,

  /// Morph: slide + rotation + scale + fade.
  morphRotate,

  /// Native iOS with parallax and swipe-back.
  ios;

  /// Whether this one follows the reading direction.
  bool get isDirectional => switch (this) {
    TransitionType.slideFromStart ||
    TransitionType.slideFromEnd ||
    TransitionType.morphScale ||
    TransitionType.morphSlide ||
    TransitionType.morphRotate => true,
    _ => false,
  };
}

// ---------------------------------------------------------------------------
// Defaults — every number a transition draws with
// ---------------------------------------------------------------------------

/// The compile-time floor under [TransitionStyle].
///
/// A transition has no tokens to read: it is motion, not layout, so
/// nothing here comes from `AppTokens`. The app-wide layer is
/// `MyGlobalTransitionTheme.build`, which sets the house's duration and
/// curve — the two things an adopter actually rebrands.
abstract final class TransitionDefaults {
  static const duration = AppDurations.slow;
  static const curve = Curves.easeInOut;
  static const swipeEnabled = true;

  /// How much of the screen a plain slide travels. A whole one.
  static const slideFraction = 1.0;

  /// What a plain [TransitionType.scale] starts at.
  static const scaleBegin = 0.8;

  // ─── morphScale ───────────────────────────────────────────
  /// How far the incoming page slides, and how far the OUTGOING one
  /// slides the other way — a third of the screen each, so the two
  /// read as one movement rather than a swap.
  static const morphScaleSlide = 0.3;
  static const morphScaleBegin = 0.8;

  /// What the outgoing page shrinks to as it leaves.
  static const morphScaleExit = 0.8;

  // ─── morphSlide ───────────────────────────────────────────
  static const morphSlideScaleBegin = 0.9;

  /// The stagger: slide first, fade through the middle, scale last.
  static const morphSlideInterval = Interval(
    0,
    0.6,
    curve: Curves.easeOutCubic,
  );
  static const morphSlideScaleInterval = Interval(
    0.4,
    1,
    curve: Curves.easeOutCubic,
  );
  static const morphSlideFadeInterval = Interval(
    0.2,
    0.8,
    curve: Curves.easeIn,
  );

  // ─── morphFade ────────────────────────────────────────────
  static const morphFadeScaleBegin = 0.95;

  // ─── morphRotate ──────────────────────────────────────────
  static const morphRotateSlide = 0.5;
  static const morphRotateTurns = 0.1;
  static const morphRotateScaleBegin = 0.8;

  // ─── The back gesture ─────────────────────────────────────
  /// The strip down the LEADING edge that starts a swipe-back, and how
  /// much of the screen the drag covers, both as fractions of the
  /// width.
  static const swipeDetectionArea = 0.1;
  static const swipeTransitionRange = 1.0;

  /// The flick that pops regardless of distance, in logical pixels per
  /// second.
  static const swipeVelocity = 1100.0;

  /// And how far a SLOW drag has to get before letting go pops.
  static const swipeCommitProgress = 0.5;

  static const swipeCommitCurve = Curves.fastEaseInToSlowEaseOut;
  static const swipeCancelCurve = Curves.easeOut;
}

// ---------------------------------------------------------------------------
// The bag
// ---------------------------------------------------------------------------

/// Every knob a page transition has, all of it optional.
///
/// Resolution order is `route > TransitionOverride > GlobalTransitionTheme
/// > TransitionStyle.defaults`, and the resolve is also where reduced
/// motion and the reading direction are applied — once, in one place,
/// rather than in each of the twelve builders.
@immutable
class TransitionStyle {
  const TransitionStyle({
    this.type,
    this.duration,
    this.curve,
    this.swipeEnabled,
    this.respectReducedMotion,
    this.slideFraction,
    this.scaleBegin,
  });

  /// How the page arrives.
  final TransitionType? type;

  final Duration? duration;
  final Curve? curve;

  /// Whether a drag from the leading edge pops the route.
  final bool? swipeEnabled;

  /// Whether the reader's reduce-motion setting collapses this to
  /// [TransitionType.none].
  ///
  /// True everywhere except the rare screen whose transition IS the
  /// content — the same call the animation module makes.
  final bool? respectReducedMotion;

  /// How much of the screen a plain slide travels.
  final double? slideFraction;

  /// What a [TransitionType.scale] starts at.
  final double? scaleBegin;

  /// Nothing answered. The floor is [TransitionDefaults].
  static const TransitionStyle defaults = TransitionStyle();

  /// The platform's own forward navigation: mirrors, and can be
  /// swiped back.
  static const TransitionStyle push = TransitionStyle(
    type: TransitionType.slideFromEnd,
  );

  /// A sheet-shaped route: up from the bottom, no mirroring, no
  /// leading-edge swipe (the drag belongs to the sheet).
  static const TransitionStyle modal = TransitionStyle(
    type: TransitionType.slideFromBottom,
    swipeEnabled: false,
  );

  /// A tab swap, a splash hand-off: no direction to speak of.
  static const TransitionStyle crossfade = TransitionStyle(
    type: TransitionType.fade,
    duration: AppDurations.quick,
  );

  /// `other` wins field by field; `null` on `other` keeps ours.
  TransitionStyle mergedWith(TransitionStyle? other) {
    if (other == null) return this;
    return TransitionStyle(
      type: other.type ?? type,
      duration: other.duration ?? duration,
      curve: other.curve ?? curve,
      swipeEnabled: other.swipeEnabled ?? swipeEnabled,
      respectReducedMotion: other.respectReducedMotion ?? respectReducedMotion,
      slideFraction: other.slideFraction ?? slideFraction,
      scaleBegin: other.scaleBegin ?? scaleBegin,
    );
  }

  TransitionStyle copyWith({
    TransitionType? type,
    Duration? duration,
    Curve? curve,
    bool? swipeEnabled,
    bool? respectReducedMotion,
    double? slideFraction,
    double? scaleBegin,
  }) => TransitionStyle(
    type: type ?? this.type,
    duration: duration ?? this.duration,
    curve: curve ?? this.curve,
    swipeEnabled: swipeEnabled ?? this.swipeEnabled,
    respectReducedMotion: respectReducedMotion ?? this.respectReducedMotion,
    slideFraction: slideFraction ?? this.slideFraction,
    scaleBegin: scaleBegin ?? this.scaleBegin,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TransitionStyle &&
          other.type == type &&
          other.duration == duration &&
          other.curve == curve &&
          other.swipeEnabled == swipeEnabled &&
          other.respectReducedMotion == respectReducedMotion &&
          other.slideFraction == slideFraction &&
          other.scaleBegin == scaleBegin;

  @override
  int get hashCode => Object.hash(
    type,
    duration,
    curve,
    swipeEnabled,
    respectReducedMotion,
    slideFraction,
    scaleBegin,
  );
}

// ---------------------------------------------------------------------------
// The bag with every question answered
// ---------------------------------------------------------------------------

/// What `RouteTransition` actually builds with.
///
/// By the time one of these exists the reader's reduce-motion setting
/// and the reading direction have already been folded in, so no builder
/// below needs a `BuildContext`.
@immutable
class ResolvedTransitionStyle {
  const ResolvedTransitionStyle({
    required this.type,
    required this.duration,
    required this.curve,
    required this.swipeEnabled,
    required this.slideFraction,
    required this.scaleBegin,
    required this.textDirection,
  });

  final TransitionType type;
  final Duration duration;
  final Curve curve;
  final bool swipeEnabled;
  final double slideFraction;
  final double scaleBegin;

  /// Already resolved, so a builder can mirror without a context.
  final TextDirection textDirection;

  bool get isRtl => textDirection == TextDirection.rtl;

  /// `1` in English, `-1` in Arabic — the sign every DIRECTIONAL
  /// transition multiplies its horizontal travel by.
  ///
  /// A physical `slideFromRight` does NOT use it: it names a side and
  /// keeps it.
  double get directionSign => isRtl ? -1 : 1;

  ResolvedTransitionStyle copyWith({
    TransitionType? type,
    Duration? duration,
  }) => ResolvedTransitionStyle(
    type: type ?? this.type,
    duration: duration ?? this.duration,
    curve: curve,
    swipeEnabled: swipeEnabled,
    slideFraction: slideFraction,
    scaleBegin: scaleBegin,
    textDirection: textDirection,
  );
}
