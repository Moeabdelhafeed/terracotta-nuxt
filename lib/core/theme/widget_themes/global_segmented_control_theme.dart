import '../../../shared/module/segmented_control/global_segmented_control.dart';
import '../../tokens/app_tokens.dart';

/// Project-tuned defaults for the [GlobalSegmentedControl] module.
///
/// Colors are intentionally left null — they resolve at build time from
/// `context.<group>Colors` (role + saturation aware). Per-call `style:`
/// overrides win.
class MyGlobalSegmentedControlTheme {
  MyGlobalSegmentedControlTheme._();

  static GlobalSegmentedControlTheme build({required AppTokens tokens}) {
    return const GlobalSegmentedControlTheme(
      // Scalar defaults live in SegmentedStyle.defaults — the factory
      // only exists as the app-wide rebrand hook.
      style: SegmentedStyle(),
    );
  }
}
