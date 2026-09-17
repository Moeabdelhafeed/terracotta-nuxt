import 'package:flutter/material.dart';

/// Visual transform applied between page positions.
///
/// `slide` keeps Flutter's default `PageView` translation; every
/// other value layers an additional transform (or replaces it) on
/// top of the natural page motion using the page-fraction value
/// — distance from the currently-centered page in `(-∞, +∞)`,
/// typically clamped to roughly `[-1.5, +1.5]` for visible pages.
enum PageTransition {
  /// Default. Native PageView translate.
  slide,

  /// Fade in / out by distance from center.
  fade,

  /// Neighbours shrink, centered page at 1.0.
  scale,

  /// Scale + fade combined — Apple-ish "depth" feel.
  depth,

  /// Background-style translate at half speed — caller's content
  /// shifts at half the native page distance, simulating parallax.
  parallax,

  /// 3D cube rotation between pages (90° per page).
  cube,

  /// 3D flip around the cross axis between pages.
  flip,

  /// iPod-style — neighbours tilted in perspective + scaled.
  coverflow,

  /// Main-axis fold-out — neighbours scale toward 0 along the
  /// scroll axis (vertical compresses Y, horizontal compresses X)
  /// anchored on the leading edge.
  accordion,

  /// Pages zoom away into the distance + fade, centered page at
  /// full size. Cinematic "tunnel" feel.
  tunnel,

  /// 2D spin + scale — neighbours rotate around Z and shrink.
  vortex,

  /// 3D swing around the leading edge — like a door opening AWAY
  /// from the camera.
  swing,
}

