import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/extensions/theme_colors_extension.dart';
import '../../../core/localization/number_formatter.dart';
import 'chart_data.dart';
import 'chart_internals.dart';
import 'chart_models.dart';
import 'chart_tooltip_overlay.dart';
import 'custom_paint_tooltip.dart';

export 'chart_data.dart' show WaterfallStep, WaterfallType;
export 'chart_models.dart' show ChartStyle;

/// Waterfall chart — sequential additions/subtractions visualized
/// as floating bars with connecting lines. Ideal for P&L breakdowns,
/// budget reconciliation, financial bridges.
///
/// ```dart
/// GlobalWaterfall(
///   steps: [
///     WaterfallStep(label: 'Revenue', value: 100, type: WaterfallType.total),
///     WaterfallStep(label: 'COGS', value: -40, type: WaterfallType.negative),
///     WaterfallStep(label: 'Opex', value: -25, type: WaterfallType.negative),
///     WaterfallStep(label: 'Profit', value: 35, type: WaterfallType.total),
///   ],
/// )
/// ```
class GlobalWaterfall extends StatelessWidget {
  const GlobalWaterfall({
    required this.steps,
    this.style = ChartStyle.standard,
    this.positiveColor,
    this.negativeColor,
    this.totalColor,
    this.barPadding = 4,
    this.showValueLabels = true,
    this.connectors = true,
    this.valueFormatter,
    super.key,
  });

  final List<WaterfallStep> steps;
  final ChartStyle style;
  final Color? positiveColor;
  final Color? negativeColor;
  final Color? totalColor;
  final double barPadding;
  final bool showValueLabels;

  /// Draw thin dashed connector lines between adjacent bars.
  final bool connectors;

  final String Function(double)? valueFormatter;

  @override
  Widget build(BuildContext context) {
    if (steps.isEmpty) return const SizedBox.shrink();

    final positive = positiveColor ?? context.statusColors.success;
    final negative = negativeColor ?? context.statusColors.error;
    final total = totalColor ?? context.primaryColors.primary;
    final gridColor = resolveGridColor(context, style);
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
              hitTest: (pos, size) => _hitTest(
                pos,
                size,
                positive: positive,
                negative: negative,
                total: total,
                fmt: fmt,
              ),
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
                    painter: _WaterfallPainter(
                      steps: steps,
                      positive: positive,
                      negative: negative,
                      total: total,
                      gridColor: gridColor,
                      axisStyle: axisStyle,
                      showAxes: style.effectiveShowAxisLabels,
                      showGrid: style.effectiveShowGrid,
                      showValueLabels: showValueLabels,
                      connectors: connectors,
                      barPadding: barPadding,
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
    );
  }

  /// Hit-test maps `(localPos, size)` to the step underneath the
  /// pointer. Mirrors `_WaterfallPainter`'s plot-rect math.
  List<TooltipEntry> _hitTest(
    Offset pos,
    Size size, {
    required Color positive,
    required Color negative,
    required Color total,
    required String Function(double) fmt,
  }) {
    const left = 44.0;
    const right_ = 8.0;
    final right = size.width - right_;
    if (pos.dx < left || pos.dx > right) return const [];
    if (pos.dy < 0 || pos.dy > size.height) return const [];
    final n = steps.length;
    if (n == 0) return const [];
    final colWidth = (right - left) / n;
    final i = ((pos.dx - left) / colWidth).floor().clamp(0, n - 1);
    final s = steps[i];
    final color =
        s.color ??
        switch (s.type) {
          WaterfallType.positive => positive,
          WaterfallType.negative => negative,
          WaterfallType.total => total,
        };
    final sign = s.type == WaterfallType.negative ? '−' : '';
    return [
      TooltipEntry(
        label: s.label,
        value: '$sign${fmt(s.value.abs())}',
        color: color,
      ),
    ];
  }
}

class _WaterfallPainter extends CustomPainter {
  _WaterfallPainter({
    required this.steps,
    required this.positive,
    required this.negative,
    required this.total,
    required this.gridColor,
    required this.axisStyle,
    required this.showAxes,
    required this.showGrid,
    required this.showValueLabels,
    required this.connectors,
    required this.barPadding,
    required this.valueFormatter,
    required this.progress,
  });

  final List<WaterfallStep> steps;
  final Color positive;
  final Color negative;
  final Color total;
  final Color gridColor;
  final TextStyle axisStyle;
  final bool showAxes;
  final bool showGrid;
  final bool showValueLabels;
  final bool connectors;
  final double barPadding;
  final String Function(double) valueFormatter;
  final double progress;

  static const _leftPad = 44.0;
  static const _bottomPad = 28.0;
  static const _topPad = 24.0;
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

