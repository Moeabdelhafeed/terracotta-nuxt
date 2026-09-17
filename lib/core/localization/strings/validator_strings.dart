import '../../../generated/l10n.dart';
import '../tr.dart';

/// Validation message strings — every `Validators.validateX` method
/// returns one of these.
class ValidatorStrings {
  ValidatorStrings._();

  // ─── Generic ────────────────────────────────────────────────
  static String get fieldIsRequired => Tr.t(
    'validator_field_is_required',
    S.current.validator_field_is_required,
  );
  static String get formInvalid =>
      Tr.t('validator.form_invalid', S.current.validator_form_invalid);
  static String get invalidFormat =>
      Tr.t('validator_invalid_format', S.current.validator_invalid_format);
  static String get containsInappropriateLanguage => Tr.t(
    'validator_contains_inappropriate_language',
    S.current.validator_contains_inappropriate_language,
  );
  static String mustBeAtLeastNCharacters(int n) => Tr.t(
    'validator_must_be_at_least_n_characters',
    S.current.validator_must_be_at_least_n_characters(n),
  );
  static String mustBeAtMostNCharacters(int n) => Tr.t(
    'validator_must_be_at_most_n_characters',
    S.current.validator_must_be_at_most_n_characters(n),
  );
  static String mustBeAtLeastN(num n) => Tr.t(
    'validator_must_be_at_least_n',
    S.current.validator_must_be_at_least_n(n),
  );
  static String mustBeAtMostN(num n) => Tr.t(
    'validator_must_be_at_most_n',
    S.current.validator_must_be_at_most_n(n),
  );

  // ─── Names ──────────────────────────────────────────────────
  static String get firstNameCannotBeEmpty => Tr.t(
    'validator_first_name_cannot_be_empty',
    S.current.validator_first_name_cannot_be_empty,
  );
  static String get firstNameMustBeAtLeast3Characters => Tr.t(
    'validator_first_name_must_be_at_least_3_characters',
    S.current.validator_first_name_must_be_at_least_3_characters,
  );
  static String get firstNameMustBeLessThan50Characters => Tr.t(
    'validator_first_name_must_be_less_than_50_characters',
    S.current.validator_first_name_must_be_less_than_50_characters,
  );
  static String get firstNameMustContainOnlyLettersAndSpaces => Tr.t(
    'validator_first_name_must_contain_only_letters_and_spaces',
    S.current.validator_first_name_must_contain_only_letters_and_spaces,
  );
  static String get lastNameCannotBeEmpty => Tr.t(
    'validator_last_name_cannot_be_empty',
    S.current.validator_last_name_cannot_be_empty,
  );
  static String get lastNameMustBeAtLeast3Characters => Tr.t(
    'validator_last_name_must_be_at_least_3_characters',
    S.current.validator_last_name_must_be_at_least_3_characters,
  );
  static String get lastNameMustBeLessThan50Characters => Tr.t(
    'validator_last_name_must_be_less_than_50_characters',
    S.current.validator_last_name_must_be_less_than_50_characters,
  );
  static String get lastNameMustContainOnlyLettersAndSpaces => Tr.t(
    'validator_last_name_must_contain_only_letters_and_spaces',
    S.current.validator_last_name_must_contain_only_letters_and_spaces,
  );
  static String get middleNameCannotBeEmpty => Tr.t(
    'validator_middle_name_cannot_be_empty',
    S.current.validator_middle_name_cannot_be_empty,
  );
  static String get middleNameMustBeAtLeast3Characters => Tr.t(
    'validator_middle_name_must_be_at_least_3_characters',
    S.current.validator_middle_name_must_be_at_least_3_characters,
  );
  static String get middleNameMustBeLessThan50Characters => Tr.t(
    'validator_middle_name_must_be_less_than_50_characters',
    S.current.validator_middle_name_must_be_less_than_50_characters,
  );
  static String get middleNameMustContainOnlyLettersAndSpaces => Tr.t(
    'validator_middle_name_must_contain_only_letters_and_spaces',
    S.current.validator_middle_name_must_contain_only_letters_and_spaces,
  );
  static String get fatherNameCannotBeEmpty => Tr.t(
    'validator_father_name_cannot_be_empty',
    S.current.validator_father_name_cannot_be_empty,
  );
  static String get fatherNameMustBeAtLeast3Characters => Tr.t(
    'validator_father_name_must_be_at_least_3_characters',
    S.current.validator_father_name_must_be_at_least_3_characters,
  );
  static String get fatherNameMustBeLessThan50Characters => Tr.t(
    'validator_father_name_must_be_less_than_50_characters',
    S.current.validator_father_name_must_be_less_than_50_characters,
  );
  static String get fatherNameMustContainOnlyLettersAndSpaces => Tr.t(
    'validator_father_name_must_contain_only_letters_and_spaces',
    S.current.validator_father_name_must_contain_only_letters_and_spaces,
  );
  static String get fullNameCannotBeEmpty => Tr.t(
    'validator_full_name_cannot_be_empty',
    S.current.validator_full_name_cannot_be_empty,
  );
  static String get fullNameMustBeLessThan100Characters => Tr.t(
    'validator_full_name_must_be_less_than_100_characters',
    S.current.validator_full_name_must_be_less_than_100_characters,
  );
  static String get fullNameMustContainOnlyLettersAndSpaces => Tr.t(
    'validator_full_name_must_contain_only_letters_and_spaces',
    S.current.validator_full_name_must_contain_only_letters_and_spaces,
  );
  static String get nameMustUseArabicLetters => Tr.t(
    'validator_name_must_use_arabic_letters',
    S.current.validator_name_must_use_arabic_letters,
  );
  static String get nameMustUseLatinLetters => Tr.t(
    'validator_name_must_use_latin_letters',
    S.current.validator_name_must_use_latin_letters,
  );
  static String fullNameMustHaveAtLeastNParts(int count) => Tr.t(
    'validator_full_name_must_have_at_least_n_parts',
    S.current.validator_full_name_must_have_at_least_n_parts(count),
  );

