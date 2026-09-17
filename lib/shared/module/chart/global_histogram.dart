import 'package:flutter/material.dart';

import '../../../core/extensions/theme_colors_extension.dart';
import '../../../core/localization/number_formatter.dart';
import 'chart_data.dart';
import 'chart_internals.dart';
import 'chart_models.dart';
import 'chart_tooltip_overlay.dart';
import 'chart_zoom_pan.dart';
import 'custom_paint_tooltip.dart';

export 'chart_data.dart' show HistogramBin;
export 'chart_models.dart' show ChartStyle;

/// Histogram — distribution of continuous data into bins. Accepts
/// either pre-binned data via [bins] or raw [values] (auto-binned
/// to [autoBinCount] equal-width bins).
///
/// ```dart
/// // Pre-binned:
/// GlobalHistogram(bins: [
///   HistogramBin(start: 0, end: 10, count: 4),
///   HistogramBin(start: 10, end: 20, count: 12),
///   ...
/// ])
///
/// // Auto-bin from raw values:
/// GlobalHistogram(values: [1.2, 3.4, 5.6, ...], autoBinCount: 12)
/// ```
class GlobalHistogram extends StatelessWidget {
  const GlobalHistogram({
    this.bins,
    this.values,
    this.style = ChartStyle.standard,
    this.autoBinCount = 10,
    this.barColor,
    this.barGradient,
    this.borderRadius = 2,
    this.barPadding = 1,
    this.showValueLabels = false,
    this.binFormatter,
    this.countFormatter,
    super.key,
  }) : assert(
         bins != null || values != null,
         'Provide either `bins` (pre-computed) or `values` (auto-binned).',
       );

  final List<HistogramBin>? bins;
  final List<double>? values;
  final ChartStyle style;
  final int autoBinCount;
  final Color? barColor;
  final Gradient? barGradient;
  final double borderRadius;
  final double barPadding;

  /// Render the count above each bar.
  final bool showValueLabels;

  /// Format the bin range label (`'10–20'`). Defaults to compact
  /// numbers separated by an en-dash.
  final String Function(HistogramBin)? binFormatter;

  /// Format the count text. Defaults to `AppNumbers.integer`.
  final String Function(int)? countFormatter;

  @override
  Widget build(BuildContext context) {
    final resolved = _resolveBins();
    if (resolved.isEmpty) return const SizedBox.shrink();

    final color = barColor ?? context.primaryColors.primary;
    final gridColor = resolveGridColor(context, style);
    final axisStyle = resolveAxisLabelStyle(context, style);

    final binFmt =
        binFormatter ??
        (b) => '${AppNumbers.compact(b.start)}–${AppNumbers.compact(b.end)}';
    final countFmt = countFormatter ?? (c) => AppNumbers.integer(c);

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
                hitTest: (pos, size) =>
                    _hitTest(pos, size, resolved, color, binFmt, countFmt),
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
                      painter: _HistogramPainter(
                        bins: resolved,
                        color: color,
                        gradient: barGradient,
                        gridColor: gridColor,
                        axisStyle: axisStyle,
                        showAxes: style.effectiveShowAxisLabels,
                        showGrid: style.effectiveShowGrid,
                        showValueLabels: showValueLabels,
                        binFormatter: binFmt,
                        countFormatter: countFmt,
                        borderRadius: borderRadius,
                        barPadding: barPadding,
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

  /// Hit-test maps `(localPos, size)` to the bin underneath the
  /// pointer. Mirrors `_HistogramPainter`'s plot-rect math so the
  /// rectangle index lookup stays in sync with the rendered chart.
  List<TooltipEntry> _hitTest(
    Offset pos,
    Size size,
    List<HistogramBin> bins,
    Color color,
    String Function(HistogramBin) binFormatter,
    String Function(int) countFormatter,
  ) {
    const left = 38.0;
    const right_ = 8.0;
    final right = size.width - right_;
    if (pos.dx < left || pos.dx > right) return const [];
    if (pos.dy < 0 || pos.dy > size.height) return const [];
    final n = bins.length;
    if (n == 0) return const [];
    final colWidth = (right - left) / n;
    final i = ((pos.dx - left) / colWidth).floor().clamp(0, n - 1);
    final b = bins[i];
    return [
      TooltipEntry(
        label: binFormatter(b),
        value: countFormatter(b.count),
        color: color,
      ),
    ];
  }

  List<HistogramBin> _resolveBins() {
    if (bins != null && bins!.isNotEmpty) return bins!;
    if (values == null || values!.isEmpty) return const [];
    final n = autoBinCount.clamp(1, 200);
    var lo = values!.first;
    var hi = values!.first;
    for (final v in values!) {
      if (v < lo) lo = v;
      if (v > hi) hi = v;
    }
    if (hi == lo) hi = lo + 1;
    final step = (hi - lo) / n;
    final counts = List.filled(n, 0);
    for (final v in values!) {
      var idx = ((v - lo) / step).floor();
      if (idx >= n) idx = n - 1;
      if (idx < 0) idx = 0;
      counts[idx]++;
    }
    return [
      for (var i = 0; i < n; i++)
        HistogramBin(
          start: lo + i * step,
          end: lo + (i + 1) * step,
          count: counts[i],
        ),
    ];
  }
}

class _HistogramPainter extends CustomPainter {
  _HistogramPainter({
    required this.bins,
    required this.color,
    required this.gradient,
    required this.gridColor,
    required this.axisStyle,
    required this.showAxes,
    required this.showGrid,
    required this.showValueLabels,
    required this.binFormatter,
    required this.countFormatter,
    required this.borderRadius,
    required this.barPadding,
    required this.progress,
  });

  final List<HistogramBin> bins;
  final Color color;
  final Gradient? gradient;
  final Color gridColor;
  final TextStyle axisStyle;
  final bool showAxes;
  final bool showGrid;
  final bool showValueLabels;
  final String Function(HistogramBin) binFormatter;
  final String Function(int) countFormatter;
  final double borderRadius;
  final double barPadding;
  final double progress;

  static const _leftPad = 38.0;
  static const _bottomPad = 22.0;
  static const _topPad = 16.0;
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

    final maxCount = bins.map((b) => b.count).reduce((a, b) => a > b ? a : b);
    if (maxCount <= 0) return;

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
        final value = (maxCount * (1 - i / _gridLines)).round();
        final tp = TextPainter(
          text: TextSpan(text: countFormatter(value), style: axisStyle),
          textDirection: TextDirection.ltr,
        )..layout(maxWidth: _leftPad - 4);
        tp.paint(canvas, Offset(left - tp.width - 4, y - tp.height / 2));
      }
    }

