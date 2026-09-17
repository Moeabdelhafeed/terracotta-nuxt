import '../../../generated/l10n.dart';
import '../tr.dart';

/// Strings under the `time_field_` prefix family (time-field validation
/// messages, picker labels, and time-part words) — call sites go through
/// this class instead of `Tr.t`/`S.current` directly.
class TimeFieldStrings {
  TimeFieldStrings._();

  static String get hourWord =>
      Tr.t('time_field.hour_word', S.current.time_field_hour_word);
  static String get minuteWord =>
      Tr.t('time_field.minute_word', S.current.time_field_minute_word);
  static String get required =>
      Tr.t('time_field.required', S.current.time_field_required);
  static String incomplete(String format) =>
      Tr.t('time_field.incomplete', S.current.time_field_incomplete(format));
  static String minTime(String time) =>
      Tr.t('time_field.min_time', S.current.time_field_min_time(time));
  static String maxTime(String time) =>
      Tr.t('time_field.max_time', S.current.time_field_max_time(time));
  static String outsideWindow(String start, String end) => Tr.t(
    'time_field.outside_window',
    S.current.time_field_outside_window(start, end),
  );
  static String interval(int minutes) =>
      Tr.t('time_field.interval', S.current.time_field_interval(minutes));
  static String get pickTime =>
      Tr.t('time_field.pick_time', S.current.time_field_pick_time);
  static String get format24 =>
      Tr.t('time_field.format_24', S.current.time_field_format_24);
  static String get format12 =>
      Tr.t('time_field.format_12', S.current.time_field_format_12);
  static String get secondWord =>
      Tr.t('time_field.second_word', S.current.time_field_second_word);
  static String get now => Tr.t('time_field.now', S.current.time_field_now);
  static String mustBeAfter(String time) => Tr.t(
    'time_field.must_be_after',
    S.current.time_field_must_be_after(time),
  );
}

/// Strings for the `time_range_` key prefix family — time-range field
/// call sites resolve their labels through this class.
class TimeRangeStrings {
  TimeRangeStrings._();

  static String get start =>
      Tr.t('time_range.start', S.current.time_range_start);
  static String get end => Tr.t('time_range.end', S.current.time_range_end);
  static String duration(int hours, int minutes) => Tr.t(
    'time_range.duration',
    S.current.time_range_duration(hours, minutes),
  );
}
