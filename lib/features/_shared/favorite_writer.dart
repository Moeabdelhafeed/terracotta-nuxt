import 'package:dio/dio.dart';

import '../../core/di/service_locator.dart';
import '../../core/types/result.dart';
import '../../data/api/calls/shop_apis.dart';
import '../../data/blocs/auth/auth_bloc.dart';
import '../../data/models/terracotta/shop/product.dart';
import '../shop/data/guest_wishlist.dart';
import 'favorites_registry.dart';

/// Adding or removing one favourite.
typedef FavoriteWrite =
    AsyncResult<Map<String, dynamic>> Function(
      String productId, {
      CancelToken? cancelToken,
    });

/// The two favourite calls, and the two things that are easy to get
/// wrong about them, in one place.
///
/// Three screens turn a heart on or off — the home rails, the shop
/// rails and the saved list — and each keeps its own state, so what is
/// shared is the WRITE, not the optimism around it. Each caller flips
/// its own copy first and puts it back if [set] answers false.
///
/// ## Both answer `data: null`
///
/// Around forty operations on this API do. The shared response handler
/// offers a null payload to the caller's own parser as `{}`, and these
/// pass an identity parser, so a null payload succeeds. It did not
/// always: the handler used to reject it and a successful add surfaced
/// as "Expected `data` on a successful response".
///
/// ## Removal is a POST
///
/// `ApiService` rewrites every DELETE to a POST carrying
/// `X-HTTP-Method-Override`. Not only a production concern, whatever
/// `CLAUDE.md` implies: the DEV server answers a plain DELETE here with
/// a 500 and an empty body, and the same call with the override header
/// succeeds. Verified live.
class FavoriteWriter {
  const FavoriteWriter({
    FavoriteWrite? add,
    FavoriteWrite? remove,
    FavoritesRegistry? registry,
    GuestWishlist? wishlist,
    bool Function()? signedIn,
  }) : _add = add,
       _remove = remove,
       _registry = registry,
       _wishlist = wishlist,
       _signedIn = signedIn;

  /// The device's own list, for a reader with no account.
  ///
  /// `GET /api/shop/favorites` and the writes behind it all answer 401
  /// for a guest (`docs/api-contract.md` §17), so a heart that only
  /// talked to the server would silently do nothing.
  final GuestWishlist? _wishlist;
  final bool Function()? _signedIn;

  /// The device list, found through the container when none was passed.
  ///
  /// **Resolved LAZILY, and null when nothing is registered.** A
  /// default that reaches into `getIt` at CONSTRUCTION throws in every
  /// test that has not stood the container up — which is exactly the
  /// trap `FavoritesCubit` documents avoiding, and it took seventy-odd
  /// tests down when this asked for the wishlist eagerly.
  GuestWishlist? get _list =>
      _wishlist ??
      (getIt.isRegistered<GuestWishlist>() ? getIt<GuestWishlist>() : null);

  /// Whether the SERVER owns this list.
  ///
  /// True when there is no device list to fall back on, so a test with
  /// an empty container behaves exactly as it did before any of this
  /// existed.
  bool get _remote {
    if (_list == null) return true;
    final signedIn = _signedIn;
    if (signedIn != null) return signedIn();
    return !getIt.isRegistered<AuthBloc>() || getIt<AuthBloc>().isAuthenticated;
  }

  final FavoriteWrite? _add;
  final FavoriteWrite? _remove;

  /// Told only about writes the server ACCEPTED, so every other screen
  /// showing the same product can catch up. Null in a test that does
  /// not care.
  final FavoritesRegistry? _registry;

  /// Tells the server — or the device, when there is no account.
  ///
  /// [offline] is the whole product, needed only when FAVOURITING
  /// without a session: the favourites sheet draws a row with a picture
  /// and a price, and looking that up again would be a network round
  /// trip on the one screen that exists because there is no network
  /// session. Un-favouriting needs only the id.
  Future<bool> set(
    int productId, {
    required bool favorited,
    Product? offline,
    CancelToken? cancelToken,
  }) async {
    if (!_remote) {
      final list = _list!;
      if (!favorited) {
        list.remove(productId);
      } else {
        // Nothing to store. Better to refuse the heart than to leave a
        // list that cannot draw itself.
        if (offline == null) return false;
        if (!list.contains(productId)) list.toggle(offline);
      }
      _registry?.record(productId, favorited: favorited);
      return true;
    }

    final write = favorited
        ? (_add ?? ShopApis.addFavorite)
        : (_remove ?? ShopApis.removeFavorite);
    final result = await write('$productId', cancelToken: cancelToken);
    final ok = result is Success;
    if (ok) _registry?.record(productId, favorited: favorited);
    return ok;
  }
}
