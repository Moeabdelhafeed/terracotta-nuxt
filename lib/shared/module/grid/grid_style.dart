import 'package:flutter/material.dart';

import '../list/list_models.dart';
import '../list/list_style.dart';
import '../list/scrubber_models.dart';
import '../scrollable/scroll_in_style.dart';
import '../scrollable/scrollable_style.dart';

/// The grid's own floor, for what a list has no equivalent of.
abstract final class GridDefaults {
  /// Gap on both axes when neither is answered on its own.
  static const spacing = 8.0;

  /// `width / height` of a tile.
  static const aspectRatio = 1.0;

  /// What the scrubber and the jump-to-index maths assume a tile is
  /// tall, before anything has been laid out.
  static const estimatedTileExtent = 100.0;

  /// The reflow when the column count changes.
  static const columnAnimDuration = Duration(milliseconds: 280);
}

/// Everything a `GlobalGrid` looks and behaves like.
///
/// Deliberately the LIST's bag with the grid's own geometry added:
/// they share their controller, their selection, their chrome and
/// their pagination vocabulary, so every field that means the same
/// thing on both is named the same on both. A house that sets a
/// pagination bar height should not get two different bars on one
/// screen.
@immutable
class GridStyle {
  const GridStyle({
    this.scrollable,
    this.scrollIn,
    this.padding,
    this.spacing,
    this.crossAxisSpacing,
    this.mainAxisSpacing,
    this.aspectRatio,
    this.loadingIndicatorColor,
    this.paginationBarHeight,
    this.paginationButtonRadius,
    this.infiniteScrollThreshold,
    this.groupHeaderHeight,
    this.groupHeaderMode,
    this.itemAnimation,
    this.animationDuration,
    this.columnAnimDuration,
    this.estimatedTileExtent,
    this.loadOlderThreshold,
    this.scrubberPlacement,
    this.unifyTiles,
    this.tileRadius,
    this.enableHaptic,
    this.respectReducedMotion,
  });

  /// The floor.
  static const defaults = GridStyle(
    spacing: GridDefaults.spacing,
    aspectRatio: GridDefaults.aspectRatio,
    paginationBarHeight: ListDefaults.paginationBarHeight,
    paginationButtonRadius: ListDefaults.paginationButtonRadius,
    infiniteScrollThreshold: ListDefaults.infiniteScrollThreshold,
    groupHeaderHeight: ListDefaults.groupHeaderHeight,
    groupHeaderMode: GroupHeaderMode.stack,
    itemAnimation: ListItemAnimation.fadeSize,
    animationDuration: ListDefaults.animationDuration,
    columnAnimDuration: GridDefaults.columnAnimDuration,
    estimatedTileExtent: GridDefaults.estimatedTileExtent,
    loadOlderThreshold: ListDefaults.loadOlderThreshold,
    scrubberPlacement: ScrubberPlacement.end,
    unifyTiles: false,
    enableHaptic: true,
    respectReducedMotion: true,
  );

  /// A gallery: square tiles, a soft edge, tiles that arrive in rows.
  static const gallery = GridStyle(
    scrollable: ScrollableStyle(
      showScrollToTop: true,
      edgeFade: EdgeFadeStyle(mode: EdgeFadeMode.shader, size: 16),
    ),
    scrollIn: ScrollInStyle.wave,
  );

  /// No chrome at all.
  static const bare = GridStyle(scrollable: ScrollableStyle.bare);

  final ScrollableStyle? scrollable;
  final ScrollInStyle? scrollIn;
  final EdgeInsetsGeometry? padding;

  /// The gap on BOTH axes, unless an axis answers for itself.
  final double? spacing;
  final double? crossAxisSpacing;
  final double? mainAxisSpacing;

  final double? aspectRatio;
  final Color? loadingIndicatorColor;
  final double? paginationBarHeight;
  final double? paginationButtonRadius;
  final double? infiniteScrollThreshold;
  final double? groupHeaderHeight;
  final GroupHeaderMode? groupHeaderMode;
  final ListItemAnimation? itemAnimation;
  final Duration? animationDuration;

  /// The reflow when the column count changes — a pinch, or a window
  /// crossing a bucket.
  final Duration? columnAnimDuration;

  final double? estimatedTileExtent;
  final double? loadOlderThreshold;

  /// Which edge the A-Z scrubber lives on, and therefore whether it
  /// runs down the side or across the end.
  final ScrubberPlacement? scrubberPlacement;

