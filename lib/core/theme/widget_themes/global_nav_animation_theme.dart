import 'package:flutter/material.dart';

import '../../animations/animation_presets.dart';
import '../../navigation/transitions/navigation_aware_animation.dart';
import '../../tokens/app_tokens.dart';

/// Project-tuned defaults for `NavigationAwareAnimation`.
///
/// The app-wide rebrand hook for widgets that animate on a navigation
/// event. Like the page-transition theme it takes [tokens] for symmetry
/// and reads none of them: motion is not layout.
///
/// Only the OPEN fields belong here — a duration, a curve, a delay.
/// Setting a slide would move every widget in the app.
class MyGlobalNavAnimationTheme {
  MyGlobalNavAnimationTheme._();

  static GlobalNavAnimationTheme build({required AppTokens tokens}) =>
      const GlobalNavAnimationTheme(
        animation: WidgetAnimation(
          // The SAME 300ms and easeOutCubic the page transitions use.
          //
          // It shipped empty, which left widget motion on the module
          // floor — `slow`, a third longer than the pages it plays
          // over. Two clocks in one arrival is what makes a screen feel
          // like it is still settling after it has arrived.
          //
          // Only the OPEN fields belong here. Setting a slide would
          // move every widget in the app.
          duration: AppDurations.normal,
          curve: Curves.easeOutCubic,
        ),
      );
}
