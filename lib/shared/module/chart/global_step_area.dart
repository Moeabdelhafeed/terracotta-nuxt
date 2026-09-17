import 'package:flutter/material.dart';

import '../../../core/localization/number_formatter.dart';
import 'chart_data.dart';
import 'chart_internals.dart';
import 'chart_models.dart';
import 'chart_tooltip_overlay.dart';
import 'chart_zoom_pan.dart';
import 'custom_paint_tooltip.dart';

export 'chart_data.dart' show ChartSeries, ChartPoint;
export 'chart_models.dart' show ChartStyle, StepAreaAnimation;

/// Step area — stepped line + filled area underneath. Each segment
/// holds its y constant until the next x, then jumps. Best for
/// data that's piecewise constant (rate changes, step functions,
/// threshold tiers).
///
/// Multiple series stack on top of each other (no symmetric
/// centering — use streamgraph for that).
///
/// ```dart
/// GlobalStepArea(
///   series: [
///     ChartSeries(name: 'Tier 1', points: [...]),
///   ],
/// )
/// ```
class GlobalStepArea extends StatelessWidget {
  const GlobalStepArea({
    required this.series,
    this.style = ChartStyle.standard,
    this.animation = StepAreaAnimation.draw,
    this.fillOpacity = 0.45,
    this.strokeWidth = 2.0,
    this.stepBefore = false,
    this.showAxisLabels = true,
    this.valueFormatter,
    super.key,
  });

  final List<ChartSeries> series;
  final ChartStyle style;
  final StepAreaAnimation animation;
  final double fillOpacity;
  final double strokeWidth;

  /// When `true`, the y jumps at the START of each x interval
  /// (step-before). Default `false` = step-after.
  final bool stepBefore;

  final bool showAxisLabels;
  final String Function(double)? valueFormatter;

  @override
  Widget build(BuildContext context) {
    if (series.isEmpty) return const SizedBox.shrink();
    final palette = resolveSeriesColors(context, style, series.length);
    final fmt = valueFormatter ?? (v) => AppNumbers.compact(v);
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
                      painter: _StepAreaPainter(
                        series: series,
                        colors: palette,
                        fillOpacity: fillOpacity,
                        strokeWidth: strokeWidth,
                        stepBefore: stepBefore,
                        showAxisLabels: showAxisLabels,
                        gridColor: gridColor,
                        axisStyle: axisStyle,
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
      ),
      style,
    );
  }

  List<TooltipEntry> _hitTest(
    Offset pos,
    Size size,
    List<Color> palette,
    String Function(double) fmt,
  ) {
    final layout = _StepLayout.compute(series: series, size: size);
    if (layout == null) return const [];
    if (pos.dx < layout.left || pos.dx > layout.right) return const [];
    var bestI = -1;
    var bestDy = double.infinity;
    final t = (pos.dx - layout.left) / (layout.right - layout.left);
    for (var si = 0; si < series.length; si++) {
      final pts = series[si].points;
      if (pts.isEmpty) continue;
      final xRange = pts.last.x - pts.first.x;
      if (xRange == 0) continue;
      final x = pts.first.x + t * xRange;
      // Find segment.
      var v = pts.first.y;
      for (var i = 0; i < pts.length; i++) {
        if (pts[i].x <= x) v = pts[i].y;
      }
      final y = layout.yFor(v);
      final d = (y - pos.dy).abs();
      if (d < bestDy) {
        bestDy = d;
        bestI = si;
      }
    }
    if (bestI < 0 || bestDy > 18) return const [];
    final pts = series[bestI].points;
    final xRange = pts.last.x - pts.first.x;
    final x = pts.first.x + t * xRange;
    var v = pts.first.y;
    for (var i = 0; i < pts.length; i++) {
      if (pts[i].x <= x) v = pts[i].y;
    }
    return [
      TooltipEntry(
        label: series[bestI].name,
        value: fmt(v),
        color: series[bestI].color ?? palette[bestI],
      ),
    ];
  }
}

class _StepLayout {
  _StepLayout({
    required this.left,
    required this.right,
    required this.top,
    required this.bottom,
    required this.xMin,
    required this.xMax,
    required this.yMin,
    required this.yMax,
  });

  final double left;
  final double right;
  final double top;
  final double bottom;
  final double xMin;
  final double xMax;
  final double yMin;
  final double yMax;

  double xFor(double v) => left + (v - xMin) / (xMax - xMin) * (right - left);
  double yFor(double v) => bottom - (v - yMin) / (yMax - yMin) * (bottom - top);

