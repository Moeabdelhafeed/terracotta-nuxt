import 'package:flutter/material.dart';

import '../../../core/extensions/theme_colors_extension.dart';
import '../../../core/localization/number_formatter.dart';
import 'chart_data.dart';
import 'chart_internals.dart';
import 'chart_models.dart';
import 'chart_tooltip_overlay.dart';
import 'chart_zoom_pan.dart';
import 'custom_paint_tooltip.dart';

export 'chart_data.dart' show BandPoint;
export 'chart_models.dart' show ChartStyle, LineChartCurve;

/// Area band chart — filled area between [low] and [high] series at
/// each `x`, with an optional [mid] line through the band's center.
/// Common for confidence intervals, forecast ranges, min/max bands.
///
/// ```dart
/// GlobalAreaBand(
///   points: [
///     BandPoint(x: 0, low: 8, high: 16, mid: 12),
///     BandPoint(x: 1, low: 10, high: 19, mid: 14),
///     ...
///   ],
/// )
/// ```
class GlobalAreaBand extends StatelessWidget {
  const GlobalAreaBand({
    required this.points,
    this.style = ChartStyle.standard,
    this.curve = LineChartCurve.smooth,
    this.bandColor,
    this.bandGradient,
    this.lineColor,
    this.lineWidth = 2,
    this.showBoundLines = true,
    this.boundLineWidth = 1,
    this.xAxisFormatter,
    this.yAxisFormatter,
    super.key,
  });

  final List<BandPoint> points;
  final ChartStyle style;
  final LineChartCurve curve;

  /// Solid band fill. Falls back to primary @ 0.18 alpha.
  final Color? bandColor;

  /// Gradient band fill — wins over [bandColor].
  final Gradient? bandGradient;

  /// Mid-line color. Falls back to primary.
  final Color? lineColor;

  final double lineWidth;

  /// Render thin lines along the upper / lower bounds of the band.
  final bool showBoundLines;
  final double boundLineWidth;

  final String Function(double)? xAxisFormatter;
  final String Function(double)? yAxisFormatter;

  @override
  Widget build(BuildContext context) {
    if (points.isEmpty) return const SizedBox.shrink();

    final primary = context.primaryColors.primary;
    final fill = bandColor ?? primary.withValues(alpha: 0.22);
    final lineC = lineColor ?? primary;
    final boundC = primary.withValues(alpha: 0.6);
    final gridColor = resolveGridColor(context, style);
    final axisStyle = resolveAxisLabelStyle(context, style);
    final xFmt = xAxisFormatter ?? (v) => formatChartNumber(v, style);
    final yFmt = yAxisFormatter ?? (v) => AppNumbers.compact(v);

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
                hitTest: (pos, size) => _hitTest(pos, size, lineC, xFmt, yFmt),
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
                      painter: _AreaBandPainter(
                        points: points,
                        curve: curve,
                        bandColor: fill,
                        bandGradient: bandGradient,
                        boundColor: boundC,
                        lineColor: lineC,
                        lineWidth: lineWidth,
                        showBoundLines: showBoundLines,
                        boundLineWidth: boundLineWidth,
                        gridColor: gridColor,
                        axisStyle: axisStyle,
                        showAxes: style.effectiveShowAxisLabels,
                        showGrid: style.effectiveShowGrid,
                        xFmt: xFmt,
                        yFmt: yFmt,
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
    Color color,
    String Function(double) xFmt,
    String Function(double) yFmt,
  ) {
    const left = 40.0;
    const right_ = 12.0;
    final right = size.width - right_;
    if (pos.dx < left || pos.dx > right) return const [];
    var xLo = double.infinity;
    var xHi = double.negativeInfinity;
    for (final p in points) {
      if (p.x < xLo) xLo = p.x;
      if (p.x > xHi) xHi = p.x;
    }
    if (xHi == xLo) return const [];
    final hoverX = xLo + (pos.dx - left) / (right - left) * (xHi - xLo);
    BandPoint? best;
    var bestDist = double.infinity;
    for (final p in points) {
      final d = (p.x - hoverX).abs();
      if (d < bestDist) {
        bestDist = d;
        best = p;
      }
    }
    if (best == null) return const [];
    final mid = best.mid;
    return [
      TooltipEntry(
        label: xFmt(best.x),
        value: mid != null
            ? '${yFmt(mid)} · band ${yFmt(best.low)}–${yFmt(best.high)}'
            : 'band ${yFmt(best.low)}–${yFmt(best.high)}',
        color: color,
      ),
    ];
  }
}

class _AreaBandPainter extends CustomPainter {
  _AreaBandPainter({
    required this.points,
    required this.curve,
    required this.bandColor,
    required this.bandGradient,
    required this.boundColor,
    required this.lineColor,
    required this.lineWidth,
    required this.showBoundLines,
    required this.boundLineWidth,
    required this.gridColor,
    required this.axisStyle,
    required this.showAxes,
    required this.showGrid,
    required this.xFmt,
    required this.yFmt,
    required this.progress,
  });

  final List<BandPoint> points;
  final LineChartCurve curve;
  final Color bandColor;
  final Gradient? bandGradient;
  final Color boundColor;
  final Color lineColor;
  final double lineWidth;
  final bool showBoundLines;
  final double boundLineWidth;
  final Color gridColor;
  final TextStyle axisStyle;
  final bool showAxes;
  final bool showGrid;
  final String Function(double) xFmt;
  final String Function(double) yFmt;
  final double progress;

