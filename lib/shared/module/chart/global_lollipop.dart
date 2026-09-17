import 'package:flutter/material.dart';

import '../../../core/extensions/theme_colors_extension.dart';
import '../../../core/localization/number_formatter.dart';
import 'chart_data.dart';
import 'chart_internals.dart';
import 'chart_models.dart';
import 'chart_tooltip_overlay.dart';
import 'chart_zoom_pan.dart';
import 'custom_paint_tooltip.dart';

export 'chart_data.dart' show LollipopDatum;
export 'chart_models.dart' show ChartStyle, LollipopAnimation;

/// Orientation for [GlobalLollipop].
enum LollipopOrientation {
  /// Rows: bar grows left → right, label on the left.
  horizontal,

  /// Columns: bar grows bottom → top, label below.
  vertical,
}

/// Lollipop chart — sparser alternative to bars. Each entry is a
/// thin stem from a baseline to a dot at [LollipopDatum.value].
/// Best for ranked lists where values cluster narrowly: stems give
/// the eye a guide while keeping ink low.
///
/// ```dart
/// GlobalLollipop(
///   data: const [
///     LollipopDatum(label: 'Search',  value: 87),
///     LollipopDatum(label: 'Direct',  value: 64),
///     LollipopDatum(label: 'Social',  value: 32),
///     LollipopDatum(label: 'Email',   value: 24),
///     LollipopDatum(label: 'Referral', value: 18),
///   ],
/// )
/// ```
class GlobalLollipop extends StatelessWidget {
  const GlobalLollipop({
    required this.data,
    this.style = ChartStyle.standard,
    this.orientation = LollipopOrientation.horizontal,
    this.animation = LollipopAnimation.stretch,
    this.stemWidth = 2.0,
    this.dotRadius = 6.0,
    this.dotRing = true,
    this.showValues = true,
    this.colorByValue = false,
    this.threshold,
    this.belowThresholdColor,
    this.valueFormatter,
    super.key,
  });

  final List<LollipopDatum> data;
  final ChartStyle style;
  final LollipopOrientation orientation;
  final LollipopAnimation animation;
  final double stemWidth;
  final double dotRadius;

  /// Draw a thin white ring around each dot — pops the dot off
  /// the stem and against busy backgrounds.
  final bool dotRing;

  final bool showValues;

  /// Tint each entry by its value's sign (positive/negative) — only
  /// useful when values can be negative.
  final bool colorByValue;

  /// When set, entries below this value paint in
  /// [belowThresholdColor] instead of the palette color.
  final double? threshold;
  final Color? belowThresholdColor;

  final String Function(double)? valueFormatter;

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) return const SizedBox.shrink();
    final palette = resolveSeriesColors(context, style, data.length);
    final fmt = valueFormatter ?? (v) => AppNumbers.compact(v);
    final axisStyle = resolveAxisLabelStyle(context, style);
    final gridColor = resolveGridColor(context, style);
    final colors = [
      for (var i = 0; i < data.length; i++)
        () {
          final d = data[i];
          if (d.color != null) return d.color!;
          if (threshold != null && d.value < threshold!) {
            return belowThresholdColor ?? context.textColors.secondary;
          }
          if (colorByValue) {
            if (d.value < 0) return context.statusColors.error;
            if (d.value > 0) return context.statusColors.success;
            return context.textColors.secondary;
          }
          return palette[i];
        }(),
    ];

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
                hitTest: (pos, size) => _hitTest(pos, size, colors, fmt),
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
                      painter: _LollipopPainter(
                        data: data,
                        colors: colors,
                        orientation: orientation,
                        animation: animation,
                        stemWidth: stemWidth,
                        dotRadius: dotRadius,
                        dotRing: dotRing,
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

  List<TooltipEntry> _hitTest(
    Offset pos,
    Size size,
    List<Color> colors,
    String Function(double) fmt,
  ) {
    if (data.isEmpty) return const [];
    final layout = _LollipopLayout.compute(
      size: size,
      data: data,
      orientation: orientation,
    );
    if (layout == null) return const [];
    var bestI = -1;
    var bestDist = double.infinity;
    for (var i = 0; i < data.length; i++) {
      final d = (layout.dotCenters[i] - pos).distance;
      if (d < bestDist) {
        bestDist = d;
        bestI = i;
      }
    }
    if (bestI < 0 || bestDist > 28) return const [];
    final d = data[bestI];
    return [
      TooltipEntry(
        label: d.label,
        value: fmt(d.value),
        color: colors[bestI],
        icon: d.icon,
        iconAsset: d.iconAsset,
        iconWidget: d.iconWidget,
      ),
    ];
  }
}

