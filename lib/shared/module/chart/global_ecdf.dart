import 'package:flutter/material.dart';

import '../../../core/localization/number_formatter.dart';
import 'chart_data.dart';
import 'chart_internals.dart';
import 'chart_models.dart';
import 'chart_tooltip_overlay.dart';
import 'chart_zoom_pan.dart';
import 'custom_paint_tooltip.dart';

export 'chart_data.dart' show ViolinDatum;
export 'chart_models.dart' show ChartStyle, EcdfAnimation;

/// Empirical cumulative distribution function. For each unique
/// sorted value `x` in a series, plots `P(X ≤ x) = rank/N` as a
/// step function. Multiple series overlay so distributions can be
/// compared directly.
///
/// Reuses [ViolinDatum] for input. Smoother than histograms;
/// reads quantiles + tail behaviour at a glance.
///
/// ```dart
/// GlobalEcdf(
///   data: [
///     ViolinDatum(label: 'Sample', values: [1.2, 1.4, ...]),
///   ],
/// )
/// ```
class GlobalEcdf extends StatelessWidget {
  const GlobalEcdf({
    required this.data,
    this.style = ChartStyle.standard,
    this.animation = EcdfAnimation.draw,
    this.smooth = false,
    this.lineWidth = 2.0,
    this.fillOpacity = 0.0,
    this.showAxisLabels = true,
    this.showQuartiles = false,
    this.valueFormatter,
    super.key,
  });

  final List<ViolinDatum> data;
  final ChartStyle style;
  final EcdfAnimation animation;

  /// Cubic interpolation between sample points instead of strict
  /// step function. Default `false` (statistically correct steps).
  final bool smooth;

  final double lineWidth;

  /// Optional fill below the curve (0 = no fill, classic ECDF look).
  final double fillOpacity;

  final bool showAxisLabels;

  /// Render quartile markers (Q1, median, Q3) as horizontal lines
  /// across the curve.
  final bool showQuartiles;

  final String Function(double)? valueFormatter;

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) return const SizedBox.shrink();
    final palette = resolveSeriesColors(context, style, data.length);
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
                      painter: _EcdfPainter(
                        data: data,
                        colors: palette,
                        smooth: smooth,
                        lineWidth: lineWidth,
                        fillOpacity: fillOpacity,
                        showAxisLabels: showAxisLabels,
                        showQuartiles: showQuartiles,
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
    final layout = _EcdfLayout.compute(data: data, size: size);
    if (layout == null) return const [];
    if (pos.dx < layout.left || pos.dx > layout.right) return const [];
    var bestI = -1;
    var bestDy = double.infinity;
    final t = (pos.dx - layout.left) / (layout.right - layout.left);
    final x = layout.gMin + t * (layout.gMax - layout.gMin);
    for (var si = 0; si < data.length; si++) {
      final values = layout.sorted[si];
      if (values.isEmpty) continue;
      // Compute P(X ≤ x) = (count of values ≤ x) / n.
      var cnt = 0;
      for (final v in values) {
        if (v <= x) cnt++;
      }
      final p = cnt / values.length;
      final y = layout.bottom - p * (layout.bottom - layout.top);
      final d = (y - pos.dy).abs();
      if (d < bestDy) {
        bestDy = d;
        bestI = si;
      }
    }
    if (bestI < 0 || bestDy > 18) return const [];
    final values = layout.sorted[bestI];
    var cnt = 0;
    for (final v in values) {
      if (v <= x) cnt++;
    }
    final p = cnt / values.length;
    return [
      TooltipEntry(
        label: data[bestI].label,
        value: 'P(X ≤ ${fmt(x)}) = ${(p * 100).toStringAsFixed(1)}%',
        color: data[bestI].color ?? palette[bestI],
      ),
    ];
  }
}

class _EcdfLayout {
  _EcdfLayout({
    required this.sorted,
    required this.left,
    required this.right,
    required this.top,
    required this.bottom,
    required this.gMin,
    required this.gMax,
  });

  final List<List<double>> sorted;
  final double left;
  final double right;
  final double top;
  final double bottom;
  final double gMin;
  final double gMax;

