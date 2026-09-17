import 'dart:math' as math;

import 'package:intl/intl.dart';

/// Locale-aware number formatters wrapping `package:intl`'s
/// [NumberFormat]. Every method defaults the locale to
/// [Intl.getCurrentLocale] so formatting picks up language switches
/// automatically — no need to thread a locale through your code.
///
/// ## Digit shapes
/// `intl` honors the locale's native digits, and WHICH locales those
/// are is not guessable — verify rather than assume. In the bundled
/// data, `ar_EG` emits Arabic-Indic numerals (٠١٢٣٤) while plain `ar`
/// and `ar_SA` emit Western ones with directional marks; `fa` and `ps`
/// emit Extended Arabic-Indic (۰۱۲۳۴), `bn` emits Bengali (০১২৩৪), and
/// `ur` and `hi` emit Western. (This comment previously had the two
/// Arabic locales exactly backwards.)
///
/// To force one shape across all locales, pass `locale: 'en'` for
/// Western or bypass this class and configure [NumberFormat] manually.
///
/// ## Performance
/// [NumberFormat] instances are lightweight but not free to construct.
/// These helpers create a fresh instance per call, which is fine for
/// typical UI use. For tight loops (e.g. formatting 10 000 list rows),
/// hoist one instance out of the loop.
///
/// ```dart
/// AppNumbers.decimal(1234.5);              // "1,234.5"   (en)
/// AppNumbers.currency(9.99);               // "$9.99"     (en-US)
/// AppNumbers.currency(9.99, code: 'EUR');  // "€9.99"
/// AppNumbers.percent(0.245);               // "24.5%"
/// AppNumbers.compact(1_500_000);           // "1.5M"
/// AppNumbers.fileSize(1_536_000);          // "1.46 MB"
/// ```
class AppNumbers {
  AppNumbers._();

  /// Whether a locale that has a native-digit variant should USE it.
  ///
  /// The app sets `Intl.defaultLocale` from the chosen language, so
  /// switching to Arabic sets it to `'ar'` — and plain `ar` formats in
  /// WESTERN digits. Switching the app to Arabic and still reading
  /// `42%` is the bug this exists to fix.
  ///
  /// Set `false` to keep Western digits in every language, which some
  /// people prefer for anything numeric-heavy.
  static bool preferNativeDigits = true;

  /// Locales whose base tag formats in Western digits while a regional
  /// variant formats in the script's own.
  ///
  /// Deliberately SHORT and verified against the bundled `intl` data —
  /// see the digit-shape note above. Adding a row means checking what
  /// that locale actually emits, not what it ought to.
  static const _nativeDigitVariant = <String, String>{'ar': 'ar_EG'};

  static String _locale(String? override) {
    final locale = override ?? Intl.getCurrentLocale();
    if (!preferNativeDigits) return locale;
    // Match the LANGUAGE, so `ar`, `ar_JO` and `ar-SA` all land on the
    // variant. A locale that already names a region keeps it only when
    // the base has no native-digit variant at all.
    final language = locale.split(RegExp('[_-]')).first;
    return _nativeDigitVariant[language] ?? locale;
  }

  // ─── Decimal ───────────────────────────────────────────────────────

  /// Locale-aware decimal format. [fractionDigits] pins the number of
  /// digits after the separator; omit for [NumberFormat]'s default
  /// (which varies by locale, typically 3).
  static String decimal(
    num value, {
    int? fractionDigits,
    String? locale,
  }) {
    final f = NumberFormat.decimalPattern(_locale(locale));
    if (fractionDigits != null) {
      f
        ..minimumFractionDigits = fractionDigits
        ..maximumFractionDigits = fractionDigits;
    }
    return f.format(value);
  }

  /// Zero-fraction integer formatting with thousands separators.
  static String integer(num value, {String? locale}) =>
      decimal(value, fractionDigits: 0, locale: locale);

  /// Zero-padded to [width] digits, in the LOCALE's own digits and with
  /// no grouping — for clock faces and counters, where `1:07` must not
  /// become `1:7`.
  ///
  /// Padding a formatted string with an ASCII `'0'` would mix digit
  /// systems: `١:07` in Arabic. The pattern does the padding, so the
  /// zero is the locale's own.
  static String padded(int value, {required int width, String? locale}) =>
      NumberFormat('0' * width, _locale(locale)).format(value);

  /// Rewrites the ASCII digits in [text] into the locale's own.
  ///
  /// For text that is NOT a number — a formatted date, a duration, a
  /// sentence with a count in it. `DateFormat` reads its month and
  /// weekday names from the app's locale, and switching that locale to
  /// the native-digit variant to get Arabic-Indic numerals would take
  /// the variant's month names with it. This changes the digits and
  /// nothing else.
  ///
  /// A no-op when the locale already writes in ASCII, or when
  /// [preferNativeDigits] is off.
  static String localizeDigits(String text, {String? locale}) {
    final zero = NumberFormat('0', _locale(locale)).format(0);
    if (zero == '0' || zero.length != 1) return text;

    final base = zero.codeUnitAt(0);
    final out = StringBuffer();
    for (final unit in text.codeUnits) {
      if (unit >= 0x30 && unit <= 0x39) {
        out.writeCharCode(base + (unit - 0x30));
      } else {
        out.writeCharCode(unit);
      }
    }
    return out.toString();
  }

