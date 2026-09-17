import '../../../shared/module/progress/global_progress.dart';
import '../../tokens/app_tokens.dart';

/// Project-tuned defaults for [GlobalProgress].
///
/// The app-wide rebrand hook: set the weight and the motion of every
/// progress indicator in the app once here.
///
/// Colors are deliberately NOT set. They resolve from
/// `context.primaryColors` at build time, so a bar tracks the active
/// palette, role, brightness and saturation.
class MyGlobalProgressTheme {
  MyGlobalProgressTheme._();

  static GlobalProgressTheme build({required AppTokens tokens}) {
    return const GlobalProgressTheme(
      style: ProgressStyle(
        // Every indeterminate indicator in the app waits this long
        // before showing itself, so work that finishes quickly never
        // flashes a spinner — a flash reads as a glitch, not as
        // loading. One line, every spinner. Set `Duration.zero` per
        // call where the wait would be worse than the flash.
        appearAfter: ProgressDefaults.suggestedAppearAfter,
      ),
    );
  }
}
