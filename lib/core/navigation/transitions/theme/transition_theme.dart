import 'package:flutter/material.dart';

import '../transition_style.dart';

/// App-wide defaults for page transitions.
///
/// The rebrand hook: set the house's duration, curve and default
/// transition once, here, and every route follows — including the ones
/// an adopter adds later, which is the point. A route still wins per
/// push, and a `TransitionOverride` in the extras wins over that.
@immutable
class GlobalTransitionTheme extends ThemeExtension<GlobalTransitionTheme> {
  const GlobalTransitionTheme({this.style});

  final TransitionStyle? style;

  static GlobalTransitionTheme? maybeOf(BuildContext context) =>
      Theme.of(context).extension<GlobalTransitionTheme>();

  @override
  GlobalTransitionTheme copyWith({TransitionStyle? style}) =>
      GlobalTransitionTheme(style: style ?? this.style);

  @override
  GlobalTransitionTheme lerp(
    ThemeExtension<GlobalTransitionTheme>? other,
    double t,
  ) {
    if (other is! GlobalTransitionTheme) return this;
    // A style is a bag of independent decisions, not a value with a
    // midpoint — half a `morphRotate` means nothing. It SNAPS at the
    // halfway mark, which is what every other bag in this app does.
    return t < 0.5 ? this : other;
  }
}

/// Turns a caller's bag into one with every question answered.
extension TransitionStyleResolve on TransitionStyle {
  /// `caller > GlobalTransitionTheme.style > TransitionStyle.defaults`,
  /// then the two things only a `BuildContext` knows.
  ///
  /// This is the ONE place reduced motion and the reading direction are
  /// applied. Per builder means twelve chances to forget, and all
  /// twelve forgot both.
  ResolvedTransitionStyle resolve(BuildContext context) {
    final merged = TransitionStyle.defaults
        .mergedWith(GlobalTransitionTheme.maybeOf(context)?.style)
        .mergedWith(this);

    var type = merged.type ?? TransitionType.none;

    // The READER's setting, which is not the caller's. A full-screen
    // page transition is the largest motion in the app, so this is the
    // last place that should ignore it.
    final respect = merged.respectReducedMotion ?? true;
    if (respect && MediaQuery.disableAnimationsOf(context)) {
      type = TransitionType.none;
    }

    return ResolvedTransitionStyle(
      type: type,
      // `none` is not a fast transition, it is no transition — a
      // non-zero duration there leaves the route sitting on an empty
      // animation before it appears.
      duration: type == TransitionType.none
          ? Duration.zero
          : (merged.duration ?? TransitionDefaults.duration),
      curve: merged.curve ?? TransitionDefaults.curve,
      // Nothing to swipe back through when nothing animated.
      swipeEnabled:
          (merged.swipeEnabled ?? TransitionDefaults.swipeEnabled) &&
          type != TransitionType.none,
      slideFraction: merged.slideFraction ?? TransitionDefaults.slideFraction,
      scaleBegin: merged.scaleBegin ?? TransitionDefaults.scaleBegin,
      textDirection: Directionality.of(context),
    );
  }
}
