import 'package:flutter/material.dart';

import '../../../core/localization/number_formatter.dart';
import 'chart_data.dart';
import 'chart_internals.dart';
import 'chart_models.dart';
import 'chart_tooltip_overlay.dart';
import 'custom_paint_tooltip.dart';

export 'chart_data.dart' show SankeyNode, SankeyLink;
export 'chart_models.dart' show ChartStyle, SankeyAnimation;

/// Sankey diagram — flows between staged nodes, link thickness
/// proportional to value. Stages stack horizontally; nodes within
/// a stage stack vertically. Links draw as cubic-bezier ribbons
/// from source's right edge to target's left edge.
///
/// ```dart
/// GlobalSankey(
///   nodes: [
///     SankeyNode(id: 'src', label: 'Search', stage: 0),
///     SankeyNode(id: 'app', label: 'Sign-up', stage: 1),
///     SankeyNode(id: 'won', label: 'Paid', stage: 2),
///   ],
///   links: [
///     SankeyLink(source: 'src', target: 'app', value: 600),
///     SankeyLink(source: 'app', target: 'won', value: 220),
///   ],
/// )
/// ```
class GlobalSankey extends StatelessWidget {
  const GlobalSankey({
    required this.nodes,
    required this.links,
    this.style = ChartStyle.standard,
    this.animation = SankeyAnimation.fade,
    this.nodeWidth = 14,
    this.nodePadding = 12,
    this.linkOpacity = 0.45,
    this.showValues = true,
    this.showLabels = true,
    this.valueFormatter,
    super.key,
  });

  final List<SankeyNode> nodes;
  final List<SankeyLink> links;
  final ChartStyle style;
  final SankeyAnimation animation;
  final double nodeWidth;
  final double nodePadding;
  final double linkOpacity;
  final bool showValues;
  final bool showLabels;
  final String Function(double)? valueFormatter;

  @override
  Widget build(BuildContext context) {
    if (nodes.isEmpty || links.isEmpty) return const SizedBox.shrink();

    final palette = resolveSeriesColors(context, style, nodes.length);
    final colorById = <String, Color>{
      for (var i = 0; i < nodes.length; i++)
        nodes[i].id: nodes[i].color ?? palette[i],
    };
    final axisStyle = resolveAxisLabelStyle(context, style);
    final fmt = valueFormatter ?? (v) => AppNumbers.compact(v);

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
              hitTest: (pos, size) => _hitTest(pos, size, colorById, fmt),
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
                    painter: _SankeyPainter(
                      nodes: nodes,
                      links: links,
                      colorById: colorById,
                      nodeWidth: nodeWidth,
                      nodePadding: nodePadding,
                      linkOpacity: linkOpacity,
                      showValues: showValues,
                      showLabels: showLabels,
                      axisStyle: axisStyle,
                      valueFormatter: fmt,
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
    Map<String, Color> colorById,
    String Function(double) fmt,
  ) {
    if (pos.dx < 0 || pos.dx > size.width) return const [];
    if (pos.dy < 0 || pos.dy > size.height) return const [];
    final layout = _SankeyLayout.compute(
      nodes: nodes,
      links: links,
      size: size,
      nodeWidth: nodeWidth,
      nodePadding: nodePadding,
    );
    if (layout == null) return const [];
    // Hit-test nodes first (priority over thin links).
    for (final n in layout.nodeRects.entries) {
      if (n.value.contains(pos)) {
        final node = nodes.firstWhere((x) => x.id == n.key);
        final inflow = links
            .where((l) => l.target == n.key)
            .fold<double>(0, (s, l) => s + l.value);
        final outflow = links
            .where((l) => l.source == n.key)
            .fold<double>(0, (s, l) => s + l.value);
        final total = inflow > outflow ? inflow : outflow;
        return [
          TooltipEntry(
            label: node.label,
            value: fmt(total),
            color: colorById[node.id]!,
            icon: node.icon,
            iconAsset: node.iconAsset,
            iconWidget: node.iconWidget,
          ),
        ];
      }
    }
    // Find closest link.
    var bestI = -1;
    var bestDist = double.infinity;
    for (var i = 0; i < layout.linkPaths.length; i++) {
      final mid = layout.linkMidpoints[i];
      final d = (mid - pos).distance;
      if (d < bestDist) {
        bestDist = d;
        bestI = i;
      }
    }
    if (bestI < 0 || bestDist > 32) return const [];
    final l = links[bestI];
    final src = nodes.firstWhere((x) => x.id == l.source);
    final tgt = nodes.firstWhere((x) => x.id == l.target);
    return [
      TooltipEntry(
        label: '${src.label} → ${tgt.label}',
        value: fmt(l.value),
        color: l.color ?? colorById[l.source]!,
      ),
    ];
  }
}

class _SankeyLayout {
  _SankeyLayout({
    required this.nodeRects,
    required this.linkPaths,
    required this.linkMidpoints,
    required this.linkSourceColors,
    required this.linkTargetColors,
    required this.linkThickness,
    required this.size,
  });

