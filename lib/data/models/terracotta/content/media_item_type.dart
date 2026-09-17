/// The kind of asset one CMS media slot holds — the `type` discriminator
/// on every leaf of `data.media` in `GET /api/media`.
///
/// Every one of the six captured slots says `"image"`, so this is a
/// one-value set today. It is still an enum with an [unknown] fallback
/// because `type` exists at all only to allow a second kind, and this
/// payload is fetched at boot: a CMS editor swapping a splash slot to a
/// video must not take the whole app's media manifest down with it.
///
/// [unknown] is a "skip me" signal, not a synonym for [image]. Guessing
/// `image` would hand an `Image` widget bytes that are not an image;
/// fall back to the bundled asset for that slot instead.
enum MediaItemType {
  /// A still image. The slot's `image` carries the `ApiImage` to paint.
  image('image'),

  /// A kind this build does not understand. Use the bundled fallback.
  unknown('unknown');

  const MediaItemType(this.wire);

  /// The exact string the API sends for this kind.
  final String wire;

  /// Parse a wire value, falling back to [unknown] for null, absent, or
  /// unrecognised input. Never throws.
  static MediaItemType fromWire(String? wire) {
    for (final type in MediaItemType.values) {
      if (type.wire == wire) return type;
    }
    return MediaItemType.unknown;
  }
}

/// Serialize a [MediaItemType] back to its wire string.
///
/// Referenced by `@JsonKey(toJson:)` — json_serializable needs a
/// top-level function, not a getter tear-off.
String mediaItemTypeToWire(MediaItemType type) => type.wire;
