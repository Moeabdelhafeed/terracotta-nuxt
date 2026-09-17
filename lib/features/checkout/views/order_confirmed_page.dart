import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/extensions/context_extensions.dart';
import '../../../core/extensions/theme_colors_extension.dart';
import '../../../core/localization/strings/order_strings.dart';
import '../../../core/tokens/extensions.dart';
import '../../../shared/module/buttons/global_filled_button.dart';
import '../../_shared/celebration_confetti.dart';
import '../../_shared/screen_entrance.dart';
import '../../_shared/terracotta_cta_style.dart';
import '../../auth/widgets/success_mark.dart';

/// «تم تأكيد طلبك !» — paid.
///
/// **`BookingConfirmedPage`'s twin, and deliberately identical.** The
/// two flows take money the same way and end the same way; a shop
/// payment used to land straight on «طلباتي», a list that looked no
/// different from the one before the money moved. Nothing told the
/// customer it had worked.
///
/// Renders from nothing but the id it was handed — the order is
/// already the server's, and there is no call here.
class OrderConfirmedPage extends StatelessWidget {
  const OrderConfirmedPage({this.orderId, super.key});

  /// The order just paid for, so the one control can open it. Null
  /// after a hot restart, where the button falls back to the list.
  final String? orderId;

  /// Design: confetti scattered over the whole frame, behind
  /// everything — the same sheet the booking and account-created
  /// frames use.

  /// The SHOP tab, then «طلباتي», then the order itself.
  ///
  /// Three navigations for one intent, and the first is the one that
  /// matters. `go` replaces the stack, so whatever it lands on becomes
  /// the ROOT — and a root of «طلباتي» is a dead end: back does
  /// nothing, and the only way out of the app is to kill it and
  /// reopen. That is exactly what happened after paying.
  ///
  /// A TAB is the only safe root, because back on a tab leaves the app
  /// the way the system expects. The two pushes above it then give
  /// every back press somewhere to go: the order, its list, the shop.
  /// The checkout is gone either way, which is the other half of the
  /// job — pressing back onto it would offer to pay again.
  void _open(BuildContext context) {
    context.goNamed('shop');
    context.pushNamed('my-orders');
    final id = orderId;
    if (id == null || id.isEmpty) return;
    context.pushNamed('order-detail', pathParameters: {'orderId': id});
  }

  @override
  Widget build(BuildContext context) {
    final spacing = context.spacing;
    final text = context.textColors;

    return Scaffold(
      backgroundColor: context.backgroundColors.scaffoldBackground,
      // No app bar: there is nowhere to go back TO — the order exists,
      // and the step behind this one would pay for it again.
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
                          const ScreenEntrance(child: SuccessMark()),
                          SizedBox(height: spacing.lg),
                          ScreenEntrance(
                            step: 1,
                            child: Text(
                              OrderStrings.confirmedTitle,
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
                              OrderStrings.confirmedBody,
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
                      child: GlobalFilledButton(
                        text: OrderStrings.track,
                        onPressed: () => _open(context),
                        // No arrow: this ends the flow rather than
                        // advancing through it.
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
