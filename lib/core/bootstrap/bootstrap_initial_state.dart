import 'dart:ui';

import 'package:flutter/material.dart';

import '../../data/blocs/preferences/preferences_cubit.dart';
import '../../data/services/languages_service.dart';
import '../../data/services/preferences/locale_service.dart';
import '../di/service_locator.dart';

/// On first launch, derive initial locale + theme from device settings.
/// Otherwise restore persisted preferences.
///
/// **Nothing may overwrite this afterwards.** `forceDevSettings()` used
/// to run right after it on every single launch, pinning English and
/// light mode — template scaffolding for deterministic screenshots,
/// kept long enough that the app appeared not to remember the language
/// at all. The preference was saved correctly the whole time; it was
/// being overwritten three lines later. It is deleted rather than
/// guarded: a switch that forces a language is not something this app
/// wants under any flag.
Future<void> setupInitialState() async {
  final prefs = getIt<PreferencesCubit>();

  if (prefs.state.isFirstTime) {
    await _handleFirstLaunch(prefs);
  } else {
    await _restoreUserSettings(prefs);
  }
}

Future<void> _handleFirstLaunch(PreferencesCubit prefs) async {
  final platformBrightness = PlatformDispatcher.instance.platformBrightness;
  final deviceLocale = PlatformDispatcher.instance.locale;
  await _setupLocale(deviceLocale, prefs);
  _setupTheme(platformBrightness, prefs);
  prefs.markNotFirstTime();
}

Future<void> _restoreUserSettings(PreferencesCubit prefs) async {
  getIt<LocaleService>().setLocale(prefs.state.language);
  prefs.setThemeMode(prefs.state.themeMode);
}

Future<void> _setupLocale(Locale deviceLocale, PreferencesCubit prefs) async {
  final languagesService = getIt<LanguagesService>();
  final language = languagesService.languages.firstWhere(
    (language) => language.locale == deviceLocale.languageCode,
    orElse: () => languagesService.defaultLanguage,
  );
  getIt<LocaleService>().setLocale(language);
}

void _setupTheme(Brightness platformBrightness, PreferencesCubit prefs) {
  final themeMode = platformBrightness == Brightness.dark
      ? ThemeMode.dark
      : ThemeMode.light;
  prefs.setThemeMode(themeMode);
}
