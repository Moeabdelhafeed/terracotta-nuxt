import 'package:flutter/material.dart';

import '../../../shared/module/image/global_image.dart';
import '../../tokens/app_tokens.dart';

/// Project-tuned defaults for [GlobalImage].
///
/// The app-wide rebrand hook: set the corner and frame of every picture
/// in the app once here.
///
/// Colors are deliberately NOT set. They resolve from
/// `context.<group>Colors` at build time, so a frame tracks the active
/// palette, role, brightness and saturation.
class MyGlobalImageTheme {
  MyGlobalImageTheme._();

  static GlobalImageTheme build({required AppTokens tokens}) {
    return GlobalImageTheme(
      style: ImageStyle(
        borderRadius: BorderRadius.circular(tokens.radii.md),
      ),
    );
  }
}
