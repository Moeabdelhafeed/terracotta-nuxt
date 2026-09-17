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
export 'chart_models.dart' show ChartStyle, BeeswarmAnimation;

/// Beeswarm — non-overlapping dots arranged so the swarm shape
/// reveals distribution density without bin boundaries. Reuses
/// [ViolinDatum] (one swarm per category, raw values).
///
/// Each dot lands at its true y (value); x is offset laterally
/// through collision-avoidance so dots never overlap.
///
/// ```dart
/// GlobalBeeswarm(
///   data: [
///     ViolinDatum(label: 'A', values: [1.2, 1.4, 1.5, ...]),
///     ViolinDatum(label: 'B', values: [...]),
///   ],
/// )
/// ```
class GlobalBeeswarm extends StatelessWidget {
  const GlobalBeeswarm({
    required this.data,
    this.style = ChartStyle.standard,
    this.animation = BeeswarmAnimation.pop,
    this.dotRadius = 3.0,
    this.dotOpacity = 0.85,
    this.dotRing = false,
    this.valueFormatter,
    super.key,
  });

  final List<ViolinDatum> data;
  final ChartStyle style;
  final BeeswarmAnimation animation;
  final double dotRadius;
  final double dotOpacity;
  final bool dotRing;
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
                      painter: _BeePainter(
                        data: data,
                        colors: palette,
                        dotRadius: dotRadius,
                        dotOpacity: dotOpacity,
                        dotRing: dotRing,
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
    final layout = _BeeLayout.compute(
      data: data,
      size: size,
      dotRadius: dotRadius,
    );
    if (layout == null) return const [];
    var bestI = -1;
    var bestJ = -1;
    var bestDist = double.infinity;
    for (var i = 0; i < layout.dots.length; i++) {
      for (var j = 0; j < layout.dots[i].length; j++) {
        final d = (layout.dots[i][j].$1 - pos).distance;
        if (d < bestDist) {
          bestDist = d;
          bestI = i;
          bestJ = j;
        }
      }
    }
    if (bestI < 0 || bestDist > dotRadius + 8) return const [];
    final v = layout.dots[bestI][bestJ].$2;
    return [
      TooltipEntry(
        label: data[bestI].label,
        value: fmt(v),
        color: data[bestI].color ?? palette[bestI],
      ),
    ];
  }
}

class _BeeLayout {
  _BeeLayout({
    required this.dots,
    required this.centers,
    required this.violinW,
    required this.gMin,
    required this.gMax,
    required this.top,
    required this.bottom,
  });

  /// Per category, list of (center, value) for each dot.
  final List<List<(Offset, double)>> dots;
  final List<double> centers;
  final double violinW;
  final double gMin;
  final double gMax;
  final double top;
  final double bottom;

  static _BeeLayout? compute({
    required List<ViolinDatum> data,
    required Size size,
    required double dotRadius,
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
    final violinW = colW * 0.78;
    const top = topPad;
    final bottom = size.height - bottomPad;

    double yFor(double v) {
      final t = (v - gMin) / (gMax - gMin);
      return bottom - t * (bottom - top);
    }

    final dots = <List<(Offset, double)>>[];
    final spacing = dotRadius * 2 + 0.6;
    for (var ci = 0; ci < n; ci++) {
      final cx = centers[ci];
      // Sort values low → high; pack from center outward.
      final sorted = [...data[ci].values]..sort();
      final placed = <Offset>[];
      for (final v in sorted) {
        final y = yFor(v);
        // Try x offsets in expanding sequence: 0, +s, -s, +2s, -2s ...
        for (var step = 0; step < 200; step++) {
          // Alternate sign per step.
          final lateral = ((step + 1) ~/ 2) * spacing * (step.isEven ? 1 : -1);
          final cand = Offset(cx + lateral, y);
          // Stay within column bounds.
          if ((cand.dx - cx).abs() > violinW / 2) continue;
          var collision = false;
          for (final p in placed) {
            final dx = p.dx - cand.dx;
            final dy = p.dy - cand.dy;
            if (dx * dx + dy * dy < spacing * spacing) {
              collision = true;
              break;
            }
          }
          if (!collision) {
            placed.add(cand);
            break;
          }
        }
      }
      dots.add([
        for (var i = 0; i < placed.length; i++) (placed[i], sorted[i]),
      ]);
    }

    return _BeeLayout(
      dots: dots,
      centers: centers,
      violinW: violinW,
      gMin: gMin,
      gMax: gMax,
      top: top,
      bottom: bottom,
    );
  }
}

class _BeePainter extends CustomPainter {
  _BeePainter({
    required this.data,
    required this.colors,
    required this.dotRadius,
    required this.dotOpacity,
    required this.dotRing,
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
  final bool dotRing;
  final Color gridColor;
  final TextStyle axisStyle;
  final BeeswarmAnimation animation;
  final double progress;
  final String Function(double) valueFormatter;

  @override
  void paint(Canvas canvas, Size size) {
    final layout = _BeeLayout.compute(
      data: data,
      size: size,
      dotRadius: dotRadius,
    );
    if (layout == null) return;

    canvas.drawLine(
      Offset(0, layout.bottom),
      Offset(size.width, layout.bottom),
      Paint()
        ..color = gridColor
        ..strokeWidth = 0.5,
    );

    final rng = math.Random(7);
    for (var ci = 0; ci < data.length; ci++) {
      final c = data[ci].color ?? colors[ci];
      final dots = layout.dots[ci];
      for (var i = 0; i < dots.length; i++) {
        final (pos, _) = dots[i];
        // Per-dot stagger.
        final delay = (i / dots.length) * 0.4;
        final t = ((progress - delay) / (1 - delay)).clamp(0.0, 1.0);
        double scale;
        var shifted = pos;
        double opacity;
        switch (animation) {
          case BeeswarmAnimation.pop:
            scale = t;
            opacity = 1.0;
          case BeeswarmAnimation.fade:
            scale = 1.0;
            opacity = progress;
          case BeeswarmAnimation.fall:
            scale = 1.0;
            shifted = Offset(
              pos.dx,
              pos.dy - (1 - t) * 24 * (rng.nextDouble() + 0.5),
            );
            opacity = t;
        }
        if (scale <= 0 || opacity <= 0) continue;
        canvas.drawCircle(
          shifted,
          dotRadius * scale,
          Paint()..color = c.withValues(alpha: dotOpacity * opacity),
        );
        if (dotRing) {
          canvas.drawCircle(
            shifted,
            dotRadius * scale,
            Paint()
              ..color = Colors.white.withValues(alpha: opacity)
              ..style = PaintingStyle.stroke
              ..strokeWidth = 1.0,
          );
        }
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
        )..layout(maxWidth: layout.violinW + 24);
        tp.paint(
          canvas,
          Offset(layout.centers[ci] - tp.width / 2, layout.bottom + 6),
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _BeePainter old) =>
      old.progress != progress ||
      old.data != data ||
      old.animation != animation;
}
