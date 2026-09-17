import 'package:flutter/material.dart';

import '../../../core/extensions/theme_colors_extension.dart';
import '../../../core/localization/number_formatter.dart';
import 'chart_data.dart';
import 'chart_internals.dart';
import 'chart_models.dart';
import 'chart_tooltip_overlay.dart';
import 'chart_zoom_pan.dart';
import 'custom_paint_tooltip.dart';

export 'chart_data.dart' show BoxPlotDatum;
export 'chart_models.dart' show ChartStyle;

/// Box plot — quartile-based distribution per category. Each box
/// shows median + Q1/Q3 + whiskers (min/max within 1.5×IQR) + dots
/// for outliers.
///
/// ```dart
/// GlobalBoxPlot(
///   data: [
///     BoxPlotDatum.fromValues(label: 'A', values: [1.2, 3.4, ...]),
///     BoxPlotDatum.fromValues(label: 'B', values: [2.1, 4.0, ...]),
///   ],
/// )
/// ```
class GlobalBoxPlot extends StatelessWidget {
  const GlobalBoxPlot({
    required this.data,
    this.style = ChartStyle.standard,
    this.boxColor,
    this.boxWidth = 32,
    this.whiskerWidth = 14,
    this.medianColor,
    this.outlierColor,
    this.valueFormatter,
    super.key,
  });

  final List<BoxPlotDatum> data;
  final ChartStyle style;

  /// Box fill color. Falls back to theme primary at low alpha.
  final Color? boxColor;

  final double boxWidth;
  final double whiskerWidth;

  /// Median tick color. Falls back to theme primary.
  final Color? medianColor;

  /// Outlier dot color. Falls back to status error.
  final Color? outlierColor;

  final String Function(double)? valueFormatter;

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) return const SizedBox.shrink();

    final box =
        boxColor ?? context.primaryColors.primary.withValues(alpha: 0.2);
    final median = medianColor ?? context.primaryColors.primary;
    final outlier = outlierColor ?? context.statusColors.error;
    final stroke = context.primaryColors.primary;
    final gridColor = resolveGridColor(context, style);
    final axisStyle = resolveAxisLabelStyle(context, style);
    final fmt = valueFormatter ?? (v) => AppNumbers.compact(v);

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
                hitTest: (pos, size) => _hitTest(pos, size, data, box, fmt),
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
                      painter: _BoxPlotPainter(
                        data: data,
                        boxColor: box,
                        strokeColor: stroke,
                        medianColor: median,
                        outlierColor: outlier,
                        gridColor: gridColor,
                        axisStyle: axisStyle,
                        showGrid: style.effectiveShowGrid,
                        showAxes: style.effectiveShowAxisLabels,
                        boxWidth: boxWidth,
                        whiskerWidth: whiskerWidth,
                        valueFormatter: fmt,
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
    List<BoxPlotDatum> data,
    Color color,
    String Function(double) fmt,
  ) {
    const left = 44.0;
    const right_ = 8.0;
    final right = size.width - right_;
    if (pos.dx < left || pos.dx > right) return const [];
    if (pos.dy < 0 || pos.dy > size.height) return const [];
    final n = data.length;
    if (n == 0) return const [];
    final colWidth = (right - left) / n;
    final i = ((pos.dx - left) / colWidth).floor().clamp(0, n - 1);
    final d = data[i];
    return [
      TooltipEntry(
        label: d.label,
        value:
            'med ${fmt(d.median)} · '
            'Q1 ${fmt(d.q1)} · Q3 ${fmt(d.q3)}',
        color: d.color ?? color,
      ),
    ];
  }
}

class _BoxPlotPainter extends CustomPainter {
  _BoxPlotPainter({
    required this.data,
    required this.boxColor,
    required this.strokeColor,
    required this.medianColor,
    required this.outlierColor,
    required this.gridColor,
    required this.axisStyle,
    required this.showGrid,
    required this.showAxes,
    required this.boxWidth,
    required this.whiskerWidth,
    required this.valueFormatter,
    required this.progress,
  });

  final List<BoxPlotDatum> data;
  final Color boxColor;
  final Color strokeColor;
  final Color medianColor;
  final Color outlierColor;
  final Color gridColor;
  final TextStyle axisStyle;
  final bool showGrid;
  final bool showAxes;
  final double boxWidth;
  final double whiskerWidth;
  final String Function(double) valueFormatter;
  final double progress;

  static const _leftPad = 44.0;
  static const _bottomPad = 22.0;
  static const _topPad = 12.0;
  static const _rightPad = 8.0;
  static const _gridLines = 4;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;
    const left = _leftPad;
    final right = size.width - _rightPad;
    const top = _topPad;
    final bottom = size.height - _bottomPad;
    if (right <= left || bottom <= top) return;