  // ─── Percent ───────────────────────────────────────────────────────

  /// Percentage — multiplies by 100 (pass `0.25` to get "25%").
  static String percent(
    num fraction, {
    int fractionDigits = 0,
    String? locale,
  }) {
    final f = NumberFormat.percentPattern(_locale(locale))
      ..minimumFractionDigits = fractionDigits
      ..maximumFractionDigits = fractionDigits;
    return f.format(fraction);
  }

  // ─── Currency ──────────────────────────────────────────────────────

  /// Currency format with either an explicit ISO 4217 [code]
  /// (e.g. `'USD'`, `'EUR'`, `'JOD'`) or a display [symbol] (`'$'`, `'€'`).
  /// Pass neither to use the locale's default currency.
  ///
  /// [fractionDigits] overrides the currency's default precision —
  /// USD defaults to 2, JPY to 0; override only if you need custom
  /// rounding.
  static String currency(
    num value, {
    String? code,
    String? symbol,
    int? fractionDigits,
    String? locale,
  }) {
    final f = NumberFormat.currency(
      locale: _locale(locale),
      name: code,
      symbol: symbol,
      decimalDigits: fractionDigits,
    );
    return f.format(value);
  }

  /// Variant that uses the currency's 3-letter code ('USD 9.99')
  /// instead of its display symbol. Handy for receipts / exports where
  /// the symbol might be ambiguous ($ → USD, CAD, AUD, …).
  static String currencyCode(
    num value, {
    required String code,
    int? fractionDigits,
    String? locale,
  }) {
    final f = NumberFormat.currency(
      locale: _locale(locale),
      name: code,
      decimalDigits: fractionDigits,
    );
    return f.format(value);
  }

  // ─── Compact (1.2K / 3.5M / 1.2B) ──────────────────────────────────

  /// Compact number — "1.2K", "3.5M", "1.2B". Locale-aware suffixes.
  static String compact(num value, {String? locale}) {
    return NumberFormat.compact(locale: _locale(locale)).format(value);
  }

  /// Compact with explicit decimal places. `compact(1500)` → `"1.5K"`;
  /// `compactLong(1500)` → `"1.5 thousand"`.
  static String compactLong(num value, {String? locale}) {
    return NumberFormat.compactLong(locale: _locale(locale)).format(value);
  }

  /// Compact currency — "$1.2K", "€3.5M".
  static String compactCurrency(
    num value, {
    String? code,
    String? symbol,
    int? fractionDigits,
    String? locale,
  }) {
    return NumberFormat.compactCurrency(
      locale: _locale(locale),
      name: code,
      symbol: symbol,
      decimalDigits: fractionDigits,
    ).format(value);
  }

  // ─── File size ─────────────────────────────────────────────────────

  /// Human-readable byte size. Defaults to **binary** units (1 KiB =
  /// 1024 B), the convention for file sizes on disk. Pass
  /// `binary: false` for SI (1 kB = 1000 B) — common in network /
  /// storage specs.
  ///
  /// Uses the locale's decimal formatter for the numeric portion so
  /// `1.5 MB` renders as `١٫٥ م.ب` in Arabic-Indic locales.
  static String fileSize(
    int bytes, {
    bool binary = true,
    int fractionDigits = 2,
    String? locale,
  }) {
    if (bytes < 0) {
      return '-${fileSize(-bytes, binary: binary, fractionDigits: fractionDigits, locale: locale)}';
    }
    if (bytes == 0) return '0 B';

    final base = binary ? 1024 : 1000;
    final units = binary
        ? const ['B', 'KiB', 'MiB', 'GiB', 'TiB', 'PiB', 'EiB']
        : const ['B', 'KB', 'MB', 'GB', 'TB', 'PB', 'EB'];

    final exponent = math.min(
      (math.log(bytes) / math.log(base)).floor(),
      units.length - 1,
    );
    final value = bytes / math.pow(base, exponent);
    final unit = units[exponent];

    // Byte column gets no decimals — fractional bytes don't exist.
    final digits = exponent == 0 ? 0 : fractionDigits;
    return '${decimal(value, fractionDigits: digits, locale: locale)} $unit';
  }

  // ─── Duration (pair with Duration extension if you have one) ───────

  /// Scientific notation — "1.23E6".
  static String scientific(
    num value, {
    int fractionDigits = 2,
    String? locale,
  }) {
    final f = NumberFormat.scientificPattern(_locale(locale))
      ..minimumFractionDigits = fractionDigits
      ..maximumFractionDigits = fractionDigits;
    return f.format(value);
  }

  // ─── Signed ───────────────────────────────────────────────────────

  /// Decimal with explicit sign prefix — "+1,234.5" / "-1,234.5" /
  /// "0". Handy for deltas (trending up / down) where the sign carries
  /// meaning.
  static String signed(num value, {int? fractionDigits, String? locale}) {
    if (value == 0) {
      return decimal(0, fractionDigits: fractionDigits, locale: locale);
    }
    final formatted = decimal(
      value.abs(),
      fractionDigits: fractionDigits,
      locale: locale,
    );
    return value > 0 ? '+$formatted' : '-$formatted';
  }
}
