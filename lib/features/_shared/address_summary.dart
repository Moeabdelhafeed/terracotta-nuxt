import 'package:flutter/material.dart';

import '../../core/extensions/context_extensions.dart';
import '../../core/extensions/theme_colors_extension.dart';
import '../../core/tokens/extensions.dart';

/// A place, drawn the way «عناويني» draws one.
///
/// The address book had this shape and the order detail did not: an
/// order's delivery section was four stacked label-over-value rows,
/// so the same address read as a form on one screen and as a place on
/// the other. This is the place version, and both use it.
///
/// ## What it does NOT take
///
/// An [Address]. The order carries a delivery address the SERVER
/// composed — `"8228, Prince Turki Road, Unit 12, Al Muhammadiyah,
/// Riyadh, 12362, 2933"` — and no structured fields behind it. Taking
/// the pieces rather than the model is what lets the order screen use
/// it without parsing that line back apart, which would guess at a
/// format the server is free to change.
class AddressSummary extends StatelessWidget {
  const AddressSummary({
    required this.line,
    this.title,
    this.facts = const [],
    this.phone,
    this.notes,
    this.isHome = false,
    this.trailing,
    super.key,
  });

  /// The name the customer gave it, or the city when they gave none.
  ///
  /// NULL when there is no name to give — an order carries a composed
  /// line and, sometimes, nothing else. The line then leads in the
  /// title's own weight rather than a heading being invented for it:
  /// repeating «التوصيل» inside the «التوصيل» card says nothing twice.
  final String? title;

  /// The street and district — what a person actually reads to
  /// recognise where this is.
  final String line;

  /// «مبنى ٤٣٥٩», «الرياض». Drawn as chips under the line.
  final List<AddressFact> facts;

  /// E.164, and drawn LTR whatever the locale: a number is dialled,
  /// not read as prose.
  final String? phone;

  /// «الباب الأزرق» — what the customer told the courier.
  final String? notes;

  /// A house glyph rather than a pin, for the default address.
  final bool isHome;

  /// «الافتراضي», or nothing.
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final spacing = context.spacing;
    final tint = context.primaryColors.primary;
    final named = (title ?? '').isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // A pin, so a place reads as a place rather than as a
            // paragraph.
            DecoratedBox(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: tint.withValues(alpha: 0.12),
              ),
              child: Padding(
                padding: EdgeInsets.all(spacing.xs),
                child: Icon(
                  isHome ? Icons.home_rounded : Icons.location_on_rounded,
                  size: context.iconSizes.sm,
                  color: tint,
                ),
              ),
            ),
            SizedBox(width: spacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (named) ...[
                    Text(
                      title!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: context.textTheme.titleSmall?.copyWith(
                        color: context.textColors.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (line.isNotEmpty) const SizedBox(height: 2),
                  ],
                  if (line.isNotEmpty)
                    Text(
                      line,
                      // THREE, not two: an order's line is the whole
                      // composed address rather than a street and a
                      // district, and two clipped it mid-word.
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: named
                          ? context.textTheme.bodySmall?.copyWith(
                              color: context.textColors.secondary,
                            )
                          : context.textTheme.titleSmall?.copyWith(
                              color: context.textColors.primary,
                              fontWeight: FontWeight.w700,
                            ),
                    ),
                ],
              ),
            ),
            if (trailing != null) trailing!,
          ],
        ),
        if (facts.isNotEmpty) ...[
          SizedBox(height: spacing.sm),
          // The numbers, each SAYING what it is.
          Wrap(
            spacing: spacing.xs,
            runSpacing: spacing.xs,
            children: [for (final fact in facts) AddressFactChip(fact)],
          ),
        ],
        if (phone case final number? when number.isNotEmpty) ...[
          SizedBox(height: spacing.xs),
          Text(
            number,
            textDirection: TextDirection.ltr,
            textAlign: TextAlign.start,
            style: context.textTheme.labelSmall?.copyWith(
              color: context.textColors.secondary,
            ),
          ),
        ],
        if (notes case final note? when note.trim().isNotEmpty) ...[
          const SizedBox(height: 2),
          Text(
            note,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: context.textTheme.labelSmall?.copyWith(
              color: context.textColors.secondary,
            ),
          ),
        ],
      ],
    );
  }
}

/// One labelled fact about a place — «مبنى ٤٣٥٩», «الرياض».
@immutable
class AddressFact {
  const AddressFact(this.text, {this.icon});

  final String text;
  final IconData? icon;
}

/// [AddressFact], drawn.
class AddressFactChip extends StatelessWidget {
  const AddressFactChip(this.fact, {super.key});

  final AddressFact fact;

  @override
  Widget build(BuildContext context) {
    final ink = context.textColors.secondary;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: context.backgroundColors.container,
        borderRadius: BorderRadius.circular(context.radii.xs),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (fact.icon case final icon?) ...[
              Icon(icon, size: context.iconSizes.xs, color: ink),
              const SizedBox(width: 4),
            ],
            Text(
              fact.text,
              style: context.textTheme.labelSmall?.copyWith(color: ink),
            ),
          ],
        ),
      ),
    );
  }
}
