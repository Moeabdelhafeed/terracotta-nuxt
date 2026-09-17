import '../../../generated/l10n.dart';
import '../tr.dart';

/// Strings for the `vin_field_` prefix family (VIN field hints +
/// validation messages) — call sites go through this class.
class VinFieldStrings {
  VinFieldStrings._();

  static String get hint => Tr.t('vin_field.hint', S.current.vin_field_hint);
  static String get required =>
      Tr.t('vin_field.required', S.current.vin_field_required);
  static String get length =>
      Tr.t('vin_field.length', S.current.vin_field_length);
  static String get checksum =>
      Tr.t('vin_field.checksum', S.current.vin_field_checksum);
  static String year(int year) =>
      Tr.t('vin_field.year', S.current.vin_field_year(year));
}
