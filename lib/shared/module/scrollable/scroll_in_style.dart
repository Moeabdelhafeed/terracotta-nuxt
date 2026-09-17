import 'package:flutter/material.dart';
import 'package:visibility_detector/visibility_detector.dart';

import 'scrollable_models.dart';

/// How the scroll-in animation is driven.
enum ScrollInMode {
  /// The default. Crossing the threshold plays the transition once,
  /// over [ScrollInStyle.duration], independent of scroll speed.
  oneShot,

  /// The animation is bound DIRECTLY to the tile's visible fraction —
  /// scrolling drives it, scrolling back reverses it. Ignores the
  /// duration, the threshold, the stagger and the once-per-index
  /// dedupe: none of them mean anything without a fire.
  continuous,
}

/// How the cascade orders a batch of tiles.
enum ScrollInStaggerMode {
  /// The default. Tiles fire in the order they cross the threshold;
  /// each claim advances a single cursor by one step. A natural
  /// scroll-order cascade.
  byOrder,

  /// Tiles in the same grid row (`index ~/ cols`) fire together, and
  /// each row offsets by one step from the batch anchor — a row-by-row
  /// wave. Only meaningful for grids; a one-column list is [byOrder].
  byRow,
}

/// The compile-time floor under the scroll-in family.
abstract final class ScrollInDefaults {
  static const duration = Duration(milliseconds: 280);

  /// The entrance curve. `scale` uses [scaleCurve] instead, because a
  /// scale that overshoots reads as arriving and a scale that eases
  /// reads as loading.
  static const curve = Curves.easeOutCubic;
  static const scaleCurve = Curves.easeOutBack;

  /// How far a sliding tile starts from its resting place, as a
  /// fraction of its own size.
  static const slideOffset = 0.25;

  /// Visible fraction that counts as "the reader can see this".
  static const threshold = 0.1;

  /// Per-tile step in the cascade. `Duration.zero` disables it.
  static const stagger = Duration(milliseconds: 50);

  /// A gap this long ends the batch — the next tile anchors a new one.
  static const staggerIdleReset = Duration(milliseconds: 200);

  /// The cascade never queues further ahead than this, so a fast
  /// scroll cannot leave the animation lagging behind the viewport.
  static const staggerMaxQueue = Duration(milliseconds: 120);

  /// How often `VisibilityDetector` may batch its reports while a
  /// scroll-in is armed. Its own default is 500ms, which is most of a
  /// second after the row appeared.
  static const visibilityInterval = Duration(milliseconds: 50);

  /// Asks the detector to report faster — **and only faster**.
  ///
  /// The interval is a global singleton. Setting it outright stomps
  /// whatever the app or a test chose, and never puts it back: a test
  /// that deliberately parks it at zero, so its teardown is not left
  /// holding a pending timer, had it reset by the next list to mount.
  static void quickenVisibilityReports() {
    final controller = VisibilityDetectorController.instance;
    if (controller.updateInterval > visibilityInterval) {
      controller.updateInterval = visibilityInterval;
    }
  }

  // ── Drag auto-scroll ───────────────────────────────────────────
  /// Distance from the viewport edge at which a drag starts scrolling.
  static const dragEdgeZone = 64.0;

  /// Pixels moved per tick at the very edge. The speed ramps linearly
  /// from zero at the zone's boundary.
  static const dragMaxSpeed = 18.0;
}

/// How a tile arrives when it scrolls into view.
///
/// All-nullable: the caller answers what it cares about, the theme
/// answers the rest, and [ScrollInDefaults] is the floor.
///
/// This is what solves the cacheExtent problem — an `initState`-driven
/// animation plays OFFSCREEN, because virtualisation mounts tiles a
/// few hundred pixels before they enter the viewport, so the reader
/// scrolls to a row that has already finished arriving.
@immutable
class ScrollInStyle {
  const ScrollInStyle({
    this.animation,
    this.duration,
    this.curve,
    this.scaleCurve,
    this.slideOffset,
    this.threshold,
    this.once,
    this.stagger,
    this.staggerMode,
    this.staggerIdleReset,
    this.staggerMaxQueue,
    this.mode,
    this.respectReducedMotion,
  });

  /// The floor. A bag with no answers resolves to this.
  static const defaults = ScrollInStyle(
    duration: ScrollInDefaults.duration,
    curve: ScrollInDefaults.curve,
    scaleCurve: ScrollInDefaults.scaleCurve,
    slideOffset: ScrollInDefaults.slideOffset,
    threshold: ScrollInDefaults.threshold,
    once: true,
    stagger: ScrollInDefaults.stagger,
    staggerMode: ScrollInStaggerMode.byOrder,
    staggerIdleReset: ScrollInDefaults.staggerIdleReset,
    staggerMaxQueue: ScrollInDefaults.staggerMaxQueue,
    mode: ScrollInMode.oneShot,
    respectReducedMotion: true,
  );

  /// A quiet fade, no cascade — for a dense list where a wave of
  /// motion is noise rather than rhythm.
  static const subtle = ScrollInStyle(
    animation: ListItemAnimation.fade,
    stagger: Duration.zero,
    duration: Duration(milliseconds: 200),
  );

  /// A row-by-row wave. Reads best on a grid, where a batch of tiles
  /// crosses the threshold together.
  static const wave = ScrollInStyle(
    animation: ListItemAnimation.slideFromBottom,
    staggerMode: ScrollInStaggerMode.byRow,
  );

