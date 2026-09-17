/// How much a sale price takes off, as a whole percentage.
///
/// ## Why this does its own arithmetic
///
/// Money on this wire is a decimal STRING and is never parsed to a
/// double — `design_conventions_test` enforces it across `lib/features`
/// and the reason is in `CLAUDE.md`: float arithmetic rounds totals
/// wrong, and the bug only shows on some amounts.
///
/// A percentage still needs numbers, so the strings are read as
/// HALALAS — integer hundredths — and the division happens there. `65.00`
/// becomes 6500, never 65.0, and nothing is ever added or multiplied in
/// floating point.
///
/// The result is a DISPLAY value, not money: it is rounded to a whole
/// percent because "-23%" is what a shopper reads, and no total is ever
/// computed from it.
abstract final class Discount {
  Discount._();

  /// `-23` for a piece marked down from 65.00 to 50.00, or null when
  /// there is no saving worth a badge.
  ///
  /// Null rather than zero for every case that is not a real markdown:
  /// no sale price, a sale price at or above the list price (the CMS
  /// does allow it), an unparseable amount, or a rounded saving of 0%.
  /// A badge saying "-0%" is worse than no badge.
  static int? percentOff({required String price, String? salePrice}) {
    if (salePrice == null) return null;

    final was = _halalas(price);
    final now = _halalas(salePrice);
    if (was == null || now == null) return null;
    if (was <= 0 || now >= was) return null;

    // INTEGER throughout. `(was - now) * 100 ~/ was` is the saving as a
    // whole percent, truncated — a 23.9% markdown shows as 23 rather
    // than being rounded up to a number the customer cannot verify
    // against the two prices beside it.
    final off = (was - now) * 100 ~/ was;
    return off <= 0 ? null : off;
  }

  /// A decimal string as integer hundredths, or null if it is not one.
  ///
  /// Tolerant of what a CMS sends: `"65"`, `"65.0"`, `"65.00"` and
  /// `" 65.5 "` all mean the same thing. More than two decimal places
  /// is truncated rather than rounded — this is a percentage, and the
  /// third place cannot move a whole percent on any price the studio
  /// sells.
  static int? _halalas(String amount) {
    final trimmed = amount.trim();
    if (trimmed.isEmpty) return null;

    final parts = trimmed.split('.');
    if (parts.length > 2) return null;

    final whole = int.tryParse(parts.first);
    if (whole == null || whole < 0) return null;
    if (parts.length == 1) return whole * 100;

    final fractionDigits = parts[1].padRight(2, '0').substring(0, 2);
    final fraction = int.tryParse(fractionDigits);
    if (fraction == null || fraction < 0) return null;

    return whole * 100 + fraction;
  }
}
