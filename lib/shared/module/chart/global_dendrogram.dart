import 'package:flutter/material.dart';

import '../../../core/extensions/theme_colors_extension.dart';
import 'chart_data.dart';
import 'chart_internals.dart';
import 'chart_models.dart';
import 'chart_tooltip_overlay.dart';
import 'custom_paint_tooltip.dart';

export 'chart_data.dart' show TreemapNode;
export 'chart_models.dart' show ChartStyle, DendrogramAnimation;

/// Orientation for [GlobalDendrogram].
enum DendrogramOrientation {
  /// Root at top, leaves at bottom.
  topDown,

  /// Root at left, leaves at right.
  leftRight,
}

/// Connector style between a parent and its children.
enum DendrogramConnector {
  /// Orthogonal L-shape sharing a horizontal/vertical bar with
  /// siblings. Default — clearest for taxonomies.
  bracket,

  /// Smooth cubic bezier directly from parent node to child node.
  curved,

  /// Stepped L-shape — bend halfway along the perpendicular axis
  /// (looks like circuit-board traces).
  step,

  /// Straight line directly from parent to child — abandons the
  /// shared-bar look in favor of radial-style branches.
  straight,

  /// Diagonal — same as straight but draws as a smooth elbow
  /// (quadratic curve through midpoint).
  elbow,
}

/// Dendrogram — hierarchical tree visualization. Reuses
/// [TreemapNode] for input. Inner nodes split into orthogonal
/// branches (bracket-style) toward their children; leaves carry
/// labels at the periphery.
///
/// Best for showing taxonomies, file trees, cluster hierarchies.
///
/// ```dart
/// GlobalDendrogram(
///   root: TreemapNode(label: 'animals', children: [
///     TreemapNode(label: 'mammals', children: [
///       TreemapNode(label: 'cat'),
///       TreemapNode(label: 'dog'),
///     ]),
///     TreemapNode(label: 'birds', value: 1),
///   ]),
/// )
/// ```
class GlobalDendrogram extends StatelessWidget {
  const GlobalDendrogram({
    required this.root,
    this.style = ChartStyle.standard,
    this.animation = DendrogramAnimation.grow,
    this.orientation = DendrogramOrientation.topDown,
    this.connector = DendrogramConnector.bracket,
    this.strokeWidth = 1.4,
    this.leafRadius = 4.0,
    this.innerNodeRadius = 3.0,
    this.colorByDepth = false,
    this.showLeafLabels = true,
    this.showInnerLabels = true,
    super.key,
  });

  final TreemapNode root;
  final ChartStyle style;
  final DendrogramAnimation animation;
  final DendrogramOrientation orientation;
  final DendrogramConnector connector;
  final double strokeWidth;
  final double leafRadius;

  /// Inner-node dot radius. Set to 0 to hide inner-node markers.
  final double innerNodeRadius;

  /// Tint each branch by its depth from the root.
  final bool colorByDepth;

  final bool showLeafLabels;

  /// Render inner (non-leaf) node labels near each branching point.
  final bool showInnerLabels;

