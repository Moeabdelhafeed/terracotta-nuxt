// Package imports:
import 'package:freezed_annotation/freezed_annotation.dart';

// Project imports:
import 'gallery_media_item.dart';

part 'gallery_album_detail.freezed.dart';
part 'gallery_album_detail.g.dart';

/// One opened album with its media — `data` of
/// `GET /api/gallery/{id}`.
///
/// The same album as `GalleryAlbum`, minus the cover, plus [items].
/// These are two distinct models rather than one optional-field model
/// because the two payloads genuinely differ in both directions.
///
/// **THERE IS NO `cover` HERE.** The list response carries it; the
/// detail response does not. A screen reached by deep link therefore
/// has no header image from this payload alone — pass the
/// `GalleryAlbum` through the route, or fall back to the first item's
/// image.
///
/// [items] is a MIXED list by design — see [GalleryMediaItem], whose
/// media is optional because [videosCount] proves a second kind exists.
/// Every item in the live capture is an image
/// (`videos_count: 0` on all three albums), so the video branch of any
/// UI built here is untested against real data.
///
/// The endpoint is documented as paginated but the live envelope
/// carries no `meta` / `links` and `data` is the bare album object, so
/// there is nothing here to page with. Model pagination only once the
/// server actually sends it.
///
/// Nullability follows the capture: every key present and non-null.
/// [items] stays `required` and non-nullable because this API sends
/// `[]` for an empty collection rather than `null` (see the empty
/// `business` group in `/api/app-settings` and the empty `gallery` on a
/// workshop).
@freezed
abstract class GalleryAlbumDetail with _$GalleryAlbumDetail {
  const factory GalleryAlbumDetail({
    /// Album id — matches `GalleryAlbum.id`.
    required int id,

    /// Already-localized album name for the requested locale.
    required String title,

    /// How many still images the album holds. Should equal the number
    /// of image items in [items] when the whole album is returned.
    required int imagesCount,

    /// How many videos the album holds. `0` throughout the capture.
    required int videosCount,

    /// The album's media, in server order. Empty list, never null.
    required List<GalleryMediaItem> items,
  }) = _GalleryAlbumDetail;

  const GalleryAlbumDetail._();

  factory GalleryAlbumDetail.fromJson(Map<String, dynamic> json) =>
      _$GalleryAlbumDetailFromJson(json);

  /// Total media the album claims to hold, per the server's own counts.
  ///
  /// Compare against `items.length` rather than assuming they match —
  /// they are computed server-side and a filtered or paged response
  /// would make them disagree.
  int get mediaCount => imagesCount + videosCount;

  /// Items this build can actually paint — images with a non-null
  /// media object. Use for the grid so an unknown kind or a video
  /// cannot slip a blank tile in.
  List<GalleryMediaItem> get images =>
      items.where((item) => item.isImage).toList();
}