class _LollipopLayout {
  _LollipopLayout({
    required this.dotCenters,
    required this.baselineCoords,
    required this.size,
  });

  final List<Offset> dotCenters;
  final List<Offset> baselineCoords;
  final Size size;

  static _LollipopLayout? compute({
    required Size size,
    required List<LollipopDatum> data,
    required LollipopOrientation orientation,
  }) {
    if (size.width <= 0 || size.height <= 0) return null;
    if (data.isEmpty) return null;

    var lo = data.first.value;
    var hi = data.first.value;
    for (final d in data) {
      if (d.value < lo) lo = d.value;
      if (d.value > hi) hi = d.value;
    }
    final allPositive = lo >= 0;
    final baseline = allPositive ? 0.0 : lo;
    final span = (hi - baseline).abs();
    final scaleMax = span > 0 ? span : 1.0;

    if (orientation == LollipopOrientation.horizontal) {
      const leftPad = 100.0;
      const rightPad = 60.0;
      const topPad = 8.0;
      const bottomPad = 8.0;
      final usableW = size.width - leftPad - rightPad;
      final usableH = size.height - topPad - bottomPad;
      final rowH = usableH / data.length;
      final dots = <Offset>[];
      final baselines = <Offset>[];
      for (var i = 0; i < data.length; i++) {
        final y = topPad + rowH * (i + 0.5);
        final t = (data[i].value - baseline) / scaleMax;
        final x = leftPad + usableW * t;
        dots.add(Offset(x, y));
        baselines.add(Offset(leftPad, y));
      }
      return _LollipopLayout(
        dotCenters: dots,
        baselineCoords: baselines,
        size: size,
      );
    } else {
      const leftPad = 24.0;
      const rightPad = 24.0;
      const topPad = 28.0;
      const bottomPad = 40.0;
      final usableW = size.width - leftPad - rightPad;
      final usableH = size.height - topPad - bottomPad;
      final colW = usableW / data.length;
      final dots = <Offset>[];
      final baselines = <Offset>[];
      for (var i = 0; i < data.length; i++) {
        final x = leftPad + colW * (i + 0.5);
        final t = (data[i].value - baseline) / scaleMax;
        final y = topPad + usableH * (1 - t);
        dots.add(Offset(x, y));
        baselines.add(Offset(x, topPad + usableH));
      }
      return _LollipopLayout(
        dotCenters: dots,
        baselineCoords: baselines,
        size: size,
      );
    }
  }
}

class _LollipopPainter extends CustomPainter {
  _LollipopPainter({
    required this.data,
    required this.colors,
    required this.orientation,
    required this.animation,
    required this.stemWidth,
    required this.dotRadius,
    required this.dotRing,
    required this.showValues,
    required this.gridColor,
    required this.axisStyle,
    required this.valueFormatter,
    required this.progress,
  });

  final List<LollipopDatum> data;
  final List<Color> colors;
  final LollipopOrientation orientation;
  final LollipopAnimation animation;
  final double stemWidth;
  final double dotRadius;
  final bool dotRing;
  final bool showValues;
  final Color gridColor;
  final TextStyle axisStyle;
  final String Function(double) valueFormatter;
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final layout = _LollipopLayout.compute(
      size: size,
      data: data,
      orientation: orientation,
    );
    if (layout == null) return;

