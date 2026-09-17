import 'package:flutter/material.dart';

import '../../../shared/module/audio/global_audio.dart';
import '../../tokens/app_tokens.dart';

/// Project-tuned defaults for [GlobalAudioPlayer].
///
/// The app-wide rebrand hook: set the card's corner and which controls
/// every player in the app offers, once, here.
///
/// Colours are deliberately NOT set. The accent, the bars and the
/// glyphs resolve from `context.*Colors` at build time so they track
/// the active palette, role, brightness and saturation — which a
/// constant in here cannot.
class MyGlobalAudioTheme {
  MyGlobalAudioTheme._();

  static GlobalAudioTheme build({required AppTokens tokens}) =>
      GlobalAudioTheme(
        style: AudioStyle(borderRadius: BorderRadius.circular(tokens.radii.md)),
      );
}
