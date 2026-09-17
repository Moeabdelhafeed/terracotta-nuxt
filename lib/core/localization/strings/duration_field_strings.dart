import '../../../generated/l10n.dart';
import '../tr.dart';

/// Strings for the `duration_field_` key prefix family — duration-field
/// call sites go through this class instead of `Tr.t`/`S.current` directly.
class DurationFieldStrings {
  DurationFieldStrings._();

  static String get required =>
      Tr.t('duration_field.required', S.current.duration_field_required);
  static String get incomplete =>
      Tr.t('duration_field.incomplete', S.current.duration_field_incomplete);
  static String min(String duration) =>
      Tr.t('duration_field.min', S.current.duration_field_min(duration));
  static String max(String duration) =>
      Tr.t('duration_field.max', S.current.duration_field_max(duration));
  static String step(int step) =>
      Tr.t('duration_field.step', S.current.duration_field_step(step));
  static String minutes(int minutes) =>
      Tr.t('duration_field.minutes', S.current.duration_field_minutes(minutes));
  static String seconds(int seconds) =>
      Tr.t('duration_field.seconds', S.current.duration_field_seconds(seconds));
  static String get pick =>
      Tr.t('duration_field.pick', S.current.duration_field_pick);

  /// Wheel headings on `GlobalDurationPicker`.
  static String get hoursWord => Tr.t(
    'duration_field.hours_word',
    S.current.duration_field_hours_word,
  );
  static String get minutesWord => Tr.t(
    'duration_field.minutes_word',
    S.current.duration_field_minutes_word,
  );
  static String get secondsWord => Tr.t(
    'duration_field.seconds_word',
    S.current.duration_field_seconds_word,
  );
}
