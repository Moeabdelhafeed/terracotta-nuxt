import 'package:freezed_annotation/freezed_annotation.dart';

part 'search_history_state.freezed.dart';
part 'search_history_state.g.dart';

/// Persisted search-query history, keyed by a caller-supplied
/// `searchId` so multiple search bars (e.g. products, contacts,
/// cities) keep separate lists.
@freezed
abstract class SearchHistoryState with _$SearchHistoryState {
  const factory SearchHistoryState({
    /// `{ searchId: [query, query, ...] }` — most-recent first.
    @Default(<String, List<String>>{}) Map<String, List<String>> entries,
  }) = _SearchHistoryState;

  factory SearchHistoryState.fromJson(Map<String, dynamic> json) =>
      _$SearchHistoryStateFromJson(json);
}
