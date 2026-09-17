import 'package:flutter/material.dart';

import '../../../core/extensions/context_extensions.dart';
import '../../../core/extensions/theme_colors_extension.dart';
import '../../../core/localization/strings/delivery_strings.dart';
import '../../../core/tokens/extensions.dart';
import '../../../shared/module/buttons/global_filled_button.dart';
import '../../booking/widgets/sheet_shell.dart';

/// «تحذير» — the studio will not hold the piece forever.
///
/// No call: read `pickup_deadline` and `is_pickup_overdue` off the
/// booking.
///
/// **This sheet uses the ERROR ramp, not the amber warning pair.** The
/// design draws it that way and it is right: an overdue pickup means
/// losing the piece, which is error-severity, not caution. The amber
/// pair in the palette belongs to the reschedule button, which is a
/// neutral secondary action.
class PieceHoldWarningSheet extends StatelessWidget {
  const PieceHoldWarningSheet({this.hoursLeft = 0, super.key});

  final int hoursLeft;

  @override
  Widget build(BuildContext context) {
    final spacing = context.spacing;
    final error = context.statusColors.error;

    return SheetShell(
      // SIZED TO ITSELF. A mark, two lines and a button — half a screen
      // left a field of empty under them.
      heightFactor: null,
      // The close button rides the panel's foot like every other sheet.
      footer: GlobalFilledButton(
        text: DeliveryStrings.close,
        style: ButtonStateStyle(
          backgroundColor: error.withValues(alpha: 0.16),
          foregroundColor: error,
        ),
        onPressed: () => Navigator.of(context).pop(),
      ),
      children: [
        Center(
          child: DecoratedBox(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: error.withValues(alpha: 0.14),
            ),
            child: Padding(
              padding: EdgeInsets.all(spacing.lg),
              child: Icon(Icons.error_rounded, size: 44, color: error),
            ),
          ),
        ),
        SizedBox(height: spacing.lg),
        Text(
          DeliveryStrings.warningTitle,
          textAlign: TextAlign.center,
          style: context.textTheme.titleLarge?.copyWith(
            color: context.textColors.primary,
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: spacing.sm),
        Text(
          DeliveryStrings.warningBody(hoursLeft),
          textAlign: TextAlign.center,
          style: context.textTheme.bodyMedium?.copyWith(
            color: context.textColors.primary,
          ),
        ),
      ],
    );
  }
}

/// Opens [PieceHoldWarningSheet] over the booking.
Future<void> showPieceHoldWarning(BuildContext context, {int hoursLeft = 0}) =>
    showTerracottaSheet<void>(
      context,
      builder: (_) => PieceHoldWarningSheet(hoursLeft: hoursLeft),
    );
