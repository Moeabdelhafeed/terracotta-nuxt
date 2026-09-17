import 'package:flutter/material.dart';

import '../../../core/extensions/context_extensions.dart';
import '../../../core/extensions/theme_colors_extension.dart';
import '../../../core/localization/strings/booking_strings.dart';
import '../../../core/localization/strings/common_strings.dart';
import '../../../core/tokens/extensions.dart';
import '../../../data/models/terracotta/core/api_image.dart';
import '../../../data/models/terracotta/workshop/workshop_product.dart';
import '../../_shared/terracotta_image.dart';
import '../../_shared/terracotta_widgets.dart';

/// One product on the catalogue screen — and the same card again inside
/// «القطع المختارة», because it is the same thing being counted and a
/// second design for it would be a second thing to keep in step.
///
/// The design puts everything that CHANGES on the end side: the count
/// badge at the top of it, the stepper at the foot. The photograph and
/// the words stay put, so a card that gains a piece does not reflow.
class PieceCard extends StatelessWidget {
  const PieceCard({
    required this.title,
    required this.price,
    required this.quantity,
    required this.canAdd,
    required this.tint,
    required this.onAdd,
    required this.onRemove,
    this.subtitle,
    this.image,
    this.editable = true,
    this.oneOnly = false,
    super.key,
  });

  /// The card for a catalogue product.
  ///
  /// A nameless row is a real row with a real price — the CMS lets one
  /// be saved with no name in this language. See `WorkshopProduct.title`.
  PieceCard.product({
    required WorkshopProduct product,
    required this.quantity,
    required this.canAdd,
    required this.tint,
    required this.onAdd,
    required this.onRemove,
    this.editable = true,
    super.key,
  }) : title = product.title ?? BookingStrings.pieceUntitled,
       subtitle = product.subtitle,
       price = product.price,
       image = product.primaryImage,
       oneOnly = false;

  final String title;

  /// The line under the name — a product's own, or when a customer's
  /// piece was made.
  final String? subtitle;

  /// A decimal STRING.
  final String price;

  final ApiImage? image;

  final int quantity;

  /// Whether the booking has room for one more — the ceiling is on the
  /// BOOKING, so every card stops offering at once.
  final bool canAdd;

  final Color tint;
  final VoidCallback onAdd;
  final VoidCallback onRemove;

  /// Whether the stepper is a TOGGLE.
  ///
  /// True for one of the customer's own pieces: it is a specific
  /// object, so the only answers are one and none — the `+` goes once
  /// and then stops offering.
  final bool oneOnly;

  /// Whether the keys are drawn at all.
  ///
  /// False on the checkout's settled sheet: the basket is decided by
  /// then and the price is the server's, so a stepper there would edit
  /// a total the customer is being asked to pay.
  final bool editable;

  /// The photograph's box, and the height the end rail is laid out
  /// against so the stepper sits on the card's baseline rather than
  /// wherever the words happen to end.
  static const double art = 72;

  @override
  Widget build(BuildContext context) {
    final spacing = context.spacing;

    return TerracottaCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(context.radii.xs),
            child: SizedBox.square(
              dimension: art,
              child: TerracottaImage(image: image),
            ),
          ),
          SizedBox(width: spacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: context.textTheme.titleMedium?.copyWith(
                    color: context.textColors.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if ((subtitle ?? '').isNotEmpty) ...[
                  SizedBox(height: spacing.xs),
                  Text(
                    subtitle!,
                    style: context.textTheme.bodySmall?.copyWith(
                      color: context.textColors.secondary,
                    ),
                  ),
                ],
                SizedBox(height: spacing.xs),
                PriceText(amount: price),
              ],
            ),
          ),
          SizedBox(width: spacing.sm),
          SizedBox(
            height: art,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Nothing to count on a card nobody has picked, and the
                // badge would read as a zero the customer has to
                // dismiss.
                if (quantity > 0)
                  _CountBadge(quantity: quantity, tint: tint)
                else
                  const SizedBox.shrink(),
                if (editable)
                  PieceStepper(
                    quantity: quantity,
                    // A specific object is one or none.
                    canAdd: canAdd && !(oneOnly && quantity > 0),
                    tint: tint,
                    onAdd: onAdd,
                    onRemove: onRemove,
                  )
                else
                  const SizedBox.shrink(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// «عدد ٢» — how many of this one are in the booking.
class _CountBadge extends StatelessWidget {
  const _CountBadge({required this.quantity, required this.tint});

  final int quantity;
  final Color tint;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: context.backgroundColors.container,
      borderRadius: BorderRadius.circular(context.radii.xs),
    ),
    child: Padding(
      padding: EdgeInsetsDirectional.symmetric(
        horizontal: context.spacing.sm,
        vertical: 2,
      ),
      child: Text(
        CommonStrings.count(quantity),
        style: context.textTheme.labelSmall?.copyWith(color: tint),
      ),
    ),
  );
}

/// The two square keys under a piece.
///
/// BOTH are always drawn, and `−` is dead at zero: the design gives
/// every card the same footprint, and a stepper that grows a second key
/// the first time it is pressed moves the one under the customer's
/// finger.
class PieceStepper extends StatelessWidget {
  const PieceStepper({
    required this.quantity,
    required this.canAdd,
    required this.tint,
    required this.onAdd,
    required this.onRemove,
    super.key,
  });

  final int quantity;
  final bool canAdd;
  final Color tint;
  final VoidCallback onAdd;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      // Reading order, which puts `−` first — the design draws the two
      // keys with `+` on the far side from where reading starts.
      _StepKey(
        icon: Icons.remove_rounded,
        tint: tint,
        onPressed: quantity > 0 ? onRemove : null,
      ),
      SizedBox(width: context.spacing.xs),
      _StepKey(
        icon: Icons.add_rounded,
        tint: tint,
        onPressed: canAdd ? onAdd : null,
      ),
    ],
  );
}

class _StepKey extends StatelessWidget {
  const _StepKey({
    required this.icon,
    required this.tint,
    required this.onPressed,
  });

  final IconData icon;
  final Color tint;

  /// Null DISABLES — the ceiling is on the booking, so the key that
  /// would break it is dead rather than silently ignored.
  final VoidCallback? onPressed;

  static const double _box = 28;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;
    final radius = BorderRadius.circular(context.radii.xs);

    return Semantics(
      button: true,
      enabled: enabled,
      child: Material(
        color: context.backgroundColors.container,
        borderRadius: radius,
        child: InkWell(
          onTap: onPressed,
          borderRadius: radius,
          child: SizedBox.square(
            dimension: _box,
            child: Icon(
              icon,
              size: context.iconSizes.sm,
              color: enabled
                  ? tint
                  : context.iconColors.secondary.withValues(alpha: 0.35),
            ),
          ),
        ),
      ),
    );
  }
}