/// Apply a [PageTransition] to `child` given its current
/// `pageFraction` (signed distance from center — 0 = centered,
/// ±1 = adjacent page) along the scroll [axis].
///
/// Pure function — usable from any PageView-driven widget that
/// tracks per-item fraction. Idempotent for `slide` (returns child
/// unchanged) — caller can apply unconditionally.
Widget applyPageTransition({
  required Widget child,
  required double pageFraction,
  required PageTransition transition,
  required Axis axis,
}) {
  if (transition == PageTransition.slide) return child;
  final isVertical = axis == Axis.vertical;
  switch (transition) {
    case PageTransition.slide:
      return child;
    case PageTransition.fade:
      final opacity = (1 - pageFraction.abs()).clamp(0.0, 1.0);
      return Opacity(opacity: opacity, child: child);
    case PageTransition.scale:
      final scale = (1 - pageFraction.abs() * 0.25).clamp(0.6, 1.0);
      return Transform.scale(scale: scale, child: child);
    case PageTransition.depth:
      final dist = pageFraction.abs();
      return Opacity(
        opacity: (1 - dist * 0.7).clamp(0.0, 1.0),
        child: Transform.scale(
          scale: (1 - dist * 0.18).clamp(0.5, 1.0),
          child: child,
        ),
      );
    case PageTransition.parallax:
      // Caller-page already translates with PageView; add half-speed
      // counter-translate to simulate background parallax.
      final shift = pageFraction * 0.5;
      return Transform.translate(
        offset: isVertical
            ? Offset(0, _viewportMain(child) * shift)
            : Offset(_viewportMain(child) * shift, 0),
        child: child,
      );
    case PageTransition.cube:
      // 3D cube — pages rotate around the cross axis as they pass.
      final angle = pageFraction * 0.5 * 3.14159; // 90° at ±1
      final matrix = Matrix4.identity()
        ..setEntry(3, 2, 0.0015) // perspective
        ..rotateY(isVertical ? 0 : angle)
        ..rotateX(isVertical ? angle : 0);
      // Anchor rotation at the hinge edge so adjacent faces meet.
      final alignment = pageFraction < 0
          ? (isVertical ? Alignment.bottomCenter : Alignment.centerRight)
          : (isVertical ? Alignment.topCenter : Alignment.centerLeft);
      return Transform(
        transform: matrix,
        alignment: alignment,
        child: child,
      );
    case PageTransition.flip:
      final angle = pageFraction.clamp(-1.0, 1.0) * 3.14159 / 2; // 90° at ±1
      final matrix = Matrix4.identity()
        ..setEntry(3, 2, 0.0015)
        ..rotateY(isVertical ? 0 : -angle)
        ..rotateX(isVertical ? -angle : 0);
      return Opacity(
        opacity: (1 - pageFraction.abs()).clamp(0.0, 1.0),
        child: Transform(
          transform: matrix,
          alignment: Alignment.center,
          child: child,
        ),
      );
    case PageTransition.coverflow:
      final dist = pageFraction.clamp(-1.5, 1.5);
      final angle = dist * 0.7; // tilt in radians
      final scale = (1 - dist.abs() * 0.15).clamp(0.7, 1.0);
      final matrix = Matrix4.identity()
        ..setEntry(3, 2, 0.001)
        ..rotateY(isVertical ? 0 : -angle)
        ..rotateX(isVertical ? -angle : 0)
        ..scaleByDouble(scale, scale, 1, 1);
      return Transform(
        transform: matrix,
        alignment: Alignment.center,
        child: child,
      );
    case PageTransition.accordion:
      // Collapse along main axis as the page leaves — visually a
      // folding panel. Anchor on the leading edge so neighbour
      // shrinks "inward" toward the edge it's sliding from.
      //
      // Tradeoff: PageView's native page translate is intrinsic to
      // the widget — fully cancelling it (via FractionalTranslation)
      // makes the drag feel reversed because the page no longer
      // follows the finger. Accept that the page slides off at the
      // far end of the fold; ClipRect keeps the compressed visual
      // tidy at least.
      final dist = pageFraction.abs().clamp(0.0, 1.0);
      final scaleMain = 1 - dist;
      return Transform(
        transform: Matrix4.identity()
          ..scaleByDouble(
            isVertical ? 1.0 : scaleMain,
            isVertical ? scaleMain : 1.0,
            1,
            1,
          ),
        alignment: pageFraction < 0
            ? (isVertical ? Alignment.bottomCenter : Alignment.centerRight)
            : (isVertical ? Alignment.topCenter : Alignment.centerLeft),
        child: ClipRect(clipBehavior: Clip.none, child: child),
      );
    case PageTransition.tunnel:
      // Pages zoom away from camera + fade as they leave.
      final dist = pageFraction.abs().clamp(0.0, 1.5);
      final scale = (1 - dist * 0.85).clamp(0.0, 1.0);
      return Opacity(
        opacity: (1 - dist * 0.7).clamp(0.0, 1.0),
        child: Transform.scale(scale: scale, child: child),
      );
    case PageTransition.vortex:
      // Pages spin around Z + shrink as they leave. Spin direction
      // tracks sign of pageFraction so leaving / entering pages
      // rotate opposite ways for a swirl effect.
      final dist = pageFraction.clamp(-1.5, 1.5);
      final absDist = dist.abs();
      final scale = (1 - absDist * 0.5).clamp(0.0, 1.0);
      final angle = dist * 1.2; // ~70° at ±1
      return Opacity(
        opacity: (1 - absDist * 0.5).clamp(0.0, 1.0),
        child: Transform.rotate(
          angle: angle,
          child: Transform.scale(scale: scale, child: child),
        ),
      );
    case PageTransition.swing:
      // 3D rotation around the leading edge — like a door swinging
      // away from camera as the page exits.
      final angle = pageFraction.clamp(-1.0, 1.0) * 1.2; // ~70°
      final matrix = Matrix4.identity()
        ..setEntry(3, 2, 0.0015)
        ..rotateY(isVertical ? 0 : -angle)
        ..rotateX(isVertical ? -angle : 0);
      final alignment = pageFraction < 0
          ? (isVertical ? Alignment.bottomCenter : Alignment.centerRight)
          : (isVertical ? Alignment.topCenter : Alignment.centerLeft);
      return Transform(
        transform: matrix,
        alignment: alignment,
        child: Opacity(
          opacity: (1 - pageFraction.abs() * 0.4).clamp(0.0, 1.0),
          child: child,
        ),
      );
  }
}

/// Heuristic viewport-main extent for parallax translate. Real value
/// comes from `LayoutBuilder` in caller; we use a sensible fallback
/// for the inline use case.
double _viewportMain(Widget _) => 360.0;
