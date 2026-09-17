import '../../../shared/module/indicator/global_indicator.dart';
import '../../tokens/app_tokens.dart';

/// Project-tuned defaults for the indicator family.
///
/// The app-wide rebrand hook: every pagination row in the app — the
/// page view's, the carousel's, the onboarding flow's — reads this.
///
/// No colours: they resolve from `context.primaryColors` /
/// `backgroundColors` at build time, so they track role, brightness
/// and saturation. The story bar is the exception and resolves to
/// WHITE, because it sits over photographs rather than over the page.
class MyGlobalIndicatorTheme {
  MyGlobalIndicatorTheme._();

  static GlobalIndicatorTheme build({required AppTokens tokens}) =>
      GlobalIndicatorTheme(
        dotStyle: DotIndicatorStyle(
          // A dot's gap is a spacing decision like any other, so it
          // grows with the window rather than staying at 8 forever.
          dotSpacing: tokens.spacing.sm,
          radius: tokens.radii.sm,
        ),
        storyStyle: StoryIndicatorStyle(spacing: tokens.spacing.xs),
      );
}
