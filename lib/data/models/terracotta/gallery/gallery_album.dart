// Package imports:
import 'package:freezed_annotation/freezed_annotation.dart';

// Project imports:
import '../core/api_image.dart';

part 'gallery_album.freezed.dart';
part 'gallery_album.g.dart';

/// One album in the gallery index — an element of `data` in
/// `GET /api/gallery` (the API's message calls these "Gallery
/// categories"; they are albums to the user).
///
/// This is the LIST shape and it is deliberately thin: enough to draw a
/// grid tile — a [cover], a [title], and how much is inside. The items
/// themselves only arrive from `GET /api/gallery/{id}`, modelled by
/// `GalleryAlbumDetail`.
///
/// **[cover] EXISTS HERE AND NOWHERE ELSE.** The detail response does
/// NOT repeat it, so a screen that navigates straight into an album by
/// id (a deep link, a push notification) has no header image unless it
/// carries this object through the route or falls back to the first
/// item. Pass the whole [GalleryAlbum] as the route extra.
///
/// Paint the cover via `cover.display`, never `cover.url` — that path
/// is storage-relative and 404s.
///
/// [imagesCount] and [videosCount] are counts of the album's contents,
/// not a page size; `videos_count` is `0` for every album in the live
/// capture but the field is why `GalleryMediaItem` treats its media as
/// optional.
///
/// Nullability follows the capture: all five keys are present and
/// non-null on every album returned. [cover] is the one to watch — an
/// album whose media were all deleted has nothing to derive a cover
/// from, and this API sends `null` for an absent single image elsewhere
/// (`workshop.image`). No captured album is empty, so it is typed
/// `required` per the samples; re-capture with an empty album in the
/// CMS before trusting that in production.
@freezed
abstract class GalleryAlbum with _$GalleryAlbum {
  const factory GalleryAlbum({
    /// Album id — the path segment for `GET /api/gallery/{id}`.
    required int id,

    /// Already-localized album name for the requested locale. Display
    /// as-is; do not look it up in the ARB.
    required String title,

    /// Grid thumbnail. In the capture it is the album's first image.
    required ApiImage cover,

    /// How many still images the album holds.
    required int imagesCount,

    /// How many videos the album holds. `0` throughout the capture.
    required int videosCount,
  }) = _GalleryAlbum;

  const GalleryAlbum._();

  factory GalleryAlbum.fromJson(Map<String, dynamic> json) =>
      _$GalleryAlbumFromJson(json);

  /// Total tiles the detail screen will show — the sum the "6 items"
  /// caption on a grid tile wants.
  int get mediaCount => imagesCount + videosCount;
}
