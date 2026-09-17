import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/extensions/theme_colors_extension.dart';
import '../../../core/localization/number_formatter.dart';
import 'chart_data.dart';
import 'chart_internals.dart';
import 'chart_models.dart';
import 'chart_tooltip_overlay.dart';
import 'custom_paint_tooltip.dart';

export 'chart_data.dart' show ViolinDatum;
export 'chart_models.dart' show ChartStyle, ViolinAnimation;

/// Violin chart — distribution shape per category, mirrored on a
/// vertical centerline. Width at any y is proportional to the
/// kernel-density estimate at that value. An optional inner box
/// shows the median + IQR (Q1, Q3).
///
/// ```dart
/// GlobalViolin(
///   data: [
///     ViolinDatum(label: 'A', values: [1.2, 1.4, 1.5, ...]),
///     ViolinDatum(label: 'B', values: [...]),
///   ],
/// )
/// ```
class GlobalViolin extends StatelessWidget {
  const GlobalViolin({
    required this.data,
    this.style = ChartStyle.standard,
    this.animation = ViolinAnimation.spread,
    this.bandwidth,
    this.showBox = true,
    this.showMedian = true,
    this.fillOpacity = 0.55,
    this.strokeWidth = 1.4,
    this.kdeSteps = 64,
    this.valueFormatter,
    super.key,
  });

  final List<ViolinDatum> data;
  final ChartStyle style;
  final ViolinAnimation animation;

  /// Kernel bandwidth (smoothing factor). When null, uses
  /// Silverman's rule per-violin.
  final double? bandwidth;

  /// Render the inner Q1-Q3 box.
  final bool showBox;

  /// Render the median tick.
  final bool showMedian;

  final double fillOpacity;
  final double strokeWidth;

  /// KDE sample count. Higher = smoother but slower.
  final int kdeSteps;

  final String Function(double)? valueFormatter;

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) return const SizedBox.shrink();
    final palette = resolveSeriesColors(context, style, data.length);
    final fmt = valueFormatter ?? (v) => AppNumbers.compact(v);
    final axisStyle = resolveAxisLabelStyle(context, style);
    final gridColor = resolveGridColor(context, style);
    final fg = context.textColors.primary;

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
                    painter: _ViolinPainter(
                      data: data,
                      colors: palette,
                      bandwidth: bandwidth,
                      showBox: showBox,
                      showMedian: showMedian,
                      fillOpacity: fillOpacity,
                      strokeWidth: strokeWidth,
                      kdeSteps: kdeSteps,
                      gridColor: gridColor,
                      axisStyle: axisStyle,
                      fg: fg,
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
    );
  }

  List<TooltipEntry> _hitTest(
    Offset pos,
    Size size,
    List<Color> palette,
    String Function(double) fmt,
  ) {
    final layout = _ViolinLayout.compute(
      data: data,
      size: size,
      kdeSteps: kdeSteps,
      bandwidth: bandwidth,
    );
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
    if (bestI < 0 || bestDx > layout.violinW / 2 + 12) return const [];
    final stats = layout.stats[bestI];
    final c = data[bestI].color ?? palette[bestI];
    return [
      TooltipEntry(
        label: data[bestI].label,
        value:
            'med ${fmt(stats.median)} · IQR ${fmt(stats.q1)}–${fmt(stats.q3)}',
        color: c,
      ),
    ];
  }
}

class _ViolinStats {
  _ViolinStats({
    required this.min,
    required this.max,
    required this.median,
    required this.q1,
    required this.q3,
  });
  final double min;
  final double max;
  final double median;
  final double q1;
  final double q3;
}

class _ViolinKde {
  _ViolinKde({required this.densities, required this.maxDensity});
  final List<double> densities;
  final double maxDensity;
}

class _ViolinLayout {
  _ViolinLayout({
    required this.centers,
    required this.violinW,
    required this.stats,
    required this.kdes,
    required this.gMin,
    required this.gMax,
    required this.top,
    required this.bottom,
  });

  final List<double> centers;
  final double violinW;
  final List<_ViolinStats> stats;
  final List<_ViolinKde> kdes;
  final double gMin;
  final double gMax;
  final double top;
  final double bottom;

