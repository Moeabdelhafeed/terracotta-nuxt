import 'package:flutter/foundation.dart';

import '../../../data/models/terracotta/core/api_image.dart';
import '../../../data/models/terracotta/workshop/workshop_own_pieces.dart';
import '../../../data/models/terracotta/workshop/workshop_product.dart';

/// One thing the customer is buying on the catalogue screen.
///
/// TWO kinds, drawn the same and priced differently: a product off the
/// studio's shelf, or one of the customer's OWN pieces brought back to
/// be painted. The wire says the same thing — a `products` line is
/// either `workshop_product_id` + `quantity` **or**
/// `workshop_booking_piece_id`, never both — so the screen carries one
/// type and the payload branches at the last moment.
///
/// An own piece is always ONE: it is a specific object, and the server
/// ignores a quantity sent with it.
@immutable
class PickedPiece {
  const PickedPiece.product({
    required int this.productId,
    required this.title,
    required this.price,
    required this.quantity,
    this.subtitle,
    this.image,
  }) : ownPieceId = null;

  const PickedPiece.own({
    required int this.ownPieceId,
    required this.title,
    required this.price,
    this.subtitle,
    this.image,
  }) : productId = null,
       quantity = 1;

  /// Set on a catalogue line.
  final int? productId;

  /// Set on one of the customer's own.
  final int? ownPieceId;

  final String title;
  final String? subtitle;

  /// A decimal STRING — the product's price, or the workshop's flat
  /// `own_pieces.price`.
  final String price;

  final ApiImage? image;

  /// Always 1 on an own piece.
  final int quantity;

  bool get isOwn => ownPieceId != null;

  /// The wire line. Quantity is left off an own piece rather than sent
  /// as one, because the server ignores it either way and a payload
  /// that says less cannot be read wrong.
  Map<String, dynamic> toLine() => isOwn
      ? {'workshop_booking_piece_id': ownPieceId}
      : {'workshop_product_id': productId, 'quantity': quantity};

  /// The same piece, differently many. Meaningless on an own piece —
  /// asserted rather than silently ignored.
  PickedPiece withQuantity(int next) {
    assert(!isOwn, 'an own piece is a specific object; it is always one');
    return PickedPiece.product(
      productId: productId!,
      title: title,
      price: price,
      quantity: next,
      subtitle: subtitle,
      image: image,
    );
  }

  static PickedPiece fromProduct(
    WorkshopProduct product,
    int quantity, {
    required String untitled,
  }) => PickedPiece.product(
    productId: product.id,
    title: product.title ?? untitled,
    subtitle: product.subtitle,
    price: product.price,
    image: product.primaryImage,
    quantity: quantity,
  );

  static PickedPiece fromOwn(
    WorkshopOwnPiece piece, {
    required String price,
    required String untitled,
    String? madeOnLabel,
  }) => PickedPiece.own(
    ownPieceId: piece.id,
    title: piece.label ?? untitled,
    subtitle: madeOnLabel,
    price: price,
    image: piece.primaryImage,
  );

  @override
  bool operator ==(Object other) =>
      other is PickedPiece &&
      other.productId == productId &&
      other.ownPieceId == ownPieceId &&
      other.quantity == quantity;

  @override
  int get hashCode => Object.hash(productId, ownPieceId, quantity);
}
