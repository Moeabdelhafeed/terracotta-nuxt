import '../../../generated/l10n.dart';
import '../tr.dart';

/// Strings under the `date_field_` prefix family (date-field validation
/// messages, picker labels, and date-part words) — call sites go through
/// this class instead of `Tr.t`/`S.current` directly.
class DateFieldStrings {
  DateFieldStrings._();

  static String incomplete(String format) =>
      Tr.t('date_field.incomplete', S.current.date_field_incomplete(format));
  static String get impossible =>
      Tr.t('date_field.impossible', S.current.date_field_impossible);
  static String minDate(String date) =>
      Tr.t('date_field.min_date', S.current.date_field_min_date(date));
  static String maxDate(String date) =>
      Tr.t('date_field.max_date', S.current.date_field_max_date(date));
  static String minDaysAhead(int days) => Tr.t(
    'date_field.min_days_ahead',
    S.current.date_field_min_days_ahead(days),
  );
  static String maxDaysAhead(int days) => Tr.t(
    'date_field.max_days_ahead',
    S.current.date_field_max_days_ahead(days),
  );
  static String get weekdayNotAllowed => Tr.t(
    'date_field.weekday_not_allowed',
    S.current.date_field_weekday_not_allowed,
  );
  static String get dateUnavailable => Tr.t(
    'date_field.date_unavailable',
    S.current.date_field_date_unavailable,
  );
  static String mustBeAfter(String date) => Tr.t(
    'date_field.must_be_after',
    S.current.date_field_must_be_after(date),
  );
  static String mustBeBefore(String date) => Tr.t(
    'date_field.must_be_before',
    S.current.date_field_must_be_before(date),
  );
  static String expiryMinMonths(int months) => Tr.t(
    'date_field.expiry_min_months',
    S.current.date_field_expiry_min_months(months),
  );
  static String ageMonths(int months) =>
      Tr.t('date_field.age_months', S.current.date_field_age_months(months));
  static String ageDays(int days) =>
      Tr.t('date_field.age_days', S.current.date_field_age_days(days));
  static String ageYears(int years) =>
      Tr.t('date_field.age_years', S.current.date_field_age_years(years));
  static String hijri(String date) =>
      Tr.t('date_field.hijri', S.current.date_field_hijri(date));
  static String get selectDate =>
      Tr.t('date_field.select_date', S.current.date_field_select_date);
  static String get pickDate =>
      Tr.t('date_field.pick_date', S.current.date_field_pick_date);
  static String get dayWord =>
      Tr.t('date_field.day_word', S.current.date_field_day_word);
  static String get monthWord =>
      Tr.t('date_field.month_word', S.current.date_field_month_word);
  static String get yearWord =>
      Tr.t('date_field.year_word', S.current.date_field_year_word);
  static String get year2Word =>
      Tr.t('date_field.year2_word', S.current.date_field_year2_word);
}

/// Strings under the `date_range_` prefix family (date-range picker
/// labels) — call sites go through this class instead of
/// `Tr.t`/`S.current` directly.
class DateRangeStrings {
  DateRangeStrings._();

  static String get start =>
      Tr.t('date_range.start', S.current.date_range_start);
  static String get end => Tr.t('date_range.end', S.current.date_range_end);
  static String get presetToday =>
      Tr.t('date_range.preset_today', S.current.date_range_preset_today);
  static String get presetLast7Days => Tr.t(
    'date_range.preset_last_7_days',
    S.current.date_range_preset_last_7_days,
  );
  static String get presetLast30Days => Tr.t(
    'date_range.preset_last_30_days',
    S.current.date_range_preset_last_30_days,
  );
  static String get presetThisMonth => Tr.t(
    'date_range.preset_this_month',
    S.current.date_range_preset_this_month,
  );
  static String get presetLastMonth => Tr.t(
    'date_range.preset_last_month',
    S.current.date_range_preset_last_month,
  );
  static String get selectRange =>
      Tr.t('date_range.select_range', S.current.date_range_select_range);
  static String get selectDateRange => Tr.t(
    'date_range.select_date_range',
    S.current.date_range_select_date_range,
  );
  static String nights(int nights) =>
      Tr.t('date_range.nights', S.current.date_range_nights(nights));
}

/// Strings under the `datetime_field_` prefix family (combined date+time
/// field labels) — call sites go through this class instead of
/// `Tr.t`/`S.current` directly.
class DatetimeFieldStrings {
  DatetimeFieldStrings._();

