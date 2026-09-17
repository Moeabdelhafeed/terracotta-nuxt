import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/types/result.dart';
import '../../../data/api/calls/shop_apis.dart';
import '../../../data/models/terracotta/shop/product.dart';
import '../../../data/models/terracotta/shop/product_page.dart';
import '../../../data/models/terracotta/shop/shop_category.dart';
import '../../_shared/favorite_writer.dart';
import '../../_shared/favorites_registry.dart';
import '../../_shared/locale_scoped_load.dart';
import '../data/product_source.dart';
import 'product_browse_state.dart';

/// The category tree.
typedef CategoriesFetch =
    AsyncResult<List<ShopCategory>> Function({CancelToken? cancelToken});

/// The last answer this screen got, kept between visits.
///
/// The browse list is a DIFFERENT query from the rail that opened it —
/// "everything in this category", not the four the rail showed — so
/// there is nothing a caller can hand over the way the product detail
/// page is handed a card's picture. Without this the screen arrived
/// empty every time and the shared elements had nowhere to land, so
/// they flew on the way back and never on the way in.
///
/// Keyed by the FILTERS and by the LANGUAGE. Product titles are the
/// server's, so a result fetched in Arabic must not be shown under an
/// English UI — the same rule `LocaleScopedLoad` keeps everywhere else.
///
/// A seed is never the final answer: the screen still asks, and what is
/// on it dims until the new rows land.
abstract final class ProductBrowseCache {
  static final _last = <String, List<Product>>{};

  /// What identifies one query. Two visits with the same filters in the
  /// same language are the same question.
  static String keyFor({
    required String locale,
    // THE STOREFRONT IS PART OF THE KEY. Category 17 is Clay in
    // materials and something else entirely in the shop, so without
    // this a reader who had browsed one would see the other's rows
    // flash in before the real answer arrived.
    ProductSource source = ProductSource.shop,
    int? categoryId,
    int? subCategoryId,
    String query = '',
    bool featured = false,
    bool onSale = false,
  }) =>
      '${source.wire}|$locale|$categoryId|$subCategoryId'
      '|$query|$featured|$onSale';

  static List<Product> read(String key) => _last[key] ?? const [];

  static void write(String key, List<Product> products) {
    if (products.isEmpty) {
      _last.remove(key);
      return;
    }
    _last[key] = products;
  }

  /// For tests, and for a sign-out — favourite hearts are per-account.
  static void clear() => _last.clear();
}

/// One page of products.
typedef ProductsPageFetch =
    AsyncResult<ProductPage> Function({
      required int page,
      int perPage,
      int? categoryId,
      int? subCategoryId,
      String? search,
      bool? featured,
      bool? onSale,
      ProductSort? sort,
      int? minPrice,
      int? maxPrice,
      CancelToken? cancelToken,
    });

