import '../../../shared/module/marquee/global_marquee.dart';
import '../../tokens/app_tokens.dart';

/// Project-tuned defaults for [GlobalMarquee].
///
/// The app-wide rebrand hook: set the scroll feel here and every
/// marquee follows, instead of tuning call sites one by one.
class MyGlobalMarqueeTheme {
  MyGlobalMarqueeTheme._();

  static GlobalMarqueeTheme build({required AppTokens tokens}) {
    return GlobalMarqueeTheme(
      style: MarqueeStyle(
        // Fade ramp and loop gap ride the token bucket so a density
        // change moves them with everything else.
        fadeWidth: tokens.spacing.lg,
        gap: tokens.spacing.xl,
      ),
    );
  }
}
