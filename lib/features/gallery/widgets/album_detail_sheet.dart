import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/error/app_exception.dart';
import '../../../core/localization/strings/auth_strings.dart';
import '../../../core/localization/strings/common_strings.dart';
import '../../../core/localization/strings/gallery_strings.dart';
import '../../../core/tokens/extensions.dart';
import '../../../data/models/terracotta/gallery/gallery_album.dart';
import '../../../data/models/terracotta/gallery/gallery_media_item.dart';
import '../../../shared/module/buttons/global_filled_button.dart';
import '../../../shared/module/empty_state/global_empty_state.dart';
import '../../../shared/module/grid/global_grid.dart';
import '../../../shared/module/media_picker/media_picker_models.dart';
import '../../../shared/module/media_picker/picker_lightbox.dart';
import '../../../shared/module/sheet/global_sheet.dart';
import '../../_shared/shared_hero.dart';
import '../../_shared/skeleton_block.dart';
import '../../_shared/terracotta_cta_style.dart';
import '../cubits/album_detail_cubit.dart';
import '../cubits/album_detail_state.dart';
import 'masonry_heights.dart';
import 'media_thumb.dart';

/// One album opened — its photographs and films as a contact sheet.
///
/// A BOTTOM SHEET, not a route: the design draws it over the gallery
/// list, which stays visible behind it.
///
/// `GET /api/gallery/{category}`.
class AlbumDetailSheet extends StatefulWidget {
  const AlbumDetailSheet({required this.albumId, this.cubit, super.key});

  final int albumId;

  /// A cubit to use instead of making one — the seam a widget test
  /// needs, since the sheet loads on mount. Null in the app.
  final AlbumDetailCubit? cubit;

  @override
  State<AlbumDetailSheet> createState() => _AlbumDetailSheetState();
}

class _AlbumDetailSheetState extends State<AlbumDetailSheet> {
  /// `load` outside the `??`: an injected cubit has to be loaded too,
  /// or a test fixture is never asked and the sheet measures its own
  /// placeholders.
  late final _album =
      (widget.cubit ?? AlbumDetailCubit(albumId: widget.albumId))..load();

  @override
  void dispose() {
    // Only what this sheet MADE.
    if (widget.cubit == null) unawaited(_album.close());
    super.dispose();
  }

  /// Opens the full-screen viewer the media picker already uses —
  /// swipeable pages, pinch-zoom, drag to dismiss.
  ///
  /// ## Why every page is an IMAGE
  ///
  /// `showPickerLightbox` renders a page from a `PickerItem` plus an
  /// `AttachmentKind`, and a `video` kind hands its url to
  /// `GlobalVideo.network`. The only url a gallery item carries is
  /// `image` — verified against the live server, where all three
  /// albums return items shaped exactly `{id, type, image}` and no
  /// `video` block exists. `getGalleryCategory`'s doc comment claims
  /// one; it is wrong.
  ///
  /// So a video's `image` is its POSTER, and handing a `.png` to a
  /// player fails. Until the wire grows a playable url — at which
  /// point `GalleryMediaItem` needs a field for it and this line
  /// becomes `m.isVideo ? video : image` — a tapped video opens the
  /// still it already shows. The thumbnail still wears its play badge,
  /// because that is what the album says it holds.
  void _openViewer(List<GalleryMediaItem> items, GalleryMediaItem tapped) {
    // Only what there is something to show for.
    final viewable = items.where((m) => m.image != null).toList();
    if (viewable.isEmpty) return;

    unawaited(
      showPickerLightbox(
        context: context,
        items: [for (final m in viewable) PickerItem.url(m.image!.display)],
        kinds: List.filled(viewable.length, AttachmentKind.image),
        initialIndex: viewable.indexOf(tapped).clamp(0, viewable.length - 1),
        // NO NAME over the picture. `serving-plates-1-1-6.jpg` is the
        // CMS's upload slug — it says nothing to a customer and sits
        // on the photograph they opened it to look at. The counter
        // stays: which of two it is, is worth knowing.
        showTitle: false,
        // The tapped photograph FLIES up into the viewer rather than
        // being replaced by it.
        heroTag: tapped.image == null
            ? null
            : HeroTag.photo(tapped.image!.display),
      ),
    );
  }

