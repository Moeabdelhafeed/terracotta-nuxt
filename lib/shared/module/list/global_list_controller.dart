import 'dart:async';

import 'package:flutter/foundation.dart';

import 'list_models.dart';

/// Fetch callback signature. The controller passes whichever of
/// `page` / `cursor` is relevant to its [PaginationMode]; the other
/// is null.
typedef GlobalListFetch<T> =
    Future<GlobalListPage<T>> Function({
      int? page,
      Object? cursor,
      required int pageSize,
    });

/// Pagination + fetch state for a [GlobalList]. Implements
/// [ChangeNotifier] so the widget rebuilds via [ListenableBuilder].
///
/// Owns: items, fetch flags (`isLoadingInitial` / `isLoadingMore` /
/// `isRefreshing`), error, paging cursor / page, total page count
/// (for numbered pagination), and the active page index when in
/// [PaginationStyle.numbered] mode.
class GlobalListController<T> extends ChangeNotifier {
  GlobalListController({
    required this.fetchPage,
    this.pageSize = 20,
    this.paginationMode = PaginationMode.page,
    this.initialPage = 1,
    this.totalPages,
  }) : _currentPage = initialPage;

  /// Caller-supplied page fetcher. Receives `page` (page mode) or
  /// `cursor` (cursor mode) + `pageSize`; returns one [GlobalListPage].
  final GlobalListFetch<T> fetchPage;

  /// Items per page. Default 20.
  final int pageSize;

  /// Page-based vs cursor-based pagination.
  final PaginationMode paginationMode;

  /// Starting page number (page mode).
  final int initialPage;

  /// Total number of pages for [PaginationStyle.numbered] /
  /// [PaginationStyle.compactNumbered] presentation. Null = unknown.
  final int? totalPages;

  // ─── State ─────────────────────────────────────────────────

  final List<T> _items = [];
  List<T> get items => List.unmodifiable(_items);

  bool _isLoadingInitial = false;
  bool _isLoadingMore = false;
  bool _isRefreshing = false;
  bool _hasMore = true;
  Object? _error;

  int _currentPage;
  Object? _nextCursor;

  /// True after [dispose] has been called. Late-arriving async work
  /// from in-flight fetches uses this to skip `notifyListeners()`.
  bool _disposed = false;

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  /// Safe wrapper around [notifyListeners] that drops the call when
  /// the controller has been disposed. Avoids `ChangeNotifier used
  /// after being disposed` crashes when the user navigates away
  /// mid-fetch.
  void _safeNotify() {
    if (_disposed) return;
    super.notifyListeners();
  }

  bool get isLoadingInitial => _isLoadingInitial;
  bool get isLoadingMore => _isLoadingMore;
  bool get isRefreshing => _isRefreshing;
  bool get hasMore => _hasMore;
  Object? get error => _error;
  int get currentPage => _currentPage;

  /// Snapshot of the controller's current presentational phase —
  /// what the widget renders right now.
  GlobalListPhase get phase {
    if (_error != null) return GlobalListPhase.error;
    if (_isLoadingInitial) return GlobalListPhase.initial;
    if (_isRefreshing) return GlobalListPhase.refreshing;
    if (_isLoadingMore) return GlobalListPhase.loadingMore;
    if (_items.isEmpty) return GlobalListPhase.empty;
    return GlobalListPhase.idle;
  }

  // ─── Public methods ────────────────────────────────────────

  /// First load. Idempotent — calling twice in quick succession
  /// returns the in-flight future on the second call.
  Future<void>? _initialFuture;
  Future<void> load() {
    if (_initialFuture != null) return _initialFuture!;
    return _initialFuture = _runInitialLoad();
  }

