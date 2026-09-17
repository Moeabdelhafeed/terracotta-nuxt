import '../../../shared/module/tooltip/global_tooltip.dart';
import '../../tokens/app_tokens.dart';

/// Project-tuned defaults for [GlobalTooltip].
///
/// The app-wide rebrand hook: set the tooltip's surface, type and
/// timing once here.
///
/// Colors are deliberately NOT set. They resolve from
/// `context.<group>Colors` at build time, so a tooltip tracks the active
/// palette, role, brightness and saturation.
class MyGlobalTooltipTheme {
  MyGlobalTooltipTheme._();

  static GlobalTooltipTheme build({required AppTokens tokens}) {
    return const GlobalTooltipTheme(style: TooltipStyle());
  }
}
