import 'package:dio/dio.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/types/result.dart';
import '../../../data/api/calls/shop_apis.dart';
import '../../../data/models/terracotta/shop/product.dart';
import '../../_shared/favorite_writer.dart';
import '../../_shared/favorites_registry.dart';
import 'favorites_state.dart';

/// The one call the favourites sheet makes.
typedef FavoritesFetch =
    AsyncResult<List<Product>> Function({CancelToken? cancelToken});

/// Loads `GET /api/shop/favorites` — the caller's saved products.
///
/// Needs a SESSION: a guest gets 401. Verified live, and the payload is
/// a plain `List<Product>` — the same rows the shop rails carry, with
/// `is_favorited` already true on every one of them.
class FavoritesCubit extends Cubit<FavoritesState> {
  FavoritesCubit({
    FavoritesFetch? fetch,
    FavoriteWriter? favorites,
    FavoritesRegistry? registry,
  }) : _fetch = fetch ?? ShopApis.getFavorites,
       // A registry of its OWN when none is passed, never `getIt` — a
       // cubit that reaches into the container for a default throws in
       // every test that has not stood the container up, and the sheet
       // is opened with the app's registry from the shop page.
       _favorites =
           favorites ??
           FavoriteWriter(registry: registry ?? FavoritesRegistry()),
       super(const FavoritesLoading());

  /// Injectable so the state machine can be tested without a network.
  /// Null in the app.
  final FavoritesFetch _fetch;

  final FavoriteWriter _favorites;

  /// A sheet is dismissed mid-flight more often than a page is — the
  /// answer would otherwise arrive to a closed cubit and `emit` throws.
  final _cancel = CancelToken();

  Future<void> load() async {
    final result = await _fetch(cancelToken: _cancel);
    if (isClosed) return;

    switch (result) {
      case Success(:final value):
        emit(FavoritesLoaded(value));
      case Failure(:final error):
        if (state is! FavoritesLoaded) emit(FavoritesFailed(error));
    }
  }

  /// Takes one product off the saved list.
  ///
  /// OPTIMISTIC: the row goes before the request does, and comes back
  /// if the server refuses. Waiting for the round trip leaves a heart
  /// the reader already turned off still filled.
  ///
  /// Removal goes out as a POST carrying `X-HTTP-Method-Override` —
  /// see [FavoriteWriter], which is where that trap is written down.
  Future<void> unfavorite(int productId) async {
    if (state case FavoritesLoaded(:final products)) {
      final before = products;
      emit(
        FavoritesLoaded([
          for (final p in products)
            if (p.id != productId) p,
        ]),
      );

      final ok = await _favorites.set(
        productId,
        favorited: false,
        cancelToken: _cancel,
      );
      if (isClosed) return;
      if (!ok) emit(FavoritesLoaded(before));
    }
  }

  @override
  Future<void> close() {
    _cancel.cancel();
    return super.close();
  }
}
