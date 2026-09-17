// Package imports:
import 'package:freezed_annotation/freezed_annotation.dart';

// Project imports:
import '../core/api_image.dart';
import 'media_item_type.dart';

part 'media_item.freezed.dart';
part 'media_item.g.dart';

/// One CMS-overridable art slot — the leaf value of `data.media` in
/// `GET /api/media`.
///
/// The manifest exists so the studio can re-skin the app's fixed
/// artwork (onboarding pages, empty states, the splash illustration)
/// without a release. Each slot is keyed by name inside a section; see
/// `MediaLibrary`.
///
/// [image] is typed nullable even though all six captured slots carry
/// one, because [type] is an open set: a slot the CMS switches to a kind
/// this build predates has no reason to still carry an `image` key.
/// Pair a null [image] — or a [MediaItemType.unknown] — with the
/// bundled asset for that slot rather than an empty frame.
///
/// Paint `image.display`, never `image.url` — the latter is relative
/// and 404s.
@freezed
abstract class MediaItem with _$MediaItem {
  const factory MediaItem({
    /// What kind of asset this slot holds. See [MediaItemType].
    @JsonKey(fromJson: MediaItemType.fromWire, toJson: mediaItemTypeToWire)
    required MediaItemType type,

    /// The artwork. Present on every captured slot; nullable because a
    /// non-image kind need not carry it.
    ApiImage? image,
  }) = _MediaItem;

  factory MediaItem.fromJson(Map<String, dynamic> json) =>
      _$MediaItemFromJson(json);
}
