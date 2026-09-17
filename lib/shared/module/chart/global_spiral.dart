import 'dart:math' as math;

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
export 'chart_models.dart' show ChartStyle, SpiralAnimation;

/// Spiral chart — periodic time-series mapped onto an Archimedean
/// spiral. One full turn represents one period (e.g. a year of
/// daily data). Reads the period structure plus long-term trend
/// at a glance.
///
/// Each `ChartPoint.x` is mapped onto the spiral angle (modulo
/// `period`); `ChartPoint.y` controls the bar / line value at
/// that angular position.
///
/// ```dart
/// GlobalSpiral(
///   series: [
///     ChartSeries(name: 'Sales', points: [
///       ChartPoint(0, 12), ChartPoint(1, 14), ...
///     ]),
///   ],
///   period: 365,
/// )
/// ```
class GlobalSpiral extends StatelessWidget {
  const GlobalSpiral({
    required this.series,
    this.style = ChartStyle.standard,
    this.animation = SpiralAnimation.draw,
    this.period = 12,
    this.turns = 3,
    this.barWidth = 4,
    this.barOpacity = 0.85,
    this.startAngle = -math.pi / 2,
    this.startRadius = 0.18,
    this.showAxisLabels = true,
    this.valueFormatter,
    super.key,
  });

  final List<ChartSeries> series;
  final ChartStyle style;
  final SpiralAnimation animation;

  /// Number of x units per full turn. (E.g. `12` for monthly data
  /// over multiple years.)
  final double period;

  /// How many turns the spiral makes total. Determines the
  /// distance between adjacent windings.
  final double turns;

  final double barWidth;
  final double barOpacity;

  /// Angular position of the spiral's start (radians). Defaults
  /// to 12 o'clock.
  final double startAngle;

  /// Inner radius (fraction of the chart's outer radius). 0 =
  /// spiral starts at the center.
  final double startRadius;

  final bool showAxisLabels;
  final String Function(double)? valueFormatter;

  @override
  Widget build(BuildContext context) {
    if (series.isEmpty) return const SizedBox.shrink();
    final palette = resolveSeriesColors(context, style, series.length);
    final fmt = valueFormatter ?? (v) => AppNumbers.compact(v);
    final axisStyle = resolveAxisLabelStyle(context, style);
    final fg = context.textColors.primary;
    final gridColor = resolveGridColor(context, style);

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
                      painter: _SpiralPainter(
                        series: series,
                        colors: palette,
                        period: period,
                        turns: turns,
                        barWidth: barWidth,
                        barOpacity: barOpacity,
                        startAngle: startAngle,
                        startRadius: startRadius,
                        showAxisLabels: showAxisLabels,
                        gridColor: gridColor,
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
    final spiral = _SpiralLayout.compute(
      series: series,
      size: size,
      period: period,
      turns: turns,
      startAngle: startAngle,
      startRadius: startRadius,
    );
    if (spiral == null) return const [];
    var bestI = -1;
    var bestJ = -1;
    var bestDist = double.infinity;
    for (var si = 0; si < series.length; si++) {
      final pts = series[si].points;
      for (var k = 0; k < pts.length; k++) {
        final c = spiral.posFor(pts[k].x);
        final d = (c - pos).distance;
        if (d < bestDist) {
          bestDist = d;
          bestI = si;
          bestJ = k;
        }
      }
    }
    if (bestI < 0 || bestDist > 18) return const [];
    final p = series[bestI].points[bestJ];
    return [
      TooltipEntry(
        label: '${series[bestI].name} · ${fmt(p.x)}',
        value: fmt(p.y),
        color: series[bestI].color ?? palette[bestI],
      ),
    ];
  }
}

class _SpiralLayout {
  _SpiralLayout({
    required this.cx,
    required this.cy,
    required this.r0,
    required this.r1,
    required this.angleStart,
    required this.totalAngle,
    required this.xMin,
    required this.xMax,
    required this.yMin,
    required this.yMax,
  });

  final double cx;
  final double cy;
  final double r0;
  final double r1;
  final double angleStart;
  final double totalAngle;
  final double xMin;
  final double xMax;
  final double yMin;
  final double yMax;

  Offset posFor(double x) {
    final t = (x - xMin) / (xMax - xMin);
    final theta = angleStart + t * totalAngle;
    final r = r0 + (r1 - r0) * t;
    return Offset(cx + r * math.cos(theta), cy + r * math.sin(theta));
  }

  static _SpiralLayout? compute({
    required List<ChartSeries> series,
    required Size size,
    required double period,
    required double turns,
    required double startAngle,
    required double startRadius,
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
    if (yLo == yHi) yHi = yLo + 1;

    final cx = size.width / 2;
    final cy = size.height / 2;
    final outer = math.min(cx, cy) - 32;
    final r0 = outer * startRadius;
    final r1 = outer;
    final totalAngle = math.pi * 2 * turns;
    return _SpiralLayout(
      cx: cx,
      cy: cy,
      r0: r0,
      r1: r1,
      angleStart: startAngle,
      totalAngle: totalAngle,
      xMin: xLo,
      xMax: xHi,
      yMin: yLo,
      yMax: yHi,
    );
  }
}

class _SpiralPainter extends CustomPainter {
  _SpiralPainter({
    required this.series,
    required this.colors,
    required this.period,
    required this.turns,
    required this.barWidth,
    required this.barOpacity,
    required this.startAngle,
    required this.startRadius,
    required this.showAxisLabels,
    required this.gridColor,
    required this.axisStyle,
    required this.fg,
    required this.animation,
    required this.progress,
    required this.valueFormatter,
  });

