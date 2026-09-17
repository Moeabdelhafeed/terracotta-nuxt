import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import '../../../../core/painters/gradient_border_painter.dart';
import '../models/popup_models.dart';
import '../theme/popup_theme.dart';

/// Pre-styled surface used by every built-in factory. Wraps child in
/// Material + ClipRRect + optional border + RepaintBoundary. Renders an
/// optional [GlobalPopupArrow] tail pointing at the anchor.
///
/// Custom surfaces should compose with this rather than reimplement the
/// styling resolution + arrow rendering.
class GlobalPopupSurface extends StatelessWidget {
  const GlobalPopupSurface({
    super.key,
    required this.layout,
    required this.child,
    this.style,
    this.maxWidth,
    this.arrow,
  });

  final GlobalPopupLayout layout;
  final Widget child;
  final GlobalPopupSurfaceStyle? style;
  final double? maxWidth;
  final GlobalPopupArrow? arrow;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ext = GlobalPopupTheme.maybeOf(context);
    // Per-field merge: caller's style overlays theme.surface, then
    // materialize against `defaults` so non-null-themed fields
    // (elevation, borderWidth, clipBehavior, intrinsicWidth) are
    // guaranteed populated.
    final merged = (ext?.surface ?? const GlobalPopupSurfaceStyle()).mergedWith(
      style,
    );
    final resolved = merged.resolved();
    // Same merge for arrow.
    final resolvedArrow = (ext?.arrow ?? const GlobalPopupArrow()).mergedWith(
      arrow,
    );
    final hasAnyArrow =
        resolvedArrow.size != null ||
        // If anything got into the arrow merge, render it. Bare
        // `GlobalPopupArrow()` with nothing set still yields all-null
        // fields → no arrow.
        arrow != null ||
        ext?.arrow != null;
    final isDark = theme.brightness == Brightness.dark;

    final surfaceColor = isDark && resolved.darkColor != null
        ? resolved.darkColor!
        : resolved.color ?? theme.colorScheme.surface;
    final hasGradientBg = resolved.gradient != null;
    final hasCustomShadow = resolved.shadow != null;
    final radius = resolved.borderRadius ?? BorderRadius.circular(12);

    // Resolve final width constraints from the layout (controller-derived
    // from `GlobalPopupOptions.width` strategy) + per-surface overrides.
    //
    // `layout.width` is the controller's screen-budget-clamped maximum.
    // Surface-supplied `maxWidth` is treated as a soft cap — we always
    // take the SMALLER of the two so a caller's `maxWidth: 400` cannot
    // bleed past the screen when the budget is e.g. 240.
    final layoutMinW = layout.minWidth ?? resolved.minWidth ?? 0.0;
    final layoutMaxW = maxWidth == null
        ? layout.width
        : (maxWidth! < layout.width ? maxWidth! : layout.width);
    final useIntrinsic = resolved.intrinsicWidth! || layout.useIntrinsicWidth;

    Widget content = Container(
      constraints: BoxConstraints(
        minHeight: layout.fixedHeight ?? 0,
        maxHeight: layout.maxHeight,
        minWidth: useIntrinsic ? 0 : layoutMinW,
        maxWidth: layoutMaxW,
      ),
      decoration: resolved.border != null
          ? BoxDecoration(border: resolved.border, borderRadius: radius)
          : null,
      padding: resolved.padding,
      child: child,
    );

    if (useIntrinsic) {
      content = ConstrainedBox(
        constraints: BoxConstraints(minWidth: layoutMinW, maxWidth: layoutMaxW),
        child: IntrinsicWidth(child: content),
      );
    }

    Widget body = Material(
      color: hasGradientBg ? Colors.transparent : surfaceColor,
      elevation: hasCustomShadow ? 0 : resolved.elevation!,
      shadowColor: resolved.shadowColor,
      borderRadius: radius,
      clipBehavior: resolved.clipBehavior!,
      child: hasGradientBg
          ? DecoratedBox(
              decoration: BoxDecoration(gradient: resolved.gradient),
              child: content,
            )
          : content,
    );

