import 'package:flutter/foundation.dart';

import '../../../core/localization/number_formatter.dart';
import '../../../core/localization/strings/cart_strings.dart';
import '../../../data/models/terracotta/commerce/cart.dart';
import '../../../data/models/terracotta/commerce/cart_item.dart';

/// One line the studio can no longer fill as ordered.
@immutable
class StockProblem {
  const StockProblem({required this.item, required this.available});

  final CartItem item;

  /// How many are left. **Zero means gone**, and the two are different
  /// offers to the customer: one can be lowered, the other can only be
  /// taken out.
  final int available;

  bool get isGone => available <= 0;

  /// What went wrong, in the customer's own words — naming the piece,
  /// because a basket of six says nothing without it.
  String get sentence => isGone
      ? CartStrings.stockGone(item.product.title)
      : CartStrings.stockLeft(
          title: item.product.title,
          wanted: item.quantity,
          left: available,
        );
}

/// What a cart re-read says about the stock behind it.
///
/// The server sends `in_stock` and `available_stock` on **every cart
/// line** (probed live — `docs/api-contract.md` §18), so this needs no
/// extra request: a plain refresh already carries the answer. That is
/// what makes it cheap enough to run on every pull-to-refresh and again
/// on the pay button, which is the last moment it still matters.
class CartStockCheck {
  const CartStockCheck._();

  /// The lines that cannot be checked out as they stand.
  ///
  /// **An untracked line is never a problem.** `available_stock` is null
  /// for the 13 of 15 live products that track no stock, and reading
  /// that as zero would condemn almost every basket.
  static List<StockProblem> problems(Cart? cart) {
    if (cart == null) return const [];
    return [
      for (final item in cart.items)
        if (_available(item) case final left?)
          if (left < item.quantity) StockProblem(item: item, available: left),
    ];
  }

  /// How many are really available for this line, or null when nothing
  /// limits it.
  ///
  /// `in_stock: false` is an explicit ZERO — the count may still be
  /// null there, and a sold-out piece with no count is the case a
  /// null-only reading would miss entirely.
  static int? _available(CartItem item) {
    if (item.inStock == false) return 0;
    return item.availableStock;
  }

  /// What the app would do if the customer asks it to sort the basket
  /// out: lower what it can, drop what is gone.
  ///
  /// Returned as a plan rather than executed here so the sheet can say
  /// what will happen BEFORE it happens, and so one code path serves
  /// both the local basket and the server's.
  /// The new quantity IS what is left — which is zero for a piece that
  /// is gone, and zero is a remove. No branch: `isGone` is defined as
  /// "nothing left", so the two cases are one rule.
  static List<StockFix> fixes(List<StockProblem> problems) => [
    for (final p in problems) StockFix(item: p.item, quantity: p.available),
  ];
}

/// One change to make: a new quantity, or zero to take the line out.
@immutable
class StockFix {
  const StockFix({required this.item, required this.quantity});

  final CartItem item;

  /// Zero means REMOVE. The API has no cart line of nothing — the
  /// stepper's minus at one removes for the same reason.
  final int quantity;

  bool get removes => quantity <= 0;
}

/// «المتبقي ٣ فقط» — the badge on a line that is over its stock.
String overLabel(int left) =>
    AppNumbers.localizeDigits(CartStrings.lineOver(left));
