import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';

/// A date on the civil (tabular) Islamic calendar — the arithmetic
/// 30-year-cycle calendar used for deterministic conversion. It tracks
/// the observational (sighting-based) calendars used for religious
/// dates to within ±1 day; treat rendered dates as informative, not
/// authoritative.
///
/// Conversion goes through the Julian Day Number, so it's exact and
/// round-trips: `HijriDate.fromGregorian(h.toGregorian()) == h`.
@immutable
class HijriDate {
  const HijriDate(this.year, this.month, this.day)
    : assert(month >= 1 && month <= 12),
      assert(day >= 1 && day <= 30);

  final int year;

  /// 1 = Muharram … 12 = Dhu al-Hijjah.
  final int month;
  final int day;

  // Month-name tables are deliberately INLINE, not ARB — they're
  // calendar data, the hijri counterpart of the CLDR month tables
  // `DateFormat.MMMM` reads for gregorian. A locale without its own
  // transliterations falls back to the English ones, like CLDR does.
  static const List<String> monthNamesAr = [
    'محرم',
    'صفر',
    'ربيع الأول',
    'ربيع الآخر',
    'جمادى الأولى',
    'جمادى الآخرة',
    'رجب',
    'شعبان',
    'رمضان',
    'شوال',
    'ذو القعدة',
    'ذو الحجة',
  ];

  static const List<String> monthNamesEn = [
    'Muharram',
    'Safar',
    "Rabi' I",
    "Rabi' II",
    'Jumada I',
    'Jumada II',
    'Rajab',
    "Sha'ban",
    'Ramadan',
    'Shawwal',
    "Dhu al-Qi'dah",
    'Dhu al-Hijjah',
  ];

  /// Civil-epoch Julian Day Number — 1 Muharram 1 AH (19 July 622 in the
  /// proleptic Gregorian calendar).
  static const int _epochJdn = 1948440;

  String get monthNameAr => monthNamesAr[month - 1];
  String get monthNameEn => monthNamesEn[month - 1];

  /// Month name for the active locale.
  String get monthName =>
      Intl.getCurrentLocale().startsWith('ar') ? monthNameAr : monthNameEn;

  /// `'20 محرم 1448'` / `'20 Muharram 1448'` (era suffix is the caller's).
  String format() => '$day $monthName $year';

  /// Whether [year] is a leap year of the 30-year civil cycle (years
  /// 2, 5, 7, 10, 13, 16, 18, 21, 24, 26, 29) — the same intercalation
  /// term `(3 + 11 · year) ~/ 30` that [toGregorian] accumulates.
  static bool isLeapYear(int year) => (3 + 11 * year) % 30 >= 19;

  /// Length of ([year], [month]) on the civil calendar: months alternate
  /// 30/29 (matching [toGregorian]'s `ceil(29.5 · (month−1))` offset),
  /// with Dhu al-Hijjah gaining the leap day.
  static int daysInMonth(int year, int month) {
    assert(month >= 1 && month <= 12);
    if (month == 12) return isLeapYear(year) ? 30 : 29;
    return month.isOdd ? 30 : 29;
  }

  static int _gregorianToJdn(int year, int month, int day) {
    final a = (14 - month) ~/ 12;
    final y = year + 4800 - a;
    final m = month + 12 * a - 3;
    return day +
        (153 * m + 2) ~/ 5 +
        365 * y +
        y ~/ 4 -
        y ~/ 100 +
        y ~/ 400 -
        32045;
  }

  static DateTime _jdnToGregorian(int jdn) {
    final a = jdn + 32044;
    final b = (4 * a + 3) ~/ 146097;
    final c = a - 146097 * b ~/ 4;
    final d = (4 * c + 3) ~/ 1461;
    final e = c - 1461 * d ~/ 4;
    final m = (5 * e + 2) ~/ 153;
    final day = e - (153 * m + 2) ~/ 5 + 1;
    final month = m + 3 - 12 * (m ~/ 10);
    final year = 100 * b + d - 4800 + m ~/ 10;
    return DateTime(year, month, day);
  }

  /// Civil-calendar conversion (the classic tabular algorithm).
  factory HijriDate.fromGregorian(DateTime date) {
    final jdn = _gregorianToJdn(date.year, date.month, date.day);
    var l = jdn - _epochJdn + 10632;
    final n = (l - 1) ~/ 10631;
    l = l - 10631 * n + 354;
    final j =
        ((10985 - l) ~/ 5316) * ((50 * l) ~/ 17719) +
        (l ~/ 5670) * ((43 * l) ~/ 15238);
    l =
        l -
        ((30 - j) ~/ 15) * ((17719 * j) ~/ 50) -
        (j ~/ 16) * ((15238 * j) ~/ 43) +
        29;
    final month = (24 * l) ~/ 709;
    final day = l - (709 * month) ~/ 24;
    final year = 30 * n + j - 30;
    return HijriDate(year, month, day);
  }

  /// Midnight-local Gregorian [DateTime] of this civil Hijri date.
  DateTime toGregorian() {
    // Month offset is ceil(29.5 · (month−1)) — the months alternate 30/29.
    final jdn =
        day +
        (59 * (month - 1) + 1) ~/ 2 +
        354 * (year - 1) +
        (3 + 11 * year) ~/ 30 +
        _epochJdn -
        1;
    return _jdnToGregorian(jdn);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HijriDate &&
          other.year == year &&
          other.month == month &&
          other.day == day;

  @override
  int get hashCode => Object.hash(year, month, day);

  @override
  String toString() => 'HijriDate($year-$month-$day)';
}
