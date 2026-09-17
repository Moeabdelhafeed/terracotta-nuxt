import '../../../shared/module/drop_down/global_drop_down.dart';
import '../../tokens/app_tokens.dart';

/// Project-tuned defaults for the [GlobalDropdown] module's OPEN surface
/// (the trigger inherits `MyGlobalTextFieldTheme`).
///
/// Colors + text styles are intentionally left null — they resolve at
/// build time from `context.<group>Colors` / `textTheme` (role +
/// saturation aware). Per-call `dropdownStyle:` overrides win.
///
/// Wired in `theme.dart`'s `extensions:` list alongside `tokens` /
/// `palette` / `MyGlobalPopupTheme` / `MyGlobalTextFieldTheme`.
class MyGlobalDropdownTheme {
  MyGlobalDropdownTheme._();

  static GlobalDropdownTheme build({required AppTokens tokens}) {
    return const GlobalDropdownTheme(
      // Scalar defaults live in DropdownStyle.defaults — the factory only
      // exists as the app-wide rebrand hook, mirroring the other modules.
      style: DropdownStyle(),
    );
  }
}