  static _EcdfLayout? compute({
    required List<ViolinDatum> data,
    required Size size,
  }) {
    if (size.width <= 0 || size.height <= 0) return null;
    if (data.isEmpty) return null;
    final sorted = <List<double>>[];
    var gMin = double.infinity;
    var gMax = -double.infinity;
    for (final d in data) {
      if (d.values.isEmpty) {
        sorted.add([]);
        continue;
      }
      final s = [...d.values]..sort();
      sorted.add(s);
      if (s.first < gMin) gMin = s.first;
      if (s.last > gMax) gMax = s.last;
    }
    if (gMin == double.infinity) return null;
    if (gMax == gMin) gMax = gMin + 1;
    final pad = (gMax - gMin) * 0.05;
    gMin -= pad;
    gMax += pad;
    const leftPad = 36.0;
    const rightPad = 16.0;
    const topPad = 16.0;
    const bottomPad = 28.0;
    return _EcdfLayout(
      sorted: sorted,
      left: leftPad,
      right: size.width - rightPad,
      top: topPad,
      bottom: size.height - bottomPad,
      gMin: gMin,
      gMax: gMax,
    );
  }
}

class _EcdfPainter extends CustomPainter {
  _EcdfPainter({
    required this.data,
    required this.colors,
    required this.smooth,
    required this.lineWidth,
    required this.fillOpacity,
    required this.showAxisLabels,
    required this.showQuartiles,
    required this.gridColor,
    required this.axisStyle,
    required this.animation,
    required this.progress,
    required this.valueFormatter,
  });

  final List<ViolinDatum> data;
  final List<Color> colors;
  final bool smooth;
  final double lineWidth;
  final double fillOpacity;
  final bool showAxisLabels;
  final bool showQuartiles;
  final Color gridColor;
  final TextStyle axisStyle;
  final EcdfAnimation animation;
  final double progress;
  final String Function(double) valueFormatter;

