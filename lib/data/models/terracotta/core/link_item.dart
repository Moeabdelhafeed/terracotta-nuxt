// Package imports:
import 'package:freezed_annotation/freezed_annotation.dart';

// Project imports:
import 'api_image.dart';

part 'link_item.freezed.dart';
part 'link_item.g.dart';

/// One outbound link with an icon — the repeated element of every group
/// in `GET /api/app-settings`.
///
/// The settings payload is a map of named lists, and every list holds
/// this identical shape: `social`, `contact`, `app_store`,
/// `google_play`, `app_gallery`, `business`. A group can legitimately be
/// an empty list (`business` is, in the live capture), so render the
/// section only when its list is non-empty.
///
/// [url] is whatever the CMS put there and is NOT always `https` — the
/// live sample mixes `https://instagram.com/...`, `https://wa.me/...`
/// and `mailto:hello@terracotta.test`. Hand it to `launchUrl` with
/// `LaunchMode.externalApplication` rather than an in-app webview, or
/// the `mailto:` and `tel:` entries will fail to open.
///
/// [text] is the already-localized label the CMS returns for the
/// requested locale — display it as-is, do not look it up in the ARB.
///
/// [image] is the icon; paint it via `image.display`, never
/// `image.url` (that path is relative and 404s).
///
/// All four keys are present and non-null in every captured group entry.
@freezed
abstract class LinkItem with _$LinkItem {
  const factory LinkItem({
    required int id,
    required String text,
    required String url,
    required ApiImage image,
  }) = _LinkItem;

  factory LinkItem.fromJson(Map<String, dynamic> json) =>
      _$LinkItemFromJson(json);
}
