import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';

import '../stack_models.dart';

/// App-wide defaults for `GlobalCardStack` AND `GlobalLayeredStack`.
///
/// ONE extension for the two, because what they share is the one
/// thing a house sets: the geometry of depth. Two extensions would be
/// two rebrand hooks that can disagree, and a screen showing a swipe
/// deck beside a notification pile would show two different ideas of
/// how deep a deck looks.
@immutable
class GlobalStackTheme extends ThemeExtension<GlobalStackTheme> {
  const GlobalStackTheme({this.style});

  final StackStyle? style;

  static GlobalStackTheme? maybeOf(BuildContext context) =>
      Theme.of(context).extension<GlobalStackTheme>();

  @override
  GlobalStackTheme copyWith({StackStyle? style}) =>
      GlobalStackTheme(style: style ?? this.style);

  @override
  GlobalStackTheme lerp(ThemeExtension<GlobalStackTheme>? other, double t) {
    if (other is! GlobalStackTheme) return this;
    return GlobalStackTheme(style: _lerpStyle(style, other.style, t));
  }

  /// The measurements interpolate — a deck deepening across a theme
  /// change should move rather than jump. The discrete ones SNAP at
  /// the halfway mark: half a `bottomRight` is not a direction, and
  /// two and a half cards is not a count.
  static StackStyle? _lerpStyle(StackStyle? a, StackStyle? b, double t) {
    if (a == null && b == null) return null;
    final pick = t < 0.5 ? a : b;
    return StackStyle(
      visibleDepth: pick?.visibleDepth,
      scaleStep: lerpDouble(a?.scaleStep, b?.scaleStep, t),
      peekOffset: lerpDouble(a?.peekOffset, b?.peekOffset, t),
      peekDirection: pick?.peekDirection,
      opacityStep: lerpDouble(a?.opacityStep, b?.opacityStep, t),
      minScale: lerpDouble(a?.minScale, b?.minScale, t),
      duration: pick?.duration,
      curve: pick?.curve,
      swipeThreshold: lerpDouble(a?.swipeThreshold, b?.swipeThreshold, t),
      maxRotationDegrees: lerpDouble(
        a?.maxRotationDegrees,
        b?.maxRotationDegrees,
        t,
      ),
      flingVelocity: lerpDouble(a?.flingVelocity, b?.flingVelocity, t),
      snapDuration: pick?.snapDuration,
      dismissDuration: pick?.dismissDuration,
      enableHaptic: pick?.enableHaptic,
      undoLimit: pick?.undoLimit,
      rotationAnchorY: lerpDouble(a?.rotationAnchorY, b?.rotationAnchorY, t),
      respectReducedMotion: pick?.respectReducedMotion,
    );
  }
}

extension StackStyleResolve on StackStyle {
  /// Stacks `caller > GlobalStackTheme.style > StackStyle.defaults`.
  ResolvedStackStyle resolve(BuildContext context) {
    final merged = StackStyle.defaults
        .mergedWith(GlobalStackTheme.maybeOf(context)?.style)
        .mergedWith(this);
    const floor = StackStyle.defaults;

    final respect = merged.respectReducedMotion ?? floor.respectReducedMotion!;
    final still = respect && MediaQuery.disableAnimationsOf(context);

    return ResolvedStackStyle(
      visibleDepth: merged.visibleDepth ?? floor.visibleDepth!,
      scaleStep: merged.scaleStep ?? floor.scaleStep!,
      peekOffset: merged.peekOffset ?? floor.peekOffset!,
      peekDirection: merged.peekDirection ?? floor.peekDirection!,
      opacityStep: merged.opacityStep ?? floor.opacityStep!,
      minScale: merged.minScale ?? floor.minScale!,
      // The DEPTH stays — it is layout, and a deck with no depth is
      // not a deck. Only the travel between depths goes.
      duration: still ? Duration.zero : (merged.duration ?? floor.duration!),
      curve: merged.curve ?? floor.curve!,
      // The tilt is the decorative half of the swipe. The card still
      // leaves; it just leaves flat.
      maxRotationDegrees: still
          ? 0
          : (merged.maxRotationDegrees ?? floor.maxRotationDegrees!),
      swipeThreshold: merged.swipeThreshold ?? floor.swipeThreshold!,
      // NOT zeroed: a flick is an input, not an animation, and a deck
      // that stopped answering flicks would be harder to use, which
      // is the opposite of what was asked for.
      flingVelocity: merged.flingVelocity ?? floor.flingVelocity!,
      snapDuration: still
          ? Duration.zero
          : (merged.snapDuration ?? floor.snapDuration!),
      dismissDuration: still
          ? Duration.zero
          : (merged.dismissDuration ?? floor.dismissDuration!),
      enableHaptic: merged.enableHaptic ?? floor.enableHaptic!,
      undoLimit: merged.undoLimit ?? floor.undoLimit!,
      // A card that does not travel does not pivot either.
      rotationAnchorY: still
          ? 0
          : (merged.rotationAnchorY ?? floor.rotationAnchorY!),
      still: still,
    );
  }
}
