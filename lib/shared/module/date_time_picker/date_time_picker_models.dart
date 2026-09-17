import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart' hide TextDirection;

import '../../../core/localization/number_formatter.dart';
import '../text_field/input_formatters/date_input_formatter.dart';

// ---------------------------------------------------------------------------
// DateTimePickerMode — what to pick
// ---------------------------------------------------------------------------

enum DateTimePickerMode {
  /// Date only (month / day / year).
  date,

  /// Time only (hour : minute AM/PM).
  time,

  /// Date and time combined.
  dateAndTime,

  /// Month and year only.
  monthYear,

  /// Year only.
  year,
}

// ---------------------------------------------------------------------------
// PickerSurface — how it is put on screen
// ---------------------------------------------------------------------------

/// Where the picker LIVES, which is a different question from how it
/// looks — the look is [DateTimePickerStyle].
///
/// It used to be called `PickerStyle`, which collided with the themeable
/// bag every other module in this app calls `style`: two `style:`
/// parameters on one widget, meaning unrelated things.
enum PickerSurface {
  /// Cupertino-style spinning wheels, inline in the page.
  wheel,

  /// A modal dialog, built from this module's own parts — see
  /// `PickerDialogs`. It was Flutter's `showDatePicker` and friends,
  /// which no amount of `Theme` wrapping could make match the app.
  dialog,

  /// The same dialog, opened on its keyboard-entry side.
  input,

  /// A calendar grid, inline in the page.
  calendar,

  /// A panel in an overlay, anchored to a trigger button.
  overlay,
}

// ---------------------------------------------------------------------------
// PickerFormat — dates in the locale's own numerals
// ---------------------------------------------------------------------------

/// Formats a date for display, digits included.
///
/// `DateFormat` reads its month and weekday names from the app's locale
/// and its DIGITS from the same place — and plain `ar` writes in ASCII
/// ones, so an Arabic calendar showed "19 أغسطس 2026". Switching the
/// whole format to the native-digit variant would take that variant's
/// month names with it, so only the digits are rewritten.
abstract final class PickerFormat {
  /// Weekday, month, day, year — the label a day cell announces.
  static String full(DateTime date) =>
      AppNumbers.localizeDigits(DateFormat.yMMMMEEEEd().format(date));

  /// Short date — `19 Aug 2026`.
  static String medium(DateTime date) =>
      AppNumbers.localizeDigits(DateFormat.yMMMd().format(date));

  /// Numeric date — `8/19/2026`.
  static String short(DateTime date) =>
      AppNumbers.localizeDigits(DateFormat.yMd().format(date));

  /// Month and year — `August 2026`.
  static String monthYear(DateTime date) =>
      AppNumbers.localizeDigits(DateFormat.yMMMM().format(date));

  /// Clock time, in whichever of the two shapes was asked for.
  static String time(DateTime date, {required bool use24HourFormat}) =>
      AppNumbers.localizeDigits(
        DateFormat(use24HourFormat ? 'HH:mm' : 'h:mm a').format(date),
      );
}

// ---------------------------------------------------------------------------
// PickerEntryMode — grid or keyboard
// ---------------------------------------------------------------------------

/// How a date dialog asks for its answer.
enum PickerEntryMode {
  /// The month grid.
  calendar,

  /// A masked text field. Faster for a date years away — a birthday
  /// reached by swiping the calendar back three hundred months is not
  /// reached at all.
  input,
}

// ---------------------------------------------------------------------------
// TypedDate — the keyboard half of the date dialog
// ---------------------------------------------------------------------------

/// Reads and writes a masked date string.
///
/// The mask itself is `DateInputFormatter`, which the text-field module
/// already owns; this is the two ends of it — which order the locale
/// writes in, and how to get a `DateTime` back out.
abstract final class TypedDate {
  /// The digit order this locale writes dates in.
  ///
  /// Taken from `intl`'s own short-date pattern rather than from a list
  /// of locales: `en_US` writes `M/d/y`, most of the world `d/M/y`, and
  /// a few `y/M/d`, and `intl` already knows which is which.
  static DateDigitOrder orderForLocale([String? locale]) {
    final pattern = DateFormat.yMd(locale ?? Intl.getCurrentLocale()).pattern;
    for (final char in (pattern ?? 'M/d/y').split('')) {
      if (char == 'y') return DateDigitOrder.ymd;
      if (char == 'd') return DateDigitOrder.dmy;
      if (char == 'M' || char == 'L') return DateDigitOrder.mdy;
    }
    return DateDigitOrder.mdy;
  }

