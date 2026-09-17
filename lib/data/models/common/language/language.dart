// Package imports:
import 'package:freezed_annotation/freezed_annotation.dart';

part 'language.freezed.dart';
part 'language.g.dart';

/// A language the app supports. Powers the locale picker, drives
/// ARB selection via `S.delegate`, and gates RTL layout through
/// [direction].
///
/// Required:
/// - [id] — backend primary key (needed for the languages API).
/// - [locale] — BCP-47 tag (`'en'`, `'ar'`, `'en-US'`).
///
/// Defaults:
/// - [isDefault] = `false` — exactly one language in the list should
///   flip this to `true`; the rest stay false.
/// - [status] = `true` — enabled by default; backends can disable a
///   language server-side by sending `false`.
///
/// [direction] is `'ltr'` or `'rtl'`; consumers (e.g.
/// [LocaleController.isRtl]) check this string.
@freezed
abstract class Language with _$Language {
  const factory Language({
    required int id,
    required String locale,
    String? name,
    String? direction,
    String? flag,
    @Default(false) bool isDefault,
    @Default(true) bool status,
  }) = _Language;

  factory Language.fromJson(Map<String, dynamic> json) =>
      _$LanguageFromJson(json);
}

/// The country an emoji flag stands for.
///
/// The seed carries flags as regional-indicator pairs (`'🇸🇦'`), and
/// those TOFU on several newer iOS models — so nothing in the app
/// paints them directly any more. Both the language dropdown and the
/// language picker recover the ISO code and hand it to
/// `CountryFlagImage` instead; this lives on the model so there is one
/// copy of the arithmetic rather than one per caller.
extension LanguageFlagIso on Language {
  /// `'🇸🇦'` → `'SA'`. Null when the flag is missing or not a
  /// regional-indicator pair.
  String? get flagIsoCode {
    final value = flag;
    if (value == null) return null;
    final runes = value.runes.toList();
    if (runes.length != 2) return null;
    const base = 0x1F1E6; // regional indicator 'A'
    final a = runes[0] - base;
    final b = runes[1] - base;
    if (a < 0 || a > 25 || b < 0 || b > 25) return null;
    return String.fromCharCodes([65 + a, 65 + b]);
  }
}
