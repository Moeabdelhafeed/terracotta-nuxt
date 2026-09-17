import 'package:flutter/material.dart';

import '../../../core/extensions/context_extensions.dart';
import '../../../core/extensions/theme_colors_extension.dart';
import '../../../core/localization/strings/home_strings.dart';
import '../../../core/localization/strings/shop_strings.dart';
import '../../../core/tokens/extensions.dart';
import '../../../data/models/terracotta/content/home_product_card.dart';
import '../../../data/models/terracotta/core/api_image.dart';
import '../../../data/models/terracotta/shop/product.dart';
import '../../../shared/module/list/global_list.dart';
import '../../_shared/shared_hero.dart';
import '../../_shared/terracotta_image.dart';
import '../../_shared/terracotta_widgets.dart';
import '../../shop/data/stock.dart';
import '../../shop/widgets/discount_badge.dart';
import '../../shop/widgets/stock_label.dart';

/// The featured / offers rail.
///
/// A card is image, favourite heart, title and price. When the product
/// is on offer the design strikes the original through beside the sale
/// price, which [PriceText] handles.
///
/// The heart sits at the START of the image, and the "featured" badge
/// at the END — both directional, so the pair swaps together.
class ProductCarousel extends StatelessWidget {
  const ProductCarousel({
    required this.products,
    this.railKey = 'rail',
    this.onToggleFavorite,
    this.onOpen,
    super.key,
  });

  /// From `GET /api/home`.
  ProductCarousel.home({
    required List<HomeProductCard> cards,
    this.railKey = 'rail',
    this.onToggleFavorite,
    this.onOpen,
    super.key,
  }) : products = [for (final c in cards) ProductTile.fromHome(c)];

  /// From `GET /api/shop/home`.
  ///
  /// Two payloads, one rail: the shop's products carry a NULLABLE image
  /// where the home rail's is required, so they meet at a small view
  /// model rather than one pretending to be the other.
  ProductCarousel.shop({
    required List<Product> items,
    this.railKey = 'rail',
    this.onToggleFavorite,
    this.onOpen,
    super.key,
  }) : products = [for (final p in items) ProductTile.fromShop(p)];

  /// The rail's contents, in the API's own model — so binding this to
  /// `GET /api/home` is a change of SOURCE, not of shape.
  final List<ProductTile> products;

  /// WHICH RAIL THIS IS, for hero claims.
  ///
  /// The home page draws a featured rail and an offers rail, and the
  /// live payload puts the same product in both — so `product:13`
  /// cannot say which card the reader pressed. Paired with the id this
  /// names the OCCURRENCE, and `HeroScope.promote` hands that
  /// occurrence the tags when it is tapped. Two rails with the same
  /// key on one page puts the bug back.
  final String railKey;

  /// Turns one product's heart on or off. Null leaves the heart as a
  /// read-only mark — which is what it was everywhere until the shop
  /// was bound, and still is on any screen that has not wired it.
  final ValueChanged<int>? onToggleFavorite;

  /// Opens one product, by id. Null leaves the card a display tile —
  /// which is what every rail was until the detail screen was bound.
  /// The TILE, not just its id: the detail page fetches, and until it
  /// answers there is nothing for a hero to land on — so the card's own
  /// picture, name and price travel with the tap.
  final ValueChanged<ProductTile>? onOpen;

  @override
  Widget build(BuildContext context) {
    final spacing = context.spacing;
    // NO fixed height. `ListCrossAxisFit.tallestItem` measures the
    // whole list once and takes the tallest — so a two-line title or a
    // struck-through original price makes the rail taller instead of
    // being clipped by a number typed here.
    //
    // `tallestItem` rather than `tallestVisible`: the strip should not
    // breathe as cards scroll past.
    return GlobalList<ProductTile>.static(
      // `GlobalList`, not a bare `ListView`: the house list is what
      // carries the empty state, the edge fade and the scroll physics
      // the rest of the app uses. A horizontal list follows the ambient
      // `Directionality` on its own — in Arabic it starts at the right
      // edge with no `reverse:` flag, and setting one double-mirrors it.
      items: products,
      scrollDirection: Axis.horizontal,
      // The rail runs EDGE TO EDGE and insets its CONTENTS instead.
      //
      // Guttered from outside, the last item is clipped mid-tile with
      // nowhere to scroll into. As list padding the first item still
      // lines up with the headings above it, and the last one scrolls
      // fully into view.
      //
      // `spacing.md` is the same token the page's own sections use, so
      // the two cannot drift apart.
      style: ListStyle(
        padding: EdgeInsets.symmetric(horizontal: spacing.md),
        // And the rail's HEIGHT comes from its content rather than from
        // a number typed here: a two-line title or a struck-through
        // original price makes it taller instead of being clipped.
        //
        // `tallestItem` measures the whole list once. `tallestVisible`
        // would re-measure per scroll frame and let the strip breathe
        // as cards pass, which is motion nobody asked for.
        crossAxisFit: ListCrossAxisFit.tallestItem,
      ),
      separatorBuilder: (_, _) => SizedBox(width: spacing.sm),
      itemBuilder: (context, product, index) => _ProductCard(
        product: product,
        // WHICH RAIL THIS IS. The home page draws a featured rail AND
        // an offers rail and the live payload puts the same product in
        // both — so a tag alone cannot say which card the reader
        // pressed. See `HeroScope.promote`.
        group: '$railKey:${product.id}',
        onToggleFavorite: onToggleFavorite,
        onOpen: onOpen,
      ),
    );
  }
}

