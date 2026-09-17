import 'package:flutter/material.dart';

import '../../../core/extensions/theme_colors_extension.dart';
import '../../../core/localization/number_formatter.dart';
import 'chart_data.dart';
import 'chart_internals.dart';
import 'chart_models.dart';
import 'chart_tooltip_overlay.dart';
import 'chart_zoom_pan.dart';
import 'custom_paint_tooltip.dart';

export 'chart_data.dart' show SlopeDatum;
export 'chart_models.dart' show ChartStyle;

/// Slope chart — two columns (`before` / `after`) with a line per
/// row connecting the two values. Compact alternative to grouped
/// bars when the focus is the change between two time points.
///
/// ```dart
/// GlobalSlopeChart(
///   data: [
///     SlopeDatum(label: 'Revenue', before: 100, after: 130),
///     SlopeDatum(label: 'Costs',   before: 70,  after: 65),
///   ],
///   beforeLabel: 'Q1', afterLabel: 'Q2',
/// )
/// ```
class GlobalSlopeChart extends StatelessWidget {
  const GlobalSlopeChart({
    required this.data,
    this.style = ChartStyle.standard,
    this.beforeLabel = 'Before',
    this.afterLabel = 'After',
    this.strokeWidth = 2.5,
    this.dotRadius = 5,
    this.showLabels = true,
    this.showValues = true,
    this.upColor,
    this.downColor,
    this.flatColor,
    this.colorByDirection = false,
    this.valueFormatter,
    super.key,
  });

  final List<SlopeDatum> data;
  final ChartStyle style;
  final String beforeLabel;
  final String afterLabel;
  final double strokeWidth;
  final double dotRadius;
  final bool showLabels;
  final bool showValues;

  /// When [colorByDirection] is true:
  final Color? upColor;
  final Color? downColor;
  final Color? flatColor;

  /// Tint each line by sign of `after - before` (up / down / flat)
  /// instead of palette colors. Useful when delta direction is the
  /// most important signal.
  final bool colorByDirection;

  final String Function(double)? valueFormatter;

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) return const SizedBox.shrink();

    final palette = resolveSeriesColors(context, style, data.length);
    final colors = [
      for (var i = 0; i < data.length; i++)
        data[i].color ??
            (colorByDirection
                ? _directionColor(context, data[i].delta)
                : palette[i]),
    ];
    final axisStyle = resolveAxisLabelStyle(context, style);
    final gridColor = resolveGridColor(context, style);
    final fmt = valueFormatter ?? (v) => AppNumbers.compact(v);

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
                hitTest: (pos, size) => _hitTest(pos, size, data, colors, fmt),
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
                      painter: _SlopeChartPainter(
                        data: data,
                        colors: colors,
                        beforeLabel: beforeLabel,
                        afterLabel: afterLabel,
                        strokeWidth: strokeWidth,
                        dotRadius: dotRadius,
                        showLabels: showLabels,
                        showValues: showValues,
                        gridColor: gridColor,
                        axisStyle: axisStyle,
                        valueFormatter: fmt,
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

  Color _directionColor(BuildContext context, double delta) {
    if (delta > 0) return upColor ?? context.statusColors.success;
    if (delta < 0) return downColor ?? context.statusColors.error;
    return flatColor ?? context.textColors.secondary;
  }

  List<TooltipEntry> _hitTest(
    Offset pos,
    Size size,
    List<SlopeDatum> data,
    List<Color> colors,
    String Function(double) fmt,
  ) {
    if (pos.dx < 0 || pos.dx > size.width) return const [];
    if (pos.dy < 0 || pos.dy > size.height) return const [];
    // Hit test by y-band — find row whose mid-y between before/after
    // is closest to pointer y. Simple band lookup keeps the hover
    // forgiving on slope lines.
    var best = -1;
    var bestDist = double.infinity;
    final layout = _SlopeLayout(size);
    for (var i = 0; i < data.length; i++) {
      final yBefore = layout.yFor(data[i].before);
      final yAfter = layout.yFor(data[i].after);
      final t = ((pos.dx - layout.leftCol) / (layout.rightCol - layout.leftCol))
          .clamp(0.0, 1.0);
      final yLine = yBefore + (yAfter - yBefore) * t;
      final dist = (yLine - pos.dy).abs();
      if (dist < bestDist) {
        bestDist = dist;
        best = i;
      }
    }
    if (best < 0 || bestDist > 24) return const [];
    final d = data[best];
    final delta = d.after - d.before;
    final sign = delta > 0 ? '+' : (delta < 0 ? '−' : '');
    return [
      TooltipEntry(
        label: d.label,
        value:
            '$beforeLabel ${fmt(d.before)} → $afterLabel ${fmt(d.after)} '
            '($sign${fmt(delta.abs())})',
        color: colors[best],
        icon: d.icon,
        iconAsset: d.iconAsset,
        iconWidget: d.iconWidget,
      ),
    ];
  }
}

class _SlopeLayout {
  _SlopeLayout(this.size);

  final Size size;
  static const double leftPad = 80;
  static const double rightPad = 80;
  static const double topPad = 24;
  static const double bottomPad = 28;

  double get leftCol => leftPad;
  double get rightCol => size.width - rightPad;
  double get top => topPad;
  double get bottom => size.height - bottomPad;

  double yFor(double v) {
    return bottom - (v - _yLo) / (_yHi - _yLo) * (bottom - top);
  }

  static double _yLo = 0;
  static double _yHi = 1;
  static void setRange(double lo, double hi) {
    _yLo = lo;
    _yHi = hi;
  }
}

