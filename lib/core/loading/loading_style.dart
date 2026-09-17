import 'package:flutter/material.dart';

import 'loading_surface.dart';

/// The floor for `LoadingOverlay`'s LOOK.
abstract final class LoadingDefaults {
  /// Which surface a `show()` puts up when it names none.
  static const surface = LoadingSurface.scrim;

  /// Alpha of the blocking backdrop.
  static const scrimOpacity = 0.45;

  /// Alpha of the gentler one — "input blocked, look elsewhere".
  static const dimOpacity = 0.18;

  static const enableBackdropBlur = false;
  static const backdropBlurSigma = 6.0;

  /// The default Material spinner.
  static const spinnerSize = 36.0;

  /// How long the overlay takes to fade in and out.
  static const fadeDuration = Duration(milliseconds: 220);

  /// The non-blocking bar at the top.
  static const barHeight = 3.0;

  /// Whether that bar sits BELOW the status bar rather than under it.
  ///
  /// True. It used to be pinned to absolute zero so it "hugs the
  /// screen edge", and with edge-to-edge on — which `initSystemChrome`
  /// enables — three pixels at y=0 are behind the clock. A progress
  /// bar nobody can see is not a progress bar.
  ///
  /// On desktop and web the inset is zero, so the flush look is what
  /// they get either way.
  static const topBarClearsStatusBar = true;

  /// Space between the spinner and the label under it.
  static const labelGap = 16.0;

  static const respectReducedMotion = true;
}

/// How `LoadingOverlay` LOOKS.
///
/// Every field is nullable: unanswered means "ask the theme, then the
/// floor".
///
/// Separate from `LoadingOptions`, which says how the overlay
/// BEHAVES — how long before it appears, how long it stays, when it
/// times out, whether a tap outside dismisses it. Those are timing
/// and policy; a house does not rebrand them, and it very much does
/// rebrand the scrim.
///
/// They were one class, and it was only settable where the overlay is
/// MOUNTED — once, in `MyApp` — so an app could not theme its own
/// loading state at all.
@immutable
class LoadingStyle {
  const LoadingStyle({
    this.surface,
    this.scrimColor,
    this.scrimOpacity,
    this.dimOpacity,
    this.enableBackdropBlur,
    this.backdropBlurSigma,
    this.spinnerSize,
    this.spinnerColor,
    this.fadeDuration,
    this.barHeight,
    this.topBarClearsStatusBar,
    this.labelGap,
    this.labelStyle,
    this.spinnerBuilder,
    this.respectReducedMotion,
  });

  /// The floor — the only place a compile-time constant lives.
  static const defaults = LoadingStyle(
    surface: LoadingDefaults.surface,
    scrimOpacity: LoadingDefaults.scrimOpacity,
    dimOpacity: LoadingDefaults.dimOpacity,
    enableBackdropBlur: LoadingDefaults.enableBackdropBlur,
    backdropBlurSigma: LoadingDefaults.backdropBlurSigma,
    spinnerSize: LoadingDefaults.spinnerSize,
    fadeDuration: LoadingDefaults.fadeDuration,
    barHeight: LoadingDefaults.barHeight,
    topBarClearsStatusBar: LoadingDefaults.topBarClearsStatusBar,
    labelGap: LoadingDefaults.labelGap,
    respectReducedMotion: LoadingDefaults.respectReducedMotion,
  );

  /// Barely there — a light dim and no spinner, for a screen that
  /// draws its own progress inline.
  static const quiet = LoadingStyle(
    surface: LoadingSurface.dim,
    dimOpacity: 0.12,
  );

  /// A heavier block, for an operation that must not be interrupted.
  static const blocking = LoadingStyle(
    surface: LoadingSurface.scrim,
    scrimOpacity: 0.62,
    enableBackdropBlur: true,
  );

  /// Which surface `show()` puts up when it names none.
  final LoadingSurface? surface;

  /// The backdrop tint. Null resolves from the palette.
  final Color? scrimColor;

  final double? scrimOpacity;
  final double? dimOpacity;
  final bool? enableBackdropBlur;
  final double? backdropBlurSigma;
  final double? spinnerSize;

  /// The spinner's colour. Null resolves from the palette.
  final Color? spinnerColor;

  final Duration? fadeDuration;
  final double? barHeight;

  /// Whether the top bar sits below the status bar rather than under
  /// it. Set false for a bar flush with the screen edge — which only
  /// looks right where there is no status bar over it.
  final bool? topBarClearsStatusBar;

  final double? labelGap;

  /// The label under the spinner. Null takes the app's own body
  /// style.
  final TextStyle? labelStyle;

  /// A branded indicator in place of the Material one.
  ///
  /// Returns the SPINNER only — the overlay still draws the scrim,
  /// the label and the cancel button. To replace the whole thing use
  /// `LoadingOptions.contentBuilder`.
  final WidgetBuilder? spinnerBuilder;

  /// Whether `MediaQuery.disableAnimationsOf` flattens the FADE.
  ///
  /// The spinner itself keeps turning: it is the only thing on screen
  /// saying the app is alive, and a still one reads as a freeze —
  /// which is the opposite of what a reader who dislikes motion is
  /// asking for.
  final bool? respectReducedMotion;

