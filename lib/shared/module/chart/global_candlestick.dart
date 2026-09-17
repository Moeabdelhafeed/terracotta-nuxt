import 'package:flutter/material.dart';

import '../../../core/extensions/theme_colors_extension.dart';
import '../../../core/localization/number_formatter.dart';
import 'chart_data.dart';
import 'chart_internals.dart';
import 'chart_models.dart';
import 'chart_zoom_pan.dart';

export 'chart_data.dart' show Candle;
export 'chart_models.dart' show ChartStyle;

/// OHLC candlestick chart (financial price action). Renders each
/// `Candle` as a thin wick from low to high with a thick body from
/// open to close — bullish (close ≥ open) and bearish bodies are
/// tinted distinctly via [bullColor] / [bearColor].
///
/// Built on Flutter `CustomPaint` (graphic's CustomMark API can also
/// host this, but direct paint is simpler for OHLC's tight per-datum
/// geometry).
///
/// ```dart
/// GlobalCandlestick(
///   candles: [
///     Candle(time: 0, open: 100, high: 108, low: 96, close: 104),
///     ...
///   ],
/// )
/// ```
class GlobalCandlestick extends StatelessWidget {
  const GlobalCandlestick({
    required this.candles,
    this.style = ChartStyle.standard,
    this.bullColor,
    this.bearColor,
    this.bodyWidth = 8,
    this.wickWidth = 1.5,
    this.priceFormatter,
    super.key,
  });

  final List<Candle> candles;
  final ChartStyle style;

  /// Color for bullish candles (close ≥ open). Falls back to
  /// `statusColors.success`.
  final Color? bullColor;

  /// Color for bearish candles (close < open). Falls back to
  /// `statusColors.error`.
  final Color? bearColor;

  final double bodyWidth;
  final double wickWidth;

  /// Format Y-axis price labels. Defaults to locale-aware compact.
  final String Function(double)? priceFormatter;

  @override
  Widget build(BuildContext context) {
    if (candles.isEmpty) return const SizedBox.shrink();

    final bull = bullColor ?? context.statusColors.success;
    final bear = bearColor ?? context.statusColors.error;
    final gridColor = resolveGridColor(context, style);
    final axisStyle = resolveAxisLabelStyle(context, style);
    final fmt = priceFormatter ?? (v) => AppNumbers.compact(v);

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
                    painter: _CandlestickPainter(
                      candles: candles,
                      bull: bull,
                      bear: bear,
                      bodyWidth: bodyWidth,
                      wickWidth: wickWidth,
                      gridColor: gridColor,
                      axisStyle: axisStyle,
                      priceFormatter: fmt,
                      showGrid: style.effectiveShowGrid,
                      showAxes: style.effectiveShowAxisLabels,
                      progress: t,
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
      style,
    );
  }
}

class _CandlestickPainter extends CustomPainter {
  _CandlestickPainter({
    required this.candles,
    required this.bull,
    required this.bear,
    required this.bodyWidth,
    required this.wickWidth,
    required this.gridColor,
    required this.axisStyle,
    required this.priceFormatter,
    required this.showGrid,
    required this.showAxes,
    required this.progress,
  });

  final List<Candle> candles;
  final Color bull;
  final Color bear;
  final double bodyWidth;
  final double wickWidth;
  final Color gridColor;
  final TextStyle axisStyle;
  final String Function(double) priceFormatter;
  final bool showGrid;
  final bool showAxes;
  final double progress;

  static const _leftPad = 44.0;
  static const _bottomPad = 4.0;
  static const _topPad = 8.0;
  static const _rightPad = 8.0;
  static const _gridLines = 5;

  @override
  void paint(Canvas canvas, Size size) {
    const left = _leftPad;
    final right = size.width - _rightPad;
    const top = _topPad;
    final bottom = size.height - _bottomPad;
    if (right <= left || bottom <= top) return;

    var lo = candles.first.low;
    var hi = candles.first.high;
    for (final c in candles) {
      if (c.low < lo) lo = c.low;
      if (c.high > hi) hi = c.high;
    }
    final pad = (hi - lo) * 0.05;
    lo -= pad;
    hi += pad;
    final pricePerPx = (hi - lo) / (bottom - top);
    if (pricePerPx <= 0) return;

    double yFor(double price) => bottom - (price - lo) / pricePerPx;

    if (showGrid) {
      final gridPaint = Paint()
        ..color = gridColor
        ..strokeWidth = 0.5;
      for (var i = 0; i <= _gridLines; i++) {
        final y = top + (bottom - top) * i / _gridLines;
        canvas.drawLine(Offset(left, y), Offset(right, y), gridPaint);
      }
    }

    if (showAxes) {
      for (var i = 0; i <= _gridLines; i++) {
        final y = top + (bottom - top) * i / _gridLines;
        final price = hi - (hi - lo) * i / _gridLines;
        final tp = TextPainter(
          text: TextSpan(text: priceFormatter(price), style: axisStyle),
          textDirection: TextDirection.ltr,
        )..layout(maxWidth: _leftPad - 6);
        tp.paint(canvas, Offset(left - tp.width - 6, y - tp.height / 2));
      }
    }

    final n = candles.length;
    final colWidth = (right - left) / n;
    final baseline = bottom; // animate body heights up from x-axis baseline.

    for (var i = 0; i < n; i++) {
      final c = candles[i];
      final cx = left + colWidth * (i + 0.5);
      final color = c.isBullish ? bull : bear;
      final paint = Paint()
        ..color = color
        ..strokeWidth = wickWidth
        ..strokeCap = StrokeCap.round;

      // Lerp endpoint y from baseline → final y as progress advances.
      double animY(double price) {
        final yFinal = yFor(price);
        return baseline + (yFinal - baseline) * progress;
      }

      // Wick.
      canvas.drawLine(
        Offset(cx, animY(c.high)),
        Offset(cx, animY(c.low)),
        paint,
      );

      // Body.
      final bodyTop = animY(c.isBullish ? c.close : c.open);
      final bodyBottom = animY(c.isBullish ? c.open : c.close);
      final bodyRect = Rect.fromLTRB(
        cx - bodyWidth / 2,
        bodyTop,
        cx + bodyWidth / 2,
        bodyBottom == bodyTop ? bodyBottom + 1 : bodyBottom,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(bodyRect, const Radius.circular(1.5)),
        Paint()..color = color,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _CandlestickPainter old) =>
      old.progress != progress ||
      old.candles != candles ||
      old.bull != bull ||
      old.bear != bear ||
      old.bodyWidth != bodyWidth ||
      old.wickWidth != wickWidth ||
      old.gridColor != gridColor ||
      old.showGrid != showGrid ||
      old.showAxes != showAxes;
}