  // ─── Phone ──────────────────────────────────────────────────
  static String get phoneNumberCannotBeEmpty => Tr.t(
    'validator_phone_number_cannot_be_empty',
    S.current.validator_phone_number_cannot_be_empty,
  );
  static String get phoneNumberMustContainOnlyDigits => Tr.t(
    'validator_phone_number_must_contain_only_digits',
    S.current.validator_phone_number_must_contain_only_digits,
  );
  static String get phoneNumberIsTooShort => Tr.t(
    'validator_phone_number_is_too_short',
    S.current.validator_phone_number_is_too_short,
  );
  static String get phoneNumberIsTooLong => Tr.t(
    'validator_phone_number_is_too_long',
    S.current.validator_phone_number_is_too_long,
  );
  static String get invalidCountryCode => Tr.t(
    'validator_invalid_country_code',
    S.current.validator_invalid_country_code,
  );

  // ─── Password ───────────────────────────────────────────────
  static String get passwordCannotBeEmpty => Tr.t(
    'validator_password_cannot_be_empty',
    S.current.validator_password_cannot_be_empty,
  );
  static String get passwordMustBeAtLeast6Characters => Tr.t(
    'validator_password_must_be_at_least_6_characters',
    S.current.validator_password_must_be_at_least_6_characters,
  );
  static String get passwordMustContainAtLeastOneUppercaseLetter => Tr.t(
    'validator_password_must_contain_at_least_one_uppercase_letter',
    S.current.validator_password_must_contain_at_least_one_uppercase_letter,
  );
  static String get passwordMustContainAtLeastOneLowercaseLetter => Tr.t(
    'validator_password_must_contain_at_least_one_lowercase_letter',
    S.current.validator_password_must_contain_at_least_one_lowercase_letter,
  );
  static String get passwordMustContainAtLeastOneNumber => Tr.t(
    'validator_password_must_contain_at_least_one_number',
    S.current.validator_password_must_contain_at_least_one_number,
  );
  static String get passwordMustContainAtLeastOneSpecialCharacter => Tr.t(
    'validator_password_must_contain_at_least_one_special_character',
    S.current.validator_password_must_contain_at_least_one_special_character,
  );
  static String get confirmPasswordCannotBeEmpty => Tr.t(
    'validator_confirm_password_cannot_be_empty',
    S.current.validator_confirm_password_cannot_be_empty,
  );
  static String get confirmPasswordMustBeTheSameAsPassword => Tr.t(
    'validator_confirm_password_must_be_the_same_as_password',
    S.current.validator_confirm_password_must_be_the_same_as_password,
  );