  static const _leftPad = 40.0;
  static const _bottomPad = 24.0;
  static const _topPad = 12.0;
  static const _rightPad = 12.0;
  static const _gridLines = 4;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;
    if (points.isEmpty) return;
    const left = _leftPad;
    final right = size.width - _rightPad;
    const top = _topPad;
    final bottom = size.height - _bottomPad;
    if (right <= left || bottom <= top) return;

    var xLo = points.first.x;
    var xHi = points.first.x;
    var yLo = points.first.low;
    var yHi = points.first.high;
    for (final p in points) {
      if (p.x < xLo) xLo = p.x;
      if (p.x > xHi) xHi = p.x;
      if (p.low < yLo) yLo = p.low;
      if (p.high > yHi) yHi = p.high;
    }
    if (xHi == xLo) xHi = xLo + 1;
    if (yHi == yLo) yHi = yLo + 1;
    final yPad = (yHi - yLo) * 0.08;
    yLo -= yPad;
    yHi += yPad;

    double xFor(double x) => left + (x - xLo) / (xHi - xLo) * (right - left);
    double yFor(double y) => bottom - (y - yLo) / (yHi - yLo) * (bottom - top);

    if (showGrid) {
      final paint = Paint()
        ..color = gridColor
        ..strokeWidth = 0.5;
      for (var i = 0; i <= _gridLines; i++) {
        final y = top + (bottom - top) * i / _gridLines;
        canvas.drawLine(Offset(left, y), Offset(right, y), paint);
      }
    }
    if (showAxes) {
      for (var i = 0; i <= _gridLines; i++) {
        final y = top + (bottom - top) * i / _gridLines;
        final value = yHi - (yHi - yLo) * i / _gridLines;
        final tp = TextPainter(
          text: TextSpan(text: yFmt(value), style: axisStyle),
          textDirection: TextDirection.ltr,
        )..layout(maxWidth: _leftPad - 4);
        tp.paint(canvas, Offset(left - tp.width - 4, y - tp.height / 2));
      }
      const xTicks = 5;
      for (var i = 0; i <= xTicks; i++) {
        final x = left + (right - left) * i / xTicks;
        final value = xLo + (xHi - xLo) * i / xTicks;
        final tp = TextPainter(
          text: TextSpan(text: xFmt(value), style: axisStyle),
          textDirection: TextDirection.ltr,
          maxLines: 1,
        )..layout();
        tp.paint(canvas, Offset(x - tp.width / 2, bottom + 4));
      }
    }

    final smooth = curve != LineChartCurve.straight;

    Path buildPath(List<Offset> pts) {
      final path = Path()..moveTo(pts.first.dx, pts.first.dy);
      if (!smooth || pts.length < 3) {
        for (var i = 1; i < pts.length; i++) {
          path.lineTo(pts[i].dx, pts[i].dy);
        }
      } else {
        // Cardinal-ish smooth via cubic-Bezier midpoints.
        for (var i = 1; i < pts.length; i++) {
          final p0 = pts[i - 1];
          final p1 = pts[i];
          final mid = Offset((p0.dx + p1.dx) / 2, (p0.dy + p1.dy) / 2);
          path.quadraticBezierTo(p0.dx, p0.dy, mid.dx, mid.dy);
          if (i == pts.length - 1) {
            path.lineTo(p1.dx, p1.dy);
          }
        }
      }
      return path;
    }

    final highPts = [for (final p in points) Offset(xFor(p.x), yFor(p.high))];
    final lowPts = [for (final p in points) Offset(xFor(p.x), yFor(p.low))];

    // Animate via clip from left → right.
    canvas.save();
    canvas.clipRect(
      Rect.fromLTWH(
        left,
        top,
        (right - left) * progress,
        bottom - top,
      ),
    );

    // Band fill — high path forward, low path reversed, closed.
    final bandPath = buildPath(highPts);
    final lowPath = buildPath(lowPts.reversed.toList());
    bandPath.lineTo(lowPts.last.dx, lowPts.last.dy);
    bandPath.addPath(lowPath, lowPts.last);
    bandPath.close();

    final bandPaint = Paint();
    if (bandGradient != null) {
      bandPaint.shader = bandGradient!.createShader(
        Rect.fromLTRB(left, top, right, bottom),
      );
    } else {
      bandPaint.color = bandColor;
    }
    canvas.drawPath(bandPath, bandPaint);

    if (showBoundLines) {
      final boundPaint = Paint()
        ..color = boundColor
        ..strokeWidth = boundLineWidth
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;
      canvas.drawPath(buildPath(highPts), boundPaint);
      canvas.drawPath(buildPath(lowPts), boundPaint);
    }

    if (points.any((p) => p.mid != null)) {
      final midPts = <Offset>[];
      for (final p in points) {
        if (p.mid != null) midPts.add(Offset(xFor(p.x), yFor(p.mid!)));
      }
      if (midPts.length >= 2) {
        final midPaint = Paint()
          ..color = lineColor
          ..strokeWidth = lineWidth
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round;
        canvas.drawPath(buildPath(midPts), midPaint);
      }
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _AreaBandPainter old) =>
      old.progress != progress ||
      old.points != points ||
      old.curve != curve ||
      old.bandColor != bandColor ||
      old.bandGradient != bandGradient ||
      old.boundColor != boundColor ||
      old.lineColor != lineColor ||
      old.lineWidth != lineWidth ||
      old.showBoundLines != showBoundLines ||
      old.boundLineWidth != boundLineWidth ||
      old.gridColor != gridColor ||
      old.showAxes != showAxes ||
      old.showGrid != showGrid;
}
