import 'package:flutter/material.dart';

import '../../../core/constants/colors/workshop_family_colors.dart';
import '../../../core/extensions/context_extensions.dart';
import '../../../core/extensions/theme_colors_extension.dart';
import '../../../core/localization/strings/booking_strings.dart';
import '../../../core/tokens/extensions.dart';
import '../../_shared/terracotta_widgets.dart';

/// The booking card that heads every detail and status screen.
///
/// Title, price, and the fact chips — party size, date, time, and the
/// celebration chip when one is attached. The celebration chip is the
/// coral pair and is INFORMATIONAL, not a warning: it must never be
/// styled from the error ramp even though it is in the red family.
class BookingSummaryCard extends StatelessWidget {
  const BookingSummaryCard({
    this.title = '',
    this.price = '',
    this.people = '',
    this.date = '',
    this.time = '',
    this.hasCelebration = false,
    this.family = WorkshopFamily.makeYourPiece,
    this.wireColor,
    super.key,
  });

  final String title;

  /// Decimal string, printed as received.
  final String price;

  final String people;
  final String date;
  final String time;
  final bool hasCelebration;
  final WorkshopFamily family;
  final String? wireColor;

  @override
  Widget build(BuildContext context) {
    final spacing = context.spacing;
    final fam = WorkshopFamilyColors.resolve(
      family: family,
      isDark: context.isDarkMode,
      wireColor: wireColor,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          title,
          style: context.textTheme.titleLarge?.copyWith(
            color: context.textColors.primary,
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: spacing.md),
        Wrap(
          spacing: spacing.sm,
          runSpacing: spacing.sm,
          children: [
            _Fact(label: price, icon: Icons.sell_rounded, tint: fam.primary),
            _Fact(
              label: people,
              icon: Icons.people_rounded,
              tint: fam.primary,
            ),
            _Fact(
              label: date,
              icon: Icons.event_rounded,
              tint: fam.primary,
            ),
            _Fact(
              label: time,
              icon: Icons.schedule_rounded,
              tint: fam.primary,
            ),
            if (hasCelebration)
              _Fact(
                label: BookingStrings.withCelebration,
                icon: Icons.cake_rounded,
                // The celebration ramp, NOT the error ramp — same
                // family, opposite meaning.
                tint: context.primaryColors.accent,
                labelColor: const Color(0xFFF57373),
              ),
          ],
        ),
      ],
    );
  }
}

class _Fact extends StatelessWidget {
  const _Fact({
    required this.label,
    required this.icon,
    required this.tint,
    this.labelColor,
  });

  final String label;
  final IconData icon;
  final Color tint;
  final Color? labelColor;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: tint.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(context.radii.lg),
    ),
    child: Padding(
      padding: EdgeInsetsDirectional.symmetric(
        horizontal: context.spacing.sm,
        vertical: context.spacing.xs,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: context.iconSizes.xs, color: tint),
          SizedBox(width: context.spacing.xs),
          Text(
            label,
            style: context.textTheme.bodySmall?.copyWith(
              color: labelColor ?? context.textColors.primary,
            ),
          ),
        ],
      ),
    ),
  );
}

/// A booking row in the my-bookings list.
class BookingListTile extends StatelessWidget {
  const BookingListTile({
    this.title = '',
    this.meta = '',
    this.statusLabel,
    this.statusColor,
    this.onTap,
    super.key,
  });

  final String title;
  final String meta;
  final String? statusLabel;
  final Color? statusColor;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => TerracottaCard(
    onTap: onTap,
    child: Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: context.textTheme.titleMedium?.copyWith(
                  color: context.textColors.primary,
                ),
              ),
              SizedBox(height: context.spacing.xs),
              Text(
                meta,
                style: context.textTheme.labelSmall?.copyWith(
                  color: context.textColors.primary,
                ),
              ),
            ],
          ),
        ),
        if (statusLabel != null)
          StatusChip(label: statusLabel!, color: statusColor),
      ],
    ),
  );
}
