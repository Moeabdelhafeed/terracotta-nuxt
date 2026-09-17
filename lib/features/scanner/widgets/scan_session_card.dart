import 'package:flutter/material.dart';

import '../../../core/extensions/context_extensions.dart';
import '../../../core/extensions/theme_colors_extension.dart';
import '../../../core/localization/number_formatter.dart';
import '../../../core/localization/strings/booking_strings.dart';
import '../../../core/localization/strings/scan_strings.dart';
import '../../../core/tokens/extensions.dart';
import '../../../data/models/terracotta/scan/scan_session.dart';
import '../../../shared/module/buttons/global_filled_button.dart';
import '../../_shared/terracotta_cta_style.dart';
import '../../_shared/terracotta_widgets.dart';
import '../../booking/widgets/clock_time.dart';

/// One session on the desk's day: who is on it, and the two controls.
class ScanSessionCard extends StatelessWidget {
  const ScanSessionCard({
    required this.session,
    required this.onStart,
    required this.onFinish,
    this.working = false,
    this.canRun = true,
    super.key,
  });

  final ScanSession session;
  final VoidCallback onStart;
  final VoidCallback onFinish;

  /// Something is in flight, so neither control should fire twice.
  final bool working;

  /// Whether Start and Finish apply at all — they are TODAY's only,
  /// and the server refuses any other day with a 422.
  final bool canRun;

