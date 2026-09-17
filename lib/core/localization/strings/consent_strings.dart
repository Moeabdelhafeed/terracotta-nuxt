import '../../../generated/l10n.dart';
import '../tr.dart';

/// Strings for the `consent_` key prefix family — the segmented
/// "I agree to the {Terms} and {Privacy}" sentence of
/// `ConsentCheckboxField` (segments, not one string, so the link spans
/// stay tappable per locale).
class ConsentStrings {
  ConsentStrings._();

  static String get prefix => Tr.t('consent.prefix', S.current.consent_prefix);
  static String get terms => Tr.t('consent.terms', S.current.consent_terms);
  static String get and => Tr.t('consent.and', S.current.consent_and);
  static String get privacy =>
      Tr.t('consent.privacy', S.current.consent_privacy);
  static String get required =>
      Tr.t('consent.required', S.current.consent_required);
}
