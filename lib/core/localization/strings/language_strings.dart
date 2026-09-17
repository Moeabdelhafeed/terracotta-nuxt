import '../../../generated/l10n.dart';
import '../tr.dart';

/// Strings for the `language_` key prefix family — localized display
/// names of the app's supported languages ("Arabic" on an English UI,
/// "الإنجليزية" on an Arabic one).
class LanguageStrings {
  LanguageStrings._();

  static String get english =>
      Tr.t('language.name_en', S.current.language_name_en);
  static String get arabic =>
      Tr.t('language.name_ar', S.current.language_name_ar);

  /// Localized display name for a supported [locale] code; null for
  /// locales the app has no translation for (callers fall back to the
  /// language's native name).
  static String? nameFor(String locale) => switch (locale) {
    'en' => english,
    'ar' => arabic,
    _ => null,
  };
}