  final List<ChartSeries> series;
  final List<Color> colors;
  final double period;
  final double turns;
  final double barWidth;
  final double barOpacity;
  final double startAngle;
  final double startRadius;
  final bool showAxisLabels;
  final Color gridColor;
  final TextStyle axisStyle;
  final Color fg;
  final SpiralAnimation animation;
  final double progress;
  final String Function(double) valueFormatter;

  @override
  void paint(Canvas canvas, Size size) {
    final spiral = _SpiralLayout.compute(
      series: series,
      size: size,
      period: period,
      turns: turns,
      startAngle: startAngle,
      startRadius: startRadius,
    );
    if (spiral == null) return;

    // Faint guide spiral.
    final guidePath = Path();
    const steps = 240;
    for (var i = 0; i <= steps; i++) {
      final t = i / steps;
      final theta = spiral.angleStart + t * spiral.totalAngle;
      final r = spiral.r0 + (spiral.r1 - spiral.r0) * t;
      final x = spiral.cx + r * math.cos(theta);
      final y = spiral.cy + r * math.sin(theta);
      if (i == 0) {
        guidePath.moveTo(x, y);
      } else {
        guidePath.lineTo(x, y);
      }
    }
    canvas.drawPath(
      guidePath,
      Paint()
        ..color = gridColor.withValues(alpha: 0.4)
        ..strokeWidth = 0.6
        ..style = PaintingStyle.stroke,
    );

    // Animation phase resolution.
    double drawT;
    double opacity;
    double rotateBy = 0;
    switch (animation) {
      case SpiralAnimation.draw:
        drawT = progress;
        opacity = 1.0;
      case SpiralAnimation.unwind:
        drawT = progress;
        opacity = 1.0;
        rotateBy = (1 - progress) * math.pi;
      case SpiralAnimation.fade:
        drawT = 1.0;
        opacity = progress;
    }
    final cutoffX = spiral.xMin + (spiral.xMax - spiral.xMin) * drawT;

    canvas.save();
    canvas.translate(spiral.cx, spiral.cy);
    canvas.rotate(rotateBy);
    canvas.translate(-spiral.cx, -spiral.cy);

    for (var si = 0; si < series.length; si++) {
      final s = series[si];
      final c = s.color ?? colors[si];

      for (var k = 0; k < s.points.length; k++) {
        final p = s.points[k];
        if (p.x > cutoffX) break;
        final t = (p.x - spiral.xMin) / (spiral.xMax - spiral.xMin);
        final theta = spiral.angleStart + t * spiral.totalAngle;
        final r = spiral.r0 + (spiral.r1 - spiral.r0) * t;
        final yNorm = ((p.y - spiral.yMin) / (spiral.yMax - spiral.yMin)).clamp(
          0.0,
          1.0,
        );
        // Bar grows perpendicular outward by yNorm × turn-spacing.
        final turnSpacing = (spiral.r1 - spiral.r0) / turns * 0.8;
        final outR = r + yNorm * turnSpacing;
        final ix = spiral.cx + r * math.cos(theta);
        final iy = spiral.cy + r * math.sin(theta);
        final ox = spiral.cx + outR * math.cos(theta);
        final oy = spiral.cy + outR * math.sin(theta);
        canvas.drawLine(
          Offset(ix, iy),
          Offset(ox, oy),
          Paint()
            ..color = c.withValues(alpha: barOpacity * opacity)
            ..strokeWidth = barWidth
            ..strokeCap = StrokeCap.round,
        );
      }
    }

    canvas.restore();

    // Axis labels (period markers — every `period` units along the
    // x-axis becomes a tick at a constant angle).
    if (!showAxisLabels) return;
    if (progress < 0.6) return;
    final fadeRaw = ((progress - 0.6) / 0.4).clamp(0.0, 1.0);
    final fade = Curves.easeOutCubic.transform(fadeRaw);
    final lblStyle = axisStyle.copyWith(
      color: fg.withValues(alpha: fade),
      fontWeight: FontWeight.w600,
    );
    // Mark `turns + 1` radial labels at increments of period.
    for (var i = 0; i <= turns.ceil(); i++) {
      final x = spiral.xMin + i * period;
      if (x > spiral.xMax) break;
      final pos = spiral.posFor(x);
      final tp = TextPainter(
        text: TextSpan(text: valueFormatter(x), style: lblStyle),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(
        canvas,
        Offset(pos.dx - tp.width / 2, pos.dy - tp.height - 4),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _SpiralPainter old) =>
      old.progress != progress ||
      old.series != series ||
      old.animation != animation ||
      old.period != period ||
      old.turns != turns;
}
