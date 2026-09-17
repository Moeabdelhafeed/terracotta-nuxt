import 'package:flutter/material.dart';

import '../../../core/extensions/theme_colors_extension.dart';
import '../../../core/localization/number_formatter.dart';
import 'chart_data.dart';
import 'chart_internals.dart';
import 'chart_models.dart';
import 'chart_tooltip_overlay.dart';
import 'chart_zoom_pan.dart';
import 'custom_paint_tooltip.dart';

export 'chart_data.dart' show Candle;
export 'chart_models.dart' show ChartStyle, FinancialChartAnimation;

/// Kagi chart — line that flips direction when price reverses by
/// `reversal`. Stroke thickness/color flips between yang (bold,
/// up-color) and yin (thin, down-color) when crossing the prior
/// swing high / low.
///
/// Accepts [Candle] OHLC input; uses each candle's close.
///
/// ```dart
/// GlobalKagi(
///   candles: [Candle(...), ...],
///   reversal: 1.5,
/// )
/// ```
class GlobalKagi extends StatelessWidget {
  const GlobalKagi({
    required this.candles,
    required this.reversal,
    this.style = ChartStyle.standard,
    this.animation = FinancialChartAnimation.sequential,
    this.yangWidth = 3.5,
    this.yinWidth = 1.4,
    this.yangColor,
    this.yinColor,
    this.showAxisLabels = true,
    this.valueFormatter,
    super.key,
  });

  final List<Candle> candles;

  /// Reversal threshold (price units). When price reverses by this
  /// amount the line direction flips.
  final double reversal;

  final ChartStyle style;
  final FinancialChartAnimation animation;
  final double yangWidth;
  final double yinWidth;
  final Color? yangColor;
  final Color? yinColor;
  final bool showAxisLabels;
  final String Function(double)? valueFormatter;

  @override
  Widget build(BuildContext context) {
    if (candles.isEmpty || reversal <= 0) return const SizedBox.shrink();
    final yang = yangColor ?? context.statusColors.success;
    final yin = yinColor ?? context.statusColors.error;
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
                hitTest: (pos, size) => _hitTest(pos, size, yang, yin, fmt),
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
                      painter: _KagiPainter(
                        candles: candles,
                        reversal: reversal,
                        yangWidth: yangWidth,
                        yinWidth: yinWidth,
                        yangColor: yang,
                        yinColor: yin,
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
    Color yang,
    Color yin,
    String Function(double) fmt,
  ) {
    final layout = _KagiLayout.compute(
      candles: candles,
      reversal: reversal,
      size: size,
    );
    if (layout == null) return const [];
    var bestI = -1;
    var bestDist = double.infinity;
    for (var i = 0; i < layout.points.length; i++) {
      final d = (layout.points[i] - pos).distance;
      if (d < bestDist) {
        bestDist = d;
        bestI = i;
      }
    }
    if (bestI < 0 || bestDist > 18) return const [];
    return [
      TooltipEntry(
        label: 'Kagi turn',
        value: fmt(layout.prices[bestI]),
        color: layout.yangFlags[bestI] ? yang : yin,
      ),
    ];
  }
}

class _KagiLayout {
  _KagiLayout({
    required this.points,
    required this.prices,
    required this.yangFlags,
    required this.priceMin,
    required this.priceMax,
    required this.left,
    required this.right,
    required this.top,
    required this.bottom,
  });

  final List<Offset> points;
  final List<double> prices;
  final List<bool> yangFlags;
  final double priceMin;
  final double priceMax;
  final double left;
  final double right;
  final double top;
  final double bottom;