  /// Field-by-field: whatever `other` answers wins, and what it leaves
  /// null keeps this bag's answer.
  LoadingStyle mergedWith(LoadingStyle? other) {
    if (other == null) return this;
    return LoadingStyle(
      surface: other.surface ?? surface,
      scrimColor: other.scrimColor ?? scrimColor,
      scrimOpacity: other.scrimOpacity ?? scrimOpacity,
      dimOpacity: other.dimOpacity ?? dimOpacity,
      enableBackdropBlur: other.enableBackdropBlur ?? enableBackdropBlur,
      backdropBlurSigma: other.backdropBlurSigma ?? backdropBlurSigma,
      spinnerSize: other.spinnerSize ?? spinnerSize,
      spinnerColor: other.spinnerColor ?? spinnerColor,
      fadeDuration: other.fadeDuration ?? fadeDuration,
      barHeight: other.barHeight ?? barHeight,
      topBarClearsStatusBar:
          other.topBarClearsStatusBar ?? topBarClearsStatusBar,
      labelGap: other.labelGap ?? labelGap,
      labelStyle: other.labelStyle ?? labelStyle,
      spinnerBuilder: other.spinnerBuilder ?? spinnerBuilder,
      respectReducedMotion: other.respectReducedMotion ?? respectReducedMotion,
    );
  }

  LoadingStyle copyWith({
    LoadingSurface? surface,
    Color? scrimColor,
    double? scrimOpacity,
    double? dimOpacity,
    bool? enableBackdropBlur,
    double? backdropBlurSigma,
    double? spinnerSize,
    Color? spinnerColor,
    Duration? fadeDuration,
    double? barHeight,
    bool? topBarClearsStatusBar,
    double? labelGap,
    TextStyle? labelStyle,
    WidgetBuilder? spinnerBuilder,
    bool? respectReducedMotion,
  }) => LoadingStyle(
    surface: surface ?? this.surface,
    scrimColor: scrimColor ?? this.scrimColor,
    scrimOpacity: scrimOpacity ?? this.scrimOpacity,
    dimOpacity: dimOpacity ?? this.dimOpacity,
    enableBackdropBlur: enableBackdropBlur ?? this.enableBackdropBlur,
    backdropBlurSigma: backdropBlurSigma ?? this.backdropBlurSigma,
    spinnerSize: spinnerSize ?? this.spinnerSize,
    spinnerColor: spinnerColor ?? this.spinnerColor,
    fadeDuration: fadeDuration ?? this.fadeDuration,
    barHeight: barHeight ?? this.barHeight,
    topBarClearsStatusBar: topBarClearsStatusBar ?? this.topBarClearsStatusBar,
    labelGap: labelGap ?? this.labelGap,
    labelStyle: labelStyle ?? this.labelStyle,
    spinnerBuilder: spinnerBuilder ?? this.spinnerBuilder,
    respectReducedMotion: respectReducedMotion ?? this.respectReducedMotion,
  );

  @override
  bool operator ==(Object other) =>
      other is LoadingStyle &&
      other.surface == surface &&
      other.scrimColor == scrimColor &&
      other.scrimOpacity == scrimOpacity &&
      other.dimOpacity == dimOpacity &&
      other.enableBackdropBlur == enableBackdropBlur &&
      other.backdropBlurSigma == backdropBlurSigma &&
      other.spinnerSize == spinnerSize &&
      other.spinnerColor == spinnerColor &&
      other.fadeDuration == fadeDuration &&
      other.barHeight == barHeight &&
      other.topBarClearsStatusBar == topBarClearsStatusBar &&
      other.labelGap == labelGap &&
      other.labelStyle == labelStyle &&
      other.spinnerBuilder == spinnerBuilder &&
      other.respectReducedMotion == respectReducedMotion;

  @override
  int get hashCode => Object.hashAll([
    surface,
    scrimColor,
    scrimOpacity,
    dimOpacity,
    enableBackdropBlur,
    backdropBlurSigma,
    spinnerSize,
    spinnerColor,
    fadeDuration,
    barHeight,
    topBarClearsStatusBar,
    labelGap,
    labelStyle,
    spinnerBuilder,
    respectReducedMotion,
  ]);
}

/// A [LoadingStyle] with every question answered.
@immutable
class ResolvedLoadingStyle {
  const ResolvedLoadingStyle({
    required this.surface,
    required this.scrimColor,
    required this.scrimOpacity,
    required this.dimOpacity,
    required this.enableBackdropBlur,
    required this.backdropBlurSigma,
    required this.spinnerSize,
    required this.spinnerColor,
    required this.fadeDuration,
    required this.barHeight,
    required this.topBarClearsStatusBar,
    required this.labelGap,
    required this.still,
    this.labelStyle,
    this.spinnerBuilder,
  });

  final LoadingSurface surface;
  final Color scrimColor;
  final double scrimOpacity;
  final double dimOpacity;
  final bool enableBackdropBlur;
  final double backdropBlurSigma;
  final double spinnerSize;
  final Color spinnerColor;

  /// ZERO when [still] — the overlay is simply there, then simply
  /// gone.
  final Duration fadeDuration;

  final double barHeight;
  final bool topBarClearsStatusBar;
  final double labelGap;
  final TextStyle? labelStyle;
  final WidgetBuilder? spinnerBuilder;

  /// Whether the reader has asked for motion to stop.
  final bool still;

  /// The backdrop's alpha for [surface].
  double get backdropOpacity =>
      surface == LoadingSurface.dim ? dimOpacity : scrimOpacity;
}