  /// Which transition. **Null means no scroll-in at all** — this is
  /// the switch, so a theme cannot turn the animation on for a list
  /// that never asked for one.
  final ListItemAnimation? animation;

  final Duration? duration;
  final Curve? curve;

  /// The curve for [ListItemAnimation.scale] only.
  final Curve? scaleCurve;

  /// How far a sliding tile starts out, as a fraction of its size.
  final double? slideOffset;

  final double? threshold;

  /// When true, an index animates once per State lifetime; re-entering
  /// the viewport keeps the finished state. When false it re-arms
  /// whenever the tile leaves the viewport entirely.
  final bool? once;

  final Duration? stagger;
  final ScrollInStaggerMode? staggerMode;
  final Duration? staggerIdleReset;
  final Duration? staggerMaxQueue;

  final ScrollInMode? mode;
  final bool? respectReducedMotion;

  ScrollInStyle mergedWith(ScrollInStyle? other) {
    if (other == null) return this;
    return ScrollInStyle(
      animation: other.animation ?? animation,
      duration: other.duration ?? duration,
      curve: other.curve ?? curve,
      scaleCurve: other.scaleCurve ?? scaleCurve,
      slideOffset: other.slideOffset ?? slideOffset,
      threshold: other.threshold ?? threshold,
      once: other.once ?? once,
      stagger: other.stagger ?? stagger,
      staggerMode: other.staggerMode ?? staggerMode,
      staggerIdleReset: other.staggerIdleReset ?? staggerIdleReset,
      staggerMaxQueue: other.staggerMaxQueue ?? staggerMaxQueue,
      mode: other.mode ?? mode,
      respectReducedMotion: other.respectReducedMotion ?? respectReducedMotion,
    );
  }

  ScrollInStyle copyWith({
    ListItemAnimation? animation,
    Duration? duration,
    Curve? curve,
    Curve? scaleCurve,
    double? slideOffset,
    double? threshold,
    bool? once,
    Duration? stagger,
    ScrollInStaggerMode? staggerMode,
    Duration? staggerIdleReset,
    Duration? staggerMaxQueue,
    ScrollInMode? mode,
    bool? respectReducedMotion,
  }) => ScrollInStyle(
    animation: animation ?? this.animation,
    duration: duration ?? this.duration,
    curve: curve ?? this.curve,
    scaleCurve: scaleCurve ?? this.scaleCurve,
    slideOffset: slideOffset ?? this.slideOffset,
    threshold: threshold ?? this.threshold,
    once: once ?? this.once,
    stagger: stagger ?? this.stagger,
    staggerMode: staggerMode ?? this.staggerMode,
    staggerIdleReset: staggerIdleReset ?? this.staggerIdleReset,
    staggerMaxQueue: staggerMaxQueue ?? this.staggerMaxQueue,
    mode: mode ?? this.mode,
    respectReducedMotion: respectReducedMotion ?? this.respectReducedMotion,
  );

  @override
  bool operator ==(Object other) =>
      other is ScrollInStyle &&
      other.animation == animation &&
      other.duration == duration &&
      other.curve == curve &&
      other.scaleCurve == scaleCurve &&
      other.slideOffset == slideOffset &&
      other.threshold == threshold &&
      other.once == once &&
      other.stagger == stagger &&
      other.staggerMode == staggerMode &&
      other.staggerIdleReset == staggerIdleReset &&
      other.staggerMaxQueue == staggerMaxQueue &&
      other.mode == mode &&
      other.respectReducedMotion == respectReducedMotion;

  @override
  int get hashCode => Object.hashAll([
    animation,
    duration,
    curve,
    scaleCurve,
    slideOffset,
    threshold,
    once,
    stagger,
    staggerMode,
    staggerIdleReset,
    staggerMaxQueue,
    mode,
    respectReducedMotion,
  ]);
}

/// A [ScrollInStyle] with every question answered.
@immutable
class ResolvedScrollInStyle {
  const ResolvedScrollInStyle({
    required this.animation,
    required this.duration,
    required this.curve,
    required this.scaleCurve,
    required this.slideOffset,
    required this.threshold,
    required this.once,
    required this.stagger,
    required this.staggerMode,
    required this.staggerIdleReset,
    required this.staggerMaxQueue,
    required this.mode,
    required this.still,
  });

  /// Null when nothing asked for a scroll-in.
  final ListItemAnimation? animation;

  /// Zero under reduced motion.
  final Duration duration;

  final Curve curve;
  final Curve scaleCurve;
  final double slideOffset;
  final double threshold;
  final bool once;

  /// Zero under reduced motion — a cascade IS motion, and one made
  /// instant is just a delay before something appears.
  final Duration stagger;

  final ScrollInStaggerMode staggerMode;
  final Duration staggerIdleReset;
  final Duration staggerMaxQueue;
  final ScrollInMode mode;

  /// The reader asked for no motion. The tile is placed, not animated
  /// — including in `continuous` mode, where binding the transition to
  /// the scroll would otherwise animate it on every single frame of
  /// every scroll.
  final bool still;

  /// Whether there is anything to play at all.
  bool get isOff => animation == null || still;

  /// The curve this animation uses.
  Curve get effectiveCurve =>
      animation == ListItemAnimation.scale ? scaleCurve : curve;
}
