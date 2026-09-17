import '../../../shared/module/icon/global_icon.dart';
import '../../tokens/app_tokens.dart';

/// Project-tuned defaults for [GlobalIcon].
///
/// The app-wide rebrand hook: set the glyph size and container
/// treatment of every icon in the app once here.
///
/// Colors are deliberately NOT set. The glyph takes the ambient
/// `IconTheme` and then `context.<group>Colors` at build time, so an
/// icon tracks the surface it sits on, then the palette, role,
/// brightness and saturation.
class MyGlobalIconTheme {
  MyGlobalIconTheme._();

  static GlobalIconTheme build({required AppTokens tokens}) {
    return GlobalIconTheme(
      // The glyph size comes from the TOKENS, so an icon grows with the
      // window the way type and spacing already do. `lg` is 24 on a
      // phone — what the module's own floor is — and 28 on a desktop.
      // Without this the hook took `tokens` and ignored them, and every
      // bare icon in the app stayed 24 at any width.
      style: IconStyle(size: tokens.iconSizes.lg),
    );
  }
}
