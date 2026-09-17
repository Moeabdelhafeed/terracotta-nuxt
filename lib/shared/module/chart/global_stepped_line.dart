import 'package:flutter/material.dart';

import 'chart_data.dart';
import 'chart_internals.dart';
import 'chart_legend.dart';
import 'chart_models.dart';
import 'chart_tooltip_overlay.dart';
import 'custom_paint_tooltip.dart';

export 'chart_data.dart' show ChartPoint, ChartSeries;
export 'chart_legend.dart' show ChartLegendEntry;
export 'chart_models.dart' show ChartStyle, SteppedLinePosition;

/// Stepped line chart — discrete-state series rendered with
/// right-angle transitions instead of slopes. Use for server-status
/// timelines, subscription tier history, audit trails, anything
/// where the value holds constant between observations.
///
/// ```dart
/// GlobalSteppedLine(
///   series: [
///     ChartSeries(name: 'Tier', points: [
///       ChartPoint(0, 1), ChartPoint(2, 2), ChartPoint(5, 3),
///     ]),
///   ],
///   stepPosition: SteppedLinePosition.after,
/// )
/// ```
class GlobalSteppedLine extends StatelessWidget {
  const GlobalSteppedLine({
    required this.series,
    this.style = ChartStyle.standard,
    this.stepPosition = SteppedLinePosition.after,
    this.filled = false,
    this.strokeWidth = 2.5,
    this.showDots = true,
    this.dotRadius = 4,
    this.xAxisFormatter,
    this.yAxisFormatter,
    super.key,
  });

  final List<ChartSeries> series;
  final ChartStyle style;
  final SteppedLinePosition stepPosition;
  final bool filled;
  final double strokeWidth;
  final bool showDots;
  final double dotRadius;
  final String Function(double)? xAxisFormatter;
  final String Function(double)? yAxisFormatter;

  @override
  Widget build(BuildContext context) {
    if (series.isEmpty) return const SizedBox.shrink();

    final colors = resolveSeriesColors(context, style, series.length);
    final gridColor = resolveGridColor(context, style);
    final axisStyle = resolveAxisLabelStyle(context, style);
    final xFmt = xAxisFormatter ?? (v) => formatChartNumber(v, style);
    final yFmt = yAxisFormatter ?? (v) => formatChartNumber(v, style);

    final entries = [
      for (var i = 0; i < series.length; i++)
        ChartLegendEntry(
          label: series[i].name,
          color: series[i].color ?? colors[i],
          icon: series[i].icon,
          iconAsset: series[i].iconAsset,
          iconWidget: series[i].iconWidget,
        ),
    ];

    final body = TweenAnimationBuilder<double>(
      tween: Tween(begin: style.enableAnimation ? 0.0 : 1.0, end: 1.0),
      duration: style.enableAnimation
          ? style.effectiveAnimationDuration
          : Duration.zero,
      curve: style.effectiveAnimationCurve,
      builder: (context, t, _) {
        return CustomPaint(
          painter: _SteppedLinePainter(
            series: series,
            colors: colors,
            stepPosition: stepPosition,
            filled: filled,
            strokeWidth: strokeWidth,
            showDots: showDots,
            dotRadius: dotRadius,
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
    );

    final chart = Center(
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
              hitTest: (pos, size) => _hitTest(pos, size, colors, yFmt, xFmt),
              builder: style.tooltipBuilder ?? defaultTooltipBuilder,
              child: body,
            ),
          ),
        ),
      ),
    );

    if (!style.effectiveShowLegend) return chart;
    final legend = ChartLegend(
      entries: entries,
      position: style.legendPosition,
    );
    switch (style.legendPosition) {
      case ChartLegendPosition.top:
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [legend, const SizedBox(height: 8), chart],
        );
      case ChartLegendPosition.bottom:
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [chart, const SizedBox(height: 8), legend],
        );
      case ChartLegendPosition.left:
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            legend,
            const SizedBox(width: 8),
            Flexible(child: chart),
          ],
        );
      case ChartLegendPosition.right:
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(child: chart),
            const SizedBox(width: 8),
            legend,
          ],
        );
      case ChartLegendPosition.hidden:
        return chart;
    }
  }

  /// Find nearest data point across all series at the given local
  /// pointer x. Returns one tooltip entry per series with its value
  /// at that x (interpreted as the active step value).
  List<TooltipEntry> _hitTest(
    Offset pos,
    Size size,
    List<Color> colors,
    String Function(double) yFmt,
    String Function(double) xFmt,
  ) {
    const left = 40.0;
    const right_ = 12.0;
    final right = size.width - right_;
    if (pos.dx < left || pos.dx > right) return const [];

    var xLo = double.infinity;
    var xHi = double.negativeInfinity;
    for (final s in series) {
      for (final p in s.points) {
        if (p.x < xLo) xLo = p.x;
        if (p.x > xHi) xHi = p.x;
      }
    }
    if (xHi == xLo) return const [];
    final hoverX = xLo + (pos.dx - left) / (right - left) * (xHi - xLo);

    final out = <TooltipEntry>[];
    for (var i = 0; i < series.length; i++) {
      final pts = series[i].points;
      if (pts.isEmpty) continue;
      // Find the active step value at hoverX — the y of the latest
      // point whose x is <= hoverX (matches "after" step semantics
      // closely enough for tooltip purposes).
      var active = pts.first;
      for (final p in pts) {
        if (p.x <= hoverX) {
          active = p;
        } else {
          break;
        }
      }
      out.add(
        TooltipEntry(
          label: series[i].name,
          value: '${xFmt(active.x)} · ${yFmt(active.y)}',
          color: series[i].color ?? colors[i],
          icon: series[i].icon,
          iconAsset: series[i].iconAsset,
          iconWidget: series[i].iconWidget,
        ),
      );
    }
    return out;
  }
}

