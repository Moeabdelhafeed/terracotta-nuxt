import 'package:flutter/material.dart';

import '../../../shared/module/animation/global_animation.dart';
import '../../tokens/app_tokens.dart';

/// Project-tuned defaults for [GlobalAnimation].
///
/// The app-wide rebrand hook: set the corner every GIF and Lottie in
/// the app rounds to, once, here.
///
/// Colors are deliberately NOT set. They resolve from
/// `context.<group>Colors` at build time, so a player tracks the active
/// palette, role, brightness and saturation.
class MyGlobalAnimationTheme {
  MyGlobalAnimationTheme._();

  static GlobalAnimationTheme build({required AppTokens tokens}) {
    return GlobalAnimationTheme(
      style: GlobalAnimationStyle(
        borderRadius: BorderRadius.circular(tokens.radii.sm),
      ),
    );
  }
}
