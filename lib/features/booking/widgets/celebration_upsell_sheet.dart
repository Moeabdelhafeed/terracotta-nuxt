import 'package:flutter/material.dart';

import '../../../core/extensions/context_extensions.dart';
import '../../../core/extensions/theme_colors_extension.dart';
import '../../../core/localization/strings/booking_strings.dart';
import '../../../core/localization/strings/common_strings.dart';
import '../../../core/localization/strings/home_strings.dart';
import '../../../core/tokens/extensions.dart';
import '../../../shared/module/buttons/global_filled_button.dart';
import '../../../shared/module/buttons/global_text_button.dart';
import '../../../shared/module/sheet/global_sheet.dart';
import '../../_shared/terracotta_cta_style.dart';
import '../../_shared/terracotta_widgets.dart';
import 'confetti_strip.dart';

/// «احتفل مع تيراكوتا» — the celebration add-on.
///
/// A CORAL sheet with the confetti behind it, as the design draws it.
/// The chrome — the grab handle, the rounded top, the safe-area inset —
/// belongs to `GlobalBottomSheet`; drawing another handle here would
/// put two on the same sheet.
///
/// The price is per person and is applied SERVER-SIDE: toggling this
/// must re-call `GET /api/workshops/{id}/price` and show what comes
/// back. Never add the celebration price locally — the server applies
/// celebration, wallet and discount in a fixed order and a local sum
/// will disagree with the charge.
class CelebrationUpsellSheet extends StatelessWidget {
  const CelebrationUpsellSheet({
    this.price = '',
    this.added = false,
    super.key,
  });

  /// Decimal string from the quote.
  final String price;

  final bool added;

  @override
  Widget build(BuildContext context) {
    final spacing = context.spacing;
    final ink = context.textColors.onPrimary;

    return Stack(
      children: [
        // ONE STRIP DOWN EACH SIDE, not a wash over the whole sheet.
        // The words sit in the middle and confetti behind them is
        // noise; at the edges it frames them.
        for (final edge in const [
          AlignmentDirectional.centerStart,
          AlignmentDirectional.centerEnd,
        ])
          ConfettiStrip(edge: edge, widthFactor: 0.3, overhang: 0.5),
        Padding(
          padding: EdgeInsets.symmetric(
            horizontal: spacing.md,
            vertical: spacing.lg,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                BookingStrings.celebrationTitle,
                textAlign: TextAlign.center,
                style: context.textTheme.headlineSmall?.copyWith(
                  color: ink,
                  fontWeight: FontWeight.w700,
                ),
              ),
              SizedBox(height: spacing.lg),
              Text(
                BookingStrings.celebrationBody,
                textAlign: TextAlign.center,
                style: context.textTheme.bodyMedium?.copyWith(
                  color: ink,
                  height: 1.8,
                ),
              ),
              SizedBox(height: spacing.xl),
              GlobalTextButton(
                text: CommonStrings.close,
                // FALSE, explicitly. Closing is a decision not to, and
                // the caller has to be able to tell it apart from the
                // button below.
                onPressed: () => Navigator.of(context).pop(false),
                style: ButtonStateStyle(textStyle: TextStyle(color: ink)),
              ),
              SizedBox(height: spacing.sm),
              GlobalFilledButton(
                // The PRICE is on the button, as the design draws it —
                // the decision and its cost in one place.
                text: added
                    ? BookingStrings.removeCelebration
                    // «اضافة ٣٠٠ ريال» — the wire sends `"300.00"`,
                    // which is a value, not a price. `PriceText.format`
                    // is the same string surgery the rest of the app
                    // prints money with: localized digits, trailing
                    // zeros gone, never parsed to a number.
                    : BookingStrings.celebrationAddPrice(
                        '${PriceText.format(price)} ${HomeStrings.currency}',
                      ),
                onPressed: () => Navigator.of(context).pop(true),
                style: terracottaCtaStyle(showArrow: false).copyWith(
                  // A lighter coral on the coral, which is what the
                  // design uses rather than the brand brown — a brown
                  // bar here would belong to a different screen.
                  backgroundColor: ink.withValues(alpha: 0.25),
                  textStyle: TextStyle(
                    color: ink,
                    fontSize: kTerracottaCtaLabelSize,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Opens [CelebrationUpsellSheet] and answers whether the customer
/// said YES.
///
/// Returns false for every other way out — the close button, the
/// barrier, a drag, the back gesture. It used to return nothing, and
/// the checkout toggled the celebration on whatever came back: tapping
/// outside the sheet to dismiss it ADDED the celebration, and so did
/// pressing «اغلاق».
///
/// Through `GlobalBottomSheet`, which draws the handle and the rounded
/// top itself — the sheet body only draws what is inside it.
Future<bool> showCelebrationSheet(
  BuildContext context, {
  String price = '',
  bool added = false,
}) async {
  final said = await GlobalBottomSheet.show<bool>(
    context: context,
    // No title row: the sheet's own heading is part of the artwork,
    // and the module's would sit above the confetti in the wrong
    // colour.
    showCloseButton: false,
    style: SheetStyle(
      backgroundColor: context.primaryColors.accent,
      handleColor: context.textColors.onPrimary.withValues(alpha: 0.6),
    ),
    content: CelebrationUpsellSheet(price: price, added: added),
  );
  // Null is every dismissal there is: the barrier, a drag, the system
  // back gesture.
  return said ?? false;
}