class _SteppedLinePainter extends CustomPainter {
  _SteppedLinePainter({
    required this.series,
    required this.colors,
    required this.stepPosition,
    required this.filled,
    required this.strokeWidth,
    required this.showDots,
    required this.dotRadius,
    required this.gridColor,
    required this.axisStyle,
    required this.showAxes,
    required this.showGrid,
    required this.xFmt,
    required this.yFmt,
    required this.progress,
  });

  final List<ChartSeries> series;
  final List<Color> colors;
  final SteppedLinePosition stepPosition;
  final bool filled;
  final double strokeWidth;
  final bool showDots;
  final double dotRadius;
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
    const left = _leftPad;
    final right = size.width - _rightPad;
    const top = _topPad;
    final bottom = size.height - _bottomPad;
    if (right <= left || bottom <= top) return;

    var xLo = double.infinity;
    var xHi = double.negativeInfinity;
    var yLo = double.infinity;
    var yHi = double.negativeInfinity;
    for (final s in series) {
      for (final p in s.points) {
        if (p.x < xLo) xLo = p.x;
        if (p.x > xHi) xHi = p.x;
        if (p.y < yLo) yLo = p.y;
        if (p.y > yHi) yHi = p.y;
      }
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

    // Build the stepped path per series.
    for (var i = 0; i < series.length; i++) {
      final pts = series[i].points;
      if (pts.length < 2) continue;
      final color = series[i].color ?? colors[i];

      final path = Path();
      final pixelPts = pts
          .map((p) => Offset(xFor(p.x), yFor(p.y)))
          .toList(growable: false);

      path.moveTo(pixelPts.first.dx, pixelPts.first.dy);
      for (var j = 1; j < pixelPts.length; j++) {
        final a = pixelPts[j - 1];
        final b = pixelPts[j];
        switch (stepPosition) {
          case SteppedLinePosition.before:
            path.lineTo(a.dx, b.dy);
            path.lineTo(b.dx, b.dy);
          case SteppedLinePosition.after:
            path.lineTo(b.dx, a.dy);
            path.lineTo(b.dx, b.dy);
          case SteppedLinePosition.center:
            final midX = (a.dx + b.dx) / 2;
            path.lineTo(midX, a.dy);
            path.lineTo(midX, b.dy);
            path.lineTo(b.dx, b.dy);
        }
      }

      // Filled area under the step path.
      if (filled) {
        final fillPath = Path.from(path)
          ..lineTo(pixelPts.last.dx, bottom)
          ..lineTo(pixelPts.first.dx, bottom)
          ..close();
        canvas.save();
        canvas.clipRect(
          Rect.fromLTWH(
            left,
            top,
            (right - left) * progress,
            bottom - top,
          ),
        );
        canvas.drawPath(
          fillPath,
          Paint()..color = color.withValues(alpha: 0.18),
        );
        canvas.restore();
      }

      // Stroke — clip to (left, x_progress) so the line "draws" L→R.
      canvas.save();
      canvas.clipRect(
        Rect.fromLTWH(
          left,
          top,
          (right - left) * progress,
          bottom - top,
        ),
      );
      final strokePaint = Paint()
        ..color = color
        ..strokeWidth = strokeWidth
        ..style = PaintingStyle.stroke
        ..strokeJoin = StrokeJoin.miter
        ..strokeCap = StrokeCap.round
        ..isAntiAlias = true;
      if (series[i].dashed) {
        // Approximate dashing — Flutter has no native dashed stroke
        // for paths. Walk the path and draw dashes per segment.
        _drawDashedPath(canvas, path, strokePaint);
      } else {
        canvas.drawPath(path, strokePaint);
      }
      canvas.restore();

      if (showDots && progress > 0.95) {
        final dotPaint = Paint()..color = color;
        final ringPaint = Paint()
          ..color = Colors.white
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5;
        for (final p in pixelPts) {
          canvas.drawCircle(p, dotRadius, dotPaint);
          canvas.drawCircle(p, dotRadius, ringPaint);
        }
      }
    }
  }

  void _drawDashedPath(Canvas canvas, Path path, Paint paint) {
    const dashOn = 6.0;
    const dashOff = 4.0;
    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      var on = true;
      while (distance < metric.length) {
        final seg = on ? dashOn : dashOff;
        if (on) {
          canvas.drawPath(
            metric.extractPath(distance, distance + seg),
            paint,
          );
        }
        distance += seg;
        on = !on;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _SteppedLinePainter old) =>
      old.progress != progress ||
      old.series != series ||
      old.colors != colors ||
      old.stepPosition != stepPosition ||
      old.filled != filled ||
      old.strokeWidth != strokeWidth ||
      old.showDots != showDots ||
      old.dotRadius != dotRadius ||
      old.gridColor != gridColor ||
      old.showAxes != showAxes ||
      old.showGrid != showGrid;
}
