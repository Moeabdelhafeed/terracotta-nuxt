import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/types/result.dart';
import '../../../data/models/terracotta/shop/product_detail.dart';
import '../../_shared/favorite_writer.dart';
import '../../_shared/favorites_registry.dart';
import '../../_shared/locale_scoped_load.dart';
import '../data/product_source.dart';
import 'product_detail_state.dart';

/// One product's detail.
typedef ProductDetailFetch =
    AsyncResult<ProductDetail> Function(
      String productId, {
      CancelToken? cancelToken,
    });

/// «كوب تيراكوتا» — one product, its gallery, its specs and its rail.
///
/// ONE request. `GET /api/shop/products/{id}` answers the description,
/// the gallery, the colourways, the three measurements, the taxonomy
/// labels AND the "you may also like" rail together, so the page has
/// one cubit rather than one per section.
///
/// NOT a singleton, unlike the tab cubits: a detail screen is per
/// product and dies with its route, so it is built by the page and
/// closed by it.
class ProductDetailCubit extends Cubit<ProductDetailState>
    with LocaleScopedLoad {
  ProductDetailCubit({
    required this.productId,
    ProductDetailFetch? fetch,
    FavoriteWriter? favorites,
    FavoritesRegistry? registry,
    // WHICH STOREFRONT — see [ProductSource]. Materials answer the
    // identical detail shape off a parallel path.
    ProductSource source = ProductSource.shop,
  }) : _fetch = fetch ?? source.detail,
       _registry = registry ?? FavoritesRegistry(),
       super(const ProductDetailLoading()) {
    _favorites = favorites ?? FavoriteWriter(registry: _registry);
  }

  final String productId;
  final ProductDetailFetch _fetch;
  late final FavoriteWriter _favorites;

  /// The app-wide record, so a heart tapped here shows on the rails and
  /// lists the reader came from.
  final FavoritesRegistry _registry;
  final _cancel = CancelToken();

  /// Whether there is a product on screen to keep.
  ///
  /// The TITLE, the description and both taxonomy labels are localized
  /// by the SERVER — `Accept-Language` is resolved per request — so a
  /// page that had already loaded went on showing Arabic copy under an
  /// English UI until something else happened to reload it. This is
  /// what tells `ensureLoaded` there is nothing to redo.
  @override
  bool get hasData => state is ProductDetailLoaded;

  @override
  Future<void> load() async {
    final result = await _fetch(productId, cancelToken: _cancel);
    if (isClosed) return;

    switch (result) {
      case Success(:final value):
        emit(ProductDetailLoaded(_painted(value)));
      case Failure(:final error):
        emit(ProductDetailFailed(error));
    }
  }

  /// A retry in a language nobody changed.
  Future<void> refresh(String locale) {
    emit(const ProductDetailLoading());
    return refreshIn(locale);
  }

  /// The payload as it arrived, corrected by anything the reader
  /// changed elsewhere — this product AND the rail under it.
  ProductDetail _painted(ProductDetail product) {
    final overrides = _registry.overrides;
    if (overrides.isEmpty) return product;
    return product.copyWith(
      isFavorited: overrides[product.id] ?? product.isFavorited,
      relatedProducts: [
        for (final p in product.relatedProducts)
          overrides.containsKey(p.id)
              ? p.copyWith(isFavorited: overrides[p.id]!)
              : p,
      ],
    );
  }

  /// Turns the heart on or off — this product's, or one on its rail.
  ///
  /// OPTIMISTIC and reverted if the server refuses, the same rule every
  /// other heart in the app follows.
  Future<void> toggleFavorite(int id) async {
    if (state case ProductDetailLoaded(:final product)) {
      final wanted = !_isFavorited(product, id);
      emit(ProductDetailLoaded(_withFavorite(product, id, value: wanted)));

      final ok = await _favorites.set(
        id,
        favorited: wanted,
        // THE WHOLE PRODUCT, for a reader with no session — see
        // `FavoriteWriter.set`. The related rail's rows are already
        // `Product`s; this page's own is the detail payload's card
        // half.
        offline: id == product.id
            ? product.toProduct()
            : product.relatedProducts.where((p) => p.id == id).firstOrNull,
        cancelToken: _cancel,
      );
      if (isClosed) return;
      if (!ok) emit(ProductDetailLoaded(product));
    }
  }

  static bool _isFavorited(ProductDetail product, int id) => id == product.id
      ? product.isFavorited
      : product.relatedProducts.any((p) => p.id == id && p.isFavorited);

  static ProductDetail _withFavorite(
    ProductDetail product,
    int id, {
    required bool value,
  }) => product.copyWith(
    isFavorited: id == product.id ? value : product.isFavorited,
    relatedProducts: [
      for (final p in product.relatedProducts)
        if (p.id == id) p.copyWith(isFavorited: value) else p,
    ],
  );

  @override
  Future<void> close() {
    _cancel.cancel('product detail closed');
    return super.close();
  }
}
