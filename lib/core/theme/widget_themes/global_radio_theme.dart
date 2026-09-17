import '../../../shared/module/radio/global_radio.dart';
import '../../tokens/app_tokens.dart';

/// Project-tuned defaults for the [GlobalRadio] module.
///
/// Colors are intentionally left null — they resolve at build time from
/// `context.<group>Colors` (role + saturation aware). Per-call `style:`
/// overrides win.
///
/// Wired in `theme.dart`'s `extensions:` list alongside `tokens` /
/// `palette` / the other module themes.
class MyGlobalRadioTheme {
  MyGlobalRadioTheme._();

  static GlobalRadioTheme build({required AppTokens tokens}) {
    return const GlobalRadioTheme(
      // Scalar defaults live in RadioStyle.defaults — the factory only
      // exists as the app-wide rebrand hook, mirroring the other modules.
      style: RadioStyle(),
    );
  }
}
