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
import '../../../core/localization/strings/field_strings.dart';
import '../../../core/localization/strings/list_strings.dart';
import '../../../core/tokens/extensions.dart';
import '../buttons/global_filled_button.dart';
import '../buttons/global_icon_button.dart';
import '../buttons/global_text_button.dart';
import '../chip/global_chip.dart';
import '../container/global_container.dart';
import '../empty_state/global_empty_state.dart';
import '../popup/popup.dart';
import '../progress/global_progress.dart';
import '../refreshable/global_refreshable.dart';
import '../scrollable/global_edge_fade.dart';
import '../scrollable/global_scroll_in.dart';
import '../scrollable/global_scroll_overlays.dart';
import '../scrollable/global_scrollable.dart'
    show
        GlobalScrollableScope,
        ListItemAnimationDirection,
        ScrollInStyleResolve,
        ScrollableStyle;
import '../shimmer/global_shimmer.dart';
import '../text_field/global_text_field.dart'
    show
        GlobalTextFormField,
        TextFieldBehavior,
        TextFieldFeatures,
        TextFieldSizing,
        TextFieldSlots,
        TextFieldStyle;
import 'cross_axis_fit.dart';
import 'global_list_controller.dart';
import 'list_models.dart';
import 'list_selection_controller.dart';
import 'list_style.dart';
import 'scrubber.dart';
import 'swipe_actions.dart';
import 'theme/collection_theme.dart';

export '../scrollable/global_scroll_in.dart'
    show ScrollInMode, ScrollInStaggerMode;
export 'cross_axis_fit.dart';
export 'global_list_controller.dart';
export 'list_models.dart';
export 'list_selection_controller.dart';
export 'list_style.dart';
export 'scrubber_models.dart';
export 'swipe_actions.dart';
export 'theme/collection_theme.dart';

/// Builder that renders a single item. Mirrors [ListView.builder]'s
/// signature.
typedef GlobalListItemBuilder<T> =
    Widget Function(
      BuildContext context,
      T item,
      int index,
    );

/// Error widget builder. `retry` runs [GlobalListController.retry].
typedef GlobalListErrorBuilder =
    Widget Function(
      BuildContext context,
      Object error,
      VoidCallback retry,
    );

/// A scrollable list with built-in chrome for the common async
/// states (loading / empty / error), pull-to-refresh, and four
/// pagination strategies. Works vertically or horizontally.
///
/// Two construction modes:
///
/// * **Async / paginated** — pass a [GlobalListController] via
///   [GlobalList]. The controller owns items + fetch state; the
///   widget rebuilds on `notifyListeners`. Pagination styles are
///   honoured via [paginationStyle].
/// * **Static** — `GlobalList.static(items: [...])`. No controller,
///   no async chrome, fixed item list. Useful for embedded sub-lists.
///
/// Header content is supplied as [headerSlivers] so callers can
/// drop in `SliverPersistentHeader` for sticky headers, etc.
class GlobalList<T> extends StatefulWidget {
  const GlobalList({
    super.key,
    required this.controller,
    required this.itemBuilder,
    this.separatorBuilder,
    this.scrollDirection = Axis.vertical,
    this.reverse = false,
    this.physics,
    this.primary,
    this.shrinkWrap = false,
    this.cacheExtent,
    this.headerSlivers = const [],
    this.footerBuilder,
    this.emptyBuilder,
    this.loadingBuilder,
    this.loadingMoreBuilder,
    this.skeletonBuilder,
    this.errorBuilder,
    this.onRefresh,
    this.refreshController,
    this.paginationStyle = PaginationStyle.infiniteScroll,
    this.loadMoreLabel,
    this.style,
    this.selection,
    this.reorderable = false,
    this.scrollController,
    this.autoLoad = true,
    this.edgeFade,
    this.emptyAction,
    this.showScrollToTop,
    this.scrollToTopThreshold,
    this.scrollToTopBuilder,
    this.showScrollProgress,
    this.progressColor,
    this.restorationId,
    this.groupBy,
    this.groupHeaderBuilder,
    this.groupHeaderHeight,
    this.groupHeaderMode,
    this.bulkActions,
    this.bulkActionsBuilder,
    this.reorderMode = ReorderMode.longPressAnywhere,
    this.searchPredicate,
    this.showSearchBar = false,
    this.searchHint,
    this.searchField,
    this.unifyTiles,
    this.animateChanges = false,
    this.itemAnimation,
    this.animationDuration,
    this.enableKeyboardNav = false,
    this.onItemActivate,
    this.onLoadOlder,
    this.loadOlderThreshold,
    this.stickyHeader,
    this.stickyFooter,
    this.autoScrollOnNewItem = false,
    this.onItemVisible,
    this.enableScrubber = false,
    this.snap = false,
    this.snapItemExtent,
    this.onItemContextMenu,
    this.swipeActions,
    this.selectOnTap = false,
    this.enablePinchZoom = false,
    this.onPinchScale,
    this.estimatedItemExtent,
    this.sectionDividerBuilder,
    this.showNewItemFab = false,
    this.newItemFabBuilder,
    this.scrollInAnimation,
    this.scrollInDuration,
    this.scrollInThreshold,
    this.scrollInOnce,
    this.scrollInStagger,
    this.scrollInStaggerMode,
    this.scrollInDirectionAware = false,
    this.onScrollInComplete,
    this.scrollInMode,
    this.swapMode = false,
    this.onReorder,
    this.swapLive = false,
  }) : _staticItems = null,
       _staticReverse = false;

  /// Static (non-paginated, non-async) variant. Skips all loading /
  /// empty / pagination chrome and just renders the provided items.
  GlobalList.static({
    Key? key,
    required List<T> items,
    required GlobalListItemBuilder<T> itemBuilder,
    IndexedWidgetBuilder? separatorBuilder,
    Axis scrollDirection = Axis.vertical,
    bool reverse = false,
    ScrollPhysics? physics,
    bool? primary,
    bool shrinkWrap = false,
    double? cacheExtent,
    List<Widget> headerSlivers = const [],
    WidgetBuilder? footerBuilder,
    ListStyle? style,
    ListSelectionController<T>? selection,
    ScrollController? scrollController,
    EdgeFadeStyle? edgeFade,
    bool? showScrollToTop,
    double? scrollToTopThreshold,
    Widget Function(BuildContext, VoidCallback)? scrollToTopBuilder,
    bool? showScrollProgress,
    Color? progressColor,
    String? restorationId,
    Object Function(T item)? groupBy,
    Widget Function(BuildContext, Object key, int count)? groupHeaderBuilder,
    double? groupHeaderHeight,
    GroupHeaderMode? groupHeaderMode,
    List<GlobalBulkAction<T>>? bulkActions,
    PreferredSizeWidget Function(BuildContext, ListSelectionController<T>)?
    bulkActionsBuilder,
    bool Function(T item, String query)? searchPredicate,
    bool showSearchBar = false,
    String? searchHint,
    Widget Function(BuildContext, TextEditingController)? searchField,
    bool? unifyTiles,
    bool animateChanges = false,
    ListItemAnimation? itemAnimation,
    Duration? animationDuration,
    bool enableKeyboardNav = false,
    void Function(int index)? onItemActivate,
    Widget? stickyHeader,
    Widget? stickyFooter,
    bool autoScrollOnNewItem = false,
    void Function(int index)? onItemVisible,
    bool enableScrubber = false,
    bool snap = false,
    double? snapItemExtent,
    void Function(BuildContext, int index, Offset position)? onItemContextMenu,
    SwipeActions? Function(BuildContext, T item, int index)? swipeActions,
    bool selectOnTap = false,
    bool enablePinchZoom = false,
    void Function(double scale)? onPinchScale,
    double? estimatedItemExtent,
    Widget Function(BuildContext, Object key, int count)? sectionDividerBuilder,
    bool showNewItemFab = false,
    Widget Function(BuildContext, int pendingCount, VoidCallback onTap)?
    newItemFabBuilder,
    ListItemAnimation? scrollInAnimation,
    Duration? scrollInDuration,
    double? scrollInThreshold,
    bool? scrollInOnce,
    Duration? scrollInStagger,
    ScrollInStaggerMode? scrollInStaggerMode,
    bool scrollInDirectionAware = false,
    void Function(int index)? onScrollInComplete,
    ScrollInMode? scrollInMode,
    bool swapMode = false,
    void Function(int from, int to)? onReorder,
    bool reorderable = false,
    bool swapLive = false,
  }) : this._internal(
         key: key,
         controller: null,
         staticItems: items,
         itemBuilder: itemBuilder,
         separatorBuilder: separatorBuilder,
         scrollDirection: scrollDirection,
         reverse: reverse,
         physics: physics,
         primary: primary,
         shrinkWrap: shrinkWrap,
         cacheExtent: cacheExtent,
         headerSlivers: headerSlivers,
         footerBuilder: footerBuilder,
         style: style,
         selection: selection,
         scrollController: scrollController,
         edgeFade: edgeFade,
         showScrollToTop: showScrollToTop,
         scrollToTopThreshold: scrollToTopThreshold,
         scrollToTopBuilder: scrollToTopBuilder,
         showScrollProgress: showScrollProgress,
         progressColor: progressColor,
         restorationId: restorationId,
         groupBy: groupBy,
         groupHeaderBuilder: groupHeaderBuilder,
         groupHeaderHeight: groupHeaderHeight,
         groupHeaderMode: groupHeaderMode,
         bulkActions: bulkActions,
         bulkActionsBuilder: bulkActionsBuilder,
         searchPredicate: searchPredicate,
         showSearchBar: showSearchBar,
         searchHint: searchHint,
         searchField: searchField,
         unifyTiles: unifyTiles,
         animateChanges: animateChanges,
         itemAnimation: itemAnimation,
         animationDuration: animationDuration,
         enableKeyboardNav: enableKeyboardNav,
         onItemActivate: onItemActivate,
         stickyHeader: stickyHeader,
         stickyFooter: stickyFooter,
         autoScrollOnNewItem: autoScrollOnNewItem,
         onItemVisible: onItemVisible,
         enableScrubber: enableScrubber,
         snap: snap,
         snapItemExtent: snapItemExtent,
         onItemContextMenu: onItemContextMenu,
         swipeActions: swipeActions,
         selectOnTap: selectOnTap,
         enablePinchZoom: enablePinchZoom,
         onPinchScale: onPinchScale,
         estimatedItemExtent: estimatedItemExtent,
         sectionDividerBuilder: sectionDividerBuilder,
         showNewItemFab: showNewItemFab,
         newItemFabBuilder: newItemFabBuilder,
         scrollInAnimation: scrollInAnimation,
         scrollInDuration: scrollInDuration,
         scrollInThreshold: scrollInThreshold,
         scrollInOnce: scrollInOnce,
         scrollInStagger: scrollInStagger,
         scrollInStaggerMode: scrollInStaggerMode,
         scrollInDirectionAware: scrollInDirectionAware,
         onScrollInComplete: onScrollInComplete,
         scrollInMode: scrollInMode,
         swapMode: swapMode,
         onReorder: onReorder,
         reorderable: reorderable,
         swapLive: swapLive,
       );

  GlobalList._internal({
    super.key,
    required GlobalListController<T>? controller,
    required this.itemBuilder,
    required List<T>? staticItems,
    this.separatorBuilder,
    this.scrollDirection = Axis.vertical,
    this.reverse = false,
    this.physics,
    this.primary,
    this.shrinkWrap = false,
    this.cacheExtent,
    this.headerSlivers = const [],
    this.footerBuilder,
    this.style,
    this.selection,
    this.scrollController,
    this.edgeFade,
    this.showScrollToTop,
    this.scrollToTopThreshold,
    this.scrollToTopBuilder,
    this.showScrollProgress,
    this.progressColor,
    this.restorationId,
    this.groupBy,
    this.groupHeaderBuilder,
    this.groupHeaderHeight,
    this.groupHeaderMode,
    this.bulkActions,
    this.bulkActionsBuilder,
    this.reorderMode = ReorderMode.longPressAnywhere,
    this.searchPredicate,
    this.showSearchBar = false,
    this.searchHint,
    this.searchField,
    this.unifyTiles,
    this.animateChanges = false,
    this.itemAnimation,
    this.animationDuration,
    this.enableKeyboardNav = false,
    this.onItemActivate,
    this.onLoadOlder,
    this.loadOlderThreshold,
    this.stickyHeader,
    this.stickyFooter,
    this.autoScrollOnNewItem = false,
    this.onItemVisible,
    this.enableScrubber = false,
    this.snap = false,
    this.snapItemExtent,
    this.onItemContextMenu,
    this.swipeActions,
    this.selectOnTap = false,
    this.enablePinchZoom = false,
    this.onPinchScale,
    this.estimatedItemExtent,
    this.sectionDividerBuilder,
    this.showNewItemFab = false,
    this.newItemFabBuilder,
    this.scrollInAnimation,
    this.scrollInDuration,
    this.scrollInThreshold,
    this.scrollInOnce,
    this.scrollInStagger,
    this.scrollInStaggerMode,
    this.scrollInDirectionAware = false,
    this.onScrollInComplete,
    this.scrollInMode,
    this.swapMode = false,
    this.onReorder,
    this.reorderable = false,
    this.swapLive = false,
  }) : controller = controller ?? _NoOpController<T>(),
       _staticItems = staticItems,
       _staticReverse = reverse,
       emptyBuilder = null,
       loadingBuilder = null,
       loadingMoreBuilder = null,
       skeletonBuilder = null,
       errorBuilder = null,
       emptyAction = null,
       onRefresh = null,
       refreshController = null,
       paginationStyle = PaginationStyle.none,
       loadMoreLabel = null,
       autoLoad = false;

  /// Paginated / async controller. The widget listens for state
  /// changes via [ChangeNotifier].
  final GlobalListController<T> controller;

  final GlobalListItemBuilder<T> itemBuilder;
  final IndexedWidgetBuilder? separatorBuilder;

