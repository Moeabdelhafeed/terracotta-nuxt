// Project imports:
import '../../constants/country_codes.dart';
import '../../localization/strings/validator_strings.dart';
import '../iban_registry.dart';

/// Static helpers that return a localized error string for an invalid
/// value, or `null` when the value is valid. Each `validateXxx` has an
/// `isValidXxx` companion for boolean checks.
class Validators {
  Validators._();

  // ─── Patterns ─────────────────────────────────────────────────

  /// Strips formatting characters (spaces, dashes, parens, dots) before
  /// validating a phone number.
  static final RegExp cleanPhoneNumber = RegExp(r'[\s\-\(\)\.]');

  static final RegExp uppercaseLetters = RegExp(r'[A-Z]');
  static final RegExp lowercaseLetters = RegExp(r'[a-z]');

  /// Matches if the string **contains** at least one digit (paired with
  /// `hasMatch`). Compare with [digitsOnly] which matches a string that
  /// is **entirely** digits.
  static final RegExp containsDigit = RegExp(r'[0-9]');

  /// "Special" = anything that isn't a letter, digit or whitespace — so
  /// `_`, `-`, `+`, `[`, `~` … all count (a hand-typed symbol list always
  /// misses some).
  static final RegExp specialCharacters = RegExp(
    r'[^\p{L}\p{N}\s]',
    unicode: true,
  );

  /// Practical email regex — Unicode-aware (accepts IDN local-parts and
  /// domains like `mañana@café.com` or `用户@例子.中国`), allows `+` and `%`
  /// in the local part, and any TLD length (rejects only single-char TLDs).
  static final RegExp emailPattern = RegExp(
    r'^[\p{L}\p{N}._%+\-]+@[\p{L}\p{N}.\-]+\.[\p{L}]{2,}$',
    unicode: true,
  );

  /// Real-name characters — Unicode-aware so it accepts diacritics
  /// (`José`, `Müller`), hyphens (`Mary-Jane`), apostrophes (`O'Brien`),
  /// dots (`J.R.R.`), and any script (Arabic, Cyrillic, CJK, ...).
  static final RegExp realNameCharacters = RegExp(
    r"^[\p{L}\p{M}\s\-'\.]+$",
    unicode: true,
  );

  /// Handle charset: letters, digits, `.` `_` `-` (covers the major
  /// platforms — IG/TikTok use `.`/`_`, GitHub `-`, X `_`), 3–20 chars.
  static final RegExp usernamePattern = RegExp(r'^[a-zA-Z0-9._-]{3,20}$');
  static final RegExp digitsOnly = RegExp(r'^\d+$');

  /// Image URL — `https?://…/x.{ext}` with optional query/fragment.
  static final RegExp imageUrlPattern = RegExp(
    r'^https?:\/\/.*\.(jpg|jpeg|png|gif|webp|svg)(?:\?.*)?(?:#.*)?$',
    caseSensitive: false,
  );

  /// Video URL — same shape as [imageUrlPattern].
  static final RegExp videoUrlPattern = RegExp(
    r'^https?:\/\/.*\.(mp4|mov|avi|wmv|flv|mpeg|mpg|m4v|3gp|3g2|m2v|m4p|m4b|m4r)(?:\?.*)?(?:#.*)?$',
    caseSensitive: false,
  );

  /// Bare-extension matchers — useful for checking local file paths or
  /// plain filenames (no scheme required).
  static final RegExp imageExtensionPattern = RegExp(
    r'\.(jpg|jpeg|png|gif|webp|svg)$',
    caseSensitive: false,
  );
  static final RegExp videoExtensionPattern = RegExp(
    r'\.(mp4|mov|avi|wmv|flv|mpeg|mpg|m4v|3gp|3g2|m2v|m4p|m4b|m4r)$',
    caseSensitive: false,
  );

  // ─── Constants ────────────────────────────────────────────────

  static const int minPhoneNumberDigits = 7;
  static const int maxPhoneNumberDigits = 15;
  static const int minPasswordLength = 6;
  static const int minNameLength = 3;
  static const int maxNameLength = 50;
  static const int maxFullNameLength = 100;
  static const int minAge = 12;
  static const int maxAge = 100;
  static const int minUsernameLength = 3;
  static const int maxUsernameLength = 20;
  static const int minPassportNumberLength = 3;
  static const int maxPassportNumberLength = 50;

  /// Default OTP length used by [validateOtp] when none is passed.
  static const int kOtpLength = 6;

  /// Dial codes sorted longest-first so the phone validator picks the
  /// longest matching prefix (e.g. `+1242` for Bahamas instead of `+1`).
  static final List<String> _dialCodesByLength = [...CountryCodes.dialCodes]
    ..sort((a, b) => b.length.compareTo(a.length));

  // ─── Phone number ─────────────────────────────────────────────