  Future<void> _runInitialLoad() async {
    _isLoadingInitial = true;
    _error = null;
    _safeNotify();
    try {
      final page = await _fetch(_currentPage, _nextCursor);
      _items
        ..clear()
        ..addAll(page.items);
      _hasMore = page.hasMore;
      _nextCursor = page.nextCursor;
    } catch (e) {
      _error = e;
    } finally {
      _isLoadingInitial = false;
      _initialFuture = null;
      _safeNotify();
    }
  }

  /// Pull-to-refresh: reset to the first page and reload.
  Future<void> refresh() async {
    _isRefreshing = true;
    _error = null;
    _safeNotify();
    try {
      _currentPage = initialPage;
      _nextCursor = null;
      final page = await _fetch(_currentPage, _nextCursor);
      _items
        ..clear()
        ..addAll(page.items);
      _hasMore = page.hasMore;
      _nextCursor = page.nextCursor;
    } catch (e) {
      _error = e;
    } finally {
      _isRefreshing = false;
      _safeNotify();
    }
  }

  /// Append the next page. No-op when already loading or no more
  /// pages remain.
  Future<void> loadMore() async {
    if (_isLoadingMore || !_hasMore || _isLoadingInitial) return;
    _isLoadingMore = true;
    _error = null;
    _safeNotify();
    try {
      final nextPage = _currentPage + 1;
      final page = await _fetch(nextPage, _nextCursor);
      _items.addAll(page.items);
      _hasMore = page.hasMore;
      _nextCursor = page.nextCursor;
      _currentPage = nextPage;
    } catch (e) {
      _error = e;
    } finally {
      _isLoadingMore = false;
      _safeNotify();
    }
  }

  /// Retry the last failed fetch. Picks initial-load vs load-more
  /// based on whether items are already present.
  Future<void> retry() {
    _error = null;
    _safeNotify();
    return _items.isEmpty ? load() : loadMore();
  }

  /// Jump to a specific page (numbered pagination). Replaces items.
  Future<void> goToPage(int page) async {
    if (page == _currentPage && _items.isNotEmpty) return;
    _isLoadingInitial = true;
    _error = null;
    _safeNotify();
    try {
      _currentPage = page;
      _nextCursor = null;
      final res = await _fetch(page, null);
      _items
        ..clear()
        ..addAll(res.items);
      _hasMore = res.hasMore;
      _nextCursor = res.nextCursor;
    } catch (e) {
      _error = e;
    } finally {
      _isLoadingInitial = false;
      _safeNotify();
    }
  }

  // ─── Item mutation helpers ─────────────────────────────────

  void addItem(T item, {int? at}) {
    if (at == null) {
      _items.add(item);
    } else {
      _items.insert(at.clamp(0, _items.length), item);
    }
    _safeNotify();
  }

  void removeItem(T item) {
    _items.remove(item);
    _safeNotify();
  }

  void removeAt(int index) {
    if (index < 0 || index >= _items.length) return;
    _items.removeAt(index);
    _safeNotify();
  }

  void replaceItem(int index, T item) {
    if (index < 0 || index >= _items.length) return;
    _items[index] = item;
    _safeNotify();
  }

  void clear() {
    _items.clear();
    _currentPage = initialPage;
    _nextCursor = null;
    _hasMore = true;
    _safeNotify();
  }

  /// Reorder helper for [ReorderableListView]-style `onReorderItem`
  /// callbacks. The framework now pre-adjusts `newIndex` for the
  /// removed item, so no manual `newIndex -= 1` is needed.
  void reorder(int oldIndex, int newIndex) {
    final item = _items.removeAt(oldIndex);
    _items.insert(newIndex, item);
    _safeNotify();
  }

  // ─── Internals ─────────────────────────────────────────────

  Future<GlobalListPage<T>> _fetch(int page, Object? cursor) {
    switch (paginationMode) {
      case PaginationMode.page:
        return fetchPage(page: page, pageSize: pageSize);
      case PaginationMode.cursor:
        return fetchPage(cursor: cursor, pageSize: pageSize);
    }
  }
}
