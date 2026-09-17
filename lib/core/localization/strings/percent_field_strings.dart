import '../../../generated/l10n.dart';
import '../tr.dart';

/// Strings for the `percent_field_` key family — call sites go through
/// this class instead of `Tr.t` / `S.current` directly.
class PercentFieldStrings {
  PercentFieldStrings._();

  static String get hint =>
      Tr.t('percent_field.hint', S.current.percent_field_hint);
  static String get required =>
      Tr.t('percent_field.required', S.current.percent_field_required);
  static String range(String min, String max) =>
      Tr.t('percent_field.range', S.current.percent_field_range(min, max));
  static String min(String min) =>
      Tr.t('percent_field.min', S.current.percent_field_min(min));
  static String max(String max) =>
      Tr.t('percent_field.max', S.current.percent_field_max(max));
}
