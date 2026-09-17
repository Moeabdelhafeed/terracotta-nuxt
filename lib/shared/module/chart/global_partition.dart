import 'package:flutter/material.dart';

import '../../../core/extensions/theme_colors_extension.dart';
import '../../../core/localization/number_formatter.dart';
import 'chart_data.dart';
import 'chart_internals.dart';
import 'chart_models.dart';
import 'chart_tooltip_overlay.dart';
import 'custom_paint_tooltip.dart';

export 'chart_data.dart' show TreemapNode;
export 'chart_models.dart' show ChartStyle, PartitionAnimation, PartitionLayout;

/// Partition chart — covers icicle + treemap-style hierarchical
/// space-filling layouts in one widget. Reuses [TreemapNode] for
/// input. The chosen [PartitionLayout] dictates packing:
///
/// - `squarified` — aspect-ratio aware treemap (default)
/// - `sliceAndDice` — alternating horizontal / vertical splits
/// - `icicleTopDown` — flat icicle stacked downward
/// - `icicleLeftRight` — flat icicle stacked rightward
class GlobalPartition extends StatelessWidget {
  const GlobalPartition({
    required this.root,
    this.style = ChartStyle.standard,
    this.layout = PartitionLayout.squarified,
    this.animation = PartitionAnimation.grow,
    this.gap = 1.0,
    this.showLabels = true,
    this.showValues = false,
    this.minLabelArea = 800,
    this.valueFormatter,
    super.key,
  });

  final TreemapNode root;
  final ChartStyle style;
  final PartitionLayout layout;
  final PartitionAnimation animation;
  final double gap;
  final bool showLabels;
  final bool showValues;

  /// Skip labels for cells whose pixel area is smaller than this.
  final double minLabelArea;

  final String Function(double)? valueFormatter;

  @override
  Widget build(BuildContext context) {
    if (root.children.isEmpty) return const SizedBox.shrink();
    final palette = resolveSeriesColors(
      context,
      style,
      root.children.length.clamp(1, 12),
    );
    final fmt = valueFormatter ?? (v) => AppNumbers.compact(v);
    final axisStyle = resolveAxisLabelStyle(context, style);
    final fg = context.textColors.primary;

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
              hitTest: (pos, size) => _hitTest(pos, size, palette, fmt),
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
                    painter: _PartitionPainter(
                      root: root,
                      palette: palette,
                      layoutMode: layout,
                      gap: gap,
                      showLabels: showLabels,
                      showValues: showValues,
                      minLabelArea: minLabelArea,
                      axisStyle: axisStyle,
                      fg: fg,
                      animation: animation,
                      progress: t,
                      valueFormatter: fmt,
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
    String Function(double) fmt,
  ) {
    final cells = _PartitionLayoutResult.compute(
      root: root,
      bounds: Rect.fromLTWH(0, 0, size.width, size.height),
      mode: layout,
      gap: gap,
    );
    if (cells == null) return const [];
    for (var i = cells.cells.length - 1; i >= 0; i--) {
      final c = cells.cells[i];
      if (c.rect.contains(pos)) {
        return [
          TooltipEntry(
            label: c.node.label,
            value: fmt(c.node.totalValue),
            color: c.color,
          ),
        ];
      }
    }
    return const [];
  }
}

class _PartitionCell {
  _PartitionCell({
    required this.node,
    required this.rect,
    required this.depth,
    required this.color,
  });

  final TreemapNode node;
  final Rect rect;
  final int depth;
  final Color color;
}

class _PartitionLayoutResult {
  _PartitionLayoutResult({
    required this.cells,
    required this.maxDepth,
  });

  final List<_PartitionCell> cells;
  final int maxDepth;

  static _PartitionLayoutResult? compute({
    required TreemapNode root,
    required Rect bounds,
    required PartitionLayout mode,
    required double gap,
  }) {
    if (bounds.width <= 0 || bounds.height <= 0) return null;
    if (root.children.isEmpty) return null;
    final cells = <_PartitionCell>[];

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

    switch (mode) {
      case PartitionLayout.squarified:
        _layoutSquarified(root, bounds, 0, cells, gap);
      case PartitionLayout.sliceAndDice:
        _layoutSliceAndDice(root, bounds, 0, cells, gap, true);
      case PartitionLayout.icicleTopDown:
        _layoutIcicle(root, bounds, 0, maxDepth, cells, gap, true);
      case PartitionLayout.icicleLeftRight:
        _layoutIcicle(root, bounds, 0, maxDepth, cells, gap, false);
    }

    return _PartitionLayoutResult(cells: cells, maxDepth: maxDepth);
  }

