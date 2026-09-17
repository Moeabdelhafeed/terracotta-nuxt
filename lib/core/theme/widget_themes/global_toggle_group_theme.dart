import '../../../shared/module/toggle_group/global_toggle_group.dart';
import '../../tokens/app_tokens.dart';

/// Project-tuned defaults for the [GlobalToggleGroup] module.
///
/// Colors are intentionally left null — they resolve at build time from
/// `context.<group>Colors` (role + saturation aware). Per-call `style:`
/// overrides win.
class MyGlobalToggleGroupTheme {
  MyGlobalToggleGroupTheme._();

  static GlobalToggleGroupTheme build({required AppTokens tokens}) {
    return const GlobalToggleGroupTheme(
      // Scalar defaults live in ToggleGroupStyle.defaults — the factory
      // only exists as the app-wide rebrand hook.
      style: ToggleGroupStyle(),
    );
  }
}
