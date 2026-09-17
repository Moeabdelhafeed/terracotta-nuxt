import 'package:flutter/material.dart';

import '../scrollable/scroll_in_style.dart';
import '../scrollable/scrollable_style.dart';
import 'cross_axis_fit.dart';
import 'list_models.dart';
import 'scrubber_models.dart';

/// The compile-time floor under the list family.
abstract final class ListDefaults {
  /// Gap between items when no `separatorBuilder` is given.
  static const itemSpacing = 0.0;

  /// How wide one swipe action's pane is. Wide enough for a glyph and
  /// a short word under it, and to be hit without aiming.
  static const swipeActionExtent = 72.0;

  /// How far across a row a swipe goes before it commits to the first
  /// action on that side. Past half, so it cannot be reached by the
  /// overshoot of an ordinary open.
  static const swipeFullSwipeThreshold = 0.55;

  /// Fraction of the extent that, once scrolled past, fetches the
  /// next page.
  static const infiniteScrollThreshold = 0.85;

  static const paginationBarHeight = 56.0;
  static const paginationButtonRadius = 8.0;

  /// Height of a group header, which has to be a fixed number: a
  /// sticky header is a `SliverPersistentHeader` and those declare
  /// their extent before they build.
  static const groupHeaderHeight = 36.0;

  /// The most of the viewport that STACKED group headers may take
  /// before the oldest ones are let go.
  ///
  /// Ten sections of a 36-point header is 360 points of header — on a
  /// short window that is the whole list, and the reader is looking at
  /// a stack of labels with no content under it.
  static const stackedHeaderMaxFraction = 0.4;

  /// The insert / remove transition when `animateChanges` is on.
  static const animationDuration = Duration(milliseconds: 350);

  /// What the scrubber and the jump-to-index maths assume a row is
  /// tall, before anything has been laid out.
  static const estimatedItemExtent = 56.0;

  /// How far past the top before "load older" fires.
  static const loadOlderThreshold = 60.0;

  /// The keyboard-focus ring around an item.
  static const focusRingWidth = 2.0;

  /// How far the ring sits OUTSIDE the item it names.
  ///
  /// Zero drew it on the item's own edge, where a tile with a rounded
  /// corner of its own paints over the ring's straighter one — the
  /// corners bled. A hair of inset puts the ring around the tile
  /// instead of on it.
  static const focusRingInset = 2.0;
}

/// Everything a [GlobalList] looks and behaves like.
///
/// All-nullable: the caller answers what it cares about, the theme
/// answers the rest, and [ListDefaults] is the floor.
///
/// **Two of its fields are whole bags of their own.** [scrollable] is
/// the same `ScrollableStyle` every other scrollable in the app takes,
/// and [scrollIn] the same `ScrollInStyle` — so a house sets its edge
/// fade, its scroll-to-top button and its row entrances ONCE, and the
/// list follows along with the page shells. They were eleven flat
/// parameters on the widget, none of which any theme could reach.
@immutable
class ListStyle {
  const ListStyle({
    this.scrollable,
    this.scrollIn,
    this.padding,
    this.itemSpacing,
    this.loadingIndicatorColor,
    this.paginationBarHeight,
    this.paginationButtonRadius,
    this.infiniteScrollThreshold,
    this.groupHeaderHeight,
    this.groupHeaderMode,
    this.maxStackedHeaders,
    this.stackedHeaderMaxFraction,
    this.itemAnimation,
    this.animationDuration,
    this.estimatedItemExtent,
    this.loadOlderThreshold,
    this.focusRingColor,
    this.focusRingWidth,
    this.focusRingRadius,
    this.focusRingInset,
    this.unifyTiles,
    this.scrubberPlacement,
    this.swipeActionExtent,
    this.swipeFullSwipeThreshold,
    this.crossAxisFit,
    this.tileRadius,
    this.enableHaptic,
    this.respectReducedMotion,
  });