    var lo = data.first.min;
    var hi = data.first.max;
    for (final d in data) {
      if (d.min < lo) lo = d.min;
      if (d.max > hi) hi = d.max;
      for (final o in d.outliers) {
        if (o < lo) lo = o;
        if (o > hi) hi = o;
      }
    }
    final pad = (hi - lo) * 0.05;
    lo -= pad;
    hi += pad;
    if (hi == lo) hi = lo + 1;
    double yFor(double v) => bottom - (v - lo) / (hi - lo) * (bottom - top);

    if (showGrid) {
      final gridPaint = Paint()
        ..color = gridColor
        ..strokeWidth = 0.5;
      for (var i = 0; i <= _gridLines; i++) {
        final y = top + (bottom - top) * i / _gridLines;
        canvas.drawLine(Offset(left, y), Offset(right, y), gridPaint);
      }
    }
    if (showAxes) {
      for (var i = 0; i <= _gridLines; i++) {
        final y = top + (bottom - top) * i / _gridLines;
        final value = hi - (hi - lo) * i / _gridLines;
        final tp = TextPainter(
          text: TextSpan(text: valueFormatter(value), style: axisStyle),
          textDirection: TextDirection.ltr,
        )..layout(maxWidth: _leftPad - 4);
        tp.paint(canvas, Offset(left - tp.width - 4, y - tp.height / 2));
      }
    }

    final n = data.length;
    final colWidth = (right - left) / n;
    final medY0 = yFor((lo + hi) / 2);

    for (var i = 0; i < n; i++) {
      final d = data[i];
      final cx = left + colWidth * (i + 0.5);

      // Animate by lerping all y-positions from the median baseline
      // → final y as progress advances.
      double animY(double v) => medY0 + (yFor(v) - medY0) * progress;

      final yMin = animY(d.min);
      final yQ1 = animY(d.q1);
      final yMed = animY(d.median);
      final yQ3 = animY(d.q3);
      final yMax = animY(d.max);

      final stroke = Paint()
        ..color = strokeColor.withValues(alpha: 0.85)
        ..strokeWidth = 1.4
        ..style = PaintingStyle.stroke;

      // Whisker line (min → max).
      canvas.drawLine(Offset(cx, yMin), Offset(cx, yMax), stroke);
      // Whisker caps.
      canvas.drawLine(
        Offset(cx - whiskerWidth / 2, yMax),
        Offset(cx + whiskerWidth / 2, yMax),
        stroke,
      );
      canvas.drawLine(
        Offset(cx - whiskerWidth / 2, yMin),
        Offset(cx + whiskerWidth / 2, yMin),
        stroke,
      );

      // Box (Q1 → Q3).
      final boxRect = Rect.fromLTRB(
        cx - boxWidth / 2,
        yQ3,
        cx + boxWidth / 2,
        yQ1,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(boxRect, const Radius.circular(2)),
        Paint()..color = (d.color ?? boxColor).withValues(alpha: 0.55),
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(boxRect, const Radius.circular(2)),
        stroke,
      );

      // Median tick.
      canvas.drawLine(
        Offset(cx - boxWidth / 2, yMed),
        Offset(cx + boxWidth / 2, yMed),
        Paint()
          ..color = medianColor
          ..strokeWidth = 2,
      );

      // Outlier dots.
      if (progress > 0.7) {
        final outAlpha = ((progress - 0.7) / 0.3).clamp(0.0, 1.0);
        for (final o in d.outliers) {
          canvas.drawCircle(
            Offset(cx, yFor(o)),
            2.5,
            Paint()..color = outlierColor.withValues(alpha: outAlpha),
          );
        }
      }

      if (showAxes) {
        final tp = TextPainter(
          text: TextSpan(text: d.label, style: axisStyle),
          textDirection: TextDirection.ltr,
          maxLines: 1,
        )..layout(maxWidth: colWidth);
        tp.paint(canvas, Offset(cx - tp.width / 2, bottom + 4));
      }
    }
  }

  @override
  bool shouldRepaint(covariant _BoxPlotPainter old) =>
      old.progress != progress ||
      old.data != data ||
      old.boxColor != boxColor ||
      old.strokeColor != strokeColor ||
      old.medianColor != medianColor ||
      old.outlierColor != outlierColor ||
      old.gridColor != gridColor ||
      old.boxWidth != boxWidth ||
      old.whiskerWidth != whiskerWidth ||
      old.showGrid != showGrid ||
      old.showAxes != showAxes;
}