  /// Rounds the BLOCK, not each tile. **Off by default.**
  ///
  /// Only the four outside corners of the grid survive: the first tile
  /// keeps its top-start, the last tile of the first row its top-end,
  /// the first tile of the last row its bottom-start, the last tile
  /// its bottom-end. Everything else is square, so a grid reads as one
  /// card divided into cells rather than a tray of separate ones.
  ///
  /// Start and end are DIRECTIONAL — the block mirrors in Arabic.
  ///
  /// Off by default because a grid usually IS a tray: a gallery of
  /// photographs wants each tile to look like its own thing. The list
  /// defaults the other way for the opposite reason.
  ///
  /// GROUPED grids get no top corners at all — a header sits above
  /// every run, including the first, so no tile is ever the top of the
  /// card.
  final bool? unifyTiles;

  /// The corner [unifyTiles] rounds the block's outside to. Defaults
  /// to the medium radius token.
  final BorderRadius? tileRadius;

  final bool? enableHaptic;
  final bool? respectReducedMotion;

  GridStyle mergedWith(GridStyle? other) {
    if (other == null) return this;
    return GridStyle(
      scrollable: scrollable == null
          ? other.scrollable
          : scrollable!.mergedWith(other.scrollable),
      scrollIn: scrollIn == null
          ? other.scrollIn
          : scrollIn!.mergedWith(other.scrollIn),
      padding: other.padding ?? padding,
      spacing: other.spacing ?? spacing,
      crossAxisSpacing: other.crossAxisSpacing ?? crossAxisSpacing,
      mainAxisSpacing: other.mainAxisSpacing ?? mainAxisSpacing,
      aspectRatio: other.aspectRatio ?? aspectRatio,
      loadingIndicatorColor:
          other.loadingIndicatorColor ?? loadingIndicatorColor,
      paginationBarHeight: other.paginationBarHeight ?? paginationBarHeight,
      paginationButtonRadius:
          other.paginationButtonRadius ?? paginationButtonRadius,
      infiniteScrollThreshold:
          other.infiniteScrollThreshold ?? infiniteScrollThreshold,
      groupHeaderHeight: other.groupHeaderHeight ?? groupHeaderHeight,
      groupHeaderMode: other.groupHeaderMode ?? groupHeaderMode,
      itemAnimation: other.itemAnimation ?? itemAnimation,
      animationDuration: other.animationDuration ?? animationDuration,
      columnAnimDuration: other.columnAnimDuration ?? columnAnimDuration,
      estimatedTileExtent: other.estimatedTileExtent ?? estimatedTileExtent,
      loadOlderThreshold: other.loadOlderThreshold ?? loadOlderThreshold,
      scrubberPlacement: other.scrubberPlacement ?? scrubberPlacement,
      unifyTiles: other.unifyTiles ?? unifyTiles,
      tileRadius: other.tileRadius ?? tileRadius,
      enableHaptic: other.enableHaptic ?? enableHaptic,
      respectReducedMotion: other.respectReducedMotion ?? respectReducedMotion,
    );
  }

  GridStyle copyWith({
    ScrollableStyle? scrollable,
    ScrollInStyle? scrollIn,
    EdgeInsetsGeometry? padding,
    double? spacing,
    double? crossAxisSpacing,
    double? mainAxisSpacing,
    double? aspectRatio,
    Color? loadingIndicatorColor,
    double? paginationBarHeight,
    double? paginationButtonRadius,
    double? infiniteScrollThreshold,
    double? groupHeaderHeight,
    GroupHeaderMode? groupHeaderMode,
    ListItemAnimation? itemAnimation,
    Duration? animationDuration,
    Duration? columnAnimDuration,
    double? estimatedTileExtent,
    double? loadOlderThreshold,
    ScrubberPlacement? scrubberPlacement,
    bool? unifyTiles,
    BorderRadius? tileRadius,
    bool? enableHaptic,
    bool? respectReducedMotion,
  }) => GridStyle(
    scrollable: scrollable ?? this.scrollable,
    scrollIn: scrollIn ?? this.scrollIn,
    padding: padding ?? this.padding,
    spacing: spacing ?? this.spacing,
    crossAxisSpacing: crossAxisSpacing ?? this.crossAxisSpacing,
    mainAxisSpacing: mainAxisSpacing ?? this.mainAxisSpacing,
    aspectRatio: aspectRatio ?? this.aspectRatio,
    loadingIndicatorColor: loadingIndicatorColor ?? this.loadingIndicatorColor,
    paginationBarHeight: paginationBarHeight ?? this.paginationBarHeight,
    paginationButtonRadius:
        paginationButtonRadius ?? this.paginationButtonRadius,
    infiniteScrollThreshold:
        infiniteScrollThreshold ?? this.infiniteScrollThreshold,
    groupHeaderHeight: groupHeaderHeight ?? this.groupHeaderHeight,
    groupHeaderMode: groupHeaderMode ?? this.groupHeaderMode,
    itemAnimation: itemAnimation ?? this.itemAnimation,
    animationDuration: animationDuration ?? this.animationDuration,
    columnAnimDuration: columnAnimDuration ?? this.columnAnimDuration,
    estimatedTileExtent: estimatedTileExtent ?? this.estimatedTileExtent,
    loadOlderThreshold: loadOlderThreshold ?? this.loadOlderThreshold,
    scrubberPlacement: scrubberPlacement ?? this.scrubberPlacement,
    unifyTiles: unifyTiles ?? this.unifyTiles,
    tileRadius: tileRadius ?? this.tileRadius,
    enableHaptic: enableHaptic ?? this.enableHaptic,
    respectReducedMotion: respectReducedMotion ?? this.respectReducedMotion,
  );

