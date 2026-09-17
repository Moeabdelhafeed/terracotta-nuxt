import '../../../generated/l10n.dart';
import '../tr.dart';

/// Strings for the `contact_form_` key family — contact-form call sites
/// resolve their labels/hints/validation messages through this class.
class ContactFormStrings {
  ContactFormStrings._();

  static String get messageLabel =>
      Tr.t('contact_form.message_label', S.current.contact_form_message_label);
  static String get messageHint =>
      Tr.t('contact_form.message_hint', S.current.contact_form_message_hint);
  static String get messageRequired => Tr.t(
    'contact_form.message_required',
    S.current.contact_form_message_required,
  );
}
