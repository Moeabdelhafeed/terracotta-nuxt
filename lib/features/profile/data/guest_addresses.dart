import 'package:flutter/foundation.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';

import '../../../data/models/terracotta/account/address.dart';

/// «عناويني» before there is an account behind it.
///
/// Every address route needs a session — `GET /api/addresses` and the
/// three writes behind it all answer 401 for a guest, the same as the
/// cart and the favourites (`docs/api-contract.md` §17). A visitor who
/// is filling a delivery address is doing it because they are about to
/// buy something, so refusing to remember it until they sign in makes
/// them type it twice.
///
/// So it lives on the device, exactly as [GuestBasket] and
/// [GuestWishlist] do.
///
/// ## The id is OURS, and negative
///
/// A local row has no server id, and inventing a positive one risks
/// colliding with a real address the moment the reader signs in and the
/// two lists sit side by side. Negative ids cannot: the server's are
/// autoincrement and always above zero. [isLocal] is how the rest of
/// the app can tell — a local row must not be sent to an endpoint that
/// would take it for a real one.
class GuestAddresses extends ChangeNotifier {
  GuestAddresses({Storage? storage}) : _injected = storage;

  static const storageKey = 'guest_addresses_v1';

  final Storage? _injected;
  Storage get _storage => _injected ?? HydratedBloc.storage;

  final List<Address> _items = [];
  bool _loaded = false;

  /// Whether [id] belongs to this device rather than to the server.
  static bool isLocal(int id) => id < 0;

  List<Address> get items {
    load();
    return List.unmodifiable(_items);
  }

  bool get isEmpty {
    load();
    return _items.isEmpty;
  }

  /// Read what is on the device. Idempotent.
  void load() {
    if (_loaded) return;
    _loaded = true;
    // An address book is a convenience, never a reason to fail to
    // start — the same rule the basket and the wishlist follow.
    try {
      final raw = _storage.read(storageKey);
      if (raw is Map && raw['items'] is List) {
        for (final entry in raw['items'] as List) {
          if (entry is Map) {
            _items.add(Address.fromJson(Map<String, dynamic>.from(entry)));
          }
        }
      }
    } on Object {
      _items.clear();
    }
  }

  /// Adds a new address, or replaces the one with the same id.
  ///
  /// Returns what was stored — with its local id filled in when it is
  /// new, because the caller needs to know what to select.
  Address save(Address address) {
    load();
    final existing = _items.indexWhere((a) => a.id == address.id);

    // NEW: one below the lowest we already hold, so two saves in a row
    // cannot land on the same id.
    final stored = existing >= 0
        ? address
        : address.copyWith(
            id: _items.isEmpty
                ? -1
                : _items.map((a) => a.id).reduce((a, b) => a < b ? a : b) - 1,
          );

    if (existing >= 0) {
      _items[existing] = stored;
    } else {
      _items.add(stored);
    }

    // THE ONLY DEFAULT. The server keeps exactly one and so does this,
    // or a checkout with two defaults has to pick and will pick wrong.
    if (stored.isDefault) _clearOtherDefaults(stored.id);
    // And a list of one is a list whose only member is the default,
    // whatever the form said.
    if (_items.length == 1 && !_items.first.isDefault) {
      _items[0] = _items.first.copyWith(isDefault: true);
    }

    _persist();
    return stored;
  }

  bool remove(int id) {
    load();
    final before = _items.length;
    _items.removeWhere((a) => a.id == id);
    if (_items.length == before) return false;

    // The list lost its default: the next one takes it, because a
    // checkout with no default has nothing to preselect.
    if (_items.isNotEmpty && !_items.any((a) => a.isDefault)) {
      _items[0] = _items.first.copyWith(isDefault: true);
    }
    _persist();
    return true;
  }

  bool makeDefault(int id) {
    load();
    final index = _items.indexWhere((a) => a.id == id);
    if (index < 0) return false;
    _items[index] = _items[index].copyWith(isDefault: true);
    _clearOtherDefaults(id);
    _persist();
    return true;
  }

  void _clearOtherDefaults(int keep) {
    for (var i = 0; i < _items.length; i++) {
      if (_items[i].id != keep && _items[i].isDefault) {
        _items[i] = _items[i].copyWith(isDefault: false);
      }
    }
  }

  void _persist() {
    notifyListeners();
    // Best effort: a device that cannot write still has the list for
    // the rest of this run.
    try {
      _storage.write(storageKey, {
        'items': [for (final a in _items) a.toJson()],
      });
    } on Object {
      // Nothing to do about it, and nothing worth failing a save for.
    }
  }

  /// Forget every one of them.
  ///
  /// Declining the handover sheet, and the tests. The sheet says so
  /// before it happens and a dialog confirms it — see
  /// `guest_handover_flow.dart`.
  void clear() {
    _items.clear();
    _loaded = true;
    _persist();
  }
}
