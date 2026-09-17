import 'package:flutter/material.dart';

import '../../core/extensions/context_extensions.dart';
import '../../core/extensions/theme_colors_extension.dart';
import '../../core/tokens/extensions.dart';
import '../../data/models/terracotta/core/api_image.dart';
import '../workshops/widgets/gift_backdrop.dart';
import 'shared_hero.dart';
import 'terracotta_image.dart';
import 'terracotta_widgets.dart';

/// One tile in the category rail — bordered when it is not the current
/// filter, and the brand's brown with the drawn loop behind it when it
/// is.
///
/// The loop is the gift tile's backdrop, reused: it is the app's one
/// piece of texture for "this surface is the chosen one", and drawing
/// a second would be a second thing to keep in step.
class CategoryChip extends StatelessWidget {
  const CategoryChip({
    required this.label,
    this.heroId,
    required this.selected,
    this.image,
    this.onTap,
    this.tint,
    super.key,
  });

  final String label;
  final bool selected;

  /// Null on every live category today, so the tile has to read from
  /// its words alone.
  final ApiImage? image;

  /// The CATEGORY this chip stands for, when it stands for one.
  ///
  /// The home and shop rails draw the same category as a tile, and it
  /// flies into this chip — the artwork and the name are the same two
  /// things in a different shape. Null on the chips that are not
  /// categories (the piece-selection rail reuses this widget), and
  /// then nothing flies.
  final int? heroId;

  final VoidCallback? onTap;

  /// What a CHOSEN tile is filled with. Null is the brand's brown —
  /// the shop's own colour. The booking flow passes the workshop
  /// family's hue instead, because every screen from the workshop card
  /// to the confirmation is re-themed by it.
  final Color? tint;

  static const _artBox = 42.0;

  @override
  Widget build(BuildContext context) {
    final onBrown = context.textColors.onPrimary;
    final ink = selected ? onBrown : context.textColors.primary;
    final fill = tint ?? context.primaryColors.primary;

    return SizedBox(
      width: 88,
      child: TerracottaCard(
        onTap: onTap,
        bordered: !selected,
        color: selected ? fill : Colors.transparent,
        padding: EdgeInsets.symmetric(
          horizontal: context.spacing.xs,
          vertical: context.spacing.sm,
        ),
        child: Stack(
          fit: StackFit.passthrough,
          children: [
            if (selected)
              Positioned.fill(
                child: GiftBackdrop(
                  tint: onBrown.withValues(alpha: 0.45),
                ),
              ),
            Column(
              mainAxisSize: MainAxisSize.min,
              // CENTRED in the rail's height. Left at the default the
              // words sat against the top of the tile with the whole
              // gap under them.
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (image != null)
                  SizedBox.square(
                    dimension: _artBox,
                    child: switch (heroId) {
                      final id? => HeroTagClaim(
                        tag: HeroTag.category(id),
                        child: TerracottaImage(
                          image: image,
                          fit: BoxFit.contain,
                        ),
                      ),
                      null => TerracottaImage(
                        image: image,
                        fit: BoxFit.contain,
                      ),
                    },
                  ),
                if (image != null) SizedBox(height: context.spacing.xs),
                switch (heroId) {
                  final id? => HeroTagClaim(
                    tag: HeroTag.categoryTitle(id),
                    child: _Label(label: label, ink: ink, selected: selected),
                  ),
                  null => _Label(label: label, ink: ink, selected: selected),
                },
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// A sub-category, as a pill. Narrower than a [CategoryChip] and with
/// no artwork — it is a refinement of the choice above it, not a
/// destination of its own.
class SubCategoryChip extends StatelessWidget {
  const SubCategoryChip({
    required this.label,
    required this.selected,
    this.onTap,
    this.tint,
    super.key,
  });

  final String label;
  final bool selected;
  final VoidCallback? onTap;

  /// See [CategoryChip.tint].
  final Color? tint;

  /// Narrow enough to read as a square, and to fit three across a
  /// phone. The label wraps to two lines rather than the tile widening
  /// to hold it on one.
  static const _width = 96.0;

  @override
  Widget build(BuildContext context) {
    final onBrown = context.textColors.onPrimary;
    final fill = tint ?? context.primaryColors.primary;

    return SizedBox(
      width: _width,
      child: TerracottaCard(
        onTap: onTap,
        bordered: !selected,
        color: selected ? fill : Colors.transparent,
        // Horizontal only. The rail gives every chip the same height,
        // so vertical padding here just shrank the box the words are
        // centred in — it did not move them.
        padding: EdgeInsets.symmetric(horizontal: context.spacing.xs),
        child: Stack(
          alignment: Alignment.center,
          fit: StackFit.passthrough,
          children: [
            // The same drawn loop the category above wears when chosen.
            if (selected)
              Positioned.fill(
                child: GiftBackdrop(
                  tint: onBrown.withValues(alpha: 0.45),
                  // Measured, not reasoned: on a 96 × 44 chip these two
                  // numbers lay down the most ink of anything that does
                  // not distort the drawing. Scale and fit pull against
                  // each other — a bigger box crops harder — so at the
                  // gift tile's 1.3 `cover` was far WORSE than
                  // `contain`, and at 1.0 it is better. See
                  // `gift_backdrop_test`.
                  scale: 1,
                  fit: BoxFit.cover,
                ),
              ),
            // Centred by the `Center`, not by the Stack's alignment:
            // `StackFit.passthrough` hands a non-positioned child the
            // Stack's own constraints, and under the rail's tight
            // height that pins the text to the top whatever the
            // alignment says.
            Center(
              child: Text(
                label,
                // TWO lines. «أكواب اسبريسو» is two words, and one line
                // is what made these tiles as wide as a sentence.
                maxLines: 2,
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
                style: context.textTheme.bodyMedium?.copyWith(
                  color: selected ? onBrown : context.textColors.primary,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The chip's own words, so the hero above has one child to carry.
class _Label extends StatelessWidget {
  const _Label({
    required this.label,
    required this.ink,
    required this.selected,
  });

  final String label;
  final Color ink;
  final bool selected;

  @override
  Widget build(BuildContext context) => Text(
    label,
    // TWO LINES and an ellipsis, not a marquee.
    //
    // This chip is a FILTER the reader is choosing between, and it has
    // the height for a second line — a name that scrolls past while
    // they are comparing four of them is harder to read, not easier.
    // The home and shop rails are the ones that marquee: their tile is
    // one line tall and 78 points wide.
    maxLines: 2,
    textAlign: TextAlign.center,
    overflow: TextOverflow.ellipsis,
    style: context.textTheme.labelLarge?.copyWith(
      color: ink,
      fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
    ),
  );
}
