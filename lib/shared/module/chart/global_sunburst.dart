import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/extensions/theme_colors_extension.dart';
import '../../../core/localization/number_formatter.dart';
import 'chart_data.dart';
import 'chart_internals.dart';
import 'chart_models.dart';
import 'chart_tooltip_overlay.dart';
import 'custom_paint_tooltip.dart';

export 'chart_data.dart' show TreemapNode;
export 'chart_models.dart' show ChartStyle, SunburstAnimation;

/// Sunburst chart — radial hierarchy. Root sits at the center;
/// each ring outward is one level of the tree. A child's angular
/// sweep is proportional to its share of its parent's total.
///
/// Reuses [TreemapNode] for hierarchical input. Hit-testing walks
/// from the cursor's polar coordinates down through the visible
/// ring at that radius.
///
/// ```dart
/// GlobalSunburst(
///   root: TreemapNode(label: 'All', children: [
///     TreemapNode(label: 'EU', children: [
///       TreemapNode(label: 'DE', value: 30),
///       TreemapNode(label: 'FR', value: 18),
///     ]),
///     TreemapNode(label: 'NA', value: 50),
///   ]),
/// )
/// ```
class GlobalSunburst extends StatelessWidget {
  const GlobalSunburst({
    required this.root,
    this.style = ChartStyle.standard,
    this.animation = SunburstAnimation.sweep,
    this.startRadius = 0.0,
    this.gap = 1.5,
    this.showLabels = true,
    this.showValueLabels = false,
    this.minLabelSweep = 0.18,
    this.centerLabel,
    this.centerSubLabel,
    this.valueFormatter,
    super.key,
  });

  /// The root container. Its [TreemapNode.label] / [TreemapNode.value]
  /// are not painted as a wedge — only its children are.
  final TreemapNode root;
  final ChartStyle style;
  final SunburstAnimation animation;

  /// Inner empty radius (donut). 0 = filled center.
  final double startRadius;

  /// Pixel gap between adjacent wedges (radial + angular separation).
  final double gap;

  /// Show in-wedge labels for slices wider than [minLabelSweep] rad.
  final bool showLabels;

  /// Show the wedge's value (count-up animated) below the label
  /// when there's enough room.
  final bool showValueLabels;

  /// Minimum angular sweep (radians) before a label paints.
  final double minLabelSweep;

  final String? centerLabel;
  final String? centerSubLabel;
  final String Function(double)? valueFormatter;

