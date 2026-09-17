import 'package:flutter/material.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../core/constants/enums/app/app_role.dart';
import '../../../core/constants/enums/app/color_saturation.dart';
import '../../models/common/language/language.dart';

part 'preferences_state.freezed.dart';
part 'preferences_state.g.dart';

/// Persisted user preferences — rehydrated on app launch via
/// `HydratedCubit`. Single source of truth for UI prefs.
///
/// Everything here survives app kill. Auth state (token, user) lives
/// in [AuthBloc] / [SecureCredentialStore], not here.
@freezed
abstract class PreferencesState with _$PreferencesState {
  const factory PreferencesState({
    @Default(defaultLanguage) Language language,
    @Default(ThemeMode.system) @_ThemeModeConverter() ThemeMode themeMode,
    @Default(AppRole.user) AppRole appRole,
    @Default(ColorSaturation.normal) ColorSaturation colorSaturation,
    @Default('circle') String revealShapeKey,
    @Default('expand') String revealDirectionName,
    @Default(false) bool seenOnboarding,
    @Default(true) bool isFirstTime,
    @Default(1.0) double fontScale,
    @Default(false) bool dynamicColor,
  }) = _PreferencesState;

  factory PreferencesState.fromJson(Map<String, dynamic> json) =>
      _$PreferencesStateFromJson(json);
}

/// Default language when no persisted value exists.
const Language defaultLanguage = Language(
  id: 1,
  name: 'English',
  locale: 'en',
  direction: 'ltr',
  flag: '🇺🇸',
  isDefault: true,
);

/// `ThemeMode` is a Flutter enum — no `toJson` / `fromJson` by default.
/// Persist via its `name`.
class _ThemeModeConverter implements JsonConverter<ThemeMode, String> {
  const _ThemeModeConverter();

  @override
  ThemeMode fromJson(String json) => ThemeMode.values.firstWhere(
    (m) => m.name == json,
    orElse: () => ThemeMode.system,
  );

  @override
  String toJson(ThemeMode object) => object.name;
}
