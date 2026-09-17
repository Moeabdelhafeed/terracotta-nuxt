import 'package:flutter/material.dart';

import '../../../core/localization/number_formatter.dart';
import 'chart_data.dart';
import 'chart_internals.dart';
import 'chart_models.dart';
import 'chart_tooltip_overlay.dart';
import 'chart_zoom_pan.dart';
import 'custom_paint_tooltip.dart';

export 'chart_data.dart' show FanBand, BandPoint, ChartPoint;
export 'chart_models.dart' show ChartStyle, FanAnimation;

/// Fan chart — multiple confidence bands stacked over a median
/// line. Wider bands (e.g. 95%) drawn first, narrower (50%) last
/// so they "fan" outward from the projection.
///
/// Common in forecast / scenario charts (BoE inflation, economic
/// projections, climate uncertainty).
///
/// ```dart
/// GlobalFanChart(
///   bands: [
///     FanBand(label: '95%', points: [...]),
///     FanBand(label: '80%', points: [...]),
///     FanBand(label: '50%', points: [...]),
///   ],
///   median: [ChartPoint(0, 100), ChartPoint(1, 102), ...],
/// )
/// ```
class GlobalFanChart extends StatelessWidget {
  const GlobalFanChart({
    required this.bands,
    this.median = const [],
    this.style = ChartStyle.standard,
    this.animation = FanAnimation.expand,
    this.smooth = true,
    this.medianWidth = 2.0,
    this.bandColor,
    this.medianColor,
    this.showAxisLabels = true,
    this.valueFormatter,
    super.key,
  });

  /// Confidence bands ordered widest → narrowest.
  final List<FanBand> bands;

  /// Optional center line (point estimate / forecast median).
  final List<ChartPoint> median;
  final ChartStyle style;
  final FanAnimation animation;
  final bool smooth;
  final double medianWidth;
  final Color? bandColor;
  final Color? medianColor;
  final bool showAxisLabels;
  final String Function(double)? valueFormatter;

  @override
  Widget build(BuildContext context) {
    if (bands.isEmpty) return const SizedBox.shrink();
    final palette = resolveSeriesColors(context, style, 1);
    final base = bandColor ?? palette.first;
    final medianC = medianColor ?? base;
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
                hitTest: (pos, size) => _hitTest(pos, size, base, fmt),
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
                      painter: _FanPainter(
                        bands: bands,
                        median: median,
                        bandBase: base,
                        medianColor: medianC,
                        smooth: smooth,
                        medianWidth: medianWidth,
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
    Color base,
    String Function(double) fmt,
  ) {
    final layout = _FanLayout.compute(
      bands: bands,
      median: median,
      size: size,
    );
    if (layout == null) return const [];
    if (pos.dx < layout.left || pos.dx > layout.right) return const [];
    final t = (pos.dx - layout.left) / (layout.right - layout.left);
    // Find x index closest.
    final outerBand = bands.first;
    if (outerBand.points.isEmpty) return const [];
    final idx = (t * (outerBand.points.length - 1)).round().clamp(
      0,
      outerBand.points.length - 1,
    );
    // Locate which band contains pos.dy.
    for (var bi = bands.length - 1; bi >= 0; bi--) {
      final b = bands[bi];
      if (idx >= b.points.length) continue;
      final p = b.points[idx];
      final yLo = layout.yFor(p.low);
      final yHi = layout.yFor(p.high);
      if (pos.dy >= yHi && pos.dy <= yLo) {
        return [
          TooltipEntry(
            label: b.label,
            value: '${fmt(p.low)}–${fmt(p.high)}',
            color: b.color ?? base,
          ),
        ];
      }
    }
    return const [];
  }
}

class _FanLayout {
  _FanLayout({
    required this.left,
    required this.right,
    required this.top,
    required this.bottom,
    required this.xMin,
    required this.xMax,
    required this.yMin,
    required this.yMax,
  });

  final double left;
  final double right;
  final double top;
  final double bottom;
  final double xMin;
  final double xMax;
  final double yMin;
  final double yMax;

  double xFor(double v) {
    return left + (v - xMin) / (xMax - xMin) * (right - left);
  }

  double yFor(double v) {
    return bottom - (v - yMin) / (yMax - yMin) * (bottom - top);
  }

