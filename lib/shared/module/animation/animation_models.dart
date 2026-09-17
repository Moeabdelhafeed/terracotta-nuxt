import 'package:flutter/material.dart';

/// The type of animated content.
enum AnimationType { gif, lottieJson, dotLottie }

/// How the animation source is provided.
enum AnimationSourceType { asset, network, file }

/// Loop behavior for animations.
enum AnimationLoopMode {
  /// Play once and stop at the last frame.
  playOnce,

  /// Loop continuously.
  loop,

  /// Play forward then backward repeatedly.
  pingPong,
}

/// A live view of what a player is doing.
///
/// Handed to `onStateChanged` and to `AnimationHandle.stateStream`, so
/// chrome outside the widget can follow it without reaching into a
/// `State` through a `GlobalKey`.
@immutable
class AnimationStateSnapshot {
  const AnimationStateSnapshot({
    required this.playing,
    required this.progress,
    required this.speed,
    required this.loaded,
    required this.errored,
    required this.reducedMotion,
    this.duration,
    this.error,
  });

  static const empty = AnimationStateSnapshot(
    playing: false,
    progress: 0,
    speed: 1,
    loaded: false,
    errored: false,
    reducedMotion: false,
  );

  final bool playing;

  /// 0..1 through the composition. Always 0 for a GIF — Flutter's
  /// decoder owns the frame clock and does not report where it is.
  final double progress;

  final double speed;
  final bool loaded;
  final bool errored;

  /// Whether the platform asked for less motion AND this player agreed
  /// to listen. A still animation is otherwise indistinguishable from
  /// one that failed.
  final bool reducedMotion;

  /// Null for a GIF, and until a Lottie composition has loaded.
  final Duration? duration;

  final String? error;
}

// ---------------------------------------------------------------------------
// Constants
// ---------------------------------------------------------------------------

/// Geometry and tolerances that only change when this module changes.
/// Anything an app would rebrand lives on [GlobalAnimationStyle] instead.
abstract final class AnimationDefaults {
  static const controlsIconSize = 24.0;
  static const progressBarHeight = 3.0;
  static const radius = 8.0;

  /// How tall the loading placeholder stands when the caller gave no
  /// height. A shimmer with no size is a shimmer nobody sees.
  static const placeholderHeight = 200.0;

  /// The scrim behind the transport row. It sits over the animation,
  /// whose colours nothing here controls, so it is an opacity on the
  /// surface rather than a colour.
  static const controlsScrimOpacity = 0.08;

  /// The percentage read-out beside the transport buttons.
  static const progressTextOpacity = 0.70;

  /// The pill behind the speed multiplier.
  static const speedPillOpacity = 0.12;

  /// Below this, the error plate is the GLYPH alone. A glyph plus a
  /// headline plus a retry line comes to about 150dp, and an animation
  /// smaller than that is common — a 40dp spinner, an inline badge.
  static const errorPlateMinHeight = 132.0;

  /// How long a player may go unpainted before it counts as off-screen.
  /// One frame is not enough — a repaint boundary or a scroll can skip
  /// a frame without the widget having left the viewport.
  static const offscreenGrace = Duration(milliseconds: 300);

  /// How much of a player has to be on screen to count as visible.
  /// Zero would restart it for a single row of pixels at the edge.
  static const visibleFraction = 0.05;

  /// What the speed control cycles through.
  static const speeds = <double>[0.5, 1.0, 1.5, 2.0, 3.0];

  /// Speed is a DIVISOR of the composition's duration, so zero is an
  /// infinite animation and a negative is a negative `Duration` — both
  /// of which throw rather than misbehave visibly.
  static const minSpeed = 0.05;
  static const maxSpeed = 20.0;
}

// ---------------------------------------------------------------------------
// GlobalAnimationStyle
// ---------------------------------------------------------------------------

/// Themeable styling bag for `GlobalAnimation` — EVERY field nullable.
///
/// It keeps the `Global` prefix where the other bags drop it
/// (`PdfStyle`, `BannerStyle`, `ChipStyle`): Flutter's own
/// `material.dart` exports an `AnimationStyle`, and a module that
/// imports Material — which is all of them — cannot name a second one.
///
/// Resolution order, materialized once per build by
/// `style.resolve(context)`:
/// `caller > GlobalAnimationTheme.style > GlobalAnimationStyle.defaults > palette`.
///
/// Adding a themed field means touching five places: here, [mergedWith],
/// [copyWith], [ResolvedAnimationStyle] and `GlobalAnimationTheme.lerp`.
@immutable
class GlobalAnimationStyle {
  const GlobalAnimationStyle({
    this.backgroundColor,
    this.borderRadius,
    this.border,
    this.boxShadow,
    this.showControls,
    this.controlsColor,
    this.controlsBackgroundColor,
    this.controlsIconSize,
    this.showProgressBar,
    this.progressBarColor,
    this.progressBarBackgroundColor,
    this.progressBarHeight,
    this.errorWidget,
    this.loadingWidget,
    this.respectReducedMotion,
  });

  /// Compile-time floor. Colours are deliberately absent: they resolve
  /// from the palette at build time, so an animation tracks the app's
  /// role, brightness and saturation.
  static const GlobalAnimationStyle defaults = GlobalAnimationStyle(
    showControls: false,
    showProgressBar: false,
    controlsIconSize: AnimationDefaults.controlsIconSize,
    progressBarHeight: AnimationDefaults.progressBarHeight,
    respectReducedMotion: true,
  );

  /// Surface behind the animation. Null paints nothing — an animation
  /// usually carries its own background, and a box under it is the
  /// exception.
  final Color? backgroundColor;

  final BorderRadius? borderRadius;
  final Border? border;
  final List<BoxShadow>? boxShadow;

