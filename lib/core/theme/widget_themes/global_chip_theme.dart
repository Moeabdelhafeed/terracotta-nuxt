import '../../../shared/module/chip/global_chip.dart';
import '../../tokens/app_tokens.dart';

/// Project-tuned defaults for [GlobalChip].
///
/// The app-wide rebrand hook: set the chip's shape, weight and elevation
/// once here and every filter, tag and category row follows.
///
/// Colors are deliberately NOT set. They resolve from
/// `context.<group>Colors` at build time, so a chip tracks the active
/// palette, role, brightness and saturation.
class MyGlobalChipTheme {
  MyGlobalChipTheme._();

  static GlobalChipTheme build({required AppTokens tokens}) {
    return const GlobalChipTheme(style: ChipStyle());
  }
}