  static _StepLayout? compute({
    required List<ChartSeries> series,
    required Size size,
  }) {
    if (size.width <= 0 || size.height <= 0) return null;
    if (series.isEmpty) return null;
    var xLo = double.infinity;
    var xHi = -double.infinity;
    var yLo = double.infinity;
    var yHi = -double.infinity;
    for (final s in series) {
      for (final p in s.points) {
        if (p.x < xLo) xLo = p.x;
        if (p.x > xHi) xHi = p.x;
        if (p.y < yLo) yLo = p.y;
        if (p.y > yHi) yHi = p.y;
      }
    }
    if (xLo == double.infinity) return null;
    if (xHi == xLo) xHi = xLo + 1;
    if (yLo > 0) yLo = 0;
    if (yHi == yLo) yHi = yLo + 1;
    final pad = (yHi - yLo) * 0.08;
    yHi += pad;
    const leftPad = 32.0;
    const rightPad = 12.0;
    const topPad = 16.0;
    const bottomPad = 28.0;
    return _StepLayout(
      left: leftPad,
      right: size.width - rightPad,
      top: topPad,
      bottom: size.height - bottomPad,
      xMin: xLo,
      xMax: xHi,
      yMin: yLo,
      yMax: yHi,
    );
  }
}

class _StepAreaPainter extends CustomPainter {
  _StepAreaPainter({
    required this.series,
    required this.colors,
    required this.fillOpacity,
    required this.strokeWidth,
    required this.stepBefore,
    required this.showAxisLabels,
    required this.gridColor,
    required this.axisStyle,
    required this.animation,
    required this.progress,
    required this.valueFormatter,
  });

  final List<ChartSeries> series;
  final List<Color> colors;
  final double fillOpacity;
  final double strokeWidth;
  final bool stepBefore;
  final bool showAxisLabels;
  final Color gridColor;
  final TextStyle axisStyle;
  final StepAreaAnimation animation;
  final double progress;
  final String Function(double) valueFormatter;

  @override
  void paint(Canvas canvas, Size size) {
    final layout = _StepLayout.compute(series: series, size: size);
    if (layout == null) return;

    canvas.drawLine(
      Offset(layout.left, layout.bottom),
      Offset(layout.right, layout.bottom),
      Paint()
        ..color = gridColor
        ..strokeWidth = 0.5,
    );

    for (var si = 0; si < series.length; si++) {
      final s = series[si];
      if (s.points.isEmpty) continue;
      final c = s.color ?? colors[si];

      var rightCutoff = layout.right;
      var yScale = 1.0;
      var opacity = 1.0;
      switch (animation) {
        case StepAreaAnimation.draw:
          rightCutoff = layout.left + (layout.right - layout.left) * progress;
        case StepAreaAnimation.expand:
          yScale = progress;
        case StepAreaAnimation.fade:
          opacity = progress;
      }

      final fillPath = Path();
      final strokePath = Path();
      var first = true;
      double? prevY;
      double? prevX;

      Offset proj(ChartPoint p) {
        final x = layout.xFor(p.x);
        final yRaw = layout.yFor(p.y);
        final y = layout.bottom - (layout.bottom - yRaw) * yScale;
        return Offset(x, y);
      }

      for (var i = 0; i < s.points.length; i++) {
        final pos = proj(s.points[i]);
        final px = pos.dx;
        final py = pos.dy;
        if (px > rightCutoff) {
          // Cap at cutoff y = current segment y.
          final useY = (stepBefore ? py : prevY ?? py);
          strokePath.lineTo(rightCutoff, useY);
          fillPath.lineTo(rightCutoff, useY);
          break;
        }
        if (first) {
          strokePath.moveTo(px, py);
          fillPath.moveTo(px, layout.bottom);
          fillPath.lineTo(px, py);
          first = false;
        } else {
          if (stepBefore) {
            strokePath.lineTo(prevX!, py);
            strokePath.lineTo(px, py);
            fillPath.lineTo(prevX, py);
            fillPath.lineTo(px, py);
          } else {
            strokePath.lineTo(px, prevY!);
            strokePath.lineTo(px, py);
            fillPath.lineTo(px, prevY);
            fillPath.lineTo(px, py);
          }
        }
        prevX = px;
        prevY = py;
      }
      // Close fill area.
      final closeX = rightCutoff < (prevX ?? layout.right)
          ? rightCutoff
          : (prevX ?? layout.right);
      fillPath.lineTo(closeX, layout.bottom);
      fillPath.close();

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
          ..strokeJoin = StrokeJoin.miter
          ..strokeCap = StrokeCap.butt,
      );
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

    drawText(valueFormatter(layout.yMax), Offset(4, layout.top - 4));
    drawText(valueFormatter(layout.yMin), Offset(4, layout.bottom - 12));
    drawText(
      valueFormatter(layout.xMin),
      Offset(layout.left, layout.bottom + 4),
    );
    drawText(
      valueFormatter(layout.xMax),
      Offset(layout.right, layout.bottom + 4),
      right: true,
    );
  }

  @override
  bool shouldRepaint(covariant _StepAreaPainter old) =>
      old.progress != progress ||
      old.series != series ||
      old.animation != animation ||
      old.stepBefore != stepBefore;
}