  static String? validatePhoneNumber(String? phoneNumber) {
    if (phoneNumber == null || phoneNumber.isEmpty) {
      return ValidatorStrings.phoneNumberCannotBeEmpty;
    }

    final cleanedNumber = phoneNumber.replaceAll(cleanPhoneNumber, '');
    final hasCountryCode = cleanedNumber.startsWith('+');

    if (hasCountryCode) {
      ({String dial, String rest})? matched;
      for (final dialCode in _dialCodesByLength) {
        if (cleanedNumber.startsWith(dialCode)) {
          matched = (
            dial: dialCode,
            rest: cleanedNumber.substring(dialCode.length),
          );
          break;
        }
      }

      if (matched == null) return ValidatorStrings.invalidCountryCode;
      if (matched.rest.isEmpty) return ValidatorStrings.phoneNumberIsTooShort;
      if (!digitsOnly.hasMatch(matched.rest)) {
        return ValidatorStrings.phoneNumberMustContainOnlyDigits;
      }
      if (matched.rest.length < minPhoneNumberDigits) {
        return ValidatorStrings.phoneNumberIsTooShort;
      }
      if (matched.rest.length > maxPhoneNumberDigits) {
        return ValidatorStrings.phoneNumberIsTooLong;
      }
    } else {
      if (!digitsOnly.hasMatch(cleanedNumber)) {
        return ValidatorStrings.phoneNumberMustContainOnlyDigits;
      }
      if (cleanedNumber.length < minPhoneNumberDigits) {
        return ValidatorStrings.phoneNumberIsTooShort;
      }
      if (cleanedNumber.length > maxPhoneNumberDigits) {
        return ValidatorStrings.phoneNumberIsTooLong;
      }
    }

    return null;
  }

  static bool isValidPhoneNumber(String? phoneNumber) =>
      validatePhoneNumber(phoneNumber) == null;

  // ─── Gender ───────────────────────────────────────────────────

  static String? validateGender(String? gender) =>
      gender == null || gender.isEmpty
      ? ValidatorStrings.genderCannotBeEmpty
      : null;

  static bool isValidGender(String? gender) => validateGender(gender) == null;

  // ─── Password ─────────────────────────────────────────────────

  static String? validateCreatePassword(String? password) {
    if (password == null || password.isEmpty) {
      return ValidatorStrings.passwordCannotBeEmpty;
    }
    if (!lowercaseLetters.hasMatch(password)) {
      return ValidatorStrings.passwordMustContainAtLeastOneLowercaseLetter;
    }
    if (!uppercaseLetters.hasMatch(password)) {
      return ValidatorStrings.passwordMustContainAtLeastOneUppercaseLetter;
    }
    if (!containsDigit.hasMatch(password)) {
      return ValidatorStrings.passwordMustContainAtLeastOneNumber;
    }
    if (!specialCharacters.hasMatch(password)) {
      return ValidatorStrings.passwordMustContainAtLeastOneSpecialCharacter;
    }
    if (password.length < minPasswordLength) {
      return ValidatorStrings.passwordMustBeAtLeast6Characters;
    }
    return null;
  }

  static bool isValidCreatePassword(String? password) =>
      validateCreatePassword(password) == null;

  /// Login-time password check — only enforces non-emptiness so existing
  /// users with weak legacy passwords can still authenticate.
  static String? validatePassword(String? password) {
    if (password == null || password.isEmpty) {
      return ValidatorStrings.passwordCannotBeEmpty;
    }
    return null;
  }

  static bool isValidPassword(String? password) =>
      validatePassword(password) == null;

  static String? validateConfirmPassword(
    String? password,
    String? confirmPassword,
  ) {
    if (confirmPassword == null || confirmPassword.isEmpty) {
      return ValidatorStrings.confirmPasswordCannotBeEmpty;
    }
    // Defer the mismatch check until the user has typed the first password —
    // otherwise the confirm field shouts as soon as it gets focus.
    if (password == null || password.isEmpty) return null;
    if (confirmPassword != password) {
      return ValidatorStrings.confirmPasswordMustBeTheSameAsPassword;
    }
    return null;
  }

  static bool isValidConfirmPassword(
    String? password,
    String? confirmPassword,
  ) => validateConfirmPassword(password, confirmPassword) == null;

  // ─── Identity ─────────────────────────────────────────────────

  /// Shared single-name rule (a "part": first / last / middle / father).
  /// Spaces stay legal — compound parts ("Abdel Rahman") are one name.
  static String? _validateNamePart(
    String? name, {
    required String emptyMsg,
    required String shortMsg,
    required String longMsg,
    required String charsMsg,
  }) {
    if (name == null || name.isEmpty) return emptyMsg;
    if (name.length < minNameLength) return shortMsg;
    if (name.length > maxNameLength) return longMsg;
    if (!realNameCharacters.hasMatch(name)) return charsMsg;
    return null;
  }

  /// Generic single-name check (first-name wording). Prefer the specific
  /// [validateFirstName] / [validateLastName] / [validateMiddleName] /
  /// [validateFatherName] so error messages name the right field.
  static String? validateRealName(String? name) => validateFirstName(name);

  static bool isValidRealName(String? name) => validateRealName(name) == null;

  static String? validateFirstName(String? name) => _validateNamePart(
    name,
    emptyMsg: ValidatorStrings.firstNameCannotBeEmpty,
    shortMsg: ValidatorStrings.firstNameMustBeAtLeast3Characters,
    longMsg: ValidatorStrings.firstNameMustBeLessThan50Characters,
    charsMsg: ValidatorStrings.firstNameMustContainOnlyLettersAndSpaces,
  );

