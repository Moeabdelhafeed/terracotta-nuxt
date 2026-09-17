import '../../../generated/l10n.dart';
import '../tr.dart';

/// Strings for the `amount_field` prefix family — call sites resolve
/// these keys through this class instead of `S.current` directly.
class AmountFieldStrings {
  AmountFieldStrings._();

  static String get preferredCurrencies => Tr.t(
    'amount_field.preferred_currencies',
    S.current.amount_field_preferred_currencies,
  );

  static String get allCurrencies => Tr.t(
    'amount_field.all_currencies',
    S.current.amount_field_all_currencies,
  );
}

/// Strings for the `bank_field` prefix family — call sites resolve
/// these keys through this class instead of `S.current` directly.
class BankFieldStrings {
  BankFieldStrings._();

  static String get holderLabel =>
      Tr.t('bank_field.holder_label', S.current.bank_field_holder_label);

  static String get holderHint =>
      Tr.t('bank_field.holder_hint', S.current.bank_field_holder_hint);

  static String get ibanLabel =>
      Tr.t('bank_field.iban_label', S.current.bank_field_iban_label);

  static String get swiftBicLabel =>
      Tr.t('bank_field.swift_bic_label', S.current.bank_field_swift_bic_label);
}

/// Strings for the `card_field` prefix family — payment-card form field
/// identifiers.
class CardFieldStrings {
  CardFieldStrings._();

  static String get numberLabel =>
      Tr.t('card_field.number_label', S.current.card_field_number_label);

  static String get expiryLabel =>
      Tr.t('card_field.expiry_label', S.current.card_field_expiry_label);

  static String get cvvLabel =>
      Tr.t('card_field.cvv_label', S.current.card_field_cvv_label);
}

/// Strings for the `crypto_field` prefix family — call sites resolve
/// these keys through this class instead of `S.current` directly.
class CryptoFieldStrings {
  CryptoFieldStrings._();

  static String get hint =>
      Tr.t('crypto_field.hint', S.current.crypto_field_hint);

  static String get required =>
      Tr.t('crypto_field.required', S.current.crypto_field_required);

  static String invalid(String network) =>
      Tr.t('crypto_field.invalid', S.current.crypto_field_invalid(network));
}

/// Strings for the `login_field` prefix family — call sites resolve
/// these keys through this class instead of `S.current` directly.
class LoginFieldStrings {
  LoginFieldStrings._();

  static String get hint =>
      Tr.t('login_field.hint', S.current.login_field_hint);
}

/// Strings for the `measurement_field` prefix family — call sites resolve
/// these keys through this class instead of `S.current` directly.
class MeasurementFieldStrings {
  MeasurementFieldStrings._();

  static String get preferredUnits => Tr.t(
    'measurement_field.preferred_units',
    S.current.measurement_field_preferred_units,
  );

  static String get allUnits => Tr.t(
    'measurement_field.all_units',
    S.current.measurement_field_all_units,
  );
}

/// Strings for the `plate_field` prefix family — call sites resolve
/// these keys through this class instead of `S.current` directly.
class PlateFieldStrings {
  PlateFieldStrings._();

  static String get hint =>
      Tr.t('plate_field.hint', S.current.plate_field_hint);

  static String get required =>
      Tr.t('plate_field.required', S.current.plate_field_required);

  static String get invalid =>
      Tr.t('plate_field.invalid', S.current.plate_field_invalid);
}
