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

/// Renko chart — bricks of fixed price size, drawn only when price
/// moves more than `brickSize` from the prior close. Strips out
/// time + minor noise, leaves directional moves.
///
/// Accepts [Candle] OHLC input; bricks are computed from each
/// candle's close price.
///
/// ```dart
/// GlobalRenko(
///   candles: [Candle(...), ...],
///   brickSize: 2.0,
/// )
/// ```
class GlobalRenko extends StatelessWidget {
  const GlobalRenko({
    required this.candles,
    required this.brickSize,
    this.style = ChartStyle.standard,
    this.animation = FinancialChartAnimation.sequential,
    this.brickWidth = 14,
    this.gap = 1.0,
    this.upColor,
    this.downColor,
    this.showAxisLabels = true,
    this.valueFormatter,
    super.key,
  });

  final List<Candle> candles;

  /// Minimum price move (in price units) needed to render a new
  /// brick. Bigger = less noise, more strategic view.
  final double brickSize;

  final ChartStyle style;
  final FinancialChartAnimation animation;
  final double brickWidth;
  final double gap;
  final Color? upColor;
  final Color? downColor;
  final bool showAxisLabels;
  final String Function(double)? valueFormatter;

  @override
  Widget build(BuildContext context) {
    if (candles.isEmpty || brickSize <= 0) return const SizedBox.shrink();
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
                      painter: _RenkoPainter(
                        candles: candles,
                        brickSize: brickSize,
                        brickWidth: brickWidth,
                        gap: gap,
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
    final layout = _RenkoLayout.compute(
      candles: candles,
      brickSize: brickSize,
      size: size,
      brickWidth: brickWidth,
    );
    if (layout == null) return const [];
    for (var i = 0; i < layout.bricks.length; i++) {
      final b = layout.bricks[i];
      if (b.rect.contains(pos)) {
        return [
          TooltipEntry(
            label: b.up ? 'Up brick' : 'Down brick',
            value: '${fmt(b.lowPrice)} → ${fmt(b.highPrice)}',
            color: b.up ? upCol : downCol,
          ),
        ];
      }
    }
    return const [];
  }
}

class _RenkoBrick {
  _RenkoBrick({
    required this.rect,
    required this.up,
    required this.lowPrice,
    required this.highPrice,
  });
  final Rect rect;
  final bool up;
  final double lowPrice;
  final double highPrice;
}

class _RenkoLayout {
  _RenkoLayout({
    required this.bricks,
    required this.priceMin,
    required this.priceMax,
    required this.left,
    required this.right,
    required this.top,
    required this.bottom,
  });

  final List<_RenkoBrick> bricks;
  final double priceMin;
  final double priceMax;
  final double left;
  final double right;
  final double top;
  final double bottom;

  static _RenkoLayout? compute({
    required List<Candle> candles,
    required double brickSize,
    required Size size,
    required double brickWidth,
  }) {
    if (size.width <= 0 || size.height <= 0) return null;
    if (candles.isEmpty || brickSize <= 0) return null;

    // Build bricks.
    final bricks = <(bool up, double lo, double hi)>[];
    var refPrice = candles.first.close;
    for (var i = 1; i < candles.length; i++) {
      var price = candles[i].close;
      while (price - refPrice >= brickSize) {
        bricks.add((true, refPrice, refPrice + brickSize));
        refPrice += brickSize;
      }
      while (refPrice - price >= brickSize) {
        bricks.add((false, refPrice - brickSize, refPrice));
        refPrice -= brickSize;
      }
    }
    if (bricks.isEmpty) return null;

    var pMin = double.infinity;
    var pMax = -double.infinity;
    for (final b in bricks) {
      if (b.$2 < pMin) pMin = b.$2;
      if (b.$3 > pMax) pMax = b.$3;
    }
    if (pMin == pMax) pMax = pMin + brickSize;

    const leftPad = 36.0;
    const rightPad = 12.0;
    const topPad = 16.0;
    const bottomPad = 28.0;
    const left = leftPad;
    final right = size.width - rightPad;
    const top = topPad;
    final bottom = size.height - bottomPad;
    final usableW = right - left;
    final spacing = brickWidth;
    final placed = <_RenkoBrick>[];
    for (var i = 0; i < bricks.length; i++) {
      final b = bricks[i];
      final x = left + i * spacing;
      if (x > right) break;
      final yLo = bottom - (b.$2 - pMin) / (pMax - pMin) * (bottom - top);
      final yHi = bottom - (b.$3 - pMin) / (pMax - pMin) * (bottom - top);
      placed.add(
        _RenkoBrick(
          rect: Rect.fromLTRB(
            x,
            yHi,
            x + spacing - 0,
            yLo,
          ),
          up: b.$1,
          lowPrice: b.$2,
          highPrice: b.$3,
        ),
      );
    }

    return _RenkoLayout(
      bricks: placed,
      priceMin: pMin,
      priceMax: pMax,
      left: left,
      right: left + (placed.length * spacing).clamp(0.0, usableW),
      top: top,
      bottom: bottom,
    );
  }
}

class _RenkoPainter extends CustomPainter {
  _RenkoPainter({
    required this.candles,
    required this.brickSize,
    required this.brickWidth,
    required this.gap,
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
  final double brickSize;
  final double brickWidth;
  final double gap;
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
    final layout = _RenkoLayout.compute(
      candles: candles,
      brickSize: brickSize,
      size: size,
      brickWidth: brickWidth,
    );
    if (layout == null) return;

    canvas.drawLine(
      Offset(layout.left, layout.bottom),
      Offset(size.width - 12, layout.bottom),
      Paint()
        ..color = gridColor
        ..strokeWidth = 0.5,
    );

    final n = layout.bricks.length;
    for (var i = 0; i < n; i++) {
      final b = layout.bricks[i];
      double opacity;
      switch (animation) {
        case FinancialChartAnimation.sequential:
          final delay = (i / n) * 0.7;
          opacity = ((progress - delay) / 0.3).clamp(0.0, 1.0);
        case FinancialChartAnimation.fade:
          opacity = progress;
      }
      if (opacity <= 0) continue;
      final c = (b.up ? upColor : downColor).withValues(alpha: opacity);
      canvas.drawRect(
        Rect.fromLTRB(
          b.rect.left + gap / 2,
          b.rect.top + gap / 2,
          b.rect.right - gap / 2,
          b.rect.bottom - gap / 2,
        ),
        Paint()..color = c,
      );
    }

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

    drawText(valueFormatter(layout.priceMax), Offset(4, layout.top - 4));
    drawText(valueFormatter(layout.priceMin), Offset(4, layout.bottom - 12));
  }

  @override
  bool shouldRepaint(covariant _RenkoPainter old) =>
      old.progress != progress ||
      old.candles != candles ||
      old.brickSize != brickSize ||
      old.animation != animation;
}
