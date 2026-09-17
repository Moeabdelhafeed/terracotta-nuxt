import 'package:flutter/material.dart';

import '../../../core/extensions/theme_colors_extension.dart';
import '../../../core/localization/number_formatter.dart';
import 'chart_data.dart';
import 'chart_internals.dart';
import 'chart_models.dart';
import 'chart_tooltip_overlay.dart';
import 'chart_zoom_pan.dart';
import 'custom_paint_tooltip.dart';

export 'chart_data.dart' show ChartSeries, ChartPoint;
export 'chart_models.dart' show ChartStyle, RidgelineAnimation;

/// Ridgeline / joy plot — N curves stacked vertically, one row per
/// series. Each row has its own baseline; curves grow upward (and
/// can overlap into the row above for the classic ridgeline look).
///
/// Best for comparing distributions or trends across many groups
/// in compact space — usage-by-day-of-week per region, latency per
/// route, etc.
///
/// ```dart
/// GlobalRidgeline(
///   series: [
///     ChartSeries(name: 'Mon', points: [...]),
///     ChartSeries(name: 'Tue', points: [...]),
///   ],
///   overlap: 0.4,
/// )
/// ```
class GlobalRidgeline extends StatelessWidget {
  const GlobalRidgeline({
    required this.series,
    this.style = ChartStyle.standard,
    this.animation = RidgelineAnimation.rise,
    this.smooth = true,
    this.overlap = 0.35,
    this.fillOpacity = 0.7,
    this.strokeWidth = 1.6,
    this.showLabels = true,
    this.valueFormatter,
    super.key,
  });

  final List<ChartSeries> series;
  final ChartStyle style;
  final RidgelineAnimation animation;

  /// Cubic interpolation between data points.
  final bool smooth;

  /// Fraction of one row's height that overlaps the next row up.
  /// 0 = no overlap (clean strips); 0.5 = curves bleed half a row up.
  final double overlap;

  final double fillOpacity;
  final double strokeWidth;
  final bool showLabels;
  final String Function(double)? valueFormatter;