  static String? validateLastName(String? name) => _validateNamePart(
    name,
    emptyMsg: ValidatorStrings.lastNameCannotBeEmpty,
    shortMsg: ValidatorStrings.lastNameMustBeAtLeast3Characters,
    longMsg: ValidatorStrings.lastNameMustBeLessThan50Characters,
    charsMsg: ValidatorStrings.lastNameMustContainOnlyLettersAndSpaces,
  );

  static String? validateMiddleName(String? name) => _validateNamePart(
    name,
    emptyMsg: ValidatorStrings.middleNameCannotBeEmpty,
    shortMsg: ValidatorStrings.middleNameMustBeAtLeast3Characters,
    longMsg: ValidatorStrings.middleNameMustBeLessThan50Characters,
    charsMsg: ValidatorStrings.middleNameMustContainOnlyLettersAndSpaces,
  );

  static String? validateFatherName(String? name) => _validateNamePart(
    name,
    emptyMsg: ValidatorStrings.fatherNameCannotBeEmpty,
    shortMsg: ValidatorStrings.fatherNameMustBeAtLeast3Characters,
    longMsg: ValidatorStrings.fatherNameMustBeLessThan50Characters,
    charsMsg: ValidatorStrings.fatherNameMustContainOnlyLettersAndSpaces,
  );

  /// Full name: [minParts] whitespace-separated parts, each ≥ 2 letters
  /// (`minParts: 4` for quadruple-name markets — first / father /
  /// grandfather / family).
  static String? validateFullName(String? name, {int minParts = 2}) {
    if (name == null || name.trim().isEmpty) {
      return ValidatorStrings.fullNameCannotBeEmpty;
    }
    final trimmed = name.trim();
    if (trimmed.length > maxFullNameLength) {
      return ValidatorStrings.fullNameMustBeLessThan100Characters;
    }
    if (!realNameCharacters.hasMatch(trimmed)) {
      return ValidatorStrings.fullNameMustContainOnlyLettersAndSpaces;
    }
    final parts = trimmed
        .split(RegExp(r'\s+'))
        .where((p) => p.length >= 2)
        .length;
    if (parts < minParts) {
      return ValidatorStrings.fullNameMustHaveAtLeastNParts(minParts);
    }
    return null;
  }

  static bool isValidFullName(String? name, {int minParts = 2}) =>
      validateFullName(name, minParts: minParts) == null;

  static String? validateEmail(String? email) {
    if (email == null || email.isEmpty) {
      return ValidatorStrings.emailCannotBeEmpty;
    }
    if (!emailPattern.hasMatch(email)) return ValidatorStrings.emailMustBeValid;
    return null;
  }

  static bool isValidEmail(String? email) => validateEmail(email) == null;

  /// Validates an age in years. Takes a typed [int] so callers parse once
  /// and don't need to handle [FormatException] inside the validator.
  static String? validateAge(int? age) {
    if (age == null) return ValidatorStrings.ageCannotBeEmpty;
    if (age < minAge) return ValidatorStrings.ageMustBeAtLeast12YearsOld;
    if (age > maxAge) return ValidatorStrings.ageMustBeLessThan100YearsOld;
    return null;
  }

  static bool isValidAge(int? age) => validateAge(age) == null;

  static String? validateUsername(String? username) {
    if (username == null || username.isEmpty) {
      return ValidatorStrings.usernameCannotBeEmpty;
    }
    if (username.length < minUsernameLength) {
      return ValidatorStrings.usernameMustBeAtLeast3Characters;
    }
    if (username.length > maxUsernameLength) {
      return ValidatorStrings.usernameMustBeLessThan20Characters;
    }
    if (!usernamePattern.hasMatch(username)) {
      return ValidatorStrings.usernameMustBeValid;
    }
    return null;
  }

  static bool isValidUsername(String? username) =>
      validateUsername(username) == null;

  static String? validateDateOfBirth(DateTime? dateOfBirth) {
    if (dateOfBirth == null) return ValidatorStrings.dateOfBirthCannotBeEmpty;
    if (dateOfBirth.isBefore(DateTime(1900)) ||
        dateOfBirth.isAfter(DateTime.now())) {
      return ValidatorStrings.dateOfBirthMustBeValid;
    }
    return null;
  }

  static bool isValidDateOfBirth(DateTime? dateOfBirth) =>
      validateDateOfBirth(dateOfBirth) == null;

  // ─── OTP ──────────────────────────────────────────────────────

  /// Validates a one-time code. Defaults to 6 digits but accepts a custom
  /// [length] for flows that use shorter/longer codes.
  static String? validateOtp(String? otp, {int length = kOtpLength}) {
    if (otp == null || otp.isEmpty) return ValidatorStrings.otpCannotBeEmpty;
    if (otp.length != length) return ValidatorStrings.otpMustBeNDigits(length);
    if (!digitsOnly.hasMatch(otp)) {
      return ValidatorStrings.otpMustBeNDigits(length);
    }
    return null;
  }

  static bool isValidOtp(String? otp, {int length = kOtpLength}) =>
      validateOtp(otp, length: length) == null;