  /// Whether the transport row is drawn.
  final bool? showControls;

  /// Tint for the transport icons and the read-out. Null takes the
  /// palette primary.
  final Color? controlsColor;

  /// Surface behind the transport row. Null washes the palette's
  /// surface, because the row sits over the animation.
  final Color? controlsBackgroundColor;

  final double? controlsIconSize;

  final bool? showProgressBar;

  /// Null takes [controlsColor].
  final Color? progressBarColor;

  final Color? progressBarBackgroundColor;
  final double? progressBarHeight;

  /// Replaces the error plate entirely. The default one is tappable to
  /// retry, so a replacement should be too.
  final Widget? errorWidget;

  /// Replaces the loading placeholder. The default is a shimmer sized
  /// to the caller's box.
  final Widget? loadingWidget;

  /// Whether "reduce motion" stops this animation from playing itself.
  ///
  /// ON. A looping decoration is exactly what the setting is for, and
  /// the module could not honour it before — Flutter already pauses
  /// GIFs under `disableAnimations`, so a Lottie beside one kept
  /// playing while the GIF next to it stood still.
  ///
  /// Turn it OFF for an animation that IS the content rather than
  /// decoration — a chart that only reads as motion, a video-like
  /// explainer someone opened on purpose.
  final bool? respectReducedMotion;

  /// Field-by-field override — anything set on [other] wins.
  GlobalAnimationStyle mergedWith(GlobalAnimationStyle? other) {
    if (other == null) return this;
    return GlobalAnimationStyle(
      backgroundColor: other.backgroundColor ?? backgroundColor,
      borderRadius: other.borderRadius ?? borderRadius,
      border: other.border ?? border,
      boxShadow: other.boxShadow ?? boxShadow,
      showControls: other.showControls ?? showControls,
      controlsColor: other.controlsColor ?? controlsColor,
      controlsBackgroundColor:
          other.controlsBackgroundColor ?? controlsBackgroundColor,
      controlsIconSize: other.controlsIconSize ?? controlsIconSize,
      showProgressBar: other.showProgressBar ?? showProgressBar,
      progressBarColor: other.progressBarColor ?? progressBarColor,
      progressBarBackgroundColor:
          other.progressBarBackgroundColor ?? progressBarBackgroundColor,
      progressBarHeight: other.progressBarHeight ?? progressBarHeight,
      errorWidget: other.errorWidget ?? errorWidget,
      loadingWidget: other.loadingWidget ?? loadingWidget,
      respectReducedMotion: other.respectReducedMotion ?? respectReducedMotion,
    );
  }

  GlobalAnimationStyle copyWith({
    Color? backgroundColor,
    BorderRadius? borderRadius,
    Border? border,
    List<BoxShadow>? boxShadow,
    bool? showControls,
    Color? controlsColor,
    Color? controlsBackgroundColor,
    double? controlsIconSize,
    bool? showProgressBar,
    Color? progressBarColor,
    Color? progressBarBackgroundColor,
    double? progressBarHeight,
    Widget? errorWidget,
    Widget? loadingWidget,
    bool? respectReducedMotion,
  }) => GlobalAnimationStyle(
    backgroundColor: backgroundColor ?? this.backgroundColor,
    borderRadius: borderRadius ?? this.borderRadius,
    border: border ?? this.border,
    boxShadow: boxShadow ?? this.boxShadow,
    showControls: showControls ?? this.showControls,
    controlsColor: controlsColor ?? this.controlsColor,
    controlsBackgroundColor:
        controlsBackgroundColor ?? this.controlsBackgroundColor,
    controlsIconSize: controlsIconSize ?? this.controlsIconSize,
    showProgressBar: showProgressBar ?? this.showProgressBar,
    progressBarColor: progressBarColor ?? this.progressBarColor,
    progressBarBackgroundColor:
        progressBarBackgroundColor ?? this.progressBarBackgroundColor,
    progressBarHeight: progressBarHeight ?? this.progressBarHeight,
    errorWidget: errorWidget ?? this.errorWidget,
    loadingWidget: loadingWidget ?? this.loadingWidget,
    respectReducedMotion: respectReducedMotion ?? this.respectReducedMotion,
  );
}

// ---------------------------------------------------------------------------
// ResolvedAnimationStyle
// ---------------------------------------------------------------------------

/// [GlobalAnimationStyle] after `caller > theme > defaults > palette`. Every
/// themed field is non-null, so build code reads `rs.controlsColor` with
/// no `??` ladder behind it.
@immutable
class ResolvedAnimationStyle {
  const ResolvedAnimationStyle({
    required this.backgroundColor,
    required this.borderRadius,
    required this.border,
    required this.boxShadow,
    required this.showControls,
    required this.controlsColor,
    required this.controlsBackgroundColor,
    required this.controlsIconSize,
    required this.showProgressBar,
    required this.progressBarColor,
    required this.progressBarBackgroundColor,
    required this.progressBarHeight,
    required this.errorWidget,
    required this.loadingWidget,
    required this.respectReducedMotion,
  });

  /// Null paints nothing, which is not the same as painting the
  /// surface: an animation with its own background does not want a box
  /// behind it.
  final Color? backgroundColor;

  final BorderRadius? borderRadius;
  final Border? border;
  final List<BoxShadow>? boxShadow;
  final bool showControls;
  final Color controlsColor;
  final Color controlsBackgroundColor;
  final double controlsIconSize;
  final bool showProgressBar;
  final Color progressBarColor;
  final Color? progressBarBackgroundColor;
  final double progressBarHeight;
  final Widget? errorWidget;
  final Widget? loadingWidget;
  final bool respectReducedMotion;
}
