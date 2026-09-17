import 'dart:ui';

import 'package:flutter/material.dart';

import '../../../core/extensions/context_extensions.dart';
import '../../../core/extensions/theme_colors_extension.dart';
import '../../../core/localization/number_formatter.dart';
import '../../../core/localization/strings/gallery_strings.dart';
import '../../../core/tokens/extensions.dart';
import '../../../data/models/terracotta/core/api_image.dart';
import '../../../shared/module/container/container_corner_scope.dart';
import '../../_shared/terracotta_image.dart';

/// One album in the masonry grid.
///
/// A photograph under a BLUR that covers the whole of it, carrying the
/// album's name and what is inside it. The blur is what makes the white
/// type legible over a picture nobody chose for its contrast — a flat
/// scrim either darkens a bright photo too little or a dark one too
/// much, and the covers are whatever the studio uploaded.
///
/// Full-cover rather than a band: the cover is a mood, not a photograph
/// anyone is asked to read, and the album's name is the thing being
/// chosen from.
class AlbumTile extends StatelessWidget {
  const AlbumTile({
    this.cover,
    this.title = '',
    this.photos = 0,
    this.videos = 0,
    this.onTap,
    super.key,
  });

  /// Painted through [ApiImage.display] — `url` alone is relative to
  /// the storage host and renders as a broken image.
  final ApiImage? cover;

  final String title;
  final int photos;
  final int videos;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final spacing = context.spacing;

    // The grid rounds the BLOCK, not each tile, and says which corners
    // this one owns through a `ContainerCornerScope`. That scope is
    // read by `GlobalContainer` and by nothing else — a tile that clips
    // itself has to ask for it, or `unifyTiles` silently does nothing
    // here and every tile keeps all four corners.
    final corners =
        ContainerCornerScope.maybeOf(context) ??
        BorderRadius.circular(context.radii.md);

    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: corners,
        // WITH A SAVE LAYER, because of the `BackdropFilter` below.
        //
        // A plain antialiased clip does not contain one: the filter
        // paints its own layer and the rounded corners come back
        // SQUARE. It only looked right while something above happened
        // to be compositing already — an entrance animation mid-fade —
        // which is why the corners survived the first paint of the
        // grid and were lost the moment it settled, or replayed on a
        // language change.
        clipBehavior: Clip.antiAliasWithSaveLayer,
        // NO height of its own. The masonry grid positions each tile at
        // the height its extractor returned, and a tile that also
        // imposed one would be laid out at one size and drawn at
        // another the moment the two rules drifted apart.
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (cover != null)
              TerracottaImage(image: cover)
            else
              ColoredBox(color: context.backgroundColors.container),

            // The overlay, across the WHOLE tile.
            //
            // `Positioned.fill` and not an `Align`: a `BackdropFilter`
            // blurs exactly the area it occupies, so its size IS the
            // extent of the effect. Sized to a band it frosts a band.
            //
            // The enclosing `ClipRRect` is what keeps it honest — a
            // `BackdropFilter` samples the layer painted behind it,
            // which in a scrolling grid is the page and the neighbouring
            // tiles, and unclipped it would drag their colours in past
            // its own edges.
            Positioned.fill(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    // A little dark on top of the blur. Blur alone
                    // averages a photo rather than darkening it, so
                    // white type over a pale cover still fails.
                    color: context.overlayColors.scrim.withValues(
                      alpha: 0.28,
                    ),
                  ),
                  child: Padding(
                    padding: EdgeInsets.all(spacing.sm),
                    child: Column(
                      // CENTRED in both axes now that the overlay is
                      // the whole tile — the words are what the tile is
                      // for.
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          title,
                          maxLines: 2,
                          textAlign: TextAlign.center,
                          overflow: TextOverflow.ellipsis,
                          style: context.textTheme.titleMedium?.copyWith(
                            color: context.textColors.onPrimary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        // An album with nothing in it gets no line at
                        // all — not a blank one holding its space.
                        if (_counts() case final counts
                            when counts.isNotEmpty) ...[
                          SizedBox(height: spacing.xs),
                          Text(
                            counts,
                            maxLines: 1,
                            textAlign: TextAlign.center,
                            overflow: TextOverflow.ellipsis,
                            style: context.textTheme.labelMedium?.copyWith(
                              color: context.textColors.onPrimary,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// «١٠ صور · ١١ فيديو», or one half of it, or nothing.
  ///
  /// The whole sentence goes through `localizeDigits` rather than each
  /// number separately: the ARB interpolates the counts itself, and
  /// plain `ar` renders them in WESTERN digits — a Latin numeral in an
  /// Arabic caption, the same bug the home screen's booking line had.
  ///
  /// Which of the three sentences it is, is [GalleryStrings.counts]'s
  /// business; empty means the album holds nothing.
  String _counts() =>
      AppNumbers.localizeDigits(GalleryStrings.counts(photos, videos));
}
