import '../../../generated/l10n.dart';
import '../tr.dart';

/// Strings for the `text_field_` key family — text-field module call sites
/// (validation requirements, password UX, counters, a11y labels) go through
/// this class.
class TextFieldStrings {
  TextFieldStrings._();

  static String reqMinLength(int length) => Tr.t(
    'text_field.req_min_length',
    S.current.text_field_req_min_length(length),
  );
  static String get reqUppercase =>
      Tr.t('text_field.req_uppercase', S.current.text_field_req_uppercase);
  static String get reqLowercase =>
      Tr.t('text_field.req_lowercase', S.current.text_field_req_lowercase);
  static String get reqDigit =>
      Tr.t('text_field.req_digit', S.current.text_field_req_digit);
  static String get reqSpecialChar => Tr.t(
    'text_field.req_special_char',
    S.current.text_field_req_special_char,
  );
  static String get reqNoSpaces =>
      Tr.t('text_field.req_no_spaces', S.current.text_field_req_no_spaces);
  static String get revealPasswordTitle => Tr.t(
    'text_field.reveal_password_title',
    S.current.text_field_reveal_password_title,
  );
  static String get revealPasswordMessage => Tr.t(
    'text_field.reveal_password_message',
    S.current.text_field_reveal_password_message,
  );
  static String get reveal =>
      Tr.t('text_field.reveal', S.current.text_field_reveal);
  static String get cancel =>
      Tr.t('text_field.cancel', S.current.text_field_cancel);
  static String get word => Tr.t('text_field.word', S.current.text_field_word);
  static String get words =>
      Tr.t('text_field.words', S.current.text_field_words);
  static String get chars =>
      Tr.t('text_field.chars', S.current.text_field_chars);
  static String get capsLockOn =>
      Tr.t('text_field.caps_lock_on', S.current.text_field_caps_lock_on);
  static String get strengthWeak =>
      Tr.t('text_field.strength_weak', S.current.text_field_strength_weak);
  static String get strengthMedium =>
      Tr.t('text_field.strength_medium', S.current.text_field_strength_medium);
  static String get strengthStrong =>
      Tr.t('text_field.strength_strong', S.current.text_field_strength_strong);
  static String get clearAll =>
      Tr.t('text_field.clear_all', S.current.text_field_clear_all);
  static String get generatePassword => Tr.t(
    'text_field.generate_password',
    S.current.text_field_generate_password,
  );
  static String get undo => Tr.t('text_field.undo', S.current.text_field_undo);
  static String get redo => Tr.t('text_field.redo', S.current.text_field_redo);
  static String get clear =>
      Tr.t('text_field.clear', S.current.text_field_clear);
  static String get voiceInput =>
      Tr.t('text_field.voice_input', S.current.text_field_voice_input);
  static String get holdToReveal =>
      Tr.t('text_field.hold_to_reveal', S.current.text_field_hold_to_reveal);
  static String get toggleVisibility => Tr.t(
    'text_field.toggle_visibility',
    S.current.text_field_toggle_visibility,
  );
  static String get profanityWarning => Tr.t(
    'text_field.profanity_warning',
    S.current.text_field_profanity_warning,
  );
  static String namePartsProgress(int count, int total) => Tr.t(
    'text_field.name_parts_progress',
    S.current.text_field_name_parts_progress(count, total),
  );
  static String get passwordHint =>
      Tr.t('text_field.password_hint', S.current.text_field_password_hint);
  static String get passwordCreateHint => Tr.t(
    'text_field.password_create_hint',
    S.current.text_field_password_create_hint,
  );
  static String get passwordConfirmHint => Tr.t(
    'text_field.password_confirm_hint',
    S.current.text_field_password_confirm_hint,
  );
  static String get screenCaptureWarning => Tr.t(
    'text_field.screen_capture_warning',
    S.current.text_field_screen_capture_warning,
  );
  static String emailDomainNotAllowed(String domains) => Tr.t(
    'text_field.email_domain_not_allowed',
    S.current.text_field_email_domain_not_allowed(domains),
  );
  static String get emailDomainUnreachable => Tr.t(
    'text_field.email_domain_unreachable',
    S.current.text_field_email_domain_unreachable,
  );
  static String passwordBreached(int count) => Tr.t(
    'text_field.password_breached',
    S.current.text_field_password_breached(count),
  );
}
