import 'package:flutter/material.dart';

import '../../../core/localization/number_formatter.dart';
import 'chart_data.dart';
import 'chart_internals.dart';
import 'chart_models.dart';
import 'chart_tooltip_overlay.dart';
import 'chart_zoom_pan.dart';
import 'custom_paint_tooltip.dart';

export 'chart_data.dart' show ChartSeries, ChartPoint;
export 'chart_models.dart' show ChartStyle, StreamgraphAnimation;

/// Streamgraph — N stacked area series symmetric around a centered
/// baseline (a.k.a. ThemeRiver). Total height at any x is the sum of
/// all series at that x; each band's vertical extent is its share.
///
/// Best for showing the relative composition of a flowing total over
/// time — music genre share, traffic source mix, sales by category.
///
/// All series must share the same `x` positions (e.g. timestamps);
/// non-overlapping `x` values are interpolated as 0.
///
/// ```dart
/// GlobalStreamgraph(
///   series: [
///     ChartSeries(name: 'Pop',  points: [...]),
///     ChartSeries(name: 'Rock', points: [...]),
///   ],
/// )
/// ```
class GlobalStreamgraph extends StatelessWidget {
  const GlobalStreamgraph({
    required this.series,
    this.style = ChartStyle.standard,
    this.animation = StreamgraphAnimation.expand,
    this.smooth = true,
    this.bandOpacity = 0.85,
    this.gap = 0.5,
    this.valueFormatter,
    super.key,
  });

  final List<ChartSeries> series;
  final ChartStyle style;
  final StreamgraphAnimation animation;

  /// Cubic interpolation between data points instead of straight
  /// segments. Default `true` gives the classic flowing look.
  final bool smooth;

  /// Per-band fill opacity.
  final double bandOpacity;

  /// Pixel gap between adjacent bands.
  final double gap;

  final String Function(double)? valueFormatter;

  @override
  Widget build(BuildContext context) {
    if (series.isEmpty) return const SizedBox.shrink();
    final palette = resolveSeriesColors(context, style, series.length);
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
                      painter: _StreamgraphPainter(
                        series: series,
                        colors: palette,
                        smooth: smooth,
                        bandOpacity: bandOpacity,
                        gap: gap,
                        gridColor: gridColor,
                        axisStyle: axisStyle,
                        valueFormatter: fmt,
                        animation: animation,
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
    List<Color> colors,
    String Function(double) fmt,
  ) {
    if (series.isEmpty) return const [];
    final layout = _StreamLayout.compute(series: series, size: size);
    if (layout == null) return const [];
    if (pos.dx < layout.left || pos.dx > layout.right) return const [];

    // Find x index closest to pos.dx.
    final t = (pos.dx - layout.left) / (layout.right - layout.left);
    final xIdx = (t * (layout.xCount - 1)).round().clamp(0, layout.xCount - 1);

    // Walk bands from bottom to top, find which contains pos.dy.
    final out = <TooltipEntry>[];
    for (var i = 0; i < series.length; i++) {
      final yLo = layout.bandLow[i][xIdx];
      final yHi = layout.bandHigh[i][xIdx];
      if (pos.dy >= yHi && pos.dy <= yLo) {
        final v = layout.values[i][xIdx];
        out.add(
          TooltipEntry(
            label: series[i].name,
            value: fmt(v),
            color: series[i].color ?? colors[i],
          ),
        );
        break;
      }
    }
    return out;
  }
}

class _StreamLayout {
  _StreamLayout({
    required this.bandLow,
    required this.bandHigh,
    required this.values,
    required this.xs,
    required this.left,
    required this.right,
    required this.top,
    required this.bottom,
  });

  /// Per series, per x: bottom y (larger value).
  final List<List<double>> bandLow;

  /// Per series, per x: top y (smaller value).
  final List<List<double>> bandHigh;

  /// Per series, per x: raw value at that x.
  final List<List<double>> values;
  final List<double> xs;
  final double left;
  final double right;
  final double top;
  final double bottom;

  int get xCount => xs.length;