  /// A date as the mask would have it typed.
  static String format(DateTime date, DateDigitOrder order) {
    String two(int v) => v.toString().padLeft(2, '0');
    final year = date.year.toString().padLeft(4, '0');
    return switch (order) {
      DateDigitOrder.dmy => '${two(date.day)}/${two(date.month)}/$year',
      DateDigitOrder.mdy => '${two(date.month)}/${two(date.day)}/$year',
      DateDigitOrder.ymd => '$year/${two(date.month)}/${two(date.day)}',
      DateDigitOrder.dm => '${two(date.day)}/${two(date.month)}',
      DateDigitOrder.my => '${two(date.month)}/${two(date.year % 100)}',
    };
  }

  /// The date [text] spells, or null if it does not spell one.
  ///
  /// Null covers both "not finished typing" and "31 February" — the
  /// caller cannot act on either, and telling them apart is the error
  /// message's job, not this one's.
  static DateTime? parse(String text, DateDigitOrder order) {
    final digits = DateInputFormatter.normalizeDigits(
      text,
    ).replaceAll(RegExp(r'\D'), '');
    if (digits.length < 8) return null;

    final int year;
    final int month;
    final int day;
    switch (order) {
      case DateDigitOrder.dmy:
        day = int.parse(digits.substring(0, 2));
        month = int.parse(digits.substring(2, 4));
        year = int.parse(digits.substring(4, 8));
      case DateDigitOrder.mdy:
        month = int.parse(digits.substring(0, 2));
        day = int.parse(digits.substring(2, 4));
        year = int.parse(digits.substring(4, 8));
      case DateDigitOrder.ymd:
        year = int.parse(digits.substring(0, 4));
        month = int.parse(digits.substring(4, 6));
        day = int.parse(digits.substring(6, 8));
      case DateDigitOrder.dm:
      case DateDigitOrder.my:
        return null;
    }

    if (month < 1 || month > 12 || day < 1) return null;
    // `DateTime` rolls 31 February into March rather than refusing it,
    // so the day is checked against the month before it is trusted.
    if (day > PickerMath.daysInMonth(year, month)) return null;
    return DateTime(year, month, day);
  }
}

// ---------------------------------------------------------------------------
// Layout choices
// ---------------------------------------------------------------------------

/// How a time is asked for.
enum TimePickerLayout {
  /// Spinning wheels. One gesture per part, and the parts are legible
  /// while they move.
  wheels,

  /// A clock face. Faster to read back at a glance, and what a phone's
  /// own alarm looks like.
  dial,
}

/// How a range is asked for.
enum RangePickerLayout {
  /// A modal over the page.
  dialog,

  /// A page of its own. A range on a phone wants the room — a modal's
  /// two dates and its actions leave the month grid squeezed between
  /// them.
  fullScreen,
}

/// What a calendar collects.
enum CalendarSelection {
  /// One date.
  single,

  /// A span, by two taps or a long-press sweep.
  range,

  /// Any number of days, each toggled on its own. There is no span
  /// between them, so the bar and the sweep are both off.
  multiple,
}

/// How FINE a thing a calendar picks.
enum CalendarGrain {
  /// A day, on the month grid.
  day,

  /// A month, on the month grid — reports its 1st.
  month,

  /// A year, on the year grid — reports the 1st of its focused month.
  year,
}

/// How the months are laid out.
enum MonthFlow {
  /// One month at a time, swiped sideways, with its neighbours peeking
  /// in at the edges.
  paged,

  /// A vertical list of months, scrolled. What a full page wants: the
  /// room is there, and a range spanning a fold is easier to pick when
  /// both ends are on screen.
  list,
}

/// Which half of the clock the dial is setting.
enum DialMode { hour, minute }

// ---------------------------------------------------------------------------
// PickerMath — the date arithmetic, without a widget
// ---------------------------------------------------------------------------

/// Every calculation the pickers do to a `DateTime`.
///
/// Pure and named, because none of it could be tested where it was: the
/// wheels need a laid-out `CupertinoPicker` and the calendar needs a
/// real screen, so a month-length bug or an AM/PM bug only ever showed
/// up on a device.
abstract final class PickerMath {
  /// Day 0 of the NEXT month is the last day of this one.
  static int daysInMonth(int year, int month) =>
      DateTime(year, month + 1, 0).day;

