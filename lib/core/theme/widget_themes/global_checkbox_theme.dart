import '../../../shared/module/checkbox/global_checkbox.dart';
import '../../tokens/app_tokens.dart';

/// Project-tuned defaults for the [GlobalCheckbox] module.
///
/// Colors are intentionally left null — they resolve at build time from
/// `context.<group>Colors` (role + saturation aware). Per-call `style:`
/// overrides win.
///
/// Wired in `theme.dart`'s `extensions:` list alongside `tokens` /
/// `palette` / the other module themes.
class MyGlobalCheckboxTheme {
  MyGlobalCheckboxTheme._();

  static GlobalCheckboxTheme build({required AppTokens tokens}) {
    return const GlobalCheckboxTheme(
      // Scalar defaults live in CheckboxStyle.defaults — the factory only
      // exists as the app-wide rebrand hook, mirroring the other modules.
      style: CheckboxStyle(),
    );
  }
}
