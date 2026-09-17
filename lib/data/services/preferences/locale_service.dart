import 'dart:async';

import '../../../core/di/service_locator.dart';
import '../../../core/flavor/flavor_config.dart';
import '../../../core/localization/remote_translations.dart';
import '../../blocs/preferences/preferences_cubit.dart';
import '../../models/common/language/language.dart';

/// Locale service — plain Dart singleton over [PreferencesCubit].
/// Read current language, flip RTL, trigger a full app-locale refresh.
///
/// Registered in `service_locator.dart`. Widget code that only needs
/// to rebuild on language change should prefer
/// `BlocSelector<PreferencesCubit, PreferencesState, Language>` over
/// calling this service directly.
class LocaleService {
  LocaleService(this._prefs);

  final PreferencesCubit _prefs;

  Language get currentLanguage => _prefs.state.language;
  bool get isRtl => currentLanguage.direction == 'rtl';
  String get languageCode => currentLanguage.locale;
  String get localeName => currentLanguage.name ?? 'English';

  Stream<Language> get onLanguageChanged =>
      _prefs.stream.map((s) => s.language).distinct();

  void setLocale(Language language) => _prefs.setLanguage(language);

  /// Change the app language and refresh remote translations. The
  /// `PreferencesCubit` emit drives the `BlocBuilder` around
  /// `MaterialApp.router`, so the new locale takes effect on the
  /// next frame — no `forceAppUpdate`-style rebuild needed.
  Future<void> changeLanguage(Language language) async {
    _prefs.setLanguage(language);
    if (FlavorConfig.instance.useRemoteTranslations) {
      await getIt<RemoteTranslations>().load();
    }
    // THE BROADCAST SUBSCRIPTION MOVES ON ITS OWN. It used to be
    // called from here, and that was the bug: nothing in the app calls
    // this method — every picker reaches for
    // `PreferencesCubit.setLanguage()` directly — so the device stayed
    // on the old language's topic for ever. `TopicSubscription`
    // listens to the language instead, from `bootstrap`, where no call
    // site can forget it. The call is kept out of here deliberately:
    // two paths to the same subscription is how the first one came to
    // be trusted and wrong.
  }
}