  /// Whether a minute wheel can be built from [interval] at all.
  ///
  /// The wheel is `60 ~/ interval` rows, so an interval that does not
  /// divide 60 silently loses the tail: 7 gives 8 rows ending at 49,
  /// and :56 becomes unreachable.
  static bool isValidMinuteInterval(int interval) =>
      interval > 0 && interval <= 60 && 60 % interval == 0;

  /// The minute a wheel of [interval] can actually show.
  ///
  /// A value of :07 on a 15-minute wheel used to sit at row 0 — the
  /// wheel read "00" while the value stayed :07, so the picker showed
  /// one time and reported another.
  static int snapMinute(int minute, int interval) =>
      interval <= 1 ? minute : (minute ~/ interval) * interval;

  /// 24-hour to the 1..12 a 12-hour wheel shows.
  static int hour12(int hour24) => hour24 % 12 == 0 ? 12 : hour24 % 12;

  /// A 12-hour wheel row back to a 24-hour value.
  ///
  /// The wheel is 1-based (it starts at 1, not 0), and 12 AM is hour 0
  /// while 12 PM is hour 12 — the one pair that does not follow the
  /// `+12` rule.
  static int hour24({
    required int index,
    required bool use24HourFormat,
    required bool isPm,
  }) {
    if (use24HourFormat) return index;
    var h = index + 1;
    if (isPm && h != 12) h += 12;
    if (!isPm && h == 12) h = 0;
    return h;
  }

  /// Which wheel row a 24-hour value sits at.
  static int hourIndex(int hour24Value, {required bool use24HourFormat}) =>
      use24HourFormat ? hour24Value : hour12(hour24Value) - 1;

  /// Rebuild a date from parts, clamping the day to the month.
  ///
  /// 31 January + "February" is 31 February, which `DateTime` silently
  /// rolls into March. Clamping keeps the month the reader chose.
  static DateTime rebuild(
    DateTime base, {
    int? year,
    int? month,
    int? day,
    int? hour,
    int? minute,
    int? second,
    bool? isPm,
    bool use24HourFormat = false,
  }) {
    final y = year ?? base.year;
    final m = month ?? base.month;
    var d = day ?? base.day;
    var h = hour ?? base.hour;
    final min = minute ?? base.minute;
    final sec = second ?? base.second;

    final maxDay = daysInMonth(y, m);
    if (d > maxDay) d = maxDay;

    if (isPm != null && !use24HourFormat) {
      final h12 = h % 12;
      h = isPm ? h12 + 12 : h12;
    }

    return DateTime(y, m, d, h, min, sec);
  }
}

// ---------------------------------------------------------------------------
// CalendarGrid — where a day sits in the 7-column grid
// ---------------------------------------------------------------------------

/// The grid geometry, without a `RenderBox`.
abstract final class CalendarGrid {
  /// How many blank cells come before the 1st, given [startOfWeek]
  /// (0 = Sunday).
  static int firstDayOffset(DateTime month, int startOfWeek) {
    final firstOfMonth = DateTime(month.year, month.month);
    final raw = firstOfMonth.weekday % 7; // 0 = Sunday
    return (raw - startOfWeek + 7) % 7;
  }

  /// How many rows a month needs — 4, 5 or 6.
  static int rowsFor(int firstDayOffset, int daysInMonth) =>
      (firstDayOffset + daysInMonth + 6) ~/ 7;

  /// Which column a day sits in, 0 = first column of the row.
  static int columnOf(DateTime day, int startOfWeek) =>
      (day.weekday % 7 - startOfWeek + 7) % 7;

  /// The ISO-8601 week [date] falls in, 1..53.
  ///
  /// ISO weeks start on a MONDAY and belong to the year holding their
  /// Thursday — which is why the first days of January are sometimes
  /// week 52 of the year before, and why this cannot be
  /// `dayOfYear ~/ 7`.
  static int isoWeekNumber(DateTime date) {
    // The THURSDAY of this week decides which year the week is in, and
    // therefore what it is numbered from. Built by day arithmetic
    // rather than `add(Duration(days:))`, which is an hour short across
    // a daylight-saving boundary.
    final thursday = DateTime(
      date.year,
      date.month,
      date.day + (4 - date.weekday),
    );
    final firstOfYear = DateTime(thursday.year);
    return 1 + thursday.difference(firstOfYear).inDays ~/ 7;
  }