class _ProductCard extends StatelessWidget {
  const _ProductCard({
    required this.product,
    required this.group,
    this.onToggleFavorite,
    this.onOpen,
  });

  final ValueChanged<int>? onToggleFavorite;
  final ValueChanged<ProductTile>? onOpen;

  final ProductTile product;

  /// This occurrence of this product — see `HeroScope.promote`.
  final Object group;

  @override
  Widget build(BuildContext context) {
    final spacing = context.spacing;

    return SizedBox(
      width: 133,
      child: TerracottaCard(
        onTap: onOpen == null
            ? null
            : () {
                // THE CARD THAT WAS PRESSED IS THE CARD THAT FLIES.
                //
                // A claim stops two heroes sharing a tag but does not
                // choose between them: the featured rail builds first
                // and kept every tag, so tapping the offers copy flew
                // the featured picture out of a row nobody touched.
                HeroScope.promote(context, group);
                onOpen!(product);
              },
        padding: EdgeInsets.zero,
        child: Opacity(
          // Faded, not hidden — the studio still wants the piece seen,
          // and the detail page still has something to say about it.
          opacity:
              Stock.level(
                    inStock: product.inStock,
                    stock: product.stock,
                  ) ==
                  StockLevel.none
              ? 0.55
              : 1,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // AspectRatio, not Expanded.
              //
              // The rail sizes itself to its tallest card now, so the
              // card's own column is unbounded — and an `Expanded` in an
              // unbounded column has nothing to expand into. It collapsed
              // to zero height, taking the picture, the heart and the
              // badge with it: the card rendered as a title and a price
              // with a blank strip above them.
              //
              // A ratio gives the column a height it can measure, which
              // is what `tallestItem` needs from every child.
              AspectRatio(
                aspectRatio: 1,
                child: Stack(
                  children: [
                    Positioned.fill(
                      // `imageApi` is the ABSOLUTE url; `url` is relative
                      // to the storage host and renders as a broken image.
                      // Rounded at the HEAD only. The picture meets the
                      // title block at the foot, so a radius there would
                      // cut two notches out of a join meant to be flush —
                      // so the CARD clips it rather than the image
                      // rounding itself.
                      child: ClipRRect(
                        borderRadius: BorderRadiusDirectional.only(
                          topStart: Radius.circular(context.radii.md),
                          topEnd: Radius.circular(context.radii.md),
                        ).resolve(Directionality.of(context)),
                        // The picture flies into the detail page's
                        // gallery.
                        //
                        // Through `HeroScope`, not a bare tag: the home
                        // page draws a featured rail AND an offers
                        // rail, and the live payload puts products 1
                        // and 13 in both — two heroes with one tag on
                        // one route, which THROWS. The first card to
                        // ask gets the tag; a second copy simply does
                        // not fly, and which of two identical cards
                        // flew hardly matters.
                        // The picture flies into the detail page's
                        // gallery.
                        //
                        // Through a CLAIM, because the home page draws a
                        // featured rail AND an offers rail, and the live
                        // payload puts products 1 and 13 in both. Two
                        // heroes with one tag on one route THROWS.
                        child: HeroTagClaim(
                          tag: HeroTag.product(product.id),
                          group: group,
                          child: TerracottaImage(image: product.image),
                        ),
                      ),
                    ),
                    // THE SAVING, at the top of the reading START.
                    //
                    // The heart keeps the END on this card, so the two
                    // never fight for a corner. Claimed rather than
                    // wrapped for the same reason the picture is: this
                    // page draws a featured rail AND an offers rail,
                    // and the live payload puts products 1 and 13 in
                    // both — two heroes with one tag on one route
                    // throws.
                    PositionedDirectional(
                      top: spacing.xs,
                      start: spacing.xs,
                      child: HeroTagClaim(
                        tag: HeroTag.productDiscount(product.id),
                        group: group,
                        child: DiscountBadge(
                          price: product.price,
                          salePrice: product.salePrice,
                          dense: true,
                        ),
                      ),
                    ),
                    PositionedDirectional(
                      top: spacing.xs,
                      end: spacing.xs,
                      child: HeroTagClaim(
                        tag: HeroTag.productFavourite(product.id),
                        group: group,
                        child: _HeartPill(
                          filled: product.isFavorited,
                          onPressed: onToggleFavorite == null
                              ? null
                              : () => onToggleFavorite!(product.id),
                        ),
                      ),
                    ),
                    // Along the foot of the picture — the same place the
                    // shop's own card puts it, so one piece looks the
                    // same wherever the customer meets it.
                    // STACKED, not stacked ON: both of these used to
                    // be pinned to the same corner, so a piece that was
                    // featured AND running out drew one badge on top of
                    // the other.
                    //
                    // The stock label leads, because it is the one that
                    // expires — «مميز» will still be true tomorrow.
                    PositionedDirectional(
                      bottom: spacing.xs,
                      start: spacing.xs,
                      end: spacing.xs,
                      child: Align(
                        alignment: AlignmentDirectional.centerStart,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Claimed rather than wrapped, like the
                            // saving above it: this page draws a
                            // featured rail AND an offers rail, and the
                            // live payload puts the same product in
                            // both.
                            HeroTagClaim(
                              tag: HeroTag.productStock(product.id),
                              group: group,
                              child: StockLabel(
                                inStock: product.inStock,
                                stock: product.stock,
                                dense: true,
                                // Filled, to match the badge under it.
                                solid: true,
                              ),
                            ),
                            if (Stock.level(
                                      inStock: product.inStock,
                                      stock: product.stock,
                                    ) !=
                                    StockLevel.fine &&
                                product.isFeatured)
                              SizedBox(height: spacing.xs / 2),
                            if (product.isFeatured)
                              HeroTagClaim(
                                tag: HeroTag.productFeatured(product.id),
                                group: group,
                                child: _FeaturedBadge(),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                // More room top and bottom than at the sides: the title
                // and the price sit under a full-bleed picture, and at an
                // even `xs` all round they read as crowded against it.
                padding: EdgeInsets.symmetric(
                  horizontal: spacing.xs,
                  vertical: spacing.sm,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    HeroTagClaim(
                      tag: HeroTag.productTitle(product.id),
                      group: group,
                      child: Text(
                        product.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: context.textTheme.bodySmall,
                      ),
                    ),
                    SizedBox(height: spacing.xs),
                    // The SALE price leads when there is one, with the
                    // original struck through beside it. Both stay
                    // STRINGS — money is decimal on this API and parsing
                    // it to a double rounds totals wrong.
                    HeroTagClaim(
                      tag: HeroTag.productPrice(product.id),
                      group: group,
                      child: PriceText(
                        amount: product.salePrice ?? product.price,
                        was: product.salePrice == null ? null : product.price,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HeartPill extends StatelessWidget {
  const _HeartPill({required this.filled, this.onPressed});

  final bool filled;

  /// Null leaves it a read-only mark rather than a dead button.
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final pill = _pill(context);
    if (onPressed == null) return pill;
    return Semantics(
      button: true,
      selected: filled,
      label: ShopStrings.myFavorites,
      child: GestureDetector(onTap: onPressed, child: pill),
    );
  }

  Widget _pill(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      // The PAGE's colour, opaque — the pill sits on a photograph and a
      // translucent card colour let the picture through, which is what
      // made it hard to see at all.
      color: context.backgroundColors.scaffoldBackground,
      borderRadius: BorderRadius.circular(context.radii.xs),
    ),
    child: Padding(
      // Was 3 points around an `xs` glyph, which came out as a control
      // too small to aim at — under the 44-point target a finger needs.
      padding: EdgeInsets.all(context.spacing.xs),
      child: Icon(
        filled ? Icons.favorite_rounded : Icons.favorite_border_rounded,
        size: context.iconSizes.sm,
        color: context.primaryColors.accent,
      ),
    ),
  );
}

class _FeaturedBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: context.primaryColors.primary,
      borderRadius: BorderRadius.circular(context.radii.xs),
    ),
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      child: Text(
        HomeStrings.badgeFeatured,
        style: context.textTheme.labelSmall?.copyWith(
          color: context.textColors.onPrimary,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
  );
}

/// One card in the rail, from either payload.
@immutable
class ProductTile {
  const ProductTile({
    required this.id,
    required this.title,
    required this.price,
    required this.isFeatured,
    required this.isFavorited,
    required this.inStock,
    this.stock,
    this.salePrice,
    this.image,
  });

  factory ProductTile.fromHome(HomeProductCard c) => ProductTile(
    id: c.id,
    title: c.title,
    price: c.price,
    salePrice: c.salePrice,
    image: c.image,
    isFeatured: c.isFeatured,
    isFavorited: c.isFavorited,
    inStock: c.inStock,
    stock: c.stock,
  );

  factory ProductTile.fromShop(Product p) => ProductTile(
    id: p.id,
    title: p.title,
    price: p.price,
    salePrice: p.salePrice,
    image: p.image,
    isFeatured: p.isFeatured,
    isFavorited: p.isFavorited,
    inStock: p.inStock,
    stock: p.stock,
  );

  final int id;
  final String title;

  /// Decimal STRINGS, never parsed to a number.
  final String price;
  final String? salePrice;

  /// Nullable: a shop product may have none.
  final ApiImage? image;

  final bool isFeatured;
  final bool isFavorited;

  /// Stock, straight off the wire. `stock: null` is UNTRACKED, not
  /// empty — see `Stock`.
  final bool inStock;
  final int? stock;
}