  /// The floor. A bag with no answers resolves to this.
  static const defaults = ListStyle(
    itemSpacing: ListDefaults.itemSpacing,
    paginationBarHeight: ListDefaults.paginationBarHeight,
    paginationButtonRadius: ListDefaults.paginationButtonRadius,
    infiniteScrollThreshold: ListDefaults.infiniteScrollThreshold,
    groupHeaderHeight: ListDefaults.groupHeaderHeight,
    groupHeaderMode: GroupHeaderMode.stack,
    stackedHeaderMaxFraction: ListDefaults.stackedHeaderMaxFraction,
    itemAnimation: ListItemAnimation.fadeSize,
    animationDuration: ListDefaults.animationDuration,
    estimatedItemExtent: ListDefaults.estimatedItemExtent,
    loadOlderThreshold: ListDefaults.loadOlderThreshold,
    focusRingWidth: ListDefaults.focusRingWidth,
    focusRingInset: ListDefaults.focusRingInset,
    unifyTiles: true,
    scrubberPlacement: ScrubberPlacement.end,
    swipeActionExtent: ListDefaults.swipeActionExtent,
    swipeFullSwipeThreshold: ListDefaults.swipeFullSwipeThreshold,
    crossAxisFit: ListCrossAxisFit.parent,
    enableHaptic: true,
    respectReducedMotion: true,
  );

  /// A long feed: a soft edge, a way back to the top, and rows that
  /// arrive rather than appearing.
  static const feed = ListStyle(
    scrollable: ScrollableStyle(
      showScrollToTop: true,
      edgeFade: EdgeFadeStyle(mode: EdgeFadeMode.shader, size: 16),
    ),
    scrollIn: ScrollInStyle(animation: ListItemAnimation.fade),
  );

  /// No chrome at all — for a list embedded in something that has its
  /// own.
  static const bare = ListStyle(scrollable: ScrollableStyle.bare);

  /// The scroll shell's own bag: the edge fade, the scroll-to-top
  /// button, the progress strip, the physics.
  final ScrollableStyle? scrollable;

  /// How a row arrives when it scrolls into view.
  final ScrollInStyle? scrollIn;

  final EdgeInsetsGeometry? padding;

  /// Gap between items when no `separatorBuilder` is given. Ignored
  /// when there is one.
  final double? itemSpacing;

  final Color? loadingIndicatorColor;
  final double? paginationBarHeight;
  final double? paginationButtonRadius;
  final double? infiniteScrollThreshold;

  final double? groupHeaderHeight;
  final GroupHeaderMode? groupHeaderMode;

  /// How many `stack`-mode headers may pin at once.
  ///
  /// Null works it out from the viewport and
  /// [stackedHeaderMaxFraction], which is what a list wants: the cap
  /// that matters is how much room is left for CONTENT, and that
  /// changes with the window.
  final int? maxStackedHeaders;

  /// The share of the viewport stacked headers may fill when
  /// [maxStackedHeaders] is null.
  final double? stackedHeaderMaxFraction;

  /// The insert / remove transition when `animateChanges` is on.
  final ListItemAnimation? itemAnimation;
  final Duration? animationDuration;

  final double? estimatedItemExtent;
  final double? loadOlderThreshold;

  /// The keyboard-focus ring around the focused item.
  ///
  /// [focusRingRadius] defaults to the same corner token
  /// `GlobalContainer` rounds to, so a ring around the app's own tile
  /// lines up with it. A caller whose row rounds differently says so
  /// here.
  final Color? focusRingColor;
  final double? focusRingWidth;
  final BorderRadius? focusRingRadius;
  final double? focusRingInset;

  /// Rounds the RUN, not each row. **On by default.**
  ///
  /// The first row keeps its top corners, the last keeps its bottom
  /// ones, and everything between is square — so a list reads as one
  /// card with rules through it rather than a stack of separate ones.
  ///
  /// It was briefly off, on the strength of a measurement that turned
  /// out to be measuring the JIT: the first variant timed in a test
  /// file pays for the warm-up, and this one happened to go first.
  /// Timed properly — interleaved, best of four, after a warm-up run —
  /// it costs about a millisecond over sixty drag frames on a
  /// thousand-row list, which is nothing.
  ///
  /// "Last" is the last row RENDERED, which on a paginated list is the
  /// last row of the page you are on. That is what the reader sees the
  /// bottom of.
  final bool? unifyTiles;

