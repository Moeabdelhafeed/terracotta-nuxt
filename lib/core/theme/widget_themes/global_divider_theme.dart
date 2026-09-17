import '../../../shared/module/divider/global_divider.dart';
import '../../tokens/app_tokens.dart';

/// Project-tuned defaults for [GlobalDivider].
///
/// The app-wide rebrand hook: set the weight and inset of every rule in
/// the app once here.
///
/// Colors are deliberately NOT set. They resolve from
/// `context.<group>Colors` at build time, so a rule tracks the active
/// palette, role, brightness and saturation.
class MyGlobalDividerTheme {
  MyGlobalDividerTheme._();

  static GlobalDividerTheme build({required AppTokens tokens}) {
    return const GlobalDividerTheme(style: DividerStyle());
  }
}
