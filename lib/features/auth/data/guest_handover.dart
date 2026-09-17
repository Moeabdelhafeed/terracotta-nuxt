import 'package:dio/dio.dart';

import '../../../core/types/result.dart';
import '../../../data/api/calls/address_apis.dart';
import '../../../data/api/calls/shop_apis.dart';
import '../../cart/data/guest_basket.dart';
import '../../profile/data/guest_addresses.dart';
import '../../shop/data/guest_wishlist.dart';

/// What a handover managed to do, so the app can say it plainly.
class HandoverResult {
  const HandoverResult({this.moved = 0, this.refused = 0});

  /// Pieces that reached the account.
  final int moved;

  /// Pieces the studio no longer has. Said out loud rather than
  /// swallowed — a basket that quietly arrives shorter is worse than
  /// one that explains itself.
  final int refused;

  bool get isEmpty => moved == 0 && refused == 0;
}

/// Moving what a visitor collected into the account they just signed
/// into.
///
/// **Nothing the account already had is touched.** Local lines are
/// ADDED on top: the same piece in the same colour has its quantities
/// summed by the server's own `POST /api/shop/cart`, which merges into
/// an existing line rather than making a second one (probed live — a
/// second add of product 1 came back as one line with the total
/// quantity). So the sheet only ever has to say what it is BRINGING,
/// and never has to ask about replacing anything.
///
/// The local stores are cleared only for what actually landed. A piece
/// the studio has run out of stays on the device rather than vanishing
/// into a failed request.
class GuestHandover {
  const GuestHandover._();

  /// Push the device's basket into the account's cart.
  static Future<HandoverResult> basket(
    GuestBasket basket, {
    CancelToken? cancelToken,
  }) async {
    basket.load();
    if (basket.isEmpty) return const HandoverResult();

    var moved = 0;
    var refused = 0;

    // Sequentially, not in parallel: these are writes to ONE cart, and
    // the server merges into existing lines. Firing them together is
    // how you get a line that lost an update.
    // A COPY: the loop removes from the basket as it goes.
    for (final line in List.of(basket.lines)) {
      final result = await ShopApis.addToCart(
        shopProductId: line.productId,
        color: line.color,
        quantity: line.quantity,
        cancelToken: cancelToken,
      );
      if (result is Success) {
        moved += line.quantity;
        basket.remove(line.key);
      } else {
        // Out of stock, or gone from the catalogue entirely. Left on
        // the device so a later attempt can still find it.
        refused += line.quantity;
      }
    }

    return HandoverResult(moved: moved, refused: refused);
  }

  /// Push the device's wishlist into the account's favourites.
  ///
  /// `POST /api/shop/favorites/{id}` **ADDS, and is idempotent** —
  /// probed live: sending it twice answers "Product added to favorites."
  /// both times and leaves exactly one row. So there is no need to read
  /// the account's list first, and no risk of a blind push turning off
  /// a heart the customer already had on.
  static Future<HandoverResult> wishlist(
    GuestWishlist wishlist, {
    CancelToken? cancelToken,
  }) async {
    wishlist.load();
    if (wishlist.isEmpty) return const HandoverResult();

    var moved = 0;
    var refused = 0;

    for (final product in List.of(wishlist.items)) {
      final result = await ShopApis.addFavorite(
        '${product.id}',
        cancelToken: cancelToken,
      );
      if (result is Success) {
        moved += 1;
        wishlist.remove(product.id);
      } else {
        refused += 1;
      }
    }

    return HandoverResult(moved: moved, refused: refused);
  }

  /// Push the device's address book into the account.
  ///
  /// `POST /api/addresses` takes the whole address; the local rows
  /// carry every field the form collected, so nothing has to be asked
  /// for again. See [GuestAddresses].
  ///
  /// The LAT and LNG are the one place this has to convert: the model
  /// stores them as strings because that is how the server sends them,
  /// and the create endpoint wants numbers. They are coordinates, not
  /// money — parsing them is not the thing `design_conventions_test`
  /// forbids — but an unparseable pair is refused rather than sent as
  /// a zero, which would put the customer's door in the Gulf of
  /// Guinea.
  ///
  /// `is_default` travels too. The server demotes the rest when it
  /// arrives, which is the same rule the device book keeps, so the one
  /// the customer marked stays the one they marked.
  static Future<HandoverResult> addresses(
    GuestAddresses book, {
    CancelToken? cancelToken,
  }) async {
    book.load();
    if (book.isEmpty) return const HandoverResult();

    var moved = 0;
    var refused = 0;

    // Sequentially, like the basket: `is_default` demotes the others,
    // and two of those racing decides the default by whichever reply
    // lands last.
    for (final address in List.of(book.items)) {
      final lat = double.tryParse(address.lat);
      final lng = double.tryParse(address.lng);
      if (lat == null || lng == null) {
        refused += 1;
        continue;
      }

      final result = await AddressApis.addAddress(
        buildingNumber: address.buildingNumber,
        street: address.street,
        district: address.district,
        postalCode: address.postalCode,
        additionalNumber: address.additionalNumber,
        lat: lat,
        lng: lng,
        phone: address.phone,
        label: address.label,
        unitNumber: address.unitNumber,
        shortAddress: address.shortAddress,
        deliveryZoneId: address.deliveryZoneId,
        notes: address.notes,
        isDefault: address.isDefault,
        cancelToken: cancelToken,
      );
      if (result is Success) {
        moved += 1;
        book.remove(address.id);
      } else {
        // A 422 on a postal code the CMS will not take, or a pin
        // outside Saudi Arabia. Left on the device so the customer can
        // fix it rather than losing what they typed.
        refused += 1;
      }
    }

    return HandoverResult(moved: moved, refused: refused);
  }
}