  static _KagiLayout? compute({
    required List<Candle> candles,
    required double reversal,
    required Size size,
  }) {
    if (size.width <= 0 || size.height <= 0) return null;
    if (candles.isEmpty) return null;

    // Build kagi turns: maintain extreme; flip when reverse > reversal.
    final prices = <double>[candles.first.close];
    final dirs = <int>[0];
    var dir = 0;
    var extreme = candles.first.close;
    for (var i = 1; i < candles.length; i++) {
      final p = candles[i].close;
      if (dir == 0) {
        if ((p - extreme).abs() >= reversal) {
          dir = p > extreme ? 1 : -1;
          prices.add(p);
          dirs.add(dir);
          extreme = p;
        }
      } else if (dir > 0) {
        if (p > extreme) {
          extreme = p;
          prices.last = p;
        } else if (extreme - p >= reversal) {
          dir = -1;
          prices.add(p);
          dirs.add(dir);
          extreme = p;
        }
      } else {
        if (p < extreme) {
          extreme = p;
          prices.last = p;
        } else if (p - extreme >= reversal) {
          dir = 1;
          prices.add(p);
          dirs.add(dir);
          extreme = p;
        }
      }
    }

    if (prices.length < 2) return null;
    var pMin = double.infinity;
    var pMax = -double.infinity;
    for (final p in prices) {
      if (p < pMin) pMin = p;
      if (p > pMax) pMax = p;
    }
    if (pMin == pMax) pMax = pMin + 1;
    final pad = (pMax - pMin) * 0.05;
    pMin -= pad;
    pMax += pad;

    const leftPad = 36.0;
    const rightPad = 12.0;
    const topPad = 16.0;
    const bottomPad = 28.0;
    const left = leftPad;
    final right = size.width - rightPad;
    const top = topPad;
    final bottom = size.height - bottomPad;

    final points = <Offset>[];
    for (var i = 0; i < prices.length; i++) {
      final t = i / (prices.length - 1);
      final x = left + t * (right - left);
      final y = bottom - (prices[i] - pMin) / (pMax - pMin) * (bottom - top);
      points.add(Offset(x, y));
    }

    // Compute yang/yin flag per segment based on prior swing crossings.
    // Simplification: yang while price > prior swing high, else yin.
    final yangFlags = List<bool>.filled(prices.length, true);
    var lastSwingHigh = prices.first;
    var yang = true;
    for (var i = 1; i < prices.length; i++) {
      if (dirs[i] == 1) {
        if (prices[i] > lastSwingHigh) {
          yang = true;
          lastSwingHigh = prices[i];
        }
      } else if (dirs[i] == -1) {
        if (prices[i] < lastSwingHigh) {
          yang = false;
        }
      }
      yangFlags[i] = yang;
    }

    return _KagiLayout(
      points: points,
      prices: prices,
      yangFlags: yangFlags,
      priceMin: pMin,
      priceMax: pMax,
      left: left,
      right: right,
      top: top,
      bottom: bottom,
    );
  }
}

class _KagiPainter extends CustomPainter {
  _KagiPainter({
    required this.candles,
    required this.reversal,
    required this.yangWidth,
    required this.yinWidth,
    required this.yangColor,
    required this.yinColor,
    required this.showAxisLabels,
    required this.gridColor,
    required this.axisStyle,
    required this.animation,
    required this.progress,
    required this.valueFormatter,
  });

  final List<Candle> candles;
  final double reversal;
  final double yangWidth;
  final double yinWidth;
  final Color yangColor;
  final Color yinColor;
  final bool showAxisLabels;
  final Color gridColor;
  final TextStyle axisStyle;
  final FinancialChartAnimation animation;
  final double progress;
  final String Function(double) valueFormatter;

  @override
  void paint(Canvas canvas, Size size) {
    final layout = _KagiLayout.compute(
      candles: candles,
      reversal: reversal,
      size: size,
    );
    if (layout == null) return;

    canvas.drawLine(
      Offset(layout.left, layout.bottom),
      Offset(layout.right, layout.bottom),
      Paint()
        ..color = gridColor
        ..strokeWidth = 0.5,
    );

    final n = layout.points.length;
    var rightCutoff = layout.right;
    var opacity = 1.0;
    if (animation == FinancialChartAnimation.sequential) {
      rightCutoff = layout.left + (layout.right - layout.left) * progress;
    } else {
      opacity = progress;
    }

    // Draw kagi as orthogonal segments: vertical from prev y to curr y
    // at curr x, then horizontal back to next x. Stroke width depends
    // on yang/yin per segment.
    for (var i = 0; i < n - 1; i++) {
      final p0 = layout.points[i];
      final p1 = layout.points[i + 1];
      if (p0.dx > rightCutoff) break;
      final yang = layout.yangFlags[i + 1];
      final c = (yang ? yangColor : yinColor).withValues(alpha: opacity);
      final w = yang ? yangWidth : yinWidth;
      final paint = Paint()
        ..color = c
        ..strokeWidth = w
        ..strokeCap = StrokeCap.square
        ..style = PaintingStyle.stroke;
      // Vertical from p0 to (p0.x, p1.y).
      var v0 = p0;
      var v1 = Offset(p0.dx, p1.dy);
      if (v1.dx > rightCutoff) {
        // Skip if segment extends past cutoff.
        continue;
      }
      canvas.drawLine(v0, v1, paint);
      // Horizontal from (p0.x, p1.y) to (p1.x, p1.y), clamped.
      final endX = p1.dx.clamp(layout.left, rightCutoff);
      canvas.drawLine(v1, Offset(endX, p1.dy), paint);
    }

    if (!showAxisLabels) return;
    if (progress < 0.4) return;
    final fadeRaw = ((progress - 0.4) / 0.6).clamp(0.0, 1.0);
    final fade = Curves.easeOutCubic.transform(fadeRaw);
    final lblStyle = axisStyle.copyWith(
      color: axisStyle.color?.withValues(alpha: fade),
    );
    void drawText(String s, Offset at) {
      final tp = TextPainter(
        text: TextSpan(text: s, style: lblStyle),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, at);
    }

    drawText(valueFormatter(layout.priceMax), Offset(4, layout.top - 4));
    drawText(valueFormatter(layout.priceMin), Offset(4, layout.bottom - 12));
  }

  @override
  bool shouldRepaint(covariant _KagiPainter old) =>
      old.progress != progress ||
      old.candles != candles ||
      old.reversal != reversal ||
      old.animation != animation;
}
