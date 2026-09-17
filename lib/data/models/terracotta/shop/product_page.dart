import 'package:flutter/foundation.dart';

import 'product.dart';

/// One page of `GET /api/shop/products`.
///
/// ## Why this is hand-parsed
///
/// Sending `per_page` flips `data` from a plain array into a LARAVEL
/// paginator: the rows move to `data.data` and the counters sit beside
/// them as `current_page` / `last_page` / `total`. Neither shared
/// handler reads that shape — `getList` wants an array and
/// `getPaginated` wants an `items` / `meta` envelope — so the unwrap
/// happens here, once, rather than at every call site.
///
/// Verified live: `per_page=3` answers `last_page: 5`, `total: 15`.
/// Leaving `per_page` off returns all fifteen as a plain array, and
/// `page` on its own is IGNORED — so paging always sends both.
@immutable
class ProductPage {
  const ProductPage({
    required this.items,
    required this.currentPage,
    required this.lastPage,
    required this.total,
  });

  /// A single unpaginated array, as the endpoint answers without
  /// `per_page`.
  factory ProductPage.single(List<Product> items) => ProductPage(
    items: items,
    currentPage: 1,
    lastPage: 1,
    total: items.length,
  );

  factory ProductPage.fromJson(Map<String, dynamic> json) {
    final rows = json['data'];
    return ProductPage(
      items: [
        if (rows is List)
          for (final row in rows)
            if (row is Map<String, dynamic>) Product.fromJson(row),
      ],
      // Defaulted rather than required: a malformed counter must not
      // throw away a page of products that parsed perfectly well.
      currentPage: _int(json['current_page']) ?? 1,
      lastPage: _int(json['last_page']) ?? 1,
      total: _int(json['total']) ?? 0,
    );
  }

  static int? _int(Object? value) => switch (value) {
    final int v => v,
    final String v => int.tryParse(v),
    _ => null,
  };

  final List<Product> items;
  final int currentPage;
  final int lastPage;
  final int total;

  /// Whether asking for [currentPage] + 1 would return anything.
  bool get hasMore => currentPage < lastPage;
}