  // ─── Identity ───────────────────────────────────────────────
  static String get genderCannotBeEmpty => Tr.t(
    'validator_gender_cannot_be_empty',
    S.current.validator_gender_cannot_be_empty,
  );
  static String get emailCannotBeEmpty => Tr.t(
    'validator_email_cannot_be_empty',
    S.current.validator_email_cannot_be_empty,
  );
  static String get emailMustBeValid => Tr.t(
    'validator_email_must_be_valid',
    S.current.validator_email_must_be_valid,
  );
  static String get ageCannotBeEmpty => Tr.t(
    'validator_age_cannot_be_empty',
    S.current.validator_age_cannot_be_empty,
  );
  static String get ageMustBeAtLeast12YearsOld => Tr.t(
    'validator_age_must_be_at_least_12',
    S.current.validator_age_must_be_at_least_12,
  );
  static String get ageMustBeLessThan100YearsOld => Tr.t(
    'validator_age_must_be_less_than_100',
    S.current.validator_age_must_be_less_than_100,
  );
  static String get usernameCannotBeEmpty => Tr.t(
    'validator_username_cannot_be_empty',
    S.current.validator_username_cannot_be_empty,
  );
  static String get usernameMustBeAtLeast3Characters => Tr.t(
    'validator_username_must_be_at_least_3_characters',
    S.current.validator_username_must_be_at_least_3_characters,
  );
  static String get usernameMustBeLessThan20Characters => Tr.t(
    'validator_username_must_be_less_than_20_characters',
    S.current.validator_username_must_be_less_than_20_characters,
  );
  static String get usernameMustBeValid => Tr.t(
    'validator_username_must_be_valid',
    S.current.validator_username_must_be_valid,
  );

  // ─── OTP ────────────────────────────────────────────────────
  static String get otpCannotBeEmpty => Tr.t(
    'validator_otp_cannot_be_empty',
    S.current.validator_otp_cannot_be_empty,
  );
  static String otpMustBeNDigits(int length) => Tr.t(
    'validator_otp_must_be_n_digits',
    S.current.validator_otp_must_be_n_digits(length),
  );

  // ─── Date ───────────────────────────────────────────────────
  static String get dateOfBirthCannotBeEmpty => Tr.t(
    'validator_date_of_birth_cannot_be_empty',
    S.current.validator_date_of_birth_cannot_be_empty,
  );
  static String get dateOfBirthMustBeValid => Tr.t(
    'validator_date_of_birth_must_be_valid',
    S.current.validator_date_of_birth_must_be_valid,
  );
  static String get dateCannotBeEmpty => Tr.t(
    'validator_date_cannot_be_empty',
    S.current.validator_date_cannot_be_empty,
  );
  static String get dateMustBeInTheFuture => Tr.t(
    'validator_date_must_be_in_the_future',
    S.current.validator_date_must_be_in_the_future,
  );
  static String get dateMustBeInThePast => Tr.t(
    'validator_date_must_be_in_the_past',
    S.current.validator_date_must_be_in_the_past,
  );
  static String ageAtLeastNYears(int years) => Tr.t(
    'validator_age_at_least_n_years',
    S.current.validator_age_at_least_n_years(years),
  );
  static String ageUnderNYears(int years) => Tr.t(
    'validator_age_under_n_years',
    S.current.validator_age_under_n_years(years),
  );

  // ─── Passport ───────────────────────────────────────────────
  static String get passportNumberCannotBeEmpty => Tr.t(
    'validator_passport_number_cannot_be_empty',
    S.current.validator_passport_number_cannot_be_empty,
  );
  static String get passportNumberMustBeAtLeast3Characters => Tr.t(
    'validator_passport_number_must_be_at_least_3_characters',
    S.current.validator_passport_number_must_be_at_least_3_characters,
  );
  static String get passportNumberMustBeLessThan50Characters => Tr.t(
    'validator_passport_number_must_be_less_than_50_characters',
    S.current.validator_passport_number_must_be_less_than_50_characters,
  );
  static String get passportExpiryDateCannotBeEmpty => Tr.t(
    'validator_passport_expiry_date_cannot_be_empty',
    S.current.validator_passport_expiry_date_cannot_be_empty,
  );
  static String get passportExpiryDateMustBeAtLeast6MonthsFromNow => Tr.t(
    'validator_passport_expiry_date_must_be_at_least_6_months_from_now',
    S.current.validator_passport_expiry_date_must_be_at_least_6_months_from_now,
  );

