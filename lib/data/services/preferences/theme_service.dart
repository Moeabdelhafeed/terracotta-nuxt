import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';

import '../../../core/constants/enums/app/app_role.dart';
import '../../../core/theme/theme.dart';
import '../../blocs/preferences/preferences_cubit.dart';

/// Theme service — plain Dart singleton over [PreferencesCubit].
/// Owns platform-brightness tracking (which [PreferencesCubit] does
/// not, because it's static prefs only) and builds [ThemeData] for a
/// `(themeMode, appRole)` pair.
///
/// Registers a [WidgetsBindingObserver] for brightness so the single
/// `PlatformDispatcher.onPlatformBrightnessChanged` slot stays free
/// for other subscribers.
class ThemeService with WidgetsBindingObserver {
  ThemeService(this._prefs) {
    _systemBrightness = PlatformDispatcher.instance.platformBrightness;
    WidgetsBinding.instance.addObserver(this);
  }

  final PreferencesCubit _prefs;
  late Brightness _systemBrightness;
  final StreamController<Brightness> _brightnessController =
      StreamController<Brightness>.broadcast();

  @override
  void didChangePlatformBrightness() {
    _systemBrightness = PlatformDispatcher.instance.platformBrightness;
    _brightnessController.add(_systemBrightness);
  }

  Stream<Brightness> get onSystemBrightnessChanged =>
      _brightnessController.stream;

  ThemeMode get themeMode => _prefs.state.themeMode;

  bool get isDark => themeMode == ThemeMode.system
      ? _systemBrightness == Brightness.dark
      : themeMode == ThemeMode.dark;

  Brightness get currentBrightness =>
      isDark ? Brightness.dark : Brightness.light;
  Brightness get currentBrightnessContrast =>
      isDark ? Brightness.light : Brightness.dark;

  void setThemeMode(ThemeMode mode) => _prefs.setThemeMode(mode);

  /// Cycle theme mode (light → dark → system → light). Delegates to the
  /// canonical 3-cycle on [PreferencesCubit].
  void toggleTheme() => _prefs.toggleTheme();

  ThemeData getThemeWithRole(AppRole appRole) =>
      AppTheme.getTheme(themeMode: themeMode, appRole: appRole);

  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _brightnessController.close();
  }
}