  // ── squarified ──────────────────────────────────────────
  static void _layoutSquarified(
    TreemapNode parent,
    Rect rect,
    int depth,
    List<_PartitionCell> out,
    double gap,
  ) {
    if (parent.children.isEmpty) return;
    final children = [...parent.children]
      ..sort((a, b) => b.totalValue.compareTo(a.totalValue));
    final total = children.fold<double>(0, (s, c) => s + c.totalValue);
    if (total <= 0) return;
    var cur = rect;
    final row = <TreemapNode>[];
    var rowSum = 0.0;

    while (children.isNotEmpty) {
      final next = children.first;
      final candidate = [...row, next];
      final candSum = rowSum + next.totalValue;
      if (row.isEmpty ||
          _worst(candidate, candSum, cur, total) <=
              _worst(row, rowSum, cur, total)) {
        row.add(next);
        rowSum += next.totalValue;
        children.removeAt(0);
      } else {
        cur = _placeRow(row, rowSum, cur, total, depth, out, parent, gap);
        row.clear();
        rowSum = 0;
      }
    }
    if (row.isNotEmpty) {
      cur = _placeRow(row, rowSum, cur, total, depth, out, parent, gap);
    }
  }

  static double _worst(
    List<TreemapNode> row,
    double sum,
    Rect rect,
    double total,
  ) {
    if (row.isEmpty) return double.infinity;
    final w = rect.shortestSide;
    final s = sum;
    var rMin = double.infinity;
    var rMax = -double.infinity;
    for (final n in row) {
      if (n.totalValue < rMin) rMin = n.totalValue;
      if (n.totalValue > rMax) rMax = n.totalValue;
    }
    final wSq = w * w;
    final sSq = s * s == 0 ? 1 : s * s;
    return [
      wSq * rMax / sSq,
      sSq / (wSq * rMin),
    ].reduce((a, b) => a > b ? a : b);
  }

  static Rect _placeRow(
    List<TreemapNode> row,
    double rowSum,
    Rect rect,
    double parentSum,
    int depth,
    List<_PartitionCell> out,
    TreemapNode parent,
    double gap,
  ) {
    final horizontal = rect.width >= rect.height;
    final rowFraction = rowSum / parentSum;
    if (horizontal) {
      final rowH = rect.height * rowFraction;
      var x = rect.left;
      for (final n in row) {
        final w = (n.totalValue / rowSum) * rect.width;
        final cellRect = Rect.fromLTWH(
          x + gap / 2,
          rect.top + gap / 2,
          w - gap,
          rowH - gap,
        );
        if (cellRect.width > 0 && cellRect.height > 0) {
          out.add(
            _PartitionCell(
              node: n,
              rect: cellRect,
              depth: depth,
              color: n.color ?? const Color(0xFF6453D8),
            ),
          );
          // Recurse for children if any.
          if (n.children.isNotEmpty) {
            _layoutSquarified(n, cellRect, depth + 1, out, gap);
          }
        }
        x += w;
      }
      return Rect.fromLTWH(
        rect.left,
        rect.top + rowH,
        rect.width,
        rect.height - rowH,
      );
    } else {
      final rowW = rect.width * rowFraction;
      var y = rect.top;
      for (final n in row) {
        final h = (n.totalValue / rowSum) * rect.height;
        final cellRect = Rect.fromLTWH(
          rect.left + gap / 2,
          y + gap / 2,
          rowW - gap,
          h - gap,
        );
        if (cellRect.width > 0 && cellRect.height > 0) {
          out.add(
            _PartitionCell(
              node: n,
              rect: cellRect,
              depth: depth,
              color: n.color ?? const Color(0xFF6453D8),
            ),
          );
          if (n.children.isNotEmpty) {
            _layoutSquarified(n, cellRect, depth + 1, out, gap);
          }
        }
        y += h;
      }
      return Rect.fromLTWH(
        rect.left + rowW,
        rect.top,
        rect.width - rowW,
        rect.height,
      );
    }
  }