  final Map<String, Rect> nodeRects;
  final List<Path> linkPaths;
  final List<Offset> linkMidpoints;
  final List<Color> linkSourceColors;
  final List<Color> linkTargetColors;
  final List<double> linkThickness;
  final Size size;

  static _SankeyLayout? compute({
    required List<SankeyNode> nodes,
    required List<SankeyLink> links,
    required Size size,
    required double nodeWidth,
    required double nodePadding,
  }) {
    if (size.width <= 0 || size.height <= 0) return null;
    if (nodes.isEmpty) return null;

    // Group by stage.
    final stages = <int, List<SankeyNode>>{};
    for (final n in nodes) {
      stages.putIfAbsent(n.stage, () => []).add(n);
    }
    final stageKeys = stages.keys.toList()..sort();

    // Compute throughput per node.
    final throughput = <String, double>{};
    for (final n in nodes) {
      final inflow = links
          .where((l) => l.target == n.id)
          .fold<double>(0, (s, l) => s + l.value);
      final outflow = links
          .where((l) => l.source == n.id)
          .fold<double>(0, (s, l) => s + l.value);
      throughput[n.id] = inflow > outflow ? inflow : outflow;
    }

    // Find max stage total (for value-to-pixel scaling).
    var maxStageTotal = 0.0;
    for (final s in stageKeys) {
      final total = stages[s]!.fold<double>(
        0,
        (sum, n) => sum + (throughput[n.id] ?? 0),
      );
      if (total > maxStageTotal) maxStageTotal = total;
    }
    if (maxStageTotal <= 0) return null;

    // Available vertical space for the "fullest" stage:
    // size.height − (maxNodes − 1) × padding.
    var maxNodes = 0;
    for (final s in stageKeys) {
      if (stages[s]!.length > maxNodes) maxNodes = stages[s]!.length;
    }
    final availH = size.height - (maxNodes - 1) * nodePadding;
    if (availH <= 0) return null;
    final scale = availH / maxStageTotal;

    // Horizontal positions: evenly spaced columns.
    final stageCount = stageKeys.length;
    final columnX = <int, double>{};
    if (stageCount == 1) {
      columnX[stageKeys.first] = (size.width - nodeWidth) / 2;
    } else {
      for (var i = 0; i < stageCount; i++) {
        final t = i / (stageCount - 1);
        columnX[stageKeys[i]] = t * (size.width - nodeWidth);
      }
    }

    // Place nodes vertically centered within each column.
    final nodeRects = <String, Rect>{};
    for (final s in stageKeys) {
      final list = stages[s]!;
      final totalH =
          list.fold<double>(
            0,
            (sum, n) => sum + (throughput[n.id] ?? 0) * scale,
          ) +
          (list.length - 1) * nodePadding;
      var y = (size.height - totalH) / 2;
      final x = columnX[s]!;
      for (final n in list) {
        final h = (throughput[n.id] ?? 0) * scale;
        nodeRects[n.id] = Rect.fromLTWH(x, y, nodeWidth, h);
        y += h + nodePadding;
      }
    }

    // Build link paths. Per node, track running offsets for
    // outgoing (right edge of source) and incoming (left edge of
    // target) so multiple links per node stack neatly.
    final outOffset = <String, double>{};
    final inOffset = <String, double>{};
    final linkPaths = <Path>[];
    final linkMidpoints = <Offset>[];
    final linkSrcColors = <Color>[];
    final linkTgtColors = <Color>[];
    final linkThickness = <double>[];

    // Sort links per source by target position (top-to-bottom)
    // so ribbons don't cross unnecessarily.
    final sortedLinks = [...links]
      ..sort((a, b) {
        final ra = nodeRects[a.target];
        final rb = nodeRects[b.target];
        if (ra == null || rb == null) return 0;
        return ra.top.compareTo(rb.top);
      });

    for (final l in sortedLinks) {
      final srcR = nodeRects[l.source];
      final tgtR = nodeRects[l.target];
      if (srcR == null || tgtR == null) continue;
      final h = l.value * scale;
      final srcY0 = srcR.top + (outOffset[l.source] ?? 0);
      final tgtY0 = tgtR.top + (inOffset[l.target] ?? 0);
      outOffset[l.source] = (outOffset[l.source] ?? 0) + h;
      inOffset[l.target] = (inOffset[l.target] ?? 0) + h;

      final x0 = srcR.right;
      final x1 = tgtR.left;
      final cx0 = x0 + (x1 - x0) * 0.5;
      final cx1 = x0 + (x1 - x0) * 0.5;
      final p = Path()
        ..moveTo(x0, srcY0)
        ..cubicTo(cx0, srcY0, cx1, tgtY0, x1, tgtY0)
        ..lineTo(x1, tgtY0 + h)
        ..cubicTo(cx1, tgtY0 + h, cx0, srcY0 + h, x0, srcY0 + h)
        ..close();
      linkPaths.add(p);
      linkMidpoints.add(Offset((x0 + x1) / 2, (srcY0 + tgtY0 + h) / 2));
      linkSrcColors.add(l.color ?? Colors.transparent);
      linkTgtColors.add(l.color ?? Colors.transparent);
      linkThickness.add(h);
    }

    return _SankeyLayout(
      nodeRects: nodeRects,
      linkPaths: linkPaths,
      linkMidpoints: linkMidpoints,
      linkSourceColors: linkSrcColors,
      linkTargetColors: linkTgtColors,
      linkThickness: linkThickness,
      size: size,
    );
  }
}

class _SankeyPainter extends CustomPainter {
  _SankeyPainter({
    required this.nodes,
    required this.links,
    required this.colorById,
    required this.nodeWidth,
    required this.nodePadding,
    required this.linkOpacity,
    required this.showValues,
    required this.showLabels,
    required this.axisStyle,
    required this.valueFormatter,
    required this.animation,
    required this.progress,
  });

