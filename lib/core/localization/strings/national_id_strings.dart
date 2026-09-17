import '../../../generated/l10n.dart';
import '../tr.dart';

/// Strings for the `national_id_` key family (national-ID field hint,
/// validation messages, and parsed-info labels) — call sites go through
/// this class instead of `Tr.t` / `S.current` directly.
class NationalIdStrings {
  NationalIdStrings._();

  static String get fieldHint =>
      Tr.t('national_id.hint', S.current.national_id_field_hint);
  static String get required =>
      Tr.t('national_id.required', S.current.national_id_required);
  static String length(int length) =>
      Tr.t('national_id.length', S.current.national_id_length(length));
  static String get generic =>
      Tr.t('national_id.generic', S.current.national_id_generic);
  static String get prefix =>
      Tr.t('national_id.prefix', S.current.national_id_prefix);
  static String get checksum =>
      Tr.t('national_id.checksum', S.current.national_id_checksum);
  static String get birthdate =>
      Tr.t('national_id.birthdate', S.current.national_id_birthdate);
  static String get governorate =>
      Tr.t('national_id.governorate', S.current.national_id_governorate);
  static String get dobMismatch =>
      Tr.t('national_id.dob_mismatch', S.current.national_id_dob_mismatch);
  static String get citizensOnly =>
      Tr.t('national_id.citizens_only', S.current.national_id_citizens_only);
  static String get residentsOnly =>
      Tr.t('national_id.residents_only', S.current.national_id_residents_only);
  static String born(String date) =>
      Tr.t('national_id.born', S.current.national_id_born(date));
  static String get male =>
      Tr.t('national_id.male', S.current.national_id_male);
  static String get female =>
      Tr.t('national_id.female', S.current.national_id_female);
  static String get citizen =>
      Tr.t('national_id.citizen', S.current.national_id_citizen);
  static String get resident =>
      Tr.t('national_id.resident', S.current.national_id_resident);
}
