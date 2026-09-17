import 'package:dio/dio.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/error/app_exception.dart';
import '../../../core/types/result.dart';
import '../../../data/api/calls/shop_apis.dart';
import '../../../data/models/terracotta/shop/product.dart';
import '../../../data/models/terracotta/shop/shop_category.dart';
import '../../../data/models/terracotta/shop/shop_home.dart';
import '../../_shared/favorite_writer.dart';
import '../../_shared/favorites_registry.dart';
import '../../_shared/locale_scoped_load.dart';
import 'shop_home_state.dart';

/// The one call this tab makes.
typedef ShopHomeFetch =
    AsyncResult<ShopHome> Function({CancelToken? cancelToken});

/// The category tree, with its sub-categories.
typedef ShopCategoriesFetch =
    AsyncResult<List<ShopCategory>> Function({CancelToken? cancelToken});

/// Loads `GET /api/shop/home` — the categories rail, the featured
/// products and the offers, all in one request.
///
/// One cubit rather than one per rail: the payload answers every
/// section, so three would mean three spinners for one response.
class ShopHomeCubit extends Cubit<ShopHomeState> with LocaleScopedLoad {
  ShopHomeCubit({
    ShopHomeFetch? fetch,
    ShopCategoriesFetch? categories,
    FavoriteWriter? favorites,
    FavoritesRegistry? registry,
  }) : _fetch = fetch ?? ShopApis.getHome,
       _categories = categories ?? ShopApis.getCategories,
       _registry = registry ?? FavoritesRegistry(),
       super(const ShopHomeLoading()) {
    _favorites = favorites ?? FavoriteWriter(registry: _registry);
    // Another screen's write is this screen's news: the same product is
    // in both payloads, and neither refetches on a tab switch.
    _registry.addListener(_repaintHearts);
  }

  /// Injectable so the state machine can be tested without a network.
  /// Null in the app.
  final ShopHomeFetch _fetch;

  late final FavoriteWriter _favorites;

  final ShopCategoriesFetch _categories;

  /// The app-wide record of what has been favourited this session.
  final FavoritesRegistry _registry;

  /// Stashed so an in-flight request is dropped when the screen goes.
  final _cancel = CancelToken();

  @override
  bool get hasData => state is ShopHomeLoaded;

  @override
  Future<void> load() async {
    // TOGETHER, not one after the other: they are independent, and the
    // screen cannot draw either rail until both are in.
    final results = await Future.wait([
      _fetch(cancelToken: _cancel),
      _categories(cancelToken: _cancel),
    ]);
    if (isClosed) return;

    final result = results[0] as Result<ShopHome, AppException>;
    final tree = results[1] as Result<List<ShopCategory>, AppException>;

    switch (result) {
      case Success(:final value):
        // Painted over with anything the reader changed on another
        // screen before this one loaded.
        emit(
          ShopHomeLoaded(
            _painted(value),
            categories: _mergeCategories(value, tree),
            query: _query,
          ),
        );
      case Failure(:final error):
        // Only when there is nothing on screen yet. A refresh that
        // fails over a shop the customer is already browsing leaves it.
        if (state is! ShopHomeLoaded) emit(ShopHomeFailed(error));
    }
  }

  /// Re-emits the payload with the registry's answers applied.
  void _repaintHearts() {
    if (state case ShopHomeLoaded(:final payload)) {
      emit(
        ShopHomeLoaded(
          _painted(payload),
          categories: _categoryTree,
          query: _query,
        ),
      );
    }
  }

  /// The two halves of a category, joined.
  ///
  /// `/shop/home` has the artwork, `/shop/categories` has the
  /// sub-categories, and neither has both. The TREE is the spine —
  /// browsing needs sub-categories — with each row's image taken from
  /// the landing payload where one exists.
  ///
  /// A failed tree is not fatal: the landing's own rail only needs the
  /// titles and the pictures, so it falls back to the payload's
  /// categories with no sub-categories under them.
  static List<ShopCategory> _mergeCategories(
    ShopHome payload,
    Result<List<ShopCategory>, AppException> tree,
  ) {
    final images = {
      for (final c in payload.categories)
        if (c.image != null) c.id: c.image,
    };
    return switch (tree) {
      Success(:final value) => [
        for (final c in value)
          images.containsKey(c.id) ? c.copyWith(image: images[c.id]) : c,
      ],
      Failure() => payload.categories,
    };
  }

