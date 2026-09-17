import 'package:flutter/material.dart';

import '../../../shared/module/audio/global_audio.dart';
import '../../tokens/app_tokens.dart';

/// Project-tuned defaults for [GlobalAudioVisualizer].
///
/// Only the corner, so a visualizer given a background matches every
/// other surface in the app. The colour is deliberately NOT set: it
/// resolves from `context.primaryColors` at build time so it tracks
/// role, brightness and saturation, which a constant in here cannot.
class MyGlobalVisualizerTheme {
  MyGlobalVisualizerTheme._();

  static GlobalVisualizerTheme build({required AppTokens tokens}) =>
      GlobalVisualizerTheme(
        style: VisualizerStyle(
          borderRadius: BorderRadius.circular(tokens.radii.md),
        ),
      );
}
