import 'package:flutter/material.dart';

import 'scrollable_models.dart';

/// The compile-time floor under the scrollable family.
///
/// Everything the caller and the theme both leave unanswered lands
/// here. Numbers only — colours resolve from the palette at build
/// time, so a rebrand moves them.
abstract final class ScrollableDefaults {
  // ── Edge fade ──────────────────────────────────────────────────
  /// Thickness of the fade band along the scroll axis.
  static const edgeFadeSize = 24.0;

  /// How dark the `innerShadow` band is at the edge.
  static const innerShadowOpacity = 0.18;

  /// The band's own show / hide, for `smart` fades.
  static const edgeFadeDuration = Duration(milliseconds: 160);

  // ── Overlays ───────────────────────────────────────────────────
  /// How far down before the scroll-to-top button appears.
  static const scrollToTopThreshold = 240.0;
  static const fabSize = 44.0;
  static const fabIconSize = 26.0;

  /// Distance from the viewport's corner.
  static const fabMargin = 12.0;

  /// Gap between the scroll-to-top button and the new-item pill above
  /// it, measured edge to edge.
  static const fabGap = 12.0;

  /// The overlays' entrance.
  static const overlayDuration = Duration(milliseconds: 220);

  /// The ride back to the top.
  static const scrollToTopDuration = Duration(milliseconds: 420);
  static const scrollToTopCurve = Curves.easeOutCubic;

  /// `scrollToOffset`'s default.
  static const scrollToOffsetDuration = Duration(milliseconds: 320);

  static const progressThickness = 3.0;
  static const progressTrackOpacity = 0.12;

  // ── Wheel ──────────────────────────────────────────────────────
  /// Pixels of scroll per unit of wheel delta. 1.0 is raw passthrough.
  static const wheelMultiplier = 1.5;

  /// How hard the lerp chases the moving target each frame. Lower is
  /// smoother and slower; 0.15 is roughly Lenis's default. Useful
  /// range 0.05 – 0.4.
  static const wheelSmoothness = 0.08;
}

// ═══════════════════════════════════════════════════════════════════
// Edge fade
// ═══════════════════════════════════════════════════════════════════

/// The edge effect at the start / end of a viewport.
///
/// Lived in `list/list_models.dart`, which meant the text field, the
/// slider, the breadcrumbs and the dropdown all imported the LIST
/// module to say how their scroll edge should look. A fade belongs to
/// whatever is scrolling.
@immutable
class EdgeFadeStyle {
  const EdgeFadeStyle({
    this.mode,
    this.size,
    this.color,
    this.smart,
    this.start,
    this.end,
    this.duration,
    this.respectReducedMotion,
  });

  /// No fade at all — and it says so explicitly, rather than being an
  /// empty bag that the theme could then turn back on.
  static const off = EdgeFadeStyle(mode: EdgeFadeMode.none);

  /// The floor. A bag with no answers resolves to this.
  static const defaults = EdgeFadeStyle(
    mode: EdgeFadeMode.shader,
    size: ScrollableDefaults.edgeFadeSize,
    smart: true,
    start: true,
    end: true,
    respectReducedMotion: true,
  );

  final EdgeFadeMode? mode;

  /// Thickness of the band along the scroll axis.
  final double? size;

  /// `scrim` fades to this colour; `innerShadow` darkens with it.
  /// `shader` and `blur` ignore it.
  final Color? color;

  /// When true, the start band hides at the start of the scroll and
  /// the end band at the end — a fade means "there is more this way",
  /// and at the first pixel there is not.
  final bool? smart;

  final bool? start;
  final bool? end;

  /// The band's own show / hide.
  final Duration? duration;

  final bool? respectReducedMotion;

  /// `other` wins field by field. Null on `other` keeps this one's.
  EdgeFadeStyle mergedWith(EdgeFadeStyle? other) {
    if (other == null) return this;
    return EdgeFadeStyle(
      mode: other.mode ?? mode,
      size: other.size ?? size,
      color: other.color ?? color,
      smart: other.smart ?? smart,
      start: other.start ?? start,
      end: other.end ?? end,
      duration: other.duration ?? duration,
      respectReducedMotion: other.respectReducedMotion ?? respectReducedMotion,
    );
  }

  EdgeFadeStyle copyWith({
    EdgeFadeMode? mode,
    double? size,
    Color? color,
    bool? smart,
    bool? start,
    bool? end,
    Duration? duration,
    bool? respectReducedMotion,
  }) => EdgeFadeStyle(
    mode: mode ?? this.mode,
    size: size ?? this.size,
    color: color ?? this.color,
    smart: smart ?? this.smart,
    start: start ?? this.start,
    end: end ?? this.end,
    duration: duration ?? this.duration,
    respectReducedMotion: respectReducedMotion ?? this.respectReducedMotion,
  );

