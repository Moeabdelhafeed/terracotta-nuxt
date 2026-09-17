import 'package:flutter/material.dart';

import '../../../core/extensions/context_extensions.dart';
import '../../../core/extensions/theme_colors_extension.dart';
import '../../../core/localization/number_formatter.dart';
import '../../../core/localization/strings/home_strings.dart';
import '../../../core/localization/strings/shop_strings.dart';
import '../../../core/tokens/extensions.dart';
import '../../../shared/module/grid/global_grid.dart';
import '../../../shared/module/image/global_image.dart';
import '../../_shared/screen_entrance.dart';
import '../../_shared/shared_hero.dart';
import '../../_shared/terracotta_widgets.dart';
import '../data/stock.dart';
import 'discount_badge.dart';
import 'stock_label.dart';

/// The search field that heads the shop.
///
/// The glyph sits at the START of the field, so it leads the text in
/// both directions — the design puts it on the right, which is the
/// start in Arabic.
class ShopSearchField extends StatelessWidget {
  const ShopSearchField({
    this.onFilter,
    this.focusNode,
    this.controller,
    this.onChanged,
    this.filterCount = 0,
    this.autofocus = false,
    this.heroTag,
    this.onTap,
    super.key,
  });

  /// Flies the FIELD between two screens — not the filter button
  /// beside it.
  ///
  /// The two are one row but not one control: the field is the same
  /// thing on both screens, and the filter button exists on the browse
  /// screen alone. Flying them together would carry a button out of a
  /// bar that never had one and land it as though it had come from
  /// somewhere. It arrives on its own instead — in from the END, the
  /// edge it lives on.
  final String? heroTag;

  final VoidCallback? onFilter;

  /// Supplied when the bar has to know whether the field is being
  /// typed in — the shop collapses it back to a glyph on blur.
  final FocusNode? focusNode;
  final TextEditingController? controller;

  /// Every keystroke. The caller decides whether to debounce — the
  /// browse screen sends this to the SERVER and does.
  final ValueChanged<String>? onChanged;

  /// How many filters are on, shown as a dot on the button.
  final int filterCount;

  final bool autofocus;

  /// Makes the field a BUTTON rather than an input.
  ///
  /// The shop tab uses it: searching the catalogue belongs to the
  /// browse screen, and tapping here goes there with the keyboard up
  /// rather than typing in place. Given one, the field takes no focus
  /// of its own — a control that both navigates and accepts text is
  /// two controls wearing one box.
  final VoidCallback? onTap;

  /// The field's own height, rather than padding around a line of text.
  /// The design draws a bar you can hit, not a caption in a box.
  static const _fieldHeight = 52.0;

