import 'package:flutter/foundation.dart';

/// Which products the reader has favourited SINCE the app started,
/// across every screen that shows one.
///
/// ## Why this exists
///
/// Home and the shop each hold their own copy of a product, in their
/// own cubit, and both are singletons that deliberately do NOT refetch
/// when the reader switches tabs — that was the fix for home → gallery
/// → home re-requesting everything. The cost is that they can disagree:
/// favourite a piece in the shop and home still has the row it loaded,
/// with the heart empty, until something else makes it reload.
///
/// The same product really is in both payloads — `GET /api/home` and
/// `GET /api/shop/home` overlap, and within each one the featured rail
/// and the offers rail overlap again.
///
/// So the heart's truth lives HERE rather than in either payload, and
/// each screen paints over its own rows with whatever this knows. It
/// holds only what has CHANGED: a product nobody has touched this
/// session is not in the map, and its payload value stands.
class FavoritesRegistry extends ChangeNotifier {
  final Map<int, bool> _byId = {};

  /// What the reader last did to this product, or null if they have not
  /// touched it — in which case the payload's own value is the truth.
  bool? statusOf(int productId) => _byId[productId];

  /// Whether [fromPayload] should be overridden for this product.
  bool resolve(int productId, {required bool fromPayload}) =>
      _byId[productId] ?? fromPayload;

  /// Records a change the SERVER accepted.
  ///
  /// Called after the write, not before: an optimistic flip that the
  /// server then refused must not leave every other screen believing
  /// it.
  void record(int productId, {required bool favorited}) {
    if (_byId[productId] == favorited) return;
    _byId[productId] = favorited;
    notifyListeners();
  }

  /// Everything known, for a screen patching a freshly loaded payload.
  Map<int, bool> get overrides => Map.unmodifiable(_byId);

  @visibleForTesting
  void clear() {
    if (_byId.isEmpty) return;
    _byId.clear();
    notifyListeners();
  }
}
