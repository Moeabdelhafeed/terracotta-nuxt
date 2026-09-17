import 'package:flutter/material.dart';

import '../../../shared/module/video/global_video.dart';
import '../../tokens/app_tokens.dart';

/// Project-tuned defaults for [GlobalVideo].
///
/// The app-wide rebrand hook: set the frame radius, the glyph set and
/// which chrome every player in the app offers, once, here.
///
/// Colors are deliberately NOT set. The seek-bar accent resolves from
/// `context.primaryColors` at build time so it tracks the active
/// palette, role, brightness and saturation — while the glyphs stay
/// white on a scrim, because they float over film rather than over a
/// surface this app painted.
class MyGlobalVideoTheme {
  MyGlobalVideoTheme._();

  static GlobalVideoTheme build({required AppTokens tokens}) =>
      GlobalVideoTheme(
        style: VideoStyle(
          borderRadius: BorderRadius.circular(tokens.radii.md),
        ),
      );
}