  @override
  Widget build(BuildContext context) =>
      // ONE SCOPE for the sheet — `HeroTagClaim` hands a tag out at
      // most once, and an album can hold the same file twice.
      HeroScope(
        child: BlocBuilder<AlbumDetailCubit, AlbumDetailState>(
          bloc: _album,
          builder: (context, state) => switch (state) {
            AlbumDetailLoading() => const _MediaSkeleton(),
            AlbumDetailFailed(:final error) => _MediaError(
              error: error,
              onRetry: _album.refresh,
            ),
            AlbumDetailLoaded(:final album) =>
              album.items.isEmpty
                  ? GlobalEmptyState(
                      icon: Icons.photo_library_outlined,
                      title: GalleryStrings.albumEmpty,
                    )
                  : _MediaGrid(
                      items: album.items,
                      onTap: (item) => _openViewer(album.items, item),
                    ),
          },
        ),
      );
}

/// The contact sheet.
class _MediaGrid extends StatelessWidget {
  const _MediaGrid({required this.items, required this.onTap});

  final List<GalleryMediaItem> items;
  final ValueChanged<GalleryMediaItem> onTap;

  @override
  Widget build(BuildContext context) => GlobalGrid<GalleryMediaItem>.static(
    items: items,
    compactColumns: 2,
    // MORE COLUMNS WHEN THERE IS WIDTH. A landscape phone is ~874dp
    // across, which reads as `expanded` — two columns there means two
    // very wide tiles and a screen that shows almost nothing. The
    // buckets are by WIDTH, so a tablet gets the same benefit.
    mediumColumns: 3,
    expandedColumns: 4,
    largeColumns: 5,
    // The sheet's own scroll view is the one that moves — a second
    // scrollable inside it would swallow the drag that dismisses it.
    shrinkWrap: true,
    physics: const NeverScrollableScrollPhysics(),
    style: GridStyle(spacing: context.spacing.sm, unifyTiles: true),
    // The SAME staggered rhythm as the album list underneath, and the
    // same block rounding — the sheet opens on top of that grid, and a
    // second rhythm would read as a different screen.
    tileExtentExtractor: (item, _) => MasonryHeights.forId(item.id),
    itemBuilder: (context, item, index) {
      final thumb = MediaThumb(item: item, onTap: () => onTap(item));
      // The OTHER end of the flight into the full-screen viewer. Claimed
      // rather than wrapped: an album can hold the same file twice, and
      // two heroes with one tag on a screen the reader is already
      // looking at is an assertion.
      return item.image == null
          ? thumb
          : HeroTagClaim(
              tag: HeroTag.photo(item.image!.display),
              child: thumb,
            );
    },
  );
}

/// Six placeholders in the same staggered rhythm, so nothing jumps
/// when the media arrives.
class _MediaSkeleton extends StatelessWidget {
  const _MediaSkeleton();

  @override
  Widget build(BuildContext context) {
    return GlobalGrid<int>.static(
      items: const [0, 1, 2, 3, 4, 5],
      compactColumns: 2,
      // MORE COLUMNS WHEN THERE IS WIDTH. A landscape phone is ~874dp
      // across, which reads as `expanded` — two columns there means two
      // very wide tiles and a screen that shows almost nothing. The
      // buckets are by WIDTH, so a tablet gets the same benefit.
      mediumColumns: 3,
      expandedColumns: 4,
      largeColumns: 5,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      style: GridStyle(spacing: context.spacing.sm, unifyTiles: true),
      // The rhythm the media will land in, so nothing jumps when it
      // does.
      tileExtentExtractor: (item, _) => MasonryHeights.forId(item),
      itemBuilder: (context, item, index) => const SkeletonBlock(),
    );
  }
}

/// Nothing arrived.
class _MediaError extends StatelessWidget {
  const _MediaError({required this.error, required this.onRetry});

  final AppException error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => GlobalEmptyState(
    icon: Icons.wifi_off_rounded,
    title: AuthStrings.errorGeneric,
    // Transport failures carry Dio's wording, which names hosts and
    // sockets and means nothing to a customer.
    subtitle: error is NetworkException ? null : error.message,
    primaryAction: GlobalFilledButton(
      text: CommonStrings.retry,
      onPressed: onRetry,
      style: terracottaCtaStyle(showArrow: false),
    ),
  );
}

/// Opens [AlbumDetailSheet] over the gallery.
///
/// Through `GlobalBottomSheet`, which draws the grab handle, the title
/// row and the close button itself — the sheet body must not draw any
/// of them, or there are two of each.
/// [cubit] is the test seam — the sheet loads on mount and a widget
/// test has no network. Null in the app.
Future<void> showAlbumDetailSheet(
  BuildContext context,
  GalleryAlbum album, {
  AlbumDetailCubit? cubit,
}) => GlobalBottomSheet.show<void>(
  context: context,
  title: album.title,
  // `show` caps itself at 90% of the screen and shrinks to fit
  // content, so a short album is a short sheet.
  content: AlbumDetailSheet(albumId: album.id, cubit: cubit),
);