  @override
  void paint(Canvas canvas, Size size) {
    final layout = _EcdfLayout.compute(data: data, size: size);
    if (layout == null) return;

    final guidePaint = Paint()
      ..color = gridColor
      ..strokeWidth = 0.5;
    canvas.drawLine(
      Offset(layout.left, layout.bottom),
      Offset(layout.right, layout.bottom),
      guidePaint,
    );
    // Horizontal guide at P=1.
    canvas.drawLine(
      Offset(layout.left, layout.top),
      Offset(layout.right, layout.top),
      Paint()
        ..color = gridColor.withValues(alpha: 0.5)
        ..strokeWidth = 0.5,
    );
    // P=0.5 reference.
    final yMid = layout.bottom - 0.5 * (layout.bottom - layout.top);
    canvas.drawLine(
      Offset(layout.left, yMid),
      Offset(layout.right, yMid),
      Paint()
        ..color = gridColor.withValues(alpha: 0.3)
        ..strokeWidth = 0.5,
    );

    double xFor(double v) {
      return layout.left +
          (v - layout.gMin) /
              (layout.gMax - layout.gMin) *
              (layout.right - layout.left);
    }

    double yFor(double p) {
      return layout.bottom - p * (layout.bottom - layout.top);
    }

    for (var si = 0; si < data.length; si++) {
      final values = layout.sorted[si];
      if (values.isEmpty) continue;
      final n = values.length;
      final c = data[si].color ?? colors[si];

      var rightCutoff = layout.right;
      var yScale = 1.0;
      var opacity = 1.0;
      switch (animation) {
        case EcdfAnimation.draw:
          rightCutoff = layout.left + (layout.right - layout.left) * progress;
        case EcdfAnimation.rise:
          yScale = progress;
        case EcdfAnimation.fade:
          opacity = progress;
      }

      final strokePath = Path();
      final fillPath = Path();
      var first = true;
      double? prevX;
      double? prevY;
      for (var i = 0; i < n; i++) {
        final v = values[i];
        final x = xFor(v);
        final pBefore = i / n;
        final pAfter = (i + 1) / n;
        final yBefore =
            layout.bottom - (layout.bottom - yFor(pBefore)) * yScale;
        final yAfter = layout.bottom - (layout.bottom - yFor(pAfter)) * yScale;
        if (x > rightCutoff) {
          // Cap at cutoff at last y level.
          if (!first) {
            strokePath.lineTo(rightCutoff, prevY!);
            fillPath.lineTo(rightCutoff, prevY);
          }
          break;
        }
        if (first) {
          // Start at (xFirst, P=0 from baseline).
          strokePath.moveTo(layout.left, layout.bottom);
          strokePath.lineTo(x, layout.bottom);
          fillPath.moveTo(layout.left, layout.bottom);
          fillPath.lineTo(x, layout.bottom);
          first = false;
        }
        if (smooth) {
          // Smooth from prev to current step's mid.
          if (prevX != null && prevY != null) {
            final cx = (prevX + x) / 2;
            strokePath.cubicTo(cx, prevY, cx, yAfter, x, yAfter);
            fillPath.cubicTo(cx, prevY, cx, yAfter, x, yAfter);
          } else {
            strokePath.lineTo(x, yAfter);
            fillPath.lineTo(x, yAfter);
          }
        } else {
          // Strict step: rise vertically at x to yAfter.
          strokePath.lineTo(x, yBefore);
          strokePath.lineTo(x, yAfter);
          fillPath.lineTo(x, yBefore);
          fillPath.lineTo(x, yAfter);
        }
        prevX = x;
        prevY = yAfter;
      }
      // Extend to right cutoff at P=1 if drawing finished.
      if (rightCutoff > (prevX ?? 0) && prevY != null) {
        strokePath.lineTo(rightCutoff, prevY);
        fillPath.lineTo(rightCutoff, prevY);
      }
      // Close fill.
      fillPath.lineTo(rightCutoff, layout.bottom);
      fillPath.close();

      if (fillOpacity > 0) {
        canvas.drawPath(
          fillPath,
          Paint()..color = c.withValues(alpha: fillOpacity * opacity),
        );
      }
      canvas.drawPath(
        strokePath,
        Paint()
          ..color = c.withValues(alpha: opacity)
          ..strokeWidth = lineWidth
          ..style = PaintingStyle.stroke
          ..strokeJoin = StrokeJoin.round
          ..strokeCap = StrokeCap.round,
      );

      // Quartile markers.
      if (showQuartiles && progress > 0.7) {
        final fade = ((progress - 0.7) / 0.3).clamp(0.0, 1.0);
        for (final p in [0.25, 0.5, 0.75]) {
          final idx = ((n - 1) * p).clamp(0, n - 1).toDouble();
          final a = idx.floor();
          final b = idx.ceil();
          final qv = values[a] + (values[b] - values[a]) * (idx - a);
          final qx = xFor(qv);
          if (qx > rightCutoff) continue;
          final qy = yFor(p);
          canvas.drawLine(
            Offset(layout.left, qy),
            Offset(qx, qy),
            Paint()
              ..color = c.withValues(alpha: 0.4 * fade)
              ..strokeWidth = 0.8,
          );
          canvas.drawLine(
            Offset(qx, qy),
            Offset(qx, layout.bottom),
            Paint()
              ..color = c.withValues(alpha: 0.4 * fade)
              ..strokeWidth = 0.8,
          );
          canvas.drawCircle(
            Offset(qx, qy),
            3,
            Paint()..color = c.withValues(alpha: fade),
          );
        }
      }
    }

    // Legend (top-left) when multiple series.
    if (data.length > 1 && progress > 0.4) {
      final fadeRaw = ((progress - 0.4) / 0.6).clamp(0.0, 1.0);
      final fade = Curves.easeOutCubic.transform(fadeRaw);
      var ly = layout.top + 6;
      for (var si = 0; si < data.length; si++) {
        final c = (data[si].color ?? colors[si]).withValues(alpha: fade);
        canvas.drawCircle(
          Offset(layout.left + 8, ly + 6),
          4,
          Paint()..color = c,
        );
        final tp = TextPainter(
          text: TextSpan(
            text: data[si].label,
            style: axisStyle.copyWith(
              color: axisStyle.color?.withValues(alpha: fade),
              fontWeight: FontWeight.w600,
            ),
          ),
          textDirection: TextDirection.ltr,
        )..layout();
        tp.paint(canvas, Offset(layout.left + 18, ly));
        ly += 16;
      }
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
      valueFormatter(layout.gMin),
      Offset(layout.left, layout.bottom + 4),
    );
    drawText(
      valueFormatter(layout.gMax),
      Offset(layout.right, layout.bottom + 4),
      right: true,
    );
    drawText('1.0', Offset(4, layout.top - 4));
    drawText('0.0', Offset(4, layout.bottom - 12));
  }

  @override
  bool shouldRepaint(covariant _EcdfPainter old) =>
      old.progress != progress ||
      old.data != data ||
      old.animation != animation ||
      old.smooth != smooth ||
      old.showQuartiles != showQuartiles;
}
