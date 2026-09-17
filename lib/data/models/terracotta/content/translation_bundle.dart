// Package imports:
import 'package:freezed_annotation/freezed_annotation.dart';

part 'translation_bundle.freezed.dart';
part 'translation_bundle.g.dart';

/// The whole of `GET /api/translations` — the remote string overrides
/// for one group in one locale, feeding `RemoteTranslations` so `Tr.t`
/// can beat the ARB fallback.
///
/// **TRAP — [translations] arrives as `[]`, not `{}`, when it is
/// empty.** That is exactly what the live capture contains, and it is
/// PHP's doing: `json_encode` renders an empty associative array as a
/// JSON *array*. The moment the CMS gains one override the same key
/// becomes an object of `key → string`. A plain `Map<String, String>`
/// field therefore parses fine in every environment that has overrides
/// and throws a cast error in every environment that does not — which
/// is the one you develop against.
///
/// [_translationsFromJson] absorbs both encodings and anything else
/// unexpected, yielding an empty map rather than throwing. Never widen
/// the field's type to `dynamic` to dodge this; callers want a map.
///
/// [group] and [locale] are echoed from the request (`"app"`, `"en"`).
/// Check [locale] before applying the bundle — a cached response for the
/// previous language will otherwise overwrite the current one's strings.
@freezed
abstract class TranslationBundle with _$TranslationBundle {
  const factory TranslationBundle({
    /// The namespace requested, echoed back. `"app"` live.
    required String group,

    /// The locale these strings are for, echoed back. `"en"` live.
    required String locale,

    /// key → translated string. **Empty in the live capture, where the
    /// API sends `[]` rather than `{}`.**
    @JsonKey(fromJson: _translationsFromJson, toJson: _translationsToJson)
    required Map<String, String> translations,
  }) = _TranslationBundle;

  const TranslationBundle._();

  factory TranslationBundle.fromJson(Map<String, dynamic> json) =>
      _$TranslationBundleFromJson(json);

  /// Whether this bundle actually overrides anything.
  bool get hasOverrides => translations.isNotEmpty;
}

/// Decode `translations` from either encoding the API uses.
///
/// A populated bundle is a JSON object; an empty one is a JSON array
/// (`[]`), because PHP cannot tell an empty map from an empty list.
/// Anything else — null, a string, a populated array — yields an empty
/// map rather than throwing: losing remote overrides degrades to the ARB
/// fallback, while throwing loses the whole response.
Map<String, String> _translationsFromJson(Object? json) {
  if (json is Map) {
    return <String, String>{
      for (final entry in json.entries)
        entry.key.toString(): entry.value?.toString() ?? '',
    };
  }
  return const <String, String>{};
}

/// Encode `translations` back out. Always an object — the `[]` form is
/// something we tolerate on the way in, not something we reproduce.
Map<String, String> _translationsToJson(Map<String, String> value) => value;
