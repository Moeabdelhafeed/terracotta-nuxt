import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';

import '../auto_scroller_models.dart';

/// App-wide defaults for [GlobalAutoScroller].
///
/// The rebrand hook is a PACE rather than a palette: an auto-scroller
/// paints nothing of its own. A ticker drifting at one speed on one
/// screen and another elsewhere is the drift this exists to stop.
@immutable
class GlobalAutoScrollerTheme extends ThemeExtension<GlobalAutoScrollerTheme> {
  const GlobalAutoScrollerTheme({this.style});

  final AutoScrollerStyle? style;

  static GlobalAutoScrollerTheme? maybeOf(BuildContext context) =>
      Theme.of(context).extension<GlobalAutoScrollerTheme>();

  @override
  GlobalAutoScrollerTheme copyWith({AutoScrollerStyle? style}) =>
      GlobalAutoScrollerTheme(style: style ?? this.style);

  @override
  GlobalAutoScrollerTheme lerp(
    ThemeExtension<GlobalAutoScrollerTheme>? other,
    double t,
  ) {
    if (other is! GlobalAutoScrollerTheme) return this;
    return GlobalAutoScrollerTheme(style: _lerpStyle(style, other.style, t));
  }

  /// Speed interpolates — a ticker changing pace across a theme
  /// transition should ramp. Everything else SNAPS: half a `bounce` is
  /// not a thing.
  static AutoScrollerStyle? _lerpStyle(
    AutoScrollerStyle? a,
    AutoScrollerStyle? b,
    double t,
  ) {
    if (a == null && b == null) return null;
    final pick = t < 0.5 ? a : b;
    return AutoScrollerStyle(
      speed: lerpDouble(a?.speed, b?.speed, t),
      loopMode: pick?.loopMode,
      pauseOnInteraction: pick?.pauseOnInteraction,
      resumeDelay: pick?.resumeDelay,
      respectReducedMotion: pick?.respectReducedMotion,
      pauseOnHover: pick?.pauseOnHover,
      pauseWhenAccessibleNavigation: pick?.pauseWhenAccessibleNavigation,
      startDelay: pick?.startDelay,
      // A DISTANCE, so it interpolates with the speed it modulates.
      edgeEaseDistance: lerpDouble(
        a?.edgeEaseDistance,
        b?.edgeEaseDistance,
        t,
      ),
      edgeEaseFloor: lerpDouble(a?.edgeEaseFloor, b?.edgeEaseFloor, t),
    );
  }
}

extension AutoScrollerStyleResolve on AutoScrollerStyle {
  /// Stacks `caller > GlobalAutoScrollerTheme.style > defaults`.
  ResolvedAutoScrollerStyle resolve(BuildContext context) {
    final merged = AutoScrollerStyle.defaults
        .mergedWith(GlobalAutoScrollerTheme.maybeOf(context)?.style)
        .mergedWith(this);
    const floor = AutoScrollerStyle.defaults;

    final respect = merged.respectReducedMotion ?? floor.respectReducedMotion!;
    final still = respect && MediaQuery.disableAnimationsOf(context);

    return ResolvedAutoScrollerStyle(
      // ZERO, not slower. This is motion with no other purpose —
      // nothing is being said that standing still does not say — so a
      // reader who asked for less of it has asked for none of this.
      speed: still ? 0 : (merged.speed ?? floor.speed!),
      loopMode: merged.loopMode ?? floor.loopMode!,
      pauseOnInteraction:
          merged.pauseOnInteraction ?? floor.pauseOnInteraction!,
      resumeDelay: merged.resumeDelay ?? floor.resumeDelay!,
      still: still,
      pauseOnHover: merged.pauseOnHover ?? floor.pauseOnHover!,
      pauseWhenAccessibleNavigation:
          merged.pauseWhenAccessibleNavigation ??
          floor.pauseWhenAccessibleNavigation!,
      // A parked rail does not owe anyone a beat first.
      startDelay: still
          ? Duration.zero
          : (merged.startDelay ?? floor.startDelay!),
      edgeEaseDistance: merged.edgeEaseDistance ?? floor.edgeEaseDistance!,
      edgeEaseFloor: merged.edgeEaseFloor ?? floor.edgeEaseFloor!,
    );
  }
}
