import 'package:flutter/foundation.dart';

import '../../../core/error/app_exception.dart';
import '../../../data/api/calls/shop_apis.dart';
import '../../../data/models/terracotta/shop/product.dart';
import '../../../data/models/terracotta/shop/shop_category.dart';

/// What the category browse screen knows.
///
/// ONE state class rather than a sealed family: the screen shows the
/// category rails and the product list at the same time, and the rails
/// stay put while the list below them reloads. A sealed
/// loading/loaded/failed would have made "the rails are here and the
/// products are on their way" unrepresentable.
@immutable
class ProductBrowseState {
  const ProductBrowseState({
    this.categories = const [],
    this.selectedCategoryId,
    this.selectedSubCategoryId,
    this.query = '',
    this.products = const [],
    this.categoriesLoading = true,
    this.productsLoading = true,
    this.loadingMore = false,
    this.hasMore = false,
    this.page = 0,
    this.total = 0,
    this.featuredOnly = false,
    this.onSaleOnly = false,
    this.sort,
    this.minPrice,
    this.maxPrice,
    this.error,
  });

  final List<ShopCategory> categories;
  final int? selectedCategoryId;
  final int? selectedSubCategoryId;

  /// The free-text filter, sent to the server as `search`.
  final String query;

  /// Everything loaded so far, across pages.
  final List<Product> products;

  final bool categoriesLoading;

  /// A FIRST page is on its way — the list is replaced.
  /// TRUE before the first ask.
  ///
  /// The page loads on mount, but `load()` runs a frame later — so with
  /// this false the very first build had no products and no request in
  /// flight, and the body fell through to «لا نتائج». Entering the
  /// browse screen flashed "nothing matches that" over an empty page
  /// before anything had been asked for.
  ///
  /// A screen that has not asked has not earned that sentence.
  final bool productsLoading;

  /// A NEXT page is on its way — the list is appended to, and what is
  /// already on screen stays.
  final bool loadingMore;

  final bool hasMore;
  final int page;

  /// How many the server says MATCH — the whole answer, not the part
  /// that has been paged in.
  ///
  /// Zero until a page has landed, which is also what a seeded list
  /// reports: `ProductBrowseCache` keeps the rows from the last visit
  /// and knows nothing about the count behind them, so the line above
  /// the list stays quiet rather than claiming a number that came from
  /// counting what happens to be on screen.
  final int total;

  /// Whether the count is worth printing.
  bool get hasTotal => total > 0 && !productsLoading;

  /// The two filters the API actually honours. Probed: `featured=1`
  /// answers 4 of 15 and `on_sale=1` answers 5; `min_price` and `sort`
  /// are accepted and IGNORED, so the sheet does not offer them.
  final bool featuredOnly;
  final bool onSaleOnly;

  /// How the list is ordered. Null is the studio's own arrangement —
  /// `sort` is simply not sent then. See [ProductSort].
  final ProductSort? sort;

  /// The price range, or null for unbounded on that end. Both compare
  /// on what the customer PAYS — the sale price on a piece on offer.
  final int? minPrice;
  final int? maxPrice;

  /// How many are on, for the badge on the filter button. The ORDER
  /// counts: it changes what the list shows first, and a reader who
  /// set it should be able to see that something is on.
  int get activeFilters =>
      (featuredOnly ? 1 : 0) +
      (onSaleOnly ? 1 : 0) +
      (sort != null ? 1 : 0) +
      (minPrice != null || maxPrice != null ? 1 : 0);
  final AppException? error;

  ShopCategory? get selectedCategory {
    for (final c in categories) {
      if (c.id == selectedCategoryId) return c;
    }
    return null;
  }

  ProductBrowseState copyWith({
    List<ShopCategory>? categories,
    int? selectedCategoryId,
    int? selectedSubCategoryId,
    bool clearSubCategory = false,
    String? query,
    List<Product>? products,
    bool? categoriesLoading,
    bool? productsLoading,
    bool? loadingMore,
    bool? hasMore,
    int? page,
    int? total,
    bool? featuredOnly,
    bool? onSaleOnly,
    ProductSort? sort,
    bool clearSort = false,
    int? minPrice,
    int? maxPrice,
    bool clearPrices = false,
    AppException? error,
    bool clearError = false,
  }) => ProductBrowseState(
    categories: categories ?? this.categories,
    selectedCategoryId: selectedCategoryId ?? this.selectedCategoryId,
    selectedSubCategoryId: clearSubCategory
        ? null
        : selectedSubCategoryId ?? this.selectedSubCategoryId,
    query: query ?? this.query,
    products: products ?? this.products,
    categoriesLoading: categoriesLoading ?? this.categoriesLoading,
    productsLoading: productsLoading ?? this.productsLoading,
    loadingMore: loadingMore ?? this.loadingMore,
    hasMore: hasMore ?? this.hasMore,
    page: page ?? this.page,
    total: total ?? this.total,
    featuredOnly: featuredOnly ?? this.featuredOnly,
    onSaleOnly: onSaleOnly ?? this.onSaleOnly,
    sort: clearSort ? null : sort ?? this.sort,
    error: clearError ? null : error ?? this.error,
  );
}
