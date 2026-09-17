import 'package:flutter/material.dart';

import '../../../../core/extensions/theme_colors_extension.dart';
import '../../../../core/tokens/extensions.dart';
import '../../grid/grid_style.dart';
import '../../scrollable/theme/scrollable_theme.dart';
import '../cross_axis_fit.dart';
import '../list_models.dart';
import '../list_style.dart';
import '../scrubber_models.dart';

/// App-wide defaults for the two collections — the list and the grid.
///
/// **One extension, two bags, on purpose.** They share their
/// controller, their selection, their chrome, their pagination
/// vocabulary and half their parameters; two extensions would be two
/// rebrand hooks that can disagree, and a house that set a pagination
/// bar height on one and not the other would get two different bars on
/// the same screen.
@immutable
class GlobalCollectionTheme extends ThemeExtension<GlobalCollectionTheme> {
  const GlobalCollectionTheme({this.listStyle, this.gridStyle});

  final ListStyle? listStyle;
  final GridStyle? gridStyle;

  static GlobalCollectionTheme? maybeOf(BuildContext context) =>
      Theme.of(context).extension<GlobalCollectionTheme>();

  @override
  GlobalCollectionTheme copyWith({
    ListStyle? listStyle,
    GridStyle? gridStyle,
  }) => GlobalCollectionTheme(
    listStyle: listStyle ?? this.listStyle,
    gridStyle: gridStyle ?? this.gridStyle,
  );

  @override
  GlobalCollectionTheme lerp(
    ThemeExtension<GlobalCollectionTheme>? other,
    double t,
  ) {
    if (other is! GlobalCollectionTheme) return this;
    // A bag of independent decisions, not a value with a midpoint —
    // half a `GroupHeaderMode.stack` means nothing. It SNAPS at the
    // halfway mark, which is what every other bag in this app does.
    return t < 0.5 ? this : other;
  }
}

/// Turns a caller's bag into one with every question answered.
extension ListStyleResolve on ListStyle? {
  /// `caller > GlobalCollectionTheme.listStyle > ListStyle.defaults`,
  /// then the palette and the reader's reduce-motion setting.
  ResolvedListStyle resolve(BuildContext context) {
    final merged = ListStyle.defaults
        .mergedWith(GlobalCollectionTheme.maybeOf(context)?.listStyle)
        .mergedWith(this);

    // The READER's setting. Neither collection read it before: a list
    // is the most-repeated motion surface in an app, and every insert,
    // remove and reorder animated regardless.
    final respect = merged.respectReducedMotion ?? true;
    final still = respect && MediaQuery.disableAnimationsOf(context);

    return ResolvedListStyle(
      scrollable: merged.scrollable.resolve(context),
      scrollIn: merged.scrollIn.resolve(context),
      padding: merged.padding,
      itemSpacing: merged.itemSpacing ?? ListDefaults.itemSpacing,
      // The palette accent. It was Material's own scheme, so a rebrand
      // moved the app and left every list spinner behind.
      loadingIndicatorColor:
          merged.loadingIndicatorColor ?? context.primaryColors.primary,
      paginationBarHeight:
          merged.paginationBarHeight ?? ListDefaults.paginationBarHeight,
      paginationButtonRadius:
          merged.paginationButtonRadius ?? ListDefaults.paginationButtonRadius,
      infiniteScrollThreshold:
          merged.infiniteScrollThreshold ??
          ListDefaults.infiniteScrollThreshold,
      groupHeaderHeight:
          merged.groupHeaderHeight ?? ListDefaults.groupHeaderHeight,
      groupHeaderMode: merged.groupHeaderMode ?? GroupHeaderMode.stack,
      maxStackedHeaders: merged.maxStackedHeaders,
      stackedHeaderMaxFraction:
          merged.stackedHeaderMaxFraction ??
          ListDefaults.stackedHeaderMaxFraction,
      itemAnimation: merged.itemAnimation ?? ListItemAnimation.fadeSize,
      // ZERO, not short: an item that changes is REPLACED rather than
      // raced into place.
      animationDuration: still
          ? Duration.zero
          : (merged.animationDuration ?? ListDefaults.animationDuration),
      estimatedItemExtent:
          merged.estimatedItemExtent ?? ListDefaults.estimatedItemExtent,
      loadOlderThreshold:
          merged.loadOlderThreshold ?? ListDefaults.loadOlderThreshold,
      focusRingColor: merged.focusRingColor ?? context.primaryColors.primary,
      focusRingWidth: merged.focusRingWidth ?? ListDefaults.focusRingWidth,
      // The SAME corner token `GlobalContainer` rounds to. It was a
      // hard-coded 8 while the app's tiles round to `radii.md`, so the
      // ring's corners cut across the tile's.
      focusRingRadius:
          merged.focusRingRadius ?? BorderRadius.circular(context.radii.md),
      focusRingInset: merged.focusRingInset ?? ListDefaults.focusRingInset,
      unifyTiles: merged.unifyTiles ?? true,
      scrubberPlacement: merged.scrubberPlacement ?? ScrubberPlacement.end,
      swipeActionExtent:
          merged.swipeActionExtent ?? ListDefaults.swipeActionExtent,
      swipeFullSwipeThreshold:
          merged.swipeFullSwipeThreshold ??
          ListDefaults.swipeFullSwipeThreshold,
      crossAxisFit: merged.crossAxisFit ?? ListCrossAxisFit.parent,
      // The SAME corner token `GlobalContainer` rounds to, so a
      // unified run matches the card it stands in for.
      tileRadius: merged.tileRadius ?? BorderRadius.circular(context.radii.md),
      enableHaptic: merged.enableHaptic ?? true,
      still: still,
    );
  }
}

