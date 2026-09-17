import '../../../generated/l10n.dart';
import '../tr.dart';

/// Strings for the `phone_field_` key prefix family — phone-field call
/// sites resolve their localized text through this class.
class PhoneFieldStrings {
  PhoneFieldStrings._();

  static String get preferredCountries => Tr.t(
    'phone_field.preferred_countries',
    S.current.phone_field_preferred_countries,
  );
  static String get allCountries =>
      Tr.t('phone_field.all_countries', S.current.phone_field_all_countries);
  static String lengthExact(int count) => Tr.t(
    'phone_field.length_exact',
    S.current.phone_field_length_exact(count),
  );
  static String lengthRange(int min, int max) => Tr.t(
    'phone_field.length_range',
    S.current.phone_field_length_range(min, max),
  );
  static String mobileLengthExact(int count) => Tr.t(
    'phone_field.mobile_length_exact',
    S.current.phone_field_mobile_length_exact(count),
  );
  static String mobileLengthRange(int min, int max) => Tr.t(
    'phone_field.mobile_length_range',
    S.current.phone_field_mobile_length_range(min, max),
  );
  static String mobilePrefix(String prefixes) => Tr.t(
    'phone_field.mobile_prefix',
    S.current.phone_field_mobile_prefix(prefixes),
  );
}