  @override
  Widget build(BuildContext context) {
    if (root.children.isEmpty) return const SizedBox.shrink();
    final palette = resolveSeriesColors(context, style, 6);
    final axisStyle = resolveAxisLabelStyle(context, style);
    final fg = context.textColors.primary;

    // Tree reveals read better with a longer default — branches
    // need time to register depth-by-depth. Bump base duration
    // unless the caller has overridden it.
    final baseDuration = style.effectiveAnimationDuration;
    final duration = animation == DendrogramAnimation.grow
        ? baseDuration * 1.6
        : (animation == DendrogramAnimation.cascade
              ? baseDuration * 1.4
              : baseDuration);

    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          minHeight: style.minHeight,
          maxWidth: resolveChartMaxWidth(context, style),
        ),
        child: AspectRatio(
          aspectRatio: style.aspectRatio,
          child: Padding(
            padding: style.padding,
            child: CustomPaintTooltipOverlay(
              hitTest: (pos, size) => _hitTest(pos, size, palette),
              builder: style.tooltipBuilder ?? defaultTooltipBuilder,
              child: TweenAnimationBuilder<double>(
                tween: Tween(
                  begin: style.enableAnimation ? 0.0 : 1.0,
                  end: 1.0,
                ),
                duration: style.enableAnimation ? duration : Duration.zero,
                curve: style.effectiveAnimationCurve,
                builder: (context, t, _) {
                  return CustomPaint(
                    painter: _DendrogramPainter(
                      root: root,
                      orientation: orientation,
                      connector: connector,
                      strokeWidth: strokeWidth,
                      leafRadius: leafRadius,
                      innerNodeRadius: innerNodeRadius,
                      colorByDepth: colorByDepth,
                      showLeafLabels: showLeafLabels,
                      showInnerLabels: showInnerLabels,
                      palette: palette,
                      axisStyle: axisStyle,
                      fg: fg,
                      animation: animation,
                      progress: t,
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  List<TooltipEntry> _hitTest(
    Offset pos,
    Size size,
    List<Color> palette,
  ) {
    final layout = _DendroLayout.compute(
      root: root,
      size: size,
      orientation: orientation,
    );
    if (layout == null) return const [];
    var bestI = -1;
    var bestDist = double.infinity;
    for (var i = 0; i < layout.nodes.length; i++) {
      final d = (layout.nodes[i].pos - pos).distance;
      if (d < bestDist) {
        bestDist = d;
        bestI = i;
      }
    }
    if (bestI < 0 || bestDist > 16) return const [];
    final n = layout.nodes[bestI];
    return [
      TooltipEntry(
        label: n.node.label,
        value: n.node.children.isEmpty ? 'leaf' : '${n.leafCount} leaves',
        color: palette[n.depth % palette.length],
      ),
    ];
  }
}

class _DendroNode {
  _DendroNode({
    required this.node,
    required this.depth,
    required this.pos,
    required this.parentPos,
    required this.leafCount,
  });
  final TreemapNode node;
  final int depth;
  final Offset pos;
  final Offset? parentPos;
  final int leafCount;
}

class _DendroLayout {
  _DendroLayout({
    required this.nodes,
    required this.maxDepth,
    required this.left,
    required this.right,
    required this.top,
    required this.bottom,
  });

  final List<_DendroNode> nodes;
  final int maxDepth;
  final double left;
  final double right;
  final double top;
  final double bottom;

  static _DendroLayout? compute({
    required TreemapNode root,
    required Size size,
    required DendrogramOrientation orientation,
  }) {
    if (size.width <= 0 || size.height <= 0) return null;
    if (root.children.isEmpty) return null;

    const leftPad = 24.0;
    const rightPad = 80.0;
    const topPad = 24.0;
    const bottomPad = 60.0;
    const left = leftPad;
    final right = size.width - rightPad;
    const top = topPad;
    final bottom = size.height - bottomPad;

    // Compute leaf count per subtree.
    int countLeaves(TreemapNode n) {
      if (n.children.isEmpty) return 1;
      var s = 0;
      for (final c in n.children) {
        s += countLeaves(c);
      }
      return s;
    }

    // Max depth.
    int depthOf(TreemapNode n) {
      if (n.children.isEmpty) return 1;
      var m = 0;
      for (final c in n.children) {
        final d = depthOf(c);
        if (d > m) m = d;
      }
      return 1 + m;
    }

    final maxDepth = depthOf(root);
    final totalLeaves = countLeaves(root);

    // Place leaves uniformly along the perpendicular axis. Inner
    // nodes computed bottom-up as midpoint of children.
    final nodes = <_DendroNode>[];
    var leafCursor = 0;

    Offset positionFor(double leafSlot, int depth) {
      // leafSlot in [0, totalLeaves-1]; depth in [0, maxDepth-1].
      if (orientation == DendrogramOrientation.topDown) {
        final x = totalLeaves == 1
            ? (left + right) / 2
            : left + (right - left) * (leafSlot / (totalLeaves - 1));
        final y =
            top +
            (maxDepth == 1 ? 0 : (bottom - top) * (depth / (maxDepth - 1)));
        return Offset(x, y);
      } else {
        final y = totalLeaves == 1
            ? (top + bottom) / 2
            : top + (bottom - top) * (leafSlot / (totalLeaves - 1));
        final x =
            left +
            (maxDepth == 1 ? 0 : (right - left) * (depth / (maxDepth - 1)));
        return Offset(x, y);
      }
    }

    Offset visit(TreemapNode n, int depth, Offset? parentPos) {
      if (n.children.isEmpty) {
        final pos = positionFor(leafCursor.toDouble(), depth);
        leafCursor += 1;
        nodes.add(
          _DendroNode(
            node: n,
            depth: depth,
            pos: pos,
            parentPos: parentPos,
            leafCount: 1,
          ),
        );
        return pos;
      }
      final childPositions = List<Offset>.filled(
        n.children.length,
        Offset.zero,
      );
      // Recurse children first to lay out leaves.
      for (var k = 0; k < n.children.length; k++) {
        // Use a placeholder parent pos for children; will replace
        // their parent reference after we know our position.
        childPositions[k] = visit(n.children[k], depth + 1, null);
      }
      // Inner node sits at midpoint of children's perpendicular axis.
      late Offset pos;
      if (orientation == DendrogramOrientation.topDown) {
        var sumX = 0.0;
        for (final p in childPositions) {
          sumX += p.dx;
        }
        final cx = sumX / childPositions.length;
        final y =
            top +
            (maxDepth == 1 ? 0 : (bottom - top) * (depth / (maxDepth - 1)));
        pos = Offset(cx, y);
      } else {
        var sumY = 0.0;
        for (final p in childPositions) {
          sumY += p.dy;
        }
        final cy = sumY / childPositions.length;
        final x =
            left +
            (maxDepth == 1 ? 0 : (right - left) * (depth / (maxDepth - 1)));
        pos = Offset(x, cy);
      }
      nodes.add(
        _DendroNode(
          node: n,
          depth: depth,
          pos: pos,
          parentPos: parentPos,
          leafCount: countLeaves(n),
        ),
      );
      // Patch children's parentPos by replacing _DendroNode entries.
      for (var k = 0; k < n.children.length; k++) {
        final cPos = childPositions[k];
        final idx = nodes.indexWhere(
          (e) => e.node == n.children[k] && e.pos == cPos,
        );
        if (idx >= 0 && nodes[idx].parentPos == null) {
          nodes[idx] = _DendroNode(
            node: nodes[idx].node,
            depth: nodes[idx].depth,
            pos: nodes[idx].pos,
            parentPos: pos,
            leafCount: nodes[idx].leafCount,
          );
        }
      }
      return pos;
    }

    visit(root, 0, null);

    return _DendroLayout(
      nodes: nodes,
      maxDepth: maxDepth,
      left: left,
      right: right,
      top: top,
      bottom: bottom,
    );
  }
}

class _DendrogramPainter extends CustomPainter {
  _DendrogramPainter({
    required this.root,
    required this.orientation,
    required this.connector,
    required this.strokeWidth,
    required this.leafRadius,
    required this.innerNodeRadius,
    required this.colorByDepth,
    required this.showLeafLabels,
    required this.showInnerLabels,
    required this.palette,
    required this.axisStyle,
    required this.fg,
    required this.animation,
    required this.progress,
  });

  final TreemapNode root;
  final DendrogramOrientation orientation;
  final DendrogramConnector connector;
  final double strokeWidth;
  final double leafRadius;
  final double innerNodeRadius;
  final bool colorByDepth;
  final bool showLeafLabels;
  final bool showInnerLabels;
  final List<Color> palette;
  final TextStyle axisStyle;
  final Color fg;
  final DendrogramAnimation animation;
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final layout = _DendroLayout.compute(
      root: root,
      size: size,
      orientation: orientation,
    );
    if (layout == null) return;

    Color colorFor(int depth) {
      if (!colorByDepth) return fg.withValues(alpha: 0.85);
      return palette[depth % palette.length];
    }

    // ── connectors ──────────────────────────────────────────
    for (final n in layout.nodes) {
      final pp = n.parentPos;
      if (pp == null) continue;

      // Animation params.
      final depth = n.depth;
      double pathProgress;
      double opacity;
      switch (animation) {
        case DendrogramAnimation.grow:
          pathProgress = progress;
          opacity = 1.0;
        case DendrogramAnimation.fade:
          pathProgress = 1.0;
          opacity = progress;
        case DendrogramAnimation.cascade:
          // Strict depth-by-depth reveal — each depth animates only
          // within its own [start, end] window, no overlap between
          // depths. Gives a clear staircase effect vs `grow` which
          // animates all depths simultaneously.
          final span = 1.0 / layout.maxDepth;
          final start = (depth - 1) * span;
          final end = start + span;
          if (progress <= start) {
            pathProgress = 0;
          } else if (progress >= end) {
            pathProgress = 1;
          } else {
            pathProgress = (progress - start) / span;
          }
          opacity = pathProgress;
      }
      if (pathProgress <= 0) continue;

      final c = colorFor(depth);
      final paint = Paint()
        ..color = c.withValues(alpha: opacity)
        ..strokeWidth = strokeWidth
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round;

      final pos = n.pos;
      final path = _buildConnector(
        parent: pp,
        child: pos,
        progress: pathProgress,
      );
      canvas.drawPath(path, paint);
    }

    // ── leaf dots + labels ─────────────────────────────────
    for (final n in layout.nodes) {
      if (n.node.children.isNotEmpty) continue;
      final pos = n.pos;
      double opacity;
      switch (animation) {
        case DendrogramAnimation.grow:
          opacity = (progress - 0.85).clamp(0.0, 0.15) / 0.15;
        case DendrogramAnimation.fade:
          opacity = progress;
        case DendrogramAnimation.cascade:
          final start = (n.depth - 1) / layout.maxDepth.toDouble();
          opacity = ((progress - start - 0.05) / (1 - start - 0.05)).clamp(
            0.0,
            1.0,
          );
      }
      if (opacity <= 0) continue;

      final c = colorFor(n.depth);
      canvas.drawCircle(
        pos,
        leafRadius,
        Paint()..color = c.withValues(alpha: opacity),
      );
      canvas.drawCircle(
        pos,
        leafRadius,
        Paint()
          ..color = Colors.white.withValues(alpha: opacity)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.2,
      );

      if (!showLeafLabels) continue;
      final lblStyle = axisStyle.copyWith(
        color: axisStyle.color?.withValues(alpha: opacity),
        fontWeight: FontWeight.w600,
      );
      final tp = TextPainter(
        text: TextSpan(text: n.node.label, style: lblStyle),
        textDirection: TextDirection.ltr,
        maxLines: 1,
        ellipsis: '…',
      )..layout(maxWidth: 80);
      if (orientation == DendrogramOrientation.topDown) {
        tp.paint(
          canvas,
          Offset(pos.dx - tp.width / 2, pos.dy + leafRadius + 4),
        );
      } else {
        tp.paint(
          canvas,
          Offset(pos.dx + leafRadius + 4, pos.dy - tp.height / 2),
        );
      }
    }

    // ── inner-node dots + labels ───────────────────────────
    for (final n in layout.nodes) {
      if (n.node.children.isEmpty) continue;
      final pos = n.pos;

      // Inner labels appear when this node's connector to its
      // PARENT has finished animating. Root (parentPos == null)
      // appears at the start.
      double opacity;
      switch (animation) {
        case DendrogramAnimation.grow:
          opacity = ((progress - 0.55) / 0.45).clamp(0.0, 1.0);
        case DendrogramAnimation.fade:
          opacity = progress;
        case DendrogramAnimation.cascade:
          if (n.parentPos == null) {
            opacity = (progress / 0.1).clamp(0.0, 1.0);
          } else {
            final span = 1.0 / layout.maxDepth;
            final end = n.depth * span;
            opacity = ((progress - end) / 0.1).clamp(0.0, 1.0);
          }
      }
      if (opacity <= 0) continue;

      final c = colorFor(n.depth);
      if (innerNodeRadius > 0) {
        canvas.drawCircle(
          pos,
          innerNodeRadius,
          Paint()..color = c.withValues(alpha: opacity),
        );
        canvas.drawCircle(
          pos,
          innerNodeRadius,
          Paint()
            ..color = Colors.white.withValues(alpha: opacity)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.0,
        );
      }

      if (!showInnerLabels) continue;
      final lblStyle = axisStyle.copyWith(
        color: axisStyle.color?.withValues(alpha: opacity * 0.85),
        fontWeight: FontWeight.w600,
        fontSize: (axisStyle.fontSize ?? 11) - 1,
      );
      final tp = TextPainter(
        text: TextSpan(text: n.node.label, style: lblStyle),
        textDirection: TextDirection.ltr,
        maxLines: 1,
        ellipsis: '…',
      )..layout(maxWidth: 100);
      // Inner labels: place TOWARD the children side so they sit
      // inside the subtree they label. The root is the exception —
      // it has no parent above/left, so its label stays on the
      // outside (above for topDown, left for leftRight) where it
      // doesn't collide with the connector bar.
      final isRoot = n.parentPos == null;
      if (orientation == DendrogramOrientation.topDown) {
        final dy = isRoot
            ? -innerNodeRadius - 4 - tp.height
            : innerNodeRadius + 4;
        tp.paint(
          canvas,
          Offset(pos.dx - tp.width / 2, pos.dy + dy),
        );
      } else {
        final dx = isRoot
            ? -innerNodeRadius - 4 - tp.width
            : innerNodeRadius + 4;
        tp.paint(
          canvas,
          Offset(pos.dx + dx, pos.dy - tp.height / 2),
        );
      }
    }
  }

  Path _buildConnector({
    required Offset parent,
    required Offset child,
    required double progress,
  }) {
    final path = Path();
    if (progress <= 0) return path;

    switch (connector) {
      case DendrogramConnector.bracket:
        // L-shape sharing a horizontal/vertical bar with siblings.
        // Halve the progress: first half draws along the parent's
        // axis (sibling-shared bar), second half completes the drop.
        if (orientation == DendrogramOrientation.topDown) {
          path.moveTo(parent.dx, parent.dy);
          final endX = parent.dx + (child.dx - parent.dx) * progress;
          path.lineTo(endX, parent.dy);
          if (progress > 0.5) {
            final vertT = ((progress - 0.5) / 0.5).clamp(0.0, 1.0);
            path.lineTo(child.dx, parent.dy);
            path.lineTo(child.dx, parent.dy + (child.dy - parent.dy) * vertT);
          }
        } else {
          path.moveTo(parent.dx, parent.dy);
          final endY = parent.dy + (child.dy - parent.dy) * progress;
          path.lineTo(parent.dx, endY);
          if (progress > 0.5) {
            final horT = ((progress - 0.5) / 0.5).clamp(0.0, 1.0);
            path.lineTo(parent.dx, child.dy);
            path.lineTo(parent.dx + (child.dx - parent.dx) * horT, child.dy);
          }
        }
      case DendrogramConnector.curved:
        // Smooth cubic bezier directly from parent to child. Control
        // points pulled along the layout axis so the curve eases
        // into and out of each end perpendicular to the depth axis.
        final dxs = child.dx - parent.dx;
        final dys = child.dy - parent.dy;
        Offset c1, c2;
        if (orientation == DendrogramOrientation.topDown) {
          c1 = Offset(parent.dx, parent.dy + dys * 0.5);
          c2 = Offset(child.dx, parent.dy + dys * 0.5);
        } else {
          c1 = Offset(parent.dx + dxs * 0.5, parent.dy);
          c2 = Offset(parent.dx + dxs * 0.5, child.dy);
        }
        // Subdivide bezier at `progress` using De Casteljau so the
        // path can grow over time.
        final end = Offset(
          parent.dx + dxs * progress,
          parent.dy + dys * progress,
        );
        // For partial reveal, sample the curve and lineTo each.
        path.moveTo(parent.dx, parent.dy);
        const steps = 24;
        for (var i = 1; i <= steps; i++) {
          final t = (i / steps) * progress;
          final p = _bezier(parent, c1, c2, child, t);
          path.lineTo(p.dx, p.dy);
        }
        // Snap to clamp end (avoid floating drift).
        path.lineTo(end.dx, end.dy);
      case DendrogramConnector.step:
        // Two-bend stepped path — bend at midpoint along the depth
        // axis. Siblings fan out independently (no shared bar).
        if (orientation == DendrogramOrientation.topDown) {
          final midY = (parent.dy + child.dy) / 2;
          // Total length ≈ 3 segments; split progress accordingly.
          path.moveTo(parent.dx, parent.dy);
          final s1 = progress.clamp(0.0, 1 / 3) * 3;
          path.lineTo(parent.dx, parent.dy + (midY - parent.dy) * s1);
          if (progress > 1 / 3) {
            final s2 = ((progress - 1 / 3) / (1 / 3)).clamp(0.0, 1.0);
            path.lineTo(parent.dx + (child.dx - parent.dx) * s2, midY);
          }
          if (progress > 2 / 3) {
            final s3 = ((progress - 2 / 3) / (1 / 3)).clamp(0.0, 1.0);
            path.lineTo(child.dx, midY);
            path.lineTo(child.dx, midY + (child.dy - midY) * s3);
          }
        } else {
          final midX = (parent.dx + child.dx) / 2;
          path.moveTo(parent.dx, parent.dy);
          final s1 = progress.clamp(0.0, 1 / 3) * 3;
          path.lineTo(parent.dx + (midX - parent.dx) * s1, parent.dy);
          if (progress > 1 / 3) {
            final s2 = ((progress - 1 / 3) / (1 / 3)).clamp(0.0, 1.0);
            path.lineTo(midX, parent.dy + (child.dy - parent.dy) * s2);
          }
          if (progress > 2 / 3) {
            final s3 = ((progress - 2 / 3) / (1 / 3)).clamp(0.0, 1.0);
            path.lineTo(midX, child.dy);
            path.lineTo(midX + (child.dx - midX) * s3, child.dy);
          }
        }
      case DendrogramConnector.straight:
        // Direct line parent → child.
        path.moveTo(parent.dx, parent.dy);
        path.lineTo(
          parent.dx + (child.dx - parent.dx) * progress,
          parent.dy + (child.dy - parent.dy) * progress,
        );
      case DendrogramConnector.elbow:
        // Quadratic bend through the midpoint along the depth axis —
        // softer than `step`, more directional than `curved`.
        final Offset ctrl;
        if (orientation == DendrogramOrientation.topDown) {
          ctrl = Offset(child.dx, parent.dy);
        } else {
          ctrl = Offset(parent.dx, child.dy);
        }
        path.moveTo(parent.dx, parent.dy);
        const steps = 24;
        for (var i = 1; i <= steps; i++) {
          final t = (i / steps) * progress;
          final omt = 1 - t;
          final x =
              omt * omt * parent.dx + 2 * omt * t * ctrl.dx + t * t * child.dx;
          final y =
              omt * omt * parent.dy + 2 * omt * t * ctrl.dy + t * t * child.dy;
          path.lineTo(x, y);
        }
    }
    return path;
  }

  Offset _bezier(Offset p0, Offset p1, Offset p2, Offset p3, double t) {
    final omt = 1 - t;
    final x =
        omt * omt * omt * p0.dx +
        3 * omt * omt * t * p1.dx +
        3 * omt * t * t * p2.dx +
        t * t * t * p3.dx;
    final y =
        omt * omt * omt * p0.dy +
        3 * omt * omt * t * p1.dy +
        3 * omt * t * t * p2.dy +
        t * t * t * p3.dy;
    return Offset(x, y);
  }

  @override
  bool shouldRepaint(covariant _DendrogramPainter old) =>
      old.progress != progress ||
      old.root != root ||
      old.orientation != orientation ||
      old.connector != connector ||
      old.animation != animation;
}