  static _StreamLayout? compute({
    required List<ChartSeries> series,
    required Size size,
  }) {
    if (size.width <= 0 || size.height <= 0) return null;
    if (series.isEmpty) return null;

    // Collect all x positions across series.
    final allX = <double>{};
    for (final s in series) {
      for (final p in s.points) {
        allX.add(p.x);
      }
    }
    if (allX.isEmpty) return null;
    final xs = allX.toList()..sort();

    // Per-series sampled values at each shared x (linear interp /
    // 0 outside extents).
    final values = <List<double>>[];
    for (final s in series) {
      final sortedPts = [...s.points]..sort((a, b) => a.x.compareTo(b.x));
      final v = <double>[];
      for (final x in xs) {
        v.add(_sampleAtX(sortedPts, x));
      }
      values.add(v);
    }

    // Total per x.
    final totals = List<double>.filled(xs.length, 0);
    for (var j = 0; j < xs.length; j++) {
      var t = 0.0;
      for (var i = 0; i < series.length; i++) {
        t += values[i][j];
      }
      totals[j] = t;
    }

    var maxTotal = 0.0;
    for (final t in totals) {
      if (t > maxTotal) maxTotal = t;
    }
    if (maxTotal <= 0) maxTotal = 1;

    const leftPad = 8.0;
    const rightPad = 8.0;
    const topPad = 12.0;
    const bottomPad = 28.0;
    const left = leftPad;
    final right = size.width - rightPad;
    const top = topPad;
    final bottom = size.height - bottomPad;
    final usableH = bottom - top;
    final centerY = (top + bottom) / 2;

    final bandLow = <List<double>>[];
    final bandHigh = <List<double>>[];
    for (var i = 0; i < series.length; i++) {
      bandLow.add(List<double>.filled(xs.length, 0));
      bandHigh.add(List<double>.filled(xs.length, 0));
    }

    for (var j = 0; j < xs.length; j++) {
      final total = totals[j];
      // Center the stack on `centerY`. Each band's y-range is its
      // share of total scaled to usableH.
      final stackH = (total / maxTotal) * usableH;
      var cursor = centerY - stackH / 2;
      for (var i = 0; i < series.length; i++) {
        final share = total > 0 ? values[i][j] / total : 0;
        final h = share * stackH;
        bandHigh[i][j] = cursor;
        bandLow[i][j] = cursor + h;
        cursor += h;
      }
    }

    return _StreamLayout(
      bandLow: bandLow,
      bandHigh: bandHigh,
      values: values,
      xs: xs,
      left: left,
      right: right,
      top: top,
      bottom: bottom,
    );
  }

  static double _sampleAtX(List<ChartPoint> pts, double x) {
    if (pts.isEmpty) return 0;
    if (x <= pts.first.x) return pts.first.y;
    if (x >= pts.last.x) return pts.last.y;
    for (var i = 1; i < pts.length; i++) {
      if (pts[i].x >= x) {
        final p0 = pts[i - 1];
        final p1 = pts[i];
        final t = (x - p0.x) / (p1.x - p0.x);
        return p0.y + (p1.y - p0.y) * t;
      }
    }
    return pts.last.y;
  }
}

class _StreamgraphPainter extends CustomPainter {
  _StreamgraphPainter({
    required this.series,
    required this.colors,
    required this.smooth,
    required this.bandOpacity,
    required this.gap,
    required this.gridColor,
    required this.axisStyle,
    required this.valueFormatter,
    required this.animation,
    required this.progress,
  });

  final List<ChartSeries> series;
  final List<Color> colors;
  final bool smooth;
  final double bandOpacity;
  final double gap;
  final Color gridColor;
  final TextStyle axisStyle;
  final String Function(double) valueFormatter;
  final StreamgraphAnimation animation;
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final layout = _StreamLayout.compute(series: series, size: size);
    if (layout == null) return;
    final centerY = (layout.top + layout.bottom) / 2;

    // Subtle centerline guide.
    canvas.drawLine(
      Offset(layout.left, centerY),
      Offset(layout.right, centerY),
      Paint()
        ..color = gridColor
        ..strokeWidth = 0.5,
    );