  // ─── URLs ─────────────────────────────────────────────────────

  static String? validateUrl(String? url) {
    if (url == null || url.isEmpty) return ValidatorStrings.urlCannotBeEmpty;
    final uri = Uri.tryParse(url);
    if (uri == null || uri.host.isEmpty) return ValidatorStrings.urlMustBeValid;
    if (uri.scheme != 'http' && uri.scheme != 'https') {
      return ValidatorStrings.urlMustStartWithHttpOrHttps;
    }
    return null;
  }

  static bool isValidUrl(String? url) => validateUrl(url) == null;

  static String? validateImageUrl(String? imageUrl) {
    if (imageUrl == null || imageUrl.isEmpty) {
      return ValidatorStrings.imageUrlCannotBeEmpty;
    }
    if (!imageUrlPattern.hasMatch(imageUrl)) {
      return ValidatorStrings.imageUrlMustBeValid;
    }
    return null;
  }

  static bool isValidImageUrl(String? imageUrl) =>
      validateImageUrl(imageUrl) == null;

  static String? validateVideoUrl(String? videoUrl) {
    if (videoUrl == null || videoUrl.isEmpty) {
      return ValidatorStrings.videoUrlCannotBeEmpty;
    }
    if (!videoUrlPattern.hasMatch(videoUrl)) {
      return ValidatorStrings.videoUrlMustBeValid;
    }
    return null;
  }

  static bool isValidVideoUrl(String? videoUrl) =>
      validateVideoUrl(videoUrl) == null;

  // ─── Passport ─────────────────────────────────────────────────

  static String? validatePassportNumber(String? passportNumber) {
    if (passportNumber == null || passportNumber.isEmpty) {
      return ValidatorStrings.passportNumberCannotBeEmpty;
    }
    if (passportNumber.length < minPassportNumberLength) {
      return ValidatorStrings.passportNumberMustBeAtLeast3Characters;
    }
    if (passportNumber.length > maxPassportNumberLength) {
      return ValidatorStrings.passportNumberMustBeLessThan50Characters;
    }
    return null;
  }

  static bool isValidPassportNumber(String? passportNumber) =>
      validatePassportNumber(passportNumber) == null;

  static String? validatePassportExpiryDate(DateTime? passportExpiryDate) {
    if (passportExpiryDate == null) {
      return ValidatorStrings.passportExpiryDateCannotBeEmpty;
    }
    final now = DateTime.now();
    final sixMonthsFromNow = DateTime(now.year, now.month + 6, now.day);
    if (passportExpiryDate.isBefore(sixMonthsFromNow)) {
      return ValidatorStrings.passportExpiryDateMustBeAtLeast6MonthsFromNow;
    }
    return null;
  }

  static bool isValidPassportExpiryDate(DateTime? passportExpiryDate) =>
      validatePassportExpiryDate(passportExpiryDate) == null;

  // ─── Generic helpers ──────────────────────────────────────────

  /// Generic non-empty/null check. Treats whitespace-only strings and
  /// empty collections as missing.
  static String? validateRequired(Object? value) {
    if (value == null) return ValidatorStrings.fieldIsRequired;
    if (value is String && value.trim().isEmpty) {
      return ValidatorStrings.fieldIsRequired;
    }
    if (value is Iterable && value.isEmpty) {
      return ValidatorStrings.fieldIsRequired;
    }
    return null;
  }

  static bool isValidRequired(Object? value) => validateRequired(value) == null;

  /// Returns `null` if [text] is `null` (use [validateRequired] separately
  /// when the field is mandatory).
  static String? validateMinLength(String? text, int min) {
    if (text == null) return null;
    if (text.length < min) {
      return ValidatorStrings.mustBeAtLeastNCharacters(min);
    }
    return null;
  }

  static String? validateMaxLength(String? text, int max) {
    if (text == null) return null;
    if (text.length > max) return ValidatorStrings.mustBeAtMostNCharacters(max);
    return null;
  }

  static String? validateLengthRange(String? text, int min, int max) =>
      validateMinLength(text, min) ?? validateMaxLength(text, max);

  /// Returns `null` if [text] is `null` or empty. Pair with [validateRequired]
  /// for mandatory fields.
  static String? validateMatches(
    String? text,
    RegExp pattern, {
    String? error,
  }) {
    if (text == null || text.isEmpty) return null;
    if (!pattern.hasMatch(text)) return error ?? ValidatorStrings.invalidFormat;
    return null;
  }

  /// Generic numeric range check.
  static String? validateInRange<T extends num>(T? value, {T? min, T? max}) {
    if (value == null) return null;
    if (min != null && value < min) return ValidatorStrings.mustBeAtLeastN(min);
    if (max != null && value > max) return ValidatorStrings.mustBeAtMostN(max);
    return null;
  }

  // ─── Numeric parsers ──────────────────────────────────────────

  static String? validateInteger(String? text, {int? min, int? max}) {
    final trimmed = text?.trim();
    if (trimmed == null || trimmed.isEmpty) {
      return ValidatorStrings.numberCannotBeEmpty;
    }
    final n = int.tryParse(trimmed);
    if (n == null) return ValidatorStrings.mustBeAValidInteger;
    return validateInRange<int>(n, min: min, max: max);
  }

