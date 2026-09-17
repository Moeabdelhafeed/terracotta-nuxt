import 'package:flutter/material.dart';

/// The floor for [GlobalAutoScroller].
abstract final class AutoScrollerDefaults {
  /// Logical pixels a second.
  ///
  /// Slow enough to read a passing headline and fast enough not to
  /// look stuck — a ticker that crawls reads as a hung app.
  static const speed = 30.0;

  /// How long after the reader lets go before the drive resumes.
  static const resumeDelay = Duration(seconds: 1);

  static const loopMode = AutoScrollLoopMode.wrap;
  static const pauseOnInteraction = true;
  static const respectReducedMotion = true;

  /// A pointer RESTING over the rail holds it, on the platforms that
  /// have one. Hovering to read a passing headline is the whole
  /// gesture on a desktop, and there is no touch there to hold it.
  static const pauseOnHover = true;

  /// A screen reader being on holds it.
  ///
  /// Content that moves out from under the reader's own cursor is not
  /// readable, and the reader has no way to catch it — TalkBack and
  /// VoiceOver both walk a list at their own pace.
  static const pauseWhenAccessibleNavigation = true;

  /// Nothing moves until the screen has settled.
  ///
  /// Zero, because a delay is a decision about ONE rail: a ticker
  /// under a headline wants a beat, a marquee in a card does not.
  static const startDelay = Duration.zero;

  /// How close to an edge the drive starts easing off, in pixels.
  ///
  /// Zero — off — because it changes nothing for `wrap`, where the
  /// edge is not a destination. `bounce` is where it earns its keep,
  /// and the `ambient` preset asks for it.
  static const edgeEaseDistance = 0.0;

  /// The slowest the easing goes, as a fraction of the full speed.
  ///
  /// NOT zero: a speed that eases all the way to nothing never
  /// arrives, and a bounce that never reaches its edge never turns
  /// around.
  static const edgeEaseFloor = 0.15;
}

/// Which end of the scrollable the drive reached.
enum AutoScrollEdge { start, end }

/// What happens when the drive reaches the end of the scrollable.
enum AutoScrollLoopMode {
  /// Jump back to the start and carry on.
  wrap,

  /// Reverse and carry on.
  bounce,

  /// Halt at the end.
  stop,
}

/// How a [GlobalAutoScroller] drives, and how it behaves at the edges.
///
/// Every field is nullable: unanswered means "ask the theme, then the
/// floor". The bag carries no COLOURS — an auto-scroller paints
/// nothing. What a house wants to set once here is the pace, and the
/// pace is the whole point: a ticker moving at a different speed on
/// two screens of one app is the drift this exists to stop.
@immutable
class AutoScrollerStyle {
  const AutoScrollerStyle({
    this.speed,
    this.loopMode,
    this.pauseOnInteraction,
    this.resumeDelay,
    this.respectReducedMotion,
    this.pauseOnHover,
    this.pauseWhenAccessibleNavigation,
    this.startDelay,
    this.edgeEaseDistance,
    this.edgeEaseFloor,
  });

  /// The floor — the only place a compile-time constant lives.
  static const defaults = AutoScrollerStyle(
    speed: AutoScrollerDefaults.speed,
    loopMode: AutoScrollerDefaults.loopMode,
    pauseOnInteraction: AutoScrollerDefaults.pauseOnInteraction,
    resumeDelay: AutoScrollerDefaults.resumeDelay,
    respectReducedMotion: AutoScrollerDefaults.respectReducedMotion,
    pauseOnHover: AutoScrollerDefaults.pauseOnHover,
    pauseWhenAccessibleNavigation:
        AutoScrollerDefaults.pauseWhenAccessibleNavigation,
    startDelay: AutoScrollerDefaults.startDelay,
    edgeEaseDistance: AutoScrollerDefaults.edgeEaseDistance,
    edgeEaseFloor: AutoScrollerDefaults.edgeEaseFloor,
  );

  /// A news ticker: quick, wrapping, and it gets out of the way the
  /// moment a finger lands.
  static const ticker = AutoScrollerStyle(
    speed: 60,
    loopMode: AutoScrollLoopMode.wrap,
  );

  /// An ambient rail that drifts back and forth rather than jumping.
  ///
  /// It EASES into each turn: a slow drift that reverses on one frame
  /// reads as a stutter, which is the one thing a decorative rail
  /// must not do.
  static const ambient = AutoScrollerStyle(
    speed: 18,
    loopMode: AutoScrollLoopMode.bounce,
    edgeEaseDistance: 64,
  );

  /// Logical pixels a second.
  final double? speed;

  /// What happens at the end of the scrollable.
  final AutoScrollLoopMode? loopMode;

  /// Whether a finger on the content stops the drive.
  final bool? pauseOnInteraction;

  /// How long after the finger lifts before it resumes.
  final Duration? resumeDelay;

  /// Whether `MediaQuery.disableAnimationsOf` stops the drive
  /// entirely.
  ///
  /// It STOPS rather than slowing: an auto-scroller is motion with no
  /// other purpose — nothing is being said that standing still does
  /// not say — so a reader who asked for less of it has asked for
  /// none of this. False is for a scroller that IS the content, such
  /// as a kiosk display nobody is holding.
  final bool? respectReducedMotion;

  /// Whether a resting pointer holds the drive. Pointer devices only —
  /// a touch produces no hover.
  final bool? pauseOnHover;

  /// Whether `MediaQuery.accessibleNavigationOf` holds the drive.
  ///
  /// A screen reader walks content at its own pace; a rail that moves
  /// underneath it is unreadable, and a reader has no gesture to stop
  /// it. This is the mechanism WCAG 2.2.2 asks for, on by default,
  /// alongside the pause / resume actions the widget publishes.
  final bool? pauseWhenAccessibleNavigation;

