import 'package:flutter/material.dart';

// ---------------------------------------------------------------------------
// Constants
// ---------------------------------------------------------------------------

const kMarqueeDefaultSpeed = 50.0;
const kMarqueeDefaultGap = 40.0;
const kMarqueeDefaultFadeWidth = 24.0;
const kMarqueePauseDuration = Duration(seconds: 2);

// ---------------------------------------------------------------------------
// MarqueeDirection
// ---------------------------------------------------------------------------

/// Scroll direction of the marquee.
enum MarqueeDirection {
  /// Left to right.
  ltr,

  /// Right to left (default — standard ticker direction).
  rtl,

  /// Bottom to top.
  up,

  /// Top to bottom.
  down,
}

// ---------------------------------------------------------------------------
// MarqueeMode
// ---------------------------------------------------------------------------

/// Scrolling behavior.
enum MarqueeMode {
  /// Continuous loop — content scrolls endlessly with a gap between repetitions.
  loop,

  /// Scroll to the end, then reverse back (ping-pong).
  bounce,
}

// ---------------------------------------------------------------------------
// MarqueeStyle
// ---------------------------------------------------------------------------

/// Themeable styling bag for [GlobalMarquee] — EVERY field nullable.
///
/// Resolution order, materialized once per build by `resolve`:
/// `caller > GlobalMarqueeTheme.style > MarqueeStyle.defaults > tokens`.
///
/// Adding a themed field means touching five places: here, [mergedWith],
/// [copyWith], [ResolvedMarqueeStyle] and `GlobalMarqueeTheme.lerp`.
@immutable
class MarqueeStyle {
  const MarqueeStyle({
    this.speed,
    this.gap,
    this.fadeEdges,
    this.fadeWidth,
    this.pauseOnHover,
    this.pauseOnTouch,
    this.initialPause,
    this.endPause,
    this.direction,
    this.mode,
  });

  /// Compile-time floor.
  static const MarqueeStyle defaults = MarqueeStyle(
    speed: kMarqueeDefaultSpeed,
    gap: kMarqueeDefaultGap,
    fadeEdges: true,
    fadeWidth: kMarqueeDefaultFadeWidth,
    pauseOnHover: true,
    pauseOnTouch: true,
    initialPause: kMarqueePauseDuration,
    endPause: kMarqueePauseDuration,
    direction: MarqueeDirection.rtl,
    mode: MarqueeMode.loop,
  );

  /// Scroll speed in logical pixels per second.
  ///
  /// Velocity, NOT a duration: a fixed duration makes long content race
  /// and short content crawl, which is the usual reason a marquee looks
  /// cheap.
  final double? speed;

  /// Gap between repetitions in [MarqueeMode.loop].
  final double? gap;

  /// Fade the edges where content is concealed.
  final bool? fadeEdges;

  /// Width of the fade ramp on each edge.
  final double? fadeWidth;

  /// Pause scrolling on mouse hover (web/desktop).
  final bool? pauseOnHover;

  /// Pause scrolling on touch (mobile).
  final bool? pauseOnTouch;

  /// Pause before starting the first scroll cycle.
  final Duration? initialPause;

  /// Pause at each end in [MarqueeMode.bounce].
  final Duration? endPause;

  /// Scroll direction.
  final MarqueeDirection? direction;

  /// Scrolling behavior.
  final MarqueeMode? mode;

  /// `other` wins field by field.
  MarqueeStyle mergedWith(MarqueeStyle? other) {
    if (other == null) return this;
    return MarqueeStyle(
      speed: other.speed ?? speed,
      gap: other.gap ?? gap,
      fadeEdges: other.fadeEdges ?? fadeEdges,
      fadeWidth: other.fadeWidth ?? fadeWidth,
      pauseOnHover: other.pauseOnHover ?? pauseOnHover,
      pauseOnTouch: other.pauseOnTouch ?? pauseOnTouch,
      initialPause: other.initialPause ?? initialPause,
      endPause: other.endPause ?? endPause,
      direction: other.direction ?? direction,
      mode: other.mode ?? mode,
    );
  }

  MarqueeStyle copyWith({
    double? speed,
    double? gap,
    bool? fadeEdges,
    double? fadeWidth,
    bool? pauseOnHover,
    bool? pauseOnTouch,
    Duration? initialPause,
    Duration? endPause,
    MarqueeDirection? direction,
    MarqueeMode? mode,
  }) {
    return MarqueeStyle(
      speed: speed ?? this.speed,
      gap: gap ?? this.gap,
      fadeEdges: fadeEdges ?? this.fadeEdges,
      fadeWidth: fadeWidth ?? this.fadeWidth,
      pauseOnHover: pauseOnHover ?? this.pauseOnHover,
      pauseOnTouch: pauseOnTouch ?? this.pauseOnTouch,
      initialPause: initialPause ?? this.initialPause,
      endPause: endPause ?? this.endPause,
      direction: direction ?? this.direction,
      mode: mode ?? this.mode,
    );
  }
}

/// Materialized [MarqueeStyle] — every field non-null.
@immutable
class ResolvedMarqueeStyle {
  const ResolvedMarqueeStyle({
    required this.speed,
    required this.gap,
    required this.fadeEdges,
    required this.fadeWidth,
    required this.pauseOnHover,
    required this.pauseOnTouch,
    required this.initialPause,
    required this.endPause,
    required this.direction,
    required this.mode,
  });

  final double speed;
  final double gap;
  final bool fadeEdges;
  final double fadeWidth;
  final bool pauseOnHover;
  final bool pauseOnTouch;
  final Duration initialPause;
  final Duration endPause;
  final MarqueeDirection direction;
  final MarqueeMode mode;

  bool get isHorizontal =>
      direction == MarqueeDirection.ltr || direction == MarqueeDirection.rtl;

  bool get isReversed =>
      direction == MarqueeDirection.ltr || direction == MarqueeDirection.down;
}