  // ─── Number ─────────────────────────────────────────────────
  static String get numberCannotBeEmpty => Tr.t(
    'validator_number_cannot_be_empty',
    S.current.validator_number_cannot_be_empty,
  );
  static String get mustBeAValidNumber => Tr.t(
    'validator_must_be_a_valid_number',
    S.current.validator_must_be_a_valid_number,
  );
  static String get mustBeAValidInteger => Tr.t(
    'validator_must_be_a_valid_integer',
    S.current.validator_must_be_a_valid_integer,
  );

  // ─── Lists ──────────────────────────────────────────────────
  static String get listCannotBeEmpty => Tr.t(
    'validator_list_cannot_be_empty',
    S.current.validator_list_cannot_be_empty,
  );
  static String listMustHaveAtLeast(int n) => Tr.t(
    'validator_list_must_have_at_least',
    S.current.validator_list_must_have_at_least(n),
  );
  static String listMustHaveAtMost(int n) => Tr.t(
    'validator_list_must_have_at_most',
    S.current.validator_list_must_have_at_most(n),
  );

  // ─── Credit card ────────────────────────────────────────────
  static String get cardNumberCannotBeEmpty => Tr.t(
    'validator_card_number_cannot_be_empty',
    S.current.validator_card_number_cannot_be_empty,
  );
  static String get cardNumberMustBeValid => Tr.t(
    'validator_card_number_must_be_valid',
    S.current.validator_card_number_must_be_valid,
  );
  static String get cardExpiryCannotBeEmpty => Tr.t(
    'validator_card_expiry_cannot_be_empty',
    S.current.validator_card_expiry_cannot_be_empty,
  );
  static String get cardExpiryMustBeValid => Tr.t(
    'validator_card_expiry_must_be_valid',
    S.current.validator_card_expiry_must_be_valid,
  );
  static String get cardExpiryMustBeMmYy => Tr.t(
    'validator_card_expiry_must_be_mm_yy',
    S.current.validator_card_expiry_must_be_mm_yy,
  );
  static String get cardExpiryMonthInvalid => Tr.t(
    'validator_card_expiry_month_invalid',
    S.current.validator_card_expiry_month_invalid,
  );
  static String get cardExpiryMustBeInTheFuture => Tr.t(
    'validator_card_expiry_must_be_in_the_future',
    S.current.validator_card_expiry_must_be_in_the_future,
  );
  static String get cardCvvCannotBeEmpty => Tr.t(
    'validator_card_cvv_cannot_be_empty',
    S.current.validator_card_cvv_cannot_be_empty,
  );
  static String get cardCvvMustBeValid => Tr.t(
    'validator_card_cvv_must_be_valid',
    S.current.validator_card_cvv_must_be_valid,
  );
  static String cardCvvMustBeNDigits(int length) => Tr.t(
    'validator_card_cvv_must_be_n_digits',
    S.current.validator_card_cvv_must_be_n_digits(length),
  );

  // ─── Geo ────────────────────────────────────────────────────
  static String get latitudeCannotBeEmpty => Tr.t(
    'validator_latitude_cannot_be_empty',
    S.current.validator_latitude_cannot_be_empty,
  );
  static String get latitudeMustBeValid => Tr.t(
    'validator_latitude_must_be_valid',
    S.current.validator_latitude_must_be_valid,
  );
  static String get longitudeCannotBeEmpty => Tr.t(
    'validator_longitude_cannot_be_empty',
    S.current.validator_longitude_cannot_be_empty,
  );
  static String get longitudeMustBeValid => Tr.t(
    'validator_longitude_must_be_valid',
    S.current.validator_longitude_must_be_valid,
  );
  static String get postalCodeCannotBeEmpty => Tr.t(
    'validator_postal_code_cannot_be_empty',
    S.current.validator_postal_code_cannot_be_empty,
  );
  static String get postalCodeMustBeValid => Tr.t(
    'validator_postal_code_must_be_valid',
    S.current.validator_postal_code_must_be_valid,
  );

