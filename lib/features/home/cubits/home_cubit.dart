import 'package:dio/dio.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/types/result.dart';
import '../../../data/api/calls/content_apis.dart';
import '../../../data/models/terracotta/content/home_payload.dart';
import '../../../data/models/terracotta/shop/product.dart';
import '../../_shared/favorite_writer.dart';
import '../../_shared/favorites_registry.dart';
import '../../_shared/locale_scoped_load.dart';
import 'home_state.dart';

/// The one call this screen makes.
typedef HomeFetch =
    AsyncResult<HomePayload> Function({CancelToken? cancelToken});

/// Loads `GET /api/home` — banners, categories, the current booking,
/// featured pieces and offers, in one request.
///
/// The whole screen comes from that one call, so there is one cubit for
/// the page rather than one per section: five cubits would mean five
/// spinners appearing at five different moments for a payload that
/// arrives all at once.
class HomeCubit extends Cubit<HomeState> with LocaleScopedLoad {
  HomeCubit({
    HomeFetch? fetch,
    FavoriteWriter? favorites,
    FavoritesRegistry? registry,
  }) : _fetch = fetch ?? ContentApis.getHome,
       _registry = registry ?? FavoritesRegistry(),
       super(const HomeLoading()) {
    _favorites = favorites ?? FavoriteWriter(registry: _registry);
    // Another screen's write is this screen's news: the same product is
    // in both payloads, and neither refetches on a tab switch.
    _registry.addListener(_repaintHearts);
  }

  /// How the payload is fetched.
  ///
  /// Injectable so the state machine can be tested without a network —
  /// and the rule worth testing is not the happy path but the refresh
  /// that FAILS over a page already on screen. Null in the app.
  final HomeFetch _fetch;

  late final FavoriteWriter _favorites;

  /// The app-wide record of what has been favourited this session.
  final FavoritesRegistry _registry;

  /// Stashed so an in-flight request is dropped when the screen goes.
  /// Without it the answer arrives to a closed cubit and `emit` throws.
  final _cancel = CancelToken();

  @override
  bool get hasData => state is HomeLoaded;

  @override
  Future<void> load() async {
    final result = await _fetch(cancelToken: _cancel);
    if (isClosed) return;

    switch (result) {
      case Success(:final value):
        // Painted over with anything the reader changed on another
        // screen before this one loaded.
        emit(HomeLoaded(_painted(value)));
      case Failure(:final error):
        // Only when there is nothing on screen yet. A refresh that
        // fails over a page the customer is already reading leaves it
        // alone — replacing content with an error because the network
        // blinked is worse than a slightly stale page.
        if (state is! HomeLoaded) emit(HomeFailed(error));
    }
  }

  /// Pull-to-refresh and the retry button both land here.
  /// Re-emits the payload with the registry's answers applied.
  void _repaintHearts() {
    if (state case HomeLoaded(:final payload)) {
      emit(HomeLoaded(_painted(payload)));
    }
  }

  HomePayload _painted(HomePayload payload) {
    var out = payload;
    for (final entry in _registry.overrides.entries) {
      out = _withFavorite(out, entry.key, entry.value);
    }
    return out;
  }

  /// Turns one product's heart on or off.
  ///
  /// OPTIMISTIC: the heart flips before the request goes out and flips
  /// back if the server refuses. A heart that waits for a round trip
  /// reads as a dead control.
  ///
  /// A product can sit in the FEATURED rail and the OFFERS rail at
  /// once — the payload's own doc says they overlap — so both copies
  /// are rewritten or the same product shows two different hearts.
  Future<void> toggleFavorite(int productId) async {
    if (state case HomeLoaded(:final payload)) {
      final before = payload;
      final wanted = !_isFavorited(payload, productId);

      emit(HomeLoaded(_withFavorite(payload, productId, wanted)));

      final ok = await _favorites.set(
        productId,
        favorited: wanted,
        // THE WHOLE PRODUCT, for a reader with no session — see
        // `FavoriteWriter.set`. Without it a guest's heart flips and
        // then undoes itself.
        offline: _productIn(payload, productId),
        cancelToken: _cancel,
      );
      if (isClosed) return;
      // Put it back. A heart left filled on a product the server never
      // saved is worse than the tap appearing not to take.
      if (!ok) emit(HomeLoaded(before));
    }
  }

  /// The product itself, out of whichever rail holds it.
  static Product? _productIn(HomePayload payload, int productId) {
    for (final p in [...payload.featuredProducts, ...payload.offers]) {
      // The home payload's card and the shop's product are the same
      // row described twice — see `HomeProductCard.toProduct`.
      if (p.id == productId) return p.toProduct();
    }
    return null;
  }

  static bool _isFavorited(HomePayload payload, int productId) => [
    ...payload.featuredProducts,
    ...payload.offers,
  ].any((p) => p.id == productId && p.isFavorited);

  static HomePayload _withFavorite(
    HomePayload payload,
    int productId,
    bool value,
  ) => payload.copyWith(
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