    // Subtle baseline guide.
    final guidePaint = Paint()
      ..color = gridColor
      ..strokeWidth = 0.5;
    if (orientation == LollipopOrientation.horizontal) {
      final x = layout.baselineCoords.first.dx;
      canvas.drawLine(
        Offset(x, 0),
        Offset(x, size.height),
        guidePaint,
      );
    } else {
      final y = layout.baselineCoords.first.dy;
      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y),
        guidePaint,
      );
    }

    for (var i = 0; i < data.length; i++) {
      final base = layout.baselineCoords[i];
      final dot = layout.dotCenters[i];
      final c = colors[i];

      // Per-row staggered progress for non-fade animations.
      final rowDelay = i / data.length * 0.15;
      final rowT = ((progress - rowDelay) / (1 - rowDelay)).clamp(0.0, 1.0);

      // Resolve animated dot position.
      Offset animDot;
      double stemT;
      double dotScale;
      double opacity;
      switch (animation) {
        case LollipopAnimation.stretch:
          stemT = rowT;
          animDot = Offset.lerp(base, dot, rowT)!;
          dotScale = (rowT - 0.85).clamp(0.0, 0.15) / 0.15;
          opacity = 1.0;
        case LollipopAnimation.rise:
          stemT = (rowT - 0.4).clamp(0.0, 0.6) / 0.6;
          animDot = Offset.lerp(base, dot, rowT)!;
          dotScale = 1.0;
          opacity = 1.0;
        case LollipopAnimation.fade:
          stemT = 1.0;
          animDot = dot;
          dotScale = 1.0;
          opacity = progress;
        case LollipopAnimation.pop:
          stemT = rowT;
          animDot = dot;
          dotScale = rowT;
          opacity = 1.0;
      }

      final stemPaint = Paint()
        ..color = c.withValues(alpha: 0.85 * opacity)
        ..strokeWidth = stemWidth
        ..strokeCap = StrokeCap.round;
      final stemEnd = Offset.lerp(base, dot, stemT)!;
      canvas.drawLine(base, stemEnd, stemPaint);

      // Dot.
      final r = dotRadius * dotScale;
      if (r > 0.5) {
        canvas.drawCircle(
          animDot,
          r,
          Paint()..color = c.withValues(alpha: opacity),
        );
        if (dotRing) {
          canvas.drawCircle(
            animDot,
            r,
            Paint()
              ..color = Colors.white.withValues(alpha: opacity)
              ..style = PaintingStyle.stroke
              ..strokeWidth = 1.5,
          );
        }
      }

      // Labels (axis side) + value labels.
      if (progress < 0.4) continue;
      final fadeRaw = ((progress - 0.4) / 0.6).clamp(0.0, 1.0);
      final fade = Curves.easeOutCubic.transform(fadeRaw);
      final lblStyle = axisStyle.copyWith(
        color: axisStyle.color?.withValues(alpha: fade),
      );
      final boldStyle = lblStyle.copyWith(fontWeight: FontWeight.w700);

      if (orientation == LollipopOrientation.horizontal) {
        // Category label on the left of the baseline.
        final labelTp = TextPainter(
          text: TextSpan(text: data[i].label, style: lblStyle),
          textDirection: TextDirection.ltr,
          maxLines: 1,
          ellipsis: '…',
        )..layout(maxWidth: base.dx - 6);
        labelTp.paint(
          canvas,
          Offset(base.dx - 6 - labelTp.width, base.dy - labelTp.height / 2),
        );
        // Value label to the right of the dot.
        if (showValues) {
          final vtp = TextPainter(
            text: TextSpan(
              text: valueFormatter(data[i].value * progress),
              style: boldStyle,
            ),
            textDirection: TextDirection.ltr,
            maxLines: 1,
          )..layout();
          vtp.paint(
            canvas,
            Offset(dot.dx + dotRadius + 4, dot.dy - vtp.height / 2),
          );
        }
      } else {
        // Category label below baseline.
        final labelTp = TextPainter(
          text: TextSpan(text: data[i].label, style: lblStyle),
          textDirection: TextDirection.ltr,
          maxLines: 1,
          ellipsis: '…',
        )..layout(maxWidth: 80);
        labelTp.paint(
          canvas,
          Offset(base.dx - labelTp.width / 2, base.dy + 6),
        );
        // Value label above dot.
        if (showValues) {
          final vtp = TextPainter(
            text: TextSpan(
              text: valueFormatter(data[i].value * progress),
              style: boldStyle,
            ),
            textDirection: TextDirection.ltr,
            maxLines: 1,
          )..layout();
          vtp.paint(
            canvas,
            Offset(dot.dx - vtp.width / 2, dot.dy - dotRadius - 4 - vtp.height),
          );
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant _LollipopPainter old) =>
      old.progress != progress ||
      old.data != data ||
      old.colors != colors ||
      old.orientation != orientation ||
      old.animation != animation;
}