/// Browsing one category: the rails, the filter and the paged list.
class ProductBrowseCubit extends Cubit<ProductBrowseState>
    with LocaleScopedLoad {
  ProductBrowseCubit({
    int? initialSubCategoryId,
    int? initialCategoryId,
    bool initialFeatured = false,
    bool initialOnSale = false,
    List<ShopCategory> knownCategories = const [],
    String? locale,
    CategoriesFetch? categories,
    ProductsPageFetch? products,
    FavoriteWriter? favorites,
    FavoritesRegistry? registry,
    // WHICH STOREFRONT. Raw materials answer the identical wire off
    // parallel endpoints, so everything below serves both and this is
    // the only thing that differs — see [ProductSource].
    ProductSource source = ProductSource.shop,
  }) : _categories = categories ?? source.categories,
       _products = products ?? _defaultProductsFor(source),
       // ONE registry, shared with the writer. Building a second for
       // the fallback would have meant the writer recorded into a
       // registry nothing else was reading.
       _registry = registry ?? FavoritesRegistry(),
       _locale = locale,
       _source = source,
       super(
         ProductBrowseState(
           selectedSubCategoryId: initialSubCategoryId,
           selectedCategoryId: initialCategoryId,
           // WHATEVER THIS SCREEN SHOWED LAST for the same question.
           //
           // Not an answer — `productsLoading` stays true and the rows
           // dim while the real one arrives. It is here so the screen
           // opens with something rather than blank, and so the shared
           // elements flying in from a rail have somewhere to land.
           products: locale == null
               ? const []
               : ProductBrowseCache.read(
                   ProductBrowseCache.keyFor(
                     locale: locale,
                     source: source,
                     categoryId: initialCategoryId,
                     subCategoryId: initialSubCategoryId,
                     featured: initialFeatured,
                     onSale: initialOnSale,
                   ),
                 ),
           // HANDED IN, not fetched again. The shop landing already
           // loaded the tree — merged with its artwork — and asking a
           // second time both costs a request and loses the images,
           // because `/shop/categories` does not carry them.
           categories: knownCategories,
           categoriesLoading: knownCategories.isEmpty,
           featuredOnly: initialFeatured,
           onSaleOnly: initialOnSale,
         ),
       ) {
    _favorites = favorites ?? FavoriteWriter(registry: _registry);
  }

  /// The language this screen is being read in, for the cache key.
  /// Null in a test that does not care.
  final String? _locale;

  /// Which storefront, for the cache key. The fetchers are already
  /// bound to it — this is only so the two do not share rows.
  final ProductSource _source;

  /// What this screen is currently asking for.
  String? get _cacheKey => _locale == null
      ? null
      : ProductBrowseCache.keyFor(
          locale: _locale,
          source: _source,
          categoryId: state.selectedCategoryId,
          subCategoryId: state.selectedSubCategoryId,
          query: state.query,
          featured: state.featuredOnly,
          onSale: state.onSaleOnly,
        );

  final CategoriesFetch _categories;
  final ProductsPageFetch _products;
  late final FavoriteWriter _favorites;

  /// The app-wide record, so a heart tapped here shows on the rails
  /// behind this screen too.
  final FavoritesRegistry _registry;
  final _cancel = CancelToken();

  /// How many rows a page asks for. Both this and `page` go out
  /// together — the server ignores `page` on its own.
  static const perPage = 10;

  /// Typing filters, but not on every keystroke: the filter goes to
  /// the SERVER, and a request per letter is a request per letter.
  static const debounce = Duration(milliseconds: 350);
  Timer? _debounce;

  /// The storefront's own paging call, with THIS cubit's `per_page`
  /// default filled in.
  ///
  /// A closure rather than the API method itself: `perPage` defaults
  /// to 10 on both of them and to [perPage] here, and handing the bare
  /// method over would silently page in tens where this screen pages
  /// in whatever it was told to.
  static ProductsPageFetch _defaultProductsFor(ProductSource source) {
    final fetch = source.products;
    return ({
      required int page,
      int perPage = ProductBrowseCubit.perPage,
      int? categoryId,
      int? subCategoryId,
      String? search,
      bool? featured,
      bool? onSale,
      ProductSort? sort,
      int? minPrice,
      int? maxPrice,
      CancelToken? cancelToken,
    }) => fetch(
      page: page,
      perPage: perPage,
      categoryId: categoryId,
      subCategoryId: subCategoryId,
      search: search,
      featured: featured,
      onSale: onSale,
      sort: sort,
      minPrice: minPrice,
      maxPrice: maxPrice,
      cancelToken: cancelToken,
    );
  }

  /// Whether there is a page of products on screen to keep.
  @override
  bool get hasData => state.products.isNotEmpty;

  /// The language the CATEGORY TREE on screen arrived in.
  ///
  /// Seeded with the locale this screen opened in, because the tree it
  /// was handed came from `ShopHomeCubit`, which had loaded in exactly
  /// that language.
  late String? _categoriesLocale = _locale;

  @override
  Future<void> load() async {
    // Already handed the tree — but only in the language being read.
    //
    // The short-circuit used to be unconditional, so a language switch
    // reloaded the PRODUCTS and left the category and sub-category
    // rails in the old one: Arabic chips above English cards. The
    // titles are the server's and the only way to re-say them is to
    // ask again.
    if (state.categories.isNotEmpty && _categoriesLocale == loadedLocale) {
      emit(
        state.copyWith(selectedCategoryId: _openingCategory(state.categories)),
      );
      await _reload();
      return;
    }

    final result = await _categories(cancelToken: _cancel);
    if (isClosed) return;

    switch (result) {
      case Success(:final value):
        // The FIRST category is opened for the reader: this screen is
        // reached by tapping a category, and an empty one under a rail
        // of them looks like a screen that failed.
        final selected = _openingCategory(value);
        _categoriesLocale = loadedLocale;
        emit(
          state.copyWith(
            categories: value,
            categoriesLoading: false,
            selectedCategoryId: selected,
          ),
        );
        await _reload();
      case Failure(:final error):
        emit(state.copyWith(categoriesLoading: false, error: error));
    }
  }

  /// Which category the screen opens on: whichever is already chosen,
  /// else the one owning the sub-category it was opened with, else the
  /// first — an empty screen under a rail of categories looks broken.
  ///
  /// EXCEPT when the screen was opened on a filter. "See all featured"
  /// means every featured piece in the shop, and quietly narrowing that
  /// to the first category answers a different question — so nothing is
  /// chosen and the rail opens with no selection.
  int? _openingCategory(List<ShopCategory> categories) {
    final asked =
        state.selectedCategoryId ??
        _categoryOf(categories, state.selectedSubCategoryId);
    if (asked != null) return asked;
    if (state.featuredOnly || state.onSaleOnly) return null;
    return categories.isEmpty ? null : categories.first.id;
  }

  /// Which category owns [subCategoryId], when the screen was opened
  /// on one.
  static int? _categoryOf(List<ShopCategory> categories, int? subCategoryId) {
    if (subCategoryId == null) return null;
    for (final c in categories) {
      if (c.subCategories.any((s) => s.id == subCategoryId)) return c.id;
    }
    return null;
  }

  void selectCategory(int categoryId) {
    if (state.selectedCategoryId == categoryId) return;
    // The sub-category belonged to the OLD category — keeping it would
    // filter by something no longer on screen.
    emit(
      state.copyWith(
        selectedCategoryId: categoryId,
        clearSubCategory: true,
      ),
    );
    unawaited(_reload());
  }

  void selectSubCategory(int? subCategoryId) {
    if (state.selectedSubCategoryId == subCategoryId) return;
    emit(
      subCategoryId == null
          ? state.copyWith(clearSubCategory: true)
          : state.copyWith(selectedSubCategoryId: subCategoryId),
    );
    unawaited(_reload());
  }

  /// Free-text, debounced.
  void search(String query) {
    if (query == state.query) return;
    emit(state.copyWith(query: query));
    _debounce?.cancel();
    _debounce = Timer(debounce, () => unawaited(_reload()));
  }

  /// Turns one product's heart on or off.
  ///
  /// OPTIMISTIC, and reverted if the server refuses — the same rule the
  /// rails follow, for the same reason: a heart that waits for a round
  /// trip reads as a dead control.
  Future<void> toggleFavorite(int productId) async {
    final before = state.products;
    final wanted = !before.any((p) => p.id == productId && p.isFavorited);

    emit(state.copyWith(products: _withFavorite(before, productId, wanted)));

    final ok = await _favorites.set(
      productId,
      favorited: wanted,
      // THE WHOLE PRODUCT, for a reader with no session — see
      // `FavoriteWriter.set`.
      offline: before.where((p) => p.id == productId).firstOrNull,
      cancelToken: _cancel,
    );
    if (isClosed) return;
    if (!ok) emit(state.copyWith(products: before));
  }

  static List<Product> _withFavorite(
    List<Product> products,
    int productId,
    bool value,
  ) => [
    for (final p in products)
      if (p.id == productId) p.copyWith(isFavorited: value) else p,
  ];

  /// A page just arrived — paint it with anything the reader changed
  /// elsewhere, the same way the rails do.
  List<Product> _painted(List<Product> products) {
    final overrides = _registry.overrides;
    if (overrides.isEmpty) return products;
    return [
      for (final p in products)
        overrides.containsKey(p.id)
            ? p.copyWith(isFavorited: overrides[p.id]!)
            : p,
    ];
  }

  /// What the filter sheet chose — the two toggles and the order.
  void applyFilters({
    required bool featuredOnly,
    required bool onSaleOnly,
    ProductSort? sort,
    int? minPrice,
    int? maxPrice,
  }) {
    if (featuredOnly == state.featuredOnly &&
        onSaleOnly == state.onSaleOnly &&
        sort == state.sort &&
        minPrice == state.minPrice &&
        maxPrice == state.maxPrice) {
      return;
    }
    emit(
      state.copyWith(
        featuredOnly: featuredOnly,
        onSaleOnly: onSaleOnly,
        sort: sort,
        minPrice: minPrice,
        maxPrice: maxPrice,
        // NULL IS A VALUE on all three — an unset order is the
        // studio's own, an unset bound is unbounded, and `copyWith`
        // treating null as "leave alone" would make clearing any of
        // them impossible.
        clearSort: sort == null,
        clearPrices: minPrice == null && maxPrice == null,
      ),
    );
    unawaited(_reload());
  }

  /// The next page, appended.
  Future<void> loadMore() async {
    if (state.loadingMore || !state.hasMore || state.productsLoading) return;
    emit(state.copyWith(loadingMore: true));

    final result = await _products(
      page: state.page + 1,
      perPage: perPage,
      categoryId: state.selectedCategoryId,
      subCategoryId: state.selectedSubCategoryId,
      search: state.query,
      featured: state.featuredOnly ? true : null,
      onSale: state.onSaleOnly ? true : null,
      sort: state.sort,
      minPrice: state.minPrice,
      maxPrice: state.maxPrice,
      cancelToken: _cancel,
    );
    if (isClosed) return;

    switch (result) {
      case Success(:final value):
        emit(
          state.copyWith(
            products: [...state.products, ..._painted(value.items)],
            page: value.currentPage,
            hasMore: value.hasMore,
            total: value.total,
            loadingMore: false,
            clearError: true,
          ),
        );
      case Failure(:final error):
        // The pages already read STAY. A failed "more" is not a reason
        // to throw away what the reader is looking at.
        emit(state.copyWith(loadingMore: false, error: error));
    }
  }

  /// The first page, replacing whatever is on screen.
  Future<void> _reload() async {
    emit(state.copyWith(productsLoading: true, clearError: true));

    final result = await _products(
      page: 1,
      perPage: perPage,
      categoryId: state.selectedCategoryId,
      subCategoryId: state.selectedSubCategoryId,
      search: state.query,
      featured: state.featuredOnly ? true : null,
      onSale: state.onSaleOnly ? true : null,
      sort: state.sort,
      minPrice: state.minPrice,
      maxPrice: state.maxPrice,
      cancelToken: _cancel,
    );
    if (isClosed) return;

    switch (result) {
      case Success(:final value):
        final painted = _painted(value.items);
        // Kept for the next visit — see `ProductBrowseCache`.
        if (_cacheKey case final key?) ProductBrowseCache.write(key, painted);
        emit(
          state.copyWith(
            products: painted,
            page: value.currentPage,
            hasMore: value.hasMore,
            total: value.total,
            productsLoading: false,
          ),
        );
      case Failure(:final error):
        emit(
          state.copyWith(
            products: const [],
            productsLoading: false,
            hasMore: false,
            total: 0,
            error: error,
          ),
        );
    }
  }

  Future<void> refresh() => _reload();

  @override
  Future<void> close() {
    _debounce?.cancel();
    _cancel.cancel();
    return super.close();
  }
}
