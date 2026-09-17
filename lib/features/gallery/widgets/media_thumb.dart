import 'package:flutter/material.dart';

import '../../../core/extensions/theme_colors_extension.dart';
import '../../../core/tokens/extensions.dart';
import '../../../data/models/terracotta/gallery/gallery_media_item.dart';
import '../../../shared/module/container/container_corner_scope.dart';
import '../../_shared/terracotta_image.dart';

/// One piece of media in an opened album — the THUMBNAIL only.
///
/// No caption, no counts, no scrim: the album sheet is a contact sheet,
/// and the picture is the whole content of the cell. What the album
/// list draws over its covers belongs to the list, where the words are
/// the thing being chosen between.
///
/// A video gets a play badge. It gets one whether or not a poster
/// arrived — the badge is what says "this one moves", and a video with
/// no poster is exactly the case where nothing else would.
class MediaThumb extends StatelessWidget {
  const MediaThumb({required this.item, this.onTap, super.key});

  final GalleryMediaItem item;
  final VoidCallback? onTap;

  /// Big enough to read as an affordance at a third of the sheet's
  /// width, small enough not to hide the frame behind it.
  static const _badge = 36.0;

  @override
  Widget build(BuildContext context) {
    final image = item.image;

    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        // The grid rounds the BLOCK and says which corners this cell
        // owns through a `ContainerCornerScope`. Only `GlobalContainer`
        // reads that scope on its own — a cell that clips itself has to
        // ask, or `unifyTiles` silently does nothing.
        borderRadius:
            ContainerCornerScope.maybeOf(context) ??
            BorderRadius.circular(context.radii.md),
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (image != null)
              TerracottaImage(image: image)
            else
              ColoredBox(color: context.backgroundColors.container),

            if (item.isVideo)
              // Over a scrim, not bare: the glyph is white and a pale
              // frame would swallow it.
              ColoredBox(
                color: context.overlayColors.scrim.withValues(alpha: 0.2),
                child: Center(
                  child: Icon(
                    Icons.play_circle_fill_rounded,
                    size: _badge,
                    color: context.textColors.onPrimary,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
