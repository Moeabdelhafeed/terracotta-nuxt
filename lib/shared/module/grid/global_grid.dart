import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart'
    show
        BoxHitTestResult,
        RenderAbstractViewport,
        RenderBox,
        RenderMetaData,
        ScrollCacheExtent;
import 'package:flutter/scheduler.dart' show SchedulerBinding, SchedulerPhase;
import 'package:flutter/services.dart'
    show HapticFeedback, HardwareKeyboard, LogicalKeyboardKey;

import '../../../core/extensions/theme_colors_extension.dart';
import '../../../core/localization/number_formatter.dart';
import '../../../core/localization/strings/common_strings.dart';
import '../../../core/localization/strings/list_strings.dart';
import '../../../core/responsive/responsive_value.dart';
import '../../../core/tokens/extensions.dart';
import '../buttons/global_filled_button.dart';
import '../buttons/global_icon_button.dart';
import '../buttons/global_text_button.dart';
import '../chip/global_chip.dart';
import '../container/container_corner_scope.dart';
import '../empty_state/global_empty_state.dart';
import '../list/global_list.dart' show GlobalListSearchBar;
import '../list/global_list_controller.dart';
import '../list/list_selection_controller.dart';
import '../list/scrubber.dart';
import '../list/theme/collection_theme.dart';
import '../popup/popup.dart';
import '../refreshable/global_refreshable.dart';
import '../scrollable/global_scrollable.dart';
import '../shimmer/global_shimmer.dart';
import 'grid_models.dart';
import 'grid_style.dart';

export '../list/global_list.dart' show GlobalListSearchHighlight;
export '../list/global_list_controller.dart';
export '../list/list_selection_controller.dart';
export '../list/theme/collection_theme.dart';
export '../scrollable/global_scroll_in.dart'
    show GridReorderMode, ScrollInMode, ScrollInStaggerMode;
export 'grid_models.dart';
export 'grid_style.dart';

/// Builder that renders a single grid item.
typedef GlobalGridItemBuilder<T> =
    Widget Function(BuildContext context, T item, int index);

/// Error widget builder. `retry` runs [GlobalListController.retry].
typedef GlobalGridErrorBuilder =
    Widget Function(BuildContext context, Object error, VoidCallback retry);

/// A responsive, scrollable grid with the same async / chrome surface
/// as `GlobalList`. Picks column count from a [ResponsiveValue<int>]
/// (or per-bucket params) and pulls spacing from design tokens.
///
/// Two construction modes:
///
/// * **Async / paginated** — pass a [GlobalListController] (same
///   controller used by `GlobalList` — items + fetch state).
/// * **Static** — `GlobalGrid.static(items: [...])`. Sync, no async
///   chrome.
///
/// Reuses chrome from the `scrollable` module: edge fade, scroll-to-
/// top FAB, scroll progress strip, scroll-position restoration. Also
/// supports search bar w/ predicate, empty CTA, pull-to-refresh,
/// pull-up to load older.
class GlobalGrid<T> extends StatefulWidget {
  const GlobalGrid({
    super.key,
    required this.controller,
    required this.itemBuilder,
    this.columnsByBucket,
    this.compactColumns,
    this.mediumColumns,
    this.expandedColumns,
    this.largeColumns,
    this.extraLargeColumns,
    this.style,
    this.headerSlivers = const [],
    this.footerBuilder,
    this.emptyBuilder,
    this.emptyAction,
    this.loadingBuilder,
    this.loadingMoreBuilder,
    this.skeletonBuilder,
    this.skeletonCount,
    this.errorBuilder,
    this.onRefresh,
    this.refreshController,
    this.onLoadOlder,
    this.loadOlderThreshold = 60,
    this.paginationStyle = PaginationStyle.infiniteScroll,
    this.loadMoreLabel,
    this.scrollController,
    this.physics,
    this.shrinkWrap = false,
    this.cacheExtent,
    this.scrollDirection = Axis.vertical,
    this.reverse = false,
    this.primary,
    this.autoLoad = true,
    this.edgeFade,
    this.showScrollToTop,
    this.scrollToTopBuilder,
    this.scrollToTopThreshold,
    this.showScrollProgress,
    this.progressColor,
    this.restorationId,
    this.showSearchBar = false,
    this.searchHint,
    this.searchField,
    this.searchPredicate,
    this.selection,
    this.bulkActions,
    this.bulkActionsBuilder,
    this.enableKeyboardNav = false,
    this.onItemActivate,
    this.onItemVisible,
    this.onItemContextMenu,
    this.selectOnTap = false,
    this.unifyTiles,
    this.animateChanges = false,
    this.itemAnimation,
    this.animationDuration,
    this.autoScrollOnNewItem = false,
    this.showNewItemFab = false,
    this.newItemFabBuilder,
    this.estimatedTileExtent,
    this.groupBy,
    this.groupHeaderBuilder,
    this.groupHeaderHeight,
    this.groupHeaderMode,
    this.sectionDividerBuilder,
    this.enableScrubber = false,
    this.stickyHeader,
    this.stickyFooter,
    this.snap = false,
    this.snapRowExtent,
    this.enablePinchZoom = false,
    this.onPinchScale,
    this.animateColumnChange = false,
    this.columnAnimDuration,
    this.tileMaxExtent,
    this.useReflowLayout = false,
    this.scrollInAnimation,
    this.scrollInDuration,
    this.scrollInThreshold,
    this.scrollInOnce,
    this.scrollInStagger,
    this.scrollInStaggerMode,
    this.scrollInDirectionAware = false,
    this.onScrollInComplete,
    this.scrollInMode,
    this.tileExtentExtractor,
    this.reorderable = false,
    this.onReorder,
    this.reorderMode = GridReorderMode.liveInsert,
  }) : _staticItems = null,
       // `tileMaxExtent` is the OTHER way to say how wide a tile is —
       // it derives the column count from the window instead of
       // naming one per bucket. Demanding a bucket slot alongside it
       // asked for the same answer twice, and refused a grid that had
       // already given it.
       assert(
         tileMaxExtent != null ||
             columnsByBucket != null ||
             compactColumns != null ||
             mediumColumns != null ||
             expandedColumns != null ||
             largeColumns != null ||
             extraLargeColumns != null,
         'Provide tileMaxExtent, columnsByBucket, or at least one '
         '*Columns slot',
       ),
       assert(
         !(reorderable && enablePinchZoom),
         'reorderable and enablePinchZoom both consume long-press / scale '
         'gestures and cannot be enabled together. Pick one.',
       );

  /// Static (non-paginated, non-async) variant. Skips loading /
  /// empty / pagination chrome and renders the provided items.
  GlobalGrid.static({
    Key? key,
    required List<T> items,
    required GlobalGridItemBuilder<T> itemBuilder,
    ResponsiveValue<int>? columnsByBucket,
    int? compactColumns,
    int? mediumColumns,
    int? expandedColumns,
    int? largeColumns,
    int? extraLargeColumns,
    GridStyle? style,
    List<Widget> headerSlivers = const [],
    WidgetBuilder? footerBuilder,
    ScrollController? scrollController,
    ScrollPhysics? physics,
    bool shrinkWrap = false,
    double? cacheExtent,
    Axis scrollDirection = Axis.vertical,
    bool reverse = false,
    bool? primary,
    EdgeFadeStyle? edgeFade,
    bool? showScrollToTop,
    Widget Function(BuildContext, VoidCallback)? scrollToTopBuilder,
    double? scrollToTopThreshold,
    bool? showScrollProgress,
    Color? progressColor,
    String? restorationId,
    bool showSearchBar = false,
    String? searchHint,
    Widget Function(BuildContext, TextEditingController)? searchField,
    bool Function(T item, String query)? searchPredicate,
    ListSelectionController<T>? selection,
    List<GlobalBulkAction<T>>? bulkActions,
    PreferredSizeWidget Function(BuildContext, ListSelectionController<T>)?
    bulkActionsBuilder,
    bool enableKeyboardNav = false,
    void Function(int index)? onItemActivate,
    void Function(int index)? onItemVisible,
    void Function(BuildContext, int index, Offset position)? onItemContextMenu,
    bool selectOnTap = false,
    bool? unifyTiles,
    bool animateChanges = false,
    ListItemAnimation? itemAnimation,
    Duration? animationDuration,
    double? estimatedTileExtent,
    Object Function(T item)? groupBy,
    Widget Function(BuildContext, Object key, int count)? groupHeaderBuilder,
    double? groupHeaderHeight,
    GroupHeaderMode? groupHeaderMode,
    Widget Function(BuildContext, Object key, int count)? sectionDividerBuilder,
    bool enableScrubber = false,
    Widget? stickyHeader,
    Widget? stickyFooter,
    bool snap = false,
    double? snapRowExtent,
    bool enablePinchZoom = false,
    void Function(double scale)? onPinchScale,
    bool animateColumnChange = false,
    Duration? columnAnimDuration,
    double? tileMaxExtent,
    bool useReflowLayout = false,
    ListItemAnimation? scrollInAnimation,
    Duration? scrollInDuration,
    double? scrollInThreshold,
    bool? scrollInOnce,
    Duration? scrollInStagger,
    ScrollInStaggerMode? scrollInStaggerMode,
    bool scrollInDirectionAware = false,
    void Function(int index)? onScrollInComplete,
    ScrollInMode? scrollInMode,
    double Function(T item, double tileWidth)? tileExtentExtractor,
    bool reorderable = false,
    void Function(int from, int to)? onReorder,
    GridReorderMode reorderMode = GridReorderMode.liveInsert,
  }) : this._internal(
         key: key,
         controller: null,
         staticItems: items,
         itemBuilder: itemBuilder,
         columnsByBucket: columnsByBucket,
         compactColumns: compactColumns,
         mediumColumns: mediumColumns,
         expandedColumns: expandedColumns,
         largeColumns: largeColumns,
         extraLargeColumns: extraLargeColumns,
         style: style,
         headerSlivers: headerSlivers,
         footerBuilder: footerBuilder,
         scrollController: scrollController,
         physics: physics,
         shrinkWrap: shrinkWrap,
         cacheExtent: cacheExtent,
         scrollDirection: scrollDirection,
         reverse: reverse,
         primary: primary,
         edgeFade: edgeFade,
         showScrollToTop: showScrollToTop,
         scrollToTopBuilder: scrollToTopBuilder,
         scrollToTopThreshold: scrollToTopThreshold,
         showScrollProgress: showScrollProgress,
         progressColor: progressColor,
         restorationId: restorationId,
         showSearchBar: showSearchBar,
         searchHint: searchHint,
         searchField: searchField,
         searchPredicate: searchPredicate,
         selection: selection,
         bulkActions: bulkActions,
         bulkActionsBuilder: bulkActionsBuilder,
         enableKeyboardNav: enableKeyboardNav,
         onItemActivate: onItemActivate,
         onItemVisible: onItemVisible,
         onItemContextMenu: onItemContextMenu,
         selectOnTap: selectOnTap,
         unifyTiles: unifyTiles,
         animateChanges: animateChanges,
         itemAnimation: itemAnimation,
         animationDuration: animationDuration,
         estimatedTileExtent: estimatedTileExtent,
         groupBy: groupBy,
         groupHeaderBuilder: groupHeaderBuilder,
         groupHeaderHeight: groupHeaderHeight,
         groupHeaderMode: groupHeaderMode,
         sectionDividerBuilder: sectionDividerBuilder,
         enableScrubber: enableScrubber,
         stickyHeader: stickyHeader,
         stickyFooter: stickyFooter,
         snap: snap,
         snapRowExtent: snapRowExtent,
         enablePinchZoom: enablePinchZoom,
         onPinchScale: onPinchScale,
         animateColumnChange: animateColumnChange,
         columnAnimDuration: columnAnimDuration,
         tileMaxExtent: tileMaxExtent,
         useReflowLayout: useReflowLayout,
         scrollInAnimation: scrollInAnimation,
         scrollInDuration: scrollInDuration,
         scrollInThreshold: scrollInThreshold,
         scrollInOnce: scrollInOnce,
         scrollInStagger: scrollInStagger,
         scrollInStaggerMode: scrollInStaggerMode,
         scrollInDirectionAware: scrollInDirectionAware,
         onScrollInComplete: onScrollInComplete,
         scrollInMode: scrollInMode,
         tileExtentExtractor: tileExtentExtractor,
         reorderable: reorderable,
         onReorder: onReorder,
         reorderMode: reorderMode,
       );

  GlobalGrid._internal({
    super.key,
    required GlobalListController<T>? controller,
    required this.itemBuilder,
    required List<T>? staticItems,
    this.columnsByBucket,
    this.compactColumns,
    this.mediumColumns,
    this.expandedColumns,
    this.largeColumns,
    this.extraLargeColumns,
    this.style,
    this.headerSlivers = const [],
    this.footerBuilder,
    this.scrollController,
    this.physics,
    this.shrinkWrap = false,
    this.cacheExtent,
    this.scrollDirection = Axis.vertical,
    this.reverse = false,
    this.primary,
    this.edgeFade,
    this.showScrollToTop,
    this.scrollToTopBuilder,
    this.scrollToTopThreshold,
    this.showScrollProgress,
    this.progressColor,
    this.restorationId,
    this.showSearchBar = false,
    this.searchHint,
    this.searchField,
    this.searchPredicate,
    this.selection,
    this.bulkActions,
    this.bulkActionsBuilder,
    this.enableKeyboardNav = false,
    this.onItemActivate,
    this.onItemVisible,
    this.onItemContextMenu,
    this.selectOnTap = false,
    this.unifyTiles,
    this.animateChanges = false,
    this.itemAnimation,
    this.animationDuration,
    this.estimatedTileExtent,
    this.groupBy,
    this.groupHeaderBuilder,
    this.groupHeaderHeight,
    this.groupHeaderMode,
    this.sectionDividerBuilder,
    this.enableScrubber = false,
    this.stickyHeader,
    this.stickyFooter,
    this.snap = false,
    this.snapRowExtent,
    this.enablePinchZoom = false,
    this.onPinchScale,
    this.animateColumnChange = false,
    this.columnAnimDuration,
    this.tileMaxExtent,
    this.useReflowLayout = false,
    this.scrollInAnimation,
    this.scrollInDuration,
    this.scrollInThreshold,
    this.scrollInOnce,
    this.scrollInStagger,
    this.scrollInStaggerMode,
    this.scrollInDirectionAware = false,
    this.onScrollInComplete,
    this.scrollInMode,
    this.tileExtentExtractor,
    this.reorderable = false,
    this.onReorder,
    this.reorderMode = GridReorderMode.liveInsert,
  }) : assert(
         !(reorderable && enablePinchZoom),
         'reorderable and enablePinchZoom both consume long-press / scale '
         'gestures and cannot be enabled together. Pick one.',
       ),
       // The default constructor refused a grid with no column slot
       // and `.static` did not, so a static grid with none went into
       // the responsive resolve with every bucket null. It is the same
       // mistake in both places; it should read the same in both.
       // `tileMaxExtent` is the OTHER way to say how wide a tile is —
       // it derives the column count from the window instead of
       // naming one per bucket. Demanding a bucket slot alongside it
       // asked for the same answer twice, and refused a grid that had
       // already given it.
       assert(
         tileMaxExtent != null ||
             columnsByBucket != null ||
             compactColumns != null ||
             mediumColumns != null ||
             expandedColumns != null ||
             largeColumns != null ||
             extraLargeColumns != null,
         'Provide tileMaxExtent, columnsByBucket, or at least one '
         '*Columns slot',
       ),
       controller = controller ?? _NoOpGridController<T>(),
       _staticItems = staticItems,
       emptyBuilder = null,
       emptyAction = null,
       loadingBuilder = null,
       loadingMoreBuilder = null,
       skeletonBuilder = null,
       skeletonCount = null,
       errorBuilder = null,
       onRefresh = null,
       refreshController = null,
       onLoadOlder = null,
       loadOlderThreshold = 60,
       paginationStyle = PaginationStyle.none,
       loadMoreLabel = null,
       autoLoad = false,
       autoScrollOnNewItem = false,
       showNewItemFab = false,
       newItemFabBuilder = null;

  // ─── Layout ────────────────────────────────────────────────

  final ResponsiveValue<int>? columnsByBucket;
  final int? compactColumns;
  final int? mediumColumns;
  final int? expandedColumns;
  final int? largeColumns;
  final int? extraLargeColumns;

  // ─── Items ─────────────────────────────────────────────────

  final GlobalListController<T> controller;
  final GlobalGridItemBuilder<T> itemBuilder;
  final List<T>? _staticItems;

  // ─── Style ─────────────────────────────────────────────────

  /// The themeable bag. Merged over
  /// `GlobalCollectionTheme.gridStyle` and then `GridStyle.defaults`,
  /// so a field left unanswered here reaches the app-wide layer.
  final GridStyle? style;

  // ─── Slots ─────────────────────────────────────────────────

  final List<Widget> headerSlivers;
  final WidgetBuilder? footerBuilder;
  final WidgetBuilder? emptyBuilder;
  final GlobalEmptyAction? emptyAction;
  final WidgetBuilder? loadingBuilder;
  final WidgetBuilder? loadingMoreBuilder;
  final IndexedWidgetBuilder? skeletonBuilder;

  /// Number of skeleton tiles to render during initial loading.
  /// When null, defaults to `(columns * 6).clamp(6, 24)` — typically
  /// fills the viewport. The widget then clamps to fit available
  /// height so no overflow occurs.
  final int? skeletonCount;
  final GlobalGridErrorBuilder? errorBuilder;

  // ─── Behaviour ─────────────────────────────────────────────

  final RefreshCallback? onRefresh;

  /// Drives the pull-to-refresh from outside the tree — after a
  /// sign-in, from a toast's Retry, on resume. Needs [onRefresh]: a
  /// grid with nothing to refresh has nothing for it to start.
  final GlobalRefreshableController? refreshController;
  final Future<void> Function()? onLoadOlder;
  final double loadOlderThreshold;
  final PaginationStyle paginationStyle;
  final String? loadMoreLabel;
  final bool autoLoad;

