import 'package:flutter/material.dart';

import '../../../core/extensions/context_extensions.dart';
import '../../../core/extensions/theme_colors_extension.dart';
import '../../../core/localization/strings/booking_strings.dart';
import '../../_shared/terracotta_cta_style.dart';
import 'confetti_strip.dart';

/// «اضافة احتفال» / «ازالة الاحتفال» — the celebration bar.
///
/// The same bar twice: pinned at the foot to ADD one, and sitting over
/// the booking card to take it off again. One widget, so the two cannot
/// drift into looking like different controls for one decision.
///
/// The confetti runs down BOTH ends, mirrored, and is drawn behind the
/// words rather than beside them — the bar is full-width and its label
/// is centred, so anything packed into the row would push the label off
/// centre.
class CelebrationBar extends StatelessWidget {
  const CelebrationBar({
    required this.added,
    this.onTap,
    this.tucked = false,
    super.key,
  });

  /// How much of the bar's foot sits under the card that overlaps it.
  static const tuckedFoot = 20.0;

  /// A TUCKED bar is taller by exactly what the card hides, so what
  /// SHOWS of it is a full-height button — the same size as the add bar
  /// at the foot, which is what makes the two read as one control.
  static const tuckedHeight = kTerracottaCtaHeight + tuckedFoot;

  /// Whether the booking already has a celebration on it. Decides the
  /// words, not the look: it is the same bar either way.
  final bool added;

  final VoidCallback? onTap;

  /// Whether a card overlaps this bar's foot. Only the one over the
  /// booking card does; the pinned one at the foot of the page is a
  /// plain button and must not carry the offset.
  final bool tucked;

  @override
  Widget build(BuildContext context) {
    final ink = context.textColors.onPrimary;

    return ClipRRect(
      borderRadius: BorderRadius.circular(kTerracottaCtaRadius),
      child: Material(
        color: context.primaryColors.accent,
        child: InkWell(
          onTap: onTap,
          child: SizedBox(
            height: tucked ? tuckedHeight : kTerracottaCtaHeight,
            child: Stack(
              children: [
                for (final edge in const [
                  AlignmentDirectional.centerStart,
                  AlignmentDirectional.centerEnd,
                ])
                  ConfettiStrip(edge: edge),
                // The label CENTRED in the whole bar. No glyph beside
                // it: the words already say what the bar does, and the
                // cake was competing with the confetti for the same
                // job.
                // The label is centred in what SHOWS, not in the box:
                // a tucked bar's foot is under the card, so centring in
                // the whole thing pushes the words low.
                Padding(
                  padding: EdgeInsetsDirectional.only(
                    bottom: tucked ? tuckedFoot : 0,
                  ),
                  child: Center(
                    child: Text(
                      added
                          ? BookingStrings.removeCelebration
                          : BookingStrings.addCelebration,
                      style: context.textTheme.titleMedium?.copyWith(
                        color: ink,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