  /// Which edge the A-Z scrubber lives on, and therefore whether it
  /// runs down the side or across the end.
  final ScrubberPlacement? scrubberPlacement;

  /// How wide ONE swipe action's pane is.
  final double? swipeActionExtent;

  /// The fraction of a row's width a swipe crosses before it commits
  /// to the first action on that side without waiting for a tap.
  final double? swipeFullSwipeThreshold;

  /// How a HORIZONTAL list decides its own height.
  ///
  /// Anything but [ListCrossAxisFit.parent] builds every item, and is
  /// for static lists: the async chrome (pagination, grouping, the
  /// scrubber) does not apply in those modes.
  final ListCrossAxisFit? crossAxisFit;

  /// The corner [unifyTiles] rounds the run's ends to. Defaults to the
  /// same token `GlobalContainer` uses, so a run of the app's own
  /// tiles matches the card it replaces.
  final BorderRadius? tileRadius;

  final bool? enableHaptic;
  final bool? respectReducedMotion;

  ListStyle mergedWith(ListStyle? other) {
    if (other == null) return this;
    return ListStyle(
      // Both are BAGS, so they merge field by field rather than being
      // replaced whole: a caller asking for a bigger fade band must
      // not lose the theme's mode.
      scrollable: scrollable == null
          ? other.scrollable
          : scrollable!.mergedWith(other.scrollable),
      scrollIn: scrollIn == null
          ? other.scrollIn
          : scrollIn!.mergedWith(other.scrollIn),
      padding: other.padding ?? padding,
      itemSpacing: other.itemSpacing ?? itemSpacing,
      loadingIndicatorColor:
          other.loadingIndicatorColor ?? loadingIndicatorColor,
      paginationBarHeight: other.paginationBarHeight ?? paginationBarHeight,
      paginationButtonRadius:
          other.paginationButtonRadius ?? paginationButtonRadius,
      infiniteScrollThreshold:
          other.infiniteScrollThreshold ?? infiniteScrollThreshold,
      groupHeaderHeight: other.groupHeaderHeight ?? groupHeaderHeight,
      groupHeaderMode: other.groupHeaderMode ?? groupHeaderMode,
      maxStackedHeaders: other.maxStackedHeaders ?? maxStackedHeaders,
      stackedHeaderMaxFraction:
          other.stackedHeaderMaxFraction ?? stackedHeaderMaxFraction,
      itemAnimation: other.itemAnimation ?? itemAnimation,
      animationDuration: other.animationDuration ?? animationDuration,
      estimatedItemExtent: other.estimatedItemExtent ?? estimatedItemExtent,
      loadOlderThreshold: other.loadOlderThreshold ?? loadOlderThreshold,
      focusRingColor: other.focusRingColor ?? focusRingColor,
      focusRingWidth: other.focusRingWidth ?? focusRingWidth,
      focusRingRadius: other.focusRingRadius ?? focusRingRadius,
      focusRingInset: other.focusRingInset ?? focusRingInset,
      unifyTiles: other.unifyTiles ?? unifyTiles,
      scrubberPlacement: other.scrubberPlacement ?? scrubberPlacement,
      swipeActionExtent: other.swipeActionExtent ?? swipeActionExtent,
      swipeFullSwipeThreshold:
          other.swipeFullSwipeThreshold ?? swipeFullSwipeThreshold,
      crossAxisFit: other.crossAxisFit ?? crossAxisFit,
      tileRadius: other.tileRadius ?? tileRadius,
      enableHaptic: other.enableHaptic ?? enableHaptic,
      respectReducedMotion: other.respectReducedMotion ?? respectReducedMotion,
    );
  }

