import '../../../generated/l10n.dart';
import '../tr.dart';

/// «الإعدادات» — the handful of things a CUSTOMER sets.
///
/// Deliberately short. The template ships a settings page carrying the
/// app-role switch, the colour-saturation ramp, the reveal shape and
/// the reveal direction — showcase controls for the people building
/// the template, not for somebody booking a pottery class. Terracotta's
/// page carries language, text size and whether notifications are on.
///
/// **The theme switch says where dark came from.** The design is
/// light-only, so dark is the app's own work — built rather than
/// borrowed, and measured (`test/terracotta/dark_palette_test.dart`).
/// The row says that instead of pretending the studio drew it.
class SettingsStrings {
  SettingsStrings._();

  static String get language =>
      Tr.t('settings_language', S.current.settings_language);

  static String get textSize =>
      Tr.t('settings_text_size', S.current.settings_text_size);

  static String get notifications =>
      Tr.t('settings_notifications', S.current.settings_notifications);

  static String get notificationsOn => Tr.t(
    'settings_notifications_on',
    S.current.settings_notifications_on,
  );

  static String get notificationsOff => Tr.t(
    'settings_notifications_off',
    S.current.settings_notifications_off,
  );

  /// The app cannot turn them on itself — only the OS can, and only
  /// the reader can tell the OS.
  static String get openNotificationSettings => Tr.t(
    'settings_notifications_open',
    S.current.settings_notifications_open,
  );

  static String version(String version) =>
      Tr.t('settings_version', S.current.settings_version(version));

  static String get theme =>
      Tr.t('settings_theme', S.current.settings_theme);

  /// Said under the switch.
  ///
  /// The design is light-only, so dark is the app's own work rather
  /// than the studio's — a warm-neutral ground built under the same
  /// brand, measured against the same 4.5:1 bar, with every ground,
  /// ink and status hue chosen for it rather than borrowed from
  /// light. The one thing still standing in is the logo's dark
  /// variant, which is a recolour.
  ///
  /// The note stays because the sentence is still true and a reader
  /// turning it on deserves to know which half of the app they are
  /// looking at. It no longer apologises for it.
  static String get themeNote =>
      Tr.t('settings_theme_note', S.current.settings_theme_note);
}
