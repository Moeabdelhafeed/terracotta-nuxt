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

/// Point-and-figure (P&F) chart — column-based price-only chart.
/// X columns of rising prices alternate with O columns of falling
/// prices. New column when price reverses by `reversal × boxSize`.
///
/// Strips out time entirely; columns spaced equidistantly on x.
///
/// ```dart
/// GlobalPointAndFigure(
///   candles: [...],
///   boxSize: 1.0,
///   reversal: 3,
/// )
/// ```
class GlobalPointAndFigure extends StatelessWidget {
  const GlobalPointAndFigure({
    required this.candles,
    required this.boxSize,
    this.reversal = 3,
    this.style = ChartStyle.standard,
    this.animation = FinancialChartAnimation.sequential,
    this.columnWidth = 14,
    this.markerStrokeWidth = 1.6,
    this.upColor,
    this.downColor,
    this.showAxisLabels = true,
    this.valueFormatter,
    super.key,
  });

  final List<Candle> candles;

  /// Price units per box.
  final double boxSize;

  /// Number of boxes that must reverse before flipping column.
  final int reversal;

  final ChartStyle style;
  final FinancialChartAnimation animation;
  final double columnWidth;
  final double markerStrokeWidth;
  final Color? upColor;
  final Color? downColor;
  final bool showAxisLabels;
  final String Function(double)? valueFormatter;

  @override
  Widget build(BuildContext context) {
    if (candles.isEmpty || boxSize <= 0) return const SizedBox.shrink();
    final upCol = upColor ?? context.statusColors.success;
    final downCol = downColor ?? context.statusColors.error;
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
                hitTest: (pos, size) =>
                    _hitTest(pos, size, upCol, downCol, fmt),
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
                      painter: _PnFPainter(
                        candles: candles,
                        boxSize: boxSize,
                        reversal: reversal,
                        columnWidth: columnWidth,
                        markerStrokeWidth: markerStrokeWidth,
                        upColor: upCol,
                        downColor: downCol,
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
    Color upCol,
    Color downCol,
    String Function(double) fmt,
  ) {
    final layout = _PnFLayout.compute(
      candles: candles,
      boxSize: boxSize,
      reversal: reversal,
      size: size,
      columnWidth: columnWidth,
    );
    if (layout == null) return const [];
    var bestI = -1;
    var bestDist = double.infinity;
    for (var i = 0; i < layout.markers.length; i++) {
      final c = layout.markers[i].center;
      final d = (c - pos).distance;
      if (d < bestDist) {
        bestDist = d;
        bestI = i;
      }
    }
    if (bestI < 0 || bestDist > columnWidth) return const [];
    final m = layout.markers[bestI];
    return [
      TooltipEntry(
        label: m.up ? 'X column' : 'O column',
        value: fmt(m.price),
        color: m.up ? upCol : downCol,
      ),
    ];
  }
}

class _PnFMarker {
  _PnFMarker({
    required this.center,
    required this.size,
    required this.up,
    required this.price,
  });
  final Offset center;
  final double size;
  final bool up;
  final double price;
}

class _PnFLayout {
  _PnFLayout({
    required this.markers,
    required this.priceMin,
    required this.priceMax,
    required this.left,
    required this.right,
    required this.top,
    required this.bottom,
  });

  final List<_PnFMarker> markers;
  final double priceMin;
  final double priceMax;
  final double left;
  final double right;
  final double top;
  final double bottom;

