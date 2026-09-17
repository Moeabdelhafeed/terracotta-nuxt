import 'package:flutter/material.dart';

import '../../../core/localization/number_formatter.dart';
import 'chart_data.dart';
import 'chart_internals.dart';
import 'chart_models.dart';
import 'chart_tooltip_overlay.dart';
import 'chart_zoom_pan.dart';
import 'custom_paint_tooltip.dart';

export 'chart_data.dart' show ChartPoint;
export 'chart_models.dart' show ChartStyle, MarginalHistogramAnimation;

/// Marginal histogram — scatter plot with histograms drawn on the
/// top (x-distribution) and right (y-distribution) margins. Reads
/// the joint distribution of two variables plus their marginals
/// at a glance.
///
/// ```dart
/// GlobalMarginalHistogram(
///   points: [ChartPoint(1.2, 3.4), ...],
///   bins: 24,
/// )
/// ```
class GlobalMarginalHistogram extends StatelessWidget {
  const GlobalMarginalHistogram({
    required this.points,
    this.style = ChartStyle.standard,
    this.animation = MarginalHistogramAnimation.sequential,
    this.bins = 20,
    this.dotRadius = 2.5,
    this.dotOpacity = 0.55,
    this.histogramSize = 0.18,
    this.color,
    this.showAxisLabels = true,
    this.valueFormatter,
    super.key,
  });

  final List<ChartPoint> points;
  final ChartStyle style;
  final MarginalHistogramAnimation animation;
  final int bins;
  final double dotRadius;
  final double dotOpacity;

  /// Fraction of the chart's short side reserved for the marginal
  /// histograms (0–0.4). Default 0.18.
  final double histogramSize;

  final Color? color;
  final bool showAxisLabels;
  final String Function(double)? valueFormatter;

  @override
  Widget build(BuildContext context) {
    if (points.isEmpty) return const SizedBox.shrink();
    final palette = resolveSeriesColors(context, style, 1);
    final c = color ?? palette.first;
    final fmt = valueFormatter ?? (v) => AppNumbers.compact(v);
    final axisStyle = resolveAxisLabelStyle(context, style);
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
                hitTest: (pos, size) => _hitTest(pos, size, c, fmt),
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
                      painter: _MHPainter(
                        points: points,
                        bins: bins,
                        dotRadius: dotRadius,
                        dotOpacity: dotOpacity,
                        histogramSize: histogramSize,
                        color: c,
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
    Color c,
    String Function(double) fmt,
  ) {
    final layout = _MHLayout.compute(
      points: points,
      size: size,
      bins: bins,
      histogramSize: histogramSize,
    );
    if (layout == null) return const [];
    var bestI = -1;
    var bestDist = double.infinity;
    for (var i = 0; i < points.length; i++) {
      final p = points[i];
      final px = layout.xFor(p.x);
      final py = layout.yFor(p.y);
      final d = ((Offset(px, py) - pos).distance);
      if (d < bestDist) {
        bestDist = d;
        bestI = i;
      }
    }
    if (bestI < 0 || bestDist > dotRadius + 8) return const [];
    return [
      TooltipEntry(
        label: '(${fmt(points[bestI].x)}, ${fmt(points[bestI].y)})',
        value: '',
        color: c,
      ),
    ];
  }
}

class _MHLayout {
  _MHLayout({
    required this.scatterRect,
    required this.topRect,
    required this.rightRect,
    required this.xMin,
    required this.xMax,
    required this.yMin,
    required this.yMax,
    required this.xBinCounts,
    required this.yBinCounts,
    required this.maxXBin,
    required this.maxYBin,
  });

  final Rect scatterRect;
  final Rect topRect;
  final Rect rightRect;
  final double xMin;
  final double xMax;
  final double yMin;
  final double yMax;
  final List<int> xBinCounts;
  final List<int> yBinCounts;
  final int maxXBin;
  final int maxYBin;

  double xFor(double v) =>
      scatterRect.left + (v - xMin) / (xMax - xMin) * scatterRect.width;
  double yFor(double v) =>
      scatterRect.bottom - (v - yMin) / (yMax - yMin) * scatterRect.height;

