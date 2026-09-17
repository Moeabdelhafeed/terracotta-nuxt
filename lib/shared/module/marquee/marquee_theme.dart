import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';

import '../../../core/responsive/extensions.dart';
import '../../../core/tokens/extensions.dart';
import 'marquee_models.dart';

/// App-wide defaults for [GlobalMarquee].
@immutable
class GlobalMarqueeTheme extends ThemeExtension<GlobalMarqueeTheme> {
  const GlobalMarqueeTheme({this.style});

  final MarqueeStyle? style;

  static GlobalMarqueeTheme? maybeOf(BuildContext context) =>
      Theme.of(context).extension<GlobalMarqueeTheme>();

  @override
  GlobalMarqueeTheme copyWith({MarqueeStyle? style}) =>
      GlobalMarqueeTheme(style: style ?? this.style);

  @override
  GlobalMarqueeTheme lerp(ThemeExtension<GlobalMarqueeTheme>? other, double t) {
    if (other is! GlobalMarqueeTheme) return this;
    return GlobalMarqueeTheme(style: _lerpStyle(style, other.style, t));
  }

  /// Continuous fields interpolate; discrete ones (direction, mode,
  /// the pause flags) snap at the midpoint — half a scroll direction is
  /// not a thing.
  static MarqueeStyle? _lerpStyle(
    MarqueeStyle? a,
    MarqueeStyle? b,
    double t,
  ) {
    if (a == null && b == null) return null;
    final pick = t < 0.5 ? a : b;
    return MarqueeStyle(
      speed: lerpDouble(a?.speed, b?.speed, t),
      gap: lerpDouble(a?.gap, b?.gap, t),
      fadeEdges: pick?.fadeEdges,
      fadeWidth: lerpDouble(a?.fadeWidth, b?.fadeWidth, t),
      pauseOnHover: pick?.pauseOnHover,
      pauseOnTouch: pick?.pauseOnTouch,
      initialPause: pick?.initialPause,
      endPause: pick?.endPause,
      direction: pick?.direction,
      mode: pick?.mode,
    );
  }
}

extension MarqueeStyleResolve on MarqueeStyle {
  /// Stacks `caller > theme > defaults`, then fills the fade ramp from
  /// tokens when nobody specified one.
  ///
  /// Token lookups DEGRADE: a marquee can render outside the app shell
  /// (toasts, overlays) where there is no `BreakpointsProvider`, and a
  /// scrolling label must not require the responsive stack to draw.
  ResolvedMarqueeStyle resolve(BuildContext context) {
    final merged = MarqueeStyle.defaults
        .mergedWith(GlobalMarqueeTheme.maybeOf(context)?.style)
        .mergedWith(this);
    final tokens = context.maybeBreakpoints == null ? null : context.tokens;
    const floor = MarqueeStyle.defaults;

    return ResolvedMarqueeStyle(
      speed: merged.speed ?? floor.speed!,
      gap: merged.gap ?? tokens?.spacing.xl ?? floor.gap!,
      fadeEdges: merged.fadeEdges ?? true,
      fadeWidth: merged.fadeWidth ?? tokens?.spacing.lg ?? floor.fadeWidth!,
      pauseOnHover: merged.pauseOnHover ?? true,
      pauseOnTouch: merged.pauseOnTouch ?? true,
      initialPause: merged.initialPause ?? floor.initialPause!,
      endPause: merged.endPause ?? floor.endPause!,
      direction: merged.direction ?? MarqueeDirection.rtl,
      mode: merged.mode ?? MarqueeMode.loop,
    );
  }
}
