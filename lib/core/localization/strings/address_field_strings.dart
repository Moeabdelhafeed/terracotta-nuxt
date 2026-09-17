import '../../../generated/l10n.dart';
import '../tr.dart';

/// Strings for the `address_field_` key family — address form field labels,
/// hints, and validation messages; call sites go through this class.
class AddressFieldStrings {
  AddressFieldStrings._();

  static String get area =>
      Tr.t('address_field.area', S.current.address_field_area);
  static String get areaHint =>
      Tr.t('address_field.area_hint', S.current.address_field_area_hint);
  static String get cityHint =>
      Tr.t('address_field.city_hint', S.current.address_field_city_hint);
  static String get line2Hint =>
      Tr.t('address_field.line2_hint', S.current.address_field_line2_hint);
  static String enter(String label) =>
      Tr.t('address_field.enter', S.current.address_field_enter(label));
  static String get typeHome =>
      Tr.t('address_field.type_home', S.current.address_field_type_home);
  static String get typeWork =>
      Tr.t('address_field.type_work', S.current.address_field_type_work);
  static String get typeOther =>
      Tr.t('address_field.type_other', S.current.address_field_type_other);
  static String get recipient =>
      Tr.t('address_field.recipient', S.current.address_field_recipient);
  static String get recipientHint => Tr.t(
    'address_field.recipient_hint',
    S.current.address_field_recipient_hint,
  );
  static String get phone =>
      Tr.t('address_field.phone', S.current.address_field_phone);
  static String get notes =>
      Tr.t('address_field.notes', S.current.address_field_notes);
  static String get notesHint =>
      Tr.t('address_field.notes_hint', S.current.address_field_notes_hint);
  static String get country =>
      Tr.t('address_field.country', S.current.address_field_country);
  static String get street =>
      Tr.t('address_field.street', S.current.address_field_street);
  static String get streetHint =>
      Tr.t('address_field.street_hint', S.current.address_field_street_hint);
  static String get line2 =>
      Tr.t('address_field.line2', S.current.address_field_line2);
  static String get city =>
      Tr.t('address_field.city', S.current.address_field_city);
  static String get state =>
      Tr.t('address_field.state', S.current.address_field_state);
  static String get governorate =>
      Tr.t('address_field.governorate', S.current.address_field_governorate);
  static String get emirate =>
      Tr.t('address_field.emirate', S.current.address_field_emirate);
  static String get region =>
      Tr.t('address_field.region', S.current.address_field_region);
  static String get county =>
      Tr.t('address_field.county', S.current.address_field_county);
  static String get postalCode =>
      Tr.t('address_field.postal_code', S.current.address_field_postal_code);
  static String get zipCode =>
      Tr.t('address_field.zip_code', S.current.address_field_zip_code);
  static String get postcode =>
      Tr.t('address_field.postcode', S.current.address_field_postcode);
  static String fieldRequired(String label) => Tr.t(
    'address_field.field_required',
    S.current.address_field_field_required(label),
  );
  static String postalInvalid(String label) => Tr.t(
    'address_field.postal_invalid',
    S.current.address_field_postal_invalid(label),
  );
  static String selectState(String label) => Tr.t(
    'address_field.select_state',
    S.current.address_field_select_state(label),
  );
}
