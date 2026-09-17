import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/extensions/theme_colors_extension.dart';
import '../../../core/localization/number_formatter.dart';
import 'chart_data.dart';
import 'chart_internals.dart';
import 'chart_models.dart';
import 'chart_tooltip_overlay.dart';
import 'chart_zoom_pan.dart';
import 'custom_paint_tooltip.dart';

export 'chart_data.dart' show ViolinDatum;
export 'chart_models.dart' show ChartStyle, QQPlotAnimation;

/// Reference distribution for QQ plot theoretical quantiles.
enum QQDistribution {
  /// Standard normal (μ=0, σ=1) — auto-rescaled to sample's mean
  /// and stdev for visual alignment with `referenceLine: true`.
  normal,

  /// Uniform on [0, 1] — auto-rescaled to sample's [min, max].
  uniform,
}

/// QQ plot — quantile-quantile scatter. Each point is `(theoretical
/// quantile, sample quantile)`. A reference line y=x indicates
/// perfect distributional match.
///
/// Reuses [ViolinDatum] for input (label + raw values per series).
/// Multiple series overlay so you can compare distributions.
///
/// ```dart
/// GlobalQQPlot(
///   data: [
///     ViolinDatum(label: 'Sample', values: [1.2, 1.4, ...]),
///   ],
/// )
/// ```
class GlobalQQPlot extends StatelessWidget {
  const GlobalQQPlot({
    required this.data,
    this.style = ChartStyle.standard,
    this.animation = QQPlotAnimation.sequential,
    this.distribution = QQDistribution.normal,
    this.dotRadius = 3.0,
    this.dotOpacity = 0.85,
    this.referenceLine = true,
    this.referenceWidth = 1.6,
    this.showAxisLabels = true,
    this.valueFormatter,
    super.key,
  });

  final List<ViolinDatum> data;
  final ChartStyle style;
  final QQPlotAnimation animation;
  final QQDistribution distribution;
  final double dotRadius;
  final double dotOpacity;
  final bool referenceLine;
  final double referenceWidth;
  final bool showAxisLabels;
  final String Function(double)? valueFormatter;

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) return const SizedBox.shrink();
    final palette = resolveSeriesColors(context, style, data.length);
    final fmt = valueFormatter ?? (v) => AppNumbers.compact(v);
    final axisStyle = resolveAxisLabelStyle(context, style);
    final gridColor = resolveGridColor(context, style);
    final fg = context.textColors.primary;

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
                      painter: _QQPainter(
                        data: data,
                        colors: palette,
                        distribution: distribution,
                        dotRadius: dotRadius,
                        dotOpacity: dotOpacity,
                        referenceLine: referenceLine,
                        referenceWidth: referenceWidth,
                        showAxisLabels: showAxisLabels,
                        gridColor: gridColor,
                        axisStyle: axisStyle,
                        fg: fg,
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
    final layout = _QQLayout.compute(
      data: data,
      size: size,
      distribution: distribution,
    );
    if (layout == null) return const [];
    var bestI = -1;
    var bestJ = -1;
    var bestDist = double.infinity;
    for (var i = 0; i < layout.points.length; i++) {
      for (var j = 0; j < layout.points[i].length; j++) {
        final p = layout.points[i][j];
        final d = (p - pos).distance;
        if (d < bestDist) {
          bestDist = d;
          bestI = i;
          bestJ = j;
        }
      }
    }
    if (bestI < 0 || bestDist > dotRadius + 8) return const [];
    final c = data[bestI].color ?? palette[bestI];
    return [
      TooltipEntry(
        label: data[bestI].label,
        value:
            'theo=${fmt(layout.theos[bestI][bestJ])} '
            '· obs=${fmt(layout.obs[bestI][bestJ])}',
        color: c,
      ),
    ];
  }
}

class _QQLayout {
  _QQLayout({
    required this.points,
    required this.theos,
    required this.obs,
    required this.left,
    required this.right,
    required this.top,
    required this.bottom,
    required this.lo,
    required this.hi,
  });

  /// Per series, per point: pixel position.
  final List<List<Offset>> points;

  /// Per series, per point: theoretical x-coord (raw).
  final List<List<double>> theos;

  /// Per series, per point: observed y-coord (raw).
  final List<List<double>> obs;
  final double left;
  final double right;
  final double top;
  final double bottom;
  final double lo;
  final double hi;