    if (hasCustomShadow) {
      body = DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: radius,
          boxShadow: resolved.shadow,
        ),
        child: body,
      );
    }

    if (resolved.borderColor != null &&
        resolved.border == null &&
        resolved.borderGradient == null) {
      body = DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: radius,
          border: Border.all(
            color: resolved.borderColor!,
            width: resolved.borderWidth!,
          ),
        ),
        child: body,
      );
    }

    if (resolved.borderGradient != null) {
      body = CustomPaint(
        foregroundPainter: GradientBorderPainter(
          gradient: resolved.borderGradient!,
          borderRadius: radius,
          borderWidth: resolved.borderWidth!,
        ),
        child: body,
      );
    }

    if (hasAnyArrow) {
      body = _ArrowedSurface(
        placement: layout.effectivePlacement,
        arrow: resolvedArrow,
        color: resolvedArrow.color ?? surfaceColor,
        surfaceElevation: resolved.elevation!,
        // How far the engine slid the surface off the anchor to keep it
        // inside the screen padding. The arrow walks back by the same
        // amount so it stays over what it points at.
        drift: layout.followerOffset,
        // The correction THIS pass is applying, which has not reached
        // `followerOffset` yet — without it the tail slides across the
        // bubble one frame after the popup appears.
        liveShift: layout.liveClampShift,
        cornerRadius: radius.topLeft.x,
        child: body,
      );
    }

    return RepaintBoundary(child: body);
  }
}

// ─────────────────────────────────────────────────────────────────────
// Arrow tail
// ─────────────────────────────────────────────────────────────────────

class _ArrowedSurface extends StatelessWidget {
  const _ArrowedSurface({
    required this.placement,
    required this.arrow,
    required this.color,
    required this.surfaceElevation,
    required this.drift,
    required this.liveShift,
    required this.cornerRadius,
    required this.child,
  });

  final GlobalPopupPlacement placement;
  final GlobalPopupArrow arrow;
  final Color color;
  final double surfaceElevation;

  /// The engine's own correction: how far the surface was slid to stay
  /// inside the screen padding, in logical pixels.
  final Offset drift;

  /// Correction being applied by the layout pass currently running,
  /// not yet folded into [drift]. Read during layout, never listened
  /// to — see `GlobalPopupLayout.liveClampShift`.
  final ValueListenable<double>? liveShift;

  /// The surface's corner radius, which bounds the tail's travel: a
  /// tail on the rounded corner has nothing straight to merge into.
  final double cornerRadius;

  final Widget child;

  @override
  Widget build(BuildContext context) {
    // Resolve every nullable field against `GlobalPopupArrow.defaults`
    // once at the top so downstream reads are non-null. `arrow` itself
    // may already be a theme + caller merge — `resolved()` only fills
    // in remaining gaps from the hardcoded defaults.
    final r = arrow.resolved();
    final geom = resolvePlacement(placement);
    final size = r.size!;
    final onTop = geom.isVertical && !geom.isAbove;
    final onBottom = geom.isVertical && geom.isAbove;
    final onLeft = !geom.isVertical && !geom.isLeading;
    final onRight = !geom.isVertical && geom.isLeading;

    final reserved = size;
    final elevation = r.elevation ?? surfaceElevation;
    final castShadow = r.castShadow! && elevation > 0;

    final dir = onTop
        ? _ArrowDir.up
        : (onBottom
              ? _ArrowDir.down
              : (onLeft ? _ArrowDir.left : _ArrowDir.right));

    final arrowWidget = _ArrowGlyph(
      arrow: r,
      fillColor: color,
      dir: dir,
      castShadow: castShadow,
      elevation: elevation,
    );

    // Positioning along the edge: start / center / end alignment. For
    // start/end the user-supplied `offset` controls the distance from
    // the corner. For center it is ignored (arrow sits dead-centered).
    final align = r.alignment!;
    final offset = r.offset!;

    Widget edgeChild;
    if (onTop || onBottom) {
      // Horizontal alignment along the top/bottom edge.
      // `PositionedDirectional` resolves `start`/`end` against ambient
      // Directionality so RTL apps mirror the arrow's offset correctly.
      switch (align) {
        case GlobalPopupArrowAlignment.start:
          edgeChild = PositionedDirectional(
            top: onTop ? -size : null,
            bottom: onBottom ? -size : null,
            start: offset,
            child: arrowWidget,
          );
        case GlobalPopupArrowAlignment.end:
          edgeChild = PositionedDirectional(
            top: onTop ? -size : null,
            bottom: onBottom ? -size : null,
            end: offset,
            child: arrowWidget,
          );
        case GlobalPopupArrowAlignment.center:
          // A CENTERED arrow is centered on the ANCHOR, not on the
          // surface. When the engine slides the surface to keep it
          // inside the screen padding, a surface-centered arrow stops
          // pointing at anything — the bug you see as a tooltip near a
          // screen edge with its tail out in the margin.
          edgeChild = Positioned(
            top: onTop ? -size : null,
            bottom: onBottom ? -size : null,
            left: 0,
            right: 0,
            child: _ArrowRail(
              drift: drift,
              liveShift: liveShift,
              cornerRadius: cornerRadius,
              child: arrowWidget,
            ),
          );
      }
    } else {
      // Vertical alignment along the left/right edge.
      switch (align) {
        case GlobalPopupArrowAlignment.start:
          edgeChild = Positioned(
            left: onLeft ? -size : null,
            right: onRight ? -size : null,
            top: offset,
            child: arrowWidget,
          );
        case GlobalPopupArrowAlignment.end:
          edgeChild = Positioned(
            left: onLeft ? -size : null,
            right: onRight ? -size : null,
            bottom: offset,
            child: arrowWidget,
          );
        case GlobalPopupArrowAlignment.center:
          edgeChild = Positioned(
            left: onLeft ? -size : null,
            right: onRight ? -size : null,
            top: 0,
            bottom: 0,
            child: Center(child: arrowWidget),
          );
      }
    }

    // Arrow always paints on TOP of the surface body so its tail can't
    // be hidden behind the surface's elevation shadow (which extends
    // outward in every direction past the body's edges).
    //
    // The arrow's own shadow (when `castShadow` is true) is clipped in
    // [_ArrowPainter] to the half-plane facing AWAY from the surface,
    // so painting on top never bleeds shadow into the popup interior.
    return Padding(
      padding: EdgeInsets.only(
        top: onTop ? reserved : 0,
        bottom: onBottom ? reserved : 0,
        left: onLeft ? reserved : 0,
        right: onRight ? reserved : 0,
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [child, edgeChild],
      ),
    );
  }
}

