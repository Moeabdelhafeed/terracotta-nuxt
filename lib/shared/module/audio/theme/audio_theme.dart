import 'package:flutter/material.dart';

import '../../../../core/extensions/theme_colors_extension.dart';
import '../../../../core/tokens/extensions.dart';
import '../audio_models.dart';

/// App-wide defaults for [GlobalAudioPlayer].
///
/// The rebrand hook: set the corner, the bar geometry and which
/// controls every player in the app offers, once, here.
@immutable
class GlobalAudioTheme extends ThemeExtension<GlobalAudioTheme> {
  const GlobalAudioTheme({this.style});

  final AudioStyle? style;

  static GlobalAudioTheme? maybeOf(BuildContext context) =>
      Theme.of(context).extension<GlobalAudioTheme>();

  @override
  GlobalAudioTheme copyWith({AudioStyle? style}) =>
      GlobalAudioTheme(style: style ?? this.style);

  @override
  GlobalAudioTheme lerp(ThemeExtension<GlobalAudioTheme>? other, double t) {
    if (other is! GlobalAudioTheme) return this;
    // A style is a bag of independent decisions, not a value with a
    // midpoint — half a `showLoop` means nothing. It SNAPS at the
    // halfway mark, which is what every other bag in this app does.
    return t < 0.5 ? this : other;
  }
}

/// Turns a caller's bag into one with every question answered.
extension AudioStyleResolve on AudioStyle {
  /// `caller > GlobalAudioTheme.style > AudioStyle.defaults`, then
  /// colours from the palette.
  ///
  /// Colours resolve HERE rather than being baked into a const bag so
  /// they track the active role, brightness and saturation. The widget
  /// used to reach for `Theme.of(context).colorScheme` in four places
  /// and `Colors.white` in two, which is how a player drew white
  /// glyphs on a light surface.
  ResolvedAudioStyle resolve(BuildContext context) {
    final merged = AudioStyle.defaults
        .mergedWith(GlobalAudioTheme.maybeOf(context)?.style)
        .mergedWith(this);

    final primary = context.primaryColors;
    final text = context.textColors;
    final background = context.backgroundColors;

    return ResolvedAudioStyle(
      accent: merged.accent ?? primary.primary,
      barColor: merged.barColor ?? background.outlineVariant,
      barWidth: merged.barWidth ?? AudioDefaults.barWidth,
      barSpacing: merged.barSpacing ?? AudioDefaults.barSpacing,
      barRadius: merged.barRadius ?? AudioDefaults.barRadius,
      waveformHeight: merged.waveformHeight ?? AudioDefaults.waveformHeight,
      controlsColor: merged.controlsColor ?? text.primary,
      // What the player is drawn on, so a glyph inside the accent
      // button can be checked against the ACCENT rather than the page.
      surfaceColor: merged.backgroundColor ?? background.cardBackground,
      showSpeed: merged.showSpeed ?? true,
      showLoop: merged.showLoop ?? true,
      showSkip: merged.showSkip ?? true,
      showQueue: merged.showQueue ?? true,
      showSleepTimer: merged.showSleepTimer ?? false,
      enableKeyboard: merged.enableKeyboard ?? true,
      skipSeconds: merged.skipSeconds ?? AudioDefaults.skipSeconds,
      speeds: merged.speeds ?? AudioDefaults.speeds,
      sleepOptions: merged.sleepOptions ?? AudioDefaults.sleepOptions,
      compactHeight: merged.compactHeight ?? AudioDefaults.compactHeight,
      padding: merged.padding ?? AudioDefaults.padding,
      borderRadius:
          merged.borderRadius ?? BorderRadius.circular(context.radii.md),
      timeTextStyle:
          merged.timeTextStyle ??
          TextStyle(
            fontSize: AudioDefaults.timeFontSize,
            fontFeatures: const [FontFeature.tabularFigures()],
            color: text.secondary,
          ),
      backgroundColor: merged.backgroundColor,
      gradient: merged.gradient,
      playButtonGradient: merged.playButtonGradient,
      playButtonShadow: merged.playButtonShadow,
    );
  }
}
