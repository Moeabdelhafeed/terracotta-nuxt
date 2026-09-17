import '../../../generated/l10n.dart';
import '../tr.dart';

/// Strings for the `wizard_` key prefix family — `GlobalWizard` chrome
/// buttons + discard-draft dialog.
class WizardStrings {
  WizardStrings._();

  static String get back => Tr.t('wizard.back', S.current.wizard_back);
  static String get next => Tr.t('wizard.next', S.current.wizard_next);
  static String get submit => Tr.t('wizard.submit', S.current.wizard_submit);
  static String get discardDraftTitle =>
      Tr.t('wizard.discard_draft_title', S.current.wizard_discard_draft_title);
  static String get discardDraftBody =>
      Tr.t('wizard.discard_draft_body', S.current.wizard_discard_draft_body);
  static String get keepDraft =>
      Tr.t('wizard.keep_draft', S.current.wizard_keep_draft);
  static String get discard => Tr.t('wizard.discard', S.current.wizard_discard);

  static String get submitFailed =>
      Tr.t('wizard.submit_failed', S.current.wizard_submit_failed);
  static String get clearDraft =>
      Tr.t('wizard.clear_draft', S.current.wizard_clear_draft);
}