  @override
  bool operator ==(Object other) =>
      other is EdgeFadeStyle &&
      other.mode == mode &&
      other.size == size &&
      other.color == color &&
      other.smart == smart &&
      other.start == start &&
      other.end == end &&
      other.duration == duration &&
      other.respectReducedMotion == respectReducedMotion;

  @override
  int get hashCode => Object.hash(
    mode,
    size,
    color,
    smart,
    start,
    end,
    duration,
    respectReducedMotion,
  );
}

/// An [EdgeFadeStyle] with every question answered.
@immutable
class ResolvedEdgeFadeStyle {
  const ResolvedEdgeFadeStyle({
    required this.mode,
    required this.size,
    required this.color,
    required this.smart,
    required this.start,
    required this.end,
    required this.duration,
  });

  final EdgeFadeMode mode;
  final double size;

  /// Already resolved against the palette — `scrim` took the page
  /// colour, `innerShadow` the scrim colour.
  final Color color;

  final bool smart;
  final bool start;
  final bool end;

  /// Zero under reduced motion: the band snaps rather than fading.
  final Duration duration;

  bool get isOff => mode == EdgeFadeMode.none || size <= 0;
}

// ═══════════════════════════════════════════════════════════════════
// The shell
// ═══════════════════════════════════════════════════════════════════

/// Everything a `GlobalScrollable` looks and behaves like.
///
/// All-nullable: the caller answers what it cares about, the theme
/// answers the rest, and [ScrollableDefaults] is the floor.
@immutable
class ScrollableStyle {
  const ScrollableStyle({
    this.edgeFade,
    this.showScrollToTop,
    this.scrollToTopThreshold,
    this.showScrollProgress,
    this.progressColor,
    this.progressThickness,
    this.progressPlacement,
    this.mode,
    this.boundaryBehavior,
    this.cacheExtent,
    this.fabSize,
    this.fabMargin,
    this.overlayDuration,
    this.scrollToTopDuration,
    this.scrollToOffsetDuration,
    this.keyboardDismissBehavior,
    this.smoothWheelScroll,
    this.wheelMultiplier,
    this.wheelSmoothness,
    this.enableHaptic,
    this.respectReducedMotion,
  });

  /// The floor.
  static const defaults = ScrollableStyle(
    edgeFade: EdgeFadeStyle.off,
    showScrollToTop: false,
    scrollToTopThreshold: ScrollableDefaults.scrollToTopThreshold,
    showScrollProgress: false,
    progressThickness: ScrollableDefaults.progressThickness,
    mode: ScrollableMode.platform,
    boundaryBehavior: BoundaryBehavior.isolated,
    fabSize: ScrollableDefaults.fabSize,
    fabMargin: ScrollableDefaults.fabMargin,
    overlayDuration: ScrollableDefaults.overlayDuration,
    scrollToTopDuration: ScrollableDefaults.scrollToTopDuration,
    scrollToOffsetDuration: ScrollableDefaults.scrollToOffsetDuration,
    keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.manual,
    smoothWheelScroll: true,
    wheelMultiplier: ScrollableDefaults.wheelMultiplier,
    wheelSmoothness: ScrollableDefaults.wheelSmoothness,
    enableHaptic: true,
    respectReducedMotion: true,
  );

  /// The app-page shell: bouncing physics, a scroll-to-top button, a
  /// soft shader fade, and pass-through so an embedded list hands off
  /// cleanly.
  static const page = ScrollableStyle(
    mode: ScrollableMode.bounce,
    showScrollToTop: true,
    edgeFade: EdgeFadeStyle(mode: EdgeFadeMode.shader, size: 16),
    boundaryBehavior: BoundaryBehavior.passThroughToParent,
  );

  /// No chrome. For a scrollable inside something that already has
  /// its own — a sheet, a dropdown, a card.
  static const bare = ScrollableStyle(
    edgeFade: EdgeFadeStyle.off,
    showScrollToTop: false,
    showScrollProgress: false,
  );

  /// A long read: progress at the top, a way back up, and a fade so
  /// the text does not collide with the app bar.
  static const article = ScrollableStyle(
    showScrollProgress: true,
    showScrollToTop: true,
    edgeFade: EdgeFadeStyle(mode: EdgeFadeMode.shader, size: 24),
  );

