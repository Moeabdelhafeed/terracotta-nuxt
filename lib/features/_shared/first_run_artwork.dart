import 'package:flutter/material.dart';

import '../../core/constants/assets/assets.dart';

/// The drawings on the screens a customer sees FIRST, decoded while the
/// splash is still up.
///
/// ## Why they need warming at all
///
/// `GlobalImage` waits `placeholderDelay` (200ms) before showing a
/// shimmer, and once one is up it stays `placeholderMinDuration` (400ms)
/// so it does not flash. That is right for a network image and wrong for
/// a file already on the device — but the rule only fires if the first
/// frame takes longer than 200ms, and on a cold start it does: bootstrap,
/// the first API calls and the route transition are all competing for
/// the same isolate. An image that was ready at 250ms is then covered
/// for 600.
///
/// None of these files is big — the largest is 345KB at 350×429, a few
/// milliseconds to decode. The delay was never decoding; it was
/// decoding at the worst possible moment. Doing it while the splash
/// holds means `Image.asset` resolves straight from the cache and the
/// first frame paints the drawing, so the 200ms threshold is never
/// approached.
///
/// ## What belongs here
///
/// Only artwork on the first screens after the splash — onboarding and
/// the auth flow. This runs on the critical path to the app being
/// usable, so a screen the customer may never open does not belong;
/// let it decode when it is opened.
abstract final class FirstRunArtwork {
  /// Onboarding: three drawings and the page indicator.
  static const onboarding = <String>[
    'assets/images/onboarding-1.png',
    'assets/images/onboarding-2.png',
    'assets/images/onboarding-3.png',
    'assets/images/vessel-dot.png',
  ];

  /// The auth flow: one drawing per screen, plus the mark under the
  /// heading and the confetti behind the success screen.
  static const auth = <String>[
    'assets/images/login-register-illustration.png',
    'assets/images/enter-otp-illustration.png',
    'assets/images/chnage-password-request-illustration.png',
    'assets/images/chnage-password-illustration.png',
    'assets/images/vecteezy_colorful-bright-confetti-isolated-on-transparent'
        '-background_11167813 1.png',
  ];

  /// The mark under every auth heading, which is also the splash's own
  /// hero — so it is usually warm already, and listing it costs nothing
  /// when it is.
  static String get mark => Assets.logos.mark.defaultPath;

  static List<String> get all => [...onboarding, ...auth, mark];

  /// Decode them all, and never fail the caller.
  ///
  /// A missing or corrupt asset must not take the splash down with it —
  /// the screen that draws it has its own error state, and reaching that
  /// screen is strictly better than never leaving the splash.
  static Future<void> warm(BuildContext context) async {
    for (final path in all) {
      if (!context.mounted) return;
      try {
        await precacheImage(AssetImage(path), context);
      } on Object {
        // Deliberately swallowed — see above.
      }
    }
  }
}