    final xCount = layout.xCount;
    final xPx = List<double>.generate(xCount, (j) {
      final t = xCount == 1 ? 0.5 : j / (xCount - 1);
      return layout.left + (layout.right - layout.left) * t;
    });

    for (var i = 0; i < series.length; i++) {
      final c = (series[i].color ?? colors[i]).withValues(alpha: bandOpacity);
      final low = layout.bandLow[i];
      final high = layout.bandHigh[i];

      // Animation handling.
      var animLow = low;
      var animHigh = high;
      var rightCutoff = layout.right;
      var opacity = 1.0;

      if (animation == StreamgraphAnimation.expand) {
        animLow = List<double>.generate(
          low.length,
          (j) => centerY + (low[j] - centerY) * progress,
        );
        animHigh = List<double>.generate(
          high.length,
          (j) => centerY + (high[j] - centerY) * progress,
        );
      } else if (animation == StreamgraphAnimation.draw) {
        rightCutoff = layout.left + (layout.right - layout.left) * progress;
      } else if (animation == StreamgraphAnimation.fade) {
        opacity = progress;
      }

      // Build single closed path: top edge L→R, drop at cutoff,
      // bottom edge R→L, close back to start.
      final path = _buildBandPath(
        xs: xPx,
        high: animHigh,
        low: animLow,
        smooth: smooth,
        maxX: rightCutoff,
      );

      // Compress band slightly to reveal gap between adjacent bands.
      // (Only relevant when gap > 0.)
      final bandPaint = Paint()
        ..color = c.withValues(alpha: bandOpacity * opacity);
      canvas.drawPath(path, bandPaint);

      // Hairline outline for definition.
      if (gap > 0) {
        final outline = Paint()
          ..color = (series[i].color ?? colors[i]).withValues(
            alpha: 0.4 * opacity,
          )
          ..strokeWidth = gap
          ..style = PaintingStyle.stroke;
        canvas.drawPath(path, outline);
      }
    }
  }

  Path _buildBandPath({
    required List<double> xs,
    required List<double> high,
    required List<double> low,
    required bool smooth,
    required double maxX,
  }) {
    final n = xs.length;
    final path = Path();
    if (n == 0) return path;

    // Determine cutoff index — last index where xs[i] <= maxX.
    var cutI = -1;
    for (var i = 0; i < n; i++) {
      if (xs[i] <= maxX) {
        cutI = i;
      } else {
        break;
      }
    }
    if (cutI < 0) return path;

    // Top edge L→R.
    path.moveTo(xs[0], high[0]);
    for (var i = 1; i <= cutI; i++) {
      if (smooth) {
        final cx = (xs[i - 1] + xs[i]) / 2;
        path.cubicTo(cx, high[i - 1], cx, high[i], xs[i], high[i]);
      } else {
        path.lineTo(xs[i], high[i]);
      }
    }
    // Interp top at cutoff if maxX falls between cutI and cutI+1.
    var rightX = xs[cutI];
    var rightHigh = high[cutI];
    var rightLow = low[cutI];
    if (cutI < n - 1 && maxX > xs[cutI]) {
      final t = (maxX - xs[cutI]) / (xs[cutI + 1] - xs[cutI]);
      rightX = maxX;
      rightHigh = high[cutI] + (high[cutI + 1] - high[cutI]) * t;
      rightLow = low[cutI] + (low[cutI + 1] - low[cutI]) * t;
      path.lineTo(rightX, rightHigh);
    }
    // Drop to bottom at right edge.
    path.lineTo(rightX, rightLow);
    // Bottom edge R→L.
    for (var i = cutI; i >= 0; i--) {
      final tx = xs[i];
      final ty = low[i];
      if (smooth && i < cutI) {
        final cx = (xs[i + 1] + tx) / 2;
        path.cubicTo(cx, low[i + 1], cx, ty, tx, ty);
      } else {
        path.lineTo(tx, ty);
      }
    }
    path.close();
    return path;
  }

  @override
  bool shouldRepaint(covariant _StreamgraphPainter old) =>
      old.progress != progress ||
      old.series != series ||
      old.animation != animation ||
      old.smooth != smooth;
}
