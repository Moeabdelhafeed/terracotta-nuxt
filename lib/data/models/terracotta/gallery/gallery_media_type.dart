/// The kind of media one gallery entry holds — the `type` discriminator
/// on every element of `data.items` in `GET /api/gallery/{id}`.
///
/// The live capture only ever contains `"image"`, but the album itself
/// reports a `videos_count`, so the API plainly models a second kind
/// this capture does not happen to include. Treat the wire value as an
/// open set: [fromWire] maps anything it does not recognise — a null, a
/// typo, a kind the CMS grows next quarter — to [unknown] rather than
/// throwing, because a shipped app must render the rest of the album
/// instead of failing to parse the response.
///
/// [unknown] is a "skip me" signal, not a synonym for [image]. Guessing
/// `image` for an unrecognised kind would paint a media item whose bytes
/// are not an image; drop the tile instead.
enum GalleryMediaType {
  /// A still image. `item.image` carries the `ApiImage` to paint.
  image('image'),

  /// A video. Counted by the album's `videos_count`; no live capture
  /// includes one, so the payload it carries alongside `type` is not
  /// yet known — see `GalleryMediaItem.image`.
  video('video'),

  /// A kind this build does not understand. Skip the item.
  unknown('unknown');

  const GalleryMediaType(this.wire);

  /// The exact string the API sends for this kind.
  final String wire;

  /// Parse a wire value, falling back to [unknown] for null, absent, or
  /// unrecognised input. Never throws.
  static GalleryMediaType fromWire(String? wire) {
    for (final type in GalleryMediaType.values) {
      if (type.wire == wire) return type;
    }
    return GalleryMediaType.unknown;
  }
}

/// Serialize a [GalleryMediaType] back to its wire string.
///
/// Referenced by `@JsonKey(toJson:)` — json_serializable needs a
/// top-level function, not a getter tear-off.
String galleryMediaTypeToWire(GalleryMediaType type) => type.wire;
