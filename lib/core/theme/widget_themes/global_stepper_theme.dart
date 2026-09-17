import 'package:flutter/widgets.dart';

import '../../../shared/module/stepper/global_stepper.dart';
import '../../tokens/app_tokens.dart';

/// Project-tuned defaults for `GlobalStepper`.
///
/// The app-wide rebrand hook. Everything here is a SIZE a token already
/// answers, so a stepper's indicator and its gaps follow the rest of
/// the app into a wider window — the module's own floor is fixed
/// numbers, which cannot.
///
/// No colours: they resolve from `context.primaryColors` /
/// `textColors` / `backgroundColors` at build time, so they track role,
/// brightness and saturation.
class MyGlobalStepperTheme {
  MyGlobalStepperTheme._();

  static GlobalStepperTheme build({required AppTokens tokens}) =>
      GlobalStepperTheme(
        style: StepperStyle(
          // The circle is a touch target as well as a mark, so it takes
          // the icon scale rather than a number of its own.
          indicatorSize: tokens.iconSizes.xl,
          contentPadding: EdgeInsets.only(top: tokens.spacing.sm),
        ),
      );
}
