import '../../../shared/module/buttons/global_filled_button.dart';
import '../../tokens/app_tokens.dart';

/// Project-tuned base styles for the button family (elevated /
/// outlined / text / icon).
///
/// Colors are intentionally left null — they resolve at build time from
/// `context.<group>Colors` (role + saturation aware). Per-call `style:`
/// overrides win.
class MyGlobalButtonsTheme {
  MyGlobalButtonsTheme._();

  static GlobalButtonsTheme build({required AppTokens tokens}) {
    return const GlobalButtonsTheme(
      // Per-variant defaults live in each widget's resolvers — the
      // factory only exists as the app-wide rebrand hook.
    );
  }
}