  // ─── Network ────────────────────────────────────────────────
  static String get ipAddressCannotBeEmpty => Tr.t(
    'validator_ip_address_cannot_be_empty',
    S.current.validator_ip_address_cannot_be_empty,
  );
  static String get ipAddressMustBeValid => Tr.t(
    'validator_ip_address_must_be_valid',
    S.current.validator_ip_address_must_be_valid,
  );
  static String get portCannotBeEmpty => Tr.t(
    'validator_port_cannot_be_empty',
    S.current.validator_port_cannot_be_empty,
  );
  static String get portMustBeValid => Tr.t(
    'validator_port_must_be_valid',
    S.current.validator_port_must_be_valid,
  );
  static String get macAddressCannotBeEmpty => Tr.t(
    'validator_mac_address_cannot_be_empty',
    S.current.validator_mac_address_cannot_be_empty,
  );
  static String get macAddressMustBeValid => Tr.t(
    'validator_mac_address_must_be_valid',
    S.current.validator_mac_address_must_be_valid,
  );

  // ─── Identifiers ────────────────────────────────────────────
  static String get ibanCannotBeEmpty => Tr.t(
    'validator_iban_cannot_be_empty',
    S.current.validator_iban_cannot_be_empty,
  );
  static String get ibanMustBeValid => Tr.t(
    'validator_iban_must_be_valid',
    S.current.validator_iban_must_be_valid,
  );
  static String ibanLengthForCountry(String country, int length) => Tr.t(
    'validator_iban_length_for_country',
    S.current.validator_iban_length_for_country(country, length),
  );
  static String get vinCannotBeEmpty => Tr.t(
    'validator_vin_cannot_be_empty',
    S.current.validator_vin_cannot_be_empty,
  );
  static String get vinMustBeValid => Tr.t(
    'validator_vin_must_be_valid',
    S.current.validator_vin_must_be_valid,
  );

  // ─── Files ──────────────────────────────────────────────────
  static String get fileSizeCannotBeEmpty => Tr.t(
    'validator_file_size_cannot_be_empty',
    S.current.validator_file_size_cannot_be_empty,
  );
  static String get fileSizeTooLarge => Tr.t(
    'validator_file_size_too_large',
    S.current.validator_file_size_too_large,
  );
  static String get fileNameCannotBeEmpty => Tr.t(
    'validator_file_name_cannot_be_empty',
    S.current.validator_file_name_cannot_be_empty,
  );
  static String get fileNameInvalid => Tr.t(
    'validator_file_name_invalid',
    S.current.validator_file_name_invalid,
  );
  static String get fileExtensionNotAllowed => Tr.t(
    'validator_file_extension_not_allowed',
    S.current.validator_file_extension_not_allowed,
  );

  // ─── Color ──────────────────────────────────────────────────
  // ARB-key TODO: add `validator_color_hex_must_be_valid` when running
  // intl_utils:generate next. Literal fallback is safe via Tr.t.
  static String get colorHexMustBeValid =>
      Tr.t('validator_color_hex_must_be_valid', 'Use #RRGGBB format');

  // ─── URL ────────────────────────────────────────────────────
  static String get urlCannotBeEmpty => Tr.t(
    'validator_url_cannot_be_empty',
    S.current.validator_url_cannot_be_empty,
  );
  static String get urlMustBeValid => Tr.t(
    'validator_url_must_be_valid',
    S.current.validator_url_must_be_valid,
  );
  static String get urlMustStartWithHttpOrHttps => Tr.t(
    'validator_url_must_start_with_http_or_https',
    S.current.validator_url_must_start_with_http_or_https,
  );
  static String get imageUrlCannotBeEmpty => Tr.t(
    'validator_image_url_cannot_be_empty',
    S.current.validator_image_url_cannot_be_empty,
  );
  static String get imageUrlMustBeValid => Tr.t(
    'validator_image_url_must_be_valid',
    S.current.validator_image_url_must_be_valid,
  );
  static String get videoUrlCannotBeEmpty => Tr.t(
    'validator_video_url_cannot_be_empty',
    S.current.validator_video_url_cannot_be_empty,
  );
  static String get videoUrlMustBeValid => Tr.t(
    'validator_video_url_must_be_valid',
    S.current.validator_video_url_must_be_valid,
  );
}
