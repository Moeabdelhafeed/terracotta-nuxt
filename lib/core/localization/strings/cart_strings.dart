import '../../../generated/l10n.dart';
import '../number_formatter.dart';
import '../tr.dart';

/// Cart feature strings — demonstrates the **pluralized** pattern via
/// [Tr.plural]. The auto-detect resolution order:
///
/// 1. Remote ICU template under `'cart_items'` → evaluated via
///    `MessageFormat`.
/// 2. Remote per-category entries (`cart_items__one`,
///    `cart_items__other`, …) → picked based on CLDR plural logic.
/// 3. Remote plain string → used as-is with `{count}` interpolation.
/// 4. ARB-generated fallback → `S.current.cart_items(count)`.
class CartStrings {
  CartStrings._();

  static String items(int count) =>
      Tr.plural('cart_items', count, S.current.cart_items(count));

  static String notifications(int count) => Tr.plural(
    'notifications_count',
    count,
    S.current.notifications_count(count),
  );

  /// Stock that ran out while the basket sat there.
  ///
  /// Counts go through `localizeDigits`: an ICU placeholder
  /// interpolates in ASCII even under `ar`.
  static String get stockTitle =>
      Tr.t('cart_stock_title', S.current.cart_stock_title);
  static String get stockBody =>
      Tr.t('cart_stock_body', S.current.cart_stock_body);

  /// Names the PIECE. A basket of six says nothing without it.
  static String stockLeft({
    required String title,
    required int wanted,
    required int left,
  }) => AppNumbers.localizeDigits(
    Tr.t(
      'cart_stock_line_left',
      S.current.cart_stock_line_left(title, wanted, left),
    ),
  );
  static String stockGone(String title) => Tr.t(
    'cart_stock_line_gone',
    S.current.cart_stock_line_gone(title),
  );

  static String get stockFix =>
      Tr.t('cart_stock_fix', S.current.cart_stock_fix);
  static String get stockFixNote =>
      Tr.t('cart_stock_fix_note', S.current.cart_stock_fix_note);
  static String get stockKeep =>
      Tr.t('cart_stock_keep', S.current.cart_stock_keep);
  static String get stockKeepNote =>
      Tr.t('cart_stock_keep_note', S.current.cart_stock_keep_note);
  static String get stockFixed =>
      Tr.t('cart_stock_fixed', S.current.cart_stock_fixed);

  static String lineOver(int left) =>
      Tr.t('cart_line_over', S.current.cart_line_over(left));
}