  static _QQLayout? compute({
    required List<ViolinDatum> data,
    required Size size,
    required QQDistribution distribution,
  }) {
    if (size.width <= 0 || size.height <= 0) return null;
    if (data.isEmpty) return null;

    const leftPad = 36.0;
    const rightPad = 16.0;
    const topPad = 16.0;
    const bottomPad = 32.0;
    const left = leftPad;
    final right = size.width - rightPad;
    const top = topPad;
    final bottom = size.height - bottomPad;

    final theos = <List<double>>[];
    final obs = <List<double>>[];
    var gLo = double.infinity;
    var gHi = -double.infinity;
    for (final d in data) {
      if (d.values.isEmpty) {
        theos.add([]);
        obs.add([]);
        continue;
      }
      final sorted = [...d.values]..sort();
      final n = sorted.length;
      final mean = sorted.reduce((a, b) => a + b) / n;
      var sq = 0.0;
      for (final v in sorted) {
        sq += (v - mean) * (v - mean);
      }
      final stdev = math.sqrt(sq / n);
      final tArr = <double>[];
      final oArr = <double>[];
      for (var i = 0; i < n; i++) {
        final p = (i + 0.5) / n;
        double th;
        switch (distribution) {
          case QQDistribution.normal:
            th = mean + stdev * _normalQuantile(p);
          case QQDistribution.uniform:
            // Rescale to sample range [min, max].
            th = sorted.first + p * (sorted.last - sorted.first);
        }
        tArr.add(th);
        oArr.add(sorted[i]);
        if (th < gLo) gLo = th;
        if (th > gHi) gHi = th;
        if (sorted[i] < gLo) gLo = sorted[i];
        if (sorted[i] > gHi) gHi = sorted[i];
      }
      theos.add(tArr);
      obs.add(oArr);
    }
    if (gLo == double.infinity) return null;
    if (gHi == gLo) gHi = gLo + 1;
    final pad = (gHi - gLo) * 0.05;
    gLo -= pad;
    gHi += pad;

    final points = <List<Offset>>[];
    for (var i = 0; i < theos.length; i++) {
      final pts = <Offset>[];
      for (var j = 0; j < theos[i].length; j++) {
        final tx = (theos[i][j] - gLo) / (gHi - gLo);
        final ty = (obs[i][j] - gLo) / (gHi - gLo);
        pts.add(
          Offset(
            left + tx * (right - left),
            bottom - ty * (bottom - top),
          ),
        );
      }
      points.add(pts);
    }

    return _QQLayout(
      points: points,
      theos: theos,
      obs: obs,
      left: left,
      right: right,
      top: top,
      bottom: bottom,
      lo: gLo,
      hi: gHi,
    );
  }

  /// Inverse standard-normal CDF — Beasley-Springer-Moro
  /// approximation. Accurate to ~1e-7 across [1e-6, 1 - 1e-6].
  static double _normalQuantile(double p) {
    const a = [
      -3.969683028665376e+01,
      2.209460984245205e+02,
      -2.759285104469687e+02,
      1.383577518672690e+02,
      -3.066479806614716e+01,
      2.506628277459239e+00,
    ];
    const b = [
      -5.447609879822406e+01,
      1.615858368580409e+02,
      -1.556989798598866e+02,
      6.680131188771972e+01,
      -1.328068155288572e+01,
    ];
    const c = [
      -7.784894002430293e-03,
      -3.223964580411365e-01,
      -2.400758277161838e+00,
      -2.549732539343734e+00,
      4.374664141464968e+00,
      2.938163982698783e+00,
    ];
    const d = [
      7.784695709041462e-03,
      3.224671290700398e-01,
      2.445134137142996e+00,
      3.754408661907416e+00,
    ];
    const pLow = 0.02425;
    const pHigh = 1 - pLow;
    final pp = p.clamp(1e-12, 1 - 1e-12);
    if (pp < pLow) {
      final q = math.sqrt(-2 * math.log(pp));
      return (((((c[0] * q + c[1]) * q + c[2]) * q + c[3]) * q + c[4]) * q +
              c[5]) /
          ((((d[0] * q + d[1]) * q + d[2]) * q + d[3]) * q + 1);
    } else if (pp <= pHigh) {
      final q = pp - 0.5;
      final r = q * q;
      return (((((a[0] * r + a[1]) * r + a[2]) * r + a[3]) * r + a[4]) * r +
              a[5]) *
          q /
          (((((b[0] * r + b[1]) * r + b[2]) * r + b[3]) * r + b[4]) * r + 1);
    } else {
      final q = math.sqrt(-2 * math.log(1 - pp));
      return -(((((c[0] * q + c[1]) * q + c[2]) * q + c[3]) * q + c[4]) * q +
              c[5]) /
          ((((d[0] * q + d[1]) * q + d[2]) * q + d[3]) * q + 1);
    }
  }
}

class _QQPainter extends CustomPainter {
  _QQPainter({
    required this.data,
    required this.colors,
    required this.distribution,
    required this.dotRadius,
    required this.dotOpacity,
    required this.referenceLine,
    required this.referenceWidth,
    required this.showAxisLabels,
    required this.gridColor,
    required this.axisStyle,
    required this.fg,
    required this.animation,
    required this.progress,
    required this.valueFormatter,
  });