enum _ArrowDir { up, down, left, right }

class _ArrowGlyph extends StatelessWidget {
  const _ArrowGlyph({
    required this.arrow,
    required this.fillColor,
    required this.dir,
    required this.castShadow,
    required this.elevation,
  });

  final GlobalPopupArrow arrow;
  final Color fillColor;
  final _ArrowDir dir;
  final bool castShadow;
  final double elevation;

  @override
  Widget build(BuildContext context) {
    // `arrow` arrives pre-resolved from `_ArrowedSurface.build` so
    // every themed field is non-null. We bang here rather than
    // re-resolving so an upstream change that forgets to resolve
    // surfaces as a clear NPE instead of silently doubling defaults.
    final size = arrow.size!;
    // Base = arrow.size * 1.6 along the base axis; apex = arrow.size
    // along the tip axis. `baseFillet` extends the canvas outward
    // along the base axis on each side by the fillet's inset distance
    // so the smoothing arcs can render past the original triangle
    // bounds (where they tangent into the popup edge).
    final baseAxis = size * 1.6;
    final apex = size;
    final filletInset = _filletInsetForArrow(
      baseAxis: baseAxis,
      apex: apex,
      filletRadius: arrow.baseFillet!,
    );
    final widenedBase = baseAxis + 2 * filletInset;
    final canvasSize = (dir == _ArrowDir.up || dir == _ArrowDir.down)
        ? Size(widenedBase, apex)
        : Size(apex, widenedBase);
    return CustomPaint(
      size: canvasSize,
      painter: _ArrowPainter(
        fillColor: fillColor,
        borderColor: arrow.borderColor,
        borderWidth: arrow.borderWidth!,
        borderRadius: arrow.borderRadius!,
        dir: dir,
        castShadow: castShadow,
        elevation: elevation,
        shadowSpread: arrow.shadowSpread!,
        shadowColor: arrow.shadowColor ?? Colors.black,
        bow: arrow.bow!,
        baseFillet: arrow.baseFillet!,
        filletInset: filletInset,
      ),
    );
  }
}

/// Distance the fillet inset extends along the base axis past the
/// original triangle's base corner. Derived from the half-angle
/// identity so the circular arc of radius `filletRadius` is tangent to
/// BOTH the slanted edge and the base edge.
double _filletInsetForArrow({
  required double baseAxis,
  required double apex,
  required double filletRadius,
}) {
  if (filletRadius <= 0) return 0;
  // Angle at the base corner of the original triangle, between the
  // slanted edge (toward tip) and the base edge (along the body).
  final theta = math.atan2(apex, baseAxis / 2);
  return filletRadius / math.tan(theta / 2);
}

