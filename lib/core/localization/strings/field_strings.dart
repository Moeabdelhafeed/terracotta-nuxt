import '../../../generated/l10n.dart';
import '../tr.dart';

/// Default hint strings for the common field wrappers
/// (`shared/common/text_form_fields/`). Grouped under the `field_`
/// key prefix — when per-flow sub-groups land (e.g. `field_auth_*`),
/// split THIS class, not the call sites.
///
/// Format-template hints (`0000 0000 0000 0000`, `XX00 …`, `0.00`)
/// intentionally stay literal in the wrappers — they are structure
/// previews, not prose.
class FieldStrings {
  FieldStrings._();

  static String get emailHint =>
      Tr.t('field.hint_email', S.current.field_hint_email);
  static String get phoneHint =>
      Tr.t('field.hint_phone', S.current.field_hint_phone);
  static String get usernameHint =>
      Tr.t('field.hint_username', S.current.field_hint_username);
  static String get passportHint =>
      Tr.t('field.hint_passport', S.current.field_hint_passport);
  static String get cardholderHint =>
      Tr.t('field.hint_cardholder', S.current.field_hint_cardholder);
  static String get searchHint =>
      Tr.t('field.hint_search', S.current.field_hint_search);
  static String get nameHint =>
      Tr.t('field.hint_name', S.current.field_hint_name);
  static String get emailLabel =>
      Tr.t('field.label_email', S.current.field_label_email);
  static String get passwordLabel =>
      Tr.t('field.label_password', S.current.field_label_password);
  static String get confirmPasswordLabel => Tr.t(
    'field.label_confirm_password',
    S.current.field_label_confirm_password,
  );
  static String get phoneLabel =>
      Tr.t('field.label_phone', S.current.field_label_phone);
  static String get nameLabel =>
      Tr.t('field.label_name', S.current.field_label_name);
  static String get usernameLabel =>
      Tr.t('field.label_username', S.current.field_label_username);
  static String get urlLabel =>
      Tr.t('field.label_url', S.current.field_label_url);
  static String get codeLabel =>
      Tr.t('field.label_code', S.current.field_label_code);
  static String get numberLabel =>
      Tr.t('field.label_number', S.current.field_label_number);
}
