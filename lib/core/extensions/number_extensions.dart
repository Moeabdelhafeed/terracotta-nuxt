import 'dart:math' as math;

/// Number utility extensions.

extension NumberExtensions on num {
  // Locale-aware number/currency/percent/file-size formatting lives in
  // `core/localization/number_formatter.dart` (`AppNumbers`).

  /// Ordinal suffix (English): `1.toOrdinal()` → "1st", `22` → "22nd".
  /// Not localized — fine for IDs and counts; for translated copy use
  /// the i18n stack.
  String toOrdinal() {
    final n = toInt();
    final abs = n.abs();
    final lastTwo = abs % 100;
    final lastOne = abs % 10;

    String suffix;
    if (lastTwo >= 11 && lastTwo <= 13) {
      suffix = 'th';
    } else {
      suffix = switch (lastOne) {
        1 => 'st',
        2 => 'nd',
        3 => 'rd',
        _ => 'th',
      };
    }
    return '$n$suffix';
  }

  // ─── Clamping & rounding ──────────────────────────────────

  /// Clamp between 0 and 1.
  double get normalized => toDouble().clamp(0.0, 1.0);

  /// Round to [places] decimal places.
  double roundTo(int places) {
    final mod = math.pow(10, places);
    return (toDouble() * mod).roundToDouble() / mod;
  }

  // ─── Duration shortcuts ───────────────────────────────────

  Duration get milliseconds => Duration(milliseconds: toInt());
  Duration get seconds => Duration(seconds: toInt());
  Duration get minutes => Duration(minutes: toInt());
  Duration get hours => Duration(hours: toInt());
  Duration get days => Duration(days: toInt());
}