  @override
  Widget build(BuildContext context) {
    final spacing = context.spacing;
    final locale = Localizations.localeOf(context).toString();

    // HEADS, not bookings. The API's `checked_in_count` on a session
    // counts ROWS — a party of three arriving as two is one row and
    // two people — so the arrivals line is summed from the bookings
    // themselves, which is the number a desk cares about.
    final arrived = session.bookings.fold<int>(
      0,
      (sum, b) =>
          sum + (b.checkedInAt == null ? 0 : b.checkedInCount ?? b.peopleCount),
    );

    return TerracottaCard(
      padding: EdgeInsets.all(spacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      session.workshopTitle ?? '',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: context.textTheme.titleSmall?.copyWith(
                        color: context.textColors.primary,
                      ),
                    ),
                    SizedBox(height: spacing.xs),
                    Text(
                      // Asia/Riyadh, exactly as sent — the session runs
                      // on the studio's clock.
                      BookingStrings.slotLabel(
                        formatClock(session.startTime ?? '', locale),
                        formatClock(session.endTime ?? '', locale),
                      ),
                      style: context.textTheme.labelMedium?.copyWith(
                        color: context.textColors.secondary,
                      ),
                    ),
                  ],
                ),
              ),
              _Tally(
                arrived: arrived,
                total: session.totalPeople,
                capacity: session.capacity,
              ),
            ],
          ),
          // CHECK-IN IS CLOSED once Finish has run, and the badge is
          // the only thing on screen that says why the scan buttons
          // have gone. Without it a desk reads their absence as the
          // app being broken.
          if (!session.canCheckIn) ...[
            SizedBox(height: spacing.sm),
            _ClosedBadge(at: session.sessionFinishedAt),
          ],
          SizedBox(height: spacing.sm),
          const Divider(height: 1),
          SizedBox(height: spacing.sm),
          for (final booking in session.bookings) ...[
            _BookingRow(booking: booking),
            SizedBox(height: spacing.xs),
          ],
          SizedBox(height: spacing.xs),
          Row(
            children: [
              if (canRun && session.canStart)
                Expanded(
                  child: GlobalFilledButton(
                    text: ScanStrings.startSession,
                    enabled: !working,
                    isLoading: working,
                    onPressed: onStart,
                    style: terracottaCtaStyle(showArrow: false),
                  ),
                ),
              if (canRun && session.canStart && session.canFinish)
                SizedBox(width: spacing.sm),
              if (canRun && session.canFinish)
                Expanded(
                  child: GlobalFilledButton(
                    text: ScanStrings.finishSession,
                    enabled: !working,
                    isLoading: working,
                    onPressed: onFinish,
                    style: terracottaCtaStyle(showArrow: false).copyWith(
                      backgroundColor: context.statusColors.success,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

/// «حضر ٣ من ٥» over «٥ من ٨».
class _Tally extends StatelessWidget {
  const _Tally({
    required this.arrived,
    required this.total,
    required this.capacity,
  });

  final int arrived;
  final int total;
  final int? capacity;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.end,
    mainAxisSize: MainAxisSize.min,
    children: [
      Text(
        ScanStrings.arrived(
          AppNumbers.localizeDigits('$arrived'),
          AppNumbers.localizeDigits('$total'),
        ),
        style: context.textTheme.labelLarge?.copyWith(
          color: arrived >= total && total > 0
              ? context.statusColors.success
              : context.textColors.primary,
          fontWeight: FontWeight.w600,
        ),
      ),
      if (capacity != null)
        Text(
          ScanStrings.seats(
            AppNumbers.localizeDigits('$total'),
            AppNumbers.localizeDigits('${capacity!}'),
          ),
          style: context.textTheme.labelSmall?.copyWith(
            color: context.textColors.secondary,
          ),
        ),
    ],
  );
}

/// «التسجيل مغلق — انتهت في ١١:٣٢».
class _ClosedBadge extends StatelessWidget {
  const _ClosedBadge({required this.at});

  /// When Finish ran. Null on a server that has not grown the field.
  final DateTime? at;

  static String _clock(DateTime at, String locale) {
    final studio = studioTime(at);
    return formatClock(
      '${studio.hour.toString().padLeft(2, '0')}:'
      '${studio.minute.toString().padLeft(2, '0')}',
      locale,
    );
  }

  @override
  Widget build(BuildContext context) {
    final spacing = context.spacing;
    final tint = context.textColors.secondary;
    final locale = Localizations.localeOf(context).toString();
    final when = at;

    return Row(
      children: [
        Icon(Icons.lock_clock, size: context.iconSizes.sm, color: tint),
        SizedBox(width: spacing.xs),
        Expanded(
          child: Text(
            when == null
                ? ScanStrings.sessionClosed
                // THE STUDIO'S CLOCK, not the device's. `DateTime.parse`
                // on an offset-bearing string answers UTC, and a desk
                // reading «٠٨:٣٢» for a session it finished at ١١:٣٢
                // would not believe the screen.
                : '${ScanStrings.sessionClosed} — '
                      '${ScanStrings.sessionClosedAt(_clock(when, locale))}',
            style: context.textTheme.labelMedium?.copyWith(color: tint),
          ),
        ),
      ],
    );
  }
}

/// One customer on the list.
class _BookingRow extends StatelessWidget {
  const _BookingRow({required this.booking});

  final ScanBooking booking;

  @override
  Widget build(BuildContext context) {
    final spacing = context.spacing;
    final here = booking.checkedInAt != null;
    final absent = booking.status == 'absent';

    return Row(
      children: [
        Icon(
          absent
              ? Icons.person_off_outlined
              : here
              ? Icons.check_circle_rounded
              : Icons.circle_outlined,
          size: context.iconSizes.sm,
          color: absent
              ? context.statusColors.warning
              : here
              ? context.statusColors.success
              : context.textColors.secondary,
        ),
        SizedBox(width: spacing.xs),
        Expanded(
          child: Text(
            booking.userName ?? '',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: context.textTheme.bodySmall?.copyWith(
              color: context.textColors.primary,
            ),
          ),
        ),
        if (booking.hasCelebration) ...[
          Icon(
            Icons.celebration_outlined,
            size: context.iconSizes.sm,
            color: context.primaryColors.primary,
          ),
          SizedBox(width: spacing.xs),
        ],
        // HOW MANY PIECES ARE PHOTOGRAPHED, while there is still time
        // to do anything about it. Shown only on somebody who is
        // `attending` and short, because that is the only state a
        // photograph can be added in — before check-in there is
        // nothing to photograph, and after Finish it is too late.
        if (booking.isMissingPieces) ...[
          Icon(
            Icons.photo_camera_back_outlined,
            size: context.iconSizes.sm,
            color: context.statusColors.warning,
          ),
          SizedBox(width: spacing.xs),
          Text(
            ScanStrings.piecesProgress(
              AppNumbers.localizeDigits('${booking.piecesCount}'),
              AppNumbers.localizeDigits('${booking.expectedPieceCount}'),
            ),
            style: context.textTheme.labelSmall?.copyWith(
              color: context.statusColors.warning,
            ),
          ),
          SizedBox(width: spacing.xs),
        ],
        Text(
          // Arrived of booked, per row — «٢ / ٣» is a party of three
          // that came as two, which is the thing a desk needs to see.
          here
              ? '${AppNumbers.localizeDigits('${booking.checkedInCount ?? booking.peopleCount}')}'
                    ' / '
                    '${AppNumbers.localizeDigits('${booking.peopleCount}')}'
              : AppNumbers.localizeDigits('${booking.peopleCount}'),
          style: context.textTheme.labelMedium?.copyWith(
            color: context.textColors.secondary,
          ),
        ),
      ],
    );
  }
}
