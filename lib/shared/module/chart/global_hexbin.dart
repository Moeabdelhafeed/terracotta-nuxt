import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/localization/number_formatter.dart';
import 'chart_data.dart';
import 'chart_internals.dart';
import 'chart_models.dart';
import 'chart_tooltip_overlay.dart';
import 'chart_zoom_pan.dart';
import 'custom_paint_tooltip.dart';

export 'chart_data.dart' show HexPoint;
export 'chart_models.dart' show ChartStyle, HexbinAnimation;

/// Hexbin chart — 2D density via hex tessellation. Each hexagon
/// aggregates the points that fall inside it; cell color is mapped
/// from a sequential gradient by count.
///
/// Better than scatter for thousands of overlapping points: avoids
/// over-plotting and reads as a smooth density field.
///
/// ```dart
/// GlobalHexbin(
///   points: [HexPoint(1.2, 3.4), HexPoint(2.1, 5.6), ...],
///   binSize: 24,
/// )
/// ```
class GlobalHexbin extends StatelessWidget {
  const GlobalHexbin({
    required this.points,
    this.style = ChartStyle.standard,
    this.animation = HexbinAnimation.pop,
    this.binSize = 22,
    this.minColor,
    this.maxColor,
    this.gap = 1.0,
    this.showAxisLabels = true,
    super.key,
  });

  final List<HexPoint> points;
  final ChartStyle style;
  final HexbinAnimation animation;

  /// Hex outer radius in pixels. Smaller = finer grid.
  final double binSize;

  /// Color for the lowest-density bin. Defaults to a faint primary.
  final Color? minColor;

  /// Color for the highest-density bin. Defaults to primary.
  final Color? maxColor;

  /// Pixel gap between adjacent hexagons.
  final double gap;

  final bool showAxisLabels;

