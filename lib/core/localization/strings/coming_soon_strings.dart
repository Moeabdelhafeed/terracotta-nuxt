import '../../../generated/l10n.dart';
import '../tr.dart';

/// Strings for the `coming_soon_` key prefix family — the coming-soon
/// system page.
class ComingSoonStrings {
  ComingSoonStrings._();

  static String get thisFeature =>
      Tr.t('coming_soon.this_feature', S.current.coming_soon_this_feature);

  static String get title =>
      Tr.t('coming_soon.title', S.current.coming_soon_title);

  static String featureOnTheWay(String feature) => Tr.t(
    'coming_soon.feature_on_the_way',
    S.current.coming_soon_feature_on_the_way(feature),
  );

  static String get bodyPlain =>
      Tr.t('coming_soon.body_plain', S.current.coming_soon_body_plain);

  static String get etaLabel =>
      Tr.t('coming_soon.eta_label', S.current.coming_soon_eta_label);

  static String get changeEmail =>
      Tr.t('coming_soon.change_email', S.current.coming_soon_change_email);

  static String get body =>
      Tr.t('coming_soon.body', S.current.coming_soon_body);

  static String get enterEmail =>
      Tr.t('coming_soon.enter_email', S.current.coming_soon_enter_email);

  static String get emailInvalid =>
      Tr.t('coming_soon.email_invalid', S.current.coming_soon_email_invalid);

  static String get notifyMe =>
      Tr.t('coming_soon.notify_me', S.current.coming_soon_notify_me);

  static String get successTitle =>
      Tr.t('coming_soon.success_title', S.current.coming_soon_success_title);

  static String successBody(String email) => Tr.t(
    'coming_soon.success_body',
    S.current.coming_soon_success_body(email),
  );

  static String get saveFailed =>
      Tr.t('coming_soon.save_failed', S.current.coming_soon_save_failed);
}
