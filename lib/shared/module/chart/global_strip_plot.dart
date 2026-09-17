import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/localization/number_formatter.dart';
import 'chart_data.dart';
import 'chart_internals.dart';
import 'chart_models.dart';
import 'chart_tooltip_overlay.dart';
import 'chart_zoom_pan.dart';
import 'custom_paint_tooltip.dart';

export 'chart_data.dart' show ViolinDatum;
export 'chart_models.dart' show ChartStyle, StripPlotAnimation;

/// Strip plot — 1D scatter per category. Each value renders as a
/// dot at its true y position, with optional small horizontal
/// jitter so dots at identical values don't overlap completely.
///
/// Differs from beeswarm: no collision packing, just simple jitter.
/// Faster, simpler look — best when distribution shape isn't the
/// primary message.
///
/// ```dart
/// GlobalStripPlot(
///   data: [
///     ViolinDatum(label: 'A', values: [1.2, 1.4, ...]),
///   ],
/// )
/// ```
class GlobalStripPlot extends StatelessWidget {
  const GlobalStripPlot({
    required this.data,
    this.style = ChartStyle.standard,
    this.animation = StripPlotAnimation.rise,
    this.dotRadius = 2.5,
    this.dotOpacity = 0.6,
    this.jitter = 0.5,
    this.showMedian = true,
    this.valueFormatter,
    super.key,
  });

  final List<ViolinDatum> data;
  final ChartStyle style;
  final StripPlotAnimation animation;
  final double dotRadius;
  final double dotOpacity;

  /// Horizontal jitter as a fraction of the column width (0–1).
  /// 0 = perfectly aligned strip; 0.5 = moderate spread.
  final double jitter;

  final bool showMedian;
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
                      painter: _StripPainter(
                        data: data,
                        colors: palette,
                        dotRadius: dotRadius,
                        dotOpacity: dotOpacity,
                        jitter: jitter,
                        showMedian: showMedian,
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
    final layout = _StripLayout.compute(data: data, size: size);
    if (layout == null) return const [];
    var bestI = -1;
    var bestDx = double.infinity;
    for (var i = 0; i < data.length; i++) {
      final dx = (layout.centers[i] - pos.dx).abs();
      if (dx < bestDx) {
        bestDx = dx;
        bestI = i;
      }
    }
    if (bestI < 0 || bestDx > layout.colW / 2) return const [];
    // Find nearest value in column to pos.dy.
    final pts = data[bestI].values;
    if (pts.isEmpty) return const [];
    var bestV = pts.first;
    var bestVDist = double.infinity;
    for (final v in pts) {
      final y = layout.yFor(v);
      final d = (y - pos.dy).abs();
      if (d < bestVDist) {
        bestVDist = d;
        bestV = v;
      }
    }
    if (bestVDist > 14) return const [];
    return [
      TooltipEntry(
        label: data[bestI].label,
        value: fmt(bestV),
        color: data[bestI].color ?? palette[bestI],
      ),
    ];
  }
}

class _StripLayout {
  _StripLayout({
    required this.centers,
    required this.colW,
    required this.gMin,
    required this.gMax,
    required this.top,
    required this.bottom,
  });

  final List<double> centers;
  final double colW;
  final double gMin;
  final double gMax;
  final double top;
  final double bottom;

  double yFor(double v) {
    return bottom - (v - gMin) / (gMax - gMin) * (bottom - top);
  }

  static _StripLayout? compute({
    required List<ViolinDatum> data,
    required Size size,
  }) {
    if (size.width <= 0 || size.height <= 0) return null;
    if (data.isEmpty) return null;
    var gMin = double.infinity;
    var gMax = -double.infinity;
    for (final d in data) {
      for (final v in d.values) {
        if (v < gMin) gMin = v;
        if (v > gMax) gMax = v;
      }
    }
    if (gMin == double.infinity) return null;
    if (gMax == gMin) gMax = gMin + 1;
    final pad = (gMax - gMin) * 0.05;
    gMin -= pad;
    gMax += pad;
    const leftPad = 32.0;
    const rightPad = 16.0;
    const topPad = 16.0;
    const bottomPad = 28.0;
    final usableW = size.width - leftPad - rightPad;
    final n = data.length;
    final colW = usableW / n;
    final centers = List<double>.generate(n, (i) => leftPad + colW * (i + 0.5));
    return _StripLayout(
      centers: centers,
      colW: colW,
      gMin: gMin,
      gMax: gMax,
      top: topPad,
      bottom: size.height - bottomPad,
    );
  }
}