class _SlopeChartPainter extends CustomPainter {
  _SlopeChartPainter({
    required this.data,
    required this.colors,
    required this.beforeLabel,
    required this.afterLabel,
    required this.strokeWidth,
    required this.dotRadius,
    required this.showLabels,
    required this.showValues,
    required this.gridColor,
    required this.axisStyle,
    required this.valueFormatter,
    required this.progress,
  });

  final List<SlopeDatum> data;
  final List<Color> colors;
  final String beforeLabel;
  final String afterLabel;
  final double strokeWidth;
  final double dotRadius;
  final bool showLabels;
  final bool showValues;
  final Color gridColor;
  final TextStyle axisStyle;
  final String Function(double) valueFormatter;
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;
    if (data.isEmpty) return;

    var lo = data.first.before;
    var hi = data.first.before;
    for (final d in data) {
      if (d.before < lo) lo = d.before;
      if (d.before > hi) hi = d.before;
      if (d.after < lo) lo = d.after;
      if (d.after > hi) hi = d.after;
    }
    final pad = (hi - lo) * 0.1;
    lo -= pad;
    hi += pad;
    if (hi == lo) hi = lo + 1;
    _SlopeLayout.setRange(lo, hi);

    final layout = _SlopeLayout(size);
    final leftCol = layout.leftCol;
    final rightCol = layout.rightCol;
    final top = layout.top;
    final bottom = layout.bottom;
    if (rightCol <= leftCol || bottom <= top) return;

    // Column markers (vertical guides).
    final guidePaint = Paint()
      ..color = gridColor
      ..strokeWidth = 0.5;
    canvas.drawLine(Offset(leftCol, top), Offset(leftCol, bottom), guidePaint);
    canvas.drawLine(
      Offset(rightCol, top),
      Offset(rightCol, bottom),
      guidePaint,
    );

    // Column header labels.
    final headerStyle = axisStyle.copyWith(
      fontWeight: FontWeight.w700,
      letterSpacing: 0.3,
    );
    _paintCenteredText(
      canvas,
      beforeLabel,
      headerStyle,
      Offset(leftCol, top - 16),
      align: TextAlign.center,
    );
    _paintCenteredText(
      canvas,
      afterLabel,
      headerStyle,
      Offset(rightCol, top - 16),
      align: TextAlign.center,
    );

    // Lines + dots + labels.
    for (var i = 0; i < data.length; i++) {
      final d = data[i];
      final yBefore = layout.yFor(d.before);
      final yAfter = layout.yFor(d.after);
      // Animate L→R.
      final tEnd = leftCol + (rightCol - leftCol) * progress;
      final yEnd = yBefore + (yAfter - yBefore) * progress;
      final stroke = Paint()
        ..color = colors[i]
        ..strokeWidth = strokeWidth
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;
      canvas.drawLine(Offset(leftCol, yBefore), Offset(tEnd, yEnd), stroke);

      if (progress > 0.95) {
        final fill = Paint()..color = colors[i];
        final ring = Paint()
          ..color = Colors.white
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5;
        canvas.drawCircle(Offset(leftCol, yBefore), dotRadius, fill);
        canvas.drawCircle(Offset(leftCol, yBefore), dotRadius, ring);
        canvas.drawCircle(Offset(rightCol, yAfter), dotRadius, fill);
        canvas.drawCircle(Offset(rightCol, yAfter), dotRadius, ring);
      }

      if (showLabels && progress > 0.85) {
        final fade = ((progress - 0.85) / 0.15).clamp(0.0, 1.0);
        final lblStyle = axisStyle.copyWith(
          color: axisStyle.color?.withValues(alpha: fade),
          fontWeight: FontWeight.w600,
        );
        // Left side: value · label
        final leftTxt = showValues
            ? '${valueFormatter(d.before)} · ${d.label}'
            : d.label;
        _paintRightAlignedText(
          canvas,
          leftTxt,
          lblStyle,
          Offset(leftCol - dotRadius - 8, yBefore - axisStyle.fontSize! / 2),
        );
        // Right side: value
        final rightTxt = showValues ? valueFormatter(d.after) : d.label;
        _paintLeftAlignedText(
          canvas,
          rightTxt,
          lblStyle,
          Offset(rightCol + dotRadius + 8, yAfter - axisStyle.fontSize! / 2),
        );
      }
    }
  }

  void _paintCenteredText(
    Canvas canvas,
    String text,
    TextStyle style,
    Offset pos, {
    TextAlign align = TextAlign.center,
  }) {
    final tp = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: TextDirection.ltr,
      textAlign: align,
      maxLines: 1,
    )..layout();
    tp.paint(canvas, Offset(pos.dx - tp.width / 2, pos.dy - tp.height / 2));
  }

  void _paintRightAlignedText(
    Canvas canvas,
    String text,
    TextStyle style,
    Offset endPos,
  ) {
    final tp = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: TextDirection.ltr,
      maxLines: 1,
    )..layout();
    tp.paint(canvas, Offset(endPos.dx - tp.width, endPos.dy));
  }

  void _paintLeftAlignedText(
    Canvas canvas,
    String text,
    TextStyle style,
    Offset startPos,
  ) {
    final tp = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: TextDirection.ltr,
      maxLines: 1,
    )..layout();
    tp.paint(canvas, startPos);
  }

  @override
  bool shouldRepaint(covariant _SlopeChartPainter old) =>
      old.progress != progress ||
      old.data != data ||
      old.colors != colors ||
      old.beforeLabel != beforeLabel ||
      old.afterLabel != afterLabel ||
      old.strokeWidth != strokeWidth ||
      old.dotRadius != dotRadius ||
      old.showLabels != showLabels ||
      old.showValues != showValues;
}