  @override
  Widget build(BuildContext context) {
    if (series.isEmpty) return const SizedBox.shrink();
    final palette = resolveSeriesColors(context, style, series.length);
    final fmt = valueFormatter ?? (v) => AppNumbers.compact(v);
    final axisStyle = resolveAxisLabelStyle(context, style);
    final gridColor = resolveGridColor(context, style);
    final bg = context.backgroundColors.cardBackground;

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
                      painter: _RidgelinePainter(
                        series: series,
                        colors: palette,
                        smooth: smooth,
                        overlap: overlap,
                        fillOpacity: fillOpacity,
                        strokeWidth: strokeWidth,
                        showLabels: showLabels,
                        gridColor: gridColor,
                        backgroundColor: bg,
                        axisStyle: axisStyle,
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

  List<TooltipEntry> _hitTest(
    Offset pos,
    Size size,
    List<Color> colors,
    String Function(double) fmt,
  ) {
    final layout = _RidgeLayout.compute(
      series: series,
      size: size,
      overlap: overlap,
    );
    if (layout == null) return const [];
    if (pos.dx < layout.left || pos.dx > layout.right) return const [];

    final t = (pos.dx - layout.left) / (layout.right - layout.left);
    var bestI = -1;
    var bestDist = double.infinity;
    for (var i = 0; i < series.length; i++) {
      final cy = layout.rowBaselines[i];
      final dy = (cy - pos.dy).abs();
      if (dy < bestDist) {
        bestDist = dy;
        bestI = i;
      }
    }
    if (bestI < 0 || bestDist > layout.rowH) return const [];

    final pts = [...series[bestI].points]..sort((a, b) => a.x.compareTo(b.x));
    if (pts.isEmpty) return const [];
    final xMin = pts.first.x;
    final xMax = pts.last.x;
    if (xMax == xMin) return const [];
    final x = xMin + (xMax - xMin) * t;
    final v = _interp(pts, x);
    return [
      TooltipEntry(
        label: series[bestI].name,
        value: fmt(v),
        color: series[bestI].color ?? colors[bestI],
      ),
    ];
  }

  static double _interp(List<ChartPoint> pts, double x) {
    if (x <= pts.first.x) return pts.first.y;
    if (x >= pts.last.x) return pts.last.y;
    for (var i = 1; i < pts.length; i++) {
      if (pts[i].x >= x) {
        final p0 = pts[i - 1];
        final p1 = pts[i];
        final t = (x - p0.x) / (p1.x - p0.x);
        return p0.y + (p1.y - p0.y) * t;
      }
    }
    return pts.last.y;
  }
}

class _RidgeLayout {
  _RidgeLayout({
    required this.rowBaselines,
    required this.rowH,
    required this.rowExtent,
    required this.left,
    required this.right,
    required this.top,
    required this.bottom,
    required this.xMin,
    required this.xMax,
  });

  final List<double> rowBaselines;
  final double rowH;
  final double rowExtent;
  final double left;
  final double right;
  final double top;
  final double bottom;
  final double xMin;
  final double xMax;

  static _RidgeLayout? compute({
    required List<ChartSeries> series,
    required Size size,
    required double overlap,
  }) {
    if (size.width <= 0 || size.height <= 0) return null;
    if (series.isEmpty) return null;

    const leftPad = 70.0;
    const rightPad = 12.0;
    const topPad = 8.0;
    const bottomPad = 8.0;
    const left = leftPad;
    final right = size.width - rightPad;
    const top = topPad;
    final bottom = size.height - bottomPad;

    final rows = series.length;
    final rowH = (bottom - top) / rows;
    final rowExtent = rowH * (1 + overlap);
    final baselines = <double>[];
    for (var i = 0; i < rows; i++) {
      baselines.add(top + rowH * (i + 0.5) + rowH / 2);
    }

    var xMin = double.infinity;
    var xMax = -double.infinity;
    for (final s in series) {
      for (final p in s.points) {
        if (p.x < xMin) xMin = p.x;
        if (p.x > xMax) xMax = p.x;
      }
    }
    if (xMin == double.infinity || xMax == -double.infinity) return null;
    if (xMax == xMin) xMax = xMin + 1;

    return _RidgeLayout(
      rowBaselines: baselines,
      rowH: rowH,
      rowExtent: rowExtent,
      left: left,
      right: right,
      top: top,
      bottom: bottom,
      xMin: xMin,
      xMax: xMax,
    );
  }
}

class _RidgelinePainter extends CustomPainter {
  _RidgelinePainter({
    required this.series,
    required this.colors,
    required this.smooth,
    required this.overlap,
    required this.fillOpacity,
    required this.strokeWidth,
    required this.showLabels,
    required this.gridColor,
    required this.backgroundColor,
    required this.axisStyle,
    required this.animation,
    required this.progress,
  });

  final List<ChartSeries> series;
  final List<Color> colors;
  final bool smooth;
  final double overlap;
  final double fillOpacity;
  final double strokeWidth;
  final bool showLabels;
  final Color gridColor;
  final Color backgroundColor;
  final TextStyle axisStyle;
  final RidgelineAnimation animation;
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final layout = _RidgeLayout.compute(
      series: series,
      size: size,
      overlap: overlap,
    );
    if (layout == null) return;

    // Per-series y-range relative to its own peak.
    final peaks = <double>[];
    for (final s in series) {
      var p = 0.0;
      for (final pt in s.points) {
        if (pt.y > p) p = pt.y;
      }
      peaks.add(p == 0 ? 1 : p);
    }

    // Paint top → bottom so each row's peak (which extends UP into
    // the row above) lands ON TOP of the previous row — the layered
    // joy-plot effect. The fillPath bg-clears its own region so the
    // overlap displays solid color, not translucent against neighbor.
    for (var i = 0; i < series.length; i++) {
      final s = series[i];
      final base = layout.rowBaselines[i];
      final peak = peaks[i];
      final c = s.color ?? colors[i];

      // Stagger per row for non-fade animations.
      final rowDelay = i / series.length * 0.25;
      final rowT = ((progress - rowDelay) / (1 - rowDelay)).clamp(0.0, 1.0);

      var rightCutoff = layout.right;
      var scaleY = 1.0;
      var opacity = 1.0;

      switch (animation) {
        case RidgelineAnimation.rise:
          scaleY = rowT;
        case RidgelineAnimation.draw:
          rightCutoff = layout.left + (layout.right - layout.left) * rowT;
        case RidgelineAnimation.fade:
          opacity = progress;
      }

      final pts = [...s.points]..sort((a, b) => a.x.compareTo(b.x));
      if (pts.isEmpty) continue;

      final fillPath = Path();
      final strokePath = Path();
      var first = true;
      for (var k = 0; k < pts.length; k++) {
        final p = pts[k];
        final tx = (p.x - layout.xMin) / (layout.xMax - layout.xMin);
        final x = layout.left + (layout.right - layout.left) * tx;
        if (x > rightCutoff) {
          if (!first && k > 0) {
            // Interp at cutoff.
            final prev = pts[k - 1];
            final px =
                layout.left +
                (layout.right - layout.left) *
                    (prev.x - layout.xMin) /
                    (layout.xMax - layout.xMin);
            final tInterp = (rightCutoff - px) / (x - px);
            final yInterp = (prev.y + (p.y - prev.y) * tInterp).clamp(
              0.0,
              peak,
            );
            final norm = yInterp / peak;
            final yPx = base - norm * layout.rowExtent * scaleY;
            strokePath.lineTo(rightCutoff, yPx);
            fillPath.lineTo(rightCutoff, yPx);
          }
          break;
        }
        final norm = (p.y / peak).clamp(0.0, 1.0);
        final y = base - norm * layout.rowExtent * scaleY;
        if (first) {
          fillPath.moveTo(x, base);
          fillPath.lineTo(x, y);
          strokePath.moveTo(x, y);
          first = false;
        } else {
          if (smooth && k >= 1) {
            final prev = pts[k - 1];
            final pxNorm = (prev.x - layout.xMin) / (layout.xMax - layout.xMin);
            final px = layout.left + (layout.right - layout.left) * pxNorm;
            final pyNorm = (prev.y / peak).clamp(0.0, 1.0);
            final py = base - pyNorm * layout.rowExtent * scaleY;
            final cx1 = (px + x) / 2;
            strokePath.cubicTo(cx1, py, cx1, y, x, y);
            fillPath.cubicTo(cx1, py, cx1, y, x, y);
          } else {
            strokePath.lineTo(x, y);
            fillPath.lineTo(x, y);
          }
        }
      }
      // Close fill back to baseline.
      fillPath.lineTo(rightCutoff, base);
      fillPath.close();

      // Background fill clears overlap from row above so peaks
      // don't muddle visually.
      canvas.drawPath(
        fillPath,
        Paint()..color = backgroundColor.withValues(alpha: opacity),
      );
      canvas.drawPath(
        fillPath,
        Paint()..color = c.withValues(alpha: fillOpacity * opacity),
      );
      canvas.drawPath(
        strokePath,
        Paint()
          ..color = c.withValues(alpha: opacity)
          ..strokeWidth = strokeWidth
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round,
      );

      // Row label.
      if (showLabels && progress > 0.4) {
        final fadeRaw = ((progress - 0.4) / 0.6).clamp(0.0, 1.0);
        final fade = Curves.easeOutCubic.transform(fadeRaw);
        final tp = TextPainter(
          text: TextSpan(
            text: s.name,
            style: axisStyle.copyWith(
              color: axisStyle.color?.withValues(alpha: fade),
              fontWeight: FontWeight.w600,
            ),
          ),
          textDirection: TextDirection.ltr,
          maxLines: 1,
          ellipsis: '…',
        )..layout(maxWidth: layout.left - 8);
        tp.paint(
          canvas,
          Offset(layout.left - 8 - tp.width, base - tp.height / 2),
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _RidgelinePainter old) =>
      old.progress != progress ||
      old.series != series ||
      old.animation != animation ||
      old.smooth != smooth ||
      old.overlap != overlap;
}