  // ─── Scroll behaviour ──────────────────────────────────────

  final ScrollController? scrollController;
  final ScrollPhysics? physics;
  final bool shrinkWrap;
  final double? cacheExtent;
  final Axis scrollDirection;
  final bool reverse;
  final bool? primary;

  // ─── Chrome (delegated to scrollable module) ───────────────

  final EdgeFadeStyle? edgeFade;
  final bool? showScrollToTop;
  final double? scrollToTopThreshold;

  /// Replaces the scroll-to-top button with the caller's own. It gets
  /// the callback that scrolls; everything else — the shape, when it
  /// appears, where it sits — stays the overlay's. Same slot the list
  /// has always had; the grid hard-coded the button.
  final Widget Function(BuildContext, VoidCallback)? scrollToTopBuilder;
  final bool? showScrollProgress;
  final Color? progressColor;
  final String? restorationId;

  // ─── Search ────────────────────────────────────────────────

  final bool showSearchBar;
  final String? searchHint;

  /// Builds the search field instead of the module's own bar.
  ///
  /// The module's own bar is deliberately bare — a primitive may not
  /// import `shared/common/`, so it cannot reach `SearchTextField` and
  /// its debounce, recents and scopes. Pass one through this slot to
  /// get them. Same seam as `GlobalList.searchField`.
  final Widget Function(BuildContext, TextEditingController)? searchField;
  final bool Function(T item, String query)? searchPredicate;

  // ─── Selection ─────────────────────────────────────────────

  final ListSelectionController<T>? selection;
  final List<GlobalBulkAction<T>>? bulkActions;
  final PreferredSizeWidget Function(BuildContext, ListSelectionController<T>)?
  bulkActionsBuilder;

  // ─── Keyboard / interaction ────────────────────────────────

  final bool enableKeyboardNav;
  final void Function(int index)? onItemActivate;
  final void Function(int index)? onItemVisible;
  final void Function(BuildContext, int index, Offset position)?
  onItemContextMenu;

  /// Lets the module own selection taps, including the ANCHOR that
  /// makes a range selection possible. Same contract as
  /// `GlobalList.selectOnTap`:
  ///
  /// - a plain tap toggles the tile and becomes the new anchor,
  /// - **Shift**+tap selects everything from the anchor to it,
  /// - **Ctrl / Cmd**+tap toggles WITHOUT moving the anchor,
  /// - a long-press and drag paints a range across the tiles,
  /// - and with [enableKeyboardNav], **Shift**+arrow extends — by one
  ///   tile sideways, by a whole ROW up or down, because that is what
  ///   the arrow moves in a grid.
  ///
  /// Needs a [selection]. The long-press is skipped when
  /// [onItemContextMenu] is set — one gesture cannot be two things.
  final bool selectOnTap;

  /// Rounds the BLOCK rather than each tile — see [GridStyle.unifyTiles].
  final bool? unifyTiles;

  // ─── Animated insert / remove ──────────────────────────────

  final bool animateChanges;
  final ListItemAnimation? itemAnimation;
  final Duration? animationDuration;

  // ─── Scroll-in animation (viewport entry) ──────────────────

  /// When non-null, each tile animates in the FIRST time it crosses
  /// [scrollInThreshold] of viewport visibility. Reuses the
  /// [ListItemAnimation] enum (fade/scale/slide/fadeSize).
  ///
  /// Fires per index, not per build — virtualization-aware. Drives
  /// off `VisibilityDetector` so the animation runs when the user
  /// actually sees the tile (not when it builds inside cacheExtent).
  ///
  /// Cooperates with `useReflowLayout`: reflow keeps driving position
  /// (`AnimatedPositioned`), scroll-in drives entry visibility.
  /// Off-screen tiles stay invisible until they enter the viewport.
  final ListItemAnimation? scrollInAnimation;

  /// Duration of the scroll-in animation.
  final Duration? scrollInDuration;

  /// Visible-fraction threshold (0..1) that triggers the animation.
  /// 0.1 = fire when 10% of the tile is visible.
  final double? scrollInThreshold;

  /// When `true` (default) each index animates ONCE per State
  /// lifetime — re-entering the viewport reuses the completed state.
  /// When `false`, the animation re-fires every time the tile is
  /// recycled and re-enters the viewport.
  final bool? scrollInOnce;

  /// Per-tile stagger applied when multiple tiles cross the
  /// visibility threshold near-simultaneously (e.g. a fresh row).
  /// `Duration.zero` disables — all tiles fire together.
  /// Default 50ms — gives a row cascade without feeling slow.
  /// Queue caps at ~6 steps so fast scrolling stays responsive.
  final Duration? scrollInStagger;

  /// How the stagger cascade orders claims. Default
  /// [ScrollInStaggerMode.byOrder] cascades in the order tiles
  /// cross the threshold. [ScrollInStaggerMode.byRow] groups by
  /// `index ~/ cols` so each grid row fires together with row-to-
  /// row offset — gives a wave effect.
  final ScrollInStaggerMode? scrollInStaggerMode;

  /// When `true`, slide-direction scroll-in animations flip based
  /// on the scroll direction at fire time. Scrolling forward (down
  /// in a vertical list) keeps the base direction; scrolling
  /// backward flips it (e.g. `slideFromBottom` becomes
  /// `slideFromTop`). Non-slide animations are unaffected.
  final bool scrollInDirectionAware;

  /// Fires when a tile's scroll-in animation completes. Skipped on
  /// the dedupe-skip path (already-fired indices don't replay).
  final void Function(int index)? onScrollInComplete;

  /// Drives the scroll-in animation playback. [ScrollInMode.oneShot]
  /// (default) fires once on threshold crossing. [ScrollInMode.continuous]
  /// binds the controller to `visibleFraction` so scrolling drives
  /// playback (parallax / hero feel). In continuous mode, duration,
  /// threshold, stagger, once, and direction-aware are effectively
  /// ignored — the animation tracks scroll position directly.
  final ScrollInMode? scrollInMode;

  // ─── Masonry layout ────────────────────────────────────────

  /// When non-null, switches to masonry layout: each tile has its
  /// own height computed via this callback. Forces reflow internally
  /// (column-packing algo needs absolute positioning). Tiles drop
  /// into the SHORTEST column at each step — yields Pinterest-style
  /// staggered layout.
  ///
  /// Returns the tile's height in logical pixels given the resolved
  /// `tileWidth` for the current viewport.
  ///
  /// Caller is responsible for stable heights across rebuilds. Use
  /// item content (image aspect, text length) to derive a value
  /// rather than randomness.
  final double Function(T item, double tileWidth)? tileExtentExtractor;

  // ─── Reorderable ───────────────────────────────────────────

  /// When `true`, tiles become draggable. Long-press to grab,
  /// release on another slot to swap. Requires (and force-enables)
  /// the reflow layout — drag-and-drop animation depends on the
  /// `AnimatedPositioned` machinery.
  final bool reorderable;

  /// Called when a reorder gesture completes. `from` and `to` are
  /// indices into the items list. Owner mutates its data + the grid
  /// rebuilds; reflow animates the position swap.
  final void Function(int from, int to)? onReorder;

  /// Drives the semantics of [reorderable]:
  /// * `liveInsert` (default) — fires repeatedly during drag as the
  ///   pointer crosses cell boundaries; caller does
  ///   `removeAt(from) + insert(to)` (insert-shift semantics).
  /// * `dropSwap` — fires once on drop; caller swaps the two slots
  ///   in place (replaceable-grid semantics).
  final GridReorderMode reorderMode;

  // ─── Auto-scroll + new-item FAB ───────────────────────────

  final bool autoScrollOnNewItem;
  final bool showNewItemFab;
  final Widget Function(BuildContext, int pendingCount, VoidCallback onTap)?
  newItemFabBuilder;

  /// Estimated tile extent (height) used by `scrollToItem` when items
  /// have uniform size. Approximation; for pixel-accurate jumps use
  /// `scrollToOffset` w/ a known offset.
  final double? estimatedTileExtent;

  // ─── Grouped sections ──────────────────────────────────────

  /// When supplied, items bucket into sections by the returned key.
  /// Each section renders as a header sliver + its own grid sliver.
  final Object Function(T item)? groupBy;

  /// Builds the section header for a given key + member count.
  /// Required when [groupBy] is set.
  final Widget Function(BuildContext, Object key, int count)?
  groupHeaderBuilder;

  final double? groupHeaderHeight;

  /// stack / replace / inline. See `GroupHeaderMode`.
  final GroupHeaderMode? groupHeaderMode;

  /// Override builder for the inline (non-pinned) section divider —
  /// active only when [groupHeaderMode] == `inline`. Falls back to
  /// [groupHeaderBuilder].
  final Widget Function(BuildContext, Object key, int count)?
  sectionDividerBuilder;

  /// Right-side A-Z scrubber strip (only meaningful when grouped).
  /// Drag finger over to jump to a section.
  final bool enableScrubber;

  // ─── Sticky footer ─────────────────────────────────────────

  /// Pinned at the bottom of the viewport (above pagination bar).
  /// Pinned above the tiles, inside the grid's own column — under the
  /// search bar and the bulk toolbar, above the scroll view, and it
  /// does not scroll away. Same slot as `GlobalList.stickyHeader`.
  final Widget? stickyHeader;

  final Widget? stickyFooter;

  // ─── Snap scroll ───────────────────────────────────────────

  /// When `true`, scroll snaps to multiples of [snapRowExtent].
  /// Carousel-style by row.
  final bool snap;

  /// Row extent used by snap. When null, falls back to
  /// [estimatedTileExtent] + main-axis spacing.
  final double? snapRowExtent;

  // ─── Pinch zoom ────────────────────────────────────────────

  /// When `true`, wraps the grid in a `GestureDetector` that reports
  /// pinch scale via [onPinchScale]. Caller adjusts column count
  /// (or item rendering) accordingly.
  final bool enablePinchZoom;

  /// Fired during pinch — caller drives column-count change.
  final void Function(double scale)? onPinchScale;

  // ─── Animated column-count transition ──────────────────────

  /// When `true`, items smoothly reflow to new positions when the
  /// resolved column count changes (e.g. window resize crosses a
  /// bucket boundary). Wires through the reflow layout under the
  /// hood — sets [useReflowLayout] implicitly when enabled. Uses
  /// [animationDuration] for the position interpolation.
  ///
  /// Tradeoff: same as opting in to [useReflowLayout] — loses
  /// virtualization. Prefer for grids with <200 items where smooth
  /// column transitions matter.
  ///
  /// [columnAnimDuration] is kept for API stability but ignored —
  /// position interpolation uses [animationDuration] (reflow's
  /// shared timing).
  final bool animateColumnChange;

  /// Legacy — see [animateColumnChange]. Ignored.
  final Duration? columnAnimDuration;

  /// When set, switches the underlying delegate to
  /// `SliverGridDelegateWithMaxCrossAxisExtent` — Flutter computes
  /// how many columns fit per row given this max tile width.
  /// Smoothly recomputes columns as the window resizes (no jumps at
  /// bucket boundaries). When null, uses fixed `crossAxisCount`
  /// resolved from per-bucket params / `columnsByBucket`.
  final double? tileMaxExtent;

  /// When `true`, replaces SliverGrid w/ a `Stack` + `AnimatedPositioned`
  /// layout. Stable items animate to new positions when items are
  /// inserted / removed / reordered or column count changes. Loses
  /// virtualization (all items rendered) — use for grids w/ small
  /// item counts (<200) where smooth reflow matters more than perf.
  ///
  /// **Identity matters.** Tile positions are keyed by
  /// `items[i].hashCode`. Pass a stable list (stored in state, not
  /// rebuilt each `build`) — otherwise every rebuild creates new
  /// objects, keys change, and reflow re-mounts each tile instead
  /// of animating its position.
  final bool useReflowLayout;

  @override
  State<GlobalGrid<T>> createState() => GlobalGridState<T>();
}

/// No-op controller used by [GlobalGrid.static] so the widget doesn't
/// need a null branch on every controller access.
class _NoOpGridController<T> extends GlobalListController<T> {
  _NoOpGridController()
    : super(
        fetchPage: ({page, cursor, required pageSize}) =>
            Future.value(GlobalListPage<T>(items: const [])),
      );
}