  @override
  Widget build(BuildContext context) {
    if (root.children.isEmpty) return const SizedBox.shrink();

    final palette = resolveSeriesColors(
      context,
      style,
      root.children.length.clamp(1, 12),
    );
    final axisStyle = resolveAxisLabelStyle(context, style);
    final fmt = valueFormatter ?? (v) => AppNumbers.compact(v);
    final fg = context.textColors.primary;

    final nodes = _flatten(root, palette, depth: 1, parentSweep: math.pi * 2);

    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          minHeight: style.minHeight,
          maxWidth: resolveSquareChartMaxWidth(context, style),
        ),
        child: AspectRatio(
          aspectRatio: 1,
          child: Padding(
            padding: style.padding,
            child: Stack(
              alignment: Alignment.center,
              clipBehavior: Clip.none,
              children: [
                CustomPaintTooltipOverlay(
                  hitTest: (pos, size) => _hitTest(pos, size, nodes, fmt),
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
                      final painter = CustomPaint(
                        painter: _SunburstPainter(
                          nodes: nodes,
                          startRadius: startRadius,
                          gap: gap,
                          showLabels: showLabels,
                          showValueLabels: showValueLabels,
                          minLabelSweep: minLabelSweep,
                          axisStyle: axisStyle,
                          valueFormatter: fmt,
                          progress: t,
                          animation: animation,
                        ),
                      );
                      switch (animation) {
                        case SunburstAnimation.fade:
                          return Opacity(opacity: t, child: painter);
                        case SunburstAnimation.spin:
                          return Transform.rotate(
                            angle: -math.pi * (1 - t),
                            child: painter,
                          );
                        case SunburstAnimation.sweep:
                        case SunburstAnimation.grow:
                          return painter;
                      }
                    },
                  ),
                ),
                if (centerLabel != null)
                  IgnorePointer(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          centerLabel!,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: fg,
                              ),
                        ),
                        if (centerSubLabel != null) ...[
                          const SizedBox(height: 2),
                          Text(
                            centerSubLabel!,
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(color: context.textColors.secondary),
                          ),
                        ],
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── flatten ──────────────────────────────────────────────
  List<_RingSlice> _flatten(
    TreemapNode root,
    List<Color> palette, {
    required int depth,
    required double parentSweep,
  }) {
    final out = <_RingSlice>[];
    var rootIndex = 0;
    void walk(
      TreemapNode parent, {
      required double startAngle,
      required double sweep,
      required int d,
      required Color baseColor,
    }) {
      final total = parent.children.fold<double>(0, (s, c) => s + c.totalValue);
      if (total <= 0) return;
      var a = startAngle;
      for (var i = 0; i < parent.children.length; i++) {
        final c = parent.children[i];
        final share = c.totalValue / total;
        final s = sweep * share;
        // Color inheritance: top-level uses palette directly,
        // descendants tint base toward white as depth increases.
        final color =
            c.color ??
            (d == 1
                ? palette[rootIndex % palette.length]
                : Color.lerp(baseColor, Colors.white, 0.18 * (d - 1))!);
        out.add(
          _RingSlice(
            node: c,
            depth: d,
            startAngle: a,
            sweep: s,
            color: color,
          ),
        );
        if (c.children.isNotEmpty) {
          walk(c, startAngle: a, sweep: s, d: d + 1, baseColor: color);
        }
        a += s;
      }
    }

    // Top-level: each child gets its share of full circle, color
    // is fixed by `rootIndex` so child trees inherit the right hue.
    final total = root.children.fold<double>(0, (s, c) => s + c.totalValue);
    if (total <= 0) return out;
    var a = -math.pi / 2; // 12 o'clock start
    for (var i = 0; i < root.children.length; i++) {
      rootIndex = i;
      final c = root.children[i];
      final share = c.totalValue / total;
      final s = math.pi * 2 * share;
      final color = c.color ?? palette[i % palette.length];
      out.add(
        _RingSlice(
          node: c,
          depth: 1,
          startAngle: a,
          sweep: s,
          color: color,
        ),
      );
      if (c.children.isNotEmpty) {
        walk(c, startAngle: a, sweep: s, d: 2, baseColor: color);
      }
      a += s;
    }
    return out;
  }

  // ── hit test ─────────────────────────────────────────────
  List<TooltipEntry> _hitTest(
    Offset pos,
    Size size,
    List<_RingSlice> nodes,
    String Function(double) fmt,
  ) {
    if (nodes.isEmpty) return const [];
    final cx = size.width / 2;
    final cy = size.height / 2;
    final outer = math.min(cx, cy);
    final dx = pos.dx - cx;
    final dy = pos.dy - cy;
    final r = math.sqrt(dx * dx + dy * dy);
    if (r > outer) return const [];
    final maxDepth = nodes.fold<int>(0, (m, n) => n.depth > m ? n.depth : m);
    final ringStart = startRadius * outer;
    final ringRange = outer - ringStart;
    final ringWidth = ringRange / maxDepth;
    if (r < ringStart) return const [];
    final depth =
        ((r - ringStart) / ringWidth).floor().clamp(0, maxDepth - 1) + 1;
    var theta = math.atan2(dy, dx);
    // Normalize to [-π/2, 3π/2) so we match the start at 12 o'clock.
    while (theta < -math.pi / 2) {
      theta += math.pi * 2;
    }
    while (theta >= math.pi * 2 - math.pi / 2) {
      theta -= math.pi * 2;
    }
    for (final n in nodes) {
      if (n.depth != depth) continue;
      var a0 = n.startAngle;
      var a1 = n.startAngle + n.sweep;
      while (a0 < -math.pi / 2) {
        a0 += math.pi * 2;
        a1 += math.pi * 2;
      }
      if (theta >= a0 && theta < a1) {
        return [
          TooltipEntry(
            label: n.node.label,
            value: fmt(n.node.totalValue),
            color: n.color,
          ),
        ];
      }
    }
    return const [];
  }
}

class _RingSlice {
  _RingSlice({
    required this.node,
    required this.depth,
    required this.startAngle,
    required this.sweep,
    required this.color,
  });

  final TreemapNode node;
  final int depth;
  final double startAngle;
  final double sweep;
  final Color color;
}

class _SunburstPainter extends CustomPainter {
  _SunburstPainter({
    required this.nodes,
    required this.startRadius,
    required this.gap,
    required this.showLabels,
    required this.showValueLabels,
    required this.minLabelSweep,
    required this.axisStyle,
    required this.valueFormatter,
    required this.progress,
    required this.animation,
  });

  final List<_RingSlice> nodes;
  final double startRadius;
  final double gap;
  final bool showLabels;
  final bool showValueLabels;
  final double minLabelSweep;
  final TextStyle axisStyle;
  final String Function(double) valueFormatter;
  final double progress;
  final SunburstAnimation animation;

