import '../../../shared/module/text/global_text.dart';
import '../../tokens/app_tokens.dart';

/// Project-tuned base styling for the [GlobalText] family.
///
/// Colors are intentionally left null — they resolve at build time from
/// `context.<group>Colors`, so text tracks the active role, palette and
/// saturation instead of freezing a constant here. Per-call
/// `textStyle:` overrides still win over everything.
///
/// This exists as the app-wide rebrand hook: set a field here and every
/// `GlobalText` in the app follows, instead of editing call sites.
class MyGlobalTextTheme {
  MyGlobalTextTheme._();

  static GlobalTextTheme build({required AppTokens tokens}) {
    return GlobalTextTheme(
      style: GlobalTextStyle(
        // Icon geometry follows the token bucket so a density change
        // moves leading/trailing glyphs with everything else.
        iconSize: tokens.iconSizes.sm,
        iconSpacing: tokens.spacing.xs,
      ),
    );
  }
}