  static bool isValidInteger(String? text, {int? min, int? max}) =>
      validateInteger(text, min: min, max: max) == null;

  /// Accepts both `.` and `,` as the decimal separator so EU-locale input
  /// like `"1,5"` parses correctly.
  static String? validateDouble(String? text, {double? min, double? max}) {
    final trimmed = text?.trim().replaceAll(',', '.');
    if (trimmed == null || trimmed.isEmpty) {
      return ValidatorStrings.numberCannotBeEmpty;
    }
    final n = double.tryParse(trimmed);
    if (n == null) return ValidatorStrings.mustBeAValidNumber;
    return validateInRange<double>(n, min: min, max: max);
  }

  static bool isValidDouble(String? text, {double? min, double? max}) =>
      validateDouble(text, min: min, max: max) == null;

  // ─── Date helpers ─────────────────────────────────────────────

  static String? validateFutureDate(DateTime? date) {
    if (date == null) return ValidatorStrings.dateCannotBeEmpty;
    if (!date.isAfter(DateTime.now())) {
      return ValidatorStrings.dateMustBeInTheFuture;
    }
    return null;
  }

  static bool isValidFutureDate(DateTime? date) =>
      validateFutureDate(date) == null;

  static String? validatePastDate(DateTime? date) {
    if (date == null) return ValidatorStrings.dateCannotBeEmpty;
    if (!date.isBefore(DateTime.now())) {
      return ValidatorStrings.dateMustBeInThePast;
    }
    return null;
  }

  static bool isValidPastDate(DateTime? date) => validatePastDate(date) == null;

  /// Validates an age **derived** from [birthDate], using the same default
  /// bounds as [validateAge] unless overridden.
  static String? validateAgeFromBirthDate(
    DateTime? birthDate, {
    int min = minAge,
    int max = maxAge,
  }) {
    if (birthDate == null) return ValidatorStrings.dateOfBirthCannotBeEmpty;
    final now = DateTime.now();
    if (birthDate.isAfter(now)) return ValidatorStrings.dateOfBirthMustBeValid;
    var years = now.year - birthDate.year;
    if (now.month < birthDate.month ||
        (now.month == birthDate.month && now.day < birthDate.day)) {
      years--;
    }
    if (years < min) return ValidatorStrings.ageAtLeastNYears(min);
    if (years > max) return ValidatorStrings.ageUnderNYears(max);
    return null;
  }

  static bool isValidAgeFromBirthDate(
    DateTime? birthDate, {
    int min = minAge,
    int max = maxAge,
  }) => validateAgeFromBirthDate(birthDate, min: min, max: max) == null;

  // ─── Lists ────────────────────────────────────────────────────

  static String? validateNonEmptyList<T>(List<T>? list) {
    if (list == null || list.isEmpty) return ValidatorStrings.listCannotBeEmpty;
    return null;
  }

  static bool isValidNonEmptyList<T>(List<T>? list) =>
      validateNonEmptyList(list) == null;

  static String? validateMinItems<T>(List<T>? list, int min) {
    if ((list?.length ?? 0) < min) {
      return ValidatorStrings.listMustHaveAtLeast(min);
    }
    return null;
  }

  static bool isValidMinItems<T>(List<T>? list, int min) =>
      validateMinItems(list, min) == null;

  static String? validateMaxItems<T>(List<T>? list, int max) {
    if (list != null && list.length > max) {
      return ValidatorStrings.listMustHaveAtMost(max);
    }
    return null;
  }

  static bool isValidMaxItems<T>(List<T>? list, int max) =>
      validateMaxItems(list, max) == null;

  // ─── Credit card ──────────────────────────────────────────────

  static final RegExp _cardCleaner = RegExp(r'[\s\-]');
  static final RegExp _cardExpiryPattern = RegExp(
    r'^(\d{1,2})\/(\d{2}|\d{4})$',
  );

  static String? validateCardNumber(String? cardNumber) {
    if (cardNumber == null || cardNumber.isEmpty) {
      return ValidatorStrings.cardNumberCannotBeEmpty;
    }
    final digits = cardNumber.replaceAll(_cardCleaner, '');
    if (!digitsOnly.hasMatch(digits)) {
      return ValidatorStrings.cardNumberMustBeValid;
    }
    if (digits.length < 13 || digits.length > 19) {
      return ValidatorStrings.cardNumberMustBeValid;
    }
    if (!_luhnValid(digits)) return ValidatorStrings.cardNumberMustBeValid;
    return null;
  }

  static bool isValidCardNumber(String? cardNumber) =>
      validateCardNumber(cardNumber) == null;

  /// Standard Luhn checksum — used by credit cards, IMEI, SIN, …
  static bool _luhnValid(String digits) {
    var sum = 0;
    var alt = false;
    for (var i = digits.length - 1; i >= 0; i--) {
      var n = digits.codeUnitAt(i) - 0x30;
      if (n < 0 || n > 9) return false;
      if (alt) {
        n *= 2;
        if (n > 9) n -= 9;
      }
      sum += n;
      alt = !alt;
    }
    return sum % 10 == 0;
  }

