import 'package:flutter/material.dart';

import '../../../core/extensions/context_extensions.dart';
import '../../../core/extensions/theme_colors_extension.dart';
import '../../../core/localization/strings/shop_strings.dart';
import '../../../core/tokens/extensions.dart';
import '../../_shared/shared_hero.dart';
import '../data/discount.dart';

/// «-٢٣٪» — what this piece saves, on the corner of its card.
///
/// ## Where it sits, and why not beside «مميز»
///
/// The featured badge is the STUDIO talking about the piece; this is
/// the PRICE talking. They are different facts and a product can carry
/// either, both or neither — so this takes the top of the reading START
/// and the featured badge keeps the END, and neither has to move when
/// the other appears.
///
/// ## The saving, not the price
///
/// A shopper compares two numbers to work out whether a markdown is
/// worth anything. This does that arithmetic for them, and it does it
/// on integer halalas rather than on doubles — see [Discount].
///
/// It draws NOTHING when there is no real saving: no sale price, a sale
/// price the CMS set at or above the list price, or a markdown that
/// rounds to zero.
class DiscountBadge extends StatelessWidget {
  const DiscountBadge({
    required this.price,
    required this.salePrice,
    this.productId,
    this.dense = false,
    super.key,
  });

  /// Decimal STRINGS, as they arrive. See [Discount].
  final String price;
  final String? salePrice;

  /// Flies to the same badge on the detail page when given. Null on a
  /// surface with no counterpart — the sheet, a rail nothing opens.
  final int? productId;

  /// The card-corner size. False is the detail page's own, which sits
  /// beside a full-size price.
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final off = Discount.percentOff(price: price, salePrice: salePrice);
    if (off == null) return const SizedBox.shrink();

    final badge = _Pill(text: ShopStrings.discountBadge(off), dense: dense);
    return switch (productId) {
      final id? => SharedHero(tag: HeroTag.productDiscount(id), child: badge),
      null => badge,
    };
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.text, required this.dense});

  final String text;
  final bool dense;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      // GREEN, because a discount is good news.
      //
      // It was the SALE red — the colour the struck-through price
      // uses. On a price that reads as "this is the old number"; on a
      // badge saying «-٢٠٪» it reads as a warning, and red is the
      // colour this app uses for a cancelled booking and a failed
      // request. Money coming OFF is the one thing on a product card
      // the customer is pleased to see.
      color: context.statusColors.success,
      borderRadius: BorderRadius.circular(context.radii.xs),
    ),
    child: Padding(
      padding: EdgeInsets.symmetric(
        horizontal: dense ? 6 : context.spacing.sm,
        vertical: dense ? 2 : 4,
      ),
      child: Text(
        text,
        style:
            (dense
                    ? context.textTheme.labelSmall
                    : context.textTheme.labelMedium)
                ?.copyWith(
                  color: context.textColors.onPrimary,
                  fontWeight: FontWeight.w700,
                ),
      ),
    ),
  );
}
