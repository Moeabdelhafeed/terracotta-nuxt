/// Cursor-based pagination result — an alternative to the offset-based
/// [PaginatedResult] used when the backend returns opaque cursor tokens
/// (e.g. GraphQL Relay, Firestore, DynamoDB).
///
/// ```dart
/// AsyncResult<CursorResult<Post>> feed({String? after}) =>
///   ApiService().get('/feed', queryParameters: {'after': ?after}, fromJson: ...);
/// ```
class CursorResult<T> {
  const CursorResult({
    required this.items,
    this.nextCursor,
    this.prevCursor,
    this.hasMore = false,
  });

  /// The items on the current page.
  final List<T> items;

  /// Opaque token to pass as the `after` / `cursor` query parameter for
  /// the next page. `null` when there is no next page.
  final String? nextCursor;

  /// Opaque token for the previous page (if the backend supports
  /// bidirectional pagination). `null` otherwise.
  final String? prevCursor;

  /// Convenience — `true` when the backend says more pages exist. Derive
  /// from `nextCursor != null` if the API doesn't return this flag.
  final bool hasMore;

  /// Map each item to a new type, preserving the cursor envelope.
  CursorResult<R> map<R>(R Function(T item) transform) => CursorResult<R>(
    items: items.map(transform).toList(),
    nextCursor: nextCursor,
    prevCursor: prevCursor,
    hasMore: hasMore,
  );

  bool get isEmpty => items.isEmpty;
  bool get isNotEmpty => items.isNotEmpty;
  int get length => items.length;

  @override
  String toString() =>
      'CursorResult(items: ${items.length}, next: $nextCursor)';
}