  final List<SankeyNode> nodes;
  final List<SankeyLink> links;
  final Map<String, Color> colorById;
  final double nodeWidth;
  final double nodePadding;
  final double linkOpacity;
  final bool showValues;
  final bool showLabels;
  final TextStyle axisStyle;
  final String Function(double) valueFormatter;
  final SankeyAnimation animation;
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final layout = _SankeyLayout.compute(
      nodes: nodes,
      links: links,
      size: size,
      nodeWidth: nodeWidth,
      nodePadding: nodePadding,
    );
    if (layout == null) return;

    final stages = <int, List<SankeyNode>>{};
    for (final n in nodes) {
      stages.putIfAbsent(n.stage, () => []).add(n);
    }
    final stageKeys = stages.keys.toList()..sort();
    final firstStage = stageKeys.first;
    final lastStage = stageKeys.last;
    final stageCount = stageKeys.length;
    final stageIndex = <int, int>{
      for (var i = 0; i < stageCount; i++) stageKeys[i]: i,
    };

    // Sort links so the largest-thickness ones paint first (under).
    final order = List<int>.generate(layout.linkPaths.length, (i) => i)
      ..sort(
        (a, b) => layout.linkThickness[b].compareTo(layout.linkThickness[a]),
      );
    final sortedLinks = [...links]
      ..sort((a, b) {
        final ra = layout.nodeRects[a.target];
        final rb = layout.nodeRects[b.target];
        if (ra == null || rb == null) return 0;
        return ra.top.compareTo(rb.top);
      });

    // ── per-mode helpers ────────────────────────────────────
    double linkProgress(int linkIndex) {
      final l = sortedLinks[linkIndex];
      final srcStage =
          stageIndex[nodes.firstWhere((n) => n.id == l.source).stage] ?? 0;
      switch (animation) {
        case SankeyAnimation.fade:
          return progress;
        case SankeyAnimation.flow:
          // Links draw 0 → 0.7, then nodes pop after.
          return (progress / 0.7).clamp(0.0, 1.0);
        case SankeyAnimation.drop:
          // Links fade in 0.5 → 1.0 after nodes drop.
          return ((progress - 0.5) / 0.5).clamp(0.0, 1.0);
        case SankeyAnimation.wave:
          // Per source-stage stagger.
          final start = srcStage / stageCount * 0.6;
          return ((progress - start) / (1 - start)).clamp(0.0, 1.0);
        case SankeyAnimation.grow:
          // Links fade in last.
          return ((progress - 0.6) / 0.4).clamp(0.0, 1.0);
      }
    }

