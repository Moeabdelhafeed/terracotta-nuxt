import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';

import '../../../core/utils/money_minor_units.dart';
import '../../../data/models/terracotta/commerce/cart.dart';
import '../../../data/models/terracotta/commerce/cart_item.dart';
import '../../../data/models/terracotta/commerce/line_product.dart';
import '../../../data/models/terracotta/core/api_image.dart';
import '../../shop/data/stock.dart';

/// One piece a visitor picked before they had an account.
///
/// Carries enough of the PRODUCT to draw the row without a network
/// call, because the whole point is that this works with no session —
/// and the cart sheet must open the same on a plane as it does on wifi.
@immutable
class BasketLine {
  const BasketLine({
    required this.productId,
    required this.title,
    required this.unitPrice,
    required this.quantity,
    this.wasPrice,
    this.color,
    this.image,
  });

  factory BasketLine.fromJson(Map<String, dynamic> json) => BasketLine(
    productId: json['product_id'] as int,
    title: json['title'] as String,
    unitPrice: json['unit_price'] as String,
    wasPrice: json['was_price'] as String?,
    quantity: json['quantity'] as int,
    color: json['color'] as String?,
    image: json['image'] == null
        ? null
        : ApiImage.fromJson(Map<String, dynamic>.from(json['image'] as Map)),
  );

  final int productId;
  final String title;

  /// Money, as a decimal STRING — the same discipline as the wire, so a
  /// line that came from here and one that came from the server can sit
  /// in the same list without one of them having been through a double.
  final String unitPrice;
  final String? wasPrice;

  final int quantity;

  /// The chosen colour, kept even though the SERVER drops it (see
  /// `docs/api-contract.md` §18). A local basket can at least show the
  /// customer what they picked.
  final String? color;

  /// The picture, stored WHOLE rather than as a url and a blurhash.
  /// It is a Freezed model with its own JSON, so a round trip through
  /// the device loses nothing and invents nothing — an `ApiImage` built
  /// by hand would need an `id` and a `type` this has no business
  /// guessing.
  final ApiImage? image;

  /// What separates two lines. Same piece in another colour is another
  /// line, which is how the studio's own cart used to behave.
  String get key => '$productId::${color ?? ''}';

  BasketLine copyWith({int? quantity}) => BasketLine(
    productId: productId,
    title: title,
    unitPrice: unitPrice,
    wasPrice: wasPrice,
    quantity: quantity ?? this.quantity,
    color: color,
    image: image,
  );

  Map<String, dynamic> toJson() => {
    'product_id': productId,
    'title': title,
    'unit_price': unitPrice,
    'was_price': wasPrice,
    'quantity': quantity,
    'color': color,
    'image': image?.toJson(),
  };
}

/// «سلتي» before there is an account behind it.
///
/// The server refuses `/api/shop/cart` outright for a guest — probed
/// live, 401 on both the read and the add (`docs/api-contract.md` §17).
/// So a visitor either builds a basket on the device or hits a wall the
/// moment they like something, and a wall is how you lose them.
///
/// It is deliberately shaped to become a `Cart`: the sheet, the badge
/// and the row widgets all take the wire model and none of them needs
/// to know which kind of basket they are looking at.
class GuestBasket extends ChangeNotifier {
  GuestBasket({Storage? storage}) : _injected = storage;

  static const storageKey = 'guest_basket_v1';

  final Storage? _injected;
  Storage get _storage => _injected ?? HydratedBloc.storage;

  final List<BasketLine> _lines = [];
  bool _loaded = false;

  List<BasketLine> get lines => List.unmodifiable(_lines);
  bool get isEmpty => _lines.isEmpty;
  int get pieceCount => _lines.fold(0, (sum, l) => sum + l.quantity);

  /// Read what is on the device. Idempotent; safe on every start.
  void load() {
    if (_loaded) return;
    _loaded = true;
    // A basket is a convenience, never a reason to fail to start. Bad
    // JSON on disk (a downgrade, a half-written record) means an empty
    // basket, not a crash on launch.
    try {
      final raw = _storage.read(storageKey);
      if (raw is Map && raw['lines'] is List) {
        for (final entry in raw['lines'] as List) {
          if (entry is Map) {
            _lines.add(BasketLine.fromJson(Map<String, dynamic>.from(entry)));
          }
        }
      }
    } on Object {
      _lines.clear();
    }
  }

  Future<void> _save() => _storage.write(storageKey, {
    'lines': _lines.map((l) => l.toJson()).toList(),
  });

  /// Put a piece in, or add to the line that is already there.
  ///
  /// [ceiling] is the piece's `max_quantity`, so a local basket cannot
  /// be filled past what the server would ever accept — otherwise the
  /// refusal only arrives at sign-in, when the customer has stopped
  /// thinking about it.
  void add(BasketLine line, {int? ceiling}) {
    load();
    final cap = Stock.ceiling(ceiling);
    final at = _lines.indexWhere((l) => l.key == line.key);
    if (at == -1) {
      _lines.add(line.copyWith(quantity: line.quantity.clamp(1, cap)));
    } else {
      final merged = _lines[at].quantity + line.quantity;
      _lines[at] = _lines[at].copyWith(quantity: merged.clamp(1, cap));
    }
    unawaited(_save());
    notifyListeners();
  }

  void setQuantity(String key, int quantity, {int? ceiling}) {
    load();
    final at = _lines.indexWhere((l) => l.key == key);
    if (at == -1) return;
    if (quantity < 1) return remove(key);
    _lines[at] = _lines[at].copyWith(
      quantity: quantity.clamp(1, Stock.ceiling(ceiling)),
    );
    unawaited(_save());
    notifyListeners();
  }

  void remove(String key) {
    load();
    if (!_lines.any((l) => l.key == key)) return;
    _lines.removeWhere((l) => l.key == key);
    unawaited(_save());
    notifyListeners();
  }

  void clear() {
    load();
    if (_lines.isEmpty) return;
    _lines.clear();
    unawaited(_save());
    notifyListeners();
  }

  /// The basket as the wire model, so every widget downstream is blind
  /// to where it came from.
  ///
  /// Line ids are NEGATIVE and derived from the position: a real cart
  /// line id is a server row and these are not, and a negative one can
  /// never collide with a server line if the two ever meet in a list.
  Cart toCart() {
    load();
    var i = 0;
    return Cart(
      totalPrice: _total(),
      items: [
        for (final l in _lines)
          CartItem(
            id: -(++i),
            quantity: l.quantity,
            unitPrice: l.unitPrice,
            lineTotal: _times(l.unitPrice, l.quantity),
            color: l.color,
            product: LineProduct(
              id: l.productId,
              title: l.title,
              price: l.wasPrice ?? l.unitPrice,
              salePrice: l.wasPrice == null ? null : l.unitPrice,
              image: l.image,
              isFeatured: false,
              isFavorited: false,
            ),
          ),
      ],
    );
  }

  String _total() =>
      MinorUnits.sumLines([for (final l in _lines) (l.unitPrice, l.quantity)]);

  /// Money stays a decimal STRING end to end — see [MinorUnits], which
  /// owns the arithmetic for the whole app.
  static String _times(String unit, int by) => MinorUnits.times(unit, by);
}
