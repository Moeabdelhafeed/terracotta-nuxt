import '../../../shared/module/empty_state/global_empty_state.dart';
import '../../tokens/app_tokens.dart';

/// Project-tuned defaults for [GlobalEmptyState].
///
/// The app-wide rebrand hook: set the glyph treatment and the type of
/// every "nothing here yet" screen once here.
///
/// Colors are deliberately NOT set. They resolve from
/// `context.<group>Colors` at build time, so an empty state tracks the
/// active palette, role, brightness and saturation.
class MyGlobalEmptyStateTheme {
  MyGlobalEmptyStateTheme._();

  static GlobalEmptyStateTheme build({required AppTokens tokens}) {
    return const GlobalEmptyStateTheme(style: EmptyStateStyle());
  }
}
