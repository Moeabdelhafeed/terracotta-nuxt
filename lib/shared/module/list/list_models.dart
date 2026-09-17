import 'package:flutter/material.dart';

// The edge fade belongs to whatever is SCROLLING, not to the list —
// the text field, the slider, the breadcrumbs and the dropdown were
// all importing this module just for it. Re-exported so a caller that
// says `list_models.dart` still finds the types.
export '../scrollable/scrollable_models.dart'
    show EdgeFadeMode, ListItemAnimation;
export '../scrollable/scrollable_style.dart' show EdgeFadeStyle;

/// One page returned by [GlobalListController.fetchPage]. Wraps the
/// items + a hint about whether more pages exist + the next cursor
/// for cursor-based pagination.
@immutable
class GlobalListPage<T> {
  const GlobalListPage({
    required this.items,
    this.hasMore = false,
    this.nextCursor,
  });

  final List<T> items;

  /// `true` when the backend signalled there are more pages. The
  /// list keeps paginating; `false` stops further fetches.
  final bool hasMore;

  /// Opaque next-page cursor (cursor-based pagination only).
  final Object? nextCursor;
}

/// How [GlobalListController] talks to the backend. Determines what
/// it passes to [GlobalListController.fetchPage] each call.
enum PaginationMode {
  /// `fetchPage(page: 1, pageSize: N)` style. Auto-increments
  /// `page` on each fetch.
  page,

  /// `fetchPage(cursor: <opaque>, pageSize: N)` style. Uses the
  /// previous page's [GlobalListPage.nextCursor] for the next call.
  cursor,
}

/// Presentational pagination strategy — purely visual, the
/// underlying controller state is identical across styles.
enum PaginationStyle {
  /// No pagination — load once, never call `loadMore`.
  none,

  /// Auto-fetch the next page when the scroll position passes the
  /// configured threshold. Tail spinner via `loadingMoreBuilder`.
  infiniteScroll,

  /// "Load more" button rendered at the tail. User taps to fetch.
  manualButton,

  /// Numbered page bar below the scroll view. Each page switch
  /// replaces the items (caller's `fetchPage` is called with the
  /// requested page).
  numbered,

  /// "Page N of M" compact bar with prev/next buttons.
  compactNumbered,
}

/// Selection mode — used by the optional [ListSelectionController].
enum SelectionMode { none, single, multi }

/// Internal state flavour exposed to the widget for switch logic.
enum GlobalListPhase {
  /// First fetch hasn't completed yet, no items rendered.
  initial,

  /// Items rendered, no async work in progress.
  idle,

  /// Pull-to-refresh in progress.
  refreshing,

  /// `loadMore()` in progress for the tail.
  loadingMore,

  /// No items in the active page AND not fetching.
  empty,

  /// Last fetch threw; [GlobalListController.error] is non-null.
  error,
}

/// Visual configuration for [GlobalList]. Per-call overrides on the
/// widget take precedence over style fields.
/// Call-to-action rendered below the default empty state, so an
/// empty list isn't a dead-end. Use `Compose`, `Add item`, etc.
@immutable
class GlobalEmptyAction {
  const GlobalEmptyAction({
    required this.label,
    required this.onPressed,
    this.icon,
  });

  final String label;
  final IconData? icon;
  final VoidCallback onPressed;
}

/// One action rendered in the bulk-actions toolbar that surfaces when
/// the [ListSelectionController] has at least one selected item.
/// Receives the current selection so the handler can act on it.
@immutable
class GlobalBulkAction<T> {
  const GlobalBulkAction({
    required this.icon,
    required this.label,
    required this.onPressed,
    this.color,
  });

  final IconData icon;
  final String label;
  final void Function(Set<T> selected) onPressed;

  /// Override colour — useful for destructive actions (`Colors.red`).
  final Color? color;
}

/// How sticky group headers behave when multiple sections are visible.
enum GroupHeaderMode {
  /// Each pinned header pins independently and they stack on top of
  /// each other as the user scrolls into a new section. Default.
  stack,

  /// Only the current section's header is shown — the previous
  /// section's header scrolls off as the next section enters via
  /// `SliverMainAxisGroup`.
  replace,

  /// Headers scroll with content (no pinning) — inline section
  /// dividers. Lighter than stack/replace.
  inline,
}

/// How an item starts a reorder drag.
enum ReorderMode {
  /// User long-presses anywhere on the item to start dragging. The
  /// widget wraps each item in `ReorderableDelayedDragStartListener`
  /// automatically.
  longPressAnywhere,

  /// Item is NOT auto-wrapped — the caller's `itemBuilder` must
  /// embed a `ReorderableDragStartListener` (e.g. via
  /// [GlobalListReorderHandle]) on the area that should start the
  /// drag.
  handleOnly,
}
