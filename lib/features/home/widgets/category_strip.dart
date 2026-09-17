import 'package:flutter/material.dart';

import '../../../core/extensions/context_extensions.dart';
import '../../../core/extensions/theme_colors_extension.dart';
import '../../../core/tokens/extensions.dart';
import '../../../data/models/terracotta/content/home_category.dart';
import '../../../data/models/terracotta/core/api_image.dart';
import '../../../data/models/terracotta/shop/shop_category.dart';
import '../../../shared/module/list/global_list.dart';
import '../../../shared/module/marquee/global_marquee.dart';
import '../../_shared/shared_hero.dart';
import '../../_shared/terracotta_image.dart';
import '../../_shared/terracotta_widgets.dart';

/// «تصفح الفئات» — the horizontally scrolling category tiles.
///
/// The list scrolls in the reading direction on its own: a horizontal
/// `ListView` follows the ambient `Directionality`, so in Arabic it
/// starts at the right edge with no `reverse:` flag. Setting one would
/// double-mirror it.
class CategoryStrip extends StatelessWidget {
  const CategoryStrip({
    this.tiles = const [],
    this.selectedId,
    this.onTap,
    super.key,
  });

  /// From `GET /api/home`.
  CategoryStrip.home({
    required List<HomeCategory> categories,
    this.selectedId,
    this.onTap,
    super.key,
  }) : tiles = [for (final c in categories) CategoryTile.fromHome(c)];

  /// From `GET /api/shop/home`.
  ///
  /// Two payloads, one strip: the shop's categories carry sub-categories
  /// and a NULLABLE image where the home rail's is required, so they
  /// meet at a small view model rather than one of them pretending to
  /// be the other.
  CategoryStrip.shop({
    required List<ShopCategory> categories,
    this.selectedId,
    this.onTap,
    super.key,
  }) : tiles = [for (final c in categories) CategoryTile.fromShop(c)];

  /// Empty by default — an empty strip is an honest way to say a screen
  /// is not bound yet, better than tiles of invented categories that
  /// look like real ones.
  final List<CategoryTile> tiles;

  /// Which one is currently filtering the shop, if any.
  final int? selectedId;

  /// Opens a category. Null leaves the tiles as a read-only strip,
  /// which is what they are on screens that do not browse.
  final ValueChanged<int>? onTap;

  @override
  Widget build(BuildContext context) {
    final spacing = context.spacing;

    return SizedBox(
      height: 94,
      child: GlobalList<CategoryTile>.static(
        items: tiles,
        scrollDirection: Axis.horizontal,
        // The rail runs EDGE TO EDGE and insets its CONTENTS instead.
        //
        // Guttered from outside, the last item is clipped mid-tile with
        // nowhere to scroll into. As list padding the first item still
        // lines up with the headings above it, and the last one scrolls
        // fully into view.
        //
        // `spacing.md` is the same token the page's own sections use,
        // so the two cannot drift apart.
        style: ListStyle(
          padding: EdgeInsets.symmetric(horizontal: spacing.md),
        ),

        separatorBuilder: (_, _) => SizedBox(width: spacing.sm),
        itemBuilder: (context, category, index) => SizedBox(
          width: 78,
          child: TerracottaCard(
            onTap: onTap == null ? null : () => onTap!(category.id),
            // TRANSPARENT unless it is the current filter. The tile is
            // its 10%-black hairline on the page — `TerracottaCard`
            // carries no shadow now, so a filled tile would be the only
            // thing separating these from the shortcuts above.
            color: category.id == selectedId
                ? context.backgroundColors.cardBackground
                : Colors.transparent,
            // MORE room top and bottom than at the sides: the artwork
            // is a cut-out on transparency and needs air above and
            // below it, where the label crowds it.
            // Symmetric, so there is no side to it and nothing for the
            // reading direction to mirror.
            padding: EdgeInsets.symmetric(
              horizontal: spacing.xs,
              vertical: spacing.sm,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Expanded(
                  // `imageApi` is the ABSOLUTE url; `url` is relative to
                  // the storage host and renders as a broken image.
                  // NO plate behind the cut-out: these are small
                  // silhouettes, and a filled box behind one is a
                  // square where a shape should be.
                  // Home and shop draw the SAME rail from two
                  // payloads, so a category holds still while the
                  // reader changes tab.
                  child: HeroTagClaim(
                    tag: HeroTag.category(category.id),
                    child: TerracottaImage(
                      image: category.image,
                      fit: BoxFit.contain,
                      backgroundColor: Colors.transparent,
                    ),
                  ),
                ),
                SizedBox(height: spacing.xs),
                HeroTagClaim(
                  tag: HeroTag.categoryTitle(category.id),
                  // MARQUEE. The names are the studio's — «مباخر
                  // وبخور» does not fit a 78-point tile — and this
                  // rail has one line to say them in, so an ellipsis
                  // hides exactly the part that tells one category
                  // from another. `GlobalMarquee` only moves when the
                  // content actually overflows, so a short name costs
                  // nothing.
                  child: GlobalMarquee(
                    semanticLabel: category.title,
                    child: Text(
                      category.title,
                      maxLines: 1,
                      softWrap: false,
                      style: context.textTheme.bodySmall,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// One tile in the strip, from either payload.
///
/// The home rail and the shop's send the same three facts under
/// different types. This is where they meet.
@immutable
class CategoryTile {
  const CategoryTile({required this.id, required this.title, this.image});

  factory CategoryTile.fromHome(HomeCategory c) =>
      CategoryTile(id: c.id, title: c.title, image: c.image);

  factory CategoryTile.fromShop(ShopCategory c) =>
      CategoryTile(id: c.id, title: c.title, image: c.image);

  final int id;
  final String title;

  /// Nullable: the shop's categories may have none.
  final ApiImage? image;
}