  static _MHLayout? compute({
    required List<ChartPoint> points,
    required Size size,
    required int bins,
    required double histogramSize,
  }) {
    if (size.width <= 0 || size.height <= 0) return null;
    if (points.isEmpty) return null;
    var xLo = double.infinity;
    var xHi = -double.infinity;
    var yLo = double.infinity;
    var yHi = -double.infinity;
    for (final p in points) {
      if (p.x < xLo) xLo = p.x;
      if (p.x > xHi) xHi = p.x;
      if (p.y < yLo) yLo = p.y;
      if (p.y > yHi) yHi = p.y;
    }
    if (xHi == xLo) xHi = xLo + 1;
    if (yHi == yLo) yHi = yLo + 1;
    final pad = (xHi - xLo) * 0.05;
    xLo -= pad;
    xHi += pad;
    final yPad = (yHi - yLo) * 0.05;
    yLo -= yPad;
    yHi += yPad;

    const padOuter = 32.0;
    final histX = size.height * histogramSize.clamp(0.05, 0.4);
    final histY = size.width * histogramSize.clamp(0.05, 0.4);
    final scatterRect = Rect.fromLTRB(
      padOuter,
      padOuter + histX,
      size.width - padOuter - histY,
      size.height - padOuter,
    );
    final topRect = Rect.fromLTRB(
      scatterRect.left,
      padOuter,
      scatterRect.right,
      scatterRect.top - 2,
    );
    final rightRect = Rect.fromLTRB(
      scatterRect.right + 2,
      scatterRect.top,
      size.width - padOuter,
      scatterRect.bottom,
    );

    final xCounts = List<int>.filled(bins, 0);
    final yCounts = List<int>.filled(bins, 0);
    for (final p in points) {
      final xi = (((p.x - xLo) / (xHi - xLo)) * bins).floor().clamp(
        0,
        bins - 1,
      );
      final yi = (((p.y - yLo) / (yHi - yLo)) * bins).floor().clamp(
        0,
        bins - 1,
      );
      xCounts[xi]++;
      yCounts[yi]++;
    }
    var maxX = 0;
    var maxY = 0;
    for (final c in xCounts) {
      if (c > maxX) maxX = c;
    }
    for (final c in yCounts) {
      if (c > maxY) maxY = c;
    }

    return _MHLayout(
      scatterRect: scatterRect,
      topRect: topRect,
      rightRect: rightRect,
      xMin: xLo,
      xMax: xHi,
      yMin: yLo,
      yMax: yHi,
      xBinCounts: xCounts,
      yBinCounts: yCounts,
      maxXBin: maxX == 0 ? 1 : maxX,
      maxYBin: maxY == 0 ? 1 : maxY,
    );
  }
}

class _MHPainter extends CustomPainter {
  _MHPainter({
    required this.points,
    required this.bins,
    required this.dotRadius,
    required this.dotOpacity,
    required this.histogramSize,
    required this.color,
    required this.showAxisLabels,
    required this.gridColor,
    required this.axisStyle,
    required this.animation,
    required this.progress,
    required this.valueFormatter,
  });

  final List<ChartPoint> points;
  final int bins;
  final double dotRadius;
  final double dotOpacity;
  final double histogramSize;
  final Color color;
  final bool showAxisLabels;
  final Color gridColor;
  final TextStyle axisStyle;
  final MarginalHistogramAnimation animation;
  final double progress;
  final String Function(double) valueFormatter;

  @override
  void paint(Canvas canvas, Size size) {
    final layout = _MHLayout.compute(
      points: points,
      size: size,
      bins: bins,
      histogramSize: histogramSize,
    );
    if (layout == null) return;

    // Frame around scatter region.
    canvas.drawRect(
      layout.scatterRect,
      Paint()
        ..color = gridColor.withValues(alpha: 0.5)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.5,
    );

    // Animation phases: 0..0.5 = scatter dots, 0.5..1 = histograms.
    double scatterT;
    double histT;
    if (animation == MarginalHistogramAnimation.sequential) {
      scatterT = (progress / 0.55).clamp(0.0, 1.0);
      histT = ((progress - 0.55) / 0.45).clamp(0.0, 1.0);
    } else {
      scatterT = progress;
      histT = progress;
    }

    // Scatter.
    for (var i = 0; i < points.length; i++) {
      final p = points[i];
      final px = layout.xFor(p.x);
      final py = layout.yFor(p.y);
      final delay = (i / points.length) * 0.4;
      final t = ((scatterT - delay) / (1 - delay)).clamp(0.0, 1.0);
      if (t <= 0) continue;
      canvas.drawCircle(
        Offset(px, py),
        dotRadius,
        Paint()..color = color.withValues(alpha: dotOpacity * t),
      );
    }

    // Top histogram (x marginal).
    final binW = layout.topRect.width / bins;
    for (var i = 0; i < bins; i++) {
      final h = layout.xBinCounts[i] / layout.maxXBin;
      final barH = h * layout.topRect.height * histT;
      final left = layout.topRect.left + i * binW;
      canvas.drawRect(
        Rect.fromLTWH(
          left + 0.5,
          layout.topRect.bottom - barH,
          binW - 1,
          barH,
        ),
        Paint()..color = color.withValues(alpha: 0.85),
      );
    }
    // Right histogram (y marginal).
    final binH = layout.rightRect.height / bins;
    for (var i = 0; i < bins; i++) {
      final h = layout.yBinCounts[i] / layout.maxYBin;
      final barW = h * layout.rightRect.width * histT;
      final bottom = layout.rightRect.bottom - i * binH;
      canvas.drawRect(
        Rect.fromLTWH(
          layout.rightRect.left,
          bottom - binH + 0.5,
          barW,
          binH - 1,
        ),
        Paint()..color = color.withValues(alpha: 0.85),
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

    drawText(
      valueFormatter(layout.xMin),
      Offset(layout.scatterRect.left, layout.scatterRect.bottom + 4),
    );
    drawText(
      valueFormatter(layout.xMax),
      Offset(layout.scatterRect.right, layout.scatterRect.bottom + 4),
      right: true,
    );
    drawText(
      valueFormatter(layout.yMax),
      Offset(4, layout.scatterRect.top - 4),
    );
    drawText(
      valueFormatter(layout.yMin),
      Offset(4, layout.scatterRect.bottom - 12),
    );
  }

  @override
  bool shouldRepaint(covariant _MHPainter old) =>
      old.progress != progress ||
      old.points != points ||
      old.animation != animation ||
      old.bins != bins;
}
