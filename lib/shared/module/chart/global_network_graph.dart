import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/extensions/theme_colors_extension.dart';
import 'chart_data.dart';
import 'chart_internals.dart';
import 'chart_models.dart';
import 'chart_tooltip_overlay.dart';
import 'chart_zoom_pan.dart';
import 'custom_paint_tooltip.dart';

export 'chart_data.dart' show GraphNode, GraphEdge;
export 'chart_models.dart' show ChartStyle, NetworkGraphAnimation;

/// Network / force-directed graph. Nodes laid out via spring +
/// repulsion forces; node radius driven by [GraphNode.value].
/// Edges as straight lines with optional weight-based thickness.
///
/// Layout settles deterministically (seeded RNG) so the same data
/// always renders the same.
///
/// ```dart
/// GlobalNetworkGraph(
///   nodes: [GraphNode(id: 'a', label: 'A'), ...],
///   edges: [GraphEdge(source: 'a', target: 'b'), ...],
/// )
/// ```
class GlobalNetworkGraph extends StatelessWidget {
  const GlobalNetworkGraph({
    required this.nodes,
    required this.edges,
    this.style = ChartStyle.standard,
    this.animation = NetworkGraphAnimation.settle,
    this.iterations = 220,
    this.minRadius = 5,
    this.maxRadius = 16,
    this.edgeOpacity = 0.45,
    this.edgeWidth = 1.0,
    this.colorByGroup = true,
    this.showLabels = true,
    this.seed = 7,
    super.key,
  });

  final List<GraphNode> nodes;
  final List<GraphEdge> edges;
  final ChartStyle style;
  final NetworkGraphAnimation animation;

  /// Force-simulation iterations. Higher = better-settled layout
  /// but slower first paint.
  final int iterations;

  final double minRadius;
  final double maxRadius;
  final double edgeOpacity;
  final double edgeWidth;
  final bool colorByGroup;
  final bool showLabels;
  final int seed;