    // Compute running totals to find the y-axis range.
    var running = 0.0;
    final spans = <(double bottomVal, double topVal, Color color)>[];
    for (final s in steps) {
      Color c;
      double a;
      double b;
      switch (s.type) {
        case WaterfallType.total:
          a = 0;
          b = s.value;
          running = s.value;
          c = s.color ?? total;
        case WaterfallType.positive:
          a = running;
          b = running + s.value;
          running = b;
          c = s.color ?? positive;
        case WaterfallType.negative:
          a = running;
          b = running + s.value;
          running = b;
          c = s.color ?? negative;
      }
      spans.add((a < b ? a : b, a > b ? a : b, c));
    }

    // y-axis extent = full span across all bar bottoms / tops + 0.
    var lo = 0.0;
    var hi = 0.0;
    for (final s in spans) {
      if (s.$1 < lo) lo = s.$1;
      if (s.$2 > hi) hi = s.$2;
    }
    if (lo == hi) {
      hi = lo + 1;
    }
    final pad = (hi - lo) * 0.05;
    lo -= pad;
    hi += pad;
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

    final n = steps.length;
    final colWidth = (right - left) / n;
    final connectorPaint = Paint()
      ..color = gridColor.withValues(alpha: 0.6)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    for (var i = 0; i < n; i++) {
      final s = steps[i];
      final span = spans[i];
      final cx = left + colWidth * (i + 0.5);
      final barLeft = cx - (colWidth - barPadding * 2) / 2;
      final barRight = cx + (colWidth - barPadding * 2) / 2;

      // Animate bar height from baseline (y=0 axis) outward.
      final yBaseline = yFor(0);
      final yEnd = yFor(s.type == WaterfallType.total ? s.value : span.$2);
      final yStart = yFor(s.type == WaterfallType.total ? 0 : span.$1);
      final animTop =
          yBaseline + (math.min(yStart, yEnd) - yBaseline) * progress;
      final animBottom =
          yBaseline + (math.max(yStart, yEnd) - yBaseline) * progress;

      final rect = Rect.fromLTRB(barLeft, animTop, barRight, animBottom);
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, const Radius.circular(2)),
        Paint()..color = span.$3,
      );

      if (showValueLabels) {
        // Count up + fade in over the second half of progress.
        final countT = ((progress - 0.5) / 0.5).clamp(0.0, 1.0);
        if (countT > 0) {
          final isNegative = s.type == WaterfallType.negative;
          final displayValue = s.value.abs() * countT;
          final txt = '${isNegative ? '−' : ''}${valueFormatter(displayValue)}';
          final tp = TextPainter(
            text: TextSpan(
              text: txt,
              style: axisStyle.copyWith(
                color: span.$3.withValues(alpha: countT),
                fontWeight: FontWeight.w700,
              ),
            ),
            textDirection: TextDirection.ltr,
            maxLines: 1,
          )..layout();
          tp.paint(
            canvas,
            Offset(cx - tp.width / 2, animTop - tp.height - 4),
          );
        }
      }

      if (showAxes) {
        final tp = TextPainter(
          text: TextSpan(text: s.label, style: axisStyle),
          textDirection: TextDirection.ltr,
          maxLines: 1,
        )..layout(maxWidth: colWidth);
        tp.paint(canvas, Offset(cx - tp.width / 2, bottom + 4));
      }

      // Connector — dashed line from this bar's outer edge to next
      // bar's inner edge at the running total y-level.
      if (connectors && i < n - 1) {
        final next = steps[i + 1];
        final connectY = yFor(
          next.type == WaterfallType.total ? 0 : spans[i].$2,
        );
        // Skip drawing across totals — they reset baseline.
        if (next.type != WaterfallType.total) {
          _drawDashedLine(
            canvas,
            Offset(barRight, connectY),
            Offset(left + colWidth * (i + 1) + barPadding, connectY),
            connectorPaint,
          );
        }
      }
    }
  }

  void _drawDashedLine(Canvas canvas, Offset start, Offset end, Paint paint) {
    const dashOn = 4.0;
    const dashOff = 3.0;
    final dx = end.dx - start.dx;
    final dy = end.dy - start.dy;
    final dist = (dx * dx + dy * dy);
    final total = (dist > 0) ? (dist).toDouble() : 0.0;
    if (total <= 0) return;
    final len = (dx.abs() + dy.abs()); // axis-aligned use case
    var painted = 0.0;
    var on = true;
    while (painted < len) {
      final seg = on ? dashOn : dashOff;
      final t0 = painted / len;
      final t1 = (painted + seg).clamp(0.0, len) / len;
      if (on) {
        canvas.drawLine(
          Offset(start.dx + dx * t0, start.dy + dy * t0),
          Offset(start.dx + dx * t1, start.dy + dy * t1),
          paint,
        );
      }
      painted += seg;
      on = !on;
    }
  }

  @override
  bool shouldRepaint(covariant _WaterfallPainter old) =>
      old.progress != progress ||
      old.steps != steps ||
      old.positive != positive ||
      old.negative != negative ||
      old.total != total ||
      old.gridColor != gridColor ||
      old.showAxes != showAxes ||
      old.showGrid != showGrid ||
      old.showValueLabels != showValueLabels ||
      old.connectors != connectors ||
      old.barPadding != barPadding;
}
