import '../../../generated/l10n.dart';
import '../tr.dart';

/// Strings for the `drop_down_` key prefix family — dropdown/select call
/// sites go through this class instead of `Tr.t` / `S.current` directly.
class DropDownStrings {
  DropDownStrings._();

  static String get selectOption =>
      Tr.t('drop_down.select_option', S.current.drop_down_select_option);
  static String get selectOptions =>
      Tr.t('drop_down.select_options', S.current.drop_down_select_options);
  static String get search =>
      Tr.t('drop_down.search', S.current.drop_down_search);
  static String get noResults =>
      Tr.t('drop_down.no_results', S.current.drop_down_no_results);
  static String createNew(String query) =>
      Tr.t('drop_down.create_new', S.current.drop_down_create_new(query));
  static String get selectAll =>
      Tr.t('drop_down.select_all', S.current.drop_down_select_all);
  static String get clearAll =>
      Tr.t('drop_down.clear_all', S.current.drop_down_clear_all);
  static String selectedCount(int count) => Tr.t(
    'drop_down.selected_count',
    S.current.drop_down_selected_count(count),
  );
  static String selectedOfMax(int count, int max) => Tr.t(
    'drop_down.selected_of_max',
    S.current.drop_down_selected_of_max(count, max),
  );
  static String get loadFailed =>
      Tr.t('drop_down.load_failed', S.current.drop_down_load_failed);
  static String moreItems(String labels, int count) => Tr.t(
    'drop_down.more_items',
    S.current.drop_down_more_items(labels, count),
  );
  static String get tapToOpen =>
      Tr.t('drop_down.tap_to_open', S.current.drop_down_tap_to_open);
  static String get tapToClose =>
      Tr.t('drop_down.tap_to_close', S.current.drop_down_tap_to_close);
  static String get clearSelection =>
      Tr.t('drop_down.clear_selection', S.current.drop_down_clear_selection);
  static String get genderLabel =>
      Tr.t('drop_down.gender_label', S.current.drop_down_gender_label);
  static String get genderHint =>
      Tr.t('drop_down.gender_hint', S.current.drop_down_gender_hint);
  static String get hourLabel =>
      Tr.t('drop_down.hour_label', S.current.drop_down_hour_label);
  static String get hourHint =>
      Tr.t('drop_down.hour_hint', S.current.drop_down_hour_hint);
  static String get languageLabel =>
      Tr.t('drop_down.language_label', S.current.drop_down_language_label);
  static String get languageHint =>
      Tr.t('drop_down.language_hint', S.current.drop_down_language_hint);
  static String get monthLabel =>
      Tr.t('drop_down.month_label', S.current.drop_down_month_label);
  static String get monthHint =>
      Tr.t('drop_down.month_hint', S.current.drop_down_month_hint);
  static String get themeLabel =>
      Tr.t('drop_down.theme_label', S.current.drop_down_theme_label);
  static String get themeHint =>
      Tr.t('drop_down.theme_hint', S.current.drop_down_theme_hint);
  static String get yearLabel =>
      Tr.t('drop_down.year_label', S.current.drop_down_year_label);
  static String get yearHint =>
      Tr.t('drop_down.year_hint', S.current.drop_down_year_hint);
  static String get countryHint =>
      Tr.t('drop_down.country_hint', S.current.drop_down_country_hint);
  static String get stateHint =>
      Tr.t('drop_down.state_hint', S.current.drop_down_state_hint);
  static String get cityHint =>
      Tr.t('drop_down.city_hint', S.current.drop_down_city_hint);
  static String get currencyHint =>
      Tr.t('drop_down.currency_hint', S.current.drop_down_currency_hint);
  static String get unitHint =>
      Tr.t('drop_down.unit_hint', S.current.drop_down_unit_hint);
  static String get colorFormatLabel => Tr.t(
    'drop_down.color_format_label',
    S.current.drop_down_color_format_label,
  );
  static String get colorFormatHint => Tr.t(
    'drop_down.color_format_hint',
    S.current.drop_down_color_format_hint,
  );
  static String get dayLabel =>
      Tr.t('drop_down.day_label', S.current.drop_down_day_label);
  static String get dayHint =>
      Tr.t('drop_down.day_hint', S.current.drop_down_day_hint);
  static String get weekdayLabel =>
      Tr.t('drop_down.weekday_label', S.current.drop_down_weekday_label);
  static String get weekdayHint =>
      Tr.t('drop_down.weekday_hint', S.current.drop_down_weekday_hint);
  static String get nationalityHint =>
      Tr.t('drop_down.nationality_hint', S.current.drop_down_nationality_hint);
  static String get timezoneHint =>
      Tr.t('drop_down.timezone_hint', S.current.drop_down_timezone_hint);
  static String get bloodTypeLabel =>
      Tr.t('drop_down.blood_type_label', S.current.drop_down_blood_type_label);
  static String get bloodTypeHint =>
      Tr.t('drop_down.blood_type_hint', S.current.drop_down_blood_type_hint);
  static String get maritalStatusLabel => Tr.t(
    'drop_down.marital_status_label',
    S.current.drop_down_marital_status_label,
  );
  static String get maritalStatusHint => Tr.t(
    'drop_down.marital_status_hint',
    S.current.drop_down_marital_status_hint,
  );
  static String get educationLabel =>
      Tr.t('drop_down.education_label', S.current.drop_down_education_label);
  static String get educationHint =>
      Tr.t('drop_down.education_hint', S.current.drop_down_education_hint);
  static String get sortByLabel =>
      Tr.t('drop_down.sort_by_label', S.current.drop_down_sort_by_label);
  static String get sortByHint =>
      Tr.t('drop_down.sort_by_hint', S.current.drop_down_sort_by_hint);
  static String get durationLabel =>
      Tr.t('drop_down.duration_label', S.current.drop_down_duration_label);
  static String get durationHint =>
      Tr.t('drop_down.duration_hint', S.current.drop_down_duration_hint);
  static String get recurrenceLabel =>
      Tr.t('drop_down.recurrence_label', S.current.drop_down_recurrence_label);
  static String get recurrenceHint =>
      Tr.t('drop_down.recurrence_hint', S.current.drop_down_recurrence_hint);
}