  ListStyle copyWith({
    ScrollableStyle? scrollable,
    ScrollInStyle? scrollIn,
    EdgeInsetsGeometry? padding,
    double? itemSpacing,
    Color? loadingIndicatorColor,
    double? paginationBarHeight,
    double? paginationButtonRadius,
    double? infiniteScrollThreshold,
    double? groupHeaderHeight,
    GroupHeaderMode? groupHeaderMode,
    int? maxStackedHeaders,
    double? stackedHeaderMaxFraction,
    ListItemAnimation? itemAnimation,
    Duration? animationDuration,
    double? estimatedItemExtent,
    double? loadOlderThreshold,
    Color? focusRingColor,
    double? focusRingWidth,
    BorderRadius? focusRingRadius,
    double? focusRingInset,
    bool? unifyTiles,
    ScrubberPlacement? scrubberPlacement,
    double? swipeActionExtent,
    double? swipeFullSwipeThreshold,
    ListCrossAxisFit? crossAxisFit,
    BorderRadius? tileRadius,
    bool? enableHaptic,
    bool? respectReducedMotion,
  }) => ListStyle(
    scrollable: scrollable ?? this.scrollable,
    scrollIn: scrollIn ?? this.scrollIn,
    padding: padding ?? this.padding,
    itemSpacing: itemSpacing ?? this.itemSpacing,
    loadingIndicatorColor: loadingIndicatorColor ?? this.loadingIndicatorColor,
    paginationBarHeight: paginationBarHeight ?? this.paginationBarHeight,
    paginationButtonRadius:
        paginationButtonRadius ?? this.paginationButtonRadius,
    infiniteScrollThreshold:
        infiniteScrollThreshold ?? this.infiniteScrollThreshold,
    groupHeaderHeight: groupHeaderHeight ?? this.groupHeaderHeight,
    groupHeaderMode: groupHeaderMode ?? this.groupHeaderMode,
    maxStackedHeaders: maxStackedHeaders ?? this.maxStackedHeaders,
    stackedHeaderMaxFraction:
        stackedHeaderMaxFraction ?? this.stackedHeaderMaxFraction,
    itemAnimation: itemAnimation ?? this.itemAnimation,
    animationDuration: animationDuration ?? this.animationDuration,
    estimatedItemExtent: estimatedItemExtent ?? this.estimatedItemExtent,
    loadOlderThreshold: loadOlderThreshold ?? this.loadOlderThreshold,
    focusRingColor: focusRingColor ?? this.focusRingColor,
    focusRingWidth: focusRingWidth ?? this.focusRingWidth,
    focusRingRadius: focusRingRadius ?? this.focusRingRadius,
    focusRingInset: focusRingInset ?? this.focusRingInset,
    unifyTiles: unifyTiles ?? this.unifyTiles,
    scrubberPlacement: scrubberPlacement ?? this.scrubberPlacement,
    swipeActionExtent: swipeActionExtent ?? this.swipeActionExtent,
    swipeFullSwipeThreshold:
        swipeFullSwipeThreshold ?? this.swipeFullSwipeThreshold,
    crossAxisFit: crossAxisFit ?? this.crossAxisFit,
    tileRadius: tileRadius ?? this.tileRadius,
    enableHaptic: enableHaptic ?? this.enableHaptic,
    respectReducedMotion: respectReducedMotion ?? this.respectReducedMotion,
  );

  @override
  bool operator ==(Object other) =>
      other is ListStyle &&
      other.scrollable == scrollable &&
      other.scrollIn == scrollIn &&
      other.padding == padding &&
      other.itemSpacing == itemSpacing &&
      other.loadingIndicatorColor == loadingIndicatorColor &&
      other.paginationBarHeight == paginationBarHeight &&
      other.paginationButtonRadius == paginationButtonRadius &&
      other.infiniteScrollThreshold == infiniteScrollThreshold &&
      other.groupHeaderHeight == groupHeaderHeight &&
      other.groupHeaderMode == groupHeaderMode &&
      other.maxStackedHeaders == maxStackedHeaders &&
      other.stackedHeaderMaxFraction == stackedHeaderMaxFraction &&
      other.itemAnimation == itemAnimation &&
      other.animationDuration == animationDuration &&
      other.estimatedItemExtent == estimatedItemExtent &&
      other.loadOlderThreshold == loadOlderThreshold &&
      other.focusRingColor == focusRingColor &&
      other.focusRingWidth == focusRingWidth &&
      other.focusRingRadius == focusRingRadius &&
      other.focusRingInset == focusRingInset &&
      other.unifyTiles == unifyTiles &&
      other.scrubberPlacement == scrubberPlacement &&
      other.swipeActionExtent == swipeActionExtent &&
      other.swipeFullSwipeThreshold == swipeFullSwipeThreshold &&
      other.crossAxisFit == crossAxisFit &&
      other.tileRadius == tileRadius &&
      other.enableHaptic == enableHaptic &&
      other.respectReducedMotion == respectReducedMotion;

