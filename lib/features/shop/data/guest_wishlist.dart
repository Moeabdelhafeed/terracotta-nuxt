import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';

import '../../../data/models/terracotta/shop/product.dart';

/// «المفضلة» before there is an account behind it.
///
/// `GET /api/shop/favorites` and the toggle behind it both answer 401
/// for a guest — probed live (`docs/api-contract.md` §17). A heart that
/// silently fails is worse than no heart at all, so a visitor's picks
/// live on the device until they have somewhere to put them.
///
/// Stores the whole [Product], not just an id: the favourites sheet has
/// to draw a row with a picture and a price, and looking fifteen
/// products up one at a time to do it would be a network round trip per
/// heart — on a screen that exists precisely because there is no
/// network session.
class GuestWishlist extends ChangeNotifier {
  GuestWishlist({Storage? storage}) : _injected = storage;

  static const storageKey = 'guest_wishlist_v1';

  final Storage? _injected;
  Storage get _storage => _injected ?? HydratedBloc.storage;

  final List<Product> _items = [];
  bool _loaded = false;

  List<Product> get items => List.unmodifiable(_items);
  bool get isEmpty => _items.isEmpty;
  int get count => _items.length;

  bool contains(int productId) {
    load();
    return _items.any((p) => p.id == productId);
  }

  /// Read what is on the device. Idempotent.
  void load() {
    if (_loaded) return;
    _loaded = true;
    // A wishlist is a convenience, never a reason to fail to start.
    try {
      final stored = _storage.read(storageKey);
      // A STRING now — see `_save`. Older devices may hold the map
      // this used to write, so both are read: dropping a wishlist on
      // upgrade is a silent loss the reader cannot explain.
      final raw = stored is String
          ? jsonDecode(stored) as Object?
          : stored as Object?;
      if (raw is Map && raw['items'] is List) {
        for (final entry in raw['items'] as List) {
          if (entry is Map) {
            _items.add(Product.fromJson(Map<String, dynamic>.from(entry)));
          }
        }
      }
    } on Object {
      _items.clear();
    }
  }

  /// Returns the state the heart should now show.
  bool toggle(Product product) {
    load();
    final at = _items.indexWhere((p) => p.id == product.id);
    if (at == -1) {
      // Stored as FAVOURITED, whatever the payload said — the payload's
      // `is_favorited` is the SERVER's opinion and the server does not
      // know about this list.
      _items.add(product.copyWith(isFavorited: true));
    } else {
      _items.removeAt(at);
    }
    unawaited(_save());
    notifyListeners();
    return at == -1;
  }

  void remove(int productId) {
    load();
    if (!_items.any((p) => p.id == productId)) return;
    _items.removeWhere((p) => p.id == productId);
    unawaited(_save());
    notifyListeners();
  }

  void clear() {
    load();
    if (_items.isEmpty) return;
    _items.clear();
    unawaited(_save());
    notifyListeners();
  }

  /// Written as a JSON STRING, not as a map of maps.
  ///
  /// `Product.toJson` is generated without `explicitToJson`, so the
  /// nested [ApiImage] comes out as the OBJECT rather than its map —
  /// and Hive's binary writer, handed a type it has no encoding for,
  /// threw out of the zone the first time anyone favourited a product
  /// with a picture. (`fromJson` would not have read it back either:
  /// it expects a map there.) Turning the annotation on is not
  /// available — a bare `@JsonSerializable` on a Freezed class makes
  /// the generator try to build for the abstract class and fail.
  ///
  /// `jsonEncode` walks the tree and calls `toJson` on whatever it
  /// meets, so the nested model is encoded properly and what reaches
  /// storage is a single string every backend can hold.
  Future<void> _save() =>
      _storage.write(storageKey, jsonEncode({'items': _items}));
}