class _ArrowPainter extends CustomPainter {
  _ArrowPainter({
    required this.fillColor,
    required this.dir,
    required this.borderRadius,
    required this.borderColor,
    required this.borderWidth,
    required this.castShadow,
    required this.elevation,
    required this.shadowSpread,
    required this.shadowColor,
    required this.bow,
    required this.baseFillet,
    required this.filletInset,
  });
  final Color fillColor;
  final _ArrowDir dir;
  final double borderRadius;
  final Color? borderColor;
  final double borderWidth;
  final bool castShadow;
  final double elevation;
  final double shadowSpread;
  final Color shadowColor;
  final double bow;
  final double baseFillet;
  final double filletInset;

  Path _buildPath(Size size) {
    if (baseFillet > 0 && filletInset > 0) {
      return _buildPathWithBaseFillet(size);
    }
    return _buildPathLegacy(size);
  }

  /// Triangle with a concave-from-outside fillet at each base corner,
  /// tangent to both the slanted edge and the popup's surface edge.
  /// The arrow's base extends past its original triangle bounds by
  /// `filletInset` on each side along the base axis so the fillet's
  /// outer endpoint lands at the canvas edge — there the surface body
  /// is right next to the arrow and the two paths blend seamlessly.
  Path _buildPathWithBaseFillet(Size size) {
    final p = Path();
    final tipR = borderRadius.clamp(0, size.shortestSide / 2).toDouble();

    // Tip + the two original triangle base corners (shifted inward by
    // `filletInset` so the fillets land flush at canvas edges). Plus
    // unit vectors pointing OUTWARD past each base corner along the
    // base edge (i.e. away from the OTHER base corner).
    final Offset tip;
    final Offset corner1;
    final Offset corner2;
    final Offset outward1;
    final Offset outward2;
    switch (dir) {
      case _ArrowDir.up:
        tip = Offset(size.width / 2, 0);
        corner1 = Offset(size.width - filletInset, size.height);
        corner2 = Offset(filletInset, size.height);
        outward1 = const Offset(1, 0);
        outward2 = const Offset(-1, 0);
      case _ArrowDir.down:
        tip = Offset(size.width / 2, size.height);
        corner1 = Offset(filletInset, 0);
        corner2 = Offset(size.width - filletInset, 0);
        outward1 = const Offset(-1, 0);
        outward2 = const Offset(1, 0);
      case _ArrowDir.left:
        tip = Offset(0, size.height / 2);
        corner1 = Offset(size.width, filletInset);
        corner2 = Offset(size.width, size.height - filletInset);
        outward1 = const Offset(0, -1);
        outward2 = const Offset(0, 1);
      case _ArrowDir.right:
        tip = Offset(size.width, size.height / 2);
        corner1 = Offset(0, size.height - filletInset);
        corner2 = Offset(0, filletInset);
        outward1 = const Offset(0, 1);
        outward2 = const Offset(0, -1);
    }

    Offset insetToward(Offset from, Offset toward, double dist) {
      final v = toward - from;
      final len = v.distance;
      if (len == 0) return from;
      return from + v * (dist / len);
    }

    final slantedR = insetToward(corner1, tip, filletInset);
    final slantedL = insetToward(corner2, tip, filletInset);
    final filletEndR = corner1 + outward1 * filletInset;
    final filletEndL = corner2 + outward2 * filletInset;
    final tipInsetR = tipR > 0 ? insetToward(tip, corner1, tipR) : tip;
    final tipInsetL = tipR > 0 ? insetToward(tip, corner2, tipR) : tip;

    final centroid = Offset(
      (tip.dx + corner1.dx + corner2.dx) / 3,
      (tip.dy + corner1.dy + corner2.dy) / 3,
    );

    Offset? bowCtrl(Offset start, Offset end) {
      if (bow <= 0) return null;
      final edge = end - start;
      final len = edge.distance;
      if (len == 0) return null;
      final perp1 = Offset(-edge.dy, edge.dx) / len;
      final perp2 = Offset(edge.dy, -edge.dx) / len;
      final mid = Offset((start.dx + end.dx) / 2, (start.dy + end.dy) / 2);
      final outward =
          (mid + perp1 - centroid).distance > (mid + perp2 - centroid).distance
          ? perp1
          : perp2;
      return mid + outward * bow;
    }

    p.moveTo(tipInsetR.dx, tipInsetR.dy);

    // Right slanted edge: tipInsetR → slantedR (close to corner1).
    final cR = bowCtrl(tipInsetR, slantedR);
    if (cR != null) {
      p.quadraticBezierTo(cR.dx, cR.dy, slantedR.dx, slantedR.dy);
    } else {
      p.lineTo(slantedR.dx, slantedR.dy);
    }

    // Fillet at corner1 — concave from outside, tangent to slanted +
    // base lines. `clockwise: false` makes the arc bulge AWAY from
    // the triangle (into the exterior wedge), so the join with the
    // popup edge reads as a soft outward curve rather than a notch.
    p.arcToPoint(
      filletEndR,
      radius: Radius.circular(baseFillet),
      clockwise: false,
    );

    // Base edge — from canvas-edge endpoint on the right to the one
    // on the left. This line sits exactly along the popup's surface
    // edge so the arrow blends into the body without a visible seam.
    p.lineTo(filletEndL.dx, filletEndL.dy);

    p.arcToPoint(
      slantedL,
      radius: Radius.circular(baseFillet),
      clockwise: false,
    );

    final cL = bowCtrl(slantedL, tipInsetL);
    if (cL != null) {
      p.quadraticBezierTo(cL.dx, cL.dy, tipInsetL.dx, tipInsetL.dy);
    } else {
      p.lineTo(tipInsetL.dx, tipInsetL.dy);
    }

    if (tipR > 0) {
      p.arcToPoint(tipInsetR, radius: Radius.circular(tipR));
    }
    p.close();
    return p;
  }

