import '../../../generated/l10n.dart';
import '../tr.dart';

/// Copy for the three intro pages — the `onboarding_` key family's
/// page content, as opposed to its chrome (next / skip / get started),
/// which lives on `OnboardingStrings` in `core/onboarding/`.
///
/// The Arabic is the source: it is what the design was drawn with and
/// what the studio approved. The English was written to match its
/// tone, not the other way round.
class OnboardingIntroStrings {
  OnboardingIntroStrings._();

  // ─── 1 · Make your piece ────────────────────────────────────

  static String get makeTitle =>
      Tr.t('onboarding.make_title', S.current.onboarding_make_title);

  static String get makeBody =>
      Tr.t('onboarding.make_body', S.current.onboarding_make_body);

  // ─── 2 · The workshop ───────────────────────────────────────

  static String get workshopTitle =>
      Tr.t('onboarding.workshop_title', S.current.onboarding_workshop_title);

  static String get workshopBody =>
      Tr.t('onboarding.workshop_body', S.current.onboarding_workshop_body);

  // ─── 3 · Track your order ───────────────────────────────────

  static String get trackTitle =>
      Tr.t('onboarding.track_title', S.current.onboarding_track_title);

  static String get trackBody =>
      Tr.t('onboarding.track_body', S.current.onboarding_track_body);
}
