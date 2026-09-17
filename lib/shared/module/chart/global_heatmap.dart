import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/extensions/theme_colors_extension.dart';
import 'chart_data.dart';
import 'chart_internals.dart';
import 'chart_models.dart';
import 'chart_zoom_pan.dart';

export 'chart_data.dart' show HeatmapCell;
export 'chart_models.dart' show ChartStyle, HeatmapAnimation;

/// 2D heatmap. Each cell's color lerps along [colorRamp] based on
/// its value within `[min, max]`. Useful for calendar activity views,
/// correlation matrices, density grids.
///
/// Built on Flutter `CustomPaint` (graphic's `HeatmapShape` doesn't
/// expose per-cell margin) so [cellPadding] visibly separates cells
/// and per-cell entrance animations are possible.
///
/// ```dart
/// GlobalHeatmap(
///   cells: [
///     HeatmapCell(x: 'Mon', y: '09:00', value: 4),
///     HeatmapCell(x: 'Mon', y: '10:00', value: 12),
///     ...
///   ],
/// )
/// ```
class GlobalHeatmap extends StatelessWidget {
  const GlobalHeatmap({
    required this.cells,
    this.style = ChartStyle.standard,
    this.colorRamp,
    this.cellPadding = 2,
    this.cellRadius = 4,
    this.animation = HeatmapAnimation.fade,
    super.key,
  });

  final List<HeatmapCell> cells;
  final ChartStyle style;

  /// 2+ colors lerped across the value range. When null, uses a
  /// theme-aware ramp from `outlineVariant` → `primary`.
  final List<Color>? colorRamp;

  /// Gap between cells in dp.
  final double cellPadding;

  /// Corner radius per cell in dp.
  final double cellRadius;

  final HeatmapAnimation animation;

  @override
  Widget build(BuildContext context) {
    if (cells.isEmpty) return const SizedBox.shrink();

    // Preserve insertion order for axis categories — first time we
    // see each x / y label sets its position on the axis.
    final xLabels = <String>[];
    final yLabels = <String>[];
    for (final c in cells) {
      if (!xLabels.contains(c.x)) xLabels.add(c.x);
      if (!yLabels.contains(c.y)) yLabels.add(c.y);
    }

    final ramp =
        colorRamp ??
        [
          context.backgroundColors.outlineVariant,
          context.primaryColors.primary,
        ];

    final values = cells.map((c) => c.value).toList(growable: false);
    final vMin = values.reduce((a, b) => a < b ? a : b);
    final vMax = values.reduce((a, b) => a > b ? a : b);

    final axisStyle = resolveAxisLabelStyle(context, style);

    final useAnimation =
        style.enableAnimation && animation != HeatmapAnimation.none;

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
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: useAnimation ? 0.0 : 1.0, end: 1.0),
                duration: useAnimation
                    ? style.effectiveAnimationDuration
                    : Duration.zero,
                curve: style.effectiveAnimationCurve,
                builder: (context, t, _) {
                  return CustomPaint(
                    painter: _HeatmapPainter(
                      cells: cells,
                      xLabels: xLabels,
                      yLabels: yLabels,
                      ramp: ramp,
                      vMin: vMin,
                      vMax: vMax,
                      cellPadding: cellPadding,
                      cellRadius: cellRadius,
                      axisStyle: axisStyle,
                      showAxes: style.effectiveShowAxisLabels,
                      progress: t,
                      animation: animation,
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
      style,
    );
  }
}

class _HeatmapPainter extends CustomPainter {
  _HeatmapPainter({
    required this.cells,
    required this.xLabels,
    required this.yLabels,
    required this.ramp,
    required this.vMin,
    required this.vMax,
    required this.cellPadding,
    required this.cellRadius,
    required this.axisStyle,
    required this.showAxes,
    required this.progress,
    required this.animation,
  });

  final List<HeatmapCell> cells;
  final List<String> xLabels;
  final List<String> yLabels;
  final List<Color> ramp;
  final double vMin;
  final double vMax;
  final double cellPadding;
  final double cellRadius;
  final TextStyle axisStyle;
  final bool showAxes;
  final double progress;
  final HeatmapAnimation animation;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;
    if (xLabels.isEmpty || yLabels.isEmpty) return;

    // Reserve gutters for axis labels.
    final leftGutter = showAxes ? _measureMaxWidth(yLabels) + 8 : 0.0;
    final bottomGutter = showAxes ? axisStyle.fontSize! + 12 : 0.0;

    final plotLeft = leftGutter;
    const plotTop = 0.0;
    final plotRight = size.width;
    final plotBottom = size.height - bottomGutter;
    final plotW = plotRight - plotLeft;
    final plotH = plotBottom - plotTop;
    if (plotW <= 0 || plotH <= 0) return;

    final cellW = plotW / xLabels.length;
    final cellH = plotH / yLabels.length;

    // Paint cells. Per-cell stagger animates differently based on
    // [animation] mode.
    final cx = (xLabels.length - 1) / 2;
    final cy = (yLabels.length - 1) / 2;
    final maxRadial = math.sqrt(cx * cx + cy * cy);

