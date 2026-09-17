import '../../../generated/l10n.dart';
import '../tr.dart';

/// Strings for the `duration_` key prefix family — humanized duration
/// labels ("45 min", "1 h 30 min") for the duration picker.
///
/// Count-parameterized keys ride [Tr.plural] (NOT flat [Tr.t] — that
/// path returns a remote override verbatim with no interpolation, so
/// every row would render the same literal).
class DurationStrings {
  DurationStrings._();

  static String minutes(int n) => Tr.plural(
    'duration.minutes',
    n,
    S.current.duration_minutes(n),
    args: {'n': n},
  );
  static String hours(int n) => Tr.plural(
    'duration.hours',
    n,
    S.current.duration_hours(n),
    args: {'n': n},
  );

  /// Composed from [hours] + [minutes] — no dedicated two-param key so
  /// each part stays remote-overridable on its own.
  static String hoursMinutes(int h, int m) => '${hours(h)} ${minutes(m)}';
  static String days(int n) =>
      Tr.plural('duration.days', n, S.current.duration_days(n), args: {'n': n});
}

/// Strings for the `recurrence_` key prefix family — user-visible
/// labels of the [Recurrence] enum options.
class RecurrenceStrings {
  RecurrenceStrings._();

  static String get none => Tr.t('recurrence.none', S.current.recurrence_none);
  static String get daily =>
      Tr.t('recurrence.daily', S.current.recurrence_daily);
  static String get weekly =>
      Tr.t('recurrence.weekly', S.current.recurrence_weekly);
  static String get monthly =>
      Tr.t('recurrence.monthly', S.current.recurrence_monthly);
  static String get yearly =>
      Tr.t('recurrence.yearly', S.current.recurrence_yearly);
}
