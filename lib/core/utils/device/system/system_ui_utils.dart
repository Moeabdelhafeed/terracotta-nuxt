import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../device_services.dart';

/// System UI — status bar, full screen, keyboard, haptics, wakelock.
///
/// **Everything that hides chrome comes back to `edgeToEdge`.** The
/// app is edge-to-edge (`MyApp` sets it, and `DeviceNotch` rewrites
/// the insets on top of it): the whole side-inset system, every
/// `SafeArea` and the notch correction assume the app is drawing
/// under the bars. [showStatusBar] used to restore
/// `SystemUiMode.manual` with all overlays instead — so hiding the
/// status bar once and showing it again left the app permanently OUT
/// of edge-to-edge, with the insets it had been rewriting no longer
/// arriving.
class SystemUiUtils {
  SystemUiUtils._();

  /// The mode the app lives in. Anything that leaves full screen or
  /// puts a bar back comes here, not to `manual`.
  static const appUiMode = SystemUiMode.edgeToEdge;

  // ─── Keyboard ─────────────────────────────────────────────

  static void hideKeyboard(BuildContext context) =>
      FocusScope.of(context).unfocus();

  // ─── Status bar ───────────────────────────────────────────

  /// Set the status-bar overlay style.
  ///
  /// Takes the WHOLE style, not just a colour. `setSystemUIOverlayStyle`
  /// replaces the lot, so the old `setStatusBarColor` — which built a
  /// style out of one colour — wiped the icon brightness every time it
  /// was called, leaving dark icons on a dark bar.
  ///
  /// Note that `statusBarColor` itself is ignored under edge-to-edge
  /// on Android 15+; the brightness fields are what still land.
  static void setOverlayStyle(SystemUiOverlayStyle style) =>
      SystemChrome.setSystemUIOverlayStyle(style);

  /// Icon brightness only — the part that still works everywhere.
  /// `dark: true` means dark icons, for a light bar.
  static void setStatusBarIconsDark({required bool dark}) =>
      SystemChrome.setSystemUIOverlayStyle(
        SystemUiOverlayStyle(
          statusBarIconBrightness: dark ? Brightness.dark : Brightness.light,
          statusBarBrightness: dark ? Brightness.light : Brightness.dark,
        ),
      );

  static Future<void> hideStatusBar() => SystemChrome.setEnabledSystemUIMode(
    SystemUiMode.manual,
    overlays: const [SystemUiOverlay.bottom],
  );

  static Future<void> showStatusBar() =>
      SystemChrome.setEnabledSystemUIMode(appUiMode);

  // ─── Full screen ──────────────────────────────────────────

  static Future<void> setFullScreen({required bool enable}) =>
      SystemChrome.setEnabledSystemUIMode(
        enable ? SystemUiMode.immersiveSticky : appUiMode,
      );

  // ─── Orientation lock ─────────────────────────────────────

  /// Narrow the allowed orientations. To put them back, pass
  /// `kAppOrientations` — NOT `DeviceOrientation.values`, which would
  /// add upside-down.
  static Future<void> setPreferredOrientations(
    List<DeviceOrientation> orientations,
  ) => SystemChrome.setPreferredOrientations(orientations);

  // ─── Haptics ──────────────────────────────────────────────

  static Future<void> hapticLight() => HapticFeedback.lightImpact();
  static Future<void> hapticMedium() => HapticFeedback.mediumImpact();
  static Future<void> hapticHeavy() => HapticFeedback.heavyImpact();
  static Future<void> hapticSelection() => HapticFeedback.selectionClick();

  /// A long vibration, where supported.
  static Future<void> vibrate() => HapticFeedback.vibrate();

  // ─── Wakelock ─────────────────────────────────────────────

  /// Keep the screen on while the app is in front.
  ///
  /// Guarded: the wakelock is unimplemented on some desktop targets
  /// and throws there, and a video page enabling one should not take
  /// the page down.
  static Future<void> enableWakelock() =>
      deviceGuard('wakelock.enable', WakelockPlus.enable, fallback: null);

  static Future<void> disableWakelock() =>
      deviceGuard('wakelock.disable', WakelockPlus.disable, fallback: null);

  static Future<void> toggleWakelock({required bool enable}) => deviceGuard(
    'wakelock.toggle',
    () => WakelockPlus.toggle(enable: enable),
    fallback: null,
  );

  static Future<bool> isWakelockEnabled() => deviceGuard(
    'wakelock.enabled',
    () => WakelockPlus.enabled,
    fallback: false,
  );
}