  /// Accepts `MM/YY` or `MM/YYYY`. Compares against the *end* of the
  /// expiry month so a card stays valid through that whole month.
  static String? validateCardExpiry(String? expiry) {
    if (expiry == null || expiry.isEmpty) {
      return ValidatorStrings.cardExpiryCannotBeEmpty;
    }
    final m = _cardExpiryPattern.firstMatch(expiry);
    if (m == null) return ValidatorStrings.cardExpiryMustBeValid;
    final month = int.parse(m.group(1)!);
    var year = int.parse(m.group(2)!);
    if (year < 100) year += 2000;
    // A well-formed value with a nonsense month is a MONTH problem, not
    // a format one — say so ("17/25" → month must be 01–12).
    if (month < 1 || month > 12) return ValidatorStrings.cardExpiryMonthInvalid;
    final endOfMonth = DateTime(year, month + 1, 0, 23, 59, 59);
    if (endOfMonth.isBefore(DateTime.now())) {
      return ValidatorStrings.cardExpiryMustBeInTheFuture;
    }
    return null;
  }

  static bool isValidCardExpiry(String? expiry) =>
      validateCardExpiry(expiry) == null;

  static String? validateCardCvv(String? cvv) {
    if (cvv == null || cvv.isEmpty) {
      return ValidatorStrings.cardCvvCannotBeEmpty;
    }
    if (!digitsOnly.hasMatch(cvv)) return ValidatorStrings.cardCvvMustBeValid;
    if (cvv.length != 3 && cvv.length != 4) {
      return ValidatorStrings.cardCvvMustBeValid;
    }
    return null;
  }

  static bool isValidCardCvv(String? cvv) => validateCardCvv(cvv) == null;

  // ─── Geo ──────────────────────────────────────────────────────

  static String? validateLatitude(double? lat) {
    if (lat == null) return ValidatorStrings.latitudeCannotBeEmpty;
    if (lat < -90 || lat > 90) return ValidatorStrings.latitudeMustBeValid;
    return null;
  }

  static bool isValidLatitude(double? lat) => validateLatitude(lat) == null;

  static String? validateLongitude(double? lon) {
    if (lon == null) return ValidatorStrings.longitudeCannotBeEmpty;
    if (lon < -180 || lon > 180) return ValidatorStrings.longitudeMustBeValid;
    return null;
  }

  static bool isValidLongitude(double? lon) => validateLongitude(lon) == null;

  /// Permissive cross-country postal code — 3..10 chars of letters,
  /// digits, spaces, or hyphens. Replace with a country-specific regex
  /// when needed.
  static final RegExp postalCodePattern = RegExp(r'^[A-Za-z0-9\s\-]{3,10}$');

  static String? validatePostalCode(String? code) {
    if (code == null || code.isEmpty) {
      return ValidatorStrings.postalCodeCannotBeEmpty;
    }
    if (!postalCodePattern.hasMatch(code)) {
      return ValidatorStrings.postalCodeMustBeValid;
    }
    return null;
  }

  static bool isValidPostalCode(String? code) =>
      validatePostalCode(code) == null;

  // ─── Network ──────────────────────────────────────────────────

  static final RegExp ipv4Pattern = RegExp(r'^(\d{1,3}\.){3}\d{1,3}$');
  static final RegExp _ipv6Group = RegExp(r'^[0-9A-Fa-f]{1,4}$');

  static String? validateIpAddress(String? ip) {
    if (ip == null || ip.isEmpty) {
      return ValidatorStrings.ipAddressCannotBeEmpty;
    }
    if (ipv4Pattern.hasMatch(ip)) {
      for (final p in ip.split('.')) {
        final n = int.parse(p);
        if (n < 0 || n > 255) return ValidatorStrings.ipAddressMustBeValid;
      }
      return null;
    }
    if (_isValidIpv6(ip)) return null;
    return ValidatorStrings.ipAddressMustBeValid;
  }

  /// Hand-validates an IPv6 string. Allows at most one `::` shorthand,
  /// requires every group to be 1..4 hex chars, and enforces a total of
  /// 8 groups (or fewer when `::` is present).
  static bool _isValidIpv6(String ip) {
    if ('::'.allMatches(ip).length > 1) return false;
    if (ip.contains('::')) {
      final parts = ip.split('::');
      if (parts.length != 2) return false;
      final left = parts[0].isEmpty ? const <String>[] : parts[0].split(':');
      final right = parts[1].isEmpty ? const <String>[] : parts[1].split(':');
      if (left.length + right.length > 7) return false;
      for (final g in left) {
        if (!_ipv6Group.hasMatch(g)) return false;
      }
      for (final g in right) {
        if (!_ipv6Group.hasMatch(g)) return false;
      }
      return true;
    }
    final groups = ip.split(':');
    if (groups.length != 8) return false;
    for (final g in groups) {
      if (!_ipv6Group.hasMatch(g)) return false;
    }
    return true;
  }

  static bool isValidIpAddress(String? ip) => validateIpAddress(ip) == null;

  static String? validatePort(int? port) {
    if (port == null) return ValidatorStrings.portCannotBeEmpty;
    if (port < 1 || port > 65535) return ValidatorStrings.portMustBeValid;
    return null;
  }