  @override
  void paint(Canvas canvas, Size size) {
    if (nodes.isEmpty) return;
    final cx = size.width / 2;
    final cy = size.height / 2;
    final outer = math.min(cx, cy);
    final maxDepth = nodes.fold<int>(0, (m, n) => n.depth > m ? n.depth : m);
    final ringStart = startRadius * outer;
    final ringRange = outer - ringStart;
    final ringWidth = ringRange / maxDepth;

    for (final n in nodes) {
      final rIn = ringStart + (n.depth - 1) * ringWidth + gap / 2;
      final rOut = ringStart + n.depth * ringWidth - gap / 2;
      if (rOut <= rIn) continue;

      // Animation handling.
      var sweep = n.sweep;
      final startAngle = n.startAngle;
      var rOutAnim = rOut;
      if (animation == SunburstAnimation.sweep) {
        sweep = n.sweep * progress;
      } else if (animation == SunburstAnimation.grow) {
        rOutAnim = rIn + (rOut - rIn) * progress;
      }
      if (sweep <= 0) continue;
      if (rOutAnim <= rIn) continue;

      // Wedge path: outer arc cw, inner arc ccw.
      final path = Path();
      final centerR = Rect.fromCircle(center: Offset(cx, cy), radius: rOutAnim);
      final innerR = Rect.fromCircle(center: Offset(cx, cy), radius: rIn);

      // Reduce angular sweep slightly to leave a gap between wedges.
      final angularGap = (gap / rOutAnim).clamp(0.0, 0.05);
      final a0 = startAngle + angularGap / 2;
      final a1 = startAngle + sweep - angularGap / 2;
      if (a1 <= a0) continue;

      path
        ..moveTo(cx + rIn * math.cos(a0), cy + rIn * math.sin(a0))
        ..lineTo(cx + rOutAnim * math.cos(a0), cy + rOutAnim * math.sin(a0))
        ..arcTo(centerR, a0, a1 - a0, false)
        ..lineTo(cx + rIn * math.cos(a1), cy + rIn * math.sin(a1))
        ..arcTo(innerR, a1, -(a1 - a0), false)
        ..close();

      canvas.drawPath(path, Paint()..color = n.color);

      // Labels.
      if (!showLabels && !showValueLabels) continue;
      if (n.sweep < minLabelSweep) continue;

      // Smooth fade — start at 0.55, finish at 1.0 (45% window).
      if (progress < 0.55) continue;
      final fadeRaw = ((progress - 0.55) / 0.45).clamp(0.0, 1.0);
      final fade = Curves.easeOutCubic.transform(fadeRaw);

      final mid = startAngle + sweep / 2;
      final rMid = (rIn + rOutAnim) / 2;
      final tx = cx + rMid * math.cos(mid);
      final ty = cy + rMid * math.sin(mid);

      // Available width inside the wedge: smaller of radial extent
      // and arc length at midR. If text overflows both, skip.
      final radialW = rOutAnim - rIn - 6;
      final arcW = sweep * rMid - 4;
      final availW = math.min(radialW, arcW);
      if (availW < 16) continue;

      final labelColor = _labelColorFor(n.color).withValues(alpha: fade);
      final lblStyle = axisStyle.copyWith(
        color: labelColor,
        fontWeight: FontWeight.w600,
        fontSize: (axisStyle.fontSize ?? 11) - 1,
        shadows: const [],
      );
      final valStyle = lblStyle.copyWith(
        fontWeight: FontWeight.w500,
        fontSize: (axisStyle.fontSize ?? 11) - 2,
        color: labelColor.withValues(alpha: fade * 0.8),
      );

      // Build text. Optionally count-up the value.
      final showLbl = showLabels;
      final showVal = showValueLabels;
      TextPainter? labelTp;
      TextPainter? valueTp;
      if (showLbl) {
        labelTp = TextPainter(
          text: TextSpan(text: n.node.label, style: lblStyle),
          textDirection: TextDirection.ltr,
          maxLines: 1,
          ellipsis: '…',
        )..layout(maxWidth: availW);
        if (labelTp.didExceedMaxLines || labelTp.width > availW + 0.5) {
          // Fallback: skip entirely if even with ellipsis it can't fit.
          continue;
        }
      }
      if (showVal) {
        final displayed = n.node.totalValue * progress;
        valueTp = TextPainter(
          text: TextSpan(text: valueFormatter(displayed), style: valStyle),
          textDirection: TextDirection.ltr,
          maxLines: 1,
          ellipsis: '…',
        )..layout(maxWidth: availW);
      }

      // Vertical stacking. Center the combined block at (tx, ty).
      final lblH = labelTp?.height ?? 0;
      final valH = valueTp?.height ?? 0;
      final lineGap = (lblH > 0 && valH > 0) ? 1.0 : 0.0;
      final totalH = lblH + valH + lineGap;
      var y = ty - totalH / 2;
      if (labelTp != null) {
        labelTp.paint(canvas, Offset(tx - labelTp.width / 2, y));
        y += lblH + lineGap;
      }
      if (valueTp != null) {
        valueTp.paint(canvas, Offset(tx - valueTp.width / 2, y));
      }
    }
  }

  Color _labelColorFor(Color bg) {
    final lum = bg.computeLuminance();
    // Soft black / soft off-white — full white reads as glare on
    // bright wedges, full black is too heavy on dark wedges.
    return lum > 0.55 ? const Color(0xFF1A1A1A) : const Color(0xFFEDEDED);
  }

  @override
  bool shouldRepaint(covariant _SunburstPainter old) =>
      old.progress != progress ||
      old.nodes != nodes ||
      old.animation != animation ||
      old.showLabels != showLabels ||
      old.showValueLabels != showValueLabels;
}
