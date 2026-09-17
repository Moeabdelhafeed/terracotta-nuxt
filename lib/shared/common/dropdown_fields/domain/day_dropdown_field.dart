import 'package:flutter/material.dart';

import '../../../../core/localization/strings/drop_down_strings.dart';
import '../../../../core/utils/hijri_date.dart';
import '../../../module/drop_down/global_drop_down.dart';
import '../generic/simple_dropdown_field.dart';
import 'month_dropdown_field.dart' show MonthCalendar;

/// Day-of-month picker (01 … N). Pass [month] / [year] (and [calendar])
/// to clamp N to the real month length — the missing third of the
/// day / month / year DOB trio. Without them it lists the calendar
/// maximum (31 gregorian / 30 hijri); with a month but no year it is
/// permissive (Feb → 29, Dhu al-Hijjah → 30) so no valid date is ever
/// unpickable.
///
/// Controlled-form note: the inner `FormField` seeds from [value] once
/// per (calendar, month, year) — the field keys itself on that triple,
/// so a month/year change re-seeds from the CURRENT [value] (clamped:
/// a day past the new month length renders unselected and validates as
/// null instead of pinning a stale 31 over February). The parent still
/// owns its stored day; clear or clamp it in the month/year onChanged.
class DayDropdownField extends StatelessWidget {
  const DayDropdownField({
    super.key,
    required this.value,
    required this.onChanged,
    this.month,
    this.year,
    this.calendar = MonthCalendar.gregorian,
    this.label,
    this.hint,
    this.enabled = true,
    this.errorText,
  });

  final int? value;
  final ValueChanged<int?>? onChanged;

  /// Month (1–12) the day list is clamped to. Null → calendar maximum.
  final int? month;

  /// Year for leap-aware clamping. Null → permissive month length.
  final int? year;

  /// Which calendar [month] / [year] refer to. Pair with
  /// `MonthDropdownField(calendar: ...)`.
  final MonthCalendar calendar;

  final String? label;
  final String? hint;
  final bool enabled;
  final String? errorText;

  int _dayCount() {
    if (calendar == MonthCalendar.hijri) {
      if (month == null) return 30;
      if (year == null) return (month!.isOdd || month == 12) ? 30 : 29;
      return HijriDate.daysInMonth(year!, month!);
    }
    if (month == null) return 31;
    // 2024 is a leap year — permissive Feb 29 when the year is unknown.
    return DateUtils.getDaysInMonth(year ?? 2024, month!);
  }

  @override
  Widget build(BuildContext context) {
    final count = _dayCount();
    final items = [
      for (var d = 1; d <= count; d++)
        DropdownItem<int>(value: d, label: d.toString().padLeft(2, '0')),
    ];
    return SimpleDropdownField<int>(
      // FormField state seeds from `value` ONCE (see
      // GlobalDropdownFormField) — key on the clamp context so a
      // month/year/calendar change remounts and re-seeds; without this
      // the clamp below is dead after the first pick and a stale 31
      // stays displayed (and validates!) over a 28-day February.
      key: ValueKey('day-$calendar-$month-$year'),
      items: items,
      // A day beyond the clamped list (31 while Feb is selected) renders
      // unselected instead of pinning a stale trigger label.
      value: value != null && value! <= count ? value : null,
      onChanged: onChanged,
      label: label ?? DropDownStrings.dayLabel,
      hint: hint ?? DropDownStrings.dayHint,
      enabled: enabled,
      errorText: errorText,
    );
  }
}
