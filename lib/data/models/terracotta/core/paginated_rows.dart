/// Rows that arrive EITHER as a bare list or inside a Laravel
/// paginator.
///
/// This backend switches shape on `per_page`: without it a collection
/// is a plain JSON array, with it the array moves to `data` inside a
/// paginator object and the counters sit beside it. Verified live on
/// `GET /api/wallet/transactions` and `GET /api/notifications`, and the
/// app always sends `per_page` — so the paginator is the shape it
/// actually receives.
///
/// Declared as a list alone, `fromJson` threw
/// `type '_Map<String, dynamic>' is not a subtype of type
/// 'List<dynamic>?'` and took the WHOLE payload down with it, including
/// the `balance` and the `unread_count` sitting beside the rows — the
/// fields those screens most need.
///
/// A shape nobody expected reads as NO ROWS rather than throwing, for
/// the same reason: whatever sits beside them is worth more than a row
/// that could not be parsed.
List<T> readPaginatedRows<T>(
  Object? json,
  T Function(Map<String, dynamic>) fromJson,
) {
  final rows = switch (json) {
    List<dynamic> list => list,
    Map<String, dynamic> page => page['data'],
    _ => null,
  };
  if (rows is! List) return const [];
  return [
    for (final row in rows)
      if (row is Map<String, dynamic>) fromJson(row),
  ];
}
