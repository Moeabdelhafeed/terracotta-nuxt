// Package imports:
import 'package:freezed_annotation/freezed_annotation.dart';

// Project imports:
import 'media_item.dart';

part 'media_library.freezed.dart';
part 'media_library.g.dart';

/// The whole of `GET /api/media` — the CMS's override manifest for the
/// app's fixed artwork.
///
/// **[media] is a map of maps, and BOTH levels are open-ended CMS keys,
/// not a schema.** The capture holds three sections — `branding`
/// (`splash_artwork`), `empty_states` (`empty_cart_image`,
/// `empty_bookings_image`) and `onboarding` (`onboarding_1_image`
/// through `onboarding_3_image`) — but nothing in the payload constrains
/// either level, so this is typed as nested maps rather than a model per
/// section. A section or slot the CMS renames simply stops resolving;
/// that is why every lookup needs a bundled fallback.
///
/// Read it through [slot], which tolerates a missing section, a missing
/// key and a slot whose kind this build does not understand, and returns
/// null for all three:
///
/// ```dart
/// final art = library.slot('onboarding', 'onboarding_1_image');
/// final url = art?.image?.display; // null → use the bundled asset
/// ```
///
/// [group] is the manifest namespace the request asked for (`"app"`),
/// echoed back — the same `group` that `GET /api/translations` returns.
@freezed
abstract class MediaLibrary with _$MediaLibrary {
  const factory MediaLibrary({
    /// The manifest namespace, echoed from the request. `"app"` live.
    required String group,

    /// section name → slot name → asset. Both key levels are CMS-owned.
    ///
    /// **An EMPTY one arrives as `[]`, not `{}`.** PHP has one array
    /// type and Laravel's JSON encoder cannot tell an empty map from
    /// an empty list, so a CMS with no media at all answers
    /// `"media": []` — which failed the `Map` cast and took the whole
    /// library down with it. That is precisely the state this feature
    /// exists to bootstrap out of: nothing loaded, so nothing seeded,
    /// so nothing ever loaded. [readSections] reads either shape.
    @JsonKey(fromJson: readSections)
    required Map<String, Map<String, MediaItem>> media,
  }) = _MediaLibrary;

  const MediaLibrary._();

  factory MediaLibrary.fromJson(Map<String, dynamic> json) =>
      _$MediaLibraryFromJson(json);

  /// The slot at `section`/`key`, or null when the CMS does not carry
  /// it. Never throws — a missing section and a missing key both give
  /// null, and the caller falls back to the bundled asset.
  MediaItem? slot(String section, String key) => media[section]?[key];
}

/// `media` off the wire, whichever shape PHP gave it.
///
/// `[]` and `{}` both mean "nothing here" — see [MediaLibrary.media].
/// The same is true one level down: a SECTION with no slots in it
/// arrives as `[]` too.
///
/// Total by design. A slot whose shape this build does not understand
/// is dropped rather than thrown over: the caller has a bundled
/// fallback for every one of these, and losing the whole manifest
/// because one entry is odd is the failure that is actually expensive.
Map<String, Map<String, MediaItem>> readSections(Object? json) {
  if (json is! Map) return const {};

  final out = <String, Map<String, MediaItem>>{};
  for (final section in json.entries) {
    final slots = section.value;
    if (slots is! Map) continue;

    final parsed = <String, MediaItem>{};
    for (final slot in slots.entries) {
      final value = slot.value;
      // Any MAP, not `Map<String, dynamic>` exactly — a decoded
      // payload gives the latter, but a literal in a test does not,
      // and the difference is not one this reader should care about.
      if (value is! Map) continue;
      try {
        parsed[slot.key.toString()] = MediaItem.fromJson(
          value.map((k, v) => MapEntry(k.toString(), v)),
        );
      } on Object {
        // A kind this build does not know. The bundled asset stands.
        continue;
      }
    }
    out[section.key.toString()] = parsed;
  }
  return out;
}
