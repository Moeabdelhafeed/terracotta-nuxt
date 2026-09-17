import 'package:flutter/material.dart';

import '../../../core/extensions/context_extensions.dart';
import '../../../core/extensions/theme_colors_extension.dart';
import '../../../core/tokens/extensions.dart';
import '../../_shared/shared_hero.dart';
import '../data/stock.dart';

/// «نفدت الكمية» / «بقي ٣ قطع» — how much is left, when it matters.
///
/// Silent when there is plenty, because a shop that labels every piece
/// "in stock" is a shop where the label means nothing. It speaks in
/// exactly two situations, and looks different in each: running OUT is
/// urgency, being out is a refusal.
class StockLabel extends StatelessWidget {
  const StockLabel({
    required this.inStock,
    this.stock,
    this.productId,
    this.dense = false,
    this.solid = false,
    super.key,
  });

  final bool inStock;
  final int? stock;

  /// Flies to the same label on the detail page when given. Null on a
  /// surface with no counterpart, and on a page that draws the same
  /// product twice — there the CALLER claims the tag, the way the
  /// saving and the heart already do.
  final int? productId;

  /// Tighter type and padding, for a product card where the label sits
  /// over the picture rather than in a column of its own.
  final bool dense;

  /// FILLED, the way «مميز» is filled.
  ///
  /// On a card the label sits over a photograph, and the tinted version
  /// — ink at 12% — takes whatever is behind it: over a pale piece it
  /// almost vanishes, and it does not match the badge stacked beside
  /// it. In a column of its own, on a page background, the tint is
  /// right and this is not.
  final bool solid;

  @override
  Widget build(BuildContext context) {
    final level = Stock.level(inStock: inStock, stock: stock);
    final text = Stock.label(inStock: inStock, stock: stock);
    if (text == null) return const SizedBox.shrink();

    // Sold out is the app's error ink; running low is the WARNING one.
    // Painting both red would make "three left" — which is an
    // invitation — look like a failure.
    final ink = level == StockLevel.none
        ? context.statusColors.error
        : context.statusColors.warning;

    final label = _Pill(
      text: text,
      ink: ink,
      dense: dense,
      solid: solid,
    );
    return switch (productId) {
      final id? => SharedHero(tag: HeroTag.productStock(id), child: label),
      null => label,
    };
  }
}

class _Pill extends StatelessWidget {
  const _Pill({
    required this.text,
    required this.ink,
    required this.dense,
    required this.solid,
  });

  final String text;
  final Color ink;
  final bool dense;
  final bool solid;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: solid ? ink : ink.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(context.radii.xs),
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: dense ? 6 : context.spacing.sm,
          vertical: dense ? 2 : 4,
        ),
        child: Text(
          text,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style:
              (dense
                      ? context.textTheme.labelSmall
                      : context.textTheme.bodySmall)
                  ?.copyWith(
                    color: solid ? context.textColors.onPrimary : ink,
                    fontWeight: FontWeight.w700,
                  ),
        ),
      ),
    );
  }
}