  @override
  int get hashCode => Object.hashAll([
    scrollable,
    scrollIn,
    padding,
    itemSpacing,
    loadingIndicatorColor,
    paginationBarHeight,
    paginationButtonRadius,
    infiniteScrollThreshold,
    groupHeaderHeight,
    groupHeaderMode,
    maxStackedHeaders,
    stackedHeaderMaxFraction,
    itemAnimation,
    animationDuration,
    estimatedItemExtent,
    loadOlderThreshold,
    focusRingColor,
    focusRingWidth,
    focusRingRadius,
    focusRingInset,
    unifyTiles,
    scrubberPlacement,
    swipeActionExtent,
    swipeFullSwipeThreshold,
    crossAxisFit,
    tileRadius,
    enableHaptic,
    respectReducedMotion,
  ]);
}

/// A [ListStyle] with every question answered.
@immutable
class ResolvedListStyle {
  const ResolvedListStyle({
    required this.scrollable,
    required this.scrollIn,
    required this.padding,
    required this.itemSpacing,
    required this.loadingIndicatorColor,
    required this.paginationBarHeight,
    required this.paginationButtonRadius,
    required this.infiniteScrollThreshold,
    required this.groupHeaderHeight,
    required this.groupHeaderMode,
    required this.maxStackedHeaders,
    required this.stackedHeaderMaxFraction,
    required this.itemAnimation,
    required this.animationDuration,
    required this.estimatedItemExtent,
    required this.loadOlderThreshold,
    required this.focusRingColor,
    required this.focusRingWidth,
    required this.focusRingRadius,
    required this.focusRingInset,
    required this.unifyTiles,
    required this.scrubberPlacement,
    required this.swipeActionExtent,
    required this.swipeFullSwipeThreshold,
    required this.crossAxisFit,
    required this.tileRadius,
    required this.enableHaptic,
    required this.still,
  });

  /// Already resolved — the list hands this straight to
  /// `GlobalEdgeFade` and `GlobalScrollOverlays`.
  final ResolvedScrollableStyle scrollable;
  final ResolvedScrollInStyle scrollIn;

  final EdgeInsetsGeometry? padding;
  final double itemSpacing;

  /// The palette accent unless the caller said otherwise.
  final Color loadingIndicatorColor;

  final double paginationBarHeight;
  final double paginationButtonRadius;
  final double infiniteScrollThreshold;
  final double groupHeaderHeight;
  final GroupHeaderMode groupHeaderMode;

  /// Null means "work it out from the viewport".
  final int? maxStackedHeaders;
  final double stackedHeaderMaxFraction;

  final ListItemAnimation itemAnimation;

  /// Zero under reduced motion — an item that changes is REPLACED
  /// rather than sliding, which is what the reader asked for.
  final Duration animationDuration;

  final double estimatedItemExtent;
  final double loadOlderThreshold;

  /// Already resolved against the palette and the corner token.
  final Color focusRingColor;
  final double focusRingWidth;
  final BorderRadius focusRingRadius;
  final double focusRingInset;

  /// Rounds the RUN, not each row — see [ListStyle.unifyTiles].
  final bool unifyTiles;
  final ScrubberPlacement scrubberPlacement;
  final double swipeActionExtent;
  final double swipeFullSwipeThreshold;

  /// How a horizontal list decides its own height — see
  /// [ListStyle.crossAxisFit].
  final ListCrossAxisFit crossAxisFit;

  final BorderRadius tileRadius;

  final bool enableHaptic;

  /// The reader asked for no motion.
  final bool still;
}