  static _FanLayout? compute({
    required List<FanBand> bands,
    required List<ChartPoint> median,
    required Size size,
  }) {
    if (size.width <= 0 || size.height <= 0) return null;
    if (bands.isEmpty) return null;
    var xLo = double.infinity;
    var xHi = -double.infinity;
    var yLo = double.infinity;
    var yHi = -double.infinity;
    for (final b in bands) {
      for (final p in b.points) {
        if (p.x < xLo) xLo = p.x;
        if (p.x > xHi) xHi = p.x;
        if (p.low < yLo) yLo = p.low;
        if (p.high > yHi) yHi = p.high;
      }
    }
    for (final p in median) {
      if (p.x < xLo) xLo = p.x;
      if (p.x > xHi) xHi = p.x;
      if (p.y < yLo) yLo = p.y;
      if (p.y > yHi) yHi = p.y;
    }
    if (xLo == double.infinity) return null;
    if (xHi == xLo) xHi = xLo + 1;
    if (yHi == yLo) yHi = yLo + 1;
    final pad = (yHi - yLo) * 0.08;
    yLo -= pad;
    yHi += pad;

    const leftPad = 32.0;
    const rightPad = 12.0;
    const topPad = 16.0;
    const bottomPad = 28.0;
    return _FanLayout(
      left: leftPad,
      right: size.width - rightPad,
      top: topPad,
      bottom: size.height - bottomPad,
      xMin: xLo,
      xMax: xHi,
      yMin: yLo,
      yMax: yHi,
    );
  }
}

class _FanPainter extends CustomPainter {
  _FanPainter({
    required this.bands,
    required this.median,
    required this.bandBase,
    required this.medianColor,
    required this.smooth,
    required this.medianWidth,
    required this.showAxisLabels,
    required this.gridColor,
    required this.axisStyle,
    required this.animation,
    required this.progress,
    required this.valueFormatter,
  });

  final List<FanBand> bands;
  final List<ChartPoint> median;
  final Color bandBase;
  final Color medianColor;
  final bool smooth;
  final double medianWidth;
  final bool showAxisLabels;
  final Color gridColor;
  final TextStyle axisStyle;
  final FanAnimation animation;
  final double progress;
  final String Function(double) valueFormatter;

