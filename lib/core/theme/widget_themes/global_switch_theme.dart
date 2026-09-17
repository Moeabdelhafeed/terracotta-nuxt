import '../../../shared/module/switch/global_switch.dart';
import '../../tokens/app_tokens.dart';

/// Project-tuned defaults for the [GlobalSwitch] module.
///
/// Colors are intentionally left null — they resolve at build time from
/// `context.<group>Colors` (role + saturation aware). Per-call `style:`
/// overrides win.
///
/// Wired in `theme.dart`'s `extensions:` list alongside `tokens` /
/// `palette` / the other module themes.
class MyGlobalSwitchTheme {
  MyGlobalSwitchTheme._();

  static GlobalSwitchTheme build({required AppTokens tokens}) {
    return const GlobalSwitchTheme(
      // Scalar defaults live in SwitchStyle.defaults — the factory only
      // exists as the app-wide rebrand hook, mirroring the other modules.
      style: SwitchStyle(),
    );
  }
}
