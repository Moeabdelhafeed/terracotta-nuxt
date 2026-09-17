// Package imports:
import 'package:freezed_annotation/freezed_annotation.dart';

// Project imports:
import '../core/api_image.dart';
import 'home_link_type.dart';

part 'home_banner.freezed.dart';
part 'home_banner.g.dart';

/// One hero card in the home carousel — an element of `data.banners` in
/// `GET /api/home`. Ten in the live capture.
///
/// **[title] is the headline and [label] is the body copy, despite the
/// names.** `label` holds the long sentence ("Every piece is thrown,
/// glazed and fired in our studio.") and `title` the short one
/// ("Handmade in Amman"). Wiring them the obvious way round puts a
/// paragraph in the headline slot.
///
/// **Routing lives in [linkType], not in [ctaText].** See [HomeLinkType]
/// for which of [linkTargetId] / [link] carries the destination for each
/// value, and why an unrecognised type must render as a non-tappable
/// card. Concretely: draw the CTA only when `linkType.isTappable` and
/// [ctaText] is non-null.
///
/// [ctaText] is null on the first captured banner and non-null on the
/// other nine — a banner can be pure artwork with no call to action.
///
/// [linkTargetId] is null for the six banners whose destination is a
/// section rather than a row. [link] is null for nine of ten; only the
/// `external` banner carries a URL. (The inferred schema summary lists
/// `link` as always-null — the sample disagrees and the sample wins.)
///
/// [image] is the artwork; paint `image.display`, never `image.url`.
@freezed
abstract class HomeBanner with _$HomeBanner {
  const factory HomeBanner({
    required int id,

    /// **Body copy**, not a caption — the long line.
    required String label,

    /// **Headline** — the short line.
    required String title,

    /// CTA button label. Null when the banner is not a call to action.
    String? ctaText,

    /// Where the banner goes. See [HomeLinkType].
    @JsonKey(fromJson: HomeLinkType.fromWire, toJson: homeLinkTypeToWire)
    required HomeLinkType linkType,

    /// CMS id of the destination row, for the id-carrying link types.
    /// Null for section-level and external destinations.
    int? linkTargetId,

    /// Absolute off-app URL. Non-null only for `external`.
    String? link,

    /// Banner artwork.
    ApiImage? image,
  }) = _HomeBanner;

  factory HomeBanner.fromJson(Map<String, dynamic> json) =>
      _$HomeBannerFromJson(json);
}
