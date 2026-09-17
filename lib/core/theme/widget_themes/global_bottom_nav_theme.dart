import '../../../shared/module/bottom_nav/global_bottom_nav.dart';
import '../../tokens/app_tokens.dart';

/// Project-tuned defaults for [GlobalBottomNav].
///
/// The app-wide rebrand hook: set the corner every floating bar rounds
/// to, once, here.
///
/// Colors are deliberately NOT set. They resolve from
/// `context.<group>Colors` at build time, so a bar tracks the active
/// palette, role, brightness and saturation.
class MyGlobalBottomNavTheme {
  MyGlobalBottomNavTheme._();

  static GlobalBottomNavTheme build({required AppTokens tokens}) {
    // The CORNER is deliberately not set.
    //
    // A floating bar takes the device's own screen radius, and a bar
    // flush to the bottom takes its top corners from the same place —
    // `DeviceRadius`, measured from the hardware. Setting a token
    // radius here pre-empted that: the bag has no way to tell a theme's
    // value from a caller's, so the theme won and every floating bar
    // wore a rounded rectangle that did not match the screen it sat in.
    //
    // A project that wants one anyway sets it here; nothing else does.
    return const GlobalBottomNavTheme(style: BottomNavStyle());
  }
}
