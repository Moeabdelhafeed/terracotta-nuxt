import 'package:flutter/material.dart';

import '../../../../core/extensions/theme_colors_extension.dart';
import '../visualizer_models.dart';

/// App-wide defaults for [GlobalAudioVisualizer].
///
/// The rebrand hook: set the shape, the bin count and the corner every
/// visualizer in the app draws with, once, here.
@immutable
class GlobalVisualizerTheme extends ThemeExtension<GlobalVisualizerTheme> {
  const GlobalVisualizerTheme({this.style});

  final VisualizerStyle? style;

  static GlobalVisualizerTheme? maybeOf(BuildContext context) =>
      Theme.of(context).extension<GlobalVisualizerTheme>();

  @override
  GlobalVisualizerTheme copyWith({VisualizerStyle? style}) =>
      GlobalVisualizerTheme(style: style ?? this.style);

  @override
  GlobalVisualizerTheme lerp(
    ThemeExtension<GlobalVisualizerTheme>? other,
    double t,
  ) {
    if (other is! GlobalVisualizerTheme) return this;
    // A style is a bag of independent decisions, not a value with a
    // midpoint — half a `glow` means nothing. It SNAPS at the halfway
    // mark, which is what every other bag in this app does.
    return t < 0.5 ? this : other;
  }
}

/// Turns a caller's bag into one with every question answered.
extension VisualizerStyleResolve on VisualizerStyle {
  /// `caller > GlobalVisualizerTheme.style > VisualizerStyle.defaults`,
  /// then the colour from the palette.
  ResolvedVisualizerStyle resolve(BuildContext context) {
    final merged = VisualizerStyle.defaults
        .mergedWith(GlobalVisualizerTheme.maybeOf(context)?.style)
        .mergedWith(this);

    return ResolvedVisualizerStyle(
      shape: merged.shape ?? VisualizerDefaults.shape,
      barCount: merged.barCount ?? VisualizerDefaults.barCount,
      // The PALETTE, not `Theme.of` — so a visualizer tracks role,
      // brightness and saturation like everything else in the module.
      color: merged.color ?? context.primaryColors.primary,
      height: merged.height ?? VisualizerDefaults.height,
      smoothing: merged.smoothing ?? VisualizerDefaults.smoothing,
      minBar: merged.minBar ?? VisualizerDefaults.minBar,
      glow: merged.glow ?? false,
      barWidthFactor:
          merged.barWidthFactor ?? VisualizerDefaults.barWidthFactor,
      windowSpread: merged.windowSpread ?? VisualizerDefaults.windowSpread,
      idleDecay: merged.idleDecay ?? VisualizerDefaults.idleDecay,
      gradient: merged.gradient,
      background: merged.background,
      borderRadius: merged.borderRadius,
    );
  }
}
