import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../data/blocs/search_history/search_history_cubit.dart';

/// Async-query signature. Returns the result list for a given query.
/// Throw to surface an error state.
typedef SearchQueryFn<T> = Future<List<T>> Function(String query);

/// Drop-in controller that adds debouncing, async-result state, and
/// persisted recent-search history on top of any text field.
///
/// Pair with `GlobalTextFormField` by listening to this controller
/// (it's a [ChangeNotifier]) and wiring:
///   * field `onChanged` → [onInput]
///   * field `onFieldSubmitted` → [submit]
///   * field `recentSearches` ← [recents]
///   * field `onRecentSearchDeleted` → [removeRecent]
///   * field `onRecentSearchesCleared` → [clearRecents]
///   * field `onSuggestionSelected` → [onRecentTapped]
///
/// Stale-query protection: an internal token advances on every fire.
/// Results from a query whose token has been superseded are dropped,
/// so the user only ever sees the latest-typed-query's results.
class GlobalSearchController<T> extends ChangeNotifier {
  GlobalSearchController({
    required this.searchId,
    required this.onQuery,
    required this.historyCubit,
    this.debounce = const Duration(milliseconds: 300),
    this.minLength = 1,
  });

  /// Stable identity used by [SearchHistoryCubit] to keep this
  /// bar's recents separate from any other bar in the app.
  final String searchId;

  /// Persisted-history source. Inject at call site — usually
  /// `historyCubit`.
  final SearchHistoryCubit historyCubit;

  /// Caller-supplied async query function. Called with the trimmed
  /// query when debounce settles.
  final SearchQueryFn<T> onQuery;

  /// Idle period after the last keystroke before [onQuery] fires.
  final Duration debounce;

  /// Minimum query length before [onQuery] is invoked. Shorter
  /// inputs clear results without firing.
  final int minLength;

  // ─── State ───────────────────────────────────────────────────

  String _query = '';
  List<T> _results = const [];
  bool _loading = false;
  Object? _error;
  Timer? _debounceTimer;
  int _queryToken = 0;

  /// Current input value (post-onInput, pre-debounce-fire).
  String get query => _query;

  /// Most recent result list emitted by [onQuery]. Cleared when the
  /// input drops below [minLength].
  List<T> get results => _results;

  bool get loading => _loading;
  Object? get error => _error;
  bool get hasResults => _results.isNotEmpty;
  bool get isIdle =>
      !_loading && _error == null && _results.isEmpty && _query.isEmpty;

  /// Persisted recent queries for this `searchId`, most-recent first.
  /// Reads via the singleton cubit so callers don't have to wire it.
  List<String> get recents => historyCubit.entriesFor(searchId);

  // ─── Mutations ───────────────────────────────────────────────

  /// Wire to your text field's `onChanged`. Resets the debounce
  /// timer + clears stale results when below [minLength].
  void onInput(String value) {
    _query = value;
    _debounceTimer?.cancel();
    if (value.trim().length < minLength) {
      _results = const [];
      _loading = false;
      _error = null;
      notifyListeners();
      return;
    }
    _debounceTimer = Timer(debounce, () => _fire(value));
  }

  /// Force-fire an immediate query, bypassing debounce. Also pushes
  /// the query into recents.
  Future<void> submit(String value) async {
    _debounceTimer?.cancel();
    _query = value;
    if (value.trim().isEmpty) return;
    historyCubit.add(searchId, value.trim());
    await _fire(value);
  }

  /// Called when the user picks a query from the recents list.
  /// Bumps it to the top of the history + re-runs the search.
  void onRecentTapped(String value) {
    submit(value);
  }

  /// Remove a single entry from recents (for swipe-delete UI).
  void removeRecent(String value) {
    historyCubit.remove(searchId, value);
    notifyListeners();
  }

  /// Clear the entire recents list for this `searchId`.
  void clearRecents() {
    historyCubit.clearFor(searchId);
    notifyListeners();
  }

  /// Reset to idle (cancels pending debounce, drops cached results).
  void clear() {
    _debounceTimer?.cancel();
    _query = '';
    _results = const [];
    _loading = false;
    _error = null;
    notifyListeners();
  }

  // ─── Internals ───────────────────────────────────────────────

  Future<void> _fire(String value) async {
    final token = ++_queryToken;
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      final out = await onQuery(value.trim());
      if (token != _queryToken) return; // stale
      _results = out;
      _loading = false;
      notifyListeners();
    } catch (e) {
      if (token != _queryToken) return;
      _error = e;
      _loading = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    super.dispose();
  }
}
