import 'package:flutter/foundation.dart';

import '../../../core/error/app_exception.dart';
import '../../../data/models/terracotta/commerce/cart.dart';

/// «عربيتي» — what is in the cart right now.
@immutable
class CartState {
  const CartState({
    this.cart,
    this.loading = false,
    this.error,
    this.busyLines = const {},
  });

  /// Null before the first answer. An EMPTY cart is a `Cart` with no
  /// lines, which is a different thing from not having asked yet.
  final Cart? cart;

  final bool loading;
  final AppException? error;

  /// Lines with a write in flight, by line id — so one row can show it
  /// is working without freezing the rest of the sheet.
  final Set<int> busyLines;

  /// What the badge shows: the number of PIECES, not of lines.
  ///
  /// Two of one cup is two things in the cart, and a badge that said
  /// «١» over a cart holding two would be wrong in the way a customer
  /// notices at checkout.
  int get pieceCount =>
      cart?.items.fold(0, (sum, item) => sum! + item.quantity) ?? 0;

  bool get isEmpty => cart?.items.isEmpty ?? true;

  /// How many of one PRODUCT the cart holds, across every colourway of
  /// it.
  ///
  /// The server caps a line by product, so a reader who already has
  /// the cap cannot add another whatever colour they pick — which is
  /// what the product page has to know before it offers to add one.
  int quantityOf(int productId) =>
      cart?.items
          .where((item) => item.product.id == productId)
          .fold(0, (sum, item) => sum! + item.quantity) ??
      0;

  CartState copyWith({
    Cart? cart,
    bool? loading,
    AppException? error,
    Set<int>? busyLines,
    bool clearError = false,
  }) => CartState(
    cart: cart ?? this.cart,
    loading: loading ?? this.loading,
    error: clearError ? null : error ?? this.error,
    busyLines: busyLines ?? this.busyLines,
  );
}