class _StripPainter extends CustomPainter {
  _StripPainter({
    required this.data,
    required this.colors,
    required this.dotRadius,
    required this.dotOpacity,
    required this.jitter,
    required this.showMedian,
    required this.gridColor,
    required this.axisStyle,
    required this.animation,
    required this.progress,
    required this.valueFormatter,
  });

  final List<ViolinDatum> data;
  final List<Color> colors;
  final double dotRadius;
  final double dotOpacity;
  final double jitter;
  final bool showMedian;
  final Color gridColor;
  final TextStyle axisStyle;
  final StripPlotAnimation animation;
  final double progress;
  final String Function(double) valueFormatter;

  @override
  void paint(Canvas canvas, Size size) {
    final layout = _StripLayout.compute(data: data, size: size);
    if (layout == null) return;

    canvas.drawLine(
      Offset(0, layout.bottom),
      Offset(size.width, layout.bottom),
      Paint()
        ..color = gridColor
        ..strokeWidth = 0.5,
    );

    for (var ci = 0; ci < data.length; ci++) {
      final c = data[ci].color ?? colors[ci];
      final cx = layout.centers[ci];
      final spread = layout.colW * jitter;
      final rng = math.Random(ci * 31 + 7);
      final values = data[ci].values;
      for (var i = 0; i < values.length; i++) {
        final v = values[i];
        final y = layout.yFor(v);
        final jx = cx + (rng.nextDouble() - 0.5) * spread;
        // Per-dot animation.
        final delay = (i / values.length) * 0.3;
        final t = ((progress - delay) / (1 - delay)).clamp(0.0, 1.0);
        var px = jx;
        var py = y;
        var opacity = 1.0;
        switch (animation) {
          case StripPlotAnimation.rise:
            py = layout.bottom - (layout.bottom - y) * t;
            opacity = t;
          case StripPlotAnimation.fade:
            opacity = progress;
          case StripPlotAnimation.drift:
            px = jx + (1 - t) * spread * (rng.nextDouble() - 0.5) * 2;
            opacity = t;
        }
        if (opacity <= 0) continue;
        canvas.drawCircle(
          Offset(px, py),
          dotRadius,
          Paint()..color = c.withValues(alpha: dotOpacity * opacity),
        );
      }

      // Median marker.
      if (showMedian && values.isNotEmpty && progress > 0.7) {
        final fade = ((progress - 0.7) / 0.3).clamp(0.0, 1.0);
        final sorted = [...values]..sort();
        final med = sorted.length.isOdd
            ? sorted[sorted.length ~/ 2]
            : (sorted[sorted.length ~/ 2 - 1] + sorted[sorted.length ~/ 2]) / 2;
        final yMed = layout.yFor(med);
        canvas.drawLine(
          Offset(cx - layout.colW * 0.3, yMed),
          Offset(cx + layout.colW * 0.3, yMed),
          Paint()
            ..color = c.withValues(alpha: fade)
            ..strokeWidth = 2.5
            ..strokeCap = StrokeCap.round,
        );
      }

      // Category label.
      if (progress > 0.4) {
        final fadeRaw = ((progress - 0.4) / 0.6).clamp(0.0, 1.0);
        final fade = Curves.easeOutCubic.transform(fadeRaw);
        final tp = TextPainter(
          text: TextSpan(
            text: data[ci].label,
            style: axisStyle.copyWith(
              color: axisStyle.color?.withValues(alpha: fade),
              fontWeight: FontWeight.w600,
            ),
          ),
          textDirection: TextDirection.ltr,
          maxLines: 1,
          ellipsis: '…',
        )..layout(maxWidth: layout.colW + 16);
        tp.paint(
          canvas,
          Offset(cx - tp.width / 2, layout.bottom + 6),
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _StripPainter old) =>
      old.progress != progress ||
      old.data != data ||
      old.animation != animation;
}