  @override
  Widget build(BuildContext context) {
    if (points.isEmpty) return const SizedBox.shrink();
    final palette = resolveSeriesColors(context, style, 1);
    final base = palette.first;
    final lo = minColor ?? base.withValues(alpha: 0.12);
    final hi = maxColor ?? base;
    final axisStyle = resolveAxisLabelStyle(context, style);
    final gridColor = resolveGridColor(context, style);

    return wrapZoomPan(
      Center(
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
                hitTest: (pos, size) => _hitTest(pos, size, hi),
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
                      painter: _HexbinPainter(
                        points: points,
                        binSize: binSize,
                        lo: lo,
                        hi: hi,
                        gap: gap,
                        gridColor: gridColor,
                        axisStyle: axisStyle,
                        showAxisLabels: showAxisLabels,
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

  List<TooltipEntry> _hitTest(Offset pos, Size size, Color hiColor) {
    final layout = _HexLayout.compute(
      points: points,
      size: size,
      binSize: binSize,
    );
    if (layout == null) return const [];
    var bestI = -1;
    var bestDist = double.infinity;
    for (var i = 0; i < layout.cells.length; i++) {
      final d = (layout.cells[i].center - pos).distance;
      if (d < bestDist) {
        bestDist = d;
        bestI = i;
      }
    }
    if (bestI < 0 || bestDist > binSize) return const [];
    final cell = layout.cells[bestI];
    return [
      TooltipEntry(
        label: 'Density',
        value: AppNumbers.compact(cell.weight),
        color: hiColor,
      ),
    ];
  }
}

class _HexCell {
  _HexCell({
    required this.center,
    required this.weight,
    required this.col,
    required this.row,
  });
  final Offset center;
  double weight;
  final int col;
  final int row;
}

class _HexLayout {
  _HexLayout({
    required this.cells,
    required this.maxWeight,
    required this.left,
    required this.right,
    required this.top,
    required this.bottom,
    required this.xMin,
    required this.xMax,
    required this.yMin,
    required this.yMax,
  });

  final List<_HexCell> cells;
  final double maxWeight;
  final double left;
  final double right;
  final double top;
  final double bottom;
  final double xMin;
  final double xMax;
  final double yMin;
  final double yMax;

  static _HexLayout? compute({
    required List<HexPoint> points,
    required Size size,
    required double binSize,
  }) {
    if (size.width <= 0 || size.height <= 0) return null;
    if (points.isEmpty) return null;

    const leftPad = 36.0;
    const rightPad = 12.0;
    const topPad = 16.0;
    const bottomPad = 28.0;
    const left = leftPad;
    final right = size.width - rightPad;
    const top = topPad;
    final bottom = size.height - bottomPad;
    if (right <= left || bottom <= top) return null;

    var xMin = double.infinity;
    var xMax = -double.infinity;
    var yMin = double.infinity;
    var yMax = -double.infinity;
    for (final p in points) {
      if (p.x < xMin) xMin = p.x;
      if (p.x > xMax) xMax = p.x;
      if (p.y < yMin) yMin = p.y;
      if (p.y > yMax) yMax = p.y;
    }
    if (xMax == xMin) xMax = xMin + 1;
    if (yMax == yMin) yMax = yMin + 1;

    // Hex grid geometry — pointy-top hexagons.
    final r = binSize;

    // Map data → pixel.
    Offset toPx(double x, double y) => Offset(
      left + (x - xMin) / (xMax - xMin) * (right - left),
      bottom - (y - yMin) / (yMax - yMin) * (bottom - top),
    );

    // Bin via offset coords (axial). For a pointy-top grid:
    final bins = <int, _HexCell>{};
    for (final p in points) {
      final px = toPx(p.x, p.y);
      // Snap to nearest hex center using `pixel_to_pointy_hex`.
      final q = (math.sqrt(3) / 3 * (px.dx - left) - 1 / 3 * (px.dy - top)) / r;
      final rr = (2 / 3 * (px.dy - top)) / r;
      final rounded = _roundAxial(q, rr);
      final cubeQ = rounded[0];
      final cubeR = rounded[1];
      final cx = left + r * (math.sqrt(3) * cubeQ + math.sqrt(3) / 2 * cubeR);
      final cy = top + r * (3 / 2 * cubeR);
      final key = cubeQ * 10000 + cubeR;
      bins.update(
        key,
        (cell) {
          cell.weight += p.weight;
          return cell;
        },
        ifAbsent: () => _HexCell(
          center: Offset(cx, cy),
          weight: p.weight,
          col: cubeQ,
          row: cubeR,
        ),
      );
    }
    if (bins.isEmpty) return null;
    var maxW = 0.0;
    for (final c in bins.values) {
      if (c.weight > maxW) maxW = c.weight;
    }

    return _HexLayout(
      cells: bins.values.toList(),
      maxWeight: maxW == 0 ? 1 : maxW,
      left: left,
      right: right,
      top: top,
      bottom: bottom,
      xMin: xMin,
      xMax: xMax,
      yMin: yMin,
      yMax: yMax,
    );
  }

  static List<int> _roundAxial(double q, double r) {
    var x = q;
    var z = r;
    var y = -x - z;
    var rx = x.round();
    var ry = y.round();
    var rz = z.round();
    final dx = (rx - x).abs();
    final dy = (ry - y).abs();
    final dz = (rz - z).abs();
    if (dx > dy && dx > dz) {
      rx = -ry - rz;
    } else if (dy > dz) {
      ry = -rx - rz;
    } else {
      rz = -rx - ry;
    }
    return [rx, rz];
  }
}

class _HexbinPainter extends CustomPainter {
  _HexbinPainter({
    required this.points,
    required this.binSize,
    required this.lo,
    required this.hi,
    required this.gap,
    required this.gridColor,
    required this.axisStyle,
    required this.showAxisLabels,
    required this.animation,
    required this.progress,
  });

  final List<HexPoint> points;
  final double binSize;
  final Color lo;
  final Color hi;
  final double gap;
  final Color gridColor;
  final TextStyle axisStyle;
  final bool showAxisLabels;
  final HexbinAnimation animation;
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final layout = _HexLayout.compute(
      points: points,
      size: size,
      binSize: binSize,
    );
    if (layout == null) return;

    // Faint axes at boundaries.
    final guidePaint = Paint()
      ..color = gridColor
      ..strokeWidth = 0.5;
    canvas.drawLine(
      Offset(layout.left, layout.bottom),
      Offset(layout.right, layout.bottom),
      guidePaint,
    );
    canvas.drawLine(
      Offset(layout.left, layout.top),
      Offset(layout.left, layout.bottom),
      guidePaint,
    );

    final r = binSize - gap / 2;

    for (final cell in layout.cells) {
      final density = cell.weight / layout.maxWeight;

      // Stagger heavy cells later for the pop animation.
      final cellDelay = (1 - density) * 0.4;
      final cellT = ((progress - cellDelay) / (1 - cellDelay)).clamp(0.0, 1.0);
      double scale;
      double opacity;
      switch (animation) {
        case HexbinAnimation.pop:
          scale = cellT;
          opacity = 1.0;
        case HexbinAnimation.fade:
          scale = 1.0;
          opacity = progress;
      }

      final color = Color.lerp(lo, hi, density)!.withValues(alpha: opacity);
      final path = _hexPath(cell.center, r * scale);
      canvas.drawPath(path, Paint()..color = color);
    }

    // Axis range labels.
    if (!showAxisLabels) return;
    if (progress < 0.4) return;
    final fadeRaw = ((progress - 0.4) / 0.6).clamp(0.0, 1.0);
    final fade = Curves.easeOutCubic.transform(fadeRaw);
    final lblStyle = axisStyle.copyWith(
      color: axisStyle.color?.withValues(alpha: fade),
    );
    void drawText(String s, Offset at, {bool right = false}) {
      final tp = TextPainter(
        text: TextSpan(text: s, style: lblStyle),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(right ? at.dx - tp.width : at.dx, at.dy));
    }

    drawText(
      AppNumbers.compact(layout.xMin),
      Offset(layout.left, layout.bottom + 4),
    );
    drawText(
      AppNumbers.compact(layout.xMax),
      Offset(layout.right, layout.bottom + 4),
      right: true,
    );
    drawText(
      AppNumbers.compact(layout.yMin),
      Offset(layout.left - 30, layout.bottom - 8),
    );
    drawText(
      AppNumbers.compact(layout.yMax),
      Offset(layout.left - 30, layout.top - 4),
    );
  }

  Path _hexPath(Offset center, double radius) {
    final path = Path();
    for (var i = 0; i < 6; i++) {
      // Pointy-top: angles at 30° + 60°×i.
      final angle = math.pi / 6 + (math.pi / 3) * i;
      final x = center.dx + radius * math.cos(angle);
      final y = center.dy + radius * math.sin(angle);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    return path;
  }

  @override
  bool shouldRepaint(covariant _HexbinPainter old) =>
      old.progress != progress ||
      old.points != points ||
      old.animation != animation ||
      old.binSize != binSize;
}
