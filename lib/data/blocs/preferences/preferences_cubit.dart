import 'package:flutter/material.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';

import '../../../core/constants/enums/app/app_role.dart';
import '../../../core/constants/enums/app/color_saturation.dart';
import '../../models/common/language/language.dart';
import 'preferences_state.dart';

/// User preferences — persisted to disk via `HydratedCubit`. Replaces
/// the old `PreferencesStore` (GetX). State survives app kill; every
/// `emit` is auto-persisted.
///
/// Initialize `HydratedBloc.storage` in `main.dart` before
/// instantiating.
class PreferencesCubit extends HydratedCubit<PreferencesState> {
  PreferencesCubit() : super(const PreferencesState());

  // ─── Language ────────────────────────────────────────────────────

  void setLanguage(Language language) =>
      emit(state.copyWith(language: language));

  // ─── Theme ───────────────────────────────────────────────────────

  void setThemeMode(ThemeMode mode) => emit(state.copyWith(themeMode: mode));

  void toggleTheme() {
    final next = switch (state.themeMode) {
      ThemeMode.light => ThemeMode.dark,
      ThemeMode.dark => ThemeMode.system,
      ThemeMode.system => ThemeMode.light,
    };
    emit(state.copyWith(themeMode: next));
  }

  // ─── Role ────────────────────────────────────────────────────────

  void setAppRole(AppRole role) => emit(state.copyWith(appRole: role));

  void toggleAppRole() => emit(
    state.copyWith(
      appRole: state.appRole == AppRole.user ? AppRole.guest : AppRole.user,
    ),
  );

  // ─── Color saturation ────────────────────────────────────────────

  void setColorSaturation(ColorSaturation s) =>
      emit(state.copyWith(colorSaturation: s));

  // ─── Reveal switch animation shape ──────────────────────────────

  void setRevealShapeKey(String key) =>
      emit(state.copyWith(revealShapeKey: key));

  void setRevealDirectionName(String name) =>
      emit(state.copyWith(revealDirectionName: name));

  // ─── Font scale ──────────────────────────────────────────────────
  // Multiplied with the system text scaler in MyApp.builder. Clamped
  // to [0.7, 2.0] to keep layouts coherent.
  static const double minFontScale = 0.7;
  static const double maxFontScale = 2.0;

  void setFontScale(double scale) {
    final clamped = scale.clamp(minFontScale, maxFontScale);
    emit(state.copyWith(fontScale: clamped));
  }

  void resetFontScale() => emit(state.copyWith(fontScale: 1.0));

  // ─── Dynamic color (Material You) ────────────────────────────────
  // When true, AppTheme can pull seed colors from the OS (Android 12+).
  // Off by default — base palette is the source of truth.

  void setDynamicColor(bool enabled) =>
      emit(state.copyWith(dynamicColor: enabled));

  // ─── Onboarding / first-launch flags ─────────────────────────────

  void markOnboardingSeen() => emit(state.copyWith(seenOnboarding: true));

  void markOnboardingUnseen() => emit(state.copyWith(seenOnboarding: false));

  void markNotFirstTime() => emit(state.copyWith(isFirstTime: false));

  // ─── Reset ───────────────────────────────────────────────────────
  // Wipe display preferences back to defaults. Keeps onboarding
  // flags so the user doesn't replay onboarding.
  void resetDisplayPreferences() {
    emit(
      state.copyWith(
        themeMode: ThemeMode.system,
        colorSaturation: ColorSaturation.normal,
        fontScale: 1.0,
        dynamicColor: false,
        revealShapeKey: 'circle',
        revealDirectionName: 'expand',
      ),
    );
  }

  // ─── Persistence hooks ───────────────────────────────────────────

  @override
  PreferencesState? fromJson(Map<String, dynamic> json) {
    try {
      return PreferencesState.fromJson(json);
    } catch (_) {
      return null;
    }
  }

  @override
  Map<String, dynamic>? toJson(PreferencesState state) => state.toJson();
}
