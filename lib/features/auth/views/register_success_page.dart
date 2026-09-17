import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/extensions/context_extensions.dart';
import '../../../core/extensions/theme_colors_extension.dart';
import '../../../core/localization/strings/auth_strings.dart';
import '../../../core/tokens/extensions.dart';
import '../../../shared/module/buttons/global_filled_button.dart';
import '../../_shared/auth_drafts.dart';
import '../../_shared/celebration_confetti.dart';
import '../../_shared/screen_entrance.dart';
import '../../_shared/shared_hero.dart';
import '../../_shared/terracotta_cta_style.dart';
import '../../gift/data/pending_gift.dart';
import '../widgets/success_mark.dart';

/// auth 4 — «تم انشاء الحساب بنجاح» / "Your account is ready".
///
/// **Not an [AuthScaffold].** Every other auth screen is a heading over
/// a form, drawn inside the same line illustration; this one is a
/// celebration — confetti edge to edge, the tick above the words rather
/// than below them, no vessel, and its single control parked at the
/// bottom of the SCREEN instead of after the content. Bending the
/// scaffold far enough to cover both would leave a widget with a
/// parameter for each half.
///
/// The body copy is the frame's own — the cancellation window, not a
/// line about the account. It reads as booking copy on an
/// account-created screen; it was queried and CONFIRMED as intended, so
/// `auth_register_success_body` carries it verbatim.
class RegisterSuccessPage extends StatelessWidget {
  const RegisterSuccessPage({super.key});

  /// Design: confetti scattered over the whole frame, behind everything.

  @override
  Widget build(BuildContext context) {
    final spacing = context.spacing;
    final text = context.textColors;

    return Scaffold(
      backgroundColor: context.backgroundColors.scaffoldBackground,
      // No app bar at all: there is nowhere to go back TO — the account
      // exists, and the step behind this one would re-register it.
      // REAL PAPER, in the air. It was a PNG of confetti lying
      // still behind the words — wallpaper, on a page about a
      // moment. See [CelebrationConfetti], which also takes
      // itself away under reduced motion.
      body: CelebrationConfetti(
        child: Stack(
          children: [
            SafeArea(
              child: Padding(
                padding: EdgeInsetsDirectional.symmetric(
                  horizontal: spacing.md,
                ),
                child: Column(
                  children: [
                    // The tick sits ABOVE the words, centred in what is
                    // left of the screen once the button has taken its
                    // place at the bottom.
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // The tick lands first and the words follow it.
                          // This screen has no header to fly in — only the
                          // bar at the bottom is shared — so without this
                          // the whole celebration is simply present the
                          // moment the page arrives.
                          const ScreenEntrance(child: SuccessMark()),
                          SizedBox(height: spacing.lg),
                          ScreenEntrance(
                            step: 1,
                            child: Text(
                              AuthStrings.registerSuccessTitle,
                              textAlign: TextAlign.center,
                              style: context.textTheme.titleLarge?.copyWith(
                                color: text.primary,
                                fontSize: 21.03,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          SizedBox(height: spacing.sm),
                          ScreenEntrance(
                            step: 2,
                            child: Text(
                              AuthStrings.registerSuccessBody,
                              textAlign: TextAlign.center,
                              style: context.textTheme.bodyMedium?.copyWith(
                                color: text.primary,
                                fontSize: 15,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    SharedHero(
                      tag: AuthHeroTag.cta,
                      // Last of the four, after the tick and the words.
                      entranceStep: 3,
                      // The bar is the same box on every screen; only the
                      // label differs, so the two words cross-fade rather
                      // than swapping the instant the flight starts.
                      flightShuttleBuilder: crossFadeShuttle,
                      child: GlobalFilledButton(
                        text: AuthStrings.continueAction,
                        onPressed: () {
                          // The flow is over — forget the number, or the
                          // next person to open the app is handed it.
                          AuthDrafts.clear();
                          // BACK TO THE GIFT, when a link is what
                          // brought them here — registering is the
                          // likeliest way a recipient gets an account
                          // at all. See [PendingGift].
                          if (PendingGift.token case final token?) {
                            context.go('/gift/$token');
                            return;
                          }
                          context.goNamed('home');
                        },
                        // No arrow: this ends the flow rather than advancing
                        // through it.
                        style: terracottaCtaStyle(showArrow: false),
                      ),
                    ),
                    SizedBox(height: spacing.md),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