  Path _buildPathLegacy(Size size) {
    // Build a triangle pointing in `dir`. When `borderRadius` is > 0,
    // round the three corners. Otherwise emit a sharp triangle.
    final p = Path();
    final r = borderRadius.clamp(0, size.shortestSide / 2).toDouble();

    // Corners in the order tip → right-base → left-base for each dir.
    final List<Offset> corners;
    switch (dir) {
      case _ArrowDir.up:
        corners = [
          Offset(size.width / 2, 0),
          Offset(size.width, size.height),
          Offset(0, size.height),
        ];
      case _ArrowDir.down:
        corners = [
          Offset(size.width / 2, size.height),
          const Offset(0, 0),
          Offset(size.width, 0),
        ];
      case _ArrowDir.left:
        corners = [
          Offset(0, size.height / 2),
          Offset(size.width, 0),
          Offset(size.width, size.height),
        ];
      case _ArrowDir.right:
        corners = [
          Offset(size.width, size.height / 2),
          Offset(0, size.height),
          const Offset(0, 0),
        ];
    }

    Offset inset(Offset corner, Offset other, double dist) {
      final v = other - corner;
      final len = v.distance;
      if (len == 0) return corner;
      return corner + v * (dist / len);
    }

    // Centroid → used to pick the outward-pointing perpendicular when
    // bowing edges.
    final centroid = Offset(
      (corners[0].dx + corners[1].dx + corners[2].dx) / 3,
      (corners[0].dy + corners[1].dy + corners[2].dy) / 3,
    );

    // For each edge i (from corners[i] to corners[(i+1)%3]) compute the
    // edge's start + end (already inset by the corner radius) and the
    // outward-pointing unit perpendicular so positive `bow` pushes the
    // quadratic control point AWAY from the centroid.
    final starts = <Offset>[];
    final ends = <Offset>[];
    final outward = <Offset>[];
    for (var i = 0; i < 3; i++) {
      final a = corners[i];
      final b = corners[(i + 1) % 3];
      starts.add(inset(a, b, r));
      ends.add(inset(b, a, r));
      final edge = b - a;
      final len = edge.distance;
      final perp1 = len == 0 ? Offset.zero : Offset(-edge.dy, edge.dx) / len;
      final perp2 = len == 0 ? Offset.zero : Offset(edge.dy, -edge.dx) / len;
      final mid = Offset((a.dx + b.dx) / 2, (a.dy + b.dy) / 2);
      outward.add(
        (mid + perp1 - centroid).distance > (mid + perp2 - centroid).distance
            ? perp1
            : perp2,
      );
    }

    // Skip the slanted edges' bow — only the two "leg" edges of the
    // triangle (the ones connected to the tip) bulge outward; the base
    // (the edge flush against the surface) stays straight so it
    // continues to stitch into the popup body.
    bool isBaseEdge(int i) {
      // The base edge is the one OPPOSITE the tip corner. The tip is
      // always `corners[0]` in our setup, so the base is the edge
      // between corners[1] and corners[2] — that's edge index 1.
      return i == 1;
    }

    p.moveTo(starts[0].dx, starts[0].dy);
    for (var i = 0; i < 3; i++) {
      if (bow > 0 && !isBaseEdge(i)) {
        final mid = Offset(
          (starts[i].dx + ends[i].dx) / 2,
          (starts[i].dy + ends[i].dy) / 2,
        );
        final ctrl = mid + outward[i] * bow;
        p.quadraticBezierTo(ctrl.dx, ctrl.dy, ends[i].dx, ends[i].dy);
      } else {
        p.lineTo(ends[i].dx, ends[i].dy);
      }
      if (r > 0) {
        final nextStart = starts[(i + 1) % 3];
        p.arcToPoint(nextStart, radius: Radius.circular(r));
      }
    }
    p.close();
    return p;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final path = _buildPath(size);

    if (castShadow) {
      // Effective elevation = base * spread. `Canvas.drawShadow` makes
      // small paths render a fairly subtle halo at the same elevation
      // the surface uses, so we boost the value before rasterizing.
      final fxElevation = elevation * shadowSpread;
      // `drawShadow` paints OUTSIDE the path in every direction. The
      // direction facing the surface body is "into" the popup — we don't
      // want shadow bleeding there. Clip the canvas to the outward
      // half-plane (plus generous side overflow for the soft falloff)
      // so the shadow only renders on the anchor-facing side.
      //
      // `pad` is sized off the boosted elevation so larger spread
      // values keep their full halo without being clipped at the tip
      // or sides.
      final pad = fxElevation * 4 + 8;
      final Rect shadowClip;
      switch (dir) {
        case _ArrowDir.up:
          // Arrow base at y = size.height (touches surface). Allow
          // shadow above + sides, cut everything below the base.
          shadowClip = Rect.fromLTRB(
            -pad,
            -pad,
            size.width + pad,
            size.height,
          );
        case _ArrowDir.down:
          // Arrow base at y = 0. Allow shadow below + sides, cut above.
          shadowClip = Rect.fromLTRB(
            -pad,
            0,
            size.width + pad,
            size.height + pad,
          );
        case _ArrowDir.left:
          // Arrow base at x = size.width. Allow shadow left + above/below,
          // cut everything right of the base.
          shadowClip = Rect.fromLTRB(
            -pad,
            -pad,
            size.width,
            size.height + pad,
          );
        case _ArrowDir.right:
          // Arrow base at x = 0. Allow shadow right + above/below, cut left.
          shadowClip = Rect.fromLTRB(
            0,
            -pad,
            size.width + pad,
            size.height + pad,
          );
      }
      canvas
        ..save()
        ..clipRect(shadowClip)
        ..drawShadow(path, shadowColor, fxElevation, false)
        ..restore();
    }

    canvas.drawPath(path, Paint()..color = fillColor);

    if (borderColor != null && borderWidth > 0) {
      // Stroke only the two slanted edges, NOT the base — base sits
      // flush against the surface so a stroke there would draw a seam.
      // When `baseFillet > 0`, the actual triangle's base corners are
      // shifted inward by `filletInset` (the canvas is expanded outward
      // by the same amount). Shift the stroke corners to match so the
      // stroke ends where the slanted edges actually do.
      final d = filletInset;
      final List<Offset> corners;
      switch (dir) {
        case _ArrowDir.up:
          corners = [
            Offset(d, size.height),
            Offset(size.width / 2, 0),
            Offset(size.width - d, size.height),
          ];
        case _ArrowDir.down:
          corners = [
            Offset(d, 0),
            Offset(size.width / 2, size.height),
            Offset(size.width - d, 0),
          ];
        case _ArrowDir.left:
          corners = [
            Offset(size.width, d),
            Offset(0, size.height / 2),
            Offset(size.width, size.height - d),
          ];
        case _ArrowDir.right:
          corners = [
            Offset(0, d),
            Offset(size.width, size.height / 2),
            Offset(0, size.height - d),
          ];
      }
      final stroke = Paint()
        ..color = borderColor!
        ..style = PaintingStyle.stroke
        ..strokeWidth = borderWidth
        ..strokeJoin = StrokeJoin.round
        ..strokeCap = StrokeCap.round;
      final strokePath = Path()
        ..moveTo(corners[0].dx, corners[0].dy)
        ..lineTo(corners[1].dx, corners[1].dy)
        ..lineTo(corners[2].dx, corners[2].dy);
      canvas.drawPath(strokePath, stroke);
    }
  }