  static _ViolinLayout? compute({
    required List<ViolinDatum> data,
    required Size size,
    required int kdeSteps,
    double? bandwidth,
  }) {
    if (size.width <= 0 || size.height <= 0) return null;
    if (data.isEmpty) return null;

    const leftPad = 32.0;
    const rightPad = 16.0;
    const topPad = 16.0;
    const bottomPad = 28.0;
    final usableW = size.width - leftPad - rightPad;
    final usableH = size.height - topPad - bottomPad;
    if (usableW <= 0 || usableH <= 0) return null;

    var gMin = double.infinity;
    var gMax = -double.infinity;
    final stats = <_ViolinStats>[];
    for (final d in data) {
      if (d.values.isEmpty) {
        stats.add(
          _ViolinStats(min: 0, max: 1, median: 0.5, q1: 0.25, q3: 0.75),
        );
        continue;
      }
      final sorted = [...d.values]..sort();
      final n = sorted.length;
      final lo = sorted.first;
      final hi = sorted.last;
      if (lo < gMin) gMin = lo;
      if (hi > gMax) gMax = hi;
      double percentile(double p) {
        final idx = ((n - 1) * p).clamp(0, n - 1).toDouble();
        final a = idx.floor();
        final b = idx.ceil();
        return sorted[a] + (sorted[b] - sorted[a]) * (idx - a);
      }

      stats.add(
        _ViolinStats(
          min: lo,
          max: hi,
          median: d.median ?? percentile(0.5),
          q1: d.q1 ?? percentile(0.25),
          q3: d.q3 ?? percentile(0.75),
        ),
      );
    }
    if (gMin == double.infinity || gMax == -double.infinity) return null;
    if (gMax == gMin) gMax = gMin + 1;
    final pad = (gMax - gMin) * 0.05;
    gMin -= pad;
    gMax += pad;

    final n = data.length;
    final colW = usableW / n;
    final centers = List<double>.generate(n, (i) => leftPad + colW * (i + 0.5));
    final violinW = colW * 0.7;

    // KDE per violin.
    final kdes = <_ViolinKde>[];
    for (var i = 0; i < n; i++) {
      final d = data[i];
      if (d.values.isEmpty) {
        kdes.add(
          _ViolinKde(densities: List.filled(kdeSteps, 0), maxDensity: 1),
        );
        continue;
      }
      // Silverman's rule of thumb for bandwidth.
      double effectiveBw;
      if (bandwidth != null) {
        effectiveBw = bandwidth;
      } else {
        final mean = d.values.reduce((a, b) => a + b) / d.values.length;
        var sumSq = 0.0;
        for (final v in d.values) {
          sumSq += (v - mean) * (v - mean);
        }
        final stdev = math.sqrt(sumSq / d.values.length);
        effectiveBw =
            1.06 * stdev * math.pow(d.values.length, -1 / 5).toDouble();
        if (effectiveBw <= 0) {
          effectiveBw = (gMax - gMin) / 50;
        }
      }
      // Sample density across full y-range.
      final densities = <double>[];
      double maxD = 0;
      for (var k = 0; k < kdeSteps; k++) {
        final t = k / (kdeSteps - 1);
        final y = gMin + (gMax - gMin) * t;
        var sum = 0.0;
        for (final v in d.values) {
          final u = (y - v) / effectiveBw;
          sum += math.exp(-0.5 * u * u);
        }
        final dens =
            sum / (d.values.length * effectiveBw * math.sqrt(math.pi * 2));
        densities.add(dens);
        if (dens > maxD) maxD = dens;
      }
      kdes.add(
        _ViolinKde(densities: densities, maxDensity: maxD == 0 ? 1 : maxD),
      );
    }

    return _ViolinLayout(
      centers: centers,
      violinW: violinW,
      stats: stats,
      kdes: kdes,
      gMin: gMin,
      gMax: gMax,
      top: topPad,
      bottom: size.height - bottomPad,
    );
  }
}

class _ViolinPainter extends CustomPainter {
  _ViolinPainter({
    required this.data,
    required this.colors,
    required this.bandwidth,
    required this.showBox,
    required this.showMedian,
    required this.fillOpacity,
    required this.strokeWidth,
    required this.kdeSteps,
    required this.gridColor,
    required this.axisStyle,
    required this.fg,
    required this.animation,
    required this.progress,
  });

  final List<ViolinDatum> data;
  final List<Color> colors;
  final double? bandwidth;
  final bool showBox;
  final bool showMedian;
  final double fillOpacity;
  final double strokeWidth;
  final int kdeSteps;
  final Color gridColor;
  final TextStyle axisStyle;
  final Color fg;
  final ViolinAnimation animation;
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final layout = _ViolinLayout.compute(
      data: data,
      size: size,
      kdeSteps: kdeSteps,
      bandwidth: bandwidth,
    );
    if (layout == null) return;

    final span = layout.gMax - layout.gMin;
    double yFor(double v) {
      final t = (v - layout.gMin) / span;
      return layout.bottom - t * (layout.bottom - layout.top);
    }

