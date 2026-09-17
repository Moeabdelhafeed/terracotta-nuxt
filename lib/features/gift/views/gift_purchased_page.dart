import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/assets/assets.dart';
import '../../../core/extensions/context_extensions.dart';
import '../../../core/extensions/theme_colors_extension.dart';
import '../../../core/localization/strings/common_strings.dart';
import '../../../core/localization/strings/gift_strings.dart';
import '../../../core/tokens/extensions.dart';
import '../../../shared/module/buttons/global_filled_button.dart';
import '../../../shared/module/buttons/global_text_button.dart';
import '../../../shared/module/image/global_image.dart';
import '../../_shared/celebration_confetti.dart';
import '../../_shared/screen_entrance.dart';
import '../../_shared/terracotta_cta_style.dart';
import '../../auth/widgets/success_mark.dart';

/// «تم شراء الهدية!» — bought, with the link to send on.
///
/// The third of the app's celebrations, and drawn like the other two:
/// confetti edge to edge, the mark above the words, the control parked
/// at the bottom of the SCREEN. See `RegisterSuccessPage` and
/// `BookingConfirmedPage`.
///
/// Its mark is a GIFT rather than a tick. Every celebration in the app
/// says "done"; this one has to say what was done, because the thing
/// the customer still has to do — send the link — only makes sense
/// beside it.
///
/// The share link is how the recipient redeems. Opening it credits
/// THEIR wallet, not the buyer's.
class GiftPurchasedPage extends StatelessWidget {
  const GiftPurchasedPage({super.key});

  /// The same sheet the account-created frame scatters.

  @override
  Widget build(BuildContext context) {
    final spacing = context.spacing;
    final text = context.textColors;

    return Scaffold(
      backgroundColor: context.backgroundColors.scaffoldBackground,
      // No app bar: the gift is bought, and the step behind this one
      // would buy a second.
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
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          ScreenEntrance(
                            child: SuccessMark(
                              // The studio's own glyph — the same one on
                              // the tile that opened this flow.
                              art: SizedBox.square(
                                dimension: 48,
                                child: GlobalImage.a(
                                  Assets.icons.gift.defaultPath,
                                  placeholder: const SizedBox.shrink(),
                                  style: ImageStyle(
                                    fit: BoxFit.contain,
                                    borderRadius: BorderRadius.zero,
                                    color: text.onPrimary,
                                    overlayBlendMode: BlendMode.srcIn,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          SizedBox(height: spacing.lg),
                          ScreenEntrance(
                            step: 1,
                            child: Text(
                              GiftStrings.purchasedTitle,
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
                              GiftStrings.purchasedBody,
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
                    ScreenEntrance(
                      step: 3,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Leaving WITHOUT sharing is a real choice —
                          // the gift is bought either way and the link is
                          // on the gifts list — so it is offered as a
                          // word rather than a second bar competing with
                          // the one that matters.
                          GlobalTextButton(
                            text: CommonStrings.close,
                            onPressed: () => context.goNamed('home'),
                            style: ButtonStateStyle(
                              textStyle: TextStyle(
                                color: context.primaryColors.accent,
                              ),
                            ),
                          ),
                          SizedBox(height: spacing.xs),
                          GlobalFilledButton(
                            text: GiftStrings.shareLink,
                            onPressed: () {},
                            style: terracottaCtaStyle(showArrow: false)
                                .copyWith(
                                  backgroundColor: context.primaryColors.accent,
                                ),
                          ),
                        ],
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
