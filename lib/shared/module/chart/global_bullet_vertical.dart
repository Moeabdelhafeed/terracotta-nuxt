import 'package:flutter/material.dart';

import '../../../core/extensions/theme_colors_extension.dart';
import '../../../core/localization/number_formatter.dart';
import 'chart_data.dart';
import 'chart_internals.dart';
import 'chart_models.dart';
import 'chart_tooltip_overlay.dart';
import 'custom_paint_tooltip.dart';

export 'chart_data.dart' show BulletDatum;
export 'chart_models.dart' show ChartStyle;

/// Bullet vertical — gauge-style KPI display arranged as columns
/// instead of rows. Each [BulletDatum] becomes a vertical column
/// with qualitative bands behind, the actual value as the bar,
/// and a horizontal tick for the target.
///
/// Best for KPI dashboards where you want to compare several
/// metrics side-by-side at a glance.
///
/// ```dart
/// GlobalBulletVertical(
///   data: [
///     BulletDatum(label: 'Revenue', value: 78, target: 90,
///       ranges: [60, 80, 100]),
///   ],
/// )
/// ```
class GlobalBulletVertical extends StatelessWidget {
  const GlobalBulletVertical({
    required this.data,
    this.style = ChartStyle.standard,
    this.barWidth = 18,
    this.bandWidth = 36,
    this.targetTickWidth = 0,
    this.showLabels = true,
    this.showValues = true,
    this.valueFormatter,
    super.key,
  });

  final List<BulletDatum> data;
  final ChartStyle style;
  final double barWidth;
  final double bandWidth;

  /// Target tick width override. 0 = matches `bandWidth`.
  final double targetTickWidth;
  final bool showLabels;
  final bool showValues;
  final String Function(double)? valueFormatter;

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) return const SizedBox.shrink();
    final palette = resolveSeriesColors(context, style, data.length);
    final fmt = valueFormatter ?? (v) => AppNumbers.compact(v);
    final axisStyle = resolveAxisLabelStyle(context, style);
    final fg = context.textColors.primary;
    final tickColor = fg;
    final bandColors = [
      context.statusColors.error.withValues(alpha: 0.18),
      context.statusColors.warning.withValues(alpha: 0.22),
      context.statusColors.success.withValues(alpha: 0.22),
      context.statusColors.success.withValues(alpha: 0.30),
    ];

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
                    painter: _BulletVPainter(
                      data: data,
                      colors: palette,
                      bandColors: bandColors,
                      tickColor: tickColor,
                      barWidth: barWidth,
                      bandWidth: bandWidth,
                      targetTickWidth: targetTickWidth == 0
                          ? bandWidth
                          : targetTickWidth,
                      showLabels: showLabels,
                      showValues: showValues,
                      axisStyle: axisStyle,
                      fg: fg,
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
    );
  }

  List<TooltipEntry> _hitTest(
    Offset pos,
    Size size,
    List<Color> palette,
    String Function(double) fmt,
  ) {
    final layout = _BulletVLayout.compute(
      data: data,
      size: size,
      bandWidth: bandWidth,
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
    if (bestI < 0 || bestDx > bandWidth / 2 + 6) return const [];
    final d = data[bestI];
    return [
      TooltipEntry(
        label: d.label,
        value: '${fmt(d.value)} / ${fmt(d.target)}${d.unit}',
        color: d.color ?? palette[bestI],
      ),
    ];
  }
}

class _BulletVLayout {
  _BulletVLayout({
    required this.centers,
    required this.top,
    required this.bottom,
    required this.gMax,
  });

  final List<double> centers;
  final double top;
  final double bottom;
  final double gMax;

  static _BulletVLayout? compute({
    required List<BulletDatum> data,
    required Size size,
    required double bandWidth,
  }) {
    if (size.width <= 0 || size.height <= 0) return null;
    if (data.isEmpty) return null;
    var gMax = 0.0;
    for (final d in data) {
      if (d.ranges.isNotEmpty && d.ranges.last > gMax) {
        gMax = d.ranges.last;
      }
      if (d.value > gMax) gMax = d.value;
      if (d.target > gMax) gMax = d.target;
    }
    if (gMax == 0) gMax = 1;

    const leftPad = 24.0;
    const rightPad = 24.0;
    const topPad = 18.0;
    const bottomPad = 36.0;
    final usableW = size.width - leftPad - rightPad;
    final n = data.length;
    final colW = usableW / n;
    final centers = List<double>.generate(n, (i) => leftPad + colW * (i + 0.5));
    return _BulletVLayout(
      centers: centers,
      top: topPad,
      bottom: size.height - bottomPad,
      gMax: gMax,
    );
  }
}

