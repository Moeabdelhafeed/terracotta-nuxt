/// Where a home banner sends the user — the `link_type` discriminator on
/// every element of `data.banners` in `GET /api/home`.
///
/// The capture exercises all ten values, one banner each, which is the
/// CMS demonstrating its whole routing vocabulary rather than a real
/// merchandising plan. Read it as an **open set anyway**: this is the
/// field a CMS grows when a new section ships, and a shipped app must
/// render the banner it cannot route rather than fail to parse the
/// entire home screen.
///
/// **[none] is both a real wire value and the fallback**, and that is
/// deliberate: an unrecognised link type degrades to "this banner is not
/// tappable", which is exactly what `"none"` already means. The cost is
/// that a banner whose type this build predates goes quiet instead of
/// crashing.
///
/// **So gate the CTA on the link type, not on `cta_text`.** A banner can
/// carry a perfectly good `cta_text` next to a type this build does not
/// understand; drawing the button anyway gives the user a control that
/// does nothing.
///
/// Which companion field carries the destination depends on the value:
/// - [shopCategory], [shopProduct], [workshop], [galleryCategory],
///   [page] → `link_target_id` (an int CMS id).
/// - [externalUrl] → `link` (an absolute URL).
/// - [shopHome], [workshops], [galleryHome], [none] → neither; the
///   destination is the section itself.
///
/// Note [page] hands you an **int id** while `GET /api/pages/{slug}`
/// wants a **slug** — resolve one against the pages list before routing.
enum HomeLinkType {
  /// Not tappable. Also the fallback for anything unrecognised.
  none('none'),

  /// The shop landing screen. No target.
  shopHome('shop_home'),

  /// A shop category. Target: `link_target_id`.
  shopCategory('shop_category'),

  /// A single product. Target: `link_target_id`.
  shopProduct('shop_product'),

  /// The workshops list. No target.
  workshops('workshops'),

  /// A single workshop. Target: `link_target_id`.
  workshop('workshop'),

  /// The gallery landing screen. No target.
  galleryHome('gallery_home'),

  /// A gallery album. Target: `link_target_id`.
  galleryCategory('gallery_category'),

  /// A CMS page. Target: `link_target_id` — an **id**, not the slug
  /// `GET /api/pages/{slug}` expects.
  page('page'),

  /// An off-app URL. Target: `link`, not `link_target_id`. Named
  /// `externalUrl` because `external` is a Dart modifier keyword and
  /// would be parsed as one at the head of an enum body.
  externalUrl('external');

  const HomeLinkType(this.wire);

  /// The exact string the API sends for this destination.
  final String wire;

  /// Parse a wire value, falling back to [none] for null, absent, or
  /// unrecognised input. Never throws.
  static HomeLinkType fromWire(String? wire) {
    for (final type in HomeLinkType.values) {
      if (type.wire == wire) return type;
    }
    return HomeLinkType.none;
  }

  /// Whether this banner should draw a tappable CTA at all.
  bool get isTappable => this != HomeLinkType.none;
}

/// Serialize a [HomeLinkType] back to its wire string.
///
/// Referenced by `@JsonKey(toJson:)` — json_serializable needs a
/// top-level function, not a getter tear-off.
String homeLinkTypeToWire(HomeLinkType type) => type.wire;