  static bool isValidPort(int? port) => validatePort(port) == null;

  /// Accepts:
  ///  - colon form `aa:bb:cc:dd:ee:ff`
  ///  - dash form  `aa-bb-cc-dd-ee-ff`
  ///  - bare form  `aabbccddeeff`
  ///  - Cisco form `aabb.ccdd.eeff`
  static final RegExp macAddressPattern = RegExp(
    r'^(?:[0-9A-Fa-f]{2}([:\-])(?:[0-9A-Fa-f]{2}\1){4}[0-9A-Fa-f]{2}'
    r'|[0-9A-Fa-f]{12}'
    r'|[0-9A-Fa-f]{4}\.[0-9A-Fa-f]{4}\.[0-9A-Fa-f]{4})$',
  );

  static String? validateMacAddress(String? mac) {
    if (mac == null || mac.isEmpty) {
      return ValidatorStrings.macAddressCannotBeEmpty;
    }
    if (!macAddressPattern.hasMatch(mac)) {
      return ValidatorStrings.macAddressMustBeValid;
    }
    return null;
  }

  static bool isValidMacAddress(String? mac) => validateMacAddress(mac) == null;

  // ─── Identifiers (IBAN, VIN) ─────────────────────────────────

  static final RegExp _ibanFormat = RegExp(r'^[A-Z]{2}\d{2}[A-Z0-9]+$');

  static String? validateIban(String? iban) {
    if (iban == null || iban.isEmpty) return ValidatorStrings.ibanCannotBeEmpty;
    final normalized = iban.replaceAll(RegExp(r'\s'), '').toUpperCase();
    if (normalized.length < 15 || normalized.length > 34) {
      return ValidatorStrings.ibanMustBeValid;
    }
    if (!_ibanFormat.hasMatch(normalized)) {
      return ValidatorStrings.ibanMustBeValid;
    }
    // Registry length first: a truncated Jordanian IBAN gets "must be 30
    // characters", not a checksum shrug.
    final expected = kIbanLengths[normalized.substring(0, 2)];
    if (expected != null && normalized.length != expected) {
      return ValidatorStrings.ibanLengthForCountry(
        normalized.substring(0, 2),
        expected,
      );
    }
    if (!_ibanChecksumValid(normalized)) {
      return ValidatorStrings.ibanMustBeValid;
    }
    return null;
  }

  static bool isValidIban(String? iban) => validateIban(iban) == null;

  /// IBAN mod-97 checksum — move first 4 chars to end, replace each letter
  /// with `(letter - 'A' + 10)`, then compute `value % 97 == 1` digit-by-
  /// digit to avoid BigInt allocation.
  static bool _ibanChecksumValid(String iban) {
    final rearranged = iban.substring(4) + iban.substring(0, 4);
    var rem = 0;
    for (var i = 0; i < rearranged.length; i++) {
      final c = rearranged.codeUnitAt(i);
      if (c >= 0x30 && c <= 0x39) {
        rem = (rem * 10 + (c - 0x30)) % 97;
      } else if (c >= 0x41 && c <= 0x5A) {
        final value = c - 0x41 + 10; // 10..35
        rem = (rem * 100 + value) % 97;
      } else {
        return false;
      }
    }
    return rem == 1;
  }

  /// 17 chars, no `I` / `O` / `Q`.
  static final RegExp vinPattern = RegExp(r'^[A-HJ-NPR-Z0-9]{17}$');

  static String? validateVin(String? vin) {
    if (vin == null || vin.isEmpty) return ValidatorStrings.vinCannotBeEmpty;
    final normalized = vin.toUpperCase();
    if (!vinPattern.hasMatch(normalized)) {
      return ValidatorStrings.vinMustBeValid;
    }
    if (!_vinChecksumValid(normalized)) return ValidatorStrings.vinMustBeValid;
    return null;
  }

  static bool isValidVin(String? vin) => validateVin(vin) == null;

  /// VIN check digit at position 9 (NHTSA spec). Mostly mandatory for
  /// North-American VINs; many European VINs intentionally fail this so
  /// real-world use sometimes prefers [vinPattern] alone.
  static bool _vinChecksumValid(String vin) {
    const transliterate = <String, int>{
      'A': 1,
      'B': 2,
      'C': 3,
      'D': 4,
      'E': 5,
      'F': 6,
      'G': 7,
      'H': 8,
      'J': 1,
      'K': 2,
      'L': 3,
      'M': 4,
      'N': 5,
      'P': 7,
      'R': 9,
      'S': 2,
      'T': 3,
      'U': 4,
      'V': 5,
      'W': 6,
      'X': 7,
      'Y': 8,
      'Z': 9,
    };
    const weights = [8, 7, 6, 5, 4, 3, 2, 10, 0, 9, 8, 7, 6, 5, 4, 3, 2];
    var sum = 0;
    for (var i = 0; i < 17; i++) {
      final c = vin[i];
      final n = transliterate[c] ?? int.tryParse(c);
      if (n == null) return false;
      sum += n * weights[i];
    }
    final check = sum % 11;
    final expected = check == 10 ? 'X' : check.toString();
    return vin[8] == expected;
  }

  // ─── Files ────────────────────────────────────────────────────