    final n = bins.length;
    final colWidth = (right - left) / n;

    for (var i = 0; i < n; i++) {
      final b = bins[i];
      final h = (b.count / maxCount) * (bottom - top) * progress;
      final cx = left + colWidth * (i + 0.5);
      final barRect = Rect.fromLTWH(
        cx - (colWidth - barPadding * 2) / 2,
        bottom - h,
        colWidth - barPadding * 2,
        h,
      );
      final paint = Paint();
      if (gradient != null) {
        paint.shader = gradient!.createShader(barRect);
      } else {
        paint.color = color;
      }
      canvas.drawRRect(
        RRect.fromRectAndCorners(
          barRect,
          topLeft: Radius.circular(borderRadius),
          topRight: Radius.circular(borderRadius),
        ),
        paint,
      );

      if (showValueLabels && b.count > 0) {
        // Count up + fade in over the second half of progress.
        final countT = ((progress - 0.4) / 0.6).clamp(0.0, 1.0);
        if (countT > 0) {
          final displayCount = (b.count * countT).round();
          final styled = axisStyle.copyWith(
            color: (axisStyle.color ?? Colors.black).withValues(alpha: countT),
          );
          final tp = TextPainter(
            text: TextSpan(text: countFormatter(displayCount), style: styled),
            textDirection: TextDirection.ltr,
            maxLines: 1,
          )..layout();
          tp.paint(
            canvas,
            Offset(cx - tp.width / 2, bottom - h - tp.height - 4),
          );
        }
      }

      if (showAxes && (i % _xTickStep(n) == 0 || i == n - 1)) {
        final label = binFormatter(b);
        final tp = TextPainter(
          text: TextSpan(text: label, style: axisStyle),
          textDirection: TextDirection.ltr,
          maxLines: 1,
        )..layout(maxWidth: colWidth * 1.6);
        tp.paint(canvas, Offset(cx - tp.width / 2, bottom + 4));
      }
    }
  }

  /// Skip every Nth bin label so they don't overlap on dense
  /// histograms.
  int _xTickStep(int n) {
    if (n <= 6) return 1;
    if (n <= 12) return 2;
    if (n <= 24) return 4;
    return (n / 6).ceil();
  }

  @override
  bool shouldRepaint(covariant _HistogramPainter old) =>
      old.progress != progress ||
      old.bins != bins ||
      old.color != color ||
      old.gradient != gradient ||
      old.gridColor != gridColor ||
      old.showAxes != showAxes ||
      old.showGrid != showGrid ||
      old.showValueLabels != showValueLabels ||
      old.borderRadius != borderRadius ||
      old.barPadding != barPadding;
}
