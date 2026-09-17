// Package imports:
import 'package:freezed_annotation/freezed_annotation.dart';

// Project imports:
import '../core/api_image.dart';
import 'language_direction.dart';

part 'language.freezed.dart';
part 'language.g.dart';

/// One locale the Terracotta backend serves — an element of the list in
/// `GET /api/languages`.
///
/// **NOT the same type as `data/models/common/language/language.dart`.**
/// That one is base-app scaffolding for the locale picker and keys off
/// `locale` + `flag`; this one is the live API shape and keys off [code]
/// + [image]. Never import both files into one library — the class names
/// collide. Migrate the picker onto this model, or rename that one.
///
/// [code] is the BCP-47 tag the rest of the API expects in the
/// `Accept-Language` header / `?lang=` query (`"en"`, `"ar"`). It is the
/// identifier; [id] is only the CMS row key.
///
/// [name] is the language named in the *requested* locale ("Arabic"),
/// [nativeName] is the language named in *itself* ("العربية"). A picker
/// shows [nativeName] — a user hunting for their language reads their
/// own script, not yours.
///
/// [isDefault] marks the backend's fallback locale. **It is `ar` in the
/// live capture, not `en`** — do not assume the default is English when
/// seeding first-run state.
///
/// [image] is a flag/badge asset and is **null for every language in the
/// capture**; the CMS simply has not uploaded any. Fall back to a text
/// or built-in flag rather than reserving space for an icon that is not
/// coming.
@freezed
abstract class Language with _$Language {
  const factory Language({
    required int id,

    /// BCP-47 tag — `"en"`, `"ar"`. The value every other endpoint wants.
    required String code,

    /// The language named in the requested locale ("Arabic").
    required String name,

    /// The language named in itself ("العربية"). Show this in a picker.
    required String nativeName,

    /// Layout direction. Drives `Directionality`; see [LanguageDirection].
    @JsonKey(
      fromJson: LanguageDirection.fromWire,
      toJson: languageDirectionToWire,
    )
    required LanguageDirection direction,

    /// The backend's fallback locale. `ar` in the live capture.
    required bool isDefault,

    /// Flag / badge asset. **Null for every language captured.**
    ApiImage? image,
  }) = _Language;

  factory Language.fromJson(Map<String, dynamic> json) =>
      _$LanguageFromJson(json);
}