  /// The day number under [local], or null if that point is not on a
  /// day of this month.
  ///
  /// [local] is measured from the top-left of the day view, [gridWidth]
  /// is the seven columns' total width, and [inset] is the padding
  /// between the two. In a right-to-left layout the columns run the
  /// other way, which is what the hand-rolled version got wrong — a
  /// drag in Arabic selected the mirror image of what was under the
  /// finger.
  static int? dayNumberAt({
    required Offset local,
    required double gridWidth,
    required double inset,
    required double headerExtent,
    required double rowExtent,
    required int firstDayOffset,
    required int daysInMonth,
    required bool rtl,
  }) {
    if (gridWidth <= 0 || rowExtent <= 0) return null;

    final x = local.dx - inset;
    final y = local.dy - headerExtent;
    if (x < 0 || x > gridWidth || y < 0) return null;

    final cellWidth = gridWidth / 7;
    var column = (x / cellWidth).floor();
    if (column < 0 || column > 6) return null;
    if (rtl) column = 6 - column;

    final row = (y / rowExtent).floor();
    final rows = rowsFor(firstDayOffset, daysInMonth);
    if (row < 0 || row >= rows) return null;

    final dayNumber = row * 7 + column - firstDayOffset + 1;
    if (dayNumber < 1 || dayNumber > daysInMonth) return null;
    return dayNumber;
  }
}

// ---------------------------------------------------------------------------
// OverlayPlacement — above or below, and how tall
// ---------------------------------------------------------------------------

/// Where an anchored picker panel goes.
///
/// Two copies of this arithmetic used to live in the two pickers, and
/// they had drifted: one measured the space against the screen and the
/// other against the screen minus 30 points, so the same trigger flipped
/// sides depending on which widget owned it.
@immutable
class OverlayPlacement {
  const OverlayPlacement({
    required this.above,
    required this.height,
    required this.offsetY,
  });

  /// Whether the panel sits above the trigger.
  final bool above;

  /// How tall the panel is. Its CONTENT's height, once measured — not a
  /// budget carved out of the room that happens to be there.
  final double height;

  /// Where its top-left goes, relative to the trigger's top-left.
  final double offsetY;

  /// [contentHeight] is the panel's natural height, once something has
  /// measured it; null on the first pass, when nothing has.
  ///
  /// The panel NEVER shrinks to fit. A calendar that loses two rows near
  /// the bottom of a screen is a calendar that cannot show the dates
  /// being asked for — so it flips to the other side, and if it fits
  /// neither it slides onto the screen and overlaps its own trigger
  /// instead. Only the screen itself caps the height.
  static OverlayPlacement decide({
    required double triggerTop,
    required double triggerHeight,
    required double availableHeight,
    required double gap,
    required double margin,
    required double maxHeight,
    required double minHeight,
    double? contentHeight,
  }) {
    final screenRoom = math.max(minHeight, availableHeight - margin * 2);
    final wanted = math.min(
      math.min(contentHeight ?? maxHeight, maxHeight),
      screenRoom,
    );

    final roomBelow =
        availableHeight - triggerTop - triggerHeight - gap - margin;
    final roomAbove = triggerTop - gap - margin;

    // Below first — it keeps the panel where the thumb already is and
    // off the trigger it belongs to.
    if (wanted <= roomBelow) {
      return OverlayPlacement(
        above: false,
        height: wanted,
        offsetY: triggerHeight + gap,
      );
    }
    if (wanted <= roomAbove) {
      return OverlayPlacement(
        above: true,
        height: wanted,
        offsetY: -wanted - gap,
      );
    }

    final goAbove = roomAbove > roomBelow;
    final preferredTop = goAbove
        ? triggerTop - gap - wanted
        : triggerTop + triggerHeight + gap;
    final lowestTop = math.max(margin, availableHeight - margin - wanted);
    final top = preferredTop.clamp(margin, lowestTop);

    return OverlayPlacement(
      above: goAbove,
      height: wanted,
      offsetY: top - triggerTop,
    );
  }
}

// ---------------------------------------------------------------------------
// DateTime helpers
// ---------------------------------------------------------------------------

extension DateTimeClamp on DateTime {
  /// This date, held inside [min] and [max].
  DateTime clampTo(DateTime min, DateTime max) {
    if (isBefore(min)) return min;
    if (isAfter(max)) return max;
    return this;
  }
}

/// Compare two dates ignoring the time of day.
bool isSameDay(DateTime? a, DateTime? b) =>
    a != null &&
    b != null &&
    a.year == b.year &&
    a.month == b.month &&
    a.day == b.day;