  @override
  Widget build(BuildContext context) {
    final spacing = context.spacing;
    return Row(
      children: [
        Expanded(
          child: _flown(
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: context.backgroundColors.inputBackground,
                borderRadius: BorderRadius.circular(context.radii.sm),
                border: Border.all(color: context.backgroundColors.outline),
              ),
              child: Padding(
                padding: EdgeInsetsDirectional.symmetric(
                  horizontal: spacing.md,
                ),
                child: SizedBox(
                  height: _fieldHeight,
                  child: Row(
                    children: [
                      Expanded(
                        // A REAL field, not a hint in a box. It was the
                        // latter, which looked right and could not be
                        // typed in — and the bar now collapses this back
                        // to a glyph when it loses focus, which needs a
                        // focus to lose.
                        child: TextField(
                          focusNode: focusNode,
                          controller: controller,
                          onChanged: onChanged,
                          autofocus: autofocus,
                          readOnly: onTap != null,
                          onTap: onTap,
                          textInputAction: TextInputAction.search,
                          style: context.textTheme.bodyMedium?.copyWith(
                            color: context.textColors.primary,
                          ),
                          decoration: InputDecoration(
                            isDense: true,
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            contentPadding: EdgeInsets.zero,
                            hintText: ShopStrings.searchHint,
                            hintStyle: context.textTheme.bodyMedium?.copyWith(
                              color: context.textColors.primary.withValues(
                                alpha: 0.54,
                              ),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: spacing.sm),
                      // At the END — the left in Arabic, as the design
                      // draws it. It led the row before, which put it on
                      // the right and pushed the hint off the edge the
                      // reader starts from.
                      Icon(
                        Icons.search_rounded,
                        size: context.iconSizes.md,
                        color: context.primaryColors.primary,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
        if (onFilter != null) ...[
          SizedBox(width: spacing.sm),
          // SQUARE, and the field's own height — it sits beside the bar
          // and a shorter button reads as a mistake.
          ScreenEntrance.drift(
            // IN FROM THE END, the edge it lives on. It is not part of
            // the field's flight, so without this it is the one thing
            // in the bar that simply appears.
            from: const Offset(1.5, 0),
            logical: true,
            arrival: EntranceArrival.mount,
            child: SizedBox.square(
              dimension: _fieldHeight,
              child: TerracottaCard(
                onTap: onFilter,
                padding: EdgeInsets.zero,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Icon(
                      Icons.tune_rounded,
                      size: context.iconSizes.md,
                      color: context.primaryColors.primary,
                    ),
                    if (filterCount > 0)
                      PositionedDirectional(
                        top: 6,
                        end: 6,
                        child: _FilterDot(count: filterCount),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  /// The field, flown when a caller gave it a tag.
  Widget _flown({required Widget child}) => heroTag == null
      ? child
      // A `TextField` in the Overlay has no `Material` over it and
      // throws — see [fieldShuttle].
      : SharedHero(
          tag: heroTag!,
          flightShuttleBuilder: fieldShuttle,
          child: child,
        );
}

/// A product card — image, heart, badge, title, price.
class ProductCard extends StatelessWidget {
  const ProductCard({
    this.title = '',
    this.price = '',
    this.wasPrice,
    this.featured = false,
    this.productId,
    this.favorited = false,
    this.inStock = true,
    this.stock,
    this.onTap,
    this.onFavorite,
    super.key,
  });

  final String title;

  /// Decimal strings, printed as received.
  final String price;
  final String? wasPrice;

  final bool featured;
  final bool favorited;

  /// Flies the discount badge to the detail page's own. Null on a card
  /// with no counterpart to fly to.
  final int? productId;

  /// Stock, straight off the wire. See `Stock` for what the pair means
  /// — `stock: null` is UNTRACKED, not empty.
  final bool inStock;
  final int? stock;

  final VoidCallback? onTap;
  final VoidCallback? onFavorite;

  @override
  Widget build(BuildContext context) {
    final spacing = context.spacing;
    final soldOut =
        Stock.level(inStock: inStock, stock: stock) == StockLevel.none;

    return TerracottaCard(
      // Still TAPPABLE when sold out. The detail page is where the
      // customer sees what it was and whether anything like it is left
      // — a card that eats the tap just feels broken.
      onTap: onTap,
      padding: EdgeInsets.zero,
      child: Opacity(
        // Faded, not hidden: the piece is still part of the catalogue
        // and the studio still wants it seen.
        opacity: soldOut ? 0.55 : 1,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Stack(
                children: [
                  Positioned.fill(
                    child: ColoredBox(
                      color: context.backgroundColors.container,
                    ),
                  ),
                  // THE START CORNER, stacked.
                  //
                  // The heart and the saving both belong here, and a
                  // second `PositionedDirectional` at the same offset
                  // would put one on top of the other. «مميز» keeps the
                  // END: it is the studio talking about the piece and
                  // this is the price talking, so a product can carry
                  // either, both or neither and nothing has to move.
                  PositionedDirectional(
                    top: spacing.xs,
                    start: spacing.xs,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        GestureDetector(
                          onTap: onFavorite,
                          child: _HeartPill(active: favorited),
                        ),
                        SizedBox(height: spacing.xs),
                        DiscountBadge(
                          price: wasPrice ?? price,
                          salePrice: wasPrice == null ? null : price,
                          productId: productId,
                          dense: true,
                        ),
                      ],
                    ),
                  ),
                  if (featured)
                    PositionedDirectional(
                      top: spacing.xs,
                      end: spacing.xs,
                      child: const _Badge(),
                    ),
                  // Along the FOOT of the picture, where it cannot fight
                  // the heart or the featured badge for a corner.
                  if (Stock.level(inStock: inStock, stock: stock) !=
                      StockLevel.fine)
                    PositionedDirectional(
                      bottom: spacing.xs,
                      start: spacing.xs,
                      end: spacing.xs,
                      child: Align(
                        alignment: AlignmentDirectional.centerStart,
                        child: StockLabel(
                          inStock: inStock,
                          stock: stock,
                          productId: productId,
                          dense: true,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Padding(
              padding: EdgeInsets.all(spacing.xs),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: context.textTheme.bodySmall,
                  ),
                  SizedBox(height: spacing.xs),
                  PriceText(amount: price, was: wasPrice),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HeartPill extends StatelessWidget {
  const _HeartPill({required this.active});

  final bool active;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: context.backgroundColors.cardBackground.withValues(alpha: 0.34),
      borderRadius: BorderRadius.circular(context.radii.xs),
    ),
    child: Padding(
      padding: const EdgeInsets.all(3),
      child: Icon(
        active ? Icons.favorite_rounded : Icons.favorite_border_rounded,
        size: context.iconSizes.xs,
        color: context.primaryColors.accent,
      ),
    ),
  );
}

class _Badge extends StatelessWidget {
  const _Badge();

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

/// A grid of product cards that reflows with the window.
///
/// Goes through [GlobalGrid] rather than a raw `GridView`: this is a
/// COLLECTION the customer browses, not a chrome strip, so it wants the
/// module's empty state, its selection plumbing and — once the shop is
/// wired — its pagination. `GET /api/shop/products` paginates with
/// `per_page`, and re-inventing that here would mean re-inventing it
/// again on every other list.
class ProductGrid extends StatelessWidget {
  const ProductGrid({this.count = 6, this.onOpen, super.key});

  final int count;
  final ValueChanged<int>? onOpen;

  @override
  Widget build(BuildContext context) {
    final spacing = context.spacing;
    return GlobalGrid<int>.static(
      items: List<int>.generate(count, (i) => i),
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      compactColumns: 2,
      // MORE COLUMNS WHEN THERE IS WIDTH. A landscape phone is ~874dp
      // across, which reads as `expanded` — two columns there means two
      // very wide tiles and a screen that shows almost nothing. The
      // buckets are by WIDTH, so a tablet gets the same benefit.
      mediumColumns: 3,
      expandedColumns: 4,
      largeColumns: 5,
      style: GridStyle(
        mainAxisSpacing: spacing.sm,
        crossAxisSpacing: spacing.sm,
        aspectRatio: 133 / 182,
        padding: EdgeInsets.zero,
      ),
      itemBuilder: (context, item, index) =>
          ProductCard(onTap: () => onOpen?.call(index)),
    );
  }
}

/// The quick-action tiles on the shop landing — cart, favourites,
/// orders.
class ShopQuickActions extends StatelessWidget {
  const ShopQuickActions({
    this.cartCount = 0,
    this.orderCount = 0,
    this.onCart,
    this.onFavorites,
    this.onOrders,
    super.key,
  });

  final int cartCount;
  final int orderCount;
  final VoidCallback? onCart;
  final VoidCallback? onFavorites;
  final VoidCallback? onOrders;

  @override
  Widget build(BuildContext context) {
    final spacing = context.spacing;

    // TWO then ONE, as the design lays them out — favourites and the
    // cart share a row and orders takes the width below them. Not three
    // across: these labels are two words each in Arabic and a third of
    // the screen wraps every one of them.
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: _Action(
                  label: ShopStrings.myFavorites,
                  art: _favorites,
                  onTap: onFavorites,
                ),
              ),
              SizedBox(width: spacing.sm),
              Expanded(
                child: _Action(
                  label: ShopStrings.myCart,
                  art: _cart,
                  badge: cartCount,
                  onTap: onCart,
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: spacing.sm),
        _Action(
          label: ShopStrings.myOrders,
          art: _orders,
          badge: orderCount,
          onTap: onOrders,
        ),
      ],
    );
  }

  static const _favorites = 'assets/images/favoriate-illustration.png';
  static const _cart = 'assets/images/cart-illustration.png';
  static const _orders = 'assets/images/my-orders-illustration.png';
}

/// One shortcut: its words at the reading start, its drawing at the
/// end.
class _Action extends StatelessWidget {
  const _Action({
    required this.label,
    required this.art,
    this.badge,
    this.onTap,
  });

  final String label;

  /// The line drawing, which is what the design uses here rather than a
  /// Material glyph.
  final String art;

  final int? badge;
  final VoidCallback? onTap;

  /// The drawing's box. Smaller than the 56 it started at: at that
  /// size it competed with the words instead of labelling them.
  static const _artBox = 40.0;

  @override
  Widget build(BuildContext context) {
    final spacing = context.spacing;
    return TerracottaCard(
      onTap: onTap,
      bordered: true,
      padding: EdgeInsets.all(spacing.sm),
      child: Row(
        children: [
          Expanded(
            child: Row(
              children: [
                Flexible(
                  child: Text(
                    label,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: context.textTheme.titleSmall?.copyWith(
                      color: context.textColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                // AFTER the words, which in Arabic is their left — a
                // count belongs behind the thing it counts.
                if (badge != null && badge! > 0) ...[
                  SizedBox(width: spacing.xs),
                  _CountBubble(count: badge!),
                ],
              ],
            ),
          ),
          SizedBox(width: spacing.sm),
          SizedBox.square(
            dimension: _artBox,
            child: GlobalImage.a(
              art,
              placeholder: const SizedBox.shrink(),
              style: const ImageStyle(
                fit: BoxFit.contain,
                borderRadius: BorderRadius.zero,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// «٢» — the count on a shortcut, localized.
class _CountBubble extends StatelessWidget {
  const _CountBubble({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      color: context.primaryColors.primary,
    ),
    child: Padding(
      padding: const EdgeInsets.all(5),
      child: Text(
        // Plain `ar` renders WESTERN digits.
        AppNumbers.localizeDigits('$count'),
        style: context.textTheme.labelSmall?.copyWith(
          color: context.textColors.onPrimary,
        ),
      ),
    ),
  );
}

/// «٢» over the filter button when filters are on.
class _FilterDot extends StatelessWidget {
  const _FilterDot({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      color: context.primaryColors.primary,
    ),
    child: Padding(
      padding: const EdgeInsets.all(4),
      child: Text(
        AppNumbers.localizeDigits('$count'),
        style: context.textTheme.labelSmall?.copyWith(
          color: context.textColors.onPrimary,
          height: 1,
        ),
      ),
    ),
  );
}
