import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/extensions/context_extensions.dart';
import '../../../core/extensions/theme_colors_extension.dart';
import '../../../core/localization/strings/booking_strings.dart';
import '../../../core/tokens/extensions.dart';
import '../../../shared/module/buttons/global_filled_button.dart';
import '../../_shared/celebration_confetti.dart';
import '../../_shared/screen_entrance.dart';
import '../../_shared/terracotta_cta_style.dart';
import '../../auth/widgets/success_mark.dart';
import '../../workshops/workshops_tab.dart';
import '../widgets/clock_time.dart';

/// «تم تاكيد حجز الورشة !» — booked.
///
/// Renders entirely from the response of
/// `POST /api/workshops/{id}/bookings`; there is no extra call.
///
/// **The account-created frame's twin.** The design draws the two
/// celebrations the same way — confetti edge to edge, the tick above
/// the words, and the single control parked at the bottom of the
/// SCREEN rather than after the content — so this screen is built the
/// same way rather than as a centred column that happens to look
/// similar. See `RegisterSuccessPage`.
///
/// The body copy is the real thing here — the customer genuinely can
/// cancel or reschedule within three hours of confirming. (The same
/// sentence appears on the account-created frame, where it is a
/// copy-paste slip that was queried and kept.)
class BookingConfirmedPage extends StatelessWidget {
  const BookingConfirmedPage({this.bookingId, this.editableUntil, super.key});

  /// Which booking «تتبع الحجز» opens. Null falls back to «ورشاتي»,
  /// which is where the button used to land always.
  final int? bookingId;

  /// When the customer loses the right to cancel or reschedule, from
  /// the created booking's own `editable_until`.
  ///
  /// NULL means there is no window — a booking made inside the
  /// workshop's `cancellation_window_hours` has no cancellation right,
  /// and the page says so rather than promising one.
  final DateTime? editableUntil;

  /// Design: confetti scattered over the whole frame, behind
  /// everything — the same sheet the account-created frame uses.

  @override
  Widget build(BuildContext context) {
    final spacing = context.spacing;
    final text = context.textColors;
    final locale = Localizations.localeOf(context).toString();
    final until = editableUntil;

    return Scaffold(
      backgroundColor: context.backgroundColors.scaffoldBackground,
      // No app bar: there is nowhere to go back TO — the booking
      // exists, and the step behind this one would pay for it again.
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
                              BookingStrings.confirmedTitle,
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
                              until == null
                                  ? BookingStrings.confirmedBodyFinal
                                  : BookingStrings.confirmedBody(
                                      formatDeadline(until, locale),
                                    ),
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
                        text: BookingStrings.track,
                        // «ورشاتي», not the booking's own page: the
                        // customer has one more booking than they had a
                        // moment ago, and the list is where it lives
                        // alongside the rest. `go`, not `push` — the
                        // checkout behind this must not be reachable by
                        // going back.
                        // «تتبع الحجز» — THE BOOKING, not the list it
                        // is in. Tracking one booking and being handed
                        // a list to find it in is a step the reader did
                        // not ask for.
                        //
                        // «ورشاتي» is still put underneath it, so back
                        // lands on the list rather than on the checkout
                        // — which would offer to pay again. The tab is
                        // ASKED for rather than passed as a parameter:
                        // this flow started on `/workshops`, so `go`
                        // pops back to the route already on the stack
                        // instead of building one, and the surviving
                        // `State` keeps the tab it had.
                        onPressed: () {
                          WorkshopsTab.request(WorkshopsTab.mine);
                          context.goNamed(
                            'workshops',
                            queryParameters: {'tab': WorkshopsTab.mine.name},
                          );
                          final id = bookingId;
                          if (id == null) return;
                          context.pushNamed(
                            'booking-detail',
                            pathParameters: {'bookingId': '$id'},
                          );
                        },
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