  // Static-mode payload — wired in by [GlobalList.static].
  final List<T>? _staticItems;
  final bool _staticReverse;

  // ─── Scroll behaviour ──────────────────────────────────────

  final Axis scrollDirection;
  final bool reverse;
  final ScrollPhysics? physics;
  final bool? primary;
  final bool shrinkWrap;
  final double? cacheExtent;
  final ScrollController? scrollController;

  // ─── Slots ────────────────────────────────────────────────

  final List<Widget> headerSlivers;
  final WidgetBuilder? footerBuilder;
  final WidgetBuilder? emptyBuilder;
  final WidgetBuilder? loadingBuilder;
  final WidgetBuilder? loadingMoreBuilder;
  final IndexedWidgetBuilder? skeletonBuilder;
  final GlobalListErrorBuilder? errorBuilder;

  // ─── Behaviour ────────────────────────────────────────────

  final RefreshCallback? onRefresh;

  /// Drives the pull-to-refresh from outside the tree — after a
  /// sign-in, from a toast's Retry, on resume. Needs [onRefresh]: a
  /// list with nothing to refresh has nothing for it to start.
  final GlobalRefreshableController? refreshController;
  final PaginationStyle paginationStyle;
  final String? loadMoreLabel;

  /// The themeable bag. Merged over
  /// `GlobalCollectionTheme.listStyle` and then `ListStyle.defaults`,
  /// so a field left unanswered here reaches the app-wide layer.
  final ListStyle? style;
  final ListSelectionController<T>? selection;
  final bool reorderable;

  /// Edge effect at the start / end of the scroll viewport — scrim,
  /// shader fade, or inner-shadow well. Defaults to off.
  final EdgeFadeStyle? edgeFade;

  /// Optional CTA rendered below the default empty state — turns a
  /// dead-end empty list into an actionable next step. Ignored when
  /// [emptyBuilder] is supplied (caller has full control then).
  final GlobalEmptyAction? emptyAction;

  /// When `true`, an overlay button appears in the bottom-end corner
  /// after scrolling past [scrollToTopThreshold]. Tapping it animates
  /// to scroll offset `0`.
  final bool? showScrollToTop;

  /// Scroll offset (in px) above which the scroll-to-top button
  /// appears. Defaults to 240 px.
  final double? scrollToTopThreshold;

  /// Override builder for the scroll-to-top FAB. Receives a callback
  /// that, when invoked, animates the list to the top.
  final Widget Function(BuildContext, VoidCallback)? scrollToTopBuilder;

  /// Thin progress strip at the start edge of the viewport showing
  /// scroll progress (0 → 1). Useful for long lists.
  final bool? showScrollProgress;

  /// Override colour for the scroll progress strip. Defaults to
  /// `colorScheme.primary`.
  final Color? progressColor;

  /// Identifier used to persist scroll offset across navigation via
  /// `PageStorageKey`. Two lists with the same id under the same
  /// route bucket will share state — choose a unique value.
  final String? restorationId;

  /// When supplied, items are bucketed into sections by the returned
  /// key. Sections retain the order in which their keys first appear
  /// in the items list — no auto-sort.
  final Object Function(T item)? groupBy;

  /// Builds the sticky section header for a given key + member count.
  /// Required when [groupBy] is supplied.
  final Widget Function(BuildContext, Object key, int count)?
  groupHeaderBuilder;

  /// Pixel height of the sticky section header.
  final double? groupHeaderHeight;

  /// Whether pinned headers stack on top of each other (`stack`) or
  /// replace each other as the user scrolls into a new section
  /// (`replace`). Replace mode uses `SliverMainAxisGroup` so the
  /// previous header scrolls off with its group.
  final GroupHeaderMode? groupHeaderMode;

  /// Actions surfaced in the bulk-actions toolbar when [selection] has
  /// items selected. Ignored when [selection] is null or empty.
  final List<GlobalBulkAction<T>>? bulkActions;

  /// Override builder for the bulk-actions toolbar. Receives the
  /// selection controller — caller has full control over chrome.
  final PreferredSizeWidget Function(BuildContext, ListSelectionController<T>)?
  bulkActionsBuilder;

  /// How items start a reorder drag. Defaults to `longPressAnywhere` —
  /// the widget wraps items in `ReorderableDelayedDragStartListener`.
  /// `handleOnly` skips the auto-wrap; caller embeds a
  /// [GlobalListReorderHandle] inside the item.
  final ReorderMode reorderMode;

  /// Predicate evaluated when [showSearchBar] is enabled. Items where
  /// the predicate returns `false` are hidden while the query is set.
  /// Empty query disables filtering.
  final bool Function(T item, String query)? searchPredicate;

  /// When `true`, renders a `TextField` above the list. Filters items
  /// locally via [searchPredicate]; for server-side search, leave off
  /// and drive a query into the controller from the caller.
  final bool showSearchBar;

  /// Placeholder text in the built-in search field.
  final String? searchHint;

  /// Builds the search field, handed the controller the list filters
  /// on.
  ///
  /// The module's own bar is deliberately bare — a primitive may not
  /// import `shared/common/`, so it cannot reach `SearchTextField` and
  /// its debounce, recents and scopes. Pass one through this slot to
  /// get them.
  final Widget Function(BuildContext, TextEditingController)? searchField;

  /// Rounds the RUN rather than each row — see [ListStyle.unifyTiles].
  final bool? unifyTiles;

  /// When `true`, items are diffed across rebuilds and inserts /
  /// removes are animated via `SliverAnimatedList`. Disables grouping
  /// and reorderable (these conflict with the animated sliver).
  final bool animateChanges;

  /// Transition used when an item enters / leaves the list under
  /// [animateChanges].
  final ListItemAnimation? itemAnimation;

  /// Duration of the insert / remove animation.
  final Duration? animationDuration;

  // ─── Scroll-in animation (viewport entry) ──────────────────

  /// When non-null, each row animates in the FIRST time it crosses
  /// [scrollInThreshold] of viewport visibility. Reuses the
  /// [ListItemAnimation] enum.
  ///
  /// Fires per index, not per build — virtualization-aware. Drives
  /// off `VisibilityDetector` so the animation runs when the user
  /// actually sees the row (not when it builds inside cacheExtent).
  final ListItemAnimation? scrollInAnimation;

  /// Duration of the scroll-in animation.
  final Duration? scrollInDuration;

  /// Visible-fraction threshold (0..1) that triggers the animation.
  final double? scrollInThreshold;

  /// When `true` (default) each index animates ONCE per State
  /// lifetime. When `false`, the animation re-fires every time the
  /// row leaves and re-enters the viewport.
  final bool? scrollInOnce;

  /// Per-row stagger applied when multiple rows cross the visibility
  /// threshold near-simultaneously. `Duration.zero` disables the
  /// cascade. Queue caps at ~120ms so fast scrolling stays in sync.
  final Duration? scrollInStagger;

  /// Stagger cascade ordering. `byRow` is effectively `byOrder` here
  /// (lists have one column) — included for API symmetry w/ grid.
  final ScrollInStaggerMode? scrollInStaggerMode;

  /// When `true`, slide-direction scroll-in animations flip based
  /// on the current scroll direction. Scrolling forward keeps the
  /// base direction; scrolling backward flips (`slideFromBottom` ⇄
  /// `slideFromTop`, `slideFromLeft` ⇄ `slideFromRight`).
  final bool scrollInDirectionAware;

  /// Fires when a row's scroll-in animation completes.
  final void Function(int index)? onScrollInComplete;

  /// Drives the scroll-in animation playback. [ScrollInMode.oneShot]
  /// (default) fires once on threshold crossing. [ScrollInMode.continuous]
  /// binds the controller to `visibleFraction` so scrolling drives
  /// playback. In continuous mode, duration / threshold / stagger /
  /// once / direction-aware are effectively ignored.
  final ScrollInMode? scrollInMode;

  // ─── Reorder semantics ─────────────────────────────────────

  /// When `true` (and [reorderable] is `true`), drag-and-drop swaps
  /// two rows instead of inserting the dragged row at the drop
  /// position. Replaces the default `SliverReorderableList` path
  /// with a drop-swap path that fires [onReorder] on drop.
  ///
  /// In swap mode, [onReorder] (not `controller.reorder`) is the
  /// callback that runs — caller mutates their data with
  /// `items[from] <-> items[to]` semantics.
  final bool swapMode;

  /// Fires when a swap-mode drag completes. `from` is the dragged
  /// row's original index, `to` is the drop target. Only invoked
  /// when [swapMode] is `true`.
  final void Function(int from, int to)? onReorder;

  /// When `true` (with [swapMode]), the swap fires CONTINUOUSLY
  /// during drag — every time the pointer crosses into a new row,
  /// the source and target rows swap. Default `false` = drop-swap
  /// (release-only). Swap doesn't shift other rows, so per-row
  /// `DragTarget.onMove` doesn't oscillate.
  final bool swapLive;

  /// When `true`, items are wrapped in `Focus`; arrow up / down move
  /// keyboard focus and `Enter` / `Space` invokes [onItemActivate].
  final bool enableKeyboardNav;

  /// Called when the focused item is activated via Enter or Space.
  final void Function(int index)? onItemActivate;

  /// Called when the user overscrolls past the end of the list (pull
  /// up from the bottom). The future is awaited so the caller can
  /// fetch older items / show a spinner.
  final Future<void> Function()? onLoadOlder;

  /// Overscroll distance (px) required to trigger [onLoadOlder].
  final double? loadOlderThreshold;

  /// Pinned at the bottom of the viewport (above pagination bar).
  /// "Total: $X" / "X of N" / batch-action footer.
  /// Pinned above the rows, inside the list's own column — so it sits
  /// under the search bar and the bulk toolbar and above the scroll
  /// view, and does not scroll away.
  ///
  /// [headerSlivers] is the other way to put something at the top, and
  /// it is a different thing: those SCROLL with the content unless
  /// each one pins itself, which means knowing about
  /// `SliverPersistentHeader` and writing a delegate. A column header,
  /// a filter row or a "3 of 40 shown" line wants this instead.
  final Widget? stickyHeader;

  final Widget? stickyFooter;

  /// When `true`, the list auto-scrolls to the new item when items
  /// are appended. Sticky behavior — if the user has scrolled away
  /// from the end, auto-scroll is suppressed until they return.
  final bool autoScrollOnNewItem;

  /// Fired the first time an item at `index` is built into the
  /// viewport. Useful for impression tracking / lazy-loading images.
  final void Function(int index)? onItemVisible;

  /// When `true` and the list is grouped, renders an A-Z scrubber
  /// strip on the trailing edge — drag to jump between sections.
  final bool enableScrubber;

  /// When `true`, scroll snaps to multiples of [snapItemExtent].
  /// Carousel-style. Caller should set [snapItemExtent] to match
  /// the item width (horizontal) or height (vertical).
  final bool snap;

  /// Extent each snap step uses. When null, falls back to
  /// [estimatedItemExtent].
  final double? snapItemExtent;

  /// Fired on right-click / secondary-tap on an item. Caller
  /// renders their own popup menu using `position`.
  final void Function(BuildContext, int index, Offset position)?
  onItemContextMenu;

  /// Builds the actions behind one row, per item.
  ///
  /// Per ITEM rather than one set for the list, because the actions a
  /// row offers depend on it: a pinned row offers "unpin", a read one
  /// offers "unread". Return null (or an empty set) for a row that
  /// swipes to nothing.
  ///
  /// `leading` and `trailing` are DIRECTIONAL — see [SwipeActions].
  /// Only for a VERTICAL list: a horizontal one has no spare axis to
  /// put the gesture on.
  final SwipeActions? Function(BuildContext, T item, int index)? swipeActions;

  /// Lets the module own selection taps, including the ANCHOR that
  /// makes a range selection possible.
  ///
  /// [ListSelectionController.selectRange] has always existed, but
  /// nothing here drove it: every caller that wanted shift-click kept
  /// its own anchor field and its own tap branch, which is the same
  /// twenty lines written once per screen and wrong in a different
  /// way each time.
  ///
  /// With this on, a row responds the way a file manager's does:
  ///
  /// - a plain tap toggles it and becomes the new anchor,
  /// - **Shift**+tap selects everything from the anchor to it,
  /// - **Ctrl / Cmd**+tap toggles WITHOUT moving the anchor,
  /// - a long-press and drag paints a range from wherever it started,
  /// - and with [enableKeyboardNav], **Shift**+arrow extends by one.
  ///
  /// Needs a [selection]. The long-press is skipped when
  /// [onItemContextMenu] is set — one gesture cannot be two things.
  final bool selectOnTap;

  /// When `true`, wraps the list in a `GestureDetector` that
  /// reports pinch scale via [onPinchScale]. Caller multiplies
  /// item heights by the scale.
  final bool enablePinchZoom;

  /// Fired during pinch — caller scales item rendering.
  final void Function(double scale)? onPinchScale;

  /// Estimated item extent (used by `scrollToItem` when items have
  /// uniform height; provides a reasonable approximation otherwise).
  final double? estimatedItemExtent;

  /// Optional override for the inline / non-pinned section divider
  /// rendered between groups when [groupHeaderMode] is `inline`.
  /// Falls back to `groupHeaderBuilder`.
  final Widget Function(BuildContext, Object key, int count)?
  sectionDividerBuilder;

  /// When `true`, a FAB appears at the bottom-end when new items
  /// arrive AND the user is scrolled away from the end of the list.
  /// Tap → scrolls to the newest item. Resets the pending count
  /// when the user reaches the end on their own.
  final bool showNewItemFab;

  /// Custom builder for the new-item FAB. Receives the pending count
  /// + a tap handler that scrolls to the newest item.
  final Widget Function(BuildContext, int pendingCount, VoidCallback onTap)?
  newItemFabBuilder;

  /// Whether to call `controller.load()` in `initState`. Off for
  /// static lists (controller is a no-op) or when the caller has
  /// already loaded.
  final bool autoLoad;

  @override
  State<GlobalList<T>> createState() => GlobalListState<T>();
}