  /// How long after the first frame before the drive starts.
  final Duration? startDelay;

  /// How close to an edge, in pixels, the speed starts easing off.
  /// Zero disables the easing.
  final double? edgeEaseDistance;

  /// The floor the easing eases DOWN to, as a fraction of the speed.
  final double? edgeEaseFloor;

  /// Field-by-field: whatever `other` answers wins, and what it leaves
  /// null keeps this bag's answer.
  AutoScrollerStyle mergedWith(AutoScrollerStyle? other) {
    if (other == null) return this;
    return AutoScrollerStyle(
      speed: other.speed ?? speed,
      loopMode: other.loopMode ?? loopMode,
      pauseOnInteraction: other.pauseOnInteraction ?? pauseOnInteraction,
      resumeDelay: other.resumeDelay ?? resumeDelay,
      respectReducedMotion: other.respectReducedMotion ?? respectReducedMotion,
      pauseOnHover: other.pauseOnHover ?? pauseOnHover,
      pauseWhenAccessibleNavigation:
          other.pauseWhenAccessibleNavigation ?? pauseWhenAccessibleNavigation,
      startDelay: other.startDelay ?? startDelay,
      edgeEaseDistance: other.edgeEaseDistance ?? edgeEaseDistance,
      edgeEaseFloor: other.edgeEaseFloor ?? edgeEaseFloor,
    );
  }

  AutoScrollerStyle copyWith({
    double? speed,
    AutoScrollLoopMode? loopMode,
    bool? pauseOnInteraction,
    Duration? resumeDelay,
    bool? respectReducedMotion,
    bool? pauseOnHover,
    bool? pauseWhenAccessibleNavigation,
    Duration? startDelay,
    double? edgeEaseDistance,
    double? edgeEaseFloor,
  }) => AutoScrollerStyle(
    speed: speed ?? this.speed,
    loopMode: loopMode ?? this.loopMode,
    pauseOnInteraction: pauseOnInteraction ?? this.pauseOnInteraction,
    resumeDelay: resumeDelay ?? this.resumeDelay,
    respectReducedMotion: respectReducedMotion ?? this.respectReducedMotion,
    pauseOnHover: pauseOnHover ?? this.pauseOnHover,
    pauseWhenAccessibleNavigation:
        pauseWhenAccessibleNavigation ?? this.pauseWhenAccessibleNavigation,
    startDelay: startDelay ?? this.startDelay,
    edgeEaseDistance: edgeEaseDistance ?? this.edgeEaseDistance,
    edgeEaseFloor: edgeEaseFloor ?? this.edgeEaseFloor,
  );

  @override
  bool operator ==(Object other) =>
      other is AutoScrollerStyle &&
      other.speed == speed &&
      other.loopMode == loopMode &&
      other.pauseOnInteraction == pauseOnInteraction &&
      other.resumeDelay == resumeDelay &&
      other.respectReducedMotion == respectReducedMotion &&
      other.pauseOnHover == pauseOnHover &&
      other.pauseWhenAccessibleNavigation == pauseWhenAccessibleNavigation &&
      other.startDelay == startDelay &&
      other.edgeEaseDistance == edgeEaseDistance &&
      other.edgeEaseFloor == edgeEaseFloor;

  @override
  int get hashCode => Object.hash(
    speed,
    loopMode,
    pauseOnInteraction,
    resumeDelay,
    respectReducedMotion,
    pauseOnHover,
    pauseWhenAccessibleNavigation,
    startDelay,
    edgeEaseDistance,
    edgeEaseFloor,
  );
}

/// An [AutoScrollerStyle] with every question answered.
@immutable
class ResolvedAutoScrollerStyle {
  const ResolvedAutoScrollerStyle({
    required this.speed,
    required this.loopMode,
    required this.pauseOnInteraction,
    required this.resumeDelay,
    required this.still,
    required this.pauseOnHover,
    required this.pauseWhenAccessibleNavigation,
    required this.startDelay,
    required this.edgeEaseDistance,
    required this.edgeEaseFloor,
  });

  /// Logical pixels a second. ZERO when [still] — see
  /// [AutoScrollerStyle.respectReducedMotion].
  final double speed;

  final AutoScrollLoopMode loopMode;
  final bool pauseOnInteraction;
  final Duration resumeDelay;

  /// Whether the reader has asked for motion to stop.
  ///
  /// Handed to the caller's builder as well as read here: a rail that
  /// parks with `NeverScrollableScrollPhysics` has put its content
  /// out of reach, and only the caller can give the physics back.
  final bool still;

  final bool pauseOnHover;
  final bool pauseWhenAccessibleNavigation;
  final Duration startDelay;
  final double edgeEaseDistance;
  final double edgeEaseFloor;

  /// The fraction of [speed] to run at, this many pixels from the
  /// nearest edge the drive is heading toward.
  ///
  /// One over the whole run rather than a branch per loop mode: with
  /// [edgeEaseDistance] at zero — the default — this is a constant 1
  /// and the arithmetic disappears.
  double easeFactorAt(double distanceToEdge) {
    if (edgeEaseDistance <= 0) return 1;
    if (distanceToEdge >= edgeEaseDistance) return 1;
    final t = (distanceToEdge / edgeEaseDistance).clamp(0.0, 1.0);
    // Squared, so the taper is gentle until it is close.
    return edgeEaseFloor + (1 - edgeEaseFloor) * t * t;
  }
}