  static _PnFLayout? compute({
    required List<Candle> candles,
    required double boxSize,
    required int reversal,
    required Size size,
    required double columnWidth,
  }) {
    if (size.width <= 0 || size.height <= 0) return null;
    if (candles.isEmpty || boxSize <= 0) return null;

    // Build columns: each column is (up: bool, lowBox: int, highBox: int)
    // where boxes are integer multiples of boxSize from a reference.
    final basePrice = candles.first.close;
    int boxOf(double p) => ((p - basePrice) / boxSize).floor();
    final columns = <(bool up, int lo, int hi)>[];
    var currentUp = true;
    var currentLo = boxOf(candles.first.close);
    var currentHi = boxOf(candles.first.close);
    columns.add((currentUp, currentLo, currentHi));

    for (var i = 1; i < candles.length; i++) {
      final p = candles[i].close;
      final box = boxOf(p);
      if (currentUp) {
        if (box > currentHi) {
          currentHi = box;
          columns[columns.length - 1] = (currentUp, currentLo, currentHi);
        } else if (currentHi - box >= reversal) {
          // Flip to O.
          currentUp = false;
          currentLo = box;
          currentHi = currentHi - 1; // start O column one box below
          if (currentLo > currentHi) currentLo = currentHi;
          columns.add((currentUp, currentLo, currentHi));
        }
      } else {
        if (box < currentLo) {
          currentLo = box;
          columns[columns.length - 1] = (currentUp, currentLo, currentHi);
        } else if (box - currentLo >= reversal) {
          currentUp = true;
          currentHi = box;
          currentLo = currentLo + 1;
          if (currentLo > currentHi) currentLo = currentHi;
          columns.add((currentUp, currentLo, currentHi));
        }
      }
    }

    // Determine global price range.
    if (columns.isEmpty) return null;
    var loBox = columns.first.$2;
    var hiBox = columns.first.$3;
    for (final col in columns) {
      if (col.$2 < loBox) loBox = col.$2;
      if (col.$3 > hiBox) hiBox = col.$3;
    }
    if (hiBox == loBox) hiBox = loBox + 1;
    final pMin = basePrice + loBox * boxSize;
    final pMax = basePrice + (hiBox + 1) * boxSize;

    const leftPad = 36.0;
    const rightPad = 12.0;
    const topPad = 16.0;
    const bottomPad = 28.0;
    const left = leftPad;
    final right = size.width - rightPad;
    const top = topPad;
    final bottom = size.height - bottomPad;

    final boxCount = (hiBox - loBox + 1).clamp(1, 1000);
    final boxH = (bottom - top) / boxCount;
    final markerSize = (boxH * 0.65).clamp(3.0, columnWidth * 0.7);

    final markers = <_PnFMarker>[];
    for (var ci = 0; ci < columns.length; ci++) {
      final col = columns[ci];
      final cx = left + ci * columnWidth + columnWidth / 2;
      if (cx > right) break;
      for (var b = col.$2; b <= col.$3; b++) {
        final price = basePrice + (b + 0.5) * boxSize;
        final yIdx = hiBox - b;
        final y = top + yIdx * boxH + boxH / 2;
        markers.add(
          _PnFMarker(
            center: Offset(cx, y),
            size: markerSize,
            up: col.$1,
            price: price,
          ),
        );
      }
    }

    return _PnFLayout(
      markers: markers,
      priceMin: pMin,
      priceMax: pMax,
      left: left,
      right: right,
      top: top,
      bottom: bottom,
    );
  }
}

class _PnFPainter extends CustomPainter {
  _PnFPainter({
    required this.candles,
    required this.boxSize,
    required this.reversal,
    required this.columnWidth,
    required this.markerStrokeWidth,
    required this.upColor,
    required this.downColor,
    required this.showAxisLabels,
    required this.gridColor,
    required this.axisStyle,
    required this.animation,
    required this.progress,
    required this.valueFormatter,
  });

  final List<Candle> candles;
  final double boxSize;
  final int reversal;
  final double columnWidth;
  final double markerStrokeWidth;
  final Color upColor;
  final Color downColor;
  final bool showAxisLabels;
  final Color gridColor;
  final TextStyle axisStyle;
  final FinancialChartAnimation animation;
  final double progress;
  final String Function(double) valueFormatter;

  @override
  void paint(Canvas canvas, Size size) {
    final layout = _PnFLayout.compute(
      candles: candles,
      boxSize: boxSize,
      reversal: reversal,
      size: size,
      columnWidth: columnWidth,
    );
    if (layout == null) return;

    final n = layout.markers.length;
    for (var i = 0; i < n; i++) {
      final m = layout.markers[i];
      double opacity;
      switch (animation) {
        case FinancialChartAnimation.sequential:
          final delay = (i / n) * 0.7;
          opacity = ((progress - delay) / 0.3).clamp(0.0, 1.0);
        case FinancialChartAnimation.fade:
          opacity = progress;
      }
      if (opacity <= 0) continue;
      final c = (m.up ? upColor : downColor).withValues(alpha: opacity);
      final paint = Paint()
        ..color = c
        ..strokeWidth = markerStrokeWidth
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;
      if (m.up) {
        // X — diagonal cross.
        final s = m.size / 2;
        canvas.drawLine(
          Offset(m.center.dx - s, m.center.dy - s),
          Offset(m.center.dx + s, m.center.dy + s),
          paint,
        );
        canvas.drawLine(
          Offset(m.center.dx + s, m.center.dy - s),
          Offset(m.center.dx - s, m.center.dy + s),
          paint,
        );
      } else {
        // O — circle.
        canvas.drawCircle(m.center, m.size / 2, paint);
      }
    }

    if (!showAxisLabels) return;
    if (progress < 0.4) return;
    final fadeRaw = ((progress - 0.4) / 0.6).clamp(0.0, 1.0);
    final fade = Curves.easeOutCubic.transform(fadeRaw);
    final lblStyle = axisStyle.copyWith(
      color: axisStyle.color?.withValues(alpha: fade),
    );
    final guidePaint = Paint()
      ..color = gridColor
      ..strokeWidth = 0.5;
    canvas.drawLine(
      Offset(layout.left, layout.bottom),
      Offset(layout.right, layout.bottom),
      guidePaint,
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
  bool shouldRepaint(covariant _PnFPainter old) =>
      old.progress != progress ||
      old.candles != candles ||
      old.boxSize != boxSize ||
      old.reversal != reversal ||
      old.animation != animation;
}