/// A controller that does nothing — used in [GlobalList.static] so
/// the widget doesn't need a null branch on every controller access.
class _NoOpController<T> extends GlobalListController<T> {
  _NoOpController()
    : super(
        fetchPage: ({page, cursor, required pageSize}) =>
            Future.value(GlobalListPage<T>(items: const [])),
      );
}

class GlobalListState<T> extends State<GlobalList<T>>
    with TickerProviderStateMixin {
  /// Auto-scrolls the surrounding Scrollable when the user drags a
  /// row near the leading/trailing edge during swap-mode drag. Built
  /// into Flutter's `SliverReorderableList`, so we only need to drive
  /// it for our custom swap path.
  final DragAutoScroller _autoScroll = DragAutoScroller();

  late ScrollController _scrollCtrl;
  bool _ownsScroll = false;
  bool _kickedLoad = false;

  // ─── Search bar state ─────────────────────────────────────
  final TextEditingController _searchCtrl = TextEditingController();
  String _searchQuery = '';

  // ─── Animated-changes state ───────────────────────────────
  final GlobalKey<SliverAnimatedListState> _animatedKey =
      GlobalKey<SliverAnimatedListState>();
  List<T> _animatedSnapshot = const [];

  /// How many rows the SLIVER believes it has.
  ///
  /// Not the same as `_animatedSnapshot.length` the moment anything
  /// goes wrong, and `removeItem` asserts on an index outside it. It
  /// is tracked rather than inferred so a desync — a filter changing
  /// under a burst of inserts, a rebuild landing between two
  /// notifications — degrades into a skipped animation instead of
  /// `itemIndex >= 0 && itemIndex < _itemsCount is not true`, which
  /// killed every later animation with it.
  int _animatedCount = 0;

  // ─── Pull-up to load older ────────────────────────────────
  bool _loadOlderInFlight = false;

  // ─── Keyboard navigation scope ────────────────────────────
  final FocusScopeNode _listFocusScope = FocusScopeNode(
    debugLabel: 'GlobalList',
  );

  // ─── Item visibility tracking ────────────────────────────
  final Set<int> _seenIndices = <int>{};

  /// The bag, resolved.
  ///
  /// In `didChangeDependencies`, never `initState` — the palette and
  /// `MediaQuery.disableAnimationsOf` are inherited reads and
  /// `initState` can see neither.
  late ResolvedListStyle _rs;

  // ─── Scroll-in animation ─────────────────────────────────
  /// Where a range selection is measured FROM — the last row tapped
  /// without a modifier. Null until the reader picks one.
  int? _selectionAnchor;

  /// The index a long-press-drag started on, while it is running.
  int? _dragSelectAnchor;

  /// Where a keyboard extension has reached, which is NOT the anchor:
  /// shift-down twice then shift-up has to shrink the range, and that
  /// needs both ends remembered.
  int? _selectionCursor;

  /// The list's own box, for turning a drag position into the index
  /// of the row under it.
  final GlobalKey _rowsKey = GlobalKey(debugLabel: 'GlobalList rows');

  /// Which row has its swipe pane open, shared by every row so only
  /// one is. Also cleared on scroll — a pane left open behind a
  /// scrolling list is one the reader has forgotten about.
  final ValueNotifier<Object?> _openSwipeRow = ValueNotifier<Object?>(null);

  final Set<int> _scrollInFired = <int>{};
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
    // The RESOLVED stagger: reduced motion zeroes it, and a cascade
    // made instant is a delay before something appears rather than a
    // cascade.
    final style = _scrollInStyle.resolve(context);
    return _scrollInCursor.claim(
      style.stagger,
      index,
      mode: style.staggerMode,
      idleReset: style.staggerIdleReset,
      maxQueue: style.staggerMaxQueue,
    );
  }

  // Direction tracking for `scrollInDirectionAware`.
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

  /// Look up an item's current index by its `identityHashCode`.
  int? _findItemIndexById(List<T> items, int id) {
    for (var i = 0; i < items.length; i++) {
      if (identityHashCode(items[i]) == id) return i;
    }
    return null;
  }

  // ─── Live-swap state ─────────────────────────────────────
  // For `swapMode + swapLive`, all hover events route through this
  // state. The dragged row's HOME slot is fixed at drag-begin; each
  // new hover undoes the in-flight swap (call onReorder w/ the
  // current pair — swap is symmetric so this restores) then applies
  // the new one. Yields "swap home with final target only" — items
  // between origin and target stay put.
  int? _liveSwapOrigin;
  int? _liveSwapCurrent;

  void _beginListSwap(int sourceIndex) {
    _liveSwapOrigin = sourceIndex;
    _liveSwapCurrent = sourceIndex;
    // GlobalListState's context is OUTSIDE the CustomScrollView, so
    // Scrollable.maybeOf wouldn't find it. Use the scroll controller
    // directly — we own it via `_scrollCtrl`.
    _autoScroll.startWithController(this, _scrollCtrl);
  }

  void _endListSwap() {
    _liveSwapOrigin = null;
    _liveSwapCurrent = null;
    _autoScroll.stop();
  }

  void _onSwapPointer(Offset globalPointer) {
    _autoScroll.pointerGlobal = globalPointer;
  }

  void _hoverListSwap(int targetIndex) {
    final origin = _liveSwapOrigin;
    if (origin == null) return;
    if (targetIndex == _liveSwapCurrent) return;
    if (_liveSwapCurrent != origin) {
      widget.onReorder?.call(origin, _liveSwapCurrent!);
    }
    if (targetIndex != origin) {
      widget.onReorder?.call(origin, targetIndex);
    }
    _liveSwapCurrent = targetIndex;
  }

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

  // ─── Auto-scroll on new item ─────────────────────────────
  int _lastItemCount = 0;

  // ─── New-item FAB ───────────────────────────────────────
  int _pendingNewCount = 0;

  // ─── Section header keys (for pixel-accurate scrubber jumps) ─
  final Map<Object, GlobalKey> _sectionHeaderKeys = <Object, GlobalKey>{};

  bool get _isStatic => widget._staticItems != null;

  @override
  void initState() {
    super.initState();
    _scrollCtrl = widget.scrollController ?? ScrollController();
    _ownsScroll = widget.scrollController == null;
    if (widget.paginationStyle == PaginationStyle.infiniteScroll) {
      _scrollCtrl.addListener(_maybeLoadMore);
    }
    widget.controller.addListener(_onControllerChange);
    if (widget.swipeActions != null) {
      _scrollCtrl.addListener(_closeSwipeOnScroll);
    }
    if (widget.autoLoad && !_isStatic && !_kickedLoad) {
      _kickedLoad = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) widget.controller.load();
      });
    }
    if (widget.selection != null) {
      widget.selection!.addListener(_onSelectionChange);
    }
    if (widget.animateChanges) {
      _animatedSnapshot = _filterItems(_currentItems);
      _animatedCount = _animatedSnapshot.length;
    }
    _searchCtrl.addListener(_onSearchChange);
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

  /// The caller's answers, as ONE bag.
  ///
  /// The flat chrome parameters — `edgeFade`, `showScrollToTop` and
  /// the rest — are a shorthand for fields of `style.scrollable`, so
  /// they merge ON TOP of it rather than living in a second place the
  /// resolve never sees. A caller who names one explicitly is being
  /// more specific than one who set the bag, so it wins.
  ListStyle get _callerStyle => (widget.style ?? const ListStyle()).mergedWith(
    ListStyle(
      scrollable: ScrollableStyle(
        edgeFade: widget.edgeFade,
        showScrollToTop: widget.showScrollToTop,
        scrollToTopThreshold: widget.scrollToTopThreshold,
        showScrollProgress: widget.showScrollProgress,
        progressColor: widget.progressColor,
      ),
      scrollIn: _scrollInStyle,
      // EVERY flat style parameter, not just the chrome. The first
      // cut of this folded only `scrollable` and `scrollIn`, so
      // `groupHeaderMode: replace` and `itemAnimation: fade` never
      // reached the resolve — the list read the floor's `stack` and
      // `fadeSize` whatever the caller asked for.
      groupHeaderHeight: widget.groupHeaderHeight,
      groupHeaderMode: widget.groupHeaderMode,
      itemAnimation: widget.itemAnimation,
      animationDuration: widget.animationDuration,
      estimatedItemExtent: widget.estimatedItemExtent,
      loadOlderThreshold: widget.loadOlderThreshold,
      unifyTiles: widget.unifyTiles,
    ),
  );

  /// The bag this list actually resolved to.
  ///
  /// The test seam for the fold above: the flat parameters are a
  /// shorthand for bag fields, and the only way to prove one arrived
  /// is to ask the list what it ended up with.
  @visibleForTesting
  ResolvedListStyle get resolvedStyle => _rs;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _rs = _callerStyle.resolve(context);
    if (_rs.crossAxisFit == ListCrossAxisFit.tallestVisible) {
      _scrollCtrl.removeListener(_queueVisibleFit);
      _scrollCtrl.addListener(_queueVisibleFit);
      _queueVisibleFit();
    }
  }

  /// Current source-of-truth items list (static items or controller
  /// items). Used for diff, filter, etc.
  List<T> get _currentItems =>
      _isStatic ? widget._staticItems! : widget.controller.items;

  /// Effective scroll physics — falls back to bouncing when the
  /// caller didn't set one AND [GlobalList.onLoadOlder] is wired.
  /// Bouncing physics is required to receive overscroll
  /// notifications past the end of the list (Android's default
  /// `ClampingScrollPhysics` clamps and emits no overscroll signal).
  ScrollPhysics? get _effectivePhysics {
    if (widget.snap) {
      final extent = widget.snapItemExtent ?? _rs.estimatedItemExtent;
      return _SnapScrollPhysics(itemExtent: extent);
    }
    if (widget.physics != null) return widget.physics;
    // Nested under a passThroughAtEdge GlobalScrollable → switch to
    // clamping so overscroll bubbles up as a notification (Bouncing
    // absorbs drag into rubber-band, no notification = no handoff).
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

  void _onSearchChange() {
    final next = _searchCtrl.text;
    if (next != _searchQuery) {
      setState(() => _searchQuery = next);
    }
  }

  /// Returns the items visible after applying the search predicate.
  /// When search is off or query is empty, returns `items` unchanged.
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

  @override
  void didUpdateWidget(GlobalList<T> oldWidget) {
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
    if (widget.selection != oldWidget.selection) {
      oldWidget.selection?.removeListener(_onSelectionChange);
      widget.selection?.addListener(_onSelectionChange);
    }
  }

  @override
  void dispose() {
    _autoScroll.stop();
    _scrollCtrl.removeListener(_maybeLoadMore);
    _scrollCtrl.removeListener(_onScrollDirectionTick);
    widget.controller.removeListener(_onControllerChange);
    widget.selection?.removeListener(_onSelectionChange);
    _scrollCtrl.removeListener(_queueVisibleFit);
    _scrollCtrl.removeListener(_closeSwipeOnScroll);
    _openSwipeRow.dispose();
    _searchCtrl
      ..removeListener(_onSearchChange)
      ..dispose();
    _listFocusScope.dispose();
    if (_ownsScroll) _scrollCtrl.dispose();
    super.dispose();
  }

  void _onControllerChange() {
    if (widget.animateChanges && !_isStatic) {
      // The FILTERED list — the same one the sliver is built from.
      // Diffing against the raw items desynced the moment a search
      // was active.
      _diffAndAnimate(_filterItems(widget.controller.items));
    }
    _maybeAutoScroll(widget.controller.items.length);
    _safeSetState();
  }

  /// Reacts to item-count changes. Two behaviors driven by flags:
  /// * [GlobalList.autoScrollOnNewItem]: animates to the new item
  ///   when the user is already near the end.
  /// * [GlobalList.showNewItemFab]: tracks the count of items added
  ///   while the user is scrolled away — surfaces a "Jump to new"
  ///   FAB in the overlays.
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

  /// Clears the pending count + animates to the newest item.
  /// Bound to the new-item FAB.
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

  /// Diffs `_animatedSnapshot` against `next` and drives the
  /// `SliverAnimatedListState` so insertions and removals animate.
  ///
  /// **Synchronously, in the same frame as the data change.** It used
  /// to defer to a post-frame callback, which meant one frame where
  /// the sliver still believed the OLD item count while the builder
  /// was already handing it the NEW list — every row rendered shifted
  /// by one and then snapped back. That is the flash when adding or
  /// removing at the top; it is invisible at the bottom because the
  /// mismatched row is off screen.
  ///
  /// `insertItem` / `removeItem` mark the sliver dirty themselves, so
  /// the rebuild that follows already has the right count.
  void _diffAndAnimate(List<T> next) {
    final captured = List<T>.from(next);
    final state = _animatedKey.currentState;
    if (state == null) {
      _animatedSnapshot = captured;
      _animatedCount = captured.length;
      return;
    }

    // A MULTISET, not a set.
    //
    // The diff used to ask "is this item in the new list?" through a
    // `Set`, which cannot see duplicates — and a list that recycles a
    // pool of items has plenty. Re-adding an item already present
    // looked like no change at all: no `insertItem` fired, the
    // sliver's count fell behind the real list, and the next remove
    // asserted on an index past the end. Every animation after that
    // was dead, because the throw left the snapshot stale.
    final remaining = <T, int>{};
    for (final item in captured) {
      remaining[item] = (remaining[item] ?? 0) + 1;
    }

    // Which of the old rows survive: the first N copies of each item,
    // where N is how many the new list holds.
    final keep = List<bool>.filled(_animatedSnapshot.length, false);
    for (var i = 0; i < _animatedSnapshot.length; i++) {
      final item = _animatedSnapshot[i];
      final left = remaining[item] ?? 0;
      if (left > 0) {
        keep[i] = true;
        remaining[item] = left - 1;
      }
    }

    // Remove descending so indices stay valid.
    for (var i = _animatedSnapshot.length - 1; i >= 0; i--) {
      if (keep[i]) continue;
      // OUT OF RANGE means the sliver and the snapshot have already
      // disagreed. Skip rather than assert: a missed animation is a
      // blemish, and the assertion took every later one down with it.
      if (i >= _animatedCount) continue;
      final item = _animatedSnapshot[i];
      state.removeItem(
        i,
        (ctx, anim) => _wrapItemTransition(
          ctx,
          widget.itemBuilder(ctx, item, i),
          anim,
        ),
        duration: _rs.animationDuration,
      );
      _animatedCount--;
    }

    // What is left of the old list, in order — the rows the sliver
    // still holds. Anything in the new list beyond these is an
    // insertion, matched off in the same first-come order.
    final survivors = <T>[
      for (var i = 0; i < _animatedSnapshot.length; i++)
        if (keep[i]) _animatedSnapshot[i],
    ];
    var survivor = 0;
    for (var i = 0; i < captured.length; i++) {
      if (survivor < survivors.length && survivors[survivor] == captured[i]) {
        survivor++;
        continue;
      }
      state.insertItem(
        i > _animatedCount ? _animatedCount : i,
        duration: _rs.animationDuration,
      );
      _animatedCount++;
    }

    _animatedSnapshot = captured;
    // Whatever happened above, this is the truth from here on: the
    // sliver rebuilds from `captured` and the next diff must agree
    // with it.
    _animatedCount = captured.length;
  }

  /// Wraps `child` in the configured [GlobalList.itemAnimation]
  /// driven by `anim`. Used by both insert (via SliverAnimatedList's
  /// itemBuilder) and remove (via removeItem's builder).
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
      // The VERTICAL pair anchors its `SizeTransition` instead of
      // sliding inside it.
      //
      // A `SlideTransition` by a FRACTION of a box the `SizeTransition`
      // is growing from zero height moves the row by a fraction of
      // almost nothing — so `slideFromTop` appeared not to animate at
      // all, and `slideFromBottom` only looked right because growing
      // downward reads like arriving from below anyway. `axisAlignment`
      // pins which edge the row grows FROM, which is the same effect
      // and is not cancelled by its own size.
      case ListItemAnimation.slideFromBottom:
        return SizeTransition(
          sizeFactor: anim,
          alignment: Alignment.bottomCenter,
          child: FadeTransition(opacity: anim, child: child),
        );
      case ListItemAnimation.slideFromTop:
        return SizeTransition(
          sizeFactor: anim,
          alignment: Alignment.topCenter,
          child: FadeTransition(opacity: anim, child: child),
        );
      case ListItemAnimation.scale:
        return SizeTransition(
          sizeFactor: anim,
          child: ScaleTransition(
            scale: anim.drive(CurveTween(curve: Curves.easeOutBack)),
            child: FadeTransition(opacity: anim, child: child),
          ),
        );
      case ListItemAnimation.fade:
        return FadeTransition(opacity: anim, child: child);
    }
  }

  void _onSelectionChange() {
    _safeSetState();
  }

  /// Defers `setState` to a post-frame callback when called during a
  /// build / layout / paint phase. The controller can fire
  /// notifications synchronously from scroll-driven fetches (e.g.
  /// `loadMore` calls `notifyListeners()` before its async work) —
  /// running `setState` directly during the parent's layout pass
  /// trips Flutter's "relayout during layout" assertions.
  void _safeSetState() {
    if (!mounted) return;
    // Deferred ONLY during build / layout / paint, which is the one
    // phase where `setState` throws.
    //
    // It used to defer during `transientCallbacks` as well — the phase
    // a drop animation ends in — so a reorder mutated the list, asked
    // for a rebuild, and got it a frame LATER: one frame painted in
    // the old order before the new one appeared. That is the flash on
    // drop, and the same frame of lag sat under every other change
    // driven from an animation.
    if (SchedulerBinding.instance.schedulerPhase !=
        SchedulerPhase.persistentCallbacks) {
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
      // Kick the fetch via a microtask so the synchronous part of
      // `loadMore` (flag flip + notifyListeners) doesn't run inside
      // the scroll-driven layout pass that triggered this listener.
      Future.microtask(widget.controller.loadMore);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Static-mode shortcut — render straight from the items list,
    // no chrome / pagination / loading. Bulk toolbar still applies if
    // a selection + actions are configured.
    if (_isStatic &&
        _rs.crossAxisFit.isFitted &&
        widget.scrollDirection == Axis.horizontal) {
      return _buildFitted(context);
    }
    if (_isStatic) {
      var staticContent = _maybeWrapPullUp(
        _maybeWrapOverlays(_maybeWrapScrubber(context, _buildStatic(context))),
      );
      final staticToolbar = _buildBulkToolbar(context);
      final searchBar = _buildSearchBar(context);
      if (staticToolbar != null ||
          searchBar != null ||
          widget.stickyHeader != null ||
          widget.stickyFooter != null) {
        staticContent = Column(
          children: [
            if (staticToolbar != null) staticToolbar,
            if (searchBar != null) searchBar,
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

    var content = _maybeWrapEdgeFade(_buildScrollView(context, ctrl, phase));

    if (widget.onRefresh != null && widget.scrollDirection == Axis.vertical) {
      // Through the MODULE, not a raw `RefreshIndicator`. A list's
      // pull is the most common one in the app, and raw it got none of
      // what `GlobalRefreshable` does: no haptic, no minimum show time
      // (so a fast fetch flashed), no error handling (a throw escaped
      // into the zone), no semantics action for a reader who cannot
      // pull, and always the Material spinner — even on an iPhone.
      content = GlobalRefreshable(
        onRefresh: widget.onRefresh!,
        controller: widget.refreshController,
        // The UNRESOLVED colour, so this only overrides the refresh
        // theme when the list was actually told one. The resolved
        // value is never null and would shout down a house style.
        style: RefreshableStyle(color: _callerStyle.loadingIndicatorColor),
        child: content,
      );
    }

    content = _maybeWrapPullUp(
      _maybeWrapOverlays(_maybeWrapScrubber(context, content)),
    );

    // Bulk toolbar pinned ABOVE the scroll view. Animates in/out
    // when the selection controller toggles between empty / non-empty.
    final bulkToolbar = _buildBulkToolbar(context);
    final searchBar = _buildSearchBar(context);

    // Numbered / compact-numbered pagination bars live OUTSIDE the
    // scroll view as a fixed footer.
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

  /// Wraps `child` in a `GestureDetector` that reports pinch scale
  /// via [GlobalList.onPinchScale]. The caller is responsible for
  /// applying the scale to their item rendering (we don't intercept
  /// item heights since items can be arbitrarily complex).
  Widget _maybeWrapPinch(Widget child) {
    if (!widget.enablePinchZoom || widget.onPinchScale == null) return child;
    return GestureDetector(
      onScaleUpdate: (d) => widget.onPinchScale!(d.scale),
      child: child,
    );
  }

  /// Overlays the A-Z scrubber on the trailing edge when enabled +
  /// the list is grouped. Computes section start indices from the
  /// current item set and animates to them via [scrollToItem].
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

  /// Wraps `child` in a [NotificationListener] that detects when the
  /// user has dragged the scroll position past the bottom of the
  /// content (only possible under [BouncingScrollPhysics], hence the
  /// override in [_effectivePhysics]). Triggers [GlobalList.onLoadOlder]
  /// once per overscroll, debounced via `_loadOlderInFlight`.
  Widget _maybeWrapPullUp(Widget child) {
    if (widget.onLoadOlder == null || widget.scrollDirection != Axis.vertical) {
      return child;
    }
    return NotificationListener<ScrollNotification>(
      onNotification: (n) {
        // Detect via direct pixel comparison rather than overscroll
        // accumulator — more robust than [OverscrollNotification]
        // which doesn't fire on every drag delta.
        final overshoot = n.metrics.pixels - n.metrics.maxScrollExtent;
        if (overshoot > _rs.loadOlderThreshold &&
            !_loadOlderInFlight &&
            n.metrics.maxScrollExtent > 0) {
          _loadOlderInFlight = true;
          final fut = widget.onLoadOlder!();
          fut.whenComplete(() {
            if (mounted) _loadOlderInFlight = false;
          });
        }
        return false;
      },
      child: child,
    );
  }

  /// Returns the built-in search bar, or null when disabled.
  Widget? _buildSearchBar(BuildContext context) {
    if (!widget.showSearchBar) return null;
    // The SLOT wins. This module is a primitive and may not import
    // `shared/common/`, so the bar it can build itself is deliberately
    // bare — no debounce, no recents, no scopes. A caller that wants
    // the app's real search field passes one in, which is the same
    // seam `GlobalAppBar.searchField` offers.
    return widget.searchField?.call(context, _searchCtrl) ??
        GlobalListSearchBar(controller: _searchCtrl, hint: widget.searchHint);
  }

  /// Wraps `content` in `FocusScope` + `FocusTraversalGroup` +
  /// `Shortcuts` so the list is a self-contained focus scope —
  /// Tab into the scope lands on the first item, arrow up / down
  /// move focus within the list.
  Widget _maybeWrapKeyboardScope(Widget content) {
    // The KEY goes on regardless of the keyboard: a drag-select turns
    // a position into a row by hit-testing this box, and that has
    // nothing to do with whether the list takes focus.
    content = KeyedSubtree(key: _rowsKey, child: content);
    if (widget.selectOnTap) {
      // The LIST ends the drag, not the row that started it.
      //
      // Once the auto-scroll carries that row off the screen the
      // sliver disposes it, its recogniser goes with it, and no
      // `onLongPressEnd` ever arrives — so the ticker ran forever and
      // the selection stayed live after the finger had gone. A
      // `Listener` here takes no part in the gesture arena and
      // outlives every row.
      content = Listener(
        // The MOVE comes from here too, for the same reason the end
        // does. A row that scrolls away takes its recogniser with it,
        // so `onLongPressMoveUpdate` stopped arriving the moment the
        // auto-scroll carried the starting row off screen — the
        // scroller kept the last edge position it had been given and
        // drove the list to the end however the finger moved after.
        onPointerMove: (e) => _onDragSelectMove(e.position),
        onPointerUp: (_) => _endDragSelect(),
        onPointerCancel: (_) => _endDragSelect(),
        child: content,
      );
    }
    if (!widget.enableKeyboardNav) return content;
    return FocusScope(
      node: _listFocusScope,
      child: FocusTraversalGroup(
        policy: ReadingOrderTraversalPolicy(),
        child: Shortcuts(
          shortcuts: const <ShortcutActivator, Intent>{
            SingleActivator(LogicalKeyboardKey.arrowDown): NextFocusIntent(),
            SingleActivator(LogicalKeyboardKey.arrowUp): PreviousFocusIntent(),
            // Shift+arrow EXTENDS rather than moving: it walks the
            // focus like the plain arrow and takes the selection with
            // it, which is what every desktop list does.
            SingleActivator(LogicalKeyboardKey.arrowDown, shift: true):
                _ExtendSelectionIntent(1),
            SingleActivator(LogicalKeyboardKey.arrowUp, shift: true):
                _ExtendSelectionIntent(-1),
          },
          child: Actions(
            actions: <Type, Action<Intent>>{
              _ExtendSelectionIntent: CallbackAction<_ExtendSelectionIntent>(
                onInvoke: (intent) {
                  _extendSelection(intent.delta);
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

  /// Moves the keyboard by one row and takes the selection with it.
  ///
  /// Anchored the same way the mouse is — the anchor is wherever the
  /// reader last picked without a modifier, so shift-down then
  /// shift-up shrinks the range rather than leaving a stranded row.
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
    // The RING follows the range. Without this the focus stayed on the
    // row the reader started from and the next Shift+arrow was
    // dispatched from there.
    _listFocusScope.focusInDirection(
      delta > 0 ? TraversalDirection.down : TraversalDirection.up,
    );
  }

  /// Programmatically moves focus into the list (to whichever item is
  /// the first focusable). Useful when callers want to focus the list
  /// from an external button, e.g. a "Search" command palette.
  void focus() {
    if (!widget.enableKeyboardNav) return;
    _listFocusScope.requestFocus();
    _listFocusScope.nextFocus();
  }

  /// Animates the scroll offset to bring `index` to the leading edge
  /// of the viewport. Uses [GlobalList.estimatedItemExtent] for the
  /// offset calculation — accurate when items are uniform, an
  /// approximation otherwise. Pair with [scrollToOffset] for exact
  /// control when you know the exact pixel position.
  Future<void> scrollToItem(
    int index, {
    Duration duration = const Duration(milliseconds: 320),
    Curve curve = Curves.easeOutCubic,
  }) async {
    if (!_scrollCtrl.hasClients) return;
    var offset = index * _rs.estimatedItemExtent;
    // When grouped, every section that starts at or before `index`
    // contributes an extra header above it. Account for those so the
    // target lines up with the actual rendered position.
    if (widget.groupBy != null && widget.groupHeaderBuilder != null) {
      final items = _currentItems;
      final seen = <Object>{};
      var sectionsBefore = 0;
      for (var i = 0; i <= index && i < items.length; i++) {
        if (seen.add(widget.groupBy!(items[i]))) sectionsBefore++;
      }
      offset += sectionsBefore * _rs.groupHeaderHeight;
    }
    final clamped = offset.clamp(0.0, _scrollCtrl.position.maxScrollExtent);
    await _scrollCtrl.animateTo(clamped, duration: duration, curve: curve);
  }

  /// Animates the scroll offset to an exact pixel value.
  Future<void> scrollToOffset(
    double offset, {
    Duration duration = const Duration(milliseconds: 320),
    Curve curve = Curves.easeOutCubic,
  }) async {
    if (!_scrollCtrl.hasClients) return;
    final clamped = offset.clamp(0.0, _scrollCtrl.position.maxScrollExtent);
    await _scrollCtrl.animateTo(clamped, duration: duration, curve: curve);
  }

  /// Returns an opaque token representing the current scroll offset.
  /// Restore later via [restoreBookmark]. Survives rebuilds (the
  /// token is a raw pixel offset).
  double bookmark() => _scrollCtrl.hasClients ? _scrollCtrl.position.pixels : 0;

  /// Rides back to the offset captured by [bookmark].
  ///
  /// It used to JUMP, which read as the list having been replaced —
  /// every other programmatic move in this class animates, so a
  /// restore that teleported was the odd one out. Reduced motion
  /// still gets the jump, because the bag resolves the duration to
  /// zero.
  Future<void> restoreBookmark(
    double token, {
    Duration? duration,
    Curve curve = Curves.easeOutCubic,
  }) async {
    if (!_scrollCtrl.hasClients) return;
    final clamped = token.clamp(0.0, _scrollCtrl.position.maxScrollExtent);
    final d = duration ?? _rs.animationDuration;
    if (d == Duration.zero) {
      _scrollCtrl.jumpTo(clamped);
      return;
    }
    await _scrollCtrl.animateTo(clamped, duration: d, curve: curve);
  }

  /// Pixel-accurate scroll to a section header (only meaningful when
  /// the list is grouped). Computes the offset within this list's
  /// own viewport via `RenderAbstractViewport.getOffsetToReveal` and
  /// drives `_scrollCtrl` directly — does NOT walk up to outer
  /// scrollables (unlike `Scrollable.ensureVisible`), so a list
  /// nested inside a parent ListView won't scroll the parent too.
  Future<void> scrollToSection(
    Object key, {
    Duration duration = const Duration(milliseconds: 320),
    Curve curve = Curves.easeOutCubic,
  }) async {
    if (!_scrollCtrl.hasClients) return;
    final groupBy = widget.groupBy;
    if (groupBy == null) return;
    final items = _filterItems(_currentItems);
    final index = items.indexWhere((item) => groupBy(item) == key);
    if (index < 0) return;

    // Measured from the INDEX, not from the header's render box.
    //
    // It used to ask the built header where it was — and in a
    // virtualised list a section below the fold has no render object
    // at all, while a PINNED one reports the top of the viewport
    // (which is wherever you already are). So the scrubber either did
    // nothing or landed somewhere unrelated to the letter pressed.
    // Every other jump in this class estimates from the index; this
    // one now does too.
    final headerKey = _sectionHeaderKeys[key];
    final ctx = headerKey?.currentContext;
    final box = ctx?.findRenderObject();
    if (box is RenderBox && box.attached) {
      final viewport = RenderAbstractViewport.maybeOf(box);
      // A BUILT, unpinned header knows exactly where it is — better
      // than an estimate, so use it when it is there.
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
    await scrollToItem(index, duration: duration, curve: curve);
  }

  /// Returns the bulk-actions toolbar wrapped in `AnimatedSize` so it
  /// collapses to zero height when no items are selected.
  Widget? _buildBulkToolbar(BuildContext context) {
    final selection = widget.selection;
    final actions = widget.bulkActions;
    final builder = widget.bulkActionsBuilder;
    if (selection == null) return null;
    if (builder == null && (actions == null || actions.isEmpty)) return null;
    return _BulkActionsCollapser<T>(
      selection: selection,
      child: builder != null
          ? builder(context, selection)
          : _BulkActionsToolbar<T>(selection: selection, actions: actions!),
    );
  }

  // ─── Static-mode branch ────────────────────────────────────

  Widget _buildStatic(BuildContext context) {
    final items = _filterItems(widget._staticItems!);
    _renderedItems = items;
    _renderedCount = items.length;
    final padding = _rs.padding ?? EdgeInsets.zero;
    final swap =
        widget.reorderable &&
        widget.swapMode &&
        widget.scrollDirection == Axis.vertical;
    final itemSlivers =
        widget.groupBy != null && widget.groupHeaderBuilder != null
        ? _buildGroupedSlivers(context, items, padding)
        : [
            SliverPadding(
              padding: padding,
              sliver: swap
                  ? SliverList.builder(
                      itemCount: items.length,
                      itemBuilder: (ctx, i) => _ListSwapCell(
                        index: i,
                        itemId: identityHashCode(items[i]),
                        findIndexById: (id) => _findItemIndexById(items, id),
                        live: widget.swapLive,
                        duration: _rs.animationDuration,
                        onDropSwap: (from, to) =>
                            widget.onReorder?.call(from, to),
                        onLiveHover: _hoverListSwap,
                        onDragBegin: _beginListSwap,
                        onDragEnd: _endListSwap,
                        onDragUpdate: _onSwapPointer,
                        child: _wrapItem(
                          ctx,
                          widget.itemBuilder(ctx, items[i], i),
                          i,
                        ),
                      ),
                    )
                  : widget.separatorBuilder != null
                  ? SliverList.separated(
                      itemCount: items.length,
                      itemBuilder: (ctx, i) => _wrapItem(
                        ctx,
                        widget.itemBuilder(ctx, items[i], i),
                        i,
                      ),
                      separatorBuilder: widget.separatorBuilder!,
                    )
                  : SliverList.builder(
                      itemCount: items.length,
                      itemBuilder: (ctx, i) => _wrapWithSpacing(
                        _wrapItem(ctx, widget.itemBuilder(ctx, items[i], i), i),
                        i,
                        items.length,
                      ),
                    ),
            ),
          ];
    final scrollView = CustomScrollView(
      key: _storageKey,
      scrollDirection: widget.scrollDirection,
      reverse: widget._staticReverse,
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
    );
    return _maybeWrapEdgeFade(scrollView);
  }

  /// Builds alternating sticky-header + section-list slivers when
  /// [GlobalList.groupBy] / [GlobalList.groupHeaderBuilder] are set.
  /// Sections preserve the order in which their keys first appear in
  /// `items` — no auto-sort, callers pre-sort if needed.
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
    final slivers = <Widget>[];
    final hPad = padding.resolve(Directionality.of(context));
    final mode = _rs.groupHeaderMode;
    // Drop stale keys so the map doesn't leak entries for removed
    // sections (could happen after filter / pagination).
    _sectionHeaderKeys.removeWhere((k, _) => !sections.containsKey(k));
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
      // Inline mode renders as a SliverToBoxAdapter so the divider
      // scrolls with the items (no pinning).
      final header = mode == GroupHeaderMode.inline
          ? SliverToBoxAdapter(child: headerWidget)
          : SliverPersistentHeader(
              pinned: true,
              delegate: _SectionHeaderDelegate(
                height: _rs.groupHeaderHeight,
                child: headerWidget,
              ),
            );
      final list = SliverPadding(
        padding: EdgeInsets.only(left: hPad.left, right: hPad.right),
        sliver: widget.separatorBuilder != null
            ? SliverList.separated(
                itemCount: indices.length,
                itemBuilder: (ctx, i) => _wrapItem(
                  ctx,
                  widget.itemBuilder(ctx, items[indices[i]], indices[i]),
                  indices[i],
                ),
                separatorBuilder: widget.separatorBuilder!,
              )
            : SliverList.builder(
                itemCount: indices.length,
                itemBuilder: (ctx, i) => _wrapWithSpacing(
                  _wrapItem(
                    ctx,
                    widget.itemBuilder(ctx, items[indices[i]], indices[i]),
                    indices[i],
                  ),
                  i,
                  indices.length,
                ),
              ),
      );
      // Replace mode: wrap (header, list) in a SliverMainAxisGroup so
      // the pinned header scrolls off with its group when the next
      // section reaches the top. Stack mode: separate top-level
      // slivers so pins stack. Inline mode: header is non-pinned so
      // a plain pair works either way.
      if (mode == GroupHeaderMode.replace) {
        slivers.add(SliverMainAxisGroup(slivers: [header, list]));
      } else {
        slivers.add(header);
        slivers.add(list);
      }
    });
    if (mode == GroupHeaderMode.stack) return _capStacking(slivers);
    return slivers;
  }

  /// How many `stack`-mode headers may pin at once.
  ///
  /// Ten sections of a 36-point header is 360 points of header. On a
  /// short window that is the whole list: a stack of labels with no
  /// content under them. The cap that matters is how much room is
  /// left for CONTENT, so it is worked out from the viewport unless
  /// the caller names a number.
  int get _maxStackedHeaders {
    final explicit = _rs.maxStackedHeaders;
    if (explicit != null) return explicit < 1 ? 1 : explicit;
    final height = _rs.groupHeaderHeight;
    if (height <= 0) return 1;
    final extent =
        _scrollCtrl.hasClients && _scrollCtrl.position.hasViewportDimension
        ? _scrollCtrl.position.viewportDimension
        // First build: nothing has been laid out yet, so the window is
        // the best guess available.
        : MediaQuery.sizeOf(context).height;
    final room = (extent * _rs.stackedHeaderMaxFraction) / height;
    return room.floor().clamp(1, 64);
  }

  /// Chunks `(header, list)` pairs into groups of [_maxStackedHeaders].
  ///
  /// A `SliverMainAxisGroup` scopes its pins to itself, so a group
  /// scrolls its headers off as the next one arrives — the pins stack
  /// WITHIN a chunk and release between them. That is the cap, and it
  /// costs one wrapper per chunk rather than a scroll listener.
  List<Widget> _capStacking(List<Widget> slivers) {
    final cap = _maxStackedHeaders;
    final pairs = slivers.length ~/ 2;
    if (pairs <= cap) return slivers;
    final out = <Widget>[];
    for (var i = 0; i < pairs; i += cap) {
      final end = (i + cap) * 2 > slivers.length
          ? slivers.length
          : (i + cap) * 2;
      out.add(SliverMainAxisGroup(slivers: slivers.sublist(i * 2, end)));
    }
    return out;
  }

  /// Wraps `child` in the shared [GlobalEdgeFade] when the configured
  /// [EdgeFadeStyle] is enabled. Used by both static and async
  /// branches so the same effect applies regardless of mode.
  ///
  /// The list used to carry its own PRIVATE copy of the fade — the
  /// four modes, the three painters, the scroll listener — six
  /// hundred lines duplicating `scrollable/`. The grid was already
  /// using the shared one, so the same `EdgeFadeStyle` drew two
  /// different edges depending on which widget you handed it to.
  Widget _maybeWrapEdgeFade(Widget child) {
    // The RESOLVED bag decides whether there is a band at all, so a
    // fade set app-wide reaches the list; the UNRESOLVED one is what
    // `GlobalEdgeFade` is handed, because it resolves its own.
    if (_rs.scrollable.edgeFade.isOff) return child;
    return GlobalEdgeFade(
      style: _callerStyle.scrollable?.edgeFade,
      axis: widget.scrollDirection,
      controller: _scrollCtrl,
      child: child,
    );
  }

  /// Wraps `child` in a Stack overlaying the scroll-to-top button +
  /// scroll progress strip when those flags are on. Both overlays
  /// sit ABOVE the edge fade so they remain visible (fade ends at
  /// viewport edges, overlays sit on top).
  Widget _maybeWrapOverlays(Widget child) {
    // The bag answers whether the chrome is there; the widget's own
    // flags still win when a caller set them, and the axis has the
    // last word — a scroll-to-top button on a horizontal strip points
    // the wrong way.
    final needsFab =
        _rs.scrollable.showScrollToTop &&
        widget.scrollDirection == Axis.vertical;
    final needsProgress = _rs.scrollable.showScrollProgress;
    final needsNewFab =
        widget.showNewItemFab && widget.scrollDirection == Axis.vertical;
    if (!needsFab && !needsProgress && !needsNewFab) return child;
    return GlobalScrollOverlays(
      controller: _scrollCtrl,
      axis: widget.scrollDirection,
      style: (_callerStyle.scrollable ?? const ScrollableStyle()).copyWith(
        // The AXIS has the last word: a scroll-to-top button on a
        // horizontal strip points the wrong way.
        showScrollToTop: needsFab,
        showScrollProgress: needsProgress,
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
      child: child,
    );
  }

  /// `PageStorageKey` to persist scroll offset across navigation, or
  /// null when no `restorationId` is configured.
  Key? get _storageKey => widget.restorationId == null
      ? null
      : PageStorageKey<String>(widget.restorationId!);

  // ─── Async-mode scroll view ────────────────────────────────

  Widget _buildScrollView(
    BuildContext context,
    GlobalListController<T> ctrl,
    GlobalListPhase phase,
  ) {
    // Full-area state widgets (initial load / empty / error) render
    // via SliverFillRemaining so they centre inside the scrollable
    // area while preserving pull-to-refresh on top.
    if (phase == GlobalListPhase.initial) {
      return _wrapInScrollView(_buildInitialLoading(context));
    }
    if (phase == GlobalListPhase.error && ctrl.items.isEmpty) {
      return _wrapInScrollView(
        _buildError(context, ctrl.error!, ctrl.retry),
      );
    }
    if (phase == GlobalListPhase.empty) {
      return _wrapInScrollView(_buildEmpty(context));
    }

    final items = _filterItems(ctrl.items);
    _renderedItems = items;
    _renderedCount = items.length;
    final padding = _rs.padding ?? EdgeInsets.zero;
    final grouped =
        widget.groupBy != null &&
        widget.groupHeaderBuilder != null &&
        !widget.reorderable;
    final itemSlivers = grouped
        ? _buildGroupedSlivers(context, items, padding)
        : [
            SliverPadding(
              padding: padding,
              sliver: _buildItemsSliver(context, items),
            ),
          ];
    return CustomScrollView(
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
        // Pagination tail: spinner / manual button / nothing.
        SliverToBoxAdapter(child: _buildPaginationTail(context, ctrl)),
        if (widget.footerBuilder != null)
          SliverToBoxAdapter(child: widget.footerBuilder!(context)),
      ],
    );
  }

  /// Builds the items sliver, switching between reorderable and
  /// plain depending on [GlobalList.reorderable]. Reorderable mode
  /// uses [SliverReorderableList] so it composes cleanly inside
  /// [CustomScrollView] alongside header slivers + tail.
  Widget _buildItemsSliver(BuildContext context, List<T> items) {
    if (widget.reorderable &&
        widget.swapMode &&
        widget.scrollDirection == Axis.vertical) {
      // Drop-swap path: each row wraps in LongPressDraggable +
      // DragTarget. Drop fires onReorder w/ swap semantics. Caller
      // mutates items[from] <-> items[to]. No live shifts —
      // intermediate rows untouched.
      return SliverList.builder(
        itemCount: items.length,
        itemBuilder: (ctx, i) => _ListSwapCell(
          index: i,
          itemId: identityHashCode(items[i]),
          findIndexById: (id) => _findItemIndexById(items, id),
          live: widget.swapLive,
          duration: _rs.animationDuration,
          onDropSwap: (from, to) {
            _reorderFeedback();
            widget.onReorder?.call(from, to);
          },
          onLiveHover: _hoverListSwap,
          onDragBegin: _beginListSwap,
          onDragEnd: _endListSwap,
          onDragUpdate: _onSwapPointer,
          child: _wrapItem(ctx, widget.itemBuilder(ctx, items[i], i), i),
        ),
      );
    }
    if (widget.reorderable && widget.scrollDirection == Axis.vertical) {
      return SliverReorderableList(
        itemCount: items.length,
        onReorderItem: (from, to) {
          _reorderFeedback();
          widget.controller.reorder(from, to);
        },
        // Custom proxy decorator that ELIMINATES the default fade /
        // shadow animation. The default proxy lingers at the drop
        // site as it fades, while the underlying items have already
        // shuffled — that's the "flash" of old positions. Returning
        // the bare child makes the proxy snap away cleanly.
        proxyDecorator: (child, index, animation) => Material(
          type: MaterialType.transparency,
          child: child,
        ),
        itemBuilder: (ctx, i) {
          // SliverReorderableList requires each item to carry a
          // unique [Key] so it can track drag identity. The drag
          // proxy renders OUTSIDE the surrounding scaffold so we
          // wrap the item in a transparent [Material] — otherwise
          // [ListTile] / ink-painting children crash with
          // "No Material widget found" while being dragged.
          // Keys MUST be identity-stable across reorders. Earlier
          // version XOR'd with index → key changed on every swap →
          // SliverReorderableList saw items as "new", remounted
          // widgets, and the old layout flashed for one frame before
          // settling. identityHashCode gives a stable key that moves
          // with the item, not the slot.
          final keyed = Material(
            key: ValueKey<int>(identityHashCode(items[i])),
            type: MaterialType.transparency,
            child: _wrapItem(ctx, widget.itemBuilder(ctx, items[i], i), i),
          );
          if (widget.reorderMode == ReorderMode.longPressAnywhere) {
            return ReorderableDelayedDragStartListener(
              key: ValueKey<int>(identityHashCode(items[i]) ^ 0x1),
              index: i,
              child: keyed,
            );
          }
          return keyed;
        },
      );
    }
    if (widget.animateChanges) {
      return SliverAnimatedList(
        key: _animatedKey,
        initialItemCount: items.length,
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
    if (widget.separatorBuilder != null) {
      return SliverList.separated(
        itemCount: items.length,
        itemBuilder: (ctx, i) =>
            _wrapItem(ctx, widget.itemBuilder(ctx, items[i], i), i),
        separatorBuilder: widget.separatorBuilder!,
      );
    }
    return SliverList.builder(
      itemCount: items.length,
      itemBuilder: (ctx, i) => _wrapWithSpacing(
        _wrapItem(ctx, widget.itemBuilder(ctx, items[i], i), i),
        i,
        items.length,
      ),
    );
  }

  /// Aggregates all item-level wrappers (keyboard focus, visibility
  /// tracking, secondary-tap context menu). Called once per item by
  /// each sliver builder so they share consistent behavior.
  /// A row landing in its new place is worth a tap on the wrist —
  /// it is the one gesture in the list where the finger has left the
  /// thing it moved and the eye may be elsewhere.
  void _reorderFeedback() {
    if (_rs.enableHaptic) HapticFeedback.selectionClick();
  }

  /// One key per item in a fitted horizontal strip, and the height
  /// the strip settled on.
  final List<GlobalKey> _fitKeys = [];
  double? _fitHeight;

  /// Whether a measurement is already queued for after this frame.
  bool _fitMeasureQueued = false;

  /// The rows this build is showing, filtered.
  ///
  /// Stashed once per build because `_wrapItem` needs to look an item
  /// up by index and used to re-filter the WHOLE list to do it — an
  /// O(n) walk and a fresh list allocation per row, so O(n²) per
  /// build on any list with selection on.
  List<T> _renderedItems = const [];

  /// How many rows are on screen for this build.
  ///
  /// `unifyTiles` needs to know which row is LAST, and on a paginated
  /// list that is the last row of the page you are on — the bottom the
  /// reader can actually see.
  int _renderedCount = 0;

  /// A horizontal strip sized to its TALLEST item.
  ///
  /// A `Row` inside a `SingleChildScrollView` takes the height of the
  /// tallest child, which a viewport never can — a viewport is handed
  /// its cross-axis extent by its parent. The cost is that every item
  /// is built: right for a strip of cards, wrong for a thousand, which
  /// is why `fitCrossAxis` is opt-in and says so.
  Widget _buildFitted(BuildContext context) {
    final items = _filterItems(widget._staticItems!);
    _renderedItems = items;
    _renderedCount = items.length;
    final toVisible = _rs.crossAxisFit == ListCrossAxisFit.tallestVisible;
    final spacing = _rs.itemSpacing;

    // One key per item, kept across builds so a measurement survives
    // the rebuild it triggers.
    if (_fitKeys.length != items.length) {
      _fitKeys
        ..clear()
        ..addAll(List.generate(items.length, (_) => GlobalKey()));
      _fitHeight = null;
    }

    final children = <Widget>[];
    for (var i = 0; i < items.length; i++) {
      if (i > 0) {
        if (widget.separatorBuilder != null) {
          children.add(widget.separatorBuilder!(context, i - 1));
        } else if (spacing > 0) {
          children.add(SizedBox(width: spacing));
        }
      }
      children.add(
        KeyedSubtree(
          key: _fitKeys[i],
          child: _wrapItem(
            context,
            widget.itemBuilder(context, items[i], i),
            i,
          ),
        ),
      );
    }

    final row = Row(
      // STRETCH for the whole-list fit, START for the visible one.
      //
      // Stretching makes every cell as tall as the row, which is what
      // you want when the row's height is fixed — but it would also
      // make every measurement equal to the row, and the visible fit
      // measures its children to decide that height. That is a loop:
      // the row would only ever agree with itself.
      crossAxisAlignment: toVisible
          ? CrossAxisAlignment.start
          : CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: children,
    );

    if (toVisible) {
      // After EVERY build, not just the first: the strip swaps an
      // `IntrinsicHeight` for a fixed height once it has an answer,
      // and that swap changes what there is to measure.
      _queueVisibleFit();
    }

    final scroller = SingleChildScrollView(
      key: _storageKey,
      scrollDirection: Axis.horizontal,
      controller: _scrollCtrl,
      physics: _effectivePhysics,
      padding: _rs.padding,
      child: row,
    );

    return _maybeWrapKeyboardScope(
      _maybeWrapEdgeFade(
        toVisible
            // Until the first measurement lands, the tallest of ALL of
            // them is the safe answer: it can only shrink from there,
            // and shrinking animates. Growing out of nothing would
            // start every strip with a jump.
            ? AnimatedContainer(
                duration: _rs.animationDuration,
                curve: Curves.easeOutCubic,
                height: _fitHeight,
                // It CLIPS, and it has to. The strip animates toward
                // the tallest card on screen, so for the length of
                // that animation it is shorter than that card by
                // definition — and a card wrapping onto another line
                // grows a frame before the measurement catches it.
                // Without this the strip throws an overflow on the
                // way to being right.
                clipBehavior: Clip.hardEdge,
                decoration: const BoxDecoration(),
                child: _fitHeight == null
                    ? IntrinsicHeight(child: scroller)
                    // The strip's height must NOT reach the cards.
                    //
                    // Handing them a bounded height shorter than they
                    // need makes each one overflow its own column —
                    // and it is shorter by definition while the
                    // animation is running, and again for the frame
                    // after a card wraps onto another line. The
                    // `OverflowBox` lets them lay out at whatever
                    // height they want; the clip above decides how
                    // much of that is seen.
                    : OverflowBox(
                        alignment: Alignment.topCenter,
                        maxHeight: double.infinity,
                        child: scroller,
                      ),
              )
            // `IntrinsicHeight` is what turns the row's height into
            // the scroll view's: a horizontal viewport otherwise takes
            // every point of cross-axis space its parent will give it,
            // which on a page is the whole page.
            : IntrinsicHeight(child: scroller),
      ),
    );
  }

  /// Queues a measurement for AFTER the next frame.
  ///
  /// A scroll listener fires when the offset changes and before the
  /// frame that moves anything — so measuring there reads the
  /// positions from the LAST layout. During a flick that is a whole
  /// frame behind, and the strip sizes itself to cards that have
  /// already left. One pending measurement at a time; a burst of
  /// scroll ticks is still one answer.
  void _queueVisibleFit() {
    if (_fitMeasureQueued) return;
    _fitMeasureQueued = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fitMeasureQueued = false;
      _measureVisibleFit();
    });
  }

  /// Measures the items that are ON SCREEN and takes the tallest.
  ///
  /// Runs after every frame the strip is in and on every scroll tick.
  /// Cheap because the row is already laid out — this reads sizes that
  /// exist rather than causing any.
  void _measureVisibleFit() {
    if (!mounted || _rs.crossAxisFit != ListCrossAxisFit.tallestVisible) {
      return;
    }
    final viewport = context.findRenderObject();
    if (viewport is! RenderBox || !viewport.attached) return;
    final width = viewport.size.width;
    if (width <= 0) return;

    var tallest = 0.0;
    for (final key in _fitKeys) {
      final box = key.currentContext?.findRenderObject();
      if (box is! RenderBox || !box.attached) continue;
      final left = box.localToGlobal(Offset.zero, ancestor: viewport).dx;
      final right = left + box.size.width;
      // Anything overlapping the viewport at all counts — a card half
      // on screen is half on screen, and clipping it would be worse
      // than making room.
      if (right <= 0 || left >= width) continue;
      // The INTRINSIC height, not the laid-out one.
      //
      // A cell fills whatever the row gives it — an `Align` expands,
      // a stretched child is stretched — so its size is the row's
      // height, and measuring that to decide the row's height is a
      // loop that only ever agrees with itself. What the card would
      // ask for is the question, and intrinsics answer it whatever
      // the current layout says.
      final height = box.getMaxIntrinsicHeight(box.size.width);
      if (height.isFinite && height > tallest) tallest = height;
    }
    if (tallest <= 0) return;
    // The list's OWN padding sits inside the scroll view, above and
    // below the row — so the content is that much taller than the
    // tallest card, and a height that counted only the card clipped
    // every one of them by exactly the padding. Which looked like the
    // strip following the leading card rather than the tallest.
    tallest += (_rs.padding ?? EdgeInsets.zero)
        .resolve(Directionality.of(context))
        .vertical;
    // A hair of tolerance: sub-pixel drift would otherwise animate the
    // strip on every frame of every scroll.
    if (_fitHeight != null && (_fitHeight! - tallest).abs() < 0.5) return;
    setState(() => _fitHeight = tallest);
  }

  /// Rounds the RUN rather than each row.
  ///
  /// The first row keeps its top corners, the last its bottom ones,
  /// and everything between is square — so a list reads as one card
  /// with rules through it rather than a stack of separate ones. A
  /// single row keeps both.
  Widget _unifyCorners(Widget child, int index) {
    // A SCOPE, not a clip. Clipping to a square rectangle removes
    // nothing: the tile's own rounded background is already inside
    // it, so every row kept its corner and the run never joined up.
    // The corner has to reach the container that PAINTS it.
    return ContainerCornerScope(
      borderRadius: cornersFor(index),
      child: child,
    );
  }

  /// The corner the row at [index] should round to when the run is
  /// unified: the first keeps its top, the last its bottom, a lone row
  /// keeps both, everything between is square.
  @visibleForTesting
  BorderRadius cornersFor(int index) {
    final radius = _rs.tileRadius;
    // GROUPED lists have a header above every run, including the
    // first — so no row is ever the top of the card, and a rounded
    // first row leaves two notches under the header it sits beneath.
    final grouped = widget.groupBy != null && widget.groupHeaderBuilder != null;
    final isFirst = !grouped && index == 0;
    final isLast = index == _renderedCount - 1;
    return BorderRadius.only(
      topLeft: isFirst ? radius.topLeft : Radius.zero,
      topRight: isFirst ? radius.topRight : Radius.zero,
      bottomLeft: isLast ? radius.bottomLeft : Radius.zero,
      bottomRight: isLast ? radius.bottomRight : Radius.zero,
    );
  }

  Widget _wrapItem(BuildContext ctx, Widget child, int index) {
    var w = child;
    if (_rs.unifyTiles) w = _unifyCorners(w, index);
    w = _maybeWrapSwipe(ctx, w, index);
    w = _maybeWrapSelectTap(w, index);
    final selection = widget.selection;
    if (selection != null && selection.mode != SelectionMode.none) {
      final items = _renderedItems;
      if (index >= 0 && index < items.length) {
        // A selected row LOOKS different and said nothing. `selected`
        // merges into whatever node the caller's builder already
        // makes, so a reader hears "selected" alongside the row's own
        // label rather than instead of it.
        w = Semantics(selected: selection.isSelected(items[index]), child: w);
      }
    }
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
      w = _VisibilityNotifier(
        index: index,
        seen: _seenIndices,
        onVisible: widget.onItemVisible!,
        child: w,
      );
    }
    w = _maybeWrapKeyboard(w, index);
    if (widget.scrollInAnimation != null) {
      w = GlobalScrollInAnimator(
        key: ValueKey<String>('lscroll_in_${identityHashCode(this)}_$index'),
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

  /// Whether the MODULE turns a tap on a row into a selection — which
  /// is what makes an otherwise inert row worth a focus stop.
  bool get _selectionIsInteractive =>
      widget.selectOnTap &&
      widget.selection != null &&
      widget.selection!.mode != SelectionMode.none;

  /// Selects [index], the way a file manager does.
  ///
  /// Public so a caller that draws its own row chrome can drive the
  /// same behaviour without re-implementing the anchor.
  /// [extend] and [keepAnchor] default to READING THE KEYBOARD — so a
  /// caller's own control (a checkbox in the row, say) gets Shift and
  /// Ctrl/Cmd for free and behaves like the row it sits in. Pass them
  /// explicitly to decide without it.
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

  /// Turns a global position into the index of the row under it, by
  /// hit-testing for the marker every row carries.
  ///
  /// The alternative — deriving the index from the scroll offset —
  /// needs every row to be the same height, which a list does not
  /// promise.
  int? _rowIndexAt(Offset globalPosition) {
    final box = _rowsKey.currentContext?.findRenderObject();
    if (box is! RenderBox) return null;
    final result = BoxHitTestResult();
    box.hitTest(result, position: box.globalToLocal(globalPosition));
    for (final entry in result.path) {
      final target = entry.target;
      if (target is RenderMetaData) {
        final meta = target.metaData;
        if (meta is _RowIndex) return meta.index;
      }
    }
    return null;
  }

  /// Starts a drag-paint, and the auto-scroll that lets it reach past
  /// the rows currently on screen.
  ///
  /// Without it the range stopped at whatever was rendered — a finger
  /// at the bottom edge held there forever and nothing more was ever
  /// selected, which is the one moment a reader expects a list to
  /// carry on by itself.
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
      // Re-run the hit test after each scrolling tick, so the range
      // keeps growing over the rows that scroll INTO the finger.
      ..onTick = () {
        final at = _autoScroll.pointerGlobal;
        if (at != null) _onDragSelectUpdate(at);
      }
      ..startWithController(this, _scrollCtrl);
  }

  /// Where the finger is now. Fed by the list's own `Listener`, so it
  /// keeps arriving after the starting row has scrolled away.
  void _onDragSelectMove(Offset globalPosition) {
    if (_dragSelectAnchor == null) return;
    // The scroller needs this even on a frame the finger did not move:
    // once the list is scrolling under it, a still finger is over a
    // new row every tick.
    _autoScroll.pointerGlobal = globalPosition;
    _onDragSelectUpdate(globalPosition);
  }

  void _endDragSelect() {
    if (_dragSelectAnchor == null) return;
    _dragSelectAnchor = null;
    _autoScroll
      ..onTick = null
      ..stop();
  }

  void _onDragSelectUpdate(Offset globalPosition) {
    final anchor = _dragSelectAnchor;
    if (anchor == null) return;
    final index = _rowIndexAt(globalPosition);
    if (index == null) return;
    final selection = widget.selection;
    if (selection == null || selection.mode != SelectionMode.multi) return;
    selection.selectRange(anchor, index, _renderedItems);
  }

  /// Clears the open pane as soon as the list moves. A row still open
  /// above the fold is one the reader has forgotten about, and it
  /// will act on their next tap.
  void _closeSwipeOnScroll() {
    if (_openSwipeRow.value != null) _openSwipeRow.value = null;
  }

  /// Gives the row the tap and the long-press that drive selection,
  /// and marks it with its index so a drag can find it.
  Widget _maybeWrapSelectTap(Widget child, int index) {
    if (!widget.selectOnTap) return child;
    final selection = widget.selection;
    if (selection == null || selection.mode == SelectionMode.none) {
      return child;
    }
    // One gesture cannot be two things: a caller who asked for a
    // context menu keeps it, and loses only the drag-paint.
    final canDragSelect =
        widget.onItemContextMenu == null &&
        selection.mode == SelectionMode.multi;
    return MetaData(
      metaData: _RowIndex(index),
      // TRANSLUCENT so the marker is hit even where the row paints
      // nothing, and so the row's own taps still land.
      behavior: HitTestBehavior.translucent,
      // A BUILDER, so the tap can reach the row's own focus node —
      // `_maybeWrapKeyboard` wraps this, so the nearest `Focus`
      // ancestor from in here is this row's stop.
      child: Builder(
        builder: (rowCtx) => GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTap: () {
            // A tap MOVES the focus, which is not stealing: the reader
            // aimed at this row. It is also what makes Shift+arrow work
            // from there — the shortcut lives above the row's stop and
            // only sees keys while one of them has focus.
            Focus.maybeOf(rowCtx)?.requestFocus();
            selectAt(index);
          },
          onLongPressStart: canDragSelect
              ? (d) => _beginDragSelect(index, d.globalPosition)
              : null,
          // No move or end handler here on purpose: the LIST owns
          // both, and outlives the row.
          onLongPressCancel: canDragSelect ? _endDragSelect : null,
          child: child,
        ),
      ),
    );
  }

  /// Puts a pane of actions behind the row when the caller offers
  /// any for this item.
  ///
  /// Innermost of the wrappers, so the pane slides the row the caller
  /// built and nothing else: the selection semantics, the keyboard
  /// stop and the entrance animation all stay put while it moves.
  Widget _maybeWrapSwipe(BuildContext ctx, Widget child, int index) {
    final builder = widget.swipeActions;
    if (builder == null) return child;
    // A horizontal list has no spare axis — the drag that would open
    // a pane is the one that scrolls it.
    if (widget.scrollDirection != Axis.vertical) return child;
    final items = _renderedItems;
    if (index < 0 || index >= items.length) return child;
    final actions = builder(ctx, items[index], index);
    if (actions == null || actions.isEmpty) return child;
    return GlobalSwipeRow(
      // Keyed by the ITEM, so a row that moves takes its open pane
      // with it rather than handing it to whoever inherits the index.
      rowId: identityHashCode(items[index]),
      openRow: _openSwipeRow,
      actions: actions,
      actionExtent: _rs.swipeActionExtent,
      fullSwipeThreshold: _rs.swipeFullSwipeThreshold,
      enableHaptic: _rs.enableHaptic,
      // Zero under reduced motion — the row snaps rather than glides.
      settleDuration: _rs.animationDuration,
      child: child,
    );
  }

  /// Wraps `child` in a [FocusableActionDetector] so keyboard focus
  /// can traverse items. Enter / Space invokes [onItemActivate];
  /// arrow keys are handled by the [FocusTraversalGroup] wrapping
  /// the entire list.
  ///
  /// It does NOT autofocus. A list that takes focus the moment it is
  /// built steals it from whatever the reader was on, and every row
  /// recycled into index 0 by scrolling took it again. `Tab` reaches
  /// row 0 on its own, and [focus] is there for a caller that wants
  /// to put the cursor in the list deliberately.

  /// Scrolls a focused row into view WITHOUT moving the page.
  ///
  /// `Scrollable.ensureVisible` reveals the target in every scrollable
  /// ancestor, so focusing a row inside a list inside a page dragged
  /// the whole page to it — which is what a reader sees as the list
  /// grabbing the screen. This moves the ONE viewport the list owns.
  /// Which row is showing a focus RING — not which has focus. A tap
  /// moves focus and shows nothing; a key press lights it up.
  int? _ringIndex;

  /// The context of the row that holds focus, so the reveal can run
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
      // The RING follows the highlight mode, not the focus.
      //
      // A tap moves focus — deliberately, so Shift+arrow can carry on
      // from the row the reader hit — but a finger has no focus ring
      // to see. `hasPrimaryFocus` cannot tell a tap from a Tab;
      // `onShowFocusHighlight` is Flutter's own answer to exactly
      // that, and it flips back on the first key press.
      onShowFocusHighlight: (show) {
        if (_ringIndex == index && show) return;
        if (!show && _ringIndex != index) return;
        _ringIndex = show ? index : null;
        _safeSetState();
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
          // The ring goes AROUND the row, not on its edge, and it
          // rounds to the same corner token `GlobalContainer` does.
          // It was a hard-coded radius of 8 drawn on the row's own
          // bounds, so the app's tiles — which round further — painted
          // over it and every corner bled.
          return Padding(
            padding: EdgeInsets.all(_rs.focusRingInset),
            child: DecoratedBox(
              // FOREGROUND. A `DecoratedBox` paints behind its child
              // by default, so the row's own opaque background covered
              // the ring's straight edges and left only the four
              // corners peeking out where the rounding leaves a gap —
              // which is exactly what it looked like.
              position: DecorationPosition.foreground,
              decoration: BoxDecoration(
                border: hasFocus
                    ? Border.all(
                        color: _rs.focusRingColor,
                        width: _rs.focusRingWidth,
                      )
                    : null,
                // The SAME corner the row itself rounds to. A
                // uniformly rounded ring around a unified run cut
                // across the square edges of every middle row.
                borderRadius: _rs.unifyTiles
                    ? cornersFor(index)
                    : _rs.focusRingRadius,
              ),
              child: child,
            ),
          );
        },
      ),
    );
  }

  /// Wraps `centerChild` in a scroll view with header slivers so
  /// pull-to-refresh keeps working on empty / loading / error
  /// states.
  Widget _wrapInScrollView(Widget centerChild) {
    // `SliverFillRemaining(hasScrollBody: false)` crashes any time
    // an ancestor queries intrinsic dimensions (common when nested
    // in `Column(mainAxisSize.min)` or shrink-wrapped lists). Skip
    // the scroll wrapper for empty / loading / error states. Pull-
    // to-refresh on empty states is the tradeoff — caller can
    // swipe-to-retry once items exist.
    if (widget.headerSlivers.isEmpty) {
      return Center(child: centerChild);
    }
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

  // ─── State widgets ─────────────────────────────────────────

  Widget _buildInitialLoading(BuildContext context) {
    if (widget.loadingBuilder != null) {
      return widget.loadingBuilder!(context);
    }
    if (widget.skeletonBuilder != null) {
      return _SkeletonStrip(
        axis: widget.scrollDirection,
        count: widget.controller.pageSize,
        itemBuilder: widget.skeletonBuilder!,
      );
    }
    // Default loading state: a strip of GlobalShimmer list-tile rows
    // instead of a generic spinner. Keeps the visual rhythm of an
    // actual list while content streams in.
    return _SkeletonStrip(
      axis: widget.scrollDirection,
      count: widget.controller.pageSize.clamp(3, 8),
      itemBuilder: (ctx, i) =>
          _DefaultShimmerTile(axis: widget.scrollDirection),
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
      icon: Icons.inbox_outlined,
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

  Widget _buildError(
    BuildContext context,
    Object error,
    VoidCallback retry,
  ) {
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
        // When a skeleton item builder is provided, use a single
        // skeleton row at the tail instead of a generic spinner —
        // visually consistent with the rest of the list.
        if (widget.skeletonBuilder != null) {
          return widget.skeletonBuilder!(context, 0);
        }
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Center(child: _spinner(context)),
        );
      case PaginationStyle.manualButton:
        if (!ctrl.hasMore) return const SizedBox.shrink();
        if (ctrl.isLoadingMore) {
          // While the next page is in flight, render a skeleton row
          // (same chrome used elsewhere in the list) instead of a
          // bare spinner.
          return widget.skeletonBuilder?.call(context, 0) ??
              _DefaultShimmerTile(axis: widget.scrollDirection);
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
    final style = widget.paginationStyle;
    if (style != PaginationStyle.numbered &&
        style != PaginationStyle.compactNumbered) {
      return null;
    }
    final total = ctrl.totalPages;
    if (total == null || total <= 1) return null;
    return _PaginationBar(
      style: style,
      currentPage: ctrl.currentPage,
      totalPages: total,
      onChanged: ctrl.goToPage,
      barStyle: _rs,
    );
  }

  // ─── Helpers ───────────────────────────────────────────────

  Widget _wrapWithSpacing(Widget child, int i, int total) {
    final spacing = _rs.itemSpacing;
    if (spacing == 0 || i == total - 1) return child;
    return widget.scrollDirection == Axis.vertical
        ? Padding(
            padding: EdgeInsets.only(bottom: spacing),
            child: child,
          )
        : Padding(
            padding: EdgeInsets.only(right: spacing),
            child: child,
          );
  }

  Widget _spinner(BuildContext context) {
    return SizedBox(
      width: 28,
      height: 28,
      child: GlobalProgress.loading(
        type: ProgressType.circular,
        style: ProgressStyle(
          thickness: 2.5,
          color: _rs.loadingIndicatorColor,
        ),
      ),
    );
  }
}

// ───────────────────────────────────────────────────────────────
// Skeleton strip
// ───────────────────────────────────────────────────────────────

class _SkeletonStrip extends StatelessWidget {
  const _SkeletonStrip({
    required this.axis,
    required this.count,
    required this.itemBuilder,
  });

  final Axis axis;
  final int count;
  final IndexedWidgetBuilder itemBuilder;

  @override
  Widget build(BuildContext context) {
    final children = [
      for (var i = 0; i < count; i++) itemBuilder(context, i),
    ];
    final strip = axis == Axis.vertical
        ? Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: children,
          )
        : Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: children,
          );
    // Skeleton can intrinsically exceed bounded parents (eg. centered
    // loading slot w/ fixed height). Wrap in a non-scrollable
    // SingleChildScrollView so overflow clips silently instead of
    // throwing — same pattern grid skeleton uses.
    return SingleChildScrollView(
      scrollDirection: axis,
      physics: const NeverScrollableScrollPhysics(),
      child: strip,
    );
  }
}

// ───────────────────────────────────────────────────────────────
// Numbered pagination bar
// ───────────────────────────────────────────────────────────────

class _PaginationBar extends StatelessWidget {
  const _PaginationBar({
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
  final ResolvedListStyle barStyle;

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

  // Width of one page slot (button or ellipsis) — used to fit the
  // pagination symmetrically inside the available width.
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

/// Built-in shimmer placeholder used by [GlobalList] when no
/// `skeletonBuilder` is provided. Vertical lists render a list-tile-
/// shaped row (circle avatar + two text lines); horizontal lists
/// render a card-shaped placeholder.
class _DefaultShimmerTile extends StatelessWidget {
  const _DefaultShimmerTile({required this.axis});

  final Axis axis;

  @override
  Widget build(BuildContext context) {
    if (axis == Axis.horizontal) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
        child: GlobalShimmer.placeholder(
          width: 200,
          height: 124,
          // The TOKEN, not 12 — see the grid's placeholder.
          borderRadius: BorderRadius.circular(context.radii.md),
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          GlobalShimmer.circle(size: 40),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GlobalShimmer.text(width: 140, height: 12),
                const SizedBox(height: 6),
                GlobalShimmer.text(width: double.infinity, height: 10),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ───────────────────────────────────────────────────────────────
// Section header delegate (sticky group headers)
// ───────────────────────────────────────────────────────────────

/// Persistent-header delegate used by [GlobalList]'s grouped mode.
/// Keeps the same height across the pin lifecycle so the sticky
/// header doesn't jump as it engages / disengages.
class _SectionHeaderDelegate extends SliverPersistentHeaderDelegate {
  _SectionHeaderDelegate({required this.height, required this.child});

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
  bool shouldRebuild(_SectionHeaderDelegate old) =>
      old.height != height || old.child != child;
}

// ───────────────────────────────────────────────────────────────
// Bulk actions toolbar
// ───────────────────────────────────────────────────────────────

/// Wraps the toolbar in `AnimatedSize` so it collapses cleanly when
/// the selection drains to zero. Subscribes to the selection
/// controller so the wrapper rebuilds on toggle.
class _BulkActionsCollapser<T> extends StatefulWidget {
  const _BulkActionsCollapser({
    required this.selection,
    required this.child,
  });

  final ListSelectionController<T> selection;
  final Widget child;

  @override
  State<_BulkActionsCollapser<T>> createState() =>
      _BulkActionsCollapserState<T>();
}

class _BulkActionsCollapserState<T> extends State<_BulkActionsCollapser<T>> {
  @override
  void initState() {
    super.initState();
    widget.selection.addListener(_onChange);
  }

  @override
  void didUpdateWidget(_BulkActionsCollapser<T> old) {
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

/// Default bulk-actions toolbar — selection count + clear button +
/// action buttons. Override via [GlobalList.bulkActionsBuilder].
class _BulkActionsToolbar<T> extends StatelessWidget {
  const _BulkActionsToolbar({
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

// ───────────────────────────────────────────────────────────────
// Reorder handle (public — exported with the module barrel)
// ───────────────────────────────────────────────────────────────

/// Drag handle for [GlobalList] in `ReorderMode.handleOnly`. Wrap a
/// trailing icon (or any widget) with this — only the wrapped area
/// starts a reorder drag. Pass the item's `index` so the underlying
/// `ReorderableDragStartListener` can identify the drag source.
class GlobalListReorderHandle extends StatelessWidget {
  const GlobalListReorderHandle({
    super.key,
    required this.index,
    this.child,
  });

  final int index;

  /// Defaults to a `Icons.drag_handle_rounded` icon when null.
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    // Palette, not Material's scheme: a rebrand has to move a list.
    return ReorderableDragStartListener(
      index: index,
      child:
          child ??
          Icon(
            Icons.drag_handle_rounded,
            color: context.textColors.primary.withValues(alpha: 0.6),
          ),
    );
  }
}

// ───────────────────────────────────────────────────────────────
// Snap physics — items snap to multiples of [itemExtent]
// ───────────────────────────────────────────────────────────────

/// Custom physics that quantises rest-position to the nearest
/// multiple of [itemExtent]. Used when [GlobalList.snap] is on.
/// Inherits from [BouncingScrollPhysics] so overscroll still works.
class _SnapScrollPhysics extends ScrollPhysics {
  const _SnapScrollPhysics({required this.itemExtent, super.parent});

  final double itemExtent;

  @override
  _SnapScrollPhysics applyTo(ScrollPhysics? ancestor) {
    return _SnapScrollPhysics(
      itemExtent: itemExtent,
      parent: buildParent(ancestor),
    );
  }

  double _snap(double offset, double max) {
    if (itemExtent <= 0) return offset;
    final n = (offset / itemExtent).roundToDouble();
    return (n * itemExtent).clamp(0.0, max);
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
// Visibility notifier — fires onVisible once when item mounts
// ───────────────────────────────────────────────────────────────

/// Fires `onVisible(index)` exactly once per index, tracked via the
/// shared `seen` set. Built items are considered "visible" as soon
/// as Flutter constructs them inside the sliver — close enough to
/// real visibility for impressions / lazy loading; precise viewport
/// hit-testing would require a `RenderObject` listener.
class _VisibilityNotifier extends StatefulWidget {
  const _VisibilityNotifier({
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
  State<_VisibilityNotifier> createState() => _VisibilityNotifierState();
}

class _VisibilityNotifierState extends State<_VisibilityNotifier> {
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
// Search highlight (public — re-exported via the module barrel)
// ───────────────────────────────────────────────────────────────

/// Renders `text` with substrings matching `query` highlighted in
/// the supplied [highlightStyle] (defaults to `colorScheme.primary`
/// + bold). Case-insensitive. Use inside an item builder when the
/// list is wired to [GlobalList.showSearchBar].
class GlobalListSearchHighlight extends StatelessWidget {
  const GlobalListSearchHighlight({
    super.key,
    required this.text,
    required this.query,
    this.baseStyle,
    this.highlightStyle,
    this.maxLines,
    this.overflow,
  });

  final String text;
  final String query;
  final TextStyle? baseStyle;
  final TextStyle? highlightStyle;
  final int? maxLines;
  final TextOverflow? overflow;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // Resolved base style: caller's baseStyle wins; otherwise pull
    // bodyMedium from the active theme (correct fg color), and as a
    // last resort fall back to onSurface so the text is never invisible
    // against the surface (DefaultTextStyle inside slivers can be
    // unset / white).
    final resolvedBase =
        (baseStyle ?? theme.textTheme.bodyMedium ?? const TextStyle()).copyWith(
          color:
              baseStyle?.color ??
              theme.textTheme.bodyMedium?.color ??
              context.textColors.primary,
        );
    final hl =
        highlightStyle ??
        TextStyle(
          color: context.primaryColors.primary,
          fontWeight: FontWeight.w700,
        );
    if (query.isEmpty) {
      return Text(
        text,
        style: resolvedBase,
        maxLines: maxLines,
        overflow: overflow,
      );
    }
    final lowerText = text.toLowerCase();
    final lowerQuery = query.toLowerCase();
    final spans = <TextSpan>[];
    var start = 0;
    while (start < text.length) {
      final hit = lowerText.indexOf(lowerQuery, start);
      if (hit < 0) {
        spans.add(TextSpan(text: text.substring(start)));
        break;
      }
      if (hit > start) spans.add(TextSpan(text: text.substring(start, hit)));
      spans.add(
        TextSpan(text: text.substring(hit, hit + query.length), style: hl),
      );
      start = hit + query.length;
    }
    return RichText(
      text: TextSpan(style: resolvedBase, children: spans),
      maxLines: maxLines,
      overflow: overflow ?? TextOverflow.clip,
    );
  }
}

// ───────────────────────────────────────────────────────────────
// Search bar (public — shared by GlobalList and GlobalGrid)
// ───────────────────────────────────────────────────────────────

/// The built-in search bar rendered above [GlobalList] / `GlobalGrid`
/// when `showSearchBar` is on. Composes the sibling [GlobalTextFormField]
/// (clear button, semantics, RTL, `GlobalTextFieldTheme`) instead of a
/// raw `TextField`, and is shared by both widgets so their styling can't
/// drift apart.
class GlobalListSearchBar extends StatelessWidget {
  const GlobalListSearchBar({
    super.key,
    required this.controller,
    this.hint,
  });

  static const _kBarPadding = EdgeInsets.fromLTRB(12, 8, 12, 4);
  static const _kContentPadding = EdgeInsets.symmetric(
    horizontal: 12,
    vertical: 10,
  );
  static const _kIconPadding = EdgeInsetsDirectional.only(start: 12, end: 8);
  static const _kFieldRadius = 10.0;
  static const _kFillAlpha = 0.5;
  static const _kIconSize = 20.0;

  /// Controller owned by the surrounding list / grid state.
  final TextEditingController controller;

  /// Placeholder text. Falls back to [FieldStrings.searchHint].
  final String? hint;

  @override
  Widget build(BuildContext context) {
    // Palette, not Material's scheme: a rebrand has to move a list.
    return Padding(
      padding: _kBarPadding,
      child: GlobalTextFormField(
        controller: controller,
        hint: hint ?? FieldStrings.searchHint,
        style: TextFieldStyle(
          fillColor: context.backgroundColors.container.withValues(
            alpha: _kFillAlpha,
          ),
          borderRadius: BorderRadius.circular(_kFieldRadius),
          contentPadding: _kContentPadding,
        ),
        behavior: const TextFieldBehavior(
          textInputAction: TextInputAction.search,
        ),
        features: const TextFieldFeatures(showClearButton: true),
        slots: TextFieldSlots(
          prefixIcon: Padding(
            padding: _kIconPadding,
            child: Icon(
              Icons.search_rounded,
              size: _kIconSize,
              color: context.textColors.secondary,
            ),
          ),
        ),
        sizing: const TextFieldSizing(isDense: true),
      ),
    );
  }
}

/// Element of the numbered pagination bar — either a page number
/// or an ellipsis. Used by [_PaginationBar._computeSlots] to pick
/// what fits inside the available width without overflow.
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
// Drop-swap reorder cell — long-press drag, drop on target swaps
// the two rows. Drop-only (no live shifts) so DragTarget hit-test
// works without oscillation.
// ───────────────────────────────────────────────────────────────

class _ListSwapCell extends StatelessWidget {
  const _ListSwapCell({
    required this.index,
    required this.duration,
    required this.itemId,
    required this.findIndexById,
    required this.onDropSwap,
    required this.onLiveHover,
    required this.onDragBegin,
    required this.onDragEnd,
    required this.onDragUpdate,
    required this.live,
    required this.child,
  });

  final int index;
  final int itemId;

  /// Resolves the dragged item's current index by id. Used in drop
  /// mode for self-drop filtering.
  final int? Function(int id) findIndexById;

  /// Drop-mode swap. `from` is the dragged source index (current
  /// position via lookup), `to` is this cell's index.
  final void Function(int from, int to) onDropSwap;

  /// Live-mode hover — fires when the pointer enters this cell.
  final void Function(int targetIndex) onLiveHover;

  /// Always fired on drag start (both modes). State uses this to
  /// start the auto-scroller + capture the live-swap origin.
  final void Function(int sourceIndex) onDragBegin;

  /// Always fired on drag end / cancel.
  final VoidCallback onDragEnd;

  /// Pointer position feed for auto-scroll. Fires on every drag move.
  final void Function(Offset globalPointer) onDragUpdate;

  /// True = live hover routing. False = drop-only.
  final bool live;

  /// How long a cell takes to hand its contents to another.
  ///
  /// Zero under reduced motion, which is the whole point of taking it
  /// from the resolved bag rather than baking a number in here.
  final Duration duration;

  final Widget child;

  @override
  Widget build(BuildContext context) {
    // Palette, not Material's scheme: a rebrand has to move a list.
    return DragTarget<int>(
      onWillAcceptWithDetails: (d) => d.data != itemId,
      onAcceptWithDetails: live
          ? null
          : (d) {
              final from = findIndexById(d.data);
              if (from == null || from == index) return;
              onDropSwap(from, index);
            },
      onMove: live ? (d) => onLiveHover(index) : null,
      builder: (ctx, candidate, rejected) {
        final hovered = candidate.isNotEmpty;
        // A swap CHANGES what this cell holds, and nothing said so —
        // the two rows exchanged contents between one frame and the
        // next. Keyed by the item, so a cell whose item changed
        // cross-fades to the new one while its partner does the same.
        final swapped = duration == Duration.zero
            ? child
            : AnimatedSwitcher(
                duration: duration,
                switchInCurve: Curves.easeOutCubic,
                switchOutCurve: Curves.easeInCubic,
                layoutBuilder: (current, previous) => Stack(
                  alignment: Alignment.topLeft,
                  children: [...previous, if (current != null) current],
                ),
                child: KeyedSubtree(
                  key: ValueKey<int>(itemId),
                  child: child,
                ),
              );
        final framed = (!live && hovered)
            ? DecoratedBox(
                // FOREGROUND, for the same reason as the focus ring:
                // behind an opaque row this drew four corners rather
                // than an outline.
                position: DecorationPosition.foreground,
                decoration: BoxDecoration(
                  border: Border.all(
                    color: context.primaryColors.primary,
                    width: 2,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: swapped,
              )
            : swapped;
        return LongPressDraggable<int>(
          data: itemId,
          delay: const Duration(milliseconds: 200),
          onDragStarted: () => onDragBegin(index),
          onDragEnd: (_) => onDragEnd(),
          onDraggableCanceled: (_, _) => onDragEnd(),
          onDragUpdate: (d) => onDragUpdate(d.globalPosition),
          feedback: Material(
            color: Theme.of(ctx).scaffoldBackgroundColor,
            elevation: 0,
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(ctx).size.width,
              ),
              child: child,
            ),
          ),
          childWhenDragging: Opacity(opacity: 0.25, child: child),
          child: framed,
        );
      },
    );
  }
}

/// What a row carries so a drag can ask which row it is over.
///
/// A marker rather than arithmetic: deriving the index from the scroll
/// offset needs every row to be the same height, and a list does not
/// promise that.
@immutable
class _RowIndex {
  const _RowIndex(this.index);

  final int index;
}

/// Walks the keyboard cursor by one row and drags the selection with
/// it. Its own intent so `Shortcuts` can bind Shift+arrow without
/// shadowing the plain arrow's traversal.
@immutable
class _ExtendSelectionIntent extends Intent {
  const _ExtendSelectionIntent(this.delta);

  final int delta;
}
