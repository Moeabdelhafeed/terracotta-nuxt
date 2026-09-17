// Project imports:
import '../../core/flavor/flavor_config.dart';
import '../api/calls/content_apis.dart';
import '../models/common/language/language.dart';
// The Terracotta catalog has its OWN `Language` — different fields, and
// `direction` is an enum there rather than a raw string. Aliased so the
// two never get confused; `_fromApi` is the only bridge between them.
import '../models/terracotta/content/language.dart' as api;

/// In-memory catalog of supported languages. Backed by the hardcoded
/// fallback below; `init()` attempts to refresh from the backend (any
/// failure leaves the fallback intact — `ContentApis.getLanguages`
/// does not throw). Not reactive — persisted user language lives in
/// `PreferencesCubit`, so widgets subscribe there instead.
class LanguagesService {
  List<Language> languages = const [
    Language(
      id: 1,
      name: 'English',
      locale: 'en',
      direction: 'ltr',
      flag: '🇺🇸',
      isDefault: true,
    ),
    Language(
      id: 2,
      // Native name — a language list is self-identifying: an Arabic
      // speaker on an English UI must still find their language.
      name: 'العربية',
      locale: 'ar',
      direction: 'rtl',
      flag: '🇸🇦',
      isDefault: false,
    ),
  ];

  Language get defaultLanguage => languages.firstWhere(
    (language) => language.isDefault == true,
    orElse: () => languages.firstWhere((language) => language.locale == 'en'),
  );

  Future<void> getLanguages() async {
    final result = await ContentApis.getLanguages();
    result.onSuccess((langs) {
      final previous = languages;
      languages = [for (final l in langs) _fromApi(l, previous)];
    });
  }

  /// Maps the Terracotta catalog entry onto the common [Language] this
  /// service and its consumers speak.
  ///
  /// Two deliberate choices:
  /// - `name` takes the API's **native** name, matching the bundled
  ///   fallback — a language list is self-identifying, so an Arabic
  ///   speaker on an English UI still finds العربية.
  /// - `flag` is carried over from [previous] when the locale matches.
  ///   The API's `image` is null for every language in the live
  ///   capture, and dropping the emoji would blank the picker on the
  ///   first successful refresh.
  static Language _fromApi(api.Language l, List<Language> previous) {
    String? flag;
    for (final existing in previous) {
      if (existing.locale == l.code) {
        flag = existing.flag;
        break;
      }
    }
    return Language(
      id: l.id,
      locale: l.code,
      name: l.nativeName,
      direction: l.direction.wire,
      flag: flag,
      isDefault: l.isDefault,
    );
  }

  Future<LanguagesService> init() async {
    // Skip the network round-trip when remote translations are disabled —
    // the hardcoded fallback above is the source of truth in that mode.
    if (!FlavorConfig.instance.useRemoteTranslations) return this;
    await getLanguages();
    return this;
  }
}
