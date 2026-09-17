import '../../../shared/module/dialog/global_dialog.dart';
import '../../tokens/app_tokens.dart';

/// Project-tuned defaults for the [GlobalDialog] module.
///
/// Colors are intentionally left null — they resolve at build time from
/// `context.<group>Colors` (role + saturation aware). Per-call `style:`
/// overrides win.
class MyGlobalDialogTheme {
  MyGlobalDialogTheme._();

  static GlobalDialogTheme build({required AppTokens tokens}) {
    return const GlobalDialogTheme(
      // Scalar defaults live in DialogStyle.defaults — the factory
      // only exists as the app-wide rebrand hook.
      style: DialogStyle(),
    );
  }
}
