/// Pure suggestion-filtering helpers. No Flutter dependency — the overlay
/// orchestration stays in the widget; only the list math lives here so it
/// is unit-testable.
class SuggestionFilter {
  const SuggestionFilter._();

  /// Case-insensitive `contains` filter, capped at [max]. Empty query
  /// returns the first [max] items unfiltered.
  static List<String> byQuery(List<String> items, String lowerQuery, int max) {
    final base = lowerQuery.isEmpty
        ? items
        : items.where((s) => s.toLowerCase().contains(lowerQuery));
    return base.take(max).toList();
  }

  /// Recent searches filtered by query (empty query → all recents).
  static List<String> recents(List<String> recent, String lowerQuery) {
    if (recent.isEmpty) return const [];
    if (lowerQuery.isEmpty) return recent;
    return recent.where((s) => s.toLowerCase().contains(lowerQuery)).toList();
  }

  /// Union of static-filtered + async results (de-duplicated, order
  /// preserved), capped at [max].
  static List<String> mergeAsync(
    List<String> staticFiltered,
    List<String> results,
    int max,
  ) {
    final merged = <String>[...staticFiltered];
    for (final r in results) {
      if (!merged.contains(r)) merged.add(r);
    }
    return merged.take(max).toList();
  }

  /// Ghost-completion tail: the part of the first candidate that
  /// `startsWith(lowerQuery)` beyond what the user already typed. Empty
  /// when nothing matches.
  static String completion(
    Iterable<String> candidates,
    String query,
    String lowerQuery,
  ) {
    final match = candidates.firstWhere(
      (s) => s.toLowerCase().startsWith(lowerQuery),
      orElse: () => '',
    );
    return match.isNotEmpty && match.length > query.length
        ? match.substring(query.length)
        : '';
  }
}
