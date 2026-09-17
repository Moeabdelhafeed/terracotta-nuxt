import '../../../core/localization/strings/shop_strings.dart';

/// How much of a piece is left, as far as the customer needs to care.
///
/// Three states, from ONE rule, so a card, a detail page and a cart row
/// can never disagree about the same piece.
enum StockLevel {
  /// Nothing to sell. The add button goes away — not disabled with a
  /// price still beside it, which reads as a bug.
  none,

  /// Fewer than [Stock.lowWater] left. Worth saying out loud: it is the
  /// difference between buying now and coming back to nothing.
  low,

  /// Enough that a number would be noise.
  fine,
}

/// The stock rule, in one place.
///
/// **`stock: null` means UNTRACKED, never zero.** 13 of the 15 live
/// products carry no stock count at all, and reading null as "none
/// left" would empty the shop. `in_stock` is the field that says sold
/// out; see `docs/api-contract.md` §18.
class Stock {
  const Stock._();

  /// Below this, the count is worth showing.
  static const lowWater = 5;

  /// The hard cap the server puts on one order, whatever the stock.
  static const perOrderCap = 100;

  static StockLevel level({required bool inStock, int? stock}) {
    if (!inStock || stock == 0) return StockLevel.none;
    if (stock != null && stock < lowWater) return StockLevel.low;
    return StockLevel.fine;
  }

  /// What to print, or null when there is nothing worth saying.
  static String? label({required bool inStock, int? stock}) =>
      switch (level(inStock: inStock, stock: stock)) {
        StockLevel.none => ShopStrings.outOfStock,
        StockLevel.low => ShopStrings.stockLeft(stock!),
        StockLevel.fine => null,
      };

  /// The most the stepper may reach.
  ///
  /// `max_quantity` is what the SERVER will accept — `stock` when the
  /// piece is tracked, [perOrderCap] when it is not — so it is the only
  /// number worth capping against. Falling back to the cap when it is
  /// absent keeps an order line (which carries no stock at all) usable.
  static int ceiling(int? maxQuantity) => maxQuantity ?? perOrderCap;

  /// Why the plus stopped, in words the customer can act on.
  ///
  /// The two refusals are different facts: running out of a piece is
  /// about the piece, and the 100 cap is about the order.
  static String reachedMessage(int ceiling) => ceiling < perOrderCap
      ? ShopStrings.maxReached(ceiling)
      : ShopStrings.maxPerOrder;
}
