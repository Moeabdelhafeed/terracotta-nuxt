import 'package:flutter/material.dart';

import '../../../core/extensions/context_extensions.dart';
import '../../../core/extensions/theme_colors_extension.dart';
import '../../../core/localization/strings/delivery_strings.dart';
import '../../../core/tokens/extensions.dart';
import '../../../data/models/terracotta/booking/paintable_workshop.dart';
import '../../_shared/terracotta_image.dart';
import 'sheet_shell.dart';

/// Which paint workshop the customer wants to bring their piece to.
///
/// Only shown when the server names MORE THAN ONE. `paintable_at` is
/// the studio's own answer to "where can a piece made here be
/// painted", and it is a list because a studio may run several — a
/// weekday session and a weekend one, say. One of them goes straight
/// through without asking.
class PaintableWorkshopSheet extends StatelessWidget {
  const PaintableWorkshopSheet({required this.options, super.key});

  final List<PaintableWorkshop> options;

  @override
  Widget build(BuildContext context) {
    final spacing = context.spacing;

    return SheetShell(
      title: DeliveryStrings.paintPickTitle,
      heightFactor: null,
      maxHeightFactor: 0.7,
      children: [
        for (final option in options) ...[
          _Option(
            option: option,
            onTap: () => Navigator.of(context).pop(option),
          ),
          SizedBox(height: spacing.sm),
        ],
        SizedBox(height: spacing.md),
      ],
    );
  }
}

class _Option extends StatelessWidget {
  const _Option({required this.option, required this.onTap});

  final PaintableWorkshop option;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final spacing = context.spacing;
    final radius = BorderRadius.circular(context.radii.md);

    return Material(
      color: context.backgroundColors.container,
      borderRadius: radius,
      child: InkWell(
        onTap: onTap,
        borderRadius: radius,
        child: Padding(
          padding: EdgeInsets.all(spacing.sm),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(context.radii.sm),
                child: SizedBox.square(
                  dimension: 56,
                  child: TerracottaImage(image: option.image),
                ),
              ),
              SizedBox(width: spacing.sm),
              Expanded(
                child: Text(
                  option.title ?? '',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: context.textTheme.titleSmall?.copyWith(
                    color: context.textColors.primary,
                  ),
                ),
              ),
              Icon(
                Icons.arrow_forward_rounded,
                size: context.iconSizes.sm,
                color: context.textColors.secondary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Asks which paint workshop. Answers null when they backed out.
Future<PaintableWorkshop?> showPaintableWorkshopSheet(
  BuildContext context, {
  required List<PaintableWorkshop> options,
}) => showTerracottaSheet<PaintableWorkshop>(
  context,
  builder: (_) => PaintableWorkshopSheet(options: options),
);
