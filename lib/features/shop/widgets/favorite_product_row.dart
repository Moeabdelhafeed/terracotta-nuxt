import 'package:flutter/material.dart';

import '../../../core/extensions/context_extensions.dart';
import '../../../core/extensions/theme_colors_extension.dart';
import '../../../core/localization/strings/common_strings.dart';
import '../../../core/localization/strings/home_strings.dart';
import '../../../core/localization/strings/shop_strings.dart';
import '../../../core/tokens/extensions.dart';
import '../../../data/models/terracotta/shop/product.dart';
import '../../_shared/shared_hero.dart';
import '../../_shared/terracotta_image.dart';
import '../../_shared/terracotta_widgets.dart';
import '../data/stock.dart';
import 'discount_badge.dart';
import 'stock_label.dart';

/// A product as a ROW rather than a tile — the shop card's secondary
/// form.
///
/// The rails draw a product as a tall card because they scroll
/// sideways and a card is what fits. A saved list scrolls DOWN, and the
/// same card there would put one and a half products on a phone. So the
/// picture goes to the reading start, the words run beside it, and the
/// heart sits at the far end where it is reachable and out of the way.
class FavoriteProductRow extends StatelessWidget {
  const FavoriteProductRow({
    required this.product,
    this.onTap,
    this.onUnfavorite,
    super.key,
  });

  final Product product;
  final VoidCallback? onTap;

  /// Turns the heart on or off.
  ///
  /// The row is used in TWO places and they are not the same: in the
  /// saved list every row is favourited by definition, and in the
  /// browse list most are not. So the heart follows the product rather
  /// than the screen — it was hardcoded filled for the saved list and
  /// then lied on every browse row.
  final VoidCallback? onUnfavorite;

  /// The picture's WIDTH. Its height comes from the row.
  ///
  /// It used to be a fixed 96 square and the row's height came from
  /// it — which held while the words beside it fitted in 96 points. A
  /// two-line title over a struck-through price and a stock label
  /// makes a taller row, and the picture stayed 96 with a band of card
  /// under it. The picture now fills whatever height the words ask
  /// for, at the same width, cropped by `BoxFit.cover`.
  static const _imageWidth = 96.0;

  /// The shortest the picture may be, so a one-line row does not
  /// reduce it to a stripe.
  static const _imageMinHeight = 96.0;

  @override
  Widget build(BuildContext context) {
    final spacing = context.spacing;

    final soldOut =
        Stock.level(inStock: product.inStock, stock: product.stock) ==
        StockLevel.none;

    return TerracottaCard(
      // Still TAPPABLE when sold out — the detail page is where the
      // customer finds out what it was and whether anything like it is
      // left. A card that eats the tap just feels broken.
      onTap: onTap,
      bordered: true,
      padding: EdgeInsets.all(spacing.xs),
      child: Opacity(
        // Faded, not hidden: the piece is still on their list and the
        // studio still wants it seen. The same 0.55 every other card
        // uses, so one screen does not disagree with another about what
        // sold out looks like.
        opacity: soldOut ? 0.55 : 1,
        // INTRINSIC, so the picture can be told how tall the row is.
        // `stretch` alone would hand it an unbounded height inside a
        // shrink-wrapping list.
        child: IntrinsicHeight(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ConstrainedBox(
                constraints: const BoxConstraints(
                  minHeight: _imageMinHeight,
                  minWidth: _imageWidth,
                  maxWidth: _imageWidth,
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(context.radii.sm),
                  child: HeroTagClaim(
                    tag: HeroTag.product(product.id),
                    child: TerracottaImage(image: product.image),
                  ),
                ),
              ),
              SizedBox(width: spacing.sm),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      HeroTagClaim(
                        tag: HeroTag.productTitle(product.id),
                        child: Text(
                          product.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: context.textTheme.titleSmall?.copyWith(
                            color: context.textColors.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      SizedBox(height: spacing.xs),
                      // A sale price struck through beside the live one, the
                      // same treatment the rails give it. Money stays a
                      // decimal STRING the whole way.
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Flexible(
                            child: HeroTagClaim(
                              tag: HeroTag.productPrice(product.id),
                              child: PriceText(
                                amount: product.salePrice ?? product.price,
                                was: product.salePrice == null
                                    ? null
                                    : product.price,
                              ),
                            ),
                          ),
                          // BESIDE the price rather than over the picture:
                          // this row has no corner to spare, and the saving
                          // belongs next to the number it is about.
                          if (product.salePrice != null) ...[
                            SizedBox(width: spacing.xs),
                            HeroTagClaim(
                              tag: HeroTag.productDiscount(product.id),
                              child: DiscountBadge(
                                price: product.price,
                                salePrice: product.salePrice,
                                dense: true,
                              ),
                            ),
                          ],
                        ],
                      ),
                      // WHAT IS LEFT, or that there is none. It was the one
                      // card in the app that said nothing about stock.
                      if (Stock.level(
                            inStock: product.inStock,
                            stock: product.stock,
                          ) !=
                          StockLevel.fine) ...[
                        SizedBox(height: spacing.xs),
                        HeroTagClaim(
                          tag: HeroTag.productStock(product.id),
                          child: StockLabel(
                            inStock: product.inStock,
                            stock: product.stock,
                            dense: true,
                          ),
                        ),
                      ],
                      if (product.isFeatured) ...[
                        SizedBox(height: spacing.xs),
                        HeroTagClaim(
                          tag: HeroTag.productFeatured(product.id),
                          child: const _FeaturedTag(),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              SizedBox(width: spacing.xs),
              // The heart sits at the TOP of the row rather than being
              // stretched down it — `stretch` above is for the picture.
              Align(
                alignment: AlignmentDirectional.topCenter,
                child: HeroTagClaim(
                  tag: HeroTag.productFavourite(product.id),
                  child: _HeartButton(
                    filled: product.isFavorited,
                    onPressed: onUnfavorite,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// «مميز».
class _FeaturedTag extends StatelessWidget {
  const _FeaturedTag();

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: context.primaryColors.primary,
      borderRadius: BorderRadius.circular(context.radii.xs),
    ),
    child: Padding(
      padding: EdgeInsets.symmetric(
        horizontal: context.spacing.xs,
        vertical: 2,
      ),
      child: Text(
        HomeStrings.badgeFeatured,
        style: context.textTheme.labelSmall?.copyWith(
          color: context.textColors.onPrimary,
        ),
      ),
    ),
  );
}

/// The heart at the row's far end.
class _HeartButton extends StatelessWidget {
  const _HeartButton({required this.filled, this.onPressed});

  /// Whether this product is saved. Filled and outline are different
  /// answers, and drawing one for both was the bug.
  final bool filled;

  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) => IconButton(
    onPressed: onPressed,
    icon: Icon(
      filled ? Icons.favorite_rounded : Icons.favorite_border_rounded,
      color: context.primaryColors.accent,
      size: context.iconSizes.md,
    ),
    tooltip: filled ? CommonStrings.remove : ShopStrings.myFavorites,
    visualDensity: VisualDensity.compact,
  );
}
