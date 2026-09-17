import '../../../generated/l10n.dart';
import '../tr.dart';

/// Strings for the `swift_field_` prefix family (SWIFT/BIC field hints +
/// validation messages) — call sites go through this class.
class SwiftFieldStrings {
  SwiftFieldStrings._();

  static String get hint =>
      Tr.t('swift_field.hint', S.current.swift_field_hint);
  static String get required =>
      Tr.t('swift_field.required', S.current.swift_field_required);
  static String get length =>
      Tr.t('swift_field.length', S.current.swift_field_length);
  static String get bank =>
      Tr.t('swift_field.bank', S.current.swift_field_bank);
  static String get country =>
      Tr.t('swift_field.country', S.current.swift_field_country);
  static String get countryNotAllowed => Tr.t(
    'swift_field.country_not_allowed',
    S.current.swift_field_country_not_allowed,
  );
  static String get location =>
      Tr.t('swift_field.location', S.current.swift_field_location);
  static String get branch =>
      Tr.t('swift_field.branch', S.current.swift_field_branch);
  static String get ibanMismatch =>
      Tr.t('swift_field.iban_mismatch', S.current.swift_field_iban_mismatch);
  static String get headOffice =>
      Tr.t('swift_field.head_office', S.current.swift_field_head_office);
  static String get testWarning =>
      Tr.t('swift_field.test_warning', S.current.swift_field_test_warning);
}