/// The grid's own resolve, over the same extension.
extension GridStyleResolve on GridStyle? {
  ResolvedGridStyle resolve(BuildContext context) {
    final merged = GridStyle.defaults
        .mergedWith(GlobalCollectionTheme.maybeOf(context)?.gridStyle)
        .mergedWith(this);

    final respect = merged.respectReducedMotion ?? true;
    final still = respect && MediaQuery.disableAnimationsOf(context);

    final spacing = merged.spacing ?? GridDefaults.spacing;

    return ResolvedGridStyle(
      scrollable: merged.scrollable.resolve(context),
      scrollIn: merged.scrollIn.resolve(context),
      padding: merged.padding,
      // One `spacing` answers BOTH axes unless an axis says otherwise,
      // which is what a caller means nine times out of ten.
      crossAxisSpacing: merged.crossAxisSpacing ?? spacing,
      mainAxisSpacing: merged.mainAxisSpacing ?? spacing,
      aspectRatio: merged.aspectRatio ?? GridDefaults.aspectRatio,
      loadingIndicatorColor:
          merged.loadingIndicatorColor ?? context.primaryColors.primary,
      paginationBarHeight:
          merged.paginationBarHeight ?? ListDefaults.paginationBarHeight,
      paginationButtonRadius:
          merged.paginationButtonRadius ?? ListDefaults.paginationButtonRadius,
      infiniteScrollThreshold:
          merged.infiniteScrollThreshold ??
          ListDefaults.infiniteScrollThreshold,
      groupHeaderHeight:
          merged.groupHeaderHeight ?? ListDefaults.groupHeaderHeight,
      groupHeaderMode: merged.groupHeaderMode ?? GroupHeaderMode.stack,
      itemAnimation: merged.itemAnimation ?? ListItemAnimation.fadeSize,
      scrubberPlacement: merged.scrubberPlacement ?? ScrubberPlacement.end,
      unifyTiles: merged.unifyTiles ?? false,
      tileRadius: merged.tileRadius ?? BorderRadius.circular(context.radii.md),
      animationDuration: still
          ? Duration.zero
          : (merged.animationDuration ?? ListDefaults.animationDuration),
      columnAnimDuration: still
          ? Duration.zero
          : (merged.columnAnimDuration ?? GridDefaults.columnAnimDuration),
      estimatedTileExtent:
          merged.estimatedTileExtent ?? GridDefaults.estimatedTileExtent,
      loadOlderThreshold:
          merged.loadOlderThreshold ?? ListDefaults.loadOlderThreshold,
      enableHaptic: merged.enableHaptic ?? true,
      still: still,
    );
  }
}