  @override
  bool operator ==(Object other) =>
      other is GridStyle &&
      other.scrollable == scrollable &&
      other.scrollIn == scrollIn &&
      other.padding == padding &&
      other.spacing == spacing &&
      other.crossAxisSpacing == crossAxisSpacing &&
      other.mainAxisSpacing == mainAxisSpacing &&
      other.aspectRatio == aspectRatio &&
      other.loadingIndicatorColor == loadingIndicatorColor &&
      other.paginationBarHeight == paginationBarHeight &&
      other.paginationButtonRadius == paginationButtonRadius &&
      other.infiniteScrollThreshold == infiniteScrollThreshold &&
      other.groupHeaderHeight == groupHeaderHeight &&
      other.groupHeaderMode == groupHeaderMode &&
      other.itemAnimation == itemAnimation &&
      other.animationDuration == animationDuration &&
      other.columnAnimDuration == columnAnimDuration &&
      other.estimatedTileExtent == estimatedTileExtent &&
      other.loadOlderThreshold == loadOlderThreshold &&
      other.scrubberPlacement == scrubberPlacement &&
      other.unifyTiles == unifyTiles &&
      other.tileRadius == tileRadius &&
      other.enableHaptic == enableHaptic &&
      other.respectReducedMotion == respectReducedMotion;

  @override
  int get hashCode => Object.hashAll([
    scrollable,
    scrollIn,
    padding,
    spacing,
    crossAxisSpacing,
    mainAxisSpacing,
    aspectRatio,
    loadingIndicatorColor,
    paginationBarHeight,
    paginationButtonRadius,
    infiniteScrollThreshold,
    groupHeaderHeight,
    groupHeaderMode,
    itemAnimation,
    animationDuration,
    columnAnimDuration,
    estimatedTileExtent,
    loadOlderThreshold,
    scrubberPlacement,
    unifyTiles,
    tileRadius,
    enableHaptic,
    respectReducedMotion,
  ]);
}

/// A [GridStyle] with every question answered.
@immutable
class ResolvedGridStyle {
  const ResolvedGridStyle({
    required this.scrollable,
    required this.scrollIn,
    required this.padding,
    required this.crossAxisSpacing,
    required this.mainAxisSpacing,
    required this.aspectRatio,
    required this.loadingIndicatorColor,
    required this.paginationBarHeight,
    required this.paginationButtonRadius,
    required this.infiniteScrollThreshold,
    required this.groupHeaderHeight,
    required this.groupHeaderMode,
    required this.itemAnimation,
    required this.animationDuration,
    required this.columnAnimDuration,
    required this.estimatedTileExtent,
    required this.loadOlderThreshold,
    required this.scrubberPlacement,
    required this.unifyTiles,
    required this.tileRadius,
    required this.enableHaptic,
    required this.still,
  });

  final ResolvedScrollableStyle scrollable;
  final ResolvedScrollInStyle scrollIn;
  final EdgeInsetsGeometry? padding;

  /// Both axes answered — `spacing` has already been folded in.
  final double crossAxisSpacing;
  final double mainAxisSpacing;

  final double aspectRatio;
  final Color loadingIndicatorColor;
  final double paginationBarHeight;
  final double paginationButtonRadius;
  final double infiniteScrollThreshold;
  final double groupHeaderHeight;
  final GroupHeaderMode groupHeaderMode;
  final ListItemAnimation itemAnimation;

  /// Zero under reduced motion.
  final Duration animationDuration;
  final Duration columnAnimDuration;

  final double estimatedTileExtent;
  final double loadOlderThreshold;
  final ScrubberPlacement scrubberPlacement;
  final bool unifyTiles;
  final BorderRadius tileRadius;
  final bool enableHaptic;
  final bool still;
}
