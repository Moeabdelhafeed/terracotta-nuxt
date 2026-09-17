import '../../../core/localization/strings/onboarding_intro_strings.dart';
import '../../../core/onboarding/onboarding_page.dart';

/// The three intro pages, in the order the design draws them.
///
/// Order is LOGICAL, not visual: page 0 is the first one a customer
/// sees, which the Arabic build renders on the right and the English
/// build on the left. Nothing here encodes a side.
///
/// Artwork bleeds on pages 1 and 3 — the design lets both line
/// drawings run past the frame edge, and cropping them to fit reads as
/// a mistake rather than a choice. Page 2's collage is inset to the
/// same 20pt margin as the rest of the screen and does not bleed.
List<OnboardingPage> terracottaOnboardingPages() => [
  OnboardingPage.image(
    asset: 'assets/images/onboarding-1.png',
    title: OnboardingIntroStrings.makeTitle,
    body: OnboardingIntroStrings.makeBody,
    bleed: true,
  ),
  OnboardingPage.image(
    asset: 'assets/images/onboarding-2.png',
    title: OnboardingIntroStrings.workshopTitle,
    body: OnboardingIntroStrings.workshopBody,
  ),
  OnboardingPage.image(
    asset: 'assets/images/onboarding-3.png',
    title: OnboardingIntroStrings.trackTitle,
    body: OnboardingIntroStrings.trackBody,
    bleed: true,
  ),
];