  /// The current filter, carried across every re-emit — a heart tapped
  /// mid-search must not clear what the reader typed.
  String get _query => switch (state) {
    ShopHomeLoaded(:final query) => query,
    _ => '',
  };

  /// Carried across every re-emit, like the query — a heart tapped
  /// mid-browse must not empty the rails.
  List<ShopCategory> get _categoryTree => switch (state) {
    ShopHomeLoaded(:final categories) => categories,
    _ => const [],
  };

  ShopHome _painted(ShopHome payload) {
    var out = payload;
    for (final entry in _registry.overrides.entries) {
      out = _withFavorite(out, entry.key, entry.value);
    }
    return out;
  }

  /// Filters what is already on screen. No request: see
  /// [ShopHomeLoaded.query].
  void search(String query) {
    if (state case ShopHomeLoaded(:final payload, query: final current)) {
      if (current == query) return;
      emit(ShopHomeLoaded(payload, categories: _categoryTree, query: query));
    }
  }

  /// Turns one product's heart on or off.
  ///
  /// OPTIMISTIC: the heart flips before the request goes out, and flips
  /// back if the server refuses. A heart that waits for a round trip
  /// reads as a dead control, and this is a tap the reader will make
  /// several of in a row.
  ///
  /// Both writes answer `data: null` on success — around forty
  /// operations on this API do — which the shared handler now offers to
  /// the caller's own parser as `{}`. These two pass an identity
  /// parser, so a null payload succeeds. It did not always: the
  /// handler used to reject it, and a successful add surfaced as
  /// "Expected `data` on a successful response".
  ///
  /// Removal goes out as a POST carrying `X-HTTP-Method-Override`,
  /// which `ApiService` does for every DELETE — the live server answers
  /// a plain DELETE here with a 500 and an empty body.
  Future<void> toggleFavorite(int productId) async {
    if (state case ShopHomeLoaded(:final payload)) {
      final before = payload;
      final wasFavorited = _isFavorited(payload, productId);

      emit(
        ShopHomeLoaded(
          _withFavorite(payload, productId, !wasFavorited),
          categories: _categoryTree,
          query: _query,
        ),
      );

      final ok = await _favorites.set(
        productId,
        favorited: !wasFavorited,
        // THE WHOLE PRODUCT, for a reader with no session.
        //
        // A guest's wishlist lives on the device and has nothing to
        // ask the picture and the price for, so `FavoriteWriter`
        // refuses a heart it cannot draw later — which is what a guest
        // tapping one actually got: a flip that undid itself.
        offline: _productIn(payload, productId),
        cancelToken: _cancel,
      );
      if (isClosed) return;
      // Put it back. A heart left filled on a product the server never
      // saved is worse than the tap appearing not to take.
      if (!ok) {
        emit(
          ShopHomeLoaded(before, categories: _categoryTree, query: _query),
        );
      }
    }
  }

  /// The product itself, out of whichever rail holds it.
  static Product? _productIn(ShopHome payload, int productId) {
    for (final p in [...payload.featuredProducts, ...payload.offers]) {
      if (p.id == productId) return p;
    }
    return null;
  }

  static bool _isFavorited(ShopHome payload, int productId) => [
    ...payload.featuredProducts,
    ...payload.offers,
  ].any((p) => p.id == productId && p.isFavorited);

  /// The payload with one product's heart set. It can appear in BOTH
  /// rails, so both are rewritten.
  static ShopHome _withFavorite(ShopHome payload, int productId, bool value) =>
      payload.copyWith(
        featuredProducts: [
          for (final p in payload.featuredProducts)
            if (p.id == productId) p.copyWith(isFavorited: value) else p,
        ],
        offers: [
          for (final p in payload.offers)
            if (p.id == productId) p.copyWith(isFavorited: value) else p,
        ],
      );

  /// Pull to refresh. Records the language it ran in, so returning to
  /// the tab does not immediately repeat it.
  Future<void> refresh(String locale) => refreshIn(locale);

  @override
  Future<void> close() {
    _registry.removeListener(_repaintHearts);
    _cancel.cancel();
    return super.close();
  }
}
