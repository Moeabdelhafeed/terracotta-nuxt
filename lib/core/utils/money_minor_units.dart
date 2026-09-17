/// Money stays a decimal STRING end to end — `"65.00"`, never a
/// number.
///
/// Arithmetic happens in integer minor units and nowhere else: a
/// `double` rounds `35.10 × 3` to something the customer would spot at
/// checkout, and the API went out of its way to send strings.
///
/// This is the app's ONE copy of that arithmetic. It is deliberately
/// small and deliberately shared — a second copy is a second rounding
/// rule, and `design_conventions_test` bans the shortcut that would
/// otherwise be taken instead.
abstract final class MinorUnits {
  /// A decimal string as whole minor units (halalas). Anything
  /// unparseable reads as zero rather than throwing: this runs while
  /// painting a screen, and a malformed price from the CMS must not
  /// take the page down with it.
  static int of(String amount) {
    final parts = amount.trim().split('.');
    final whole = int.tryParse(parts.first) ?? 0;
    final frac = parts.length > 1
        ? int.tryParse(parts[1].padRight(2, '0').substring(0, 2)) ?? 0
        : 0;
    return whole * 100 + frac;
  }

  /// Minor units back to the wire's own shape, two places always.
  static String format(int units) =>
      '${units ~/ 100}.${(units % 100).toString().padLeft(2, '0')}';

  /// One unit price, [by] times.
  static String times(String unit, int by) => format(of(unit) * by);

  /// The sum of `(price, quantity)` lines.
  static String sumLines(Iterable<(String, int)> lines) {
    var units = 0;
    for (final (price, quantity) in lines) {
      units += of(price) * quantity;
    }
    return format(units);
  }
}