    // Faint gridlines at min / median-of-medians / max.
    final guidePaint = Paint()
      ..color = gridColor.withValues(alpha: 0.5)
      ..strokeWidth = 0.5;
    canvas.drawLine(
      Offset(0, layout.bottom),
      Offset(size.width, layout.bottom),
      guidePaint,
    );

    for (var i = 0; i < data.length; i++) {
      final cx = layout.centers[i];
      final stats = layout.stats[i];
      final kde = layout.kdes[i];
      final c = data[i].color ?? colors[i];
      final halfW = layout.violinW / 2;

      // Per-violin animation.
      final rowDelay = i / data.length * 0.2;
      final rowT = ((progress - rowDelay) / (1 - rowDelay)).clamp(0.0, 1.0);
      var widthScale = 1.0;
      var yScale = 1.0;
      var opacity = 1.0;
      switch (animation) {
        case ViolinAnimation.spread:
          widthScale = rowT;
        case ViolinAnimation.rise:
          yScale = rowT;
        case ViolinAnimation.fade:
          opacity = progress;
      }

      // Build symmetric path: right edge top→bottom, left edge bottom→top.
      final path = Path();
      final n = kde.densities.length;
      for (var k = 0; k < n; k++) {
        final t = k / (n - 1);
        final v = layout.gMin + span * t;
        final yBase = yFor(v);
        final yAnimated = layout.bottom - (layout.bottom - yBase) * yScale;
        final w = (kde.densities[k] / kde.maxDensity) * halfW * widthScale;
        if (k == 0) {
          path.moveTo(cx + w, yAnimated);
        } else {
          path.lineTo(cx + w, yAnimated);
        }
      }
      for (var k = n - 1; k >= 0; k--) {
        final t = k / (n - 1);
        final v = layout.gMin + span * t;
        final yBase = yFor(v);
        final yAnimated = layout.bottom - (layout.bottom - yBase) * yScale;
        final w = (kde.densities[k] / kde.maxDensity) * halfW * widthScale;
        path.lineTo(cx - w, yAnimated);
      }
      path.close();

      canvas.drawPath(
        path,
        Paint()..color = c.withValues(alpha: fillOpacity * opacity),
      );
      canvas.drawPath(
        path,
        Paint()
          ..color = c.withValues(alpha: opacity)
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeWidth
          ..strokeJoin = StrokeJoin.round,
      );

      // Inner Q1-Q3 box.
      if (showBox) {
        final yQ1 = yFor(stats.q1);
        final yQ3 = yFor(stats.q3);
        final yQ1Anim = layout.bottom - (layout.bottom - yQ1) * yScale;
        final yQ3Anim = layout.bottom - (layout.bottom - yQ3) * yScale;
        final boxW = halfW * 0.32 * widthScale;
        final box = Rect.fromLTRB(
          cx - boxW,
          math.min(yQ1Anim, yQ3Anim),
          cx + boxW,
          math.max(yQ1Anim, yQ3Anim),
        );
        canvas.drawRect(
          box,
          Paint()..color = fg.withValues(alpha: 0.85 * opacity),
        );
      }

      // Median tick.
      if (showMedian) {
        final yMed = yFor(stats.median);
        final yMedAnim = layout.bottom - (layout.bottom - yMed) * yScale;
        final tickW = halfW * 0.5 * widthScale;
        canvas.drawLine(
          Offset(cx - tickW, yMedAnim),
          Offset(cx + tickW, yMedAnim),
          Paint()
            ..color = Colors.white.withValues(alpha: opacity)
            ..strokeWidth = 2.0
            ..strokeCap = StrokeCap.round,
        );
      }

      // Category label at bottom.
      if (progress > 0.4) {
        final fadeRaw = ((progress - 0.4) / 0.6).clamp(0.0, 1.0);
        final fade = Curves.easeOutCubic.transform(fadeRaw);
        final tp = TextPainter(
          text: TextSpan(
            text: data[i].label,
            style: axisStyle.copyWith(
              color: axisStyle.color?.withValues(alpha: fade),
              fontWeight: FontWeight.w600,
            ),
          ),
          textDirection: TextDirection.ltr,
          maxLines: 1,
          ellipsis: '…',
        )..layout(maxWidth: layout.violinW + 8);
        tp.paint(
          canvas,
          Offset(cx - tp.width / 2, layout.bottom + 6),
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _ViolinPainter old) =>
      old.progress != progress ||
      old.data != data ||
      old.animation != animation ||
      old.showBox != showBox ||
      old.showMedian != showMedian;
}
