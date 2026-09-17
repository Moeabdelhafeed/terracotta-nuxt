// Package imports:
import 'package:freezed_annotation/freezed_annotation.dart';

// Project imports:
import '../core/link_item.dart';

part 'app_settings.freezed.dart';
part 'app_settings.g.dart';

/// The whole of `GET /api/app-settings` — six named groups of outbound
/// links, and nothing else.
///
/// This payload is not a settings *object* in the usual sense: there are
/// no flags, no toggles, no feature switches. It is a map whose every
/// value is a list of the identical [LinkItem] shape (icon + label +
/// url), and the group name is the only thing that distinguishes a
/// social handle from a store badge. Read it once at boot and feed it to
/// the "about"/"contact us" surfaces.
///
/// **A group can legitimately be empty.** `business` is `[]` in the live
/// capture. Render each section only when its list is non-empty, or the
/// contact sheet grows a headed section with nothing under it.
///
/// [contact] mixes schemes — the capture holds a `https://wa.me/...`
/// alongside a `mailto:`. See [LinkItem] for why every one of these must
/// go to `launchUrl(..., LaunchMode.externalApplication)` rather than an
/// in-app webview.
///
/// [appStore] / [googlePlay] / [appGallery] are three separate groups
/// rather than one "download" list, so a build can show only the badge
/// for the store it shipped to. All six keys are present in the live
/// capture, so all six are required.
@freezed
abstract class AppSettings with _$AppSettings {
  const factory AppSettings({
    /// Social profiles — Instagram, TikTok in the capture.
    @JsonKey(fromJson: readLinks)
    required List<LinkItem> social,

    /// Ways to reach the studio. Mixed schemes (`https:`, `mailto:`).
    @JsonKey(fromJson: readLinks)
    required List<LinkItem> contact,

    /// Apple App Store badge/link.
    @JsonKey(fromJson: readLinks)
    required List<LinkItem> appStore,

    /// Google Play badge/link.
    @JsonKey(fromJson: readLinks)
    required List<LinkItem> googlePlay,

    /// Huawei AppGallery badge/link.
    @JsonKey(fromJson: readLinks)
    required List<LinkItem> appGallery,

    /// Business / corporate links. **Empty in the live capture** —
    /// check `isNotEmpty` before drawing a section for it.
    @JsonKey(fromJson: readLinks)
    required List<LinkItem> business,
  }) = _AppSettings;

  factory AppSettings.fromJson(Map<String, dynamic> json) =>
      _$AppSettingsFromJson(json);
}

/// A block of links, whichever shape PHP gave it.
///
/// **An empty one arrives as `{}`, not `[]`** — or the other way
/// round, depending on the block. PHP has one array type and Laravel's
/// encoder cannot tell an empty map from an empty list, so any block
/// the studio has not filled can come back as either. Both mean
/// "nothing here".
///
/// A row this build cannot read is dropped rather than thrown over:
/// losing the studio's phone number because one social icon is odd is
/// the failure that actually costs something.
List<LinkItem> readLinks(Object? json) {
  if (json is! List) return const [];

  final out = <LinkItem>[];
  for (final row in json) {
    if (row is! Map) continue;
    try {
      out.add(LinkItem.fromJson(row.map((k, v) => MapEntry(k.toString(), v))));
    } on Object {
      continue;
    }
  }
  return out;
}

/// The business block, whichever shape PHP gave it — see [readLinks].
Map<String, dynamic> readBusiness(Object? json) {
  if (json is! Map) return const {};
  return json.map((k, v) => MapEntry(k.toString(), v));
}