  final EdgeFadeStyle? edgeFade;
  final bool? showScrollToTop;
  final double? scrollToTopThreshold;
  final bool? showScrollProgress;
  final Color? progressColor;
  final double? progressThickness;
  final ScrollProgressPlacement? progressPlacement;
  final ScrollableMode? mode;
  final BoundaryBehavior? boundaryBehavior;

  /// How far beyond the viewport to keep tiles built.
  ///
  /// **`.custom` only.** A `SingleChildScrollView` builds its child
  /// whole, so there is nothing to cache; the box constructor asserts
  /// rather than ignoring it in silence.
  final double? cacheExtent;

  /// The scroll-to-top button's diameter, and how far it sits off the
  /// corner.
  final double? fabSize;
  final double? fabMargin;

  final Duration? overlayDuration;
  final Duration? scrollToTopDuration;
  final Duration? scrollToOffsetDuration;

  /// What a drag does to an open keyboard.
  ///
  /// `onDrag` is what a form page wants — scrolling away from a field
  /// should not leave the reader trapped behind the keyboard — and it
  /// is a house decision rather than a per-page one, which is why it
  /// lives on the bag.
  final ScrollViewKeyboardDismissBehavior? keyboardDismissBehavior;

  /// Whether wheel / trackpad signals are smoothed. Touch drags never
  /// go through this path.
  final bool? smoothWheelScroll;
  final double? wheelMultiplier;
  final double? wheelSmoothness;

  final bool? enableHaptic;
  final bool? respectReducedMotion;

  ScrollableStyle mergedWith(ScrollableStyle? other) {
    if (other == null) return this;
    return ScrollableStyle(
      // The fade is a BAG, so it merges field by field rather than
      // being replaced whole: a caller asking only for a bigger band
      // must not lose the theme's mode.
      edgeFade: edgeFade == null
          ? other.edgeFade
          : edgeFade!.mergedWith(other.edgeFade),
      showScrollToTop: other.showScrollToTop ?? showScrollToTop,
      scrollToTopThreshold: other.scrollToTopThreshold ?? scrollToTopThreshold,
      showScrollProgress: other.showScrollProgress ?? showScrollProgress,
      progressColor: other.progressColor ?? progressColor,
      progressThickness: other.progressThickness ?? progressThickness,
      progressPlacement: other.progressPlacement ?? progressPlacement,
      mode: other.mode ?? mode,
      boundaryBehavior: other.boundaryBehavior ?? boundaryBehavior,
      cacheExtent: other.cacheExtent ?? cacheExtent,
      keyboardDismissBehavior:
          other.keyboardDismissBehavior ?? keyboardDismissBehavior,
      fabSize: other.fabSize ?? fabSize,
      fabMargin: other.fabMargin ?? fabMargin,
      overlayDuration: other.overlayDuration ?? overlayDuration,
      scrollToTopDuration: other.scrollToTopDuration ?? scrollToTopDuration,
      scrollToOffsetDuration:
          other.scrollToOffsetDuration ?? scrollToOffsetDuration,
      smoothWheelScroll: other.smoothWheelScroll ?? smoothWheelScroll,
      wheelMultiplier: other.wheelMultiplier ?? wheelMultiplier,
      wheelSmoothness: other.wheelSmoothness ?? wheelSmoothness,
      enableHaptic: other.enableHaptic ?? enableHaptic,
      respectReducedMotion: other.respectReducedMotion ?? respectReducedMotion,
    );
  }

  ScrollableStyle copyWith({
    EdgeFadeStyle? edgeFade,
    bool? showScrollToTop,
    double? scrollToTopThreshold,
    bool? showScrollProgress,
    Color? progressColor,
    double? progressThickness,
    ScrollProgressPlacement? progressPlacement,
    ScrollableMode? mode,
    BoundaryBehavior? boundaryBehavior,
    double? cacheExtent,
    ScrollViewKeyboardDismissBehavior? keyboardDismissBehavior,
    double? fabSize,
    double? fabMargin,
    Duration? overlayDuration,
    Duration? scrollToTopDuration,
    Duration? scrollToOffsetDuration,
    bool? smoothWheelScroll,
    double? wheelMultiplier,
    double? wheelSmoothness,
    bool? enableHaptic,
    bool? respectReducedMotion,
  }) => ScrollableStyle(
    edgeFade: edgeFade ?? this.edgeFade,
    showScrollToTop: showScrollToTop ?? this.showScrollToTop,
    scrollToTopThreshold: scrollToTopThreshold ?? this.scrollToTopThreshold,
    showScrollProgress: showScrollProgress ?? this.showScrollProgress,
    progressColor: progressColor ?? this.progressColor,
    progressThickness: progressThickness ?? this.progressThickness,
    progressPlacement: progressPlacement ?? this.progressPlacement,
    mode: mode ?? this.mode,
    boundaryBehavior: boundaryBehavior ?? this.boundaryBehavior,
    cacheExtent: cacheExtent ?? this.cacheExtent,
    keyboardDismissBehavior:
        keyboardDismissBehavior ?? this.keyboardDismissBehavior,
    fabSize: fabSize ?? this.fabSize,
    fabMargin: fabMargin ?? this.fabMargin,
    overlayDuration: overlayDuration ?? this.overlayDuration,
    scrollToTopDuration: scrollToTopDuration ?? this.scrollToTopDuration,
    scrollToOffsetDuration:
        scrollToOffsetDuration ?? this.scrollToOffsetDuration,
    smoothWheelScroll: smoothWheelScroll ?? this.smoothWheelScroll,
    wheelMultiplier: wheelMultiplier ?? this.wheelMultiplier,
    wheelSmoothness: wheelSmoothness ?? this.wheelSmoothness,
    enableHaptic: enableHaptic ?? this.enableHaptic,
    respectReducedMotion: respectReducedMotion ?? this.respectReducedMotion,
  );