    double nodeProgress(SankeyNode n) {
      final s = stageIndex[n.stage] ?? 0;
      switch (animation) {
        case SankeyAnimation.fade:
          return progress;
        case SankeyAnimation.flow:
          return ((progress - 0.7) / 0.3).clamp(0.0, 1.0);
        case SankeyAnimation.drop:
          return (progress / 0.5).clamp(0.0, 1.0);
        case SankeyAnimation.wave:
          final start = s / stageCount * 0.6;
          return ((progress - start) / (1 - start)).clamp(0.0, 1.0);
        case SankeyAnimation.grow:
          return (progress / 0.6).clamp(0.0, 1.0);
      }
    }

    // ── links ───────────────────────────────────────────────
    for (final i in order) {
      final l = sortedLinks[i];
      final lp = linkProgress(i);
      if (lp <= 0) continue;
      final srcCBase = l.color ?? colorById[l.source]!;
      final tgtCBase = l.color ?? colorById[l.target]!;
      final srcC = srcCBase.withValues(alpha: linkOpacity * lp);
      final tgtC = tgtCBase.withValues(alpha: linkOpacity * lp);
      final bounds = layout.linkPaths[i].getBounds();

      final drawPath = layout.linkPaths[i];
      Shader shader;

      if (animation == SankeyAnimation.flow) {
        // Reveal left-to-right via a hard cutoff in the gradient.
        final cutoff = lp.clamp(0.0, 1.0);
        shader = LinearGradient(
          stops: [0, cutoff, cutoff],
          colors: [srcC, tgtC, Colors.transparent],
        ).createShader(bounds);
      } else {
        shader = LinearGradient(
          colors: [srcC, tgtC],
        ).createShader(bounds);
      }

      canvas.drawPath(drawPath, Paint()..shader = shader);
    }

    // ── nodes ───────────────────────────────────────────────
    for (final n in nodes) {
      final r = layout.nodeRects[n.id];
      if (r == null) continue;
      final np = nodeProgress(n);
      if (np <= 0) continue;
      final c = colorById[n.id]!;
      var drawRect = r;
      var opacity = np;

      if (animation == SankeyAnimation.drop) {
        // Fall from -size.height * 0.15 to final position.
        final dy = -(1 - np) * size.height * 0.15;
        drawRect = r.shift(Offset(0, dy));
      } else if (animation == SankeyAnimation.grow) {
        // Vertical scale from center.
        final cy = r.center.dy;
        final h = r.height * np;
        drawRect = Rect.fromLTWH(r.left, cy - h / 2, r.width, h);
        opacity = 1.0;
      }

      final rr = RRect.fromRectAndRadius(drawRect, const Radius.circular(2));
      canvas.drawRRect(rr, Paint()..color = c.withValues(alpha: opacity));
    }

    // ── labels ──────────────────────────────────────────────
    // Smoother fade: start at 0.55, finish at 1.0 (45% window).
    if (!showLabels && !showValues) return;
    if (progress < 0.55) return;
    final fade = ((progress - 0.55) / 0.45).clamp(0.0, 1.0);
    final eased = Curves.easeOutCubic.transform(fade);
    final baseColor = axisStyle.color ?? const Color(0xFF000000);
    final lblStyle = axisStyle.copyWith(
      color: baseColor.withValues(alpha: eased * 0.92),
      fontWeight: FontWeight.w600,
      shadows: const [],
    );

    for (final n in nodes) {
      final r = layout.nodeRects[n.id];
      if (r == null) continue;
      final inflow = links
          .where((l) => l.target == n.id)
          .fold<double>(0, (s, l) => s + l.value);
      final outflow = links
          .where((l) => l.source == n.id)
          .fold<double>(0, (s, l) => s + l.value);
      final total = inflow > outflow ? inflow : outflow;
      // Count-up: scale displayed value by progress.
      final displayed = total * progress;

      var text = '';
      if (showLabels) text = n.label;
      if (showValues) {
        if (text.isNotEmpty) text += ' · ';
        text += valueFormatter(displayed);
      }

      final placeRight =
          n.stage == firstStage || (n.stage != lastStage && outflow >= inflow);
      final tp = TextPainter(
        text: TextSpan(text: text, style: lblStyle),
        textDirection: TextDirection.ltr,
        maxLines: 1,
      )..layout();
      final y = r.center.dy - tp.height / 2;
      final x = placeRight ? r.right + 6 : r.left - 6 - tp.width;
      tp.paint(canvas, Offset(x, y));
    }
  }

  @override
  bool shouldRepaint(covariant _SankeyPainter old) =>
      old.progress != progress ||
      old.nodes != nodes ||
      old.links != links ||
      old.animation != animation;
}