  @override
  bool shouldRepaint(covariant _ArrowPainter old) =>
      old.fillColor != fillColor ||
      old.dir != dir ||
      old.borderRadius != borderRadius ||
      old.borderColor != borderColor ||
      old.borderWidth != borderWidth ||
      old.castShadow != castShadow ||
      old.elevation != elevation ||
      old.shadowSpread != shadowSpread ||
      old.shadowColor != shadowColor ||
      old.bow != bow;
}

// ─────────────────────────────────────────────────────────────────────
// _ArrowRail
// ─────────────────────────────────────────────────────────────────────

/// Positions a CENTERED arrow along the surface's edge.
///
/// The arrow is centered on the ANCHOR, not on the surface: the engine
/// slides a popup sideways to keep it inside the screen padding, and a
/// tail left in the middle of a surface that moved points at the margin
/// beside the thing it describes.
///
/// It walks back by the whole correction — the part already folded into
/// `followerOffset` plus the part this layout pass is applying — and
/// stops only where the tail would leave the surface's straight edge.
/// The bound used to be half the ANCHOR's width, which is not a bound
/// on the arrow at all: an icon 40dp wide capped the tail at 20dp of
/// travel while the surface had slid 80, so it stopped a long way short
/// of the icon it was supposed to point at.
class _ArrowRail extends SingleChildRenderObjectWidget {
  const _ArrowRail({
    required this.drift,
    required this.liveShift,
    required this.cornerRadius,
    required Widget super.child,
  });