  @override
  void paint(Canvas canvas, Size size) {
    final layout = _FanLayout.compute(
      bands: bands,
      median: median,
      size: size,
    );
    if (layout == null) return;

    // Subtle grid: top/bottom of plot rect + median line baseline.
    final guidePaint = Paint()
      ..color = gridColor
      ..strokeWidth = 0.5;
    canvas.drawLine(
      Offset(layout.left, layout.bottom),
      Offset(layout.right, layout.bottom),
      guidePaint,
    );

    // Center y for expand animation — approximate: median line if
    // present, else midpoint of yMin..yMax.
    double centerYAt(double x) {
      if (median.isEmpty) {
        return (layout.top + layout.bottom) / 2;
      }
      // Find nearest median y.
      var bestI = 0;
      var bestDx = double.infinity;
      for (var i = 0; i < median.length; i++) {
        final d = (median[i].x - x).abs();
        if (d < bestDx) {
          bestDx = d;
          bestI = i;
        }
      }
      return layout.yFor(median[bestI].y);
    }

    // Bands — wide first.
    for (var bi = 0; bi < bands.length; bi++) {
      final b = bands[bi];
      if (b.points.isEmpty) continue;
      final layered = bi / bands.length.toDouble();
      final alpha = b.opacity * (1 + layered * 1.2);
      var rightCutoff = layout.right;
      var opacity = 1.0;
      if (animation == FanAnimation.draw) {
        rightCutoff = layout.left + (layout.right - layout.left) * progress;
      } else if (animation == FanAnimation.fade) {
        opacity = progress;
      }

      final color = (b.color ?? bandBase).withValues(
        alpha: alpha.clamp(0.05, 0.85) * opacity,
      );

      final path = _bandPath(
        b.points,
        layout,
        smooth: smooth,
        maxX: rightCutoff,
        animateExpand: animation == FanAnimation.expand,
        progress: progress,
        centerYAt: centerYAt,
      );
      canvas.drawPath(path, Paint()..color = color);
    }

    // Median line.
    if (median.isNotEmpty) {
      final path = Path();
      var rightCutoff = layout.right;
      if (animation == FanAnimation.draw) {
        rightCutoff = layout.left + (layout.right - layout.left) * progress;
      }
      var first = true;
      for (var i = 0; i < median.length; i++) {
        final p = median[i];
        final px = layout.xFor(p.x);
        if (px > rightCutoff) {
          if (!first && i > 0) {
            final prev = median[i - 1];
            final ppx = layout.xFor(prev.x);
            final t = (rightCutoff - ppx) / (px - ppx);
            final ppy = layout.yFor(prev.y);
            final cy = layout.yFor(p.y);
            path.lineTo(rightCutoff, ppy + (cy - ppy) * t);
          }
          break;
        }
        final py = layout.yFor(p.y);
        if (first) {
          path.moveTo(px, py);
          first = false;
        } else {
          if (smooth) {
            final prev = median[i - 1];
            final ppx = layout.xFor(prev.x);
            final ppy = layout.yFor(prev.y);
            final cx = (ppx + px) / 2;
            path.cubicTo(cx, ppy, cx, py, px, py);
          } else {
            path.lineTo(px, py);
          }
        }
      }
      var opacity = 1.0;
      if (animation == FanAnimation.fade) opacity = progress;
      if (animation == FanAnimation.expand) {
        opacity = (progress - 0.3).clamp(0.0, 0.7) / 0.7;
      }
      canvas.drawPath(
        path,
        Paint()
          ..color = medianColor.withValues(alpha: opacity)
          ..strokeWidth = medianWidth
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round,
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

    drawText(valueFormatter(layout.yMax), Offset(4, layout.top - 4));
    drawText(valueFormatter(layout.yMin), Offset(4, layout.bottom - 12));
    drawText(
      valueFormatter(layout.xMin),
      Offset(layout.left, layout.bottom + 4),
    );
    drawText(
      valueFormatter(layout.xMax),
      Offset(layout.right, layout.bottom + 4),
      right: true,
    );
  }

  Path _bandPath(
    List<BandPoint> points,
    _FanLayout layout, {
    required bool smooth,
    required double maxX,
    required bool animateExpand,
    required double progress,
    required double Function(double x) centerYAt,
  }) {
    final path = Path();
    if (points.isEmpty) return path;

    double yLoFor(BandPoint p) {
      final raw = layout.yFor(p.low);
      if (!animateExpand) return raw;
      final c = centerYAt(p.x);
      return c + (raw - c) * progress;
    }

    double yHiFor(BandPoint p) {
      final raw = layout.yFor(p.high);
      if (!animateExpand) return raw;
      final c = centerYAt(p.x);
      return c + (raw - c) * progress;
    }

    // Top edge L→R.
    var first = true;
    var cutI = -1;
    for (var i = 0; i < points.length; i++) {
      final px = layout.xFor(points[i].x);
      if (px > maxX) break;
      cutI = i;
    }
    if (cutI < 0) return path;

    for (var i = 0; i <= cutI; i++) {
      final p = points[i];
      final px = layout.xFor(p.x);
      final py = yHiFor(p);
      if (first) {
        path.moveTo(px, py);
        first = false;
      } else {
        if (smooth) {
          final prev = points[i - 1];
          final ppx = layout.xFor(prev.x);
          final ppy = yHiFor(prev);
          final cx = (ppx + px) / 2;
          path.cubicTo(cx, ppy, cx, py, px, py);
        } else {
          path.lineTo(px, py);
        }
      }
    }
    // Interp at right edge if maxX between samples.
    final rightIdx = cutI;
    final rightX = layout.xFor(points[rightIdx].x);
    var endX = rightX;
    var endHigh = yHiFor(points[rightIdx]);
    var endLow = yLoFor(points[rightIdx]);
    if (rightIdx < points.length - 1 && maxX > rightX) {
      final next = points[rightIdx + 1];
      final nx = layout.xFor(next.x);
      final t = (maxX - rightX) / (nx - rightX);
      endX = maxX;
      endHigh =
          yHiFor(points[rightIdx]) +
          (yHiFor(next) - yHiFor(points[rightIdx])) * t;
      endLow =
          yLoFor(points[rightIdx]) +
          (yLoFor(next) - yLoFor(points[rightIdx])) * t;
      path.lineTo(endX, endHigh);
    }
    path.lineTo(endX, endLow);
    // Bottom edge R→L.
    for (var i = cutI; i >= 0; i--) {
      final p = points[i];
      final px = layout.xFor(p.x);
      final py = yLoFor(p);
      if (smooth && i < cutI) {
        final next = points[i + 1];
        final npx = layout.xFor(next.x);
        final npy = yLoFor(next);
        final cx = (npx + px) / 2;
        path.cubicTo(cx, npy, cx, py, px, py);
      } else {
        path.lineTo(px, py);
      }
    }
    path.close();
    return path;
  }

  @override
  bool shouldRepaint(covariant _FanPainter old) =>
      old.progress != progress ||
      old.bands != bands ||
      old.median != median ||
      old.animation != animation;
}