  @override
  bool operator ==(Object other) =>
      other is ScrollableStyle &&
      other.edgeFade == edgeFade &&
      other.showScrollToTop == showScrollToTop &&
      other.scrollToTopThreshold == scrollToTopThreshold &&
      other.showScrollProgress == showScrollProgress &&
      other.progressColor == progressColor &&
      other.progressThickness == progressThickness &&
      other.progressPlacement == progressPlacement &&
      other.mode == mode &&
      other.boundaryBehavior == boundaryBehavior &&
      other.cacheExtent == cacheExtent &&
      other.keyboardDismissBehavior == keyboardDismissBehavior &&
      other.fabSize == fabSize &&
      other.fabMargin == fabMargin &&
      other.overlayDuration == overlayDuration &&
      other.scrollToTopDuration == scrollToTopDuration &&
      other.scrollToOffsetDuration == scrollToOffsetDuration &&
      other.smoothWheelScroll == smoothWheelScroll &&
      other.wheelMultiplier == wheelMultiplier &&
      other.wheelSmoothness == wheelSmoothness &&
      other.enableHaptic == enableHaptic &&
      other.respectReducedMotion == respectReducedMotion;

  @override
  int get hashCode => Object.hashAll([
    edgeFade,
    showScrollToTop,
    scrollToTopThreshold,
    showScrollProgress,
    progressColor,
    progressThickness,
    progressPlacement,
    mode,
    boundaryBehavior,
    cacheExtent,
    keyboardDismissBehavior,
    fabSize,
    fabMargin,
    overlayDuration,
    scrollToTopDuration,
    scrollToOffsetDuration,
    smoothWheelScroll,
    wheelMultiplier,
    wheelSmoothness,
    enableHaptic,
    respectReducedMotion,
  ]);
}

/// A [ScrollableStyle] with every question answered.
@immutable
class ResolvedScrollableStyle {
  const ResolvedScrollableStyle({
    required this.edgeFade,
    required this.showScrollToTop,
    required this.scrollToTopThreshold,
    required this.showScrollProgress,
    required this.progressColor,
    required this.progressThickness,
    required this.progressPlacement,
    required this.mode,
    required this.boundaryBehavior,
    required this.cacheExtent,
    required this.keyboardDismissBehavior,
    required this.fabSize,
    required this.fabMargin,
    required this.overlayDuration,
    required this.scrollToTopDuration,
    required this.scrollToOffsetDuration,
    required this.smoothWheelScroll,
    required this.wheelMultiplier,
    required this.wheelSmoothness,
    required this.enableHaptic,
  });

  final ResolvedEdgeFadeStyle edgeFade;
  final bool showScrollToTop;
  final double scrollToTopThreshold;
  final bool showScrollProgress;
  final Color progressColor;
  final double progressThickness;
  final ScrollProgressPlacement progressPlacement;
  final ScrollableMode mode;
  final BoundaryBehavior boundaryBehavior;
  final double? cacheExtent;
  final ScrollViewKeyboardDismissBehavior keyboardDismissBehavior;
  final double fabSize;
  final double fabMargin;

  /// Zero under reduced motion — the overlays appear rather than
  /// sliding, and the ride to the top is a jump.
  final Duration overlayDuration;
  final Duration scrollToTopDuration;
  final Duration scrollToOffsetDuration;

  /// Off under reduced motion: the whole point of the smoothing is a
  /// glide the reader did not ask for.
  final bool smoothWheelScroll;

  final double wheelMultiplier;
  final double wheelSmoothness;
  final bool enableHaptic;
}