class _BulletVPainter extends CustomPainter {
  _BulletVPainter({
    required this.data,
    required this.colors,
    required this.bandColors,
    required this.tickColor,
    required this.barWidth,
    required this.bandWidth,
    required this.targetTickWidth,
    required this.showLabels,
    required this.showValues,
    required this.axisStyle,
    required this.fg,
    required this.progress,
    required this.valueFormatter,
  });

  final List<BulletDatum> data;
  final List<Color> colors;
  final List<Color> bandColors;
  final Color tickColor;
  final double barWidth;
  final double bandWidth;
  final double targetTickWidth;
  final bool showLabels;
  final bool showValues;
  final TextStyle axisStyle;
  final Color fg;
  final double progress;
  final String Function(double) valueFormatter;

  @override
  void paint(Canvas canvas, Size size) {
    final layout = _BulletVLayout.compute(
      data: data,
      size: size,
      bandWidth: bandWidth,
    );
    if (layout == null) return;

    for (var i = 0; i < data.length; i++) {
      final d = data[i];
      final cx = layout.centers[i];

      // Per-column scale relative to gMax (consistent across all
      // columns so they compare apples-to-apples).
      double yFor(double v) {
        final t = (v / layout.gMax).clamp(0.0, 1.0);
        return layout.bottom - t * (layout.bottom - layout.top);
      }

      // Qualitative bands — paint cumulative ranges from bottom up.
      var prev = 0.0;
      for (var k = 0; k < d.ranges.length; k++) {
        final yLo = yFor(prev);
        final yHi = yFor(d.ranges[k]);
        final color = bandColors[k % bandColors.length];
        canvas.drawRect(
          Rect.fromLTRB(
            cx - bandWidth / 2,
            yHi,
            cx + bandWidth / 2,
            yLo,
          ),
          Paint()..color = color,
        );
        prev = d.ranges[k];
      }

      // Bar (animated grow from baseline).
      final c = d.color ?? colors[i];
      final yBar = yFor(d.value);
      final barTop = layout.bottom - (layout.bottom - yBar) * progress;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTRB(
            cx - barWidth / 2,
            barTop,
            cx + barWidth / 2,
            layout.bottom,
          ),
          const Radius.circular(2),
        ),
        Paint()..color = c,
      );

      // Comparative marker (small horizontal line).
      if (d.comparative != null) {
        final yC = yFor(d.comparative!);
        canvas.drawLine(
          Offset(cx - bandWidth / 2 + 2, yC),
          Offset(cx + bandWidth / 2 - 2, yC),
          Paint()
            ..color = tickColor.withValues(alpha: 0.55)
            ..strokeWidth = 1.5
            ..strokeCap = StrokeCap.round,
        );
      }

      // Target tick.
      if (progress > 0.6) {
        final fade = ((progress - 0.6) / 0.4).clamp(0.0, 1.0);
        final yT = yFor(d.target);
        canvas.drawLine(
          Offset(cx - targetTickWidth / 2, yT),
          Offset(cx + targetTickWidth / 2, yT),
          Paint()
            ..color = tickColor.withValues(alpha: fade)
            ..strokeWidth = 2.5
            ..strokeCap = StrokeCap.round,
        );
      }

      // Labels.
      if (progress > 0.4) {
        final fadeRaw = ((progress - 0.4) / 0.6).clamp(0.0, 1.0);
        final fade = Curves.easeOutCubic.transform(fadeRaw);
        if (showLabels) {
          final tp = TextPainter(
            text: TextSpan(
              text: d.label,
              style: axisStyle.copyWith(
                color: axisStyle.color?.withValues(alpha: fade),
                fontWeight: FontWeight.w600,
              ),
            ),
            textDirection: TextDirection.ltr,
            maxLines: 1,
            ellipsis: '…',
          )..layout(maxWidth: bandWidth + 24);
          tp.paint(canvas, Offset(cx - tp.width / 2, layout.bottom + 6));
        }
        if (showValues) {
          final txt = valueFormatter(d.value * progress) + d.unit;
          final tp = TextPainter(
            text: TextSpan(
              text: txt,
              style: axisStyle.copyWith(
                color: fg.withValues(alpha: fade),
                fontWeight: FontWeight.w700,
              ),
            ),
            textDirection: TextDirection.ltr,
          )..layout();
          tp.paint(
            canvas,
            Offset(cx - tp.width / 2, layout.top - tp.height - 2),
          );
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant _BulletVPainter old) =>
      old.progress != progress || old.data != data;
}