  static String? validateFileSize(int? bytes, {required int maxBytes}) {
    if (bytes == null) return ValidatorStrings.fileSizeCannotBeEmpty;
    if (bytes > maxBytes) return ValidatorStrings.fileSizeTooLarge;
    return null;
  }

  static bool isValidFileSize(int? bytes, {required int maxBytes}) =>
      validateFileSize(bytes, maxBytes: maxBytes) == null;

  /// True if [path]'s last extension is in [allowed]. Case-insensitive.
  /// Pass a [Set] (precomputed lowercase, dot-stripped) for hot paths;
  /// otherwise an [Iterable] is normalized on the fly.
  static String? validateFileExtension(
    String? path, {
    required Iterable<String> allowed,
  }) {
    if (path == null || path.isEmpty) {
      return ValidatorStrings.fileNameCannotBeEmpty;
    }
    final lastDot = path.lastIndexOf('.');
    if (lastDot < 0 || lastDot == path.length - 1) {
      return ValidatorStrings.fileExtensionNotAllowed;
    }
    final ext = path.substring(lastDot + 1).toLowerCase();
    final ok = allowed is Set<String>
        ? allowed.contains(ext)
        : allowed.any((e) => e.toLowerCase().replaceFirst('.', '') == ext);
    if (!ok) return ValidatorStrings.fileExtensionNotAllowed;
    return null;
  }

  static bool isValidFileExtension(
    String? path, {
    required Iterable<String> allowed,
  }) => validateFileExtension(path, allowed: allowed) == null;

  static final RegExp _badFileNameChars = RegExp(r'[<>:"/\\|?*\x00-\x1F]');

  /// Rejects path-traversal characters, control chars, and the `.` / `..`
  /// special names. Suitable for filename inputs only — not for full paths.
  static String? validateFileName(String? name) {
    if (name == null || name.isEmpty) {
      return ValidatorStrings.fileNameCannotBeEmpty;
    }
    if (_badFileNameChars.hasMatch(name)) {
      return ValidatorStrings.fileNameInvalid;
    }
    if (name == '.' || name == '..') return ValidatorStrings.fileNameInvalid;
    return null;
  }

  static bool isValidFileName(String? name) => validateFileName(name) == null;

  // ─── Color ────────────────────────────────────────────────────

  static final RegExp _hexColorPattern = RegExp(r'^#[0-9A-Fa-f]{6}$');

  /// Accepts `#RRGGBB` form. Returns `null` for empty input — pair with
  /// [validateRequired] when mandatory.
  static String? validateColorHex(String? value) {
    if (value == null || value.isEmpty) return null;
    if (!_hexColorPattern.hasMatch(value)) {
      return ValidatorStrings.colorHexMustBeValid;
    }
    return null;
  }

  static bool isValidColorHex(String? value) => validateColorHex(value) == null;

  // ─── Composition ──────────────────────────────────────────────

  /// Compose multiple [Validator]s into one — runs each in order and
  /// returns the first non-null error. Cheaper checks should come first.
  ///
  /// ```dart
  /// final v = Validators.compose<String>([
  ///   Validators.validateRequired,
  ///   (s) => Validators.validateMinLength(s, 8),
  ///   Validators.validateEmail,
  /// ]);
  /// final err = v(textController.text);
  /// ```
  static Validator<T> compose<T>(List<Validator<T>> validators) {
    return (T? value) {
      for (final v in validators) {
        final err = v(value);
        if (err != null) return err;
      }
      return null;
    };
  }
}

/// A predicate-style validator that returns `null` when [T] is acceptable,
/// or a localized error string otherwise — the same shape Flutter's
/// `FormField.validator` callbacks expect. Compose with [Validators.compose].
typedef Validator<T> = String? Function(T? value);

/// Ergonomic shortcuts on `String?` for the common bool-returning checks.
/// ```dart
/// if (textField.text.isValidEmail) submit();
/// ```
extension StringValidatorsX on String? {
  bool get isValidEmail => Validators.isValidEmail(this);
  bool get isValidUrl => Validators.isValidUrl(this);
  bool get isValidImageUrl => Validators.isValidImageUrl(this);
  bool get isValidVideoUrl => Validators.isValidVideoUrl(this);
  bool get isValidPhoneNumber => Validators.isValidPhoneNumber(this);
  bool get isValidUsername => Validators.isValidUsername(this);
  bool get isValidRealName => Validators.isValidRealName(this);
  bool get isValidPassword => Validators.isValidPassword(this);
  bool get isValidCreatePassword => Validators.isValidCreatePassword(this);
  bool get isValidPostalCode => Validators.isValidPostalCode(this);
  bool get isValidCardNumber => Validators.isValidCardNumber(this);
  bool get isValidCardExpiry => Validators.isValidCardExpiry(this);
  bool get isValidCardCvv => Validators.isValidCardCvv(this);
  bool get isValidIpAddress => Validators.isValidIpAddress(this);
  bool get isValidMacAddress => Validators.isValidMacAddress(this);
  bool get isValidIban => Validators.isValidIban(this);
  bool get isValidVin => Validators.isValidVin(this);
  bool get isValidFileName => Validators.isValidFileName(this);
}