class GlobalGridState<T> extends State<GlobalGrid<T>>
        // PLURAL. The auto-scroller disposes its ticker when a drag ends
        // and makes a new one for the next drag, so the single-ticker
        // mixin threw on the SECOND press-and-hold. `GlobalListState` has
        // always used this one, for the same scroller.
        with
        TickerProviderStateMixin {
  late ScrollController _scrollCtrl;

  /// Carries a drag-paint past the tiles on screen. The SAME scroller
  /// the reflow grid uses for reorder — a drag that reaches the edge
  /// means the same thing either way.
  final DragAutoScroller _autoScroll = DragAutoScroller();
  bool _ownsScroll = false;
  bool _kickedLoad = false;

  // ─── Search ──────────────────────────────────────────────
  final TextEditingController _searchCtrl = TextEditingController();
  String _searchQuery = '';

  // ─── Pull-up ─────────────────────────────────────────────
  bool _loadOlderInFlight = false;

  // ─── Animated changes ───────────────────────────────────
  final GlobalKey<SliverAnimatedGridState> _animatedKey =
      GlobalKey<SliverAnimatedGridState>();
  List<T> _animatedSnapshot = const [];

  // ─── Auto-scroll + new-item FAB ────────────────────────
  int _lastItemCount = 0;
  int _pendingNewCount = 0;

  // ─── Visibility tracking ───────────────────────────────
  final Set<int> _seenIndices = <int>{};

  // ─── Scroll-in animation ───────────────────────────────
  // Tracks which indices have already played their scroll-in
  // animation. When `scrollInOnce` is true, indices in this set
  // skip the animator's invisible-start state.
  final Set<int> _scrollInFired = <int>{};

  // Monotonic schedule cursor for the row-stagger cascade. See
  // `ScrollInStaggerCursor` docs for queue-saturation + idle-reset.
  final ScrollInStaggerCursor _scrollInCursor = ScrollInStaggerCursor();

  /// The caller's answers, as one bag. The animator merges it over
  /// `GlobalScrollableTheme.scrollInStyle` and then the floor, so a
  /// field left unanswered here reaches the app-wide layer.
  ScrollInStyle get _scrollInStyle => ScrollInStyle(
    animation: widget.scrollInAnimation,
    duration: widget.scrollInDuration,
    threshold: widget.scrollInThreshold,
    once: widget.scrollInOnce,
    stagger: widget.scrollInStagger,
    staggerMode: widget.scrollInStaggerMode,
    mode: widget.scrollInMode,
  );

  Duration _claimScrollInSlot(int index) {
    final cols = _lastResolvedColumns ?? 1;
    // The RESOLVED stagger: reduced motion zeroes it, and a cascade
    // made instant is a delay before something appears rather than a
    // cascade.
    final style = _scrollInStyle.resolve(context);
    return _scrollInCursor.claim(
      style.stagger,
      index,
      mode: style.staggerMode,
      cols: cols,
      idleReset: style.staggerIdleReset,
      maxQueue: style.staggerMaxQueue,
    );
  }

  // Column count captured at the last layout. Used for byRow stagger
  // mode + reorderable swap math. Set by `_resolveColumns` and the
  // reflow/grid build paths.
  int? _lastResolvedColumns;

  // Scroll direction tracking (for `scrollInDirectionAware`). Updated
  // by a listener on the active scroll controller. `true` = the user
  // is scrolling toward higher offsets (down in vertical lists).
  bool _scrollingForward = true;
  double _lastScrollOffset = 0;

  void _onScrollDirectionTick() {
    final pos = _scrollCtrl.hasClients ? _scrollCtrl.offset : 0.0;
    final delta = pos - _lastScrollOffset;
    if (delta.abs() > 0.5) {
      _scrollingForward = delta > 0;
      _lastScrollOffset = pos;
    }
  }

  /// Returns the override animation to use when
  /// [GlobalGrid.scrollInDirectionAware] is enabled. Flips slide
  /// transitions to come from the leading edge of the scroll (the
  /// edge new content appears from). Returns null when no override
  /// applies (non-slide animations, or scrolling in the natural
  /// forward direction).
  ListItemAnimation? _resolveDirectionAwareAnimation() {
    if (!widget.scrollInDirectionAware) return null;
    final base = widget.scrollInAnimation;
    if (base == null) return null;
    if (!_scrollingForward) {
      // `flipped` covers the directional pair too, so a reader
      // scrolling back in Arabic gets the mirror of the mirror.
      final flipped = base.flipped;
      return flipped == base ? null : flipped;
    }
    return switch (base) {
      ListItemAnimation.slideFromBottom ||
      ListItemAnimation.slideFromTop ||
      ListItemAnimation.slideFromLeft ||
      ListItemAnimation.slideFromRight ||
      ListItemAnimation.slideFromStart ||
      ListItemAnimation.slideFromEnd => base,
      _ => null,
    };
  }

  // ─── Keyboard nav scope ───────────────────────────────
  final FocusScopeNode _focusScope = FocusScopeNode(debugLabel: 'GlobalGrid');

  // ─── Section header keys (pixel-accurate scrubber jumps) ─
  final Map<Object, GlobalKey> _sectionHeaderKeys = <Object, GlobalKey>{};

  // ─── Layout-time viewport cross-axis size ────────────────
  // Updated by LayoutBuilder around the scroll view. Used to
  // compute exact snap row extent. Null until first layout.
  double? _lastViewportCross;

  bool get _isStatic => widget._staticItems != null;

  /// Effective reflow flag — true when caller opts in directly OR
  /// when [GlobalGrid.animateColumnChange] / masonry / reorder are
  /// enabled (all three need the reflow `Stack` + `AnimatedPositioned`
  /// machinery).
  bool get _effectiveReflow =>
      widget.useReflowLayout ||
      widget.animateColumnChange ||
      widget.tileExtentExtractor != null ||
      widget.reorderable;

  @override
  void initState() {
    super.initState();
    _scrollCtrl = widget.scrollController ?? ScrollController();
    _ownsScroll = widget.scrollController == null;
    if (widget.paginationStyle == PaginationStyle.infiniteScroll) {
      _scrollCtrl.addListener(_maybeLoadMore);
    }
    widget.controller.addListener(_onControllerChange);
    widget.selection?.addListener(_onSelectionChange);
    if (widget.autoLoad && !_isStatic && !_kickedLoad) {
      _kickedLoad = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) widget.controller.load();
      });
    }
    _searchCtrl.addListener(_onSearchChange);
    if (widget.animateChanges) {
      _animatedSnapshot = List<T>.from(_currentItems);
    }
    if (widget.scrollInAnimation != null) {
      // The detector batches its reports behind a timer, and its
      // default (500ms) is far too slow for an entrance that is meant
      // to fire as the row appears.
      //
      // LOWER only, never raise. It is a global singleton: setting it
      // outright stomps whatever the app — or a test — chose, and a
      // test that deliberately puts it at zero to keep its teardown
      // clean would have it put straight back to 50ms by the next list
      // that mounts.
      ScrollInDefaults.quickenVisibilityReports();
      if (widget.scrollInDirectionAware) {
        _scrollCtrl.addListener(_onScrollDirectionTick);
      }
    }
  }

  List<T> get _currentItems =>
      _isStatic ? widget._staticItems! : widget.controller.items;

  void _onSelectionChange() {
    _safeSetState();
  }

  /// The bag, resolved.
  ///
  /// In `didChangeDependencies`, never `initState` — the palette and
  /// `MediaQuery.disableAnimationsOf` are inherited reads.
  late ResolvedGridStyle _rs;

  /// The caller's answers, as ONE bag.
  ///
  /// The flat chrome parameters are a shorthand for fields of
  /// `style.scrollable`, so they merge ON TOP of it rather than living
  /// in a second place the resolve never sees.
  GridStyle get _callerStyle => (widget.style ?? const GridStyle()).mergedWith(
    GridStyle(
      scrollable: ScrollableStyle(
        edgeFade: widget.edgeFade,
        showScrollToTop: widget.showScrollToTop,
        scrollToTopThreshold: widget.scrollToTopThreshold,
        showScrollProgress: widget.showScrollProgress,
        progressColor: widget.progressColor,
      ),
      scrollIn: _scrollInStyle,
      // EVERY flat style parameter, not just the chrome.
      groupHeaderHeight: widget.groupHeaderHeight,
      groupHeaderMode: widget.groupHeaderMode,
      itemAnimation: widget.itemAnimation,
      animationDuration: widget.animationDuration,
      columnAnimDuration: widget.columnAnimDuration,
      estimatedTileExtent: widget.estimatedTileExtent,
      unifyTiles: widget.unifyTiles,
    ),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _rs = _callerStyle.resolve(context);
  }

  @override
  void didUpdateWidget(GlobalGrid<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    _rs = _callerStyle.resolve(context);
    if (widget.scrollController != oldWidget.scrollController) {
      oldWidget.controller.removeListener(_onControllerChange);
      if (_ownsScroll) _scrollCtrl.dispose();
      _scrollCtrl = widget.scrollController ?? ScrollController();
      _ownsScroll = widget.scrollController == null;
      if (widget.paginationStyle == PaginationStyle.infiniteScroll) {
        _scrollCtrl.addListener(_maybeLoadMore);
      }
      widget.controller.addListener(_onControllerChange);
    }
  }

  @override
  void dispose() {
    _autoScroll.stop();
    _scrollCtrl.removeListener(_maybeLoadMore);
    _scrollCtrl.removeListener(_onScrollDirectionTick);
    widget.controller.removeListener(_onControllerChange);
    widget.selection?.removeListener(_onSelectionChange);
    _searchCtrl
      ..removeListener(_onSearchChange)
      ..dispose();
    _focusScope.dispose();
    if (_ownsScroll) _scrollCtrl.dispose();
    super.dispose();
  }

  void _onControllerChange() {
    if (widget.animateChanges && !_isStatic) {
      _diffAndAnimate(widget.controller.items);
    }
    _maybeAutoScroll(widget.controller.items.length);
    _safeSetState();
  }

  /// Diffs `_animatedSnapshot` against `next` and drives the
  /// `SliverAnimatedGridState` so insertions / removals animate.
  /// Deferred to a post-frame callback so the rebuild caused by the
  /// controller's notify completes first — that way the new widget's
  /// itemBuilder closure (w/ the LATEST items list) is in place
  /// when the animation begins.
  void _diffAndAnimate(List<T> next) {
    final captured = List<T>.from(next);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final state = _animatedKey.currentState;
      if (state == null) {
        _animatedSnapshot = captured;
        return;
      }
      final nextSet = captured.toSet();
      final oldSet = _animatedSnapshot.toSet();
      for (var i = _animatedSnapshot.length - 1; i >= 0; i--) {
        final item = _animatedSnapshot[i];
        if (!nextSet.contains(item)) {
          state.removeItem(
            i,
            (ctx, anim) => _wrapItemTransition(
              ctx,
              widget.itemBuilder(ctx, item, i),
              anim,
            ),
            duration: _rs.animationDuration,
          );
        }
      }
      for (var i = 0; i < captured.length; i++) {
        if (!oldSet.contains(captured[i])) {
          state.insertItem(i, duration: _rs.animationDuration);
        }
      }
      _animatedSnapshot = captured;
    });
  }

  /// Tracks item-count delta. Drives `autoScrollOnNewItem` (animate
  /// to bottom when user is near end) + `showNewItemFab` (increments
  /// pending count when user is scrolled away).
  void _maybeAutoScroll(int newCount) {
    final added = newCount > _lastItemCount;
    final delta = newCount - _lastItemCount;
    _lastItemCount = newCount;
    if (!added || !_scrollCtrl.hasClients) return;
    final pos = _scrollCtrl.position;
    final atEnd = pos.maxScrollExtent - pos.pixels < 120;
    if (widget.autoScrollOnNewItem && atEnd) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || !_scrollCtrl.hasClients) return;
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 240),
          curve: Curves.easeOutCubic,
        );
      });
    }
    if (widget.showNewItemFab && !atEnd) {
      _pendingNewCount += delta;
    }
  }

  Future<void> _jumpToNewest() async {
    _pendingNewCount = 0;
    if (mounted) setState(() {});
    if (!_scrollCtrl.hasClients) return;
    await _scrollCtrl.animateTo(
      _scrollCtrl.position.maxScrollExtent,
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutCubic,
    );
  }

  void _onSearchChange() {
    final next = _searchCtrl.text;
    if (next != _searchQuery) {
      setState(() => _searchQuery = next);
    }
  }

  void _safeSetState() {
    if (!mounted) return;
    final phase = SchedulerBinding.instance.schedulerPhase;
    if (phase == SchedulerPhase.idle ||
        phase == SchedulerPhase.postFrameCallbacks) {
      setState(() {});
      return;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() {});
    });
  }

  void _maybeLoadMore() {
    if (!_scrollCtrl.hasClients) return;
    final pos = _scrollCtrl.position;
    if (pos.maxScrollExtent <= 0) return;
    final progress = pos.pixels / pos.maxScrollExtent;
    if (progress >= _rs.infiniteScrollThreshold) {
      Future.microtask(widget.controller.loadMore);
    }
  }

  /// Filter items via [searchPredicate] when search bar is on +
  /// query is non-empty.
  List<T> _filterItems(List<T> items) {
    if (!widget.showSearchBar ||
        widget.searchPredicate == null ||
        _searchQuery.isEmpty) {
      return items;
    }
    return items
        .where((it) => widget.searchPredicate!(it, _searchQuery))
        .toList();
  }

  /// Resolved column count for the current `WindowSizeClass`.
  int _resolveColumns() {
    final rv =
        widget.columnsByBucket ??
        ResponsiveValue<int>(
          compact: widget.compactColumns,
          medium: widget.mediumColumns,
          expanded: widget.expandedColumns,
          large: widget.largeColumns,
          extraLarge: widget.extraLargeColumns,
        );
    final cols = rv.resolve(context);
    _lastResolvedColumns = cols;
    return cols;
  }

  @override
  Widget build(BuildContext context) {
    if (_isStatic) {
      var staticContent = _maybeWrapScrubber(
        context,
        _maybeWrapChrome(_buildStatic(context)),
      );
      final staticToolbar = _buildBulkToolbar(context);
      final staticSearch = _buildSearchBar(context);
      if (staticToolbar != null ||
          staticSearch != null ||
          widget.stickyHeader != null ||
          widget.stickyFooter != null) {
        staticContent = Column(
          children: [
            if (staticToolbar != null) staticToolbar,
            if (staticSearch != null) staticSearch,
            if (widget.stickyHeader != null) widget.stickyHeader!,
            Expanded(child: staticContent),
            if (widget.stickyFooter != null) widget.stickyFooter!,
          ],
        );
      }
      return _maybeWrapPinch(_maybeWrapKeyboardScope(staticContent));
    }

    final ctrl = widget.controller;
    final phase = ctrl.phase;

    var content = _buildScrollView(context, ctrl, phase);

    if (widget.onRefresh != null && widget.scrollDirection == Axis.vertical) {
      // Through the MODULE — see `GlobalList`'s note. Two collections
      // with two different pull-to-refreshes is exactly the drift the
      // shared scrubber was extracted to stop.
      content = GlobalRefreshable(
        onRefresh: widget.onRefresh!,
        controller: widget.refreshController,
        style: RefreshableStyle(color: _callerStyle.loadingIndicatorColor),
        child: content,
      );
    }

    content = _maybeWrapChrome(content);

    content = _maybeWrapScrubber(context, content);

    final bulkToolbar = _buildBulkToolbar(context);
    final searchBar = _buildSearchBar(context);
    final paginationBar = _buildPaginationBar(context, ctrl);
    if (bulkToolbar != null ||
        searchBar != null ||
        paginationBar != null ||
        widget.stickyHeader != null ||
        widget.stickyFooter != null) {
      content = Column(
        children: [
          if (bulkToolbar != null) bulkToolbar,
          if (searchBar != null) searchBar,
          if (widget.stickyHeader != null) widget.stickyHeader!,
          Expanded(child: content),
          if (widget.stickyFooter != null) widget.stickyFooter!,
          if (paginationBar != null) paginationBar,
        ],
      );
    }
    return _maybeWrapPinch(_maybeWrapKeyboardScope(content));
  }

  /// Wraps `child` in pull-up notifier + edge fade + scroll
  /// overlays + scope-aware physics inheritance.
  Widget _maybeWrapChrome(Widget child) {
    var content = child;
    // Edge fade hugs the scrollable.
    if (!_rs.scrollable.edgeFade.isOff) {
      content = GlobalEdgeFade(
        controller: _scrollCtrl,
        style: _callerStyle.scrollable?.edgeFade,
        axis: widget.scrollDirection,
        child: content,
      );
    }
    // Scroll-to-top FAB + progress strip on top.
    final needsNewFab =
        widget.showNewItemFab && widget.scrollDirection == Axis.vertical;
    final needsFab =
        _rs.scrollable.showScrollToTop &&
        widget.scrollDirection == Axis.vertical;
    if (needsFab || _rs.scrollable.showScrollProgress || needsNewFab) {
      content = GlobalScrollOverlays(
        controller: _scrollCtrl,
        axis: widget.scrollDirection,
        style: (_callerStyle.scrollable ?? const ScrollableStyle()).copyWith(
          // The AXIS has the last word: a scroll-to-top button on a
          // horizontal strip points the wrong way.
          showScrollToTop: needsFab,
        ),
        scrollToTopBuilder: widget.scrollToTopBuilder,
        newItemPendingCount: needsNewFab ? _pendingNewCount : 0,
        newItemFabBuilder: widget.newItemFabBuilder,
        onNewItemTap: needsNewFab ? _jumpToNewest : null,
        onReachedEnd: needsNewFab
            ? () {
                if (_pendingNewCount != 0) setState(() => _pendingNewCount = 0);
              }
            : null,
        child: content,
      );
    }
    // Pull-up to load older — listens for pixels > max + threshold.
    if (widget.onLoadOlder != null && widget.scrollDirection == Axis.vertical) {
      content = NotificationListener<ScrollNotification>(
        onNotification: (n) {
          final overshoot = n.metrics.pixels - n.metrics.maxScrollExtent;
          if (overshoot > _rs.loadOlderThreshold &&
              !_loadOlderInFlight &&
              n.metrics.maxScrollExtent > 0) {
            _loadOlderInFlight = true;
            widget.onLoadOlder!().whenComplete(() {
              if (mounted) _loadOlderInFlight = false;
            });
          }
          return false;
        },
        child: content,
      );
    }
    return content;
  }

  /// Effective scroll physics — switches to clamping when nested
  /// under a pass-through `GlobalScrollable` so overscroll bubbles
  /// up. Otherwise honors caller / falls back to platform default.
  ScrollPhysics? get _effectivePhysics {
    if (widget.snap) {
      // If caller passed an explicit `snapRowExtent`, use it.
      // Otherwise compute at layout time via `_computeSnapRowExtent`.
      final rowExtent =
          widget.snapRowExtent ??
          _computeSnapRowExtent() ??
          (_rs.estimatedTileExtent + _rs.mainAxisSpacing);
      return _GridSnapPhysics(rowExtent: rowExtent);
    }
    if (widget.physics != null) return widget.physics;
    if (GlobalScrollableScope.maybeOf(context)?.passThroughActive == true) {
      return const ClampingScrollPhysics(
        parent: AlwaysScrollableScrollPhysics(),
      );
    }
    if (widget.onLoadOlder != null) {
      return const BouncingScrollPhysics(
        parent: AlwaysScrollableScrollPhysics(),
      );
    }
    return null;
  }

  /// Computes the actual row extent from the resolved column count +
  /// aspect ratio + viewport width. Returns null if viewport isn't
  /// laid out yet.
  ///
  /// row height = tile width / aspect ratio + main spacing
  /// tile width = (viewport - h-padding - (cols-1)*cross spacing) / cols
  double? _computeSnapRowExtent() {
    final viewportCross = _lastViewportCross;
    if (viewportCross == null || viewportCross <= 0) return null;
    final padding = (_rs.padding ?? EdgeInsets.zero).resolve(
      Directionality.of(context),
    );
    final hPad = padding.left + padding.right;
    final cross = _rs.crossAxisSpacing;
    final main = _rs.mainAxisSpacing;
    final cols = _resolveColumns();
    if (cols <= 0) return null;
    final tileWidth = (viewportCross - hPad - (cols - 1) * cross) / cols;
    if (tileWidth <= 0) return null;
    final tileHeight = tileWidth / _rs.aspectRatio;
    return tileHeight + main;
  }

  Key? get _storageKey => widget.restorationId == null
      ? null
      : PageStorageKey<String>(widget.restorationId!);

  // ─── Static-mode branch ────────────────────────────────────

  Widget _buildStatic(BuildContext context) {
    final items = _filterItems(widget._staticItems!);
    _renderedItems = items;
    final padding = _rs.padding ?? EdgeInsets.zero;
    if (_effectiveReflow) return _buildReflowScrollView(context, items);
    final grouped = widget.groupBy != null && widget.groupHeaderBuilder != null;
    final itemSlivers = grouped
        ? _buildGroupedSlivers(context, items, padding)
        : [SliverPadding(padding: padding, sliver: _buildGridSliver(items))];
    return _maybeCaptureViewport(
      () => CustomScrollView(
        key: _storageKey,
        scrollDirection: widget.scrollDirection,
        reverse: widget.reverse,
        physics: _effectivePhysics,
        primary: widget.primary,
        shrinkWrap: widget.shrinkWrap,
        scrollCacheExtent: widget.cacheExtent == null
            ? null
            : ScrollCacheExtent.pixels(widget.cacheExtent!),
        controller: _scrollCtrl,
        slivers: [
          ...widget.headerSlivers,
          ...itemSlivers,
          if (widget.footerBuilder != null)
            SliverToBoxAdapter(child: widget.footerBuilder!(context)),
        ],
      ),
    );
  }

  /// When snap or the scrubber is on, wraps the scrollable in a
  /// `LayoutBuilder` so the actual viewport cross-axis size is known
  /// before physics is resolved. The builder is called synchronously
  /// each layout — we set `_lastViewportCross` BEFORE invoking
  /// `builder` so the nested CustomScrollView reads physics from
  /// `_effectivePhysics` w/ the correct value on the FIRST build (no
  /// postFrame defer, no extra rebuild needed).
  ///
  /// The scrubber needs the same number: a section it cannot see has
  /// to be counted in rows, and a row's height comes from the tile
  /// width, which comes from here.
  Widget _maybeCaptureViewport(Widget Function() builder) {
    final needSnap = widget.snap && widget.snapRowExtent == null;
    final needScrubber = widget.enableScrubber && widget.groupBy != null;
    if (!needSnap && !needScrubber) return builder();
    return LayoutBuilder(
      builder: (ctx, c) {
        _lastViewportCross = widget.scrollDirection == Axis.vertical
            ? c.maxWidth
            : c.maxHeight;
        return builder();
      },
    );
  }

  // ─── Async-mode scroll view ────────────────────────────────

  Widget _buildScrollView(
    BuildContext context,
    GlobalListController<T> ctrl,
    GlobalListPhase phase,
  ) {
    if (phase == GlobalListPhase.initial) {
      return _wrapInScrollView(_buildInitialLoading(context));
    }
    if (phase == GlobalListPhase.error && ctrl.items.isEmpty) {
      return _wrapInScrollView(_buildError(context, ctrl.error!, ctrl.retry));
    }
    if (phase == GlobalListPhase.empty) {
      return _wrapInScrollView(_buildEmpty(context));
    }

    final items = _filterItems(ctrl.items);
    _renderedItems = items;
    final padding = _rs.padding ?? EdgeInsets.zero;
    if (_effectiveReflow) return _buildReflowScrollView(context, items);
    final grouped =
        widget.groupBy != null &&
        widget.groupHeaderBuilder != null &&
        !widget.animateChanges;
    final itemSlivers = grouped
        ? _buildGroupedSlivers(context, items, padding)
        : [SliverPadding(padding: padding, sliver: _buildGridSliver(items))];
    return _maybeCaptureViewport(
      () => CustomScrollView(
        key: _storageKey,
        scrollDirection: widget.scrollDirection,
        reverse: widget.reverse,
        physics: _effectivePhysics,
        primary: widget.primary,
        shrinkWrap: widget.shrinkWrap,
        scrollCacheExtent: widget.cacheExtent == null
            ? null
            : ScrollCacheExtent.pixels(widget.cacheExtent!),
        controller: _scrollCtrl,
        slivers: [
          ...widget.headerSlivers,
          ...itemSlivers,
          SliverToBoxAdapter(child: _buildPaginationTail(context, ctrl)),
          if (widget.footerBuilder != null)
            SliverToBoxAdapter(child: widget.footerBuilder!(context)),
        ],
      ),
    );
  }

  /// Reflow-layout scroll view — `Stack` + `AnimatedPositioned`
  /// per tile inside a `SingleChildScrollView`. Stable items animate
  /// to new positions when items shift / column count changes / etc.
  /// No virtualization (all tiles rendered) — for grids w/ small
  /// item counts where smooth reflow matters.
  Widget _buildReflowScrollView(BuildContext context, List<T> items) {
    final padding = _rs.padding ?? EdgeInsets.zero;
    final useMaxExtent = widget.tileMaxExtent != null;
    return SingleChildScrollView(
      key: _storageKey,
      controller: _scrollCtrl,
      scrollDirection: widget.scrollDirection,
      reverse: widget.reverse,
      physics: _effectivePhysics,
      primary: widget.primary,
      padding: padding,
      child: LayoutBuilder(
        builder: (ctx, c) {
          final cols = useMaxExtent
              ? (c.maxWidth / widget.tileMaxExtent!).floor().clamp(1, 1024)
              : _resolveColumns();
          _lastResolvedColumns = cols;
          return _ReflowGrid<T>(
            items: items,
            columns: cols,
            aspectRatio: _rs.aspectRatio,
            spacing: _rs.crossAxisSpacing,
            crossSpacing: _rs.crossAxisSpacing,
            mainSpacing: _rs.mainAxisSpacing,
            duration: _rs.animationDuration,
            enterAnimation: _rs.itemAnimation,
            scrollDirection: widget.scrollDirection,
            // When scroll-in is active, _wrapItem already adds the
            // entry animation via _ScrollInAnimator — skip the
            // built-in reflow enter wrapper to avoid double-animating.
            skipEnterWrapper: widget.scrollInAnimation != null,
            tileExtentExtractor: widget.tileExtentExtractor,
            reorderable: widget.reorderable,
            onReorder: widget.onReorder,
            reorderMode: widget.reorderMode,
            // Only the masonry path: uniform reflow is a rectangle, and
            // `cornersFor` already reads it correctly.
            unifyTiles: _rs.unifyTiles && _masonry,
            tileRadius: _rs.tileRadius,
            dropTopCorners:
                widget.groupBy != null && widget.groupHeaderBuilder != null,
            itemBuilder: (innerCtx, i) => _wrapItem(
              innerCtx,
              widget.itemBuilder(innerCtx, items[i], i),
              i,
            ),
          );
        },
      ),
    );
  }

  /// Renders the empty / loading / error widget centered in the
  /// available space. We DON'T wrap in `CustomScrollView` here:
  /// `SliverFillRemaining(hasScrollBody: false)` crashes any time
  /// an ancestor queries intrinsic dimensions (common when nested
  /// in `Column(mainAxisSize.min)` or shrink-wrapped lists).
  /// Tradeoff: pull-to-refresh on empty states no longer works.
  /// Caller can swipe-to-retry once items exist.
  Widget _wrapInScrollView(Widget centerChild) {
    if (widget.headerSlivers.isEmpty) {
      return Center(child: centerChild);
    }
    // Headers exist — keep the sliver structure but use a
    // box-sized adapter w/ a SizedBox set to a sane min height
    // so the centered widget gets vertical room.
    return CustomScrollView(
      scrollDirection: widget.scrollDirection,
      reverse: widget.reverse,
      physics: _effectivePhysics,
      primary: widget.primary,
      shrinkWrap: widget.shrinkWrap,
      scrollCacheExtent: widget.cacheExtent == null
          ? null
          : ScrollCacheExtent.pixels(widget.cacheExtent!),
      controller: _scrollCtrl,
      slivers: [
        ...widget.headerSlivers,
        SliverToBoxAdapter(
          child: SizedBox(height: 240, child: Center(child: centerChild)),
        ),
      ],
    );
  }

  /// Aggregates per-item wrappers (keyboard focus, visibility,
  /// secondary-tap context menu).
  /// The corner the tile at [index] rounds to when the block is
  /// unified: only the four OUTSIDE corners of the grid survive.
  ///
  /// A grid has four of them where a list has two, and which tile owns
  /// which depends on the column count — so it is recomputed from the
  /// resolved columns rather than baked in anywhere.
  @visibleForTesting
  BorderRadius cornersFor(int index) {
    final radius = _rs.tileRadius;
    final columns = _resolveColumns();
    final count = _renderedItems.length;
    if (columns <= 0 || count <= 0) return BorderRadius.zero;
    // GROUPED grids have a header above every run, including the
    // first, so no tile is ever the top of the card — the same reason
    // the list drops its first row's corners when grouped.
    final grouped = widget.groupBy != null && widget.groupHeaderBuilder != null;
    final lastRowStart = ((count - 1) ~/ columns) * columns;
    final isTopStart = !grouped && index == 0;
    // The last tile OF THE FIRST ROW — which is the last tile overall
    // when everything fits on one row.
    final isTopEnd = !grouped && index == (columns - 1).clamp(0, count - 1);
    final isBottomStart = index == lastRowStart;
    final isBottomEnd = index == count - 1;
    // START and END, not left and right: the block mirrors in Arabic.
    final rtl = Directionality.of(context) == TextDirection.rtl;
    final topStart = isTopStart ? radius.topLeft : Radius.zero;
    final topEnd = isTopEnd ? radius.topRight : Radius.zero;
    final bottomStart = isBottomStart ? radius.bottomLeft : Radius.zero;
    final bottomEnd = isBottomEnd ? radius.bottomRight : Radius.zero;
    return BorderRadius.only(
      topLeft: rtl ? topEnd : topStart,
      topRight: rtl ? topStart : topEnd,
      bottomLeft: rtl ? bottomEnd : bottomStart,
      bottomRight: rtl ? bottomStart : bottomEnd,
    );
  }

  /// Masonry owns its own corner resolution — see
  /// `_ReflowGridState._maybeUnify`. Index arithmetic cannot say which
  /// tile ended a column when the packer chose the column.
  bool get _masonry => widget.tileExtentExtractor != null;

  Widget _wrapItem(BuildContext ctx, Widget child, int index) {
    var w = child;
    if (_rs.unifyTiles && !_masonry) {
      // A SCOPE, not a clip: clipping to a square rectangle removes
      // nothing, because the tile's own rounded background is already
      // inside it. The corner has to reach the container that paints
      // it.
      w = ContainerCornerScope(borderRadius: cornersFor(index), child: w);
    }
    w = _maybeWrapSelectTap(w, index);
    if (widget.onItemContextMenu != null) {
      w = GestureDetector(
        behavior: HitTestBehavior.translucent,
        onSecondaryTapDown: (d) =>
            widget.onItemContextMenu!(ctx, index, d.globalPosition),
        onLongPressStart: (d) =>
            widget.onItemContextMenu!(ctx, index, d.globalPosition),
        child: w,
      );
    }
    if (widget.onItemVisible != null) {
      w = _GridVisibilityNotifier(
        index: index,
        seen: _seenIndices,
        onVisible: widget.onItemVisible!,
        child: w,
      );
    }
    w = _maybeWrapKeyboard(w, index);
    if (widget.scrollInAnimation != null) {
      w = GlobalScrollInAnimator(
        key: ValueKey<String>('gscroll_in_${identityHashCode(this)}_$index'),
        index: index,
        fired: _scrollInFired,
        style: _scrollInStyle,
        claimStaggerDelay: _claimScrollInSlot,
        animationOverride: widget.scrollInDirectionAware
            ? _resolveDirectionAwareAnimation
            : null,
        onComplete: widget.onScrollInComplete,
        child: w,
      );
    }
    return w;
  }

  /// Wraps `child` in `FocusableActionDetector` so keyboard focus
  /// can traverse tiles. Enter / Space → [onItemActivate]. Outline
  /// renders when focused.
  ///
  /// It does NOT autofocus: a grid that takes focus the moment it is
  /// built steals it from whatever the reader was on, and every tile
  /// recycled into index 0 by scrolling took it again.

  /// Whether the MODULE turns a tap on a tile into a selection —
  /// which is what makes an otherwise inert tile worth a focus stop.
  bool get _selectionIsInteractive =>
      widget.selectOnTap &&
      widget.selection != null &&
      widget.selection!.mode != SelectionMode.none;

  /// Selects [index], the way a file manager does.
  ///
  /// [extend] and [keepAnchor] default to READING THE KEYBOARD — so a
  /// caller's own control on the tile gets Shift and Ctrl/Cmd for free
  /// and behaves like the tile it sits on.
  void selectAt(int index, {bool? extend, bool? keepAnchor}) {
    final selection = widget.selection;
    if (selection == null || selection.mode == SelectionMode.none) return;
    final items = _renderedItems;
    if (index < 0 || index >= items.length) return;
    final keys = HardwareKeyboard.instance;
    final doExtend = extend ?? keys.isShiftPressed;
    // Cmd on a Mac, Ctrl everywhere else — both, since a keyboard
    // attached to a phone can be either.
    final holdAnchor =
        keepAnchor ?? (keys.isMetaPressed || keys.isControlPressed);
    final anchor = _selectionAnchor;
    if (doExtend && anchor != null && selection.mode == SelectionMode.multi) {
      selection.selectRange(anchor, index, items);
      return;
    }
    selection.toggle(items[index]);
    if (!holdAnchor) {
      _selectionAnchor = index;
      _selectionCursor = index;
    }
  }

  /// Moves the keyboard cursor and takes the selection with it.
  ///
  /// [delta] is in TILES: the caller passes one for a sideways step
  /// and a whole row for a vertical one, because that is what the
  /// arrow moves in a grid.
  void _extendSelection(int delta) {
    final selection = widget.selection;
    if (selection == null || selection.mode != SelectionMode.multi) return;
    final items = _renderedItems;
    if (items.isEmpty) return;
    final anchor = _selectionAnchor ?? 0;
    final from = _selectionCursor ?? anchor;
    final next = (from + delta).clamp(0, items.length - 1);
    if (next == from) return;
    _selectionCursor = next;
    _selectionAnchor ??= anchor;
    selection
      ..clear()
      ..selectRange(_selectionAnchor!, next, items);
    _focusScope.focusInDirection(
      delta > 0 ? TraversalDirection.down : TraversalDirection.up,
    );
  }

  /// Turns a global position into the index of the tile under it, by
  /// hit-testing for the marker every tile carries. Arithmetic would
  /// need every tile to be the same size, which masonry is not.
  int? _tileIndexAt(Offset globalPosition) {
    final box = _tilesKey.currentContext?.findRenderObject();
    if (box is! RenderBox) return null;
    final result = BoxHitTestResult();
    box.hitTest(result, position: box.globalToLocal(globalPosition));
    for (final entry in result.path) {
      final target = entry.target;
      if (target is RenderMetaData) {
        final meta = target.metaData;
        if (meta is _TileIndex) return meta.index;
      }
    }
    return null;
  }

  /// Starts a drag-paint, and the auto-scroll that lets it reach past
  /// the tiles currently on screen.
  void _beginDragSelect(int index, Offset globalPosition) {
    final selection = widget.selection;
    if (selection == null) return;
    _dragSelectAnchor = index;
    _selectionAnchor = index;
    _selectionCursor = index;
    selection.select(_renderedItems[index]);
    if (_rs.enableHaptic) HapticFeedback.selectionClick();
    _autoScroll
      ..pointerGlobal = globalPosition
      ..onTick = () {
        final at = _autoScroll.pointerGlobal;
        if (at != null) _onDragSelectUpdate(at);
      }
      ..startWithController(this, _scrollCtrl);
  }

  /// Where the finger is now. Fed by the grid's own `Listener`, so it
  /// keeps arriving after the starting tile has scrolled away — with
  /// it the tile's recogniser goes too, and the scroller would keep
  /// the last edge position it was given for ever.
  void _onDragSelectMove(Offset globalPosition) {
    if (_dragSelectAnchor == null) return;
    _autoScroll.pointerGlobal = globalPosition;
    _onDragSelectUpdate(globalPosition);
  }

  void _onDragSelectUpdate(Offset globalPosition) {
    final anchor = _dragSelectAnchor;
    if (anchor == null) return;
    final index = _tileIndexAt(globalPosition);
    if (index == null) return;
    final selection = widget.selection;
    if (selection == null || selection.mode != SelectionMode.multi) return;
    selection.selectRange(anchor, index, _renderedItems);
  }

  void _endDragSelect() {
    if (_dragSelectAnchor == null) return;
    _dragSelectAnchor = null;
    _autoScroll
      ..onTick = null
      ..stop();
  }

  /// Gives the tile the tap and the long-press that drive selection,
  /// and marks it with its index so a drag can find it.
  Widget _maybeWrapSelectTap(Widget child, int index) {
    if (!widget.selectOnTap) return child;
    final selection = widget.selection;
    if (selection == null || selection.mode == SelectionMode.none) {
      return child;
    }
    final canDragSelect =
        widget.onItemContextMenu == null &&
        selection.mode == SelectionMode.multi;
    return MetaData(
      metaData: _TileIndex(index),
      behavior: HitTestBehavior.translucent,
      child: Builder(
        builder: (tileCtx) => GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTap: () {
            // A tap MOVES the focus, which is not stealing: the reader
            // aimed at this tile. It is also what makes Shift+arrow
            // work from there.
            Focus.maybeOf(tileCtx)?.requestFocus();
            selectAt(index);
          },
          onLongPressStart: canDragSelect
              ? (d) => _beginDragSelect(index, d.globalPosition)
              : null,
          // No move or end handler here on purpose: the GRID owns
          // both, and outlives the tile.
          onLongPressCancel: canDragSelect ? _endDragSelect : null,
          child: child,
        ),
      ),
    );
  }

  /// Scrolls a focused row into view WITHOUT moving the page.
  ///
  /// `Scrollable.ensureVisible` reveals the target in every scrollable
  /// ancestor, so focusing a row inside a list inside a page dragged
  /// the whole page to it — which is what a reader sees as the list
  /// grabbing the screen. This moves the ONE viewport the list owns.
  /// The tiles this build is showing, filtered — so a lookup by index
  /// does not re-filter the whole collection per tile.
  List<T> _renderedItems = const [];

  /// Where a range selection is measured FROM — the last tile tapped
  /// without a modifier.
  int? _selectionAnchor;

  /// Where a keyboard extension has reached, which is NOT the anchor:
  /// shift-down twice then shift-up has to shrink the range.
  int? _selectionCursor;

  /// The index a long-press-drag started on, while it is running.
  int? _dragSelectAnchor;

  /// The grid's own box, for turning a drag position into the index
  /// of the tile under it.
  final GlobalKey _tilesKey = GlobalKey(debugLabel: 'GlobalGrid tiles');

  /// Which tile is showing a focus RING — not which has focus. A tap
  /// moves focus and shows nothing; a key press lights it up.
  int? _ringIndex;

  /// The context of the tile that holds focus, so the reveal can run
  /// after the frame without capturing a stale one.
  BuildContext? _focusedRowContext;

  void _revealFocused(BuildContext rowContext) {
    if (!_scrollCtrl.hasClients) return;
    final box = rowContext.findRenderObject();
    if (box is! RenderBox || !box.attached) return;
    final viewport = RenderAbstractViewport.maybeOf(box);
    if (viewport == null) return;
    // MINIMALLY, and only when it has to. Revealing at 0.5 centred
    // every row that took focus — so tapping one near the top of the
    // list scrolled it to the middle under the finger. `0.0` and
    // `1.0` bracket the offsets at which the row is just inside the
    // top and bottom edges: anywhere between them it is already
    // visible and nothing should move.
    final atTop = viewport.getOffsetToReveal(box, 0).offset;
    final atBottom = viewport.getOffsetToReveal(box, 1).offset;
    final lo = atBottom < atTop ? atBottom : atTop;
    final hi = atBottom < atTop ? atTop : atBottom;
    final current = _scrollCtrl.offset;
    if (current >= lo && current <= hi) return;
    final target = (current < lo ? lo : hi).clamp(
      _scrollCtrl.position.minScrollExtent,
      _scrollCtrl.position.maxScrollExtent,
    );
    if ((target - current).abs() < 1) return;
    _scrollCtrl.animateTo(
      target,
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOutCubic,
    );
  }

  Widget _maybeWrapKeyboard(Widget child, int index) {
    if (!widget.enableKeyboardNav) return child;
    // A focus stop that DOES NOTHING is a trap: on the scrubber
    // demos every tile took focus and lit a ring on the way past,
    // while Enter on it did nothing at all. A row earns a stop when
    // there is something to activate — a callback, or a selection the
    // module drives.
    if (widget.onItemActivate == null && !_selectionIsInteractive) {
      return child;
    }
    return FocusableActionDetector(
      actions: <Type, Action<Intent>>{
        ActivateIntent: CallbackAction<ActivateIntent>(
          onInvoke: (_) {
            widget.onItemActivate?.call(index);
            return null;
          },
        ),
      },
      // The RING follows the highlight mode, not the focus. A tap
      // moves focus but a finger has no ring to see;
      // `hasPrimaryFocus` cannot tell a tap from a Tab, and
      // `onShowFocusHighlight` is Flutter's own answer to exactly
      // that.
      onShowFocusHighlight: (show) {
        if (_ringIndex == index && show) return;
        if (!show && _ringIndex != index) return;
        if (!mounted) return;
        setState(() => _ringIndex = show ? index : null);
      },
      onFocusChange: (has) {
        if (!has) return;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          final ctx = _focusedRowContext;
          if (ctx != null && ctx.mounted) _revealFocused(ctx);
        });
      },
      child: Builder(
        builder: (ctx) {
          final hasFocus = _ringIndex == index;
          if (Focus.of(ctx).hasPrimaryFocus) _focusedRowContext = ctx;
          // Palette, not Material's scheme: a rebrand has to move a list.
          return DecoratedBox(
            decoration: BoxDecoration(
              border: hasFocus
                  ? Border.all(color: ctx.primaryColors.primary, width: 2)
                  : null,
              borderRadius: BorderRadius.circular(8),
            ),
            child: child,
          );
        },
      ),
    );
  }

  /// Wraps content in `FocusScope` + `FocusTraversalGroup` +
  /// `Shortcuts`. Arrow keys traverse a 2-D grid: left/right by 1,
  /// up/down by N (column count) — uses
  /// `DirectionalFocusTraversalPolicyMixin` via
  /// `OrderedTraversalPolicy` plus directional intents that map to
  /// next/previous focus over the children's reading order.
  Widget _maybeWrapKeyboardScope(Widget content) {
    // The KEY goes on regardless of the keyboard: a drag-select turns
    // a position into a tile by hit-testing this box.
    content = KeyedSubtree(key: _tilesKey, child: content);
    if (widget.selectOnTap) {
      // The GRID ends the drag, and feeds it, not the tile that
      // started it: once the auto-scroll carries that tile off screen
      // the sliver disposes it and its recogniser with it.
      content = Listener(
        onPointerMove: (e) => _onDragSelectMove(e.position),
        onPointerUp: (_) => _endDragSelect(),
        onPointerCancel: (_) => _endDragSelect(),
        child: content,
      );
    }
    if (!widget.enableKeyboardNav) return content;
    return FocusScope(
      node: _focusScope,
      child: FocusTraversalGroup(
        policy: ReadingOrderTraversalPolicy(),
        child: Shortcuts(
          shortcuts: const <ShortcutActivator, Intent>{
            SingleActivator(LogicalKeyboardKey.arrowRight): NextFocusIntent(),
            SingleActivator(LogicalKeyboardKey.arrowLeft):
                PreviousFocusIntent(),
            SingleActivator(LogicalKeyboardKey.arrowDown):
                DirectionalFocusIntent(TraversalDirection.down),
            SingleActivator(LogicalKeyboardKey.arrowUp): DirectionalFocusIntent(
              TraversalDirection.up,
            ),
            // Shift+arrow EXTENDS. Sideways is one tile; up and down
            // are a whole ROW, because that is the step the plain
            // arrow takes in a grid.
            SingleActivator(LogicalKeyboardKey.arrowRight, shift: true):
                _ExtendSelectionIntent.sideways(1),
            SingleActivator(LogicalKeyboardKey.arrowLeft, shift: true):
                _ExtendSelectionIntent.sideways(-1),
            SingleActivator(LogicalKeyboardKey.arrowDown, shift: true):
                _ExtendSelectionIntent.byRow(1),
            SingleActivator(LogicalKeyboardKey.arrowUp, shift: true):
                _ExtendSelectionIntent.byRow(-1),
          },
          child: Actions(
            actions: <Type, Action<Intent>>{
              _ExtendSelectionIntent: CallbackAction<_ExtendSelectionIntent>(
                onInvoke: (intent) {
                  _extendSelection(
                    intent.rows
                        ? intent.delta * _resolveColumns()
                        : intent.delta,
                  );
                  return null;
                },
              ),
            },
            child: content,
          ),
        ),
      ),
    );
  }

  /// Move focus into the grid programmatically — useful for "focus
  /// list" buttons / command palettes.
  void focus() {
    if (!widget.enableKeyboardNav) return;
    _focusScope.requestFocus();
    _focusScope.nextFocus();
  }

  /// Wraps `child` in the configured [GlobalGrid.itemAnimation]
  /// driven by `anim`.
  Widget _wrapItemTransition(
    BuildContext ctx,
    Widget child,
    Animation<double> anim,
  ) {
    // `slideFromStart` / `slideFromEnd` follow the reader; the
    // physical members pass straight through.
    switch (_rs.itemAnimation.resolveDirection(Directionality.of(ctx))) {
      case ListItemAnimation.fadeSize:
        return SizeTransition(
          sizeFactor: anim,
          child: FadeTransition(opacity: anim, child: child),
        );
      case ListItemAnimation.slideFromStart:
      case ListItemAnimation.slideFromEnd:
      // Already mapped onto a physical side by `resolveDirection`;
      // listed so the switch stays exhaustive.
      case ListItemAnimation.slideFromLeft:
        return FadeTransition(
          opacity: anim,
          child: SlideTransition(
            position: anim.drive(
              Tween(
                begin: const Offset(-1, 0),
                end: Offset.zero,
              ).chain(CurveTween(curve: Curves.easeOutCubic)),
            ),
            child: child,
          ),
        );
      case ListItemAnimation.slideFromRight:
        return FadeTransition(
          opacity: anim,
          child: SlideTransition(
            position: anim.drive(
              Tween(
                begin: const Offset(1, 0),
                end: Offset.zero,
              ).chain(CurveTween(curve: Curves.easeOutCubic)),
            ),
            child: child,
          ),
        );
      case ListItemAnimation.slideFromBottom:
        return SlideTransition(
          position: anim.drive(
            Tween(
              begin: const Offset(0, 1),
              end: Offset.zero,
            ).chain(CurveTween(curve: Curves.easeOutCubic)),
          ),
          child: FadeTransition(opacity: anim, child: child),
        );
      case ListItemAnimation.slideFromTop:
        return SlideTransition(
          position: anim.drive(
            Tween(
              begin: const Offset(0, -1),
              end: Offset.zero,
            ).chain(CurveTween(curve: Curves.easeOutCubic)),
          ),
          child: FadeTransition(opacity: anim, child: child),
        );
      case ListItemAnimation.scale:
        return ScaleTransition(
          scale: anim.drive(CurveTween(curve: Curves.easeOutBack)),
          child: FadeTransition(opacity: anim, child: child),
        );
      case ListItemAnimation.fade:
        return FadeTransition(opacity: anim, child: child);
    }
  }

  /// Bulk-actions toolbar — collapses to zero height when selection
  /// drains. Pinned above the grid in a `Column`.
  Widget? _buildBulkToolbar(BuildContext context) {
    final selection = widget.selection;
    final actions = widget.bulkActions;
    final builder = widget.bulkActionsBuilder;
    if (selection == null) return null;
    if (builder == null && (actions == null || actions.isEmpty)) return null;
    return _GridBulkActionsCollapser<T>(
      selection: selection,
      child: builder != null
          ? builder(context, selection)
          : _GridBulkActionsToolbar<T>(selection: selection, actions: actions!),
    );
  }

  /// Builds alternating section header + section grid slivers when
  /// [groupBy] / [groupHeaderBuilder] are set. Sections preserve the
  /// order in which their keys first appear in `items`. Mode:
  /// * `stack` — pinned headers stack on top (default Flutter).
  /// * `replace` — wraps each (header, grid) in `SliverMainAxisGroup`
  ///   so the previous header scrolls off w/ its group.
  /// * `inline` — non-pinned divider sliver above each section.
  List<Widget> _buildGroupedSlivers(
    BuildContext context,
    List<T> items,
    EdgeInsetsGeometry padding,
  ) {
    final groupBy = widget.groupBy!;
    final headerBuilder = widget.groupHeaderBuilder!;
    final sections = <Object, List<int>>{};
    for (var i = 0; i < items.length; i++) {
      final key = groupBy(items[i]);
      sections.putIfAbsent(key, () => <int>[]).add(i);
    }
    _sectionHeaderKeys.removeWhere((k, _) => !sections.containsKey(k));
    final slivers = <Widget>[];
    final hPad = padding.resolve(Directionality.of(context));
    final mode = _rs.groupHeaderMode;
    sections.forEach((key, indices) {
      final headerKey = _sectionHeaderKeys.putIfAbsent(key, GlobalKey.new);
      final headerWidget = KeyedSubtree(
        key: headerKey,
        child:
            (mode == GroupHeaderMode.inline &&
                widget.sectionDividerBuilder != null)
            ? widget.sectionDividerBuilder!(context, key, indices.length)
            : headerBuilder(context, key, indices.length),
      );
      final header = mode == GroupHeaderMode.inline
          ? SliverToBoxAdapter(child: headerWidget)
          : SliverPersistentHeader(
              pinned: true,
              delegate: _GridSectionHeaderDelegate(
                height: _rs.groupHeaderHeight,
                child: headerWidget,
              ),
            );
      // Each section gets its own SliverGrid w/ the same delegate.
      final sectionItems = [for (final i in indices) items[i]];
      final sectionSliver = SliverPadding(
        padding: EdgeInsets.only(
          left: hPad.left,
          right: hPad.right,
          top: hPad.top,
          bottom: hPad.bottom,
        ),
        sliver: _buildGridSliverFromList(
          sectionItems,
          indexOffset: indices.first,
        ),
      );
      if (mode == GroupHeaderMode.replace) {
        slivers.add(SliverMainAxisGroup(slivers: [header, sectionSliver]));
      } else {
        slivers.add(header);
        slivers.add(sectionSliver);
      }
    });
    return slivers;
  }

  /// Resolves the sliver-grid delegate. Switches to
  /// `MaxCrossAxisExtent` when [tileMaxExtent] is set so column
  /// count smoothly recomputes on resize. Otherwise uses
  /// `FixedCrossAxisCount` from the resolved bucket count.
  SliverGridDelegate _resolveDelegate() {
    final cross = _rs.crossAxisSpacing;
    final main = _rs.mainAxisSpacing;
    if (widget.tileMaxExtent != null) {
      return SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: widget.tileMaxExtent!,
        crossAxisSpacing: cross,
        mainAxisSpacing: main,
        childAspectRatio: _rs.aspectRatio,
      );
    }
    return SliverGridDelegateWithFixedCrossAxisCount(
      crossAxisCount: _resolveColumns(),
      crossAxisSpacing: cross,
      mainAxisSpacing: main,
      childAspectRatio: _rs.aspectRatio,
    );
  }

  /// Build SliverGrid w/ pre-sliced section items. Uses index offset
  /// so wrappers (visibility, keyboard) report the original item
  /// position in the full list.
  Widget _buildGridSliverFromList(List<T> sectionItems, {int indexOffset = 0}) {
    final delegate = _resolveDelegate();
    return SliverGrid(
      gridDelegate: delegate,
      delegate: SliverChildBuilderDelegate(
        (ctx, i) => _wrapItem(
          ctx,
          widget.itemBuilder(ctx, sectionItems[i], indexOffset + i),
          indexOffset + i,
        ),
        childCount: sectionItems.length,
      ),
    );
  }

  /// Pixel-accurate scroll to a section header. Uses
  /// `RenderAbstractViewport.getOffsetToReveal` against THIS list's
  /// own viewport so a nested grid doesn't scroll its parent too.
  Future<void> scrollToSection(
    Object key, {
    Duration duration = const Duration(milliseconds: 320),
    Curve curve = Curves.easeOutCubic,
  }) async {
    if (!_scrollCtrl.hasClients) return;
    // A BUILT, unpinned header knows exactly where it is — better than
    // an estimate, so use it when it is there.
    //
    // It used to ONLY ask the header, and in a virtualised grid a
    // section below the fold has no render object at all, while a
    // PINNED one reports the top of the viewport (which is wherever
    // you already are). So the scrubber either did nothing or landed
    // somewhere unrelated to the letter pressed — the same bug the
    // list had, and the same fix: estimate from the index.
    final headerKey = _sectionHeaderKeys[key];
    final ctx = headerKey?.currentContext;
    final box = ctx?.findRenderObject();
    if (box is RenderBox && box.attached) {
      final viewport = RenderAbstractViewport.maybeOf(box);
      if (viewport != null && _rs.groupHeaderMode == GroupHeaderMode.inline) {
        final target = viewport.getOffsetToReveal(box, 0).offset;
        await _scrollCtrl.animateTo(
          target.clamp(0.0, _scrollCtrl.position.maxScrollExtent),
          duration: duration,
          curve: curve,
        );
        return;
      }
    }
    final estimate = _estimatedSectionOffset(key);
    if (estimate == null) return;
    await _scrollCtrl.animateTo(
      estimate.clamp(0.0, _scrollCtrl.position.maxScrollExtent),
      duration: duration,
      curve: curve,
    );
  }

  /// Where a section STARTS, counted in rows rather than measured.
  ///
  /// Walks the groups ahead of [key], charging each one its header
  /// plus however many rows its tiles fill. Returns null when the
  /// grid cannot say how tall a row is yet (before first layout).
  double? _estimatedSectionOffset(Object key) {
    final groupBy = widget.groupBy;
    if (groupBy == null) return null;
    final rowPitch = _computeSnapRowExtent();
    if (rowPitch == null) return null;
    final cols = _resolveColumns();
    if (cols <= 0) return null;
    final items = _filterItems(_currentItems);
    var offset = 0.0;
    var runKey = items.isEmpty ? null : groupBy(items.first);
    var runCount = 0;
    for (var i = 0; i <= items.length; i++) {
      final k = i < items.length ? groupBy(items[i]) : null;
      if (i == items.length || k != runKey) {
        if (runKey == key) return offset;
        offset += _rs.groupHeaderHeight;
        offset += (runCount / cols).ceil() * rowPitch;
        runKey = k;
        runCount = 0;
      }
      runCount++;
    }
    return null;
  }

  /// A-Z scrubber overlay on the edge [GridStyle.scrubberPlacement]
  /// names, when grouped + enabled.
  Widget _maybeWrapScrubber(BuildContext context, Widget child) {
    if (!widget.enableScrubber || widget.groupBy == null) return child;
    final items = _currentItems;
    if (items.isEmpty) return child;
    final keys = <Object>[];
    final seen = <Object>{};
    for (var i = 0; i < items.length; i++) {
      final k = widget.groupBy!(items[i]);
      if (seen.add(k)) keys.add(k);
    }
    // The LIST's strip, not a copy: keyboard, magnification, sampling
    // and an eager recogniser that beats the scroll view to the
    // arena. The grid's own copy had none of it.
    return scrubberOverlay(
      child: child,
      placement: _rs.scrubberPlacement,
      strip: GlobalScrubber(
        keys: keys,
        onJump: scrollToSection,
        placement: _rs.scrubberPlacement,
      ),
    );
  }

  /// Pinch-zoom wrap — reports scale to caller via [onPinchScale].
  /// Caller drives column count.
  Widget _maybeWrapPinch(Widget child) {
    if (!widget.enablePinchZoom || widget.onPinchScale == null) return child;
    return GestureDetector(
      onScaleUpdate: (d) => widget.onPinchScale!(d.scale),
      child: child,
    );
  }

  /// Builds the items sliver. Single `SliverGrid` w/ fixed
  /// cross-axis count delegate. When [animateChanges] is on, uses
  /// `SliverAnimatedGrid` driven by `_animatedKey`.
  Widget _buildGridSliver(List<T> items) {
    final delegate = _resolveDelegate();
    if (widget.animateChanges) {
      return SliverAnimatedGrid(
        key: _animatedKey,
        initialItemCount: items.length,
        gridDelegate: delegate,
        itemBuilder: (ctx, i, anim) {
          if (i >= items.length) return const SizedBox.shrink();
          return _wrapItemTransition(
            ctx,
            _wrapItem(ctx, widget.itemBuilder(ctx, items[i], i), i),
            anim,
          );
        },
      );
    }
    return SliverGrid(
      gridDelegate: delegate,
      delegate: SliverChildBuilderDelegate(
        (ctx, i) => _wrapItem(ctx, widget.itemBuilder(ctx, items[i], i), i),
        childCount: items.length,
      ),
    );
  }

  // ─── Search bar ────────────────────────────────────────────

  Widget? _buildSearchBar(BuildContext context) {
    if (!widget.showSearchBar) return null;
    // The SLOT wins — see [GlobalGrid.searchField].
    return widget.searchField?.call(context, _searchCtrl) ??
        GlobalListSearchBar(
          controller: _searchCtrl,
          hint: widget.searchHint,
        );
  }

  // ─── State widgets ─────────────────────────────────────────

  Widget _buildInitialLoading(BuildContext context) {
    if (widget.loadingBuilder != null) return widget.loadingBuilder!(context);
    final columns = _resolveColumns();
    final count = widget.skeletonCount ?? (columns * 6).clamp(6, 24);
    return _SkeletonTileGrid(
      columns: columns,
      count: count,
      itemBuilder:
          widget.skeletonBuilder ??
          (ctx, i) => _DefaultShimmerTile(aspectRatio: _rs.aspectRatio),
      aspectRatio: _rs.aspectRatio,
      crossSpacing: _rs.crossAxisSpacing,
      mainSpacing: _rs.mainAxisSpacing,
      // Match the actual grid's padding so skeleton tile sizes match
      // post-load real items.
      padding: _rs.padding ?? EdgeInsets.zero,
    );
  }

  Widget _buildEmpty(BuildContext context) {
    if (widget.emptyBuilder != null) return widget.emptyBuilder!(context);
    final action = widget.emptyAction;
    // GlobalEmptyState, not a hand-rolled Column. This was 56dp of
    // `onSurface @ 30%` against the module's 64dp of `outline @ 40%` —
    // two surfaces drawing the same "nothing here" at different sizes,
    // in different colours, off `Theme.of` rather than the palette, and
    // announcing nothing when the list emptied.
    return GlobalEmptyState(
      title: ListStrings.emptyTitle,
      icon: Icons.grid_view_rounded,
      variant: EmptyStateVariant.compact,
      primaryAction: action == null
          ? null
          : GlobalFilledButton(
              text: action.label,
              icon: action.icon ?? Icons.add_rounded,
              onPressed: action.onPressed,
            ),
    );
  }

  Widget _buildError(BuildContext context, Object error, VoidCallback retry) {
    if (widget.errorBuilder != null) {
      return widget.errorBuilder!(context, error, retry);
    }
    // Palette, not Material's scheme: a rebrand has to move a list.
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.error_outline_rounded,
            size: 48,
            color: context.statusColors.error,
          ),
          const SizedBox(height: 12),
          Text(
            CommonStrings.somethingWentWrong,
            style: TextStyle(
              color: context.textColors.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '$error',
            style: TextStyle(
              color: context.textColors.primary.withValues(alpha: 0.6),
              fontSize: 12,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: retry,
            icon: const Icon(Icons.refresh_rounded),
            label: Text(CommonStrings.retry),
          ),
        ],
      ),
    );
  }

  // ─── Pagination tail (inside scroll view) ──────────────────

  /// Skeleton row used by infinite-scroll + manual-button paginators
  /// while a fetch is in-flight. Single Row of N shimmer tiles —
  /// each `Expanded` splits the available cross-axis equally,
  /// matching `SliverGrid`'s tile-width math exactly. Inherits the
  /// grid's horizontal padding + main-axis spacing for top so it
  /// aligns w/ real items above.
  Widget _buildPaginationSkeletonRow(BuildContext context) {
    final columns = _resolveColumns();
    final gridPad = (_rs.padding ?? EdgeInsets.zero).resolve(
      Directionality.of(context),
    );
    final cross = _rs.crossAxisSpacing;
    final main = _rs.mainAxisSpacing;
    return Padding(
      padding: EdgeInsets.fromLTRB(
        gridPad.left,
        main,
        gridPad.right,
        gridPad.bottom,
      ),
      child: LayoutBuilder(
        builder: (ctx, c) {
          final tileWidth = (c.maxWidth - (columns - 1) * cross) / columns;
          final tileHeight = tileWidth / _rs.aspectRatio;
          return SizedBox(
            height: tileHeight,
            child: Row(
              children: [
                for (var i = 0; i < columns; i++) ...[
                  if (i > 0) SizedBox(width: cross),
                  Expanded(
                    child:
                        widget.skeletonBuilder?.call(context, i) ??
                        GlobalShimmer.placeholder(
                          width: double.infinity,
                          height: double.infinity,
                          borderRadius: BorderRadius.circular(12),
                        ),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildPaginationTail(
    BuildContext context,
    GlobalListController<T> ctrl,
  ) {
    if (ctrl.items.isEmpty) return const SizedBox.shrink();
    if (ctrl.error != null && ctrl.items.isNotEmpty) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Center(
          child: OutlinedButton.icon(
            onPressed: ctrl.retry,
            icon: const Icon(Icons.refresh_rounded, size: 16),
            label: Text(CommonStrings.retry),
          ),
        ),
      );
    }
    switch (widget.paginationStyle) {
      case PaginationStyle.infiniteScroll:
        if (!ctrl.hasMore) return const SizedBox.shrink();
        if (widget.loadingMoreBuilder != null) {
          return widget.loadingMoreBuilder!(context);
        }
        // Skeleton row matches grid rhythm — N shimmer tiles at the
        // current column count. Visually consistent w/ initial load.
        return _buildPaginationSkeletonRow(context);
      case PaginationStyle.manualButton:
        if (!ctrl.hasMore) return const SizedBox.shrink();
        if (ctrl.isLoadingMore) {
          return _buildPaginationSkeletonRow(context);
        }
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Center(
            child: OutlinedButton(
              onPressed: ctrl.loadMore,
              child: Text(widget.loadMoreLabel ?? ListStrings.loadMore),
            ),
          ),
        );
      case PaginationStyle.none:
      case PaginationStyle.numbered:
      case PaginationStyle.compactNumbered:
        return const SizedBox.shrink();
    }
  }

  // ─── Pagination footer bar (outside scroll view) ───────────

  Widget? _buildPaginationBar(
    BuildContext context,
    GlobalListController<T> ctrl,
  ) {
    final s = widget.paginationStyle;
    if (s != PaginationStyle.numbered && s != PaginationStyle.compactNumbered) {
      return null;
    }
    final total = ctrl.totalPages;
    if (total == null || total <= 1) return null;
    return _GridPaginationBar(
      style: s,
      currentPage: ctrl.currentPage,
      totalPages: total,
      onChanged: ctrl.goToPage,
      barStyle: _rs,
    );
  }

  // ─── Public programmatic API ──────────────────────────────

  Future<void> scrollToOffset(
    double offset, {
    Duration duration = const Duration(milliseconds: 320),
    Curve curve = Curves.easeOutCubic,
  }) async {
    if (!_scrollCtrl.hasClients) return;
    final clamped = offset.clamp(0.0, _scrollCtrl.position.maxScrollExtent);
    await _scrollCtrl.animateTo(clamped, duration: duration, curve: curve);
  }

  /// Animates to bring `index` near the leading edge of the
  /// viewport. Approximation: `row = index ~/ columns`, `offset =
  /// row * (estimatedTileExtent + spacing)`. Pixel-accurate jumps
  /// require known offsets via [scrollToOffset].
  Future<void> scrollToItem(
    int index, {
    Duration duration = const Duration(milliseconds: 320),
    Curve curve = Curves.easeOutCubic,
  }) async {
    if (!_scrollCtrl.hasClients) return;
    final columns = _resolveColumns();
    final spacing = _rs.mainAxisSpacing;
    final row = index ~/ columns;
    final offset = (row * (_rs.estimatedTileExtent + spacing)).clamp(
      0.0,
      _scrollCtrl.position.maxScrollExtent,
    );
    await _scrollCtrl.animateTo(offset, duration: duration, curve: curve);
  }

  /// Token = current scroll offset. Restore via [restoreBookmark].
  double bookmark() => _scrollCtrl.hasClients ? _scrollCtrl.position.pixels : 0;

  /// Jumps to a previously-captured bookmark token. No animation.
  void restoreBookmark(double token) {
    if (!_scrollCtrl.hasClients) return;
    final clamped = token.clamp(0.0, _scrollCtrl.position.maxScrollExtent);
    _scrollCtrl.jumpTo(clamped);
  }
}

// ───────────────────────────────────────────────────────────────
// Visibility notifier — fires onVisible once per index when the
// item mounts inside the sliver
// ───────────────────────────────────────────────────────────────

class _GridVisibilityNotifier extends StatefulWidget {
  const _GridVisibilityNotifier({
    required this.index,
    required this.seen,
    required this.onVisible,
    required this.child,
  });

  final int index;
  final Set<int> seen;
  final void Function(int) onVisible;
  final Widget child;

  @override
  State<_GridVisibilityNotifier> createState() =>
      _GridVisibilityNotifierState();
}

class _GridVisibilityNotifierState extends State<_GridVisibilityNotifier> {
  @override
  void initState() {
    super.initState();
    if (!widget.seen.contains(widget.index)) {
      widget.seen.add(widget.index);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) widget.onVisible(widget.index);
      });
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

// ───────────────────────────────────────────────────────────────
// Bulk actions toolbar (collapses w/ AnimatedSize on selection
// drain)
// ───────────────────────────────────────────────────────────────

class _GridBulkActionsCollapser<T> extends StatefulWidget {
  const _GridBulkActionsCollapser({
    required this.selection,
    required this.child,
  });
  final ListSelectionController<T> selection;
  final Widget child;

  @override
  State<_GridBulkActionsCollapser<T>> createState() =>
      _GridBulkActionsCollapserState<T>();
}

class _GridBulkActionsCollapserState<T>
    extends State<_GridBulkActionsCollapser<T>> {
  @override
  void initState() {
    super.initState();
    widget.selection.addListener(_onChange);
  }

  @override
  void didUpdateWidget(_GridBulkActionsCollapser<T> old) {
    super.didUpdateWidget(old);
    if (widget.selection != old.selection) {
      old.selection.removeListener(_onChange);
      widget.selection.addListener(_onChange);
    }
  }

  @override
  void dispose() {
    widget.selection.removeListener(_onChange);
    super.dispose();
  }

  void _onChange() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final hasSelection = widget.selection.selected.isNotEmpty;
    return AnimatedSize(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
      alignment: Alignment.bottomCenter,
      child: hasSelection ? widget.child : const SizedBox.shrink(),
    );
  }
}

class _GridBulkActionsToolbar<T> extends StatelessWidget {
  const _GridBulkActionsToolbar({
    required this.selection,
    required this.actions,
  });
  final ListSelectionController<T> selection;
  final List<GlobalBulkAction<T>> actions;

  @override
  Widget build(BuildContext context) {
    // Palette, not Material's scheme: a rebrand has to move a list.
    return Material(
      color: context.primaryColors.primary.withValues(alpha: 0.12),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          child: Row(
            children: [
              GlobalIconButton(
                iconData: Icons.close_rounded,
                tooltip: ListStrings.clearSelection,
                onPressed: selection.clear,
                style: ButtonStateStyle(
                  foregroundColor: context.textColors.primary,
                ),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  ListStrings.selectedCount(selection.selected.length),
                  style: TextStyle(
                    color: context.textColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              for (final a in actions)
                GlobalIconButton(
                  iconData: a.icon,
                  tooltip: a.label,
                  onPressed: () => a.onPressed(selection.selected.toSet()),
                  style: ButtonStateStyle(
                    foregroundColor: a.color ?? context.textColors.primary,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Skeleton placeholder grid — shown during the initial load phase
/// when no items have been fetched yet. Column-of-Rows w/ Expanded
/// children — matches `SliverGrid`'s tile-width math exactly. No
/// `GridView.builder(shrinkWrap: true)` brittle intrinsics.
class _SkeletonTileGrid extends StatelessWidget {
  const _SkeletonTileGrid({
    required this.columns,
    required this.count,
    required this.itemBuilder,
    required this.aspectRatio,
    required this.crossSpacing,
    required this.mainSpacing,
    required this.padding,
  });

  final int columns;
  final int count;
  final IndexedWidgetBuilder itemBuilder;
  final double aspectRatio;
  final double crossSpacing;
  final double mainSpacing;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final rows = (count / columns).ceil();
    // SingleChildScrollView protects against vertical overflow when
    // parent height is too small for `count` tiles. NeverScrollable —
    // user can't scroll the skeleton (no point); just clips the
    // overflow safely.
    return SingleChildScrollView(
      physics: const NeverScrollableScrollPhysics(),
      child: Padding(
        padding: padding,
        child: LayoutBuilder(
          builder: (ctx, c) {
            final width = c.maxWidth;
            final tileWidth = (width - (columns - 1) * crossSpacing) / columns;
            final tileHeight = tileWidth / aspectRatio;
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (var r = 0; r < rows; r++) ...[
                  if (r > 0) SizedBox(height: mainSpacing),
                  SizedBox(
                    height: tileHeight,
                    child: Row(
                      children: [
                        for (var col = 0; col < columns; col++) ...[
                          if (col > 0) SizedBox(width: crossSpacing),
                          Expanded(
                            child: itemBuilder(context, r * columns + col),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ],
            );
          },
        ),
      ),
    );
  }
}

/// Default skeleton tile — shimmer placeholder card. Used when no
/// `skeletonBuilder` is supplied.
class _DefaultShimmerTile extends StatelessWidget {
  const _DefaultShimmerTile({required this.aspectRatio});
  final double aspectRatio;

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: aspectRatio,
      child: GlobalShimmer.placeholder(
        width: double.infinity,
        height: double.infinity,
        // The TOKEN, not 12. A hard-coded corner on the placeholder
        // means the skeleton stops matching the tiles it stands in for
        // the moment the app rounds them differently.
        borderRadius: BorderRadius.circular(context.radii.md),
      ),
    );
  }
}

// ───────────────────────────────────────────────────────────────
// Pagination footer bar (mirrors list module)
// ───────────────────────────────────────────────────────────────

class _GridPaginationBar extends StatelessWidget {
  const _GridPaginationBar({
    required this.style,
    required this.currentPage,
    required this.totalPages,
    required this.onChanged,
    required this.barStyle,
  });

  final PaginationStyle style;
  final int currentPage;
  final int totalPages;
  final ValueChanged<int> onChanged;
  final ResolvedGridStyle barStyle;

  @override
  Widget build(BuildContext context) {
    // Palette, not Material's scheme: a rebrand has to move a list.
    final theme = Theme.of(context);
    return Material(
      color: theme.scaffoldBackgroundColor,
      // NO `SafeArea`. It used to add the device's bottom inset, which
      // is right for a bar at the true bottom of a screen and wrong
      // everywhere else — a list inside a card grew 34 points of empty
      // bar under it. Screen insets belong to the page:
      // `GlobalContainer.shell` and `GlobalScaffold` apply them.
      child: SizedBox(
        height: barStyle.paginationBarHeight,
        child: style == PaginationStyle.compactNumbered
            ? _buildCompact(context)
            : _buildNumbered(context),
      ),
    );
  }

  Widget _buildCompact(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const SizedBox(width: 12),
        GlobalIconButton(
          iconData: Icons.chevron_left_rounded,
          tooltip: ListStrings.previousPage,
          onPressed: currentPage > 1 ? () => onChanged(currentPage - 1) : null,
          enabled: currentPage > 1,
        ),
        Expanded(
          // TAPPABLE. "Page 3 of 10" was a label, so the only way to
          // reach page seven was seven presses of an arrow. It opens
          // the same menu the numbered bar's gap does — every page,
          // each one named rather than a bare digit.
          child: GlobalPopup.menu<int>(
            anchor: GlobalTextButton(
              text: ListStrings.pageOf(currentPage, totalPages),
              onPressed: null,
              enabled: true,
            ),
            items: [
              for (var p = 1; p <= totalPages; p++)
                GlobalPopupMenuItem(
                  value: p,
                  label: ListStrings.page(p),
                  enabled: p != currentPage,
                ),
            ],
            onSelected: onChanged,
            // The bar sits at the FOOT of a list, so the menu opens
            // upward — and `topCenter` keeps it under the label it
            // came from.
            options: const GlobalPopupOptions(
              placement: GlobalPopupPlacement.top,
            ),
          ),
        ),
        GlobalIconButton(
          iconData: Icons.chevron_right_rounded,
          tooltip: ListStrings.nextPage,
          onPressed: currentPage < totalPages
              ? () => onChanged(currentPage + 1)
              : null,
          enabled: currentPage < totalPages,
        ),
        const SizedBox(width: 12),
      ],
    );
  }

  static const double _kSlotWidth = 34;
  static const double _kSlotDigitWidth = 8;
  static const double _kArrowIconSize = 20;
  static const double _kGapIconSize = 16;
  static const _kPageSwitchDuration = Duration(milliseconds: 180);
  static const double _kSelectedPageScale = 1.12;

  Widget _buildNumbered(BuildContext context) {
    final slotWidth = _slotWidth;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        children: [
          GlobalIconButton(
            iconData: Icons.chevron_left_rounded,
            tooltip: ListStrings.previousPage,
            size: ButtonSize.small,
            iconSize: _kArrowIconSize,
            onPressed: currentPage > 1
                ? () => onChanged(currentPage - 1)
                : null,
            enabled: currentPage > 1,
          ),
          Expanded(
            child: LayoutBuilder(
              builder: (ctx, constraints) {
                // Floor-divide the available width by slot width so
                // pages always fit symmetrically with no scrolling.
                final maxSlots = (constraints.maxWidth / slotWidth)
                    .floor()
                    .clamp(1, totalPages);
                final slots = _computeSlots(currentPage, totalPages, maxSlots);
                // The row stays PUT and the selection moves through
                // it. Crossfading the whole run was the first attempt
                // and it read as a flash: every number left and
                // arrived at once, including the ones that had not
                // changed. Each slot is keyed by its page, so the
                // framework keeps the chips that stayed and only the
                // fill travels — which is the thing that actually
                // moved.
                return Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    for (final s in slots)
                      SizedBox(
                        // EVERY slot the same width. A chip sizes to
                        // its label, so `1` and `10` were different
                        // widths and the row jittered as the page
                        // changed.
                        key: ValueKey<String>(
                          s.isEllipsis
                              ? 'gap-${s.hiddenFrom}-${s.hiddenTo}'
                              : 'page-${s.page}',
                        ),
                        width: slotWidth,
                        child: s.isEllipsis
                            ? _ellipsisMenu(context, s)
                            : _pageButton(context, s.page!),
                      ),
                  ],
                );
              },
            ),
          ),
          GlobalIconButton(
            iconData: Icons.chevron_right_rounded,
            tooltip: ListStrings.nextPage,
            size: ButtonSize.small,
            iconSize: _kArrowIconSize,
            onPressed: currentPage < totalPages
                ? () => onChanged(currentPage + 1)
                : null,
            enabled: currentPage < totalPages,
          ),
        ],
      ),
    );
  }

  /// One slot's width, sized to the LONGEST page number the bar can
  /// show — so every chip is the same width whatever digits it holds.
  double get _slotWidth =>
      _kSlotWidth + (totalPages.toString().length - 1) * _kSlotDigitWidth;

  /// Which page numbers and gaps to render for the available slots.
  ///
  /// It grows outward from the CURRENT page: page one, the last page
  /// and the current page are always there, then the immediate
  /// neighbours, then further out until the slots run out. The
  /// neighbours matter — the old windowing could leave `1 … 4 … 10`
  /// with the current page alone between two gaps, so page five was
  /// unreachable except through the arrow.
  ///
  /// Each gap carries the run it swallowed, so a bar with two of them
  /// opens two different menus rather than the same list twice.
  List<_PageSlot> _computeSlots(int current, int total, int maxSlots) {
    if (total <= maxSlots) {
      return [for (var i = 1; i <= total; i++) _PageSlot.page(i)];
    }
    final cur = current.clamp(1, total);
    // Two gaps at most, and each costs a slot of its own.
    final budget = (maxSlots - 2).clamp(1, total);

    final show = <int>{cur};
    void offer(int page) {
      if (show.length >= budget) return;
      if (page < 1 || page > total) return;
      show.add(page);
    }

    // NEIGHBOURS before the ends. When the slots are tight, being
    // able to step to the next page matters more than seeing that
    // page one exists — the old order left `1 … 4 … 10`, where the
    // only way to reach five was the arrow.
    offer(cur - 1);
    offer(cur + 1);
    offer(1);
    offer(total);
    for (var step = 2; show.length < budget && step <= total; step++) {
      offer(cur - step);
      offer(cur + step);
    }

    final pages = show.toList()..sort();
    final out = <_PageSlot>[];
    // A gap BEFORE the first shown page, and AFTER the last. Without
    // these a tight bar rendered `2 3 4` of ten pages with no way to
    // reach anything else and nothing saying so.
    if (pages.first > 1) out.add(_PageSlot.ellipsis(1, pages.first - 1));
    for (var i = 0; i < pages.length; i++) {
      if (i > 0 && pages[i] - pages[i - 1] > 1) {
        out.add(_PageSlot.ellipsis(pages[i - 1] + 1, pages[i] - 1));
      }
      out.add(_PageSlot.page(pages[i]));
    }
    if (pages.last < total) out.add(_PageSlot.ellipsis(pages.last + 1, total));
    return out;
  }

  /// One page in the bar.
  ///
  /// A `GlobalChip`, not a hand-rolled `Material` + `InkWell` in a
  /// square: a page selector IS a choice group, and the chip is the
  /// app's control for exactly that — filled when it is the one you
  /// are on, outlined when it is not, themed either way.
  Widget _pageButton(BuildContext context, int page) {
    final selected = page == currentPage;
    // NOT centred: a chip sizes to its label, so `1` and `10` came out
    // different widths and the row jittered as the page changed. The
    // slot is tight, so the chip fills it.
    //
    // The SCALE is the page-change animation: the chip that becomes
    // the current page grows into it and the one that stops being it
    // settles back, over the same beat. Material already cross-fades
    // a chip's own fill, so the two together read as one number
    // handing the selection to another.
    return AnimatedScale(
      scale: selected ? _kSelectedPageScale : 1,
      duration: _kPageSwitchDuration,
      curve: Curves.easeOutBack,
      child: SizedBox.expand(
        child: GlobalChip(
          // The BAR's own colour, and no shadow: an unselected page is
          // part of the bar, not a card floating on it.
          style: ChipStyle(
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            shadowColor: const Color(0x00000000),
            elevation: 0,
          ),
          // Plain `ar` formats in WESTERN digits, so the bar read
          // `1 2 3` beside `١ ٢ ٣` everywhere else.
          label: AppNumbers.decimal(page),
          // A bare digit reads as a loose number in a row of numbers.
          semanticLabel: ListStrings.page(page),
          selected: selected,
          // ALWAYS a choice, even for the page you are on: passing
          // `null` there makes it a static label chip, which drops the
          // selected state a reader needs to know they have arrived.
          onSelected: (_) {
            if (!selected) onChanged(page);
          },
        ),
      ),
    );
  }

  /// The run of pages the bar could not fit.
  ///
  /// It was a bare `…` — a character that says something was
  /// swallowed and offers no way to reach it. This is the breadcrumb
  /// trail's answer: a button that opens what it hid.
  Widget _ellipsisMenu(BuildContext context, _PageSlot slot) {
    final hidden = slot.hidden.toList();
    if (hidden.isEmpty) return const SizedBox.shrink();
    // The SAME menu the compact bar's label opens — `GlobalPopup.menu`
    // sizes itself to its widest row and drives its own keyboard.
    //
    // It briefly opened a hand-placed `showAt` with a fixed width and
    // a hand-built layout instead, which is the mistake this module's
    // own docs warn about: a fixed 160 points whatever the rows need,
    // and a menu whose Enter did nothing.
    return GlobalPopup.menu<int>(
      anchor: GlobalIconButton(
        iconData: Icons.more_horiz_rounded,
        tooltip: ListStrings.morePages,
        size: ButtonSize.small,
        iconSize: _kGapIconSize,
        // The POPUP owns the tap and, since its tap trigger is a
        // focus stop, the Enter as well.
        onPressed: null,
        enabled: true,
      ),
      items: [
        for (final p in hidden)
          GlobalPopupMenuItem(value: p, label: ListStrings.page(p)),
      ],
      onSelected: onChanged,
      // The button's own tooltip already names it; a second label
      // here makes a reader hear it twice.
      // A pagination bar sits at the FOOT of a list, so its menu opens
      // upward — and `topStart` is directional, so it opens from the
      // reading-start edge in Arabic too.
      options: const GlobalPopupOptions(
        placement: GlobalPopupPlacement.topStart,
      ),
    );
  }
}

class _PageSlot {
  const _PageSlot._(this.page, this.hiddenFrom, this.hiddenTo);

  factory _PageSlot.page(int page) => _PageSlot._(page, 0, 0);

  /// A gap, carrying the run of pages it swallowed.
  ///
  /// It used to carry nothing, so a bar showing `1 … 5 6 … 10` opened
  /// the same menu of every hidden page from both gaps.
  factory _PageSlot.ellipsis(int from, int to) => _PageSlot._(null, from, to);

  final int? page;
  final int hiddenFrom;
  final int hiddenTo;

  bool get isEllipsis => page == null;

  Iterable<int> get hidden sync* {
    for (var p = hiddenFrom; p <= hiddenTo; p++) {
      yield p;
    }
  }
}

// ───────────────────────────────────────────────────────────────
// Sliver variant + helper (kept for backwards compat)
// ───────────────────────────────────────────────────────────────

/// Sliver variant of [GlobalGrid] — drop into a [CustomScrollView].
/// Lighter than [GlobalGrid]: no chrome, no async, just a responsive
/// grid sliver.
class SliverGlobalGrid extends StatelessWidget {
  const SliverGlobalGrid({
    super.key,
    required this.itemCount,
    required this.itemBuilder,
    this.columnsByBucket,
    this.compactColumns,
    this.mediumColumns,
    this.expandedColumns,
    this.largeColumns,
    this.extraLargeColumns,
    this.spacing,
    this.crossAxisSpacing,
    this.mainAxisSpacing,
    this.childAspectRatio = 1.0,
  });

  final ResponsiveValue<int>? columnsByBucket;
  final int? compactColumns;
  final int? mediumColumns;
  final int? expandedColumns;
  final int? largeColumns;
  final int? extraLargeColumns;
  final double? spacing;
  final double? crossAxisSpacing;
  final double? mainAxisSpacing;
  final double childAspectRatio;
  final int itemCount;
  final Widget Function(BuildContext context, int index) itemBuilder;

  ResponsiveValue<int> _resolveColumns() {
    if (columnsByBucket != null) return columnsByBucket!;
    return ResponsiveValue<int>(
      compact: compactColumns,
      medium: mediumColumns,
      expanded: expandedColumns,
      large: largeColumns,
      extraLarge: extraLargeColumns,
    );
  }

  @override
  Widget build(BuildContext context) {
    final columns = _resolveColumns().resolve(context);
    final defaultGap = spacing ?? context.spacing.sm;
    final cross = crossAxisSpacing ?? defaultGap;
    final main = mainAxisSpacing ?? defaultGap;
    return SliverGrid(
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: columns,
        crossAxisSpacing: cross,
        mainAxisSpacing: main,
        childAspectRatio: childAspectRatio,
      ),
      delegate: SliverChildBuilderDelegate(itemBuilder, childCount: itemCount),
    );
  }
}

/// Smaller-first column resolver — pulls a column count appropriate
/// for the active `WindowSizeClass` without instantiating a widget.
int globalColumnsFor(
  BuildContext context, {
  int? compact,
  int? medium,
  int? expanded,
  int? large,
  int? extraLarge,
}) {
  return ResponsiveValue<int>(
    compact: compact,
    medium: medium,
    expanded: expanded,
    large: large,
    extraLarge: extraLarge,
  ).resolve(context);
}

// ───────────────────────────────────────────────────────────────
// Snap physics — scroll quantises to multiples of [rowExtent]
// ───────────────────────────────────────────────────────────────

class _GridSnapPhysics extends ScrollPhysics {
  const _GridSnapPhysics({required this.rowExtent, super.parent});

  final double rowExtent;

  @override
  _GridSnapPhysics applyTo(ScrollPhysics? ancestor) {
    return _GridSnapPhysics(
      rowExtent: rowExtent,
      parent: buildParent(ancestor),
    );
  }

  double _snap(double offset, double max) {
    if (rowExtent <= 0) return offset;
    final n = (offset / rowExtent).roundToDouble();
    return (n * rowExtent).clamp(0.0, max);
  }

  @override
  Simulation? createBallisticSimulation(
    ScrollMetrics position,
    double velocity,
  ) {
    final tolerance = toleranceFor(position);
    if ((velocity.abs() < tolerance.velocity) &&
        (position.pixels - _snap(position.pixels, position.maxScrollExtent))
                .abs() <
            tolerance.distance) {
      return null;
    }
    final target = _snap(
      position.pixels + velocity * 0.1,
      position.maxScrollExtent,
    );
    if ((target - position.pixels).abs() < tolerance.distance) return null;
    return ScrollSpringSimulation(
      spring,
      position.pixels,
      target,
      velocity,
      tolerance: tolerance,
    );
  }
}

// ───────────────────────────────────────────────────────────────
// Section header delegate (sticky group headers)
// ───────────────────────────────────────────────────────────────

class _GridSectionHeaderDelegate extends SliverPersistentHeaderDelegate {
  _GridSectionHeaderDelegate({required this.height, required this.child});

  final double height;
  final Widget child;

  @override
  double get minExtent => height;

  @override
  double get maxExtent => height;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) =>
      // SIZED to the extent the delegate DECLARED. It returned the
      // caller's child as-is, so a header shorter than
      // `groupHeaderHeight` painted 32 points inside a 36-point slot
      // and the sliver asserted `layoutExtent exceeds paintExtent` —
      // a caller who built a smaller header than the style asked for
      // took the whole page down.
      SizedBox(height: height, width: double.infinity, child: child);

  @override
  bool shouldRebuild(_GridSectionHeaderDelegate old) =>
      old.height != height || old.child != child;
}

// ───────────────────────────────────────────────────────────────
// Reflow grid — Stack + AnimatedPositioned per tile
// ───────────────────────────────────────────────────────────────

/// `Stack`-based grid that animates each tile's position when items
/// shift. Used by [GlobalGrid] when `useReflowLayout: true`.
///
/// Tradeoff: NO virtualization — every item is built. Use for grids
/// w/ small item counts (<200) where smooth reflow matters more
/// than memory.
class _ReflowGrid<T> extends StatefulWidget {
  const _ReflowGrid({
    required this.items,
    required this.columns,
    required this.aspectRatio,
    required this.spacing,
    required this.duration,
    required this.itemBuilder,
    required this.enterAnimation,
    required this.skipEnterWrapper,
    required this.scrollDirection,
    this.crossSpacing,
    this.mainSpacing,
    this.tileExtentExtractor,
    this.reorderable = false,
    this.onReorder,
    this.reorderMode = GridReorderMode.liveInsert,
    this.unifyTiles = false,
    this.tileRadius = BorderRadius.zero,
    this.dropTopCorners = false,
  });

  final List<T> items;
  final int columns;
  final double aspectRatio;
  final double spacing;
  final double? crossSpacing;
  final double? mainSpacing;
  final Duration duration;
  final ListItemAnimation enterAnimation;
  final bool skipEnterWrapper;
  final Axis scrollDirection;
  final double Function(T item, double tileWidth)? tileExtentExtractor;
  final bool reorderable;
  final void Function(int from, int to)? onReorder;
  final GridReorderMode reorderMode;

  /// Round the BLOCK's four outside corners rather than every tile.
  ///
  /// Handled HERE and not by the outer state for the masonry path:
  /// which tile owns a corner is a fact about where the packing put
  /// it, and the packing only exists inside this widget's layout.
  final bool unifyTiles;
  final BorderRadius tileRadius;

  /// Grouped grids get no top corners at all — a header sits above
  /// every run, including the first.
  final bool dropTopCorners;

  final Widget Function(BuildContext, int index) itemBuilder;

  @override
  State<_ReflowGrid<T>> createState() => _ReflowGridState<T>();
}

class _ReflowGridState<T> extends State<_ReflowGrid<T>>
    with TickerProviderStateMixin {
  /// Auto-scrolls the parent Scrollable when the user drags a tile
  /// near the top/bottom edge. Driven by `_onPointerMove` updates +
  /// a Ticker started in `_beginDrag`.
  final DragAutoScroller _autoScroll = DragAutoScroller();

  /// Identity hash of the item currently being dragged. Set by
  /// `_ReorderCell` via `onDragBegin`; cleared on drag end. While
  /// non-null, the `Listener` ABOVE the stack hit-tests pointer
  /// moves against the target (post-reorder) positions and fires
  /// `onReorder` when the cursor enters a new cell.
  int? _draggingId;

  /// Index of the cell the cursor is currently over. Updated when
  /// the pointer crosses cell boundaries — gates redundant reorder
  /// fires so cells don't flicker when the cursor stands still while
  /// items animate underneath it.
  int? _lastTargetIndex;

  /// Target index captured by the dragged tile for `dropSwap` mode.
  /// Updated continuously during drag; consumed on drop.
  int? _dropSwapTarget;

  /// For `liveSwap` mode: where the dragged item STARTED. Used as
  /// the "home" slot — every swap is between [_swapOrigin] and the
  /// current hover, with the previous swap undone first. Yields
  /// "swap home with final target only" semantics; intermediate
  /// cells never accumulate moves.
  int? _swapOrigin;

  /// For `liveSwap` mode: the cell most recently hovered. Tracks
  /// the in-flight swap so we can revert it before applying the
  /// next one when the cursor moves to a different cell.
  int? _swapCurrentTarget;

  /// Cached positions from the most recent `LayoutBuilder` pass.
  /// Used by the pointer-move handler to hit-test cells against
  /// their TARGET (non-animating) rectangles — avoids the
  /// oscillation that comes from hit-testing the animating cells.
  _ReflowPositions? _positions;

  /// Width of the `Stack` the tiles are positioned in — the mirror
  /// axis for the RTL hit test.
  double _stackCrossWidth = 0;

  /// Cache of the Listener's RenderBox so each auto-scroll tick can
  /// convert the global pointer position back into local coordinates
  /// after the parent Scrollable has been scrolled programmatically.
  /// Captured in build via the Listener's context key.
  final GlobalKey _listenerKey = GlobalKey();

  void _beginDrag(int id, int sourceIndex) {
    _draggingId = id;
    _lastTargetIndex = sourceIndex;
    _dropSwapTarget = sourceIndex;
    _swapOrigin = sourceIndex;
    _swapCurrentTarget = sourceIndex;
    _autoScroll.start(this, context);
    _autoScroll.onTick = _reprocessOnScrollTick;
  }

  /// Re-runs the drag hit-test using the LAST known global pointer
  /// position. While the user holds the pointer still and the auto-
  /// scroller scrolls the viewport, pointer events DON'T fire — so
  /// hover stays stuck on the cells that scrolled away. Re-mapping
  /// global → local each tick fixes that.
  void _reprocessOnScrollTick() {
    final pointer = _autoScroll.pointerGlobal;
    if (pointer == null || _draggingId == null) return;
    final box = _listenerKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null || !box.attached) return;
    final local = box.globalToLocal(pointer);
    _processDrag(local);
  }

  void _endDrag() {
    if (widget.reorderMode == GridReorderMode.dropSwap && _draggingId != null) {
      final from = _findIndexById(_draggingId!);
      final to = _dropSwapTarget;
      if (from != null && to != null && from != to) {
        widget.onReorder?.call(from, to);
      }
    }
    _draggingId = null;
    _lastTargetIndex = null;
    _dropSwapTarget = null;
    _swapOrigin = null;
    _swapCurrentTarget = null;
    _autoScroll.stop();
  }

  @override
  void dispose() {
    _autoScroll.stop();
    super.dispose();
  }

  void _onPointerMove(PointerMoveEvent event) {
    if (_draggingId == null) return;
    _autoScroll.pointerGlobal = event.position;
    _processDrag(event.localPosition);
  }

  void _processDrag(Offset localPointer) {
    if (_draggingId == null) return;
    final positions = _positions;
    if (positions == null) return;
    final target = _hitTest(localPointer, positions);
    if (target == null || target == _lastTargetIndex) return;
    _lastTargetIndex = target;
    if (widget.reorderMode == GridReorderMode.dropSwap) {
      _dropSwapTarget = target;
      setState(() {});
      return;
    }
    if (widget.reorderMode == GridReorderMode.liveSwap) {
      final origin = _swapOrigin;
      if (origin == null) return;
      if (target == _swapCurrentTarget) return;
      if (_swapCurrentTarget != origin) {
        widget.onReorder?.call(origin, _swapCurrentTarget!);
      }
      if (target != origin) {
        widget.onReorder?.call(origin, target);
      }
      _swapCurrentTarget = target;
      return;
    }
    // liveInsert — fire once per cell crossing.
    final from = _findIndexById(_draggingId!);
    if (from == null || from == target) return;
    widget.onReorder?.call(from, target);
  }

  int? _hitTest(Offset pos, _ReflowPositions p) {
    // `lefts` is start-relative (see the AnimatedPositionedDirectional
    // in build); the pointer is physical. In Arabic a tile at start
    // `s` occupies physical `[W - s - w, W - s)`, so mirror the
    // pointer once here instead of every comparison below.
    final x = Directionality.of(context) == TextDirection.rtl
        ? _stackCrossWidth - pos.dx
        : pos.dx;
    for (var i = 0; i < p.lefts.length; i++) {
      if (x >= p.lefts[i] &&
          x < p.lefts[i] + p.widths[i] &&
          pos.dy >= p.tops[i] &&
          pos.dy < p.tops[i] + p.heights[i]) {
        return i;
      }
    }
    return null;
  }

  int? _findIndexById(int id) {
    for (var i = 0; i < widget.items.length; i++) {
      if (identityHashCode(widget.items[i]) == id) return i;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final cross = widget.crossSpacing ?? widget.spacing;
    final main = widget.mainSpacing ?? widget.spacing;
    final isVertical = widget.scrollDirection == Axis.vertical;
    // Read HERE, in this element's own build, and not inside the
    // layout callback below.
    //
    // The callback runs during LAYOUT and everything it builds belongs
    // to the `LayoutBuilder`'s own private `BuildScope`. Calling
    // `Directionality.of(context)` in there registers a dependency on
    // an element that lives OUTSIDE that scope — the read and the
    // rebuild end up in two different scopes, and a language switch is
    // precisely the moment the two disagree.
    final rtl = Directionality.of(context) == TextDirection.rtl;
    return LayoutBuilder(
      builder: (ctx, c) {
        // Cross-axis extent is bounded by the parent (width when
        // scrolling vertically, height when scrolling horizontally).
        final crossExtent = isVertical ? c.maxWidth : c.maxHeight;
        final tileCrossExtent =
            (crossExtent - (widget.columns - 1) * cross) / widget.columns;
        final positions = widget.tileExtentExtractor != null
            ? _layoutMasonry(tileCrossExtent, cross, main)
            : _layoutUniform(tileCrossExtent, cross, main, isVertical);
        _positions = positions;
        // The hit test reads PHYSICAL dx off the Listener; the layout
        // is in start-relative x. Mirroring needs the box's width.
        _stackCrossWidth = isVertical ? crossExtent : positions.totalMain;
        return SizedBox(
          // SizedBox bounds the main axis; cross is already bounded
          // by the LayoutBuilder constraints.
          width: isVertical ? null : positions.totalMain,
          height: isVertical ? positions.totalMain : null,
          child: Listener(
            key: _listenerKey,
            onPointerMove: _onPointerMove,
            child: Stack(
              children: [
                for (var i = 0; i < widget.items.length; i++)
                  // `Directional`, not the physical one: `lefts` is a
                  // START-relative coordinate. Vertical scroll puts
                  // column 0 on the right in Arabic; horizontal scroll
                  // puts item 0 at the content's right edge, which is
                  // where an RTL viewport parks scroll offset zero.
                  AnimatedPositionedDirectional(
                    key: ValueKey<int>(identityHashCode(widget.items[i])),
                    duration: widget.duration,
                    curve: Curves.easeOutCubic,
                    start: positions.lefts[i],
                    top: positions.tops[i],
                    width: positions.widths[i],
                    height: positions.heights[i],
                    child: _maybeUnify(
                      positions,
                      i,
                      rtl,
                      _wrapInteractive(
                        ctx,
                        i,
                        positions.widths[i],
                        positions.heights[i],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Rounds the four OUTSIDE corners of the block, from where the
  /// packing actually put each tile.
  ///
  /// The outer state resolves this by index — first tile, last tile of
  /// the first row, first tile of the last row, last tile — which is
  /// exactly right for a rectangular grid and wrong for a masonry one.
  /// Masonry drops each tile into the SHORTEST column, so the tile that
  /// ends a column is whichever one happened to land there. With three
  /// tiles in two columns the index rule hands BOTH bottom corners to
  /// the last tile and none to the tile that is actually sitting at the
  /// foot of the other column.
  ///
  /// Here the columns are known, so the question answers itself: the
  /// first and last tile of the START column own the start corners, the
  /// first and last of the END column own the end ones.
  Widget _maybeUnify(_ReflowPositions p, int i, bool rtl, Widget child) {
    if (!widget.unifyTiles) return child;

    // The columns that actually HAVE something in them, not 0 and
    // `columns - 1`.
    //
    // A column can be empty — fewer tiles than columns, which is the
    // ordinary state of a grid that has just loaded one row. Reading
    // the outside off the configured count then asks an empty column
    // for its first and last tile, finds none, and assigns those two
    // corners to nobody: a single tile came out rounded down its
    // leading edge and square down its trailing one, and three tiles
    // in four columns left two of them square on every side.
    var startCol = 1 << 30;
    var endCol = -1;
    for (final slot in p.slots) {
      if (slot < startCol) startCol = slot;
      if (slot > endCol) endCol = slot;
    }
    // Wrapped either way, with nothing assigned when there is nothing
    // to assign. Returning the bare child instead would change the
    // subtree's runtimeType, which makes `Widget.canUpdate` false and
    // REPLACES the whole tile element — losing its entrance animation
    // and its state for what is only a change of corner.
    final empty = endCol < 0;

    var isTopStart = false;
    var isTopEnd = false;
    var isBottomStart = false;
    var isBottomEnd = false;

    // One column owns BOTH sides of the block — a lone tile is the
    // whole of it and keeps all four corners.
    for (final col in empty ? const <int>{} : {startCol, endCol}) {
      var first = -1;
      var last = -1;
      for (var j = 0; j < p.slots.length; j++) {
        if (p.slots[j] != col) continue;
        if (first < 0) first = j;
        last = j;
      }
      if (first < 0) continue;
      if (col == startCol) {
        isTopStart = isTopStart || i == first;
        isBottomStart = isBottomStart || i == last;
      }
      if (col == endCol) {
        isTopEnd = isTopEnd || i == first;
        isBottomEnd = isBottomEnd || i == last;
      }
    }
    if (widget.dropTopCorners) {
      isTopStart = false;
      isTopEnd = false;
    }

    final r = widget.tileRadius;
    // START and END, not left and right: the block mirrors in Arabic.
    // `rtl` is passed in, read in this State's own build — see there.
    final topStart = isTopStart ? r.topLeft : Radius.zero;
    final topEnd = isTopEnd ? r.topRight : Radius.zero;
    final bottomStart = isBottomStart ? r.bottomLeft : Radius.zero;
    final bottomEnd = isBottomEnd ? r.bottomRight : Radius.zero;
    return ContainerCornerScope(
      borderRadius: BorderRadius.only(
        topLeft: rtl ? topEnd : topStart,
        topRight: rtl ? topStart : topEnd,
        bottomLeft: rtl ? bottomEnd : bottomStart,
        bottomRight: rtl ? bottomStart : bottomEnd,
      ),
      child: child,
    );
  }

  /// Uniform-height layout. `tileCrossExtent` = tile width when
  /// scrolling vertically, tile height when scrolling horizontally.
  _ReflowPositions _layoutUniform(
    double tileCrossExtent,
    double cross,
    double main,
    bool isVertical,
  ) {
    // aspectRatio = width / height. In vertical scroll, cross axis is
    // width so tileMain = tileCross / ratio. In horizontal scroll,
    // cross axis is height so tileMain (width) = tileCross * ratio.
    final tileMainExtent = isVertical
        ? tileCrossExtent / widget.aspectRatio
        : tileCrossExtent * widget.aspectRatio;
    final n = widget.items.length;
    final lefts = List<double>.filled(n, 0);
    final tops = List<double>.filled(n, 0);
    final widths = List<double>.filled(
      n,
      isVertical ? tileCrossExtent : tileMainExtent,
    );
    final heights = List<double>.filled(
      n,
      isVertical ? tileMainExtent : tileCrossExtent,
    );
    final slots = List<int>.filled(n, 0);
    for (var i = 0; i < n; i++) {
      final crossIdx = i % widget.columns;
      final mainIdx = i ~/ widget.columns;
      final crossPos = crossIdx * (tileCrossExtent + cross);
      final mainPos = mainIdx * (tileMainExtent + main);
      lefts[i] = isVertical ? crossPos : mainPos;
      tops[i] = isVertical ? mainPos : crossPos;
      slots[i] = crossIdx;
    }
    final mainSlots = (n / widget.columns).ceil();
    final totalMain = mainSlots == 0
        ? 0.0
        : mainSlots * tileMainExtent + (mainSlots - 1) * main;
    return _ReflowPositions(
      lefts: lefts,
      tops: tops,
      widths: widths,
      heights: heights,
      slots: slots,
      totalMain: totalMain,
    );
  }

  /// Masonry layout — tile-by-tile column packing on the main axis.
  /// Each tile drops into the cross-axis slot (column for vertical /
  /// row for horizontal) with the SMALLEST running main-axis length.
  /// `tileCrossExtent` is the fixed cross-axis size (tile width in
  /// vertical scroll, tile height in horizontal). `tileExtentExtractor`
  /// supplies each tile's variable main-axis size.
  _ReflowPositions _layoutMasonry(
    double tileCrossExtent,
    double cross,
    double main,
  ) {
    final isVertical = widget.scrollDirection == Axis.vertical;
    final n = widget.items.length;
    final lefts = List<double>.filled(n, 0);
    final tops = List<double>.filled(n, 0);
    final widths = List<double>.filled(n, 0);
    final heights = List<double>.filled(n, 0);
    final slotMainLengths = List<double>.filled(widget.columns, 0);
    final slots = List<int>.filled(n, 0);
    for (var i = 0; i < n; i++) {
      // Extractor receives the cross-axis extent (was named tileWidth
      // historically; here it's whichever axis is the CROSS one).
      final mainLen = widget.tileExtentExtractor!(
        widget.items[i],
        tileCrossExtent,
      );
      // Pick the slot with the smallest running length (ties →
      // leftmost / topmost).
      var slot = 0;
      var minLen = slotMainLengths[0];
      for (var s = 1; s < widget.columns; s++) {
        if (slotMainLengths[s] < minLen) {
          minLen = slotMainLengths[s];
          slot = s;
        }
      }
      final crossPos = slot * (tileCrossExtent + cross);
      final mainPos = slotMainLengths[slot];
      lefts[i] = isVertical ? crossPos : mainPos;
      tops[i] = isVertical ? mainPos : crossPos;
      widths[i] = isVertical ? tileCrossExtent : mainLen;
      heights[i] = isVertical ? mainLen : tileCrossExtent;
      slots[i] = slot;
      slotMainLengths[slot] = slotMainLengths[slot] + mainLen + main;
    }
    var totalMain = 0.0;
    for (final v in slotMainLengths) {
      if (v > totalMain) totalMain = v;
    }
    if (totalMain > 0) totalMain -= main;
    return _ReflowPositions(
      lefts: lefts,
      tops: tops,
      widths: widths,
      heights: heights,
      slots: slots,
      totalMain: totalMain,
    );
  }

  Widget _wrapInteractive(BuildContext ctx, int i, double w, double h) {
    final inner = widget.skipEnterWrapper
        ? widget.itemBuilder(ctx, i)
        : _ReflowEnterTile(
            duration: widget.duration,
            animation: widget.enterAnimation,
            child: widget.itemBuilder(ctx, i),
          );
    if (!widget.reorderable || widget.onReorder == null) return inner;
    final id = identityHashCode(widget.items[i]);
    final hovered =
        widget.reorderMode == GridReorderMode.dropSwap &&
        _draggingId != null &&
        _draggingId != id &&
        _dropSwapTarget == i;
    return _ReorderCell(
      itemId: id,
      width: w,
      height: h,
      hovered: hovered,
      onDragBegin: () => _beginDrag(id, i),
      onDragEnd: _endDrag,
      child: inner,
    );
  }
}

/// Bundle of per-tile positions computed by `_ReflowGrid` for one
/// build pass.
class _ReflowPositions {
  const _ReflowPositions({
    required this.lefts,
    required this.tops,
    required this.widths,
    required this.heights,
    required this.slots,
    required this.totalMain,
  });

  final List<double> lefts;
  final List<double> tops;
  final List<double> widths;
  final List<double> heights;

  /// Which column each tile landed in. Under masonry that is the
  /// shortest-column pick, which no index arithmetic can reproduce.
  final List<int> slots;

  /// Extent along the scroll (main) axis — height when vertical,
  /// width when horizontal.
  final double totalMain;
}

// ───────────────────────────────────────────────────────────────
// Reorderable cell — LongPressDraggable (hit-test in parent)
// ───────────────────────────────────────────────────────────────

/// Wraps a reflow tile w/ `LongPressDraggable`. Hit-testing happens
/// in the parent (`_ReflowGridState._onPointerMove`) against the
/// TARGET positions — that avoids the oscillation that comes from
/// per-cell `DragTarget`s firing as cells animate under a stationary
/// pointer.
///
/// Feedback renders the full tile w/ elevation. Source slot stays
/// empty (`childWhenDragging: SizedBox.shrink()`) — the data has
/// moved to a new slot, so the original slot is occupied by
/// whatever shifted in.
///
/// In `dropSwap` mode, the cell highlights itself when the cursor
/// hovers (parent passes `hovered: true`).
class _ReorderCell extends StatelessWidget {
  const _ReorderCell({
    required this.itemId,
    required this.width,
    required this.height,
    required this.hovered,
    required this.onDragBegin,
    required this.onDragEnd,
    required this.child,
  });

  final int itemId;
  final double width;
  final double height;

  /// True when this cell is the current drop-swap target. Renders a
  /// primary-colored border to signal the swap destination.
  final bool hovered;

  /// Called when the long-press transitions into an active drag.
  final VoidCallback onDragBegin;

  /// Called on drag end (drop OR cancel). Parent uses this to clear
  /// drag state + fire `onReorder` for `dropSwap` mode.
  final VoidCallback onDragEnd;

  final Widget child;

  @override
  Widget build(BuildContext context) {
    // Palette, not Material's scheme: a rebrand has to move a list.
    final framed = hovered
        ? DecoratedBox(
            decoration: BoxDecoration(
              border: Border.all(
                color: context.primaryColors.primary,
                width: 2,
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: child,
          )
        : child;
    return LongPressDraggable<int>(
      data: itemId,
      delay: const Duration(milliseconds: 200),
      onDragStarted: onDragBegin,
      onDragEnd: (_) => onDragEnd(),
      onDraggableCanceled: (_, _) => onDragEnd(),
      feedback: Material(
        color: Colors.transparent,
        // Elevation removed — translucent tile backgrounds leak the
        // drop shadow through the content, looking buggy. Caller's
        // tile decides its own depth treatment.
        elevation: 0,
        child: SizedBox(width: width, height: height, child: child),
      ),
      childWhenDragging: const SizedBox.shrink(),
      child: framed,
    );
  }
}

// ───────────────────────────────────────────────────────────────
// Reflow enter tile — runs entry animation ONCE on initState
// ───────────────────────────────────────────────────────────────

/// Stateful one-shot enter wrapper for reflow grid tiles. Runs the
/// configured `enterAnimation` ONCE on `initState`. Subsequent
/// rebuilds (e.g. column-count changes via tileMaxExtent or pinch)
/// don't restart the animation — the parent's `ValueKey<int>` keeps
/// our State alive across rebuilds. Tween-based approaches restart
/// every frame because Tween instances don't compare by value.
class _ReflowEnterTile extends StatefulWidget {
  const _ReflowEnterTile({
    required this.duration,
    required this.animation,
    required this.child,
  });

  final Duration duration;
  final ListItemAnimation animation;
  final Widget child;

  @override
  State<_ReflowEnterTile> createState() => _ReflowEnterTileState();
}

class _ReflowEnterTileState extends State<_ReflowEnterTile>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _curved;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: widget.duration)
      ..forward();
    _curved = CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    switch (widget.animation.resolveDirection(Directionality.of(context))) {
      case ListItemAnimation.fadeSize:
        return FadeTransition(
          opacity: _curved,
          child: ScaleTransition(scale: _curved, child: widget.child),
        );
      case ListItemAnimation.slideFromStart:
      case ListItemAnimation.slideFromEnd:
      // Already mapped onto a physical side by `resolveDirection`;
      // listed so the switch stays exhaustive.
      case ListItemAnimation.slideFromLeft:
        return FadeTransition(
          opacity: _curved,
          child: SlideTransition(
            position: _curved.drive(
              Tween(begin: const Offset(-1, 0), end: Offset.zero),
            ),
            child: widget.child,
          ),
        );
      case ListItemAnimation.slideFromRight:
        return FadeTransition(
          opacity: _curved,
          child: SlideTransition(
            position: _curved.drive(
              Tween(begin: const Offset(1, 0), end: Offset.zero),
            ),
            child: widget.child,
          ),
        );
      case ListItemAnimation.slideFromBottom:
        return FadeTransition(
          opacity: _curved,
          child: SlideTransition(
            position: _curved.drive(
              Tween(begin: const Offset(0, 1), end: Offset.zero),
            ),
            child: widget.child,
          ),
        );
      case ListItemAnimation.slideFromTop:
        return FadeTransition(
          opacity: _curved,
          child: SlideTransition(
            position: _curved.drive(
              Tween(begin: const Offset(0, -1), end: Offset.zero),
            ),
            child: widget.child,
          ),
        );
      case ListItemAnimation.scale:
        return FadeTransition(
          opacity: _curved,
          child: ScaleTransition(
            scale: _ctrl.drive(CurveTween(curve: Curves.easeOutBack)),
            child: widget.child,
          ),
        );
      case ListItemAnimation.fade:
        return FadeTransition(opacity: _curved, child: widget.child);
    }
  }
}

/// What a tile carries so a drag can ask which tile it is over.
@immutable
class _TileIndex {
  const _TileIndex(this.index);

  final int index;
}

/// Walks the keyboard cursor and drags the selection with it. Its own
/// intent so `Shortcuts` can bind Shift+arrow without shadowing the
/// plain arrow's traversal.
@immutable
class _ExtendSelectionIntent extends Intent {
  const _ExtendSelectionIntent.sideways(this.delta) : rows = false;
  const _ExtendSelectionIntent.byRow(this.delta) : rows = true;

  final int delta;

  /// Whether [delta] counts ROWS rather than tiles.
  final bool rows;
}