  static String get date =>
      Tr.t('datetime_field.date', S.current.datetime_field_date);
  static String get time =>
      Tr.t('datetime_field.time', S.current.datetime_field_time);
}

/// Strings under the `date_picker_` prefix family — the calendar and
/// wheel pickers in `shared/module/date_time_picker/`.
///
/// Almost all of these are SEMANTIC labels rather than visible text: a
/// calendar's day cell reads as the bare number "5" to a screen reader
/// unless something says which month it is in and what state it is in.
/// AM / PM are deliberately NOT here — `DateFormat.dateSymbols.AMPMS`
/// already knows them per locale, and an ARB copy would drift.
class DatePickerStrings {
  DatePickerStrings._();

  static String get previousMonth => Tr.t(
    'date_picker.previous_month',
    S.current.date_picker_previous_month,
  );
  static String get nextMonth =>
      Tr.t('date_picker.next_month', S.current.date_picker_next_month);
  static String get previousYear =>
      Tr.t('date_picker.previous_year', S.current.date_picker_previous_year);
  static String get nextYear =>
      Tr.t('date_picker.next_year', S.current.date_picker_next_year);
  static String get previousYears => Tr.t(
    'date_picker.previous_years',
    S.current.date_picker_previous_years,
  );
  static String get nextYears =>
      Tr.t('date_picker.next_years', S.current.date_picker_next_years);
  static String get chooseMonth =>
      Tr.t('date_picker.choose_month', S.current.date_picker_choose_month);
  static String get chooseYear =>
      Tr.t('date_picker.choose_year', S.current.date_picker_choose_year);
  static String get today =>
      Tr.t('date_picker.today', S.current.date_picker_today);
  static String get selected =>
      Tr.t('date_picker.selected', S.current.date_picker_selected);
  static String get rangeStart =>
      Tr.t('date_picker.range_start', S.current.date_picker_range_start);
  static String get rangeEnd =>
      Tr.t('date_picker.range_end', S.current.date_picker_range_end);
  static String get inRange =>
      Tr.t('date_picker.in_range', S.current.date_picker_in_range);
  static String get unavailable =>
      Tr.t('date_picker.unavailable', S.current.date_picker_unavailable);
  static String minRangeDays(int days) => Tr.t(
    'date_picker.min_range_days',
    S.current.date_picker_min_range_days(days),
  );
  static String maxRangeDays(int days) => Tr.t(
    'date_picker.max_range_days',
    S.current.date_picker_max_range_days(days),
  );
  static String get hour =>
      Tr.t('date_picker.hour', S.current.date_picker_hour);
  static String get minute =>
      Tr.t('date_picker.minute', S.current.date_picker_minute);
  static String get period =>
      Tr.t('date_picker.period', S.current.date_picker_period);

  /// The date-part words the WHEELS are named by.
  ///
  /// Not `DateFieldStrings.monthWord` — those are format hints ("MM",
  /// "DD", "YYYY") for a typed field, and a screen reader announcing a
  /// wheel as "MM" says nothing.
  static String get month =>
      Tr.t('date_picker.month', S.current.date_picker_month);
  static String get day => Tr.t('date_picker.day', S.current.date_picker_day);
  static String get year =>
      Tr.t('date_picker.year', S.current.date_picker_year);
  static String get second =>
      Tr.t('date_picker.second', S.current.date_picker_second);
  static String get selectTimeRange => Tr.t(
    'date_picker.select_time_range',
    S.current.date_picker_select_time_range,
  );

  /// The dialog's entry-mode toggle.
  static String get typeADate =>
      Tr.t('date_picker.type_a_date', S.current.date_picker_type_a_date);
  static String get pickFromCalendar => Tr.t(
    'date_picker.pick_from_calendar',
    S.current.date_picker_pick_from_calendar,
  );
  static String get selectTime =>
      Tr.t('date_picker.select_time', S.current.date_picker_select_time);
  static String get selectDateTime => Tr.t(
    'date_picker.select_date_time',
    S.current.date_picker_select_date_time,
  );
  static String get selectMonthYear => Tr.t(
    'date_picker.select_month_year',
    S.current.date_picker_select_month_year,
  );
  static String get selectYear =>
      Tr.t('date_picker.select_year', S.current.date_picker_select_year);
  static String events(int count) =>
      Tr.t('date_picker.events', S.current.date_picker_events(count));
  static String get close =>
      Tr.t('date_picker.close', S.current.date_picker_close);
}
