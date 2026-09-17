import '../../../generated/l10n.dart';
import '../tr.dart';

/// Strings for the `theme_mode_` key prefix family — user-visible labels
/// of the [ThemeMode] options.
class ThemeModeStrings {
  ThemeModeStrings._();

  static String get system =>
      Tr.t('theme_mode.system', S.current.theme_mode_system);
  static String get light =>
      Tr.t('theme_mode.light', S.current.theme_mode_light);
  static String get dark => Tr.t('theme_mode.dark', S.current.theme_mode_dark);
}
