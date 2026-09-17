import 'package:dio/dio.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/di/service_locator.dart';
import '../../../core/types/result.dart';
import '../../../data/api/calls/shop_apis.dart';
import '../../../data/blocs/auth/auth_bloc.dart';
import '../../../data/models/terracotta/commerce/cart.dart';
import '../../../data/models/terracotta/commerce/cart_item.dart';
import '../../_shared/locale_scoped_load.dart';
import '../data/cart_stock_check.dart';
import '../data/guest_basket.dart';
import 'cart_state.dart';

typedef CartFetch = AsyncResult<Cart> Function({CancelToken? cancelToken});

typedef CartAdd =
    AsyncResult<CartItem> Function({
      required int shopProductId,
      String? color,
      int? quantity,
      CancelToken? cancelToken,
    });

typedef CartSetQuantity =
    AsyncResult<CartItem> Function(
      String itemId, {
      required int quantity,
      CancelToken? cancelToken,
    });

typedef CartRemove =
    AsyncResult<Map<String, dynamic>> Function(
      String itemId, {
      CancelToken? cancelToken,
    });

/// The cart, app-wide.
///
/// A `getIt` SINGLETON because the BADGE is: the count sits on the app
/// bar of every screen, and a cart owned by the sheet would be built
/// and thrown away each time it opened — the badge would read zero
/// until someone looked inside.
///
/// **Every write is followed by a re-read.** `POST`, `PUT` and `DELETE`
/// each answer with the LINE they touched (or nothing, for a removal),
/// never with the cart around it — so the total and the other lines
/// would drift from the server on every change. The line's own answer
/// still matters: it is what proves the write landed before the reload
/// goes out.
class CartCubit extends Cubit<CartState> with LocaleScopedLoad {
  CartCubit({
    CartFetch? fetch,
    CartAdd? add,
    CartSetQuantity? setQuantity,
    CartRemove? remove,
    GuestBasket? basket,
    bool Function()? signedIn,
  }) : _basket = basket,
       _signedIn = signedIn,
       _fetch = fetch ?? ShopApis.getCart,
       _add = add ?? _defaultAdd,
       _setQuantity = setQuantity ?? _defaultSetQuantity,
       _remove = remove ?? _defaultRemove,
       super(const CartState());

  /// The device's own basket, for a reader with no account. Null in a
  /// test that only cares about the server half.
  final GuestBasket? _basket;
  final bool Function()? _signedIn;

  /// Whether the SERVER owns this cart.
  ///
  /// A guest gets 401 on every cart route (`docs/api-contract.md` §17),
  /// so for them the basket on the device IS the cart — not a cache of
  /// one, not a queue of writes to replay. Nothing downstream knows the
  /// difference: both answer with a `Cart`.
  bool get _remote =>
      _basket == null ||
      (_signedIn?.call() ?? getIt<AuthBloc>().isAuthenticated);

  final CartFetch _fetch;
  final CartAdd _add;
  final CartSetQuantity _setQuantity;
  final CartRemove _remove;
  final _cancel = CancelToken();

  static AsyncResult<CartItem> _defaultAdd({
    required int shopProductId,
    String? color,
    int? quantity,
    CancelToken? cancelToken,
  }) => ShopApis.addToCart(
    shopProductId: shopProductId,
    color: color,
    quantity: quantity,
    cancelToken: cancelToken,
  );

  static AsyncResult<CartItem> _defaultSetQuantity(
    String itemId, {
    required int quantity,
    CancelToken? cancelToken,
  }) => ShopApis.updateCartItem(
    itemId,
    quantity: quantity,
    cancelToken: cancelToken,
  );

  static AsyncResult<Map<String, dynamic>> _defaultRemove(
    String itemId, {
    CancelToken? cancelToken,
  }) => ShopApis.removeCartItem(itemId, cancelToken: cancelToken);

  /// Whether the cart has ever been read.
  ///
  /// A cart line carries the PRODUCT's name, which the server writes —
  /// so the cart is locale-scoped like every other server-written
  /// payload, and a language switch re-asks rather than leaving Arabic
  /// names under an English page.
  @override
  bool get hasData => state.cart != null;

  /// The session ended: forget what was theirs and show what is ours.
  ///
  /// This cubit is a `getIt` singleton and outlives every page, so
  /// nothing else would have asked it again — `ensureLoaded` only
  /// fetches when the LANGUAGE changes. The badge in the bar therefore
  /// kept counting the customer who had just signed out.
  ///
  /// The device basket is what a reader with no session has, so this
  /// lands on THAT rather than on nothing.
  void signedOut() {
    invalidate();
    // A WHOLE NEW STATE, not a `copyWith`: `cart: null` there means
    // "keep what you have", which is the one thing this must not do —
    // a device with no basket would have gone on showing the customer
    // who just left.
    emit(CartState(cart: _basket?.toCart()));
  }

