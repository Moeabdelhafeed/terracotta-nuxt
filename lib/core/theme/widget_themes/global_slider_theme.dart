import '../../../shared/module/slider/global_slider.dart';
import '../../tokens/app_tokens.dart';

/// Project-tuned defaults for `GlobalSlider`.
///
/// The app-wide rebrand hook. Everything here is a SIZE a token already
/// answers, so a slider rounds and pads like the rest of the app and
/// follows it into a wider window — the module's own floor is fixed
/// numbers, which cannot.
///
/// No colours: they resolve from `context.primaryColors` /
/// `textColors` / `backgroundColors` at build time, so they track role,
/// brightness and saturation.
class MyGlobalSliderTheme {
  MyGlobalSliderTheme._();

  static GlobalSliderTheme build({required AppTokens tokens}) =>
      GlobalSliderTheme(
        style: SliderStyle(
          containerRadius: tokens.radii.md,
          valueBadgeRadius: tokens.radii.sm,
          endChipRadius: tokens.radii.xs,
        ),
      );
}