  final Offset drift;
  final ValueListenable<double>? liveShift;
  final double cornerRadius;

  @override
  _RenderArrowRail createRenderObject(BuildContext context) => _RenderArrowRail(
    drift: drift,
    liveShift: liveShift,
    cornerRadius: cornerRadius,
  );

  @override
  void updateRenderObject(
    BuildContext context,
    _RenderArrowRail renderObject,
  ) {
    renderObject
      ..drift = drift
      ..liveShift = liveShift
      ..cornerRadius = cornerRadius;
  }
}

class _RenderArrowRail extends RenderShiftedBox {
  _RenderArrowRail({
    required Offset drift,
    required ValueListenable<double>? liveShift,
    required double cornerRadius,
  }) : _drift = drift,
       _liveShift = liveShift,
       _cornerRadius = cornerRadius,
       super(null);

  Offset _drift;
  Offset get drift => _drift;
  set drift(Offset v) {
    if (v == _drift) return;
    _drift = v;
    markNeedsLayout();
  }

  ValueListenable<double>? _liveShift;
  ValueListenable<double>? get liveShift => _liveShift;
  set liveShift(ValueListenable<double>? v) {
    if (v == _liveShift) return;
    _liveShift = v;
    markNeedsLayout();
  }

  double _cornerRadius;
  double get cornerRadius => _cornerRadius;
  set cornerRadius(double v) {
    if (v == _cornerRadius) return;
    _cornerRadius = v;
    markNeedsLayout();
  }

  @override
  void performLayout() {
    final child = this.child;
    if (child == null) {
      size = constraints.smallest;
      return;
    }
    child.layout(const BoxConstraints(), parentUsesSize: true);
    // Tight width from the `Positioned(left: 0, right: 0)` above, which
    // is the surface's own width.
    size = Size(constraints.maxWidth, child.size.height);

    // Read, don't listen: the only writer publishes immediately before
    // laying out this subtree, so the value is always this pass's.
    final total = _drift.dx + (_liveShift?.value ?? 0);
    // Far enough that the tail still has straight edge to merge into on
    // both sides of its own base.
    final reach = (size.width - child.size.width) / 2 - _cornerRadius;
    final travel = reach <= 0 ? 0.0 : (-total).clamp(-reach, reach);

    (child.parentData! as BoxParentData).offset = Offset(
      (size.width - child.size.width) / 2 + travel,
      0,
    );
  }
}
