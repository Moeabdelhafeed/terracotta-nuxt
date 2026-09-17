import 'package:flutter/material.dart';

import '../../../core/extensions/context_extensions.dart';
import '../../../core/extensions/theme_colors_extension.dart';
import '../../../core/localization/number_formatter.dart';
import '../../../core/localization/strings/common_strings.dart';
import '../../../core/localization/strings/scan_strings.dart';
import '../../../core/tokens/extensions.dart';
import '../../../data/models/terracotta/scan/scan_session.dart';
import '../../../shared/module/buttons/global_filled_button.dart';
import '../../../shared/module/buttons/global_outlined_button.dart';
import '../../_shared/terracotta_cta_style.dart';
import '../../booking/widgets/sheet_shell.dart';

/// The last thing the desk sees before a session is closed.
///
/// ## Why this is a sheet and not a confirmation line
///
/// Finish is IRREVERSIBLE for photographs. A piece can only be
/// uploaded while its booking is `attending`; the moment Finish runs
/// the booking moves to `preparing` and **no piece can ever be added
/// to it again**. So the one question worth asking here is not "are
/// you sure" — it is *who is still short*, by name, with their count.
///
/// "3 bookings" does not tell a desk who to go and look for. «ليلى — ٠
/// من ٢» does. The CMS lists exactly this in exactly this spot, and
/// the two have to agree because the studio uses both.
///
/// ## The counts are re-read first
///
/// [missing] must come from a session the caller has just re-fetched,
/// not from whatever was on screen when the desk opened the day. There
/// is no push and no socket on this endpoint — the numbers move
/// because a customer uploaded a photograph on their own phone thirty
/// seconds ago, and a stale list here sends the desk after somebody
/// who has already finished.
class FinishSessionSheet extends StatelessWidget {
  const FinishSessionSheet({required this.missing, super.key});

  /// Everyone still short of their pieces. Empty is the good case and
  /// still shows — the desk asked a question and deserves the answer.
  final List<ScanBooking> missing;

  @override
  Widget build(BuildContext context) {
    final spacing = context.spacing;
    final clear = missing.isEmpty;

    return SheetShell(
      title: clear
          ? ScanStrings.finishWarningTitle
          : ScanStrings.finishMissingTitle,
      heightFactor: null,
      maxHeightFactor: 0.8,
      footer: Row(
        children: [
          Expanded(
            child: GlobalOutlinedButton(
              text: CommonStrings.cancel,
              onPressed: () => Navigator.of(context).pop(false),
            ),
          ),
          SizedBox(width: spacing.sm),
          Expanded(
            child: GlobalFilledButton(
              // THE WORDS CHANGE WITH THE ANSWER. Pressing «أنهِ
              // الجلسة» over a list of people who have not finished
              // reads as though the list were advice; «أنهِ على أي
              // حال» says what the press actually costs.
              text: clear
                  ? ScanStrings.finishSession
                  : ScanStrings.finishAnyway,
              onPressed: () => Navigator.of(context).pop(true),
              style: terracottaCtaStyle(showArrow: false).copyWith(
                backgroundColor: clear
                    ? context.statusColors.success
                    : context.statusColors.warning,
              ),
            ),
          ),
        ],
      ),
      children: [
        Text(
          clear ? ScanStrings.finishAllDone : ScanStrings.finishMissingBody,
          style: context.textTheme.bodyMedium?.copyWith(
            color: context.textColors.secondary,
          ),
        ),
        if (!clear) ...[
          SizedBox(height: spacing.md),
          for (final booking in missing) ...[
            _MissingRow(booking: booking),
            SizedBox(height: spacing.xs),
          ],
        ],
        SizedBox(height: spacing.sm),
        Text(
          ScanStrings.finishWarningBody,
          style: context.textTheme.labelMedium?.copyWith(
            color: context.textColors.secondary,
          ),
        ),
        SizedBox(height: spacing.md),
      ],
    );
  }
}

/// One person the desk has to go and find.
class _MissingRow extends StatelessWidget {
  const _MissingRow({required this.booking});

  final ScanBooking booking;

  @override
  Widget build(BuildContext context) {
    final spacing = context.spacing;
    final warning = context.statusColors.warning;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: warning.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(context.radii.sm),
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: spacing.sm,
          vertical: spacing.xs,
        ),
        child: Row(
          children: [
            Icon(
              Icons.photo_camera_back_outlined,
              size: context.iconSizes.sm,
              color: warning,
            ),
            SizedBox(width: spacing.xs),
            Expanded(
              child: Text(
                ScanStrings.missingRow(
                  booking.userName ?? '',
                  AppNumbers.localizeDigits('${booking.piecesCount}'),
                  AppNumbers.localizeDigits('${booking.expectedPieceCount}'),
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: context.textTheme.bodySmall?.copyWith(
                  color: context.textColors.primary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Asks the desk to confirm Finish, showing who is still short.
///
/// Answers true when they went ahead.
Future<bool> showFinishSessionSheet(
  BuildContext context, {
  required List<ScanBooking> missing,
}) async =>
    await showTerracottaSheet<bool>(
      context,
      builder: (_) => FinishSessionSheet(missing: missing),
    ) ??
    false;
