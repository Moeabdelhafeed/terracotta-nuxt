import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';

import '../../extensions/theme_colors_extension.dart';
import '../loading_style.dart';

/// App-wide defaults for `LoadingOverlay`.
///
/// The overlay is mounted ONCE, in `MyApp`, so its look was settable
/// only there — an app could not theme its own loading state, which is
/// one of the few surfaces every user sees.
@immutable
class GlobalLoadingTheme extends ThemeExtension<GlobalLoadingTheme> {
  const GlobalLoadingTheme({this.style});

  final LoadingStyle? style;

  static GlobalLoadingTheme? maybeOf(BuildContext context) =>
      Theme.of(context).extension<GlobalLoadingTheme>();

  @override
  GlobalLoadingTheme copyWith({LoadingStyle? style}) =>
      GlobalLoadingTheme(style: style ?? this.style);

  @override
  GlobalLoadingTheme lerp(
    ThemeExtension<GlobalLoadingTheme>? other,
    double t,
  ) {
    if (other is! GlobalLoadingTheme) return this;
    return GlobalLoadingTheme(style: _lerpStyle(style, other.style, t));
  }

  /// Colours and measurements interpolate. The SURFACE snaps — half a
  /// scrim and half a top bar is neither — and so do the builders.
  static LoadingStyle? _lerpStyle(
    LoadingStyle? a,
    LoadingStyle? b,
    double t,
  ) {
    if (a == null && b == null) return null;
    final pick = t < 0.5 ? a : b;
    return LoadingStyle(
      surface: pick?.surface,
      scrimColor: Color.lerp(a?.scrimColor, b?.scrimColor, t),
      scrimOpacity: lerpDouble(a?.scrimOpacity, b?.scrimOpacity, t),
      dimOpacity: lerpDouble(a?.dimOpacity, b?.dimOpacity, t),
      enableBackdropBlur: pick?.enableBackdropBlur,
      backdropBlurSigma: lerpDouble(
        a?.backdropBlurSigma,
        b?.backdropBlurSigma,
        t,
      ),
      spinnerSize: lerpDouble(a?.spinnerSize, b?.spinnerSize, t),
      spinnerColor: Color.lerp(a?.spinnerColor, b?.spinnerColor, t),
      fadeDuration: pick?.fadeDuration,
      barHeight: lerpDouble(a?.barHeight, b?.barHeight, t),
      topBarClearsStatusBar: pick?.topBarClearsStatusBar,
      labelGap: lerpDouble(a?.labelGap, b?.labelGap, t),
      labelStyle: TextStyle.lerp(a?.labelStyle, b?.labelStyle, t),
      spinnerBuilder: pick?.spinnerBuilder,
      respectReducedMotion: pick?.respectReducedMotion,
    );
  }
}

extension LoadingStyleResolve on LoadingStyle {
  /// Stacks `caller > GlobalLoadingTheme.style > LoadingStyle.defaults`.
  ResolvedLoadingStyle resolve(BuildContext context) {
    final merged = LoadingStyle.defaults
        .mergedWith(GlobalLoadingTheme.maybeOf(context)?.style)
        .mergedWith(this);
    const floor = LoadingStyle.defaults;

    final respect = merged.respectReducedMotion ?? floor.respectReducedMotion!;
    final still = respect && MediaQuery.disableAnimationsOf(context);

    return ResolvedLoadingStyle(
      surface: merged.surface ?? floor.surface!,
      // From the PALETTE. It used to be `colorScheme.scrim`, which is
      // Material's answer rather than the app's role-aware one.
      scrimColor: merged.scrimColor ?? context.overlayColors.scrim,
      scrimOpacity: merged.scrimOpacity ?? floor.scrimOpacity!,
      dimOpacity: merged.dimOpacity ?? floor.dimOpacity!,
      enableBackdropBlur:
          merged.enableBackdropBlur ?? floor.enableBackdropBlur!,
      backdropBlurSigma: merged.backdropBlurSigma ?? floor.backdropBlurSigma!,
      spinnerSize: merged.spinnerSize ?? floor.spinnerSize!,
      spinnerColor: merged.spinnerColor ?? context.primaryColors.primary,
      // The FADE goes; the spinner does not. A still spinner is the
      // only thing on screen saying the app is alive, and stopping it
      // reads as a freeze.
      fadeDuration: still
          ? Duration.zero
          : (merged.fadeDuration ?? floor.fadeDuration!),
      barHeight: merged.barHeight ?? floor.barHeight!,
      topBarClearsStatusBar:
          merged.topBarClearsStatusBar ?? floor.topBarClearsStatusBar!,
      labelGap: merged.labelGap ?? floor.labelGap!,
      labelStyle: merged.labelStyle,
      spinnerBuilder: merged.spinnerBuilder,
      still: still,
    );
  }
}
