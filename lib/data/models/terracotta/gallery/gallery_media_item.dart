// Package imports:
import 'package:freezed_annotation/freezed_annotation.dart';

// Project imports:
import '../core/api_image.dart';
import 'gallery_media_type.dart';

part 'gallery_media_item.freezed.dart';
part 'gallery_media_item.g.dart';

/// One tile inside an opened album — an element of `data.items` in
/// `GET /api/gallery/{id}`, as `GalleryAlbumDetail.items`.
///
/// The shape is a discriminated wrapper: an [id], a [type] naming the
/// kind of media, and the media itself alongside. The same envelope is
/// used by `GET /api/media`, where every branding / onboarding /
/// empty-state slot is also `{type, image}` — so a widget written
/// against this shape works for both.
///
/// **TWO DIFFERENT `type` FIELDS ARE NESTED HERE.** This model's [type]
/// is the media KIND (`"image"`, `"video"`). `image.type` is the file
/// EXTENSION (`"png"`, `"jpg"`). They are unrelated and the JSON puts
/// them one level apart. Never branch on `image.type` to decide whether
/// something is a video.
///
/// **[image] IS NULLABLE ON PURPOSE, AGAINST THE SAMPLE.** Every item
/// in every live capture is `type: "image"` with a populated `image`
/// object, which by the usual rule would make it `required`. It is not,
/// because the album that contains these items reports a `videos_count`
/// — the API itself says a second kind of item exists, and this capture
/// (`videos_count: 0` on all three albums) simply has none of them. A
/// video item cannot plausibly carry an `image` under that key, so a
/// `required` here would parse today's demo content and crash the whole
/// album the first time the CMS uploads a video. Read it defensively:
/// check [type], then null-check [image] before painting.
///
/// Paint via `image.display`, never `image.url` — the latter is a
/// storage-relative path and 404s.
@freezed
abstract class GalleryMediaItem with _$GalleryMediaItem {
  const factory GalleryMediaItem({
    /// The item's own id — NOT the id of the nested image. Both are
    /// present and they differ (item 1 wraps image 33).
    required int id,

    /// The media kind. Unrecognised wire values degrade to
    /// [GalleryMediaType.unknown]; skip those tiles.
    @JsonKey(
      fromJson: GalleryMediaType.fromWire,
      toJson: galleryMediaTypeToWire,
    )
    required GalleryMediaType type,

    /// The still image for an `image` item. Null for any kind that is
    /// not an image — see the class doc.
    ApiImage? image,
  }) = _GalleryMediaItem;

  const GalleryMediaItem._();

  factory GalleryMediaItem.fromJson(Map<String, dynamic> json) =>
      _$GalleryMediaItemFromJson(json);

  /// A still image with bytes to paint. The only case the current
  /// gallery UI can render.
  bool get isImage => type == GalleryMediaType.image && image != null;

  /// A video item. No live capture contains one; the payload it carries
  /// is unverified, so confirm the shape before building a player.
  bool get isVideo => type == GalleryMediaType.video;
}
