import 'package:flutter/material.dart';

import '../../../core/extensions/context_extensions.dart';
import '../../../core/extensions/theme_colors_extension.dart';
import '../../../core/localization/strings/booking_strings.dart';
import '../../../core/tokens/extensions.dart';
import '../../../shared/module/buttons/global_filled_button.dart';
import '../../../shared/module/image/global_image.dart';

/// «الغاء الحجز» — are you sure.
///
/// A DIALOG, not a route: it sits over the booking it is about.
///
/// `DELETE /api/workshops/bookings/{booking}` — a cancel refunds to the
/// wallet rather than to the card, which is why the confirm copy does
/// not promise a card refund.
///
/// **Note the inversion in the design**: the CONFIRM ("نعم") is the
/// soft red button and the DISMISS ("لا") is the solid one. That is
/// deliberate — the loud button is the safe choice — and it is
/// reproduced rather than "corrected".
///
/// The dismiss also comes FIRST in the row, so in Arabic it lands on
/// the right where the design draws it. The pair mirrors together in
/// English, which keeps the safe choice under the same thumb.
class CancelBookingDialog extends StatelessWidget {
  const CancelBookingDialog({this.onConfirm, super.key});

  final VoidCallback? onConfirm;

  /// Shared with `BookingStage.cancelled`.
  static const _art = 'assets/images/workshop-illustration-8.png';

  @override
  Widget build(BuildContext context) {
    final spacing = context.spacing;
    final error = context.statusColors.error;

    return Dialog(
      backgroundColor: context.backgroundColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(context.radii.lg),
      ),
      // VERTICAL padding only — the drawing runs to the dialog's own
      // edges. Its line is a horizon, and a horizon with a margin
      // either side is a picture of one.
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: spacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // The calendar with a red cross — the same drawing «ملغاة»
            // heads its page with, so the dialog and the state it leads
            // to are visibly the same thing. It is why this dialog is
            // not `GlobalDialog.confirm`: the house one has no room for
            // a picture, and the picture is what makes the question
            // land before the words are read.
            SizedBox(
              height: 96,
              child: GlobalImage.a(
                _art,
                placeholder: const SizedBox.shrink(),
                style: const ImageStyle(
                  fit: BoxFit.contain,
                  borderRadius: BorderRadius.zero,
                ),
              ),
            ),
            SizedBox(height: spacing.sm),
            _Gutter(
              child: Text(
                BookingStrings.cancelTitle,
                textAlign: TextAlign.center,
                style: context.textTheme.titleLarge?.copyWith(
                  color: context.textColors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            SizedBox(height: spacing.sm),
            _Gutter(
              child: Text(
                BookingStrings.cancelConfirm,
                textAlign: TextAlign.center,
                style: context.textTheme.bodyMedium?.copyWith(
                  color: context.textColors.primary,
                ),
              ),
            ),
            SizedBox(height: spacing.lg),
            _Gutter(
              child: Row(
                children: [
                  // DISMISS leads — so in Arabic the solid button lands
                  // on the right, where the design puts it. The loud
                  // one is the SAFE choice; see the class doc.
                  Expanded(
                    child: GlobalFilledButton(
                      text: BookingStrings.no,
                      style: ButtonStateStyle(backgroundColor: error),
                      onPressed: () => Navigator.of(context).pop(false),
                    ),
                  ),
                  SizedBox(width: spacing.sm),
                  // Confirm — the SOFT button, per the design.
                  Expanded(
                    child: GlobalFilledButton(
                      text: BookingStrings.yes,
                      style: ButtonStateStyle(
                        backgroundColor: error.withValues(alpha: 0.16),
                        foregroundColor: error,
                      ),
                      onPressed: () {
                        Navigator.of(context).pop(true);
                        onConfirm?.call();
                      },
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Opens [CancelBookingDialog] over the booking.
Future<bool?> showCancelBookingDialog(BuildContext context) => showDialog<bool>(
  context: context,
  builder: (_) => const CancelBookingDialog(),
);

/// The dialog's side margin, applied per block — the illustration is
/// the one thing that does without it.
class _Gutter extends StatelessWidget {
  const _Gutter({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.symmetric(horizontal: context.spacing.lg),
    child: child,
  );
}
