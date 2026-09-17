import 'package:flutter/material.dart';

/// [BuildContext] helpers that fill gaps not covered by GoRouter.
///
/// Navigation (push / pop / go / canPop) comes from GoRouter. Layout
/// queries (windowSize / breakpoints) live on `core/responsive/`.
/// Transient feedback goes through `GlobalToast.s/.e/.w/.i` (toast
/// module) and `GlobalBanner` — there is deliberately no
/// `context.showSnackBar` / `context.showBanner` wrapper here.
extension ContextThemeExtensions on BuildContext {
  /// Shorthand for [Theme.of].
  ThemeData get theme => Theme.of(this);

  /// Shorthand for [Theme.of]`.textTheme`.
  TextTheme get textTheme => theme.textTheme;

  /// Shorthand for [Theme.of]`.colorScheme`.
  ColorScheme get colorScheme => theme.colorScheme;

  /// True when the resolved [ThemeData.brightness] is dark.
  bool get isDarkMode => theme.brightness == Brightness.dark;
}

extension ContextMediaQueryExtensions on BuildContext {
  /// Platform brightness (OS setting, not the app theme).
  Brightness get platformBrightness => MediaQuery.of(this).platformBrightness;

  /// True when the OS is in dark mode (independent of app theme).
  bool get isPlatformDark =>
      MediaQuery.of(this).platformBrightness == Brightness.dark;

  /// Top device inset (notch / status bar area) — the raw `viewPadding.top`,
  /// unaffected by the keyboard.
  double get safeTop => MediaQuery.of(this).viewPadding.top;

  /// Bottom device inset (home indicator / gesture bar area) — the raw
  /// `viewPadding.bottom`, unaffected by the keyboard.
  double get safeBottom => MediaQuery.of(this).viewPadding.bottom;
}
