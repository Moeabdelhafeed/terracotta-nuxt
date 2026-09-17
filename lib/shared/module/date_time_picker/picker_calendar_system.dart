import 'package:intl/intl.dart' hide TextDirection;

import '../../../core/localization/number_formatter.dart';
import '../../../core/localization/strings/date_field_strings.dart';
import '../../../core/utils/hijri_date.dart';

/// Which calendar the month grid counts in.
enum PickerCalendar {
  gregorian,
  hijri;

  PickerCalendarSystem get system => switch (this) {
    PickerCalendar.gregorian => const GregorianSystem(),
    PickerCalendar.hijri => const HijriSystem(),
  };
}

/// Everything the month grid needs to know about a calendar.
///
/// The grid works in ANCHORS — a `DateTime` that is day 1 of some month
/// in this system — and in plain `DateTime`s for the days themselves.
/// The value a picker reports is always a `DateTime`, whichever
/// calendar drew it; only the counting changes.
///
/// Weekdays are deliberately absent: a week is seven days in both
/// calendars and `DateTime.weekday` already answers for both, which is
/// why the grid's column arithmetic needed no changes at all.
abstract class PickerCalendarSystem {
  const PickerCalendarSystem();

  /// Day 1 of the month [date] falls in.
  DateTime firstOfMonth(DateTime date);

  /// How many days that month has — 28 to 31, or 29 to 30.
  int daysInMonth(DateTime anchor);

  /// [count] months later (or earlier, when negative).
  DateTime addMonths(DateTime anchor, int count);

  /// How many months [b] is after [a].
  int monthsBetween(DateTime a, DateTime b);

  /// Day 1 of ([year], [month]).
  DateTime anchorFor(int year, int month);

  /// The [n]th day of [anchor]'s month. Out-of-range values run into
  /// the neighbouring months, which is what the grid's leading and
  /// trailing blanks want.
  DateTime dayOf(DateTime anchor, int n) =>
      DateTime(anchor.year, anchor.month, anchor.day + n - 1);

  /// Which day of its month [date] is.
  int dayNumberOf(DateTime date);

  /// Which year [date] is in.
  int yearOf(DateTime date);

  /// The month's name, in the reader's language.
  String monthName(DateTime anchor);

  /// All twelve, for the month grid.
  List<String> monthNames();

  /// A whole date, spelled out — the label a day cell announces.
  String describe(DateTime date);

  /// The same date, short enough for a trigger or an app bar.
  String describeShort(DateTime date);
}

/// The calendar `DateTime` already counts in.
class GregorianSystem extends PickerCalendarSystem {
  const GregorianSystem();

  @override
  DateTime firstOfMonth(DateTime date) => DateTime(date.year, date.month);

  @override
  int daysInMonth(DateTime anchor) =>
      DateTime(anchor.year, anchor.month + 1, 0).day;

  @override
  DateTime addMonths(DateTime anchor, int count) =>
      DateTime(anchor.year, anchor.month + count);

  @override
  int monthsBetween(DateTime a, DateTime b) =>
      (b.year - a.year) * 12 + b.month - a.month;

  @override
  DateTime anchorFor(int year, int month) => DateTime(year, month);

  @override
  int dayNumberOf(DateTime date) => date.day;

  @override
  int yearOf(DateTime date) => date.year;

  @override
  String monthName(DateTime anchor) => DateFormat.MMMM().format(anchor);

  @override
  List<String> monthNames() => DateFormat.MMM().dateSymbols.SHORTMONTHS;

  @override
  String describe(DateTime date) =>
      AppNumbers.localizeDigits(DateFormat.yMMMMEEEEd().format(date));

  @override
  String describeShort(DateTime date) =>
      AppNumbers.localizeDigits(DateFormat.yMMMd().format(date));
}

/// The civil (tabular) Islamic calendar.
///
/// It rides `HijriDate`, which converts through the Julian Day Number
/// and so round-trips exactly. That calendar tracks the observational,
/// sighting-based ones to within a day — fine for picking a date, not
/// authoritative for a religious one, and the module's CLAUDE.md says
/// so where an adopter will read it.
class HijriSystem extends PickerCalendarSystem {
  const HijriSystem();

  @override
  DateTime firstOfMonth(DateTime date) {
    final h = HijriDate.fromGregorian(date);
    return HijriDate(h.year, h.month, 1).toGregorian();
  }

  @override
  int daysInMonth(DateTime anchor) {
    final h = HijriDate.fromGregorian(anchor);
    return HijriDate.daysInMonth(h.year, h.month);
  }

  @override
  DateTime addMonths(DateTime anchor, int count) {
    final h = HijriDate.fromGregorian(anchor);
    final total = h.year * 12 + (h.month - 1) + count;
    return HijriDate(total ~/ 12, total % 12 + 1, 1).toGregorian();
  }

  @override
  int monthsBetween(DateTime a, DateTime b) {
    final ha = HijriDate.fromGregorian(a);
    final hb = HijriDate.fromGregorian(b);
    return (hb.year - ha.year) * 12 + hb.month - ha.month;
  }

  @override
  DateTime anchorFor(int year, int month) =>
      HijriDate(year, month, 1).toGregorian();

  @override
  int dayNumberOf(DateTime date) => HijriDate.fromGregorian(date).day;

  @override
  int yearOf(DateTime date) => HijriDate.fromGregorian(date).year;

  @override
  String monthName(DateTime anchor) =>
      HijriDate.fromGregorian(anchor).monthName;

  @override
  List<String> monthNames() => Intl.getCurrentLocale().startsWith('ar')
      ? HijriDate.monthNamesAr
      : HijriDate.monthNamesEn;

  @override
  String describe(DateTime date) {
    final h = HijriDate.fromGregorian(date);
    // The weekday is the same day whichever calendar names it, so it
    // comes from `intl` — only the numbers and the month change.
    final weekday = DateFormat.EEEE().format(date);
    return DateFieldStrings.hijri(
      '$weekday, ${AppNumbers.padded(h.day, width: 1)} ${h.monthName} '
      '${AppNumbers.padded(h.year, width: 4)}',
    );
  }

  @override
  String describeShort(DateTime date) {
    final h = HijriDate.fromGregorian(date);
    return DateFieldStrings.hijri(
      '${AppNumbers.padded(h.day, width: 1)} ${h.monthName} '
      '${AppNumbers.padded(h.year, width: 4)}',
    );
  }
}
