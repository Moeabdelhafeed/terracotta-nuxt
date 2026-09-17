import 'package:hydrated_bloc/hydrated_bloc.dart';

import 'search_history_state.dart';

/// Per-search-bar recent-query history. Keyed by `searchId` so any
/// number of search bars share the same store without colliding.
/// Most-recent first. Caps each list at [maxPerSearch] (oldest
/// evicted on push). Dedups on add — re-running an existing query
/// moves it to the top.
class SearchHistoryCubit extends HydratedCubit<SearchHistoryState> {
  SearchHistoryCubit({this.maxPerSearch = 8})
    : super(const SearchHistoryState());

  /// Maximum recent queries kept per `searchId`.
  final int maxPerSearch;

  // ─── Reads ───────────────────────────────────────────────────

  List<String> entriesFor(String searchId) =>
      List<String>.unmodifiable(state.entries[searchId] ?? const []);

  // ─── Writes ──────────────────────────────────────────────────

  void add(String searchId, String query) {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return;
    final current = List<String>.from(state.entries[searchId] ?? const []);
    current
      ..remove(trimmed)
      ..insert(0, trimmed);
    if (current.length > maxPerSearch) {
      current.removeRange(maxPerSearch, current.length);
    }
    final next = Map<String, List<String>>.from(state.entries);
    next[searchId] = current;
    emit(state.copyWith(entries: next));
  }

  void remove(String searchId, String query) {
    final current = state.entries[searchId];
    if (current == null || !current.contains(query)) return;
    final next = List<String>.from(current)..remove(query);
    final updated = Map<String, List<String>>.from(state.entries);
    if (next.isEmpty) {
      updated.remove(searchId);
    } else {
      updated[searchId] = next;
    }
    emit(state.copyWith(entries: updated));
  }

  void clearFor(String searchId) {
    if (!state.entries.containsKey(searchId)) return;
    final updated = Map<String, List<String>>.from(state.entries)
      ..remove(searchId);
    emit(state.copyWith(entries: updated));
  }

  void clearAll() =>
      emit(state.copyWith(entries: const <String, List<String>>{}));

  // ─── Hydrated serialization ──────────────────────────────────

  @override
  SearchHistoryState? fromJson(Map<String, dynamic> json) {
    try {
      return SearchHistoryState.fromJson(json);
    } catch (_) {
      return null;
    }
  }

  @override
  Map<String, dynamic>? toJson(SearchHistoryState state) => state.toJson();
}