  @override
  Future<void> load() async {
    if (!_remote) {
      emit(
        state.copyWith(
          cart: _basket!.toCart(),
          loading: false,
          clearError: true,
        ),
      );
      return;
    }
    emit(state.copyWith(loading: true, clearError: true));

    final result = await _fetch(cancelToken: _cancel);
    if (isClosed) return;

    switch (result) {
      case Success(:final value):
        emit(state.copyWith(cart: value, loading: false));
      case Failure(:final error):
        // A guest gets 401 here. That is not an error worth shouting
        // about — it is an empty cart until they sign in.
        emit(state.copyWith(loading: false, error: error));
    }
  }

  /// Put a piece in the cart.
  ///
  /// Returns whether the server took it, so the screen that asked can
  /// say so — or not fly its little animation into a cart that refused.
  Future<bool> add({
    required int productId,
    String? color,
    int quantity = 1,
    BasketLine? offline,
    int? ceiling,
  }) async {
    // No account: the basket on the device is the cart. [offline]
    // carries the picture, the title and the price the row needs to
    // draw itself with nothing to ask — which is the point.
    if (!_remote) {
      if (offline == null) return false;
      _basket!.add(offline.copyWith(quantity: quantity), ceiling: ceiling);
      emit(state.copyWith(cart: _basket.toCart(), clearError: true));
      return true;
    }

    final result = await _add(
      shopProductId: productId,
      color: color,
      quantity: quantity,
      cancelToken: _cancel,
    );
    if (isClosed) return false;

    if (result case Failure(:final error)) {
      emit(state.copyWith(error: error));
      return false;
    }
    await load();
    return true;
  }

  /// Change a line's quantity, or drop the line when it reaches zero.
  ///
  /// The stepper's minus at 1 REMOVES rather than sending `quantity: 0`
  /// — the endpoint takes a count, and a cart line of nothing is not a
  /// thing this API has.
  Future<void> setQuantity(CartItem item, int quantity) async {
    if (quantity == item.quantity) return;
    if (quantity < 1) return removeLine(item);

    if (!_remote) {
      _basket!.setQuantity(
        _keyOf(item),
        quantity,
        ceiling: item.product.maxQuantity,
      );
      emit(state.copyWith(cart: _basket.toCart(), clearError: true));
      return;
    }

    emit(state.copyWith(busyLines: {...state.busyLines, item.id}));
    final result = await _setQuantity(
      '${item.id}',
      quantity: quantity,
      cancelToken: _cancel,
    );
    if (isClosed) return;

    if (result case Failure(:final error)) {
      emit(state.copyWith(error: error, busyLines: _without(item.id)));
      return;
    }
    await load();
    if (!isClosed) emit(state.copyWith(busyLines: _without(item.id)));
  }

  Future<void> removeLine(CartItem item) async {
    if (!_remote) {
      _basket!.remove(_keyOf(item));
      emit(state.copyWith(cart: _basket.toCart(), clearError: true));
      return;
    }

    emit(state.copyWith(busyLines: {...state.busyLines, item.id}));
    final result = await _remove('${item.id}', cancelToken: _cancel);
    if (isClosed) return;

    if (result case Failure(:final error)) {
      emit(state.copyWith(error: error, busyLines: _without(item.id)));
      return;
    }
    await load();
    if (!isClosed) emit(state.copyWith(busyLines: _without(item.id)));
  }

  /// Lines the studio can no longer fill as ordered.
  ///
  /// Free: the server sends `in_stock` and `available_stock` on every
  /// cart line, so the last read already knows. Nothing is asked again.
  List<StockProblem> get stockProblems => CartStockCheck.problems(state.cart);

  /// Lower what can be lowered, take out what is gone.
  ///
  /// One path for both baskets — the local one and the server's — so a
  /// guest and a customer get the same repair.
  Future<void> applyStockFixes() async {
    for (final fix in CartStockCheck.fixes(stockProblems)) {
      if (fix.removes) {
        await removeLine(fix.item);
      } else {
        await setQuantity(fix.item, fix.quantity);
      }
      if (isClosed) return;
    }
  }

  Set<int> _without(int id) => {...state.busyLines}..remove(id);

  /// A local line's identity — the same key `GuestBasket` files it
  /// under, rebuilt from the `CartItem` the sheet handed back.
  static String _keyOf(CartItem item) =>
      '${item.product.id}::${item.color ?? ''}';

  @override
  Future<void> close() {
    _cancel.cancel('cart closed');
    return super.close();
  }
}