  // ── slice and dice ──────────────────────────────────────
  static void _layoutSliceAndDice(
    TreemapNode parent,
    Rect rect,
    int depth,
    List<_PartitionCell> out,
    double gap,
    bool horizontalFirst,
  ) {
    if (parent.children.isEmpty) return;
    final total = parent.children.fold<double>(0, (s, c) => s + c.totalValue);
    if (total <= 0) return;
    final horizontal = (depth % 2 == 0) ? horizontalFirst : !horizontalFirst;
    var cursor = horizontal ? rect.left : rect.top;
    for (final c in parent.children) {
      final frac = c.totalValue / total;
      Rect cell;
      if (horizontal) {
        final w = rect.width * frac;
        cell = Rect.fromLTWH(
          cursor + gap / 2,
          rect.top + gap / 2,
          w - gap,
          rect.height - gap,
        );
        cursor += w;
      } else {
        final h = rect.height * frac;
        cell = Rect.fromLTWH(
          rect.left + gap / 2,
          cursor + gap / 2,
          rect.width - gap,
          h - gap,
        );
        cursor += h;
      }
      if (cell.width > 0 && cell.height > 0) {
        out.add(
          _PartitionCell(
            node: c,
            rect: cell,
            depth: depth,
            color: c.color ?? const Color(0xFF6453D8),
          ),
        );
        if (c.children.isNotEmpty) {
          _layoutSliceAndDice(c, cell, depth + 1, out, gap, horizontalFirst);
        }
      }
    }
  }

  // ── icicle ──────────────────────────────────────────────
  static void _layoutIcicle(
    TreemapNode parent,
    Rect rect,
    int depth,
    int maxDepth,
    List<_PartitionCell> out,
    double gap,
    bool topDown,
  ) {
    if (parent.children.isEmpty) return;
    final total = parent.children.fold<double>(0, (s, c) => s + c.totalValue);
    if (total <= 0) return;
    final layerThickness = topDown
        ? rect.height / maxDepth
        : rect.width / maxDepth;
    final layerOffset = topDown
        ? rect.top + depth * layerThickness
        : rect.left + depth * layerThickness;
    var cursor = topDown ? rect.left : rect.top;
    for (final c in parent.children) {
      final frac = c.totalValue / total;
      Rect cell;
      if (topDown) {
        final w = rect.width * frac;
        cell = Rect.fromLTWH(
          cursor + gap / 2,
          layerOffset + gap / 2,
          w - gap,
          layerThickness - gap,
        );
        cursor += w;
      } else {
        final h = rect.height * frac;
        cell = Rect.fromLTWH(
          layerOffset + gap / 2,
          cursor + gap / 2,
          layerThickness - gap,
          h - gap,
        );
        cursor += h;
      }
      if (cell.width > 0 && cell.height > 0) {
        out.add(
          _PartitionCell(
            node: c,
            rect: cell,
            depth: depth,
            color: c.color ?? const Color(0xFF6453D8),
          ),
        );
        if (c.children.isNotEmpty) {
          // Pass child's slice rect (across full layer dim).
          final childRect = topDown
              ? Rect.fromLTWH(
                  cell.left - gap / 2,
                  rect.top,
                  cell.width + gap,
                  rect.height,
                )
              : Rect.fromLTWH(
                  rect.left,
                  cell.top - gap / 2,
                  rect.width,
                  cell.height + gap,
                );
          _layoutIcicle(c, childRect, depth + 1, maxDepth, out, gap, topDown);
        }
      }
    }
  }
}

class _PartitionPainter extends CustomPainter {
  _PartitionPainter({
    required this.root,
    required this.palette,
    required this.layoutMode,
    required this.gap,
    required this.showLabels,
    required this.showValues,
    required this.minLabelArea,
    required this.axisStyle,
    required this.fg,
    required this.animation,
    required this.progress,
    required this.valueFormatter,
  });