  final List<ViolinDatum> data;
  final List<Color> colors;
  final QQDistribution distribution;
  final double dotRadius;
  final double dotOpacity;
  final bool referenceLine;
  final double referenceWidth;
  final bool showAxisLabels;
  final Color gridColor;
  final TextStyle axisStyle;
  final Color fg;
  final QQPlotAnimation animation;
  final double progress;
  final String Function(double) valueFormatter;

  @override
  void paint(Canvas canvas, Size size) {
    final layout = _QQLayout.compute(
      data: data,
      size: size,
      distribution: distribution,
    );
    if (layout == null) return;

    // Plot frame.
    canvas.drawRect(
      Rect.fromLTRB(layout.left, layout.top, layout.right, layout.bottom),
      Paint()
        ..color = gridColor.withValues(alpha: 0.5)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.5,
    );

    // Reference line y=x.
    if (referenceLine) {
      double refT;
      switch (animation) {
        case QQPlotAnimation.sequential:
          refT = (progress / 0.4).clamp(0.0, 1.0);
        case QQPlotAnimation.fade:
          refT = progress;
        case QQPlotAnimation.scatter:
          refT = (progress / 0.4).clamp(0.0, 1.0);
      }
      // Reference line spans (lo, lo) → (hi, hi). Project both ends.
      final p0 = Offset(
        layout.left,
        layout.bottom,
      );
      final p1 = Offset(
        layout.right,
        layout.top,
      );
      final endX = p0.dx + (p1.dx - p0.dx) * refT;
      final endY = p0.dy + (p1.dy - p0.dy) * refT;
      canvas.drawLine(
        p0,
        Offset(endX, endY),
        Paint()
          ..color = fg.withValues(alpha: 0.55)
          ..strokeWidth = referenceWidth
          ..strokeCap = StrokeCap.round,
      );
    }

    final rng = math.Random(11);

    for (var si = 0; si < data.length; si++) {
      final c = data[si].color ?? colors[si];
      final pts = layout.points[si];
      for (var i = 0; i < pts.length; i++) {
        final pos = pts[i];
        // Per-dot animation.
        double scale;
        var shifted = pos;
        double opacity;
        switch (animation) {
          case QQPlotAnimation.sequential:
            // Reference draws 0..0.4, dots from 0.4..1.0.
            final delay = 0.4 + (i / pts.length) * 0.5;
            final t = ((progress - delay) / (1 - delay)).clamp(0.0, 1.0);
            scale = t;
            opacity = 1.0;
          case QQPlotAnimation.fade:
            scale = 1.0;
            opacity = progress;
          case QQPlotAnimation.scatter:
            final delay = (i / pts.length) * 0.4;
            final t = ((progress - delay) / (1 - delay)).clamp(0.0, 1.0);
            shifted = Offset(
              pos.dx + (1 - t) * 60 * (rng.nextDouble() - 0.5),
              pos.dy + (1 - t) * 60 * (rng.nextDouble() - 0.5),
            );
            scale = 1.0;
            opacity = t;
        }
        if (scale <= 0 || opacity <= 0) continue;
        canvas.drawCircle(
          shifted,
          dotRadius * scale,
          Paint()..color = c.withValues(alpha: dotOpacity * opacity),
        );
      }
    }

    // Axis range labels.
    if (!showAxisLabels) return;
    if (progress < 0.5) return;
    final fadeRaw = ((progress - 0.5) / 0.5).clamp(0.0, 1.0);
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

    drawText(valueFormatter(layout.lo), Offset(layout.left, layout.bottom + 4));
    drawText(
      valueFormatter(layout.hi),
      Offset(layout.right, layout.bottom + 4),
      right: true,
    );
    drawText(valueFormatter(layout.hi), Offset(4, layout.top - 4));
    drawText(valueFormatter(layout.lo), Offset(4, layout.bottom - 12));
    // Axis titles.
    final titleStyle = lblStyle.copyWith(fontWeight: FontWeight.w600);
    final theTitle = distribution == QQDistribution.normal
        ? 'Theoretical (normal)'
        : 'Theoretical (uniform)';
    final tpx = TextPainter(
      text: TextSpan(text: theTitle, style: titleStyle),
      textDirection: TextDirection.ltr,
    )..layout();
    tpx.paint(
      canvas,
      Offset(
        (layout.left + layout.right) / 2 - tpx.width / 2,
        layout.bottom + 16,
      ),
    );
  }

  @override
  bool shouldRepaint(covariant _QQPainter old) =>
      old.progress != progress ||
      old.data != data ||
      old.distribution != distribution ||
      old.animation != animation;
}
