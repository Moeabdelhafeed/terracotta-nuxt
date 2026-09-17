import 'package:flutter/material.dart';

import '../nav_animation_style.dart';

/// App-wide defaults for widgets that animate on a navigation event.
///
/// The rebrand hook: set the house's duration and curve once, here, and
/// every `NavigationAwareAnimation` follows. A caller still wins per
/// widget.
@immutable
class GlobalNavAnimationTheme extends ThemeExtension<GlobalNavAnimationTheme> {
  const GlobalNavAnimationTheme({this.animation});

  /// The open fields every animation inherits — a duration, a curve, a
  /// delay. Setting a slide here would move every widget in the app.
  final WidgetAnimation? animation;

  static GlobalNavAnimationTheme? maybeOf(BuildContext context) =>
      Theme.of(context).extension<GlobalNavAnimationTheme>();

  @override
  GlobalNavAnimationTheme copyWith({WidgetAnimation? animation}) =>
      GlobalNavAnimationTheme(animation: animation ?? this.animation);

  @override
  GlobalNavAnimationTheme lerp(
    ThemeExtension<GlobalNavAnimationTheme>? other,
    double t,
  ) {
    if (other is! GlobalNavAnimationTheme) return this;
    // A bag of independent decisions, not a value with a midpoint. It
    // SNAPS at the halfway mark, like every other bag in this app.
    return t < 0.5 ? this : other;
  }
}

/// Turns a caller's animation into one with every question answered.
extension WidgetAnimationResolve on WidgetAnimation {
  /// `caller > GlobalNavAnimationTheme.animation >
  /// NavAnimationDefaults`, then the two things only a `BuildContext`
  /// knows.
  ResolvedWidgetAnimation resolve(BuildContext context) {
    final merged = WidgetAnimation.defaults
        .mergedWith(GlobalNavAnimationTheme.maybeOf(context)?.animation)
        .mergedWith(this);

    // The READER's setting. A widget that slides across the screen on
    // every push is exactly the motion this exists to stop.
    final respect = merged.respectReducedMotion ?? true;
    if (respect && MediaQuery.disableAnimationsOf(context)) {
      // NOT a shorter animation — none at all, and no delay to sit
      // through before nothing happens.
      return const ResolvedWidgetAnimation(
        duration: Duration.zero,
        curve: Curves.linear,
        delay: Duration.zero,
      );
    }

    // The horizontal travel mirrors only for the directional presets.
    final mirror =
        (merged.mirrorInRtl ?? false) &&
        Directionality.of(context) == TextDirection.rtl;
    Offset? flip(Offset? offset) =>
        offset == null || !mirror ? offset : Offset(-offset.dx, offset.dy);

    return ResolvedWidgetAnimation(
      duration: merged.duration ?? NavAnimationDefaults.duration,
      curve: merged.curve ?? NavAnimationDefaults.curve,
      delay: merged.delay ?? NavAnimationDefaults.delay,
      slideFrom: flip(merged.slideFrom),
      slideTo: flip(merged.slideTo),
      fadeFrom: merged.fadeFrom,
      fadeTo: merged.fadeTo,
      scaleFrom: merged.scaleFrom,
      scaleTo: merged.scaleTo,
    );
  }
}
