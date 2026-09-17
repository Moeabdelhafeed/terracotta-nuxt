import '../../data/models/api/pagination_links/pagination_links.dart';
import '../../data/models/api/pagination_meta/pagination_meta.dart';

/// A page of [items] plus its paging envelope — `meta` (current page,
/// page size, total count…) and `links` (first/last/next/previous).
///
/// Paired with [Result] (`core/types/result.dart`), the idiomatic return
/// shape for a paginated endpoint is:
/// ```dart
/// AsyncResult<PaginatedResult<User>> listUsers() => ApiService().getPaginated<User>(...);
/// ```
class PaginatedResult<T> {
  const PaginatedResult({
    required this.items,
    this.meta,
    this.links,
  });

  /// The items on the current page.
  final List<T> items;

  /// Cursor / offset / count information about the page.
  final PaginationMeta? meta;

  /// Hyperlinks to related pages (first, last, next, previous).
  final PaginationLinks? links;

  /// Map each item to a new type, preserving the pagination envelope.
  PaginatedResult<R> map<R>(R Function(T item) transform) => PaginatedResult<R>(
    items: items.map(transform).toList(),
    meta: meta,
    links: links,
  );

  bool get isEmpty => items.isEmpty;
  bool get isNotEmpty => items.isNotEmpty;
  int get length => items.length;

  @override
  String toString() => 'PaginatedResult(items: ${items.length}, meta: $meta)';
}