  final TreemapNode root;
  final List<Color> palette;
  final PartitionLayout layoutMode;
  final double gap;
  final bool showLabels;
  final bool showValues;
  final double minLabelArea;
  final TextStyle axisStyle;
  final Color fg;
  final PartitionAnimation animation;
  final double progress;
  final String Function(double) valueFormatter;

  @override
  void paint(Canvas canvas, Size size) {
    final result = _PartitionLayoutResult.compute(
      root: root,
      bounds: Rect.fromLTWH(0, 0, size.width, size.height),
      mode: layoutMode,
      gap: gap,
    );
    if (result == null) return;

    for (var i = 0; i < result.cells.length; i++) {
      final c = result.cells[i];
      // Cell color: top-level ancestor's palette color, then lerp.
      final topAncestor = _topAncestor(c.node);
      final topIdx = root.children.indexOf(topAncestor);
      final base = topIdx >= 0
          ? palette[topIdx % palette.length]
          : palette.first;
      final color = c.depth == 0
          ? base
          : Color.lerp(base, Colors.white, c.depth * 0.12)!;

      double opacity;
      var drawRect = c.rect;
      switch (animation) {
        case PartitionAnimation.fade:
          opacity = progress;
        case PartitionAnimation.cascade:
          final start = c.depth / (result.maxDepth + 1);
          opacity = ((progress - start) / (1 - start)).clamp(0.0, 1.0);
        case PartitionAnimation.grow:
          // Cells grow outward from centroid.
          final centerX = c.rect.center.dx;
          final centerY = c.rect.center.dy;
          final w = c.rect.width * progress;
          final h = c.rect.height * progress;
          drawRect = Rect.fromCenter(
            center: Offset(centerX, centerY),
            width: w,
            height: h,
          );
          opacity = 1.0;
      }
      if (opacity <= 0) continue;

      canvas.drawRRect(
        RRect.fromRectAndRadius(drawRect, const Radius.circular(2)),
        Paint()..color = color.withValues(alpha: opacity),
      );

      // Label.
      if (!showLabels && !showValues) continue;
      if (drawRect.width * drawRect.height < minLabelArea) continue;
      if (progress < 0.55) continue;
      final fadeRaw = ((progress - 0.55) / 0.45).clamp(0.0, 1.0);
      final fade = Curves.easeOutCubic.transform(fadeRaw);
      final lblColor = _labelColorFor(color).withValues(alpha: fade);
      final text = StringBuffer();
      if (showLabels) text.write(c.node.label);
      if (showValues) {
        if (text.isNotEmpty) text.write('\n');
        text.write(valueFormatter(c.node.totalValue));
      }
      final tp = TextPainter(
        text: TextSpan(
          text: text.toString(),
          style: axisStyle.copyWith(
            color: lblColor,
            fontWeight: FontWeight.w600,
            shadows: const [],
          ),
        ),
        textDirection: TextDirection.ltr,
        textAlign: TextAlign.center,
        maxLines: 2,
        ellipsis: '…',
      )..layout(maxWidth: drawRect.width - 6);
      if (tp.height > drawRect.height - 4) continue;
      tp.paint(
        canvas,
        Offset(
          drawRect.center.dx - tp.width / 2,
          drawRect.center.dy - tp.height / 2,
        ),
      );
    }
  }

  TreemapNode _topAncestor(TreemapNode n) {
    // Walk top-level children for membership; if `n` is deeper,
    // we approximate by checking if n itself is a top-level child.
    // For correct walks we'd need parent refs; this works because
    // top-level children are searched directly.
    if (root.children.contains(n)) return n;
    for (final c in root.children) {
      if (_contains(c, n)) return c;
    }
    return n;
  }

  bool _contains(TreemapNode subtree, TreemapNode target) {
    if (subtree == target) return true;
    for (final c in subtree.children) {
      if (_contains(c, target)) return true;
    }
    return false;
  }

  Color _labelColorFor(Color bg) {
    final lum = bg.computeLuminance();
    return lum > 0.55 ? const Color(0xFF1A1A1A) : const Color(0xFFEDEDED);
  }

  @override
  bool shouldRepaint(covariant _PartitionPainter old) =>
      old.progress != progress ||
      old.root != root ||
      old.layoutMode != layoutMode ||
      old.animation != animation;
}