    for (final c in cells) {
      final xi = xLabels.indexOf(c.x);
      final yi = yLabels.indexOf(c.y);
      if (xi < 0 || yi < 0) continue;

      final delay = switch (animation) {
        HeatmapAnimation.fade => 0.0,
        HeatmapAnimation.none => 0.0,
        HeatmapAnimation.popIn =>
          (xi + yi) /
              ((xLabels.length + yLabels.length).clamp(1, double.infinity)),
        HeatmapAnimation.waveIn =>
          xi / xLabels.length.clamp(1, double.infinity),
        HeatmapAnimation.bloomOut =>
          (math.sqrt(math.pow(xi - cx, 2) + math.pow(yi - cy, 2)) /
              maxRadial.clamp(0.0001, double.infinity)),
      };

      // Each cell has a 0.6-wide active window in the global timeline.
      // Stagger pushes the window's start later for cells that should
      // appear afterwards.
      final localT = ((progress - delay * 0.4) / 0.6).clamp(0.0, 1.0);
      if (localT <= 0) continue;

      final t = (c.value - vMin) / (vMax - vMin == 0 ? 1 : vMax - vMin);
      final color = _lerpRamp(ramp, t);

      final left = plotLeft + xi * cellW + cellPadding / 2;
      final top = plotTop + yi * cellH + cellPadding / 2;
      final w = cellW - cellPadding;
      final h = cellH - cellPadding;
      if (w <= 0 || h <= 0) continue;

      switch (animation) {
        case HeatmapAnimation.popIn:
          // Scale cell 0→1 about its center.
          final scale = Curves.easeOutBack.transform(localT);
          final scaledW = w * scale;
          final scaledH = h * scale;
          final dx = left + (w - scaledW) / 2;
          final dy = top + (h - scaledH) / 2;
          _paintCell(
            canvas,
            Rect.fromLTWH(dx, dy, scaledW, scaledH),
            color.withValues(alpha: color.a * scale),
          );
        case HeatmapAnimation.fade:
        case HeatmapAnimation.waveIn:
        case HeatmapAnimation.bloomOut:
        case HeatmapAnimation.none:
          _paintCell(
            canvas,
            Rect.fromLTWH(left, top, w, h),
            color.withValues(alpha: color.a * localT),
          );
      }
    }

    if (showAxes) {
      _paintAxes(
        canvas,
        plotLeft: plotLeft,
        plotBottom: plotBottom,
        cellW: cellW,
        cellH: cellH,
      );
    }
  }

  void _paintCell(Canvas canvas, Rect rect, Color color) {
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, Radius.circular(cellRadius)),
      Paint()..color = color,
    );
  }

  void _paintAxes(
    Canvas canvas, {
    required double plotLeft,
    required double plotBottom,
    required double cellW,
    required double cellH,
  }) {
    // Y labels on the left.
    for (var i = 0; i < yLabels.length; i++) {
      final tp = TextPainter(
        text: TextSpan(text: yLabels[i], style: axisStyle),
        textDirection: TextDirection.ltr,
      )..layout(maxWidth: plotLeft - 4);
      tp.paint(
        canvas,
        Offset(plotLeft - tp.width - 4, i * cellH + (cellH - tp.height) / 2),
      );
    }

    // X labels along the bottom.
    for (var i = 0; i < xLabels.length; i++) {
      final tp = TextPainter(
        text: TextSpan(text: xLabels[i], style: axisStyle),
        textDirection: TextDirection.ltr,
        textAlign: TextAlign.center,
      )..layout(maxWidth: cellW);
      tp.paint(
        canvas,
        Offset(plotLeft + i * cellW + (cellW - tp.width) / 2, plotBottom + 6),
      );
    }
  }

  double _measureMaxWidth(List<String> labels) {
    var max = 0.0;
    for (final s in labels) {
      final tp = TextPainter(
        text: TextSpan(text: s, style: axisStyle),
        textDirection: TextDirection.ltr,
      )..layout();
      if (tp.width > max) max = tp.width;
    }
    return max;
  }

  /// Lerp through an N-color ramp. `t` in `[0, 1]`.
  Color _lerpRamp(List<Color> ramp, double t) {
    final clamped = t.clamp(0.0, 1.0);
    if (ramp.length == 1) return ramp.first;
    final scaled = clamped * (ramp.length - 1);
    final lo = scaled.floor().clamp(0, ramp.length - 1);
    final hi = (lo + 1).clamp(0, ramp.length - 1);
    final local = scaled - lo;
    return Color.lerp(ramp[lo], ramp[hi], local) ?? ramp[lo];
  }

  @override
  bool shouldRepaint(covariant _HeatmapPainter old) =>
      old.progress != progress ||
      old.cells != cells ||
      old.ramp != ramp ||
      old.cellPadding != cellPadding ||
      old.cellRadius != cellRadius ||
      old.showAxes != showAxes ||
      old.animation != animation;
}