  @override
  Widget build(BuildContext context) {
    if (nodes.isEmpty) return const SizedBox.shrink();
    final groups = <String>[];
    if (colorByGroup) {
      for (final n in nodes) {
        final g = n.group ?? '';
        if (!groups.contains(g)) groups.add(g);
      }
    }
    final palette = resolveSeriesColors(
      context,
      style,
      colorByGroup ? groups.length.clamp(1, 12) : 1,
    );
    final fg = context.textColors.primary;
    final outline = context.backgroundColors.outlineVariant;
    final axisStyle = resolveAxisLabelStyle(context, style);

    return wrapZoomPan(
      Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minHeight: style.minHeight,
            maxWidth: resolveSquareChartMaxWidth(context, style),
          ),
          child: AspectRatio(
            aspectRatio: 1,
            child: Padding(
              padding: style.padding,
              child: CustomPaintTooltipOverlay(
                hitTest: (pos, size) => _hitTest(pos, size, palette, groups),
                builder: style.tooltipBuilder ?? defaultTooltipBuilder,
                child: TweenAnimationBuilder<double>(
                  tween: Tween(
                    begin: style.enableAnimation ? 0.0 : 1.0,
                    end: 1.0,
                  ),
                  duration: style.enableAnimation
                      ? style.effectiveAnimationDuration
                      : Duration.zero,
                  curve: style.effectiveAnimationCurve,
                  builder: (context, t, _) {
                    return CustomPaint(
                      painter: _NetworkPainter(
                        nodes: nodes,
                        edges: edges,
                        palette: palette,
                        groups: groups,
                        colorByGroup: colorByGroup,
                        showLabels: showLabels,
                        iterations: iterations,
                        minRadius: minRadius,
                        maxRadius: maxRadius,
                        edgeOpacity: edgeOpacity,
                        edgeWidth: edgeWidth,
                        fg: fg,
                        outline: outline,
                        axisStyle: axisStyle,
                        seed: seed,
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
      ),
      style,
    );
  }

  Color _colorFor(GraphNode n, List<Color> palette, List<String> groups) {
    if (n.color != null) return n.color!;
    if (!colorByGroup) return palette.first;
    final idx = groups.indexOf(n.group ?? '');
    return palette[idx.clamp(0, palette.length - 1)];
  }

  List<TooltipEntry> _hitTest(
    Offset pos,
    Size size,
    List<Color> palette,
    List<String> groups,
  ) {
    final layout = _NetworkLayout.compute(
      nodes: nodes,
      edges: edges,
      size: size,
      iterations: iterations,
      minRadius: minRadius,
      maxRadius: maxRadius,
      seed: seed,
    );
    if (layout == null) return const [];
    var bestI = -1;
    var bestDist = double.infinity;
    for (var i = 0; i < nodes.length; i++) {
      final p = layout.positions[i];
      final r = layout.radii[i];
      final d = (p - pos).distance;
      if (d <= r + 4 && d < bestDist) {
        bestDist = d;
        bestI = i;
      }
    }
    if (bestI < 0) return const [];
    final n = nodes[bestI];
    final c = _colorFor(n, palette, groups);
    final connections = edges
        .where(
          (e) => e.source == n.id || e.target == n.id,
        )
        .length;
    return [
      TooltipEntry(
        label: n.label,
        value: '$connections connections',
        color: c,
      ),
    ];
  }
}

class _NetworkLayout {
  _NetworkLayout({
    required this.positions,
    required this.radii,
    required this.idIndex,
  });

  final List<Offset> positions;
  final List<double> radii;
  final Map<String, int> idIndex;

  static _NetworkLayout? compute({
    required List<GraphNode> nodes,
    required List<GraphEdge> edges,
    required Size size,
    required int iterations,
    required double minRadius,
    required double maxRadius,
    required int seed,
  }) {
    if (size.width <= 0 || size.height <= 0) return null;
    if (nodes.isEmpty) return null;

    final n = nodes.length;
    final cx = size.width / 2;
    final cy = size.height / 2;
    final rng = math.Random(seed);

    // Seed positions on a circle so initial layout is deterministic.
    final pos = List<Offset>.generate(n, (i) {
      final theta = i / n * math.pi * 2;
      final r = math.min(cx, cy) * 0.4 + rng.nextDouble() * 12;
      return Offset(cx + r * math.cos(theta), cy + r * math.sin(theta));
    });

    final idIndex = <String, int>{
      for (var i = 0; i < n; i++) nodes[i].id: i,
    };

    // Compute radii.
    var maxV = 0.0;
    for (final node in nodes) {
      if (node.value > maxV) maxV = node.value;
    }
    if (maxV == 0) maxV = 1;
    final radii = <double>[];
    for (final node in nodes) {
      final t = math.sqrt(node.value / maxV).clamp(0.0, 1.0);
      radii.add(minRadius + (maxRadius - minRadius) * t);
    }

    // Force constants — empirical defaults.
    final area = size.width * size.height;
    final k = math.sqrt(area / n) * 0.55;
    const centerStrength = 0.012;
    final maxDisp = math.min(cx, cy) * 0.08;
    const pad = 12.0;
    final outerRadius = math.min(cx, cy) - pad;

    final velocity = List<Offset>.filled(n, Offset.zero);
    var temperature = math.min(cx, cy) * 0.18;

    for (var iter = 0; iter < iterations; iter++) {
      final disp = List<Offset>.filled(n, Offset.zero);

      // Repulsive forces between all node pairs.
      for (var i = 0; i < n; i++) {
        for (var j = i + 1; j < n; j++) {
          final delta = pos[i] - pos[j];
          var d = delta.distance;
          if (d < 0.001) d = 0.001;
          final force = (k * k) / d;
          final unit = delta / d;
          disp[i] += unit * force;
          disp[j] -= unit * force;
        }
      }

      // Attractive forces along edges (Hooke springs).
      for (final e in edges) {
        final si = idIndex[e.source];
        final ti = idIndex[e.target];
        if (si == null || ti == null) continue;
        final delta = pos[si] - pos[ti];
        var d = delta.distance;
        if (d < 0.001) d = 0.001;
        final force = (d * d) / k * e.weight;
        final unit = delta / d;
        disp[si] -= unit * force;
        disp[ti] += unit * force;
      }

      // Gentle pull toward center.
      for (var i = 0; i < n; i++) {
        final toCenter = Offset(cx, cy) - pos[i];
        disp[i] += toCenter * centerStrength * k;
      }

      // Apply displacement clamped by temperature; settle velocity.
      for (var i = 0; i < n; i++) {
        var d = disp[i];
        final mag = d.distance;
        if (mag > 0) {
          final clamped = math.min(mag, temperature);
          d = d / mag * clamped;
        }
        velocity[i] = velocity[i] * 0.5 + d * 0.5;
        var newPos = pos[i] + velocity[i];
        // Keep inside outer circle (square clamp acceptable too).
        final fromCenter = newPos - Offset(cx, cy);
        final dist = fromCenter.distance;
        if (dist > outerRadius) {
          newPos = Offset(cx, cy) + fromCenter / dist * outerRadius;
        }
        pos[i] = newPos;
      }

      // Cool.
      temperature *= 0.97;
      if (temperature < maxDisp * 0.05) break;
    }

    return _NetworkLayout(
      positions: pos,
      radii: radii,
      idIndex: idIndex,
    );
  }
}

class _NetworkPainter extends CustomPainter {
  _NetworkPainter({
    required this.nodes,
    required this.edges,
    required this.palette,
    required this.groups,
    required this.colorByGroup,
    required this.showLabels,
    required this.iterations,
    required this.minRadius,
    required this.maxRadius,
    required this.edgeOpacity,
    required this.edgeWidth,
    required this.fg,
    required this.outline,
    required this.axisStyle,
    required this.seed,
    required this.animation,
    required this.progress,
  });

  final List<GraphNode> nodes;
  final List<GraphEdge> edges;
  final List<Color> palette;
  final List<String> groups;
  final bool colorByGroup;
  final bool showLabels;
  final int iterations;
  final double minRadius;
  final double maxRadius;
  final double edgeOpacity;
  final double edgeWidth;
  final Color fg;
  final Color outline;
  final TextStyle axisStyle;
  final int seed;
  final NetworkGraphAnimation animation;
  final double progress;

  Color _colorFor(GraphNode n) {
    if (n.color != null) return n.color!;
    if (!colorByGroup) return palette.first;
    final idx = groups.indexOf(n.group ?? '');
    return palette[idx.clamp(0, palette.length - 1)];
  }

  @override
  void paint(Canvas canvas, Size size) {
    final layout = _NetworkLayout.compute(
      nodes: nodes,
      edges: edges,
      size: size,
      iterations: iterations,
      minRadius: minRadius,
      maxRadius: maxRadius,
      seed: seed,
    );
    if (layout == null) return;

    final cx = size.width / 2;
    final cy = size.height / 2;

    // Animation interp: lerp from initial circle positions to final
    // settled positions for `settle` mode.
    final initialPos = List<Offset>.generate(nodes.length, (i) {
      final theta = i / nodes.length * math.pi * 2;
      final r = math.min(cx, cy) * 0.85;
      return Offset(cx + r * math.cos(theta), cy + r * math.sin(theta));
    });
    Offset posFor(int i) {
      final settled = layout.positions[i];
      switch (animation) {
        case NetworkGraphAnimation.settle:
          return Offset.lerp(initialPos[i], settled, progress)!;
        case NetworkGraphAnimation.fade:
        case NetworkGraphAnimation.ripple:
          return settled;
      }
    }

    double opacityFor(int i) {
      switch (animation) {
        case NetworkGraphAnimation.settle:
          return progress;
        case NetworkGraphAnimation.fade:
          return progress;
        case NetworkGraphAnimation.ripple:
          final settled = layout.positions[i];
          final d = (settled - Offset(cx, cy)).distance / math.min(cx, cy);
          final delay = d.clamp(0.0, 1.0) * 0.5;
          return ((progress - delay) / (1 - delay)).clamp(0.0, 1.0);
      }
    }

    // Edges.
    for (final e in edges) {
      final si = layout.idIndex[e.source];
      final ti = layout.idIndex[e.target];
      if (si == null || ti == null) continue;
      final s = posFor(si);
      final t = posFor(ti);
      final ec = e.color ?? fg;
      final op = math.min(opacityFor(si), opacityFor(ti));
      canvas.drawLine(
        s,
        t,
        Paint()
          ..color = ec.withValues(alpha: edgeOpacity * op)
          ..strokeWidth = edgeWidth * e.weight
          ..strokeCap = StrokeCap.round,
      );
    }

    // Nodes.
    for (var i = 0; i < nodes.length; i++) {
      final pos = posFor(i);
      final r = layout.radii[i];
      final c = _colorFor(nodes[i]);
      final op = opacityFor(i);
      if (op <= 0) continue;
      // Halo.
      canvas.drawCircle(
        pos,
        r + 1.5,
        Paint()..color = outline.withValues(alpha: op),
      );
      canvas.drawCircle(
        pos,
        r,
        Paint()..color = c.withValues(alpha: op),
      );
    }

    // Labels.
    if (!showLabels) return;
    if (progress < 0.55) return;
    final fadeRaw = ((progress - 0.55) / 0.45).clamp(0.0, 1.0);
    final fade = Curves.easeOutCubic.transform(fadeRaw);
    for (var i = 0; i < nodes.length; i++) {
      final pos = posFor(i);
      final r = layout.radii[i];
      final tp = TextPainter(
        text: TextSpan(
          text: nodes[i].label,
          style: axisStyle.copyWith(
            color: fg.withValues(alpha: fade * 0.92),
            fontWeight: FontWeight.w600,
          ),
        ),
        textDirection: TextDirection.ltr,
        maxLines: 1,
        ellipsis: '…',
      )..layout(maxWidth: 80);
      tp.paint(
        canvas,
        Offset(pos.dx + r + 3, pos.dy - tp.height / 2),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _NetworkPainter old) =>
      old.progress != progress ||
      old.nodes != nodes ||
      old.edges != edges ||
      old.animation != animation;
}
