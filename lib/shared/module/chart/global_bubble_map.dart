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
import 'global_choropleth.dart' show MapProjection;

export 'chart_data.dart' show MapPoint, MapRegion;
export 'chart_models.dart' show ChartStyle, BubbleMapAnimation;

/// Bubble map — sized circles at geo points, optional region
/// outlines as a base layer. Bubble area is proportional to value.
///
/// ```dart
/// GlobalBubbleMap(
///   regions: [...],   // optional backdrop
///   points: [
///     MapPoint(label: 'NY', position: Offset(74, 41), value: 320),
///     MapPoint(label: 'LA', position: Offset(118, 34), value: 180),
///   ],
/// )
/// ```
class GlobalBubbleMap extends StatelessWidget {
  const GlobalBubbleMap({
    required this.points,
    this.regions = const [],
    this.style = ChartStyle.standard,
    this.animation = BubbleMapAnimation.pop,
    this.minRadius = 4,
    this.maxRadius = 28,
    this.bubbleColor,
    this.bubbleOpacity = 0.75,
    this.regionColor,
    this.regionOutline,
    this.showLabels = false,
    this.flipY = true,
    this.valueFormatter,
    super.key,
  });

  final List<MapPoint> points;
  final List<MapRegion> regions;
  final ChartStyle style;
  final BubbleMapAnimation animation;
  final double minRadius;
  final double maxRadius;
  final Color? bubbleColor;
  final double bubbleOpacity;

  /// Color for the backdrop region fill. Defaults to a faint
  /// surface tone.
  final Color? regionColor;

  /// Color for backdrop region outlines.
  final Color? regionOutline;

  final bool showLabels;
  final bool flipY;
  final String Function(double)? valueFormatter;

  @override
  Widget build(BuildContext context) {
    if (points.isEmpty && regions.isEmpty) return const SizedBox.shrink();
    final palette = resolveSeriesColors(context, style, 1);
    final color = bubbleColor ?? palette.first;
    final fillBg =
        regionColor ??
        context.backgroundColors.outlineVariant.withValues(alpha: 0.4);
    final outlineBg = regionOutline ?? context.backgroundColors.outlineVariant;
    final fmt = valueFormatter ?? (v) => AppNumbers.compact(v);
    final axisStyle = resolveAxisLabelStyle(context, style);
    final fg = context.textColors.primary;

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
                hitTest: (pos, size) => _hitTest(pos, size, color, fmt),
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
                      painter: _BubbleMapPainter(
                        regions: regions,
                        points: points,
                        regionFill: fillBg,
                        regionOutline: outlineBg,
                        bubbleColor: color,
                        bubbleOpacity: bubbleOpacity,
                        minRadius: minRadius,
                        maxRadius: maxRadius,
                        showLabels: showLabels,
                        flipY: flipY,
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
    Color color,
    String Function(double) fmt,
  ) {
    final layout = MapProjection.fit(
      regions: regions,
      points: points,
      flows: const [],
      size: size,
      flipY: flipY,
    );
    if (layout == null) return const [];
    var maxV = 0.0;
    for (final p in points) {
      if (p.value.abs() > maxV) maxV = p.value.abs();
    }
    if (maxV == 0) maxV = 1;
    var bestI = -1;
    var bestDist = double.infinity;
    for (var i = 0; i < points.length; i++) {
      final pp = layout.project(points[i].position);
      final r = _radiusFor(points[i].value, maxV);
      final d = (pp - pos).distance;
      if (d <= r + 4 && d < bestDist) {
        bestDist = d;
        bestI = i;
      }
    }
    if (bestI < 0) return const [];
    final p = points[bestI];
    return [
      TooltipEntry(
        label: p.label,
        value: fmt(p.value),
        color: p.color ?? color,
        icon: p.icon,
      ),
    ];
  }

  double _radiusFor(double v, double maxV) {
    final t = math.sqrt(v.abs() / maxV).clamp(0.0, 1.0);
    return minRadius + (maxRadius - minRadius) * t;
  }
}

class _BubbleMapPainter extends CustomPainter {
  _BubbleMapPainter({
    required this.regions,
    required this.points,
    required this.regionFill,
    required this.regionOutline,
    required this.bubbleColor,
    required this.bubbleOpacity,
    required this.minRadius,
    required this.maxRadius,
    required this.showLabels,
    required this.flipY,
    required this.axisStyle,
    required this.fg,
    required this.animation,
    required this.progress,
    required this.valueFormatter,
  });

  final List<MapRegion> regions;
  final List<MapPoint> points;
  final Color regionFill;
  final Color regionOutline;
  final Color bubbleColor;
  final double bubbleOpacity;
  final double minRadius;
  final double maxRadius;
  final bool showLabels;
  final bool flipY;
  final TextStyle axisStyle;
  final Color fg;
  final BubbleMapAnimation animation;
  final double progress;
  final String Function(double) valueFormatter;

  @override
  void paint(Canvas canvas, Size size) {
    final layout = MapProjection.fit(
      regions: regions,
      points: points,
      flows: const [],
      size: size,
      flipY: flipY,
    );
    if (layout == null) return;

    // Backdrop regions.
    for (final r in regions) {
      for (final ring in r.polygons) {
        if (ring.isEmpty) continue;
        final path = Path()
          ..moveTo(
            layout.project(ring.first).dx,
            layout.project(ring.first).dy,
          );
        for (var i = 1; i < ring.length; i++) {
          final pp = layout.project(ring[i]);
          path.lineTo(pp.dx, pp.dy);
        }
        path.close();
        canvas.drawPath(path, Paint()..color = regionFill);
        canvas.drawPath(
          path,
          Paint()
            ..color = regionOutline
            ..style = PaintingStyle.stroke
            ..strokeWidth = 0.8
            ..strokeJoin = StrokeJoin.round,
        );
      }
    }

    // Bubbles — sort largest-first so big bubbles paint UNDER
    // smaller ones (avoid covering tiny markers).
    var maxV = 0.0;
    for (final p in points) {
      if (p.value.abs() > maxV) maxV = p.value.abs();
    }
    if (maxV == 0) maxV = 1;
    final order = List<int>.generate(points.length, (i) => i)
      ..sort((a, b) => points[b].value.abs().compareTo(points[a].value.abs()));

    final cx = (layout.left + layout.right) / 2;
    final cy = (layout.top + layout.bottom) / 2;
    final maxD = math.sqrt(
      math.pow(layout.right - cx, 2) + math.pow(layout.bottom - cy, 2),
    );

    for (final idx in order) {
      final p = points[idx];
      final pp = layout.project(p.position);
      final r = _radiusFor(p.value, maxV);

      double scale;
      double opacity;
      switch (animation) {
        case BubbleMapAnimation.pop:
          // Largest bubbles delayed, smaller pop first — gradual reveal.
          final rankT = order.indexOf(idx) / points.length.toDouble();
          final delay = rankT * 0.35;
          final t = ((progress - delay) / (1 - delay)).clamp(0.0, 1.0);
          scale = t;
          opacity = 1.0;
        case BubbleMapAnimation.fade:
          scale = 1.0;
          opacity = progress;
        case BubbleMapAnimation.ripple:
          final d = (pp - Offset(cx, cy)).distance;
          final delay = (d / maxD) * 0.6;
          final t = ((progress - delay) / (1 - delay)).clamp(0.0, 1.0);
          scale = t;
          opacity = 1.0;
      }
      if (scale <= 0) continue;

      final c = (p.color ?? bubbleColor).withValues(
        alpha: bubbleOpacity * opacity,
      );
      canvas.drawCircle(pp, r * scale, Paint()..color = c);
      canvas.drawCircle(
        pp,
        r * scale,
        Paint()
          ..color = (p.color ?? bubbleColor).withValues(alpha: opacity)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.2,
      );

      // Label.
      if (!showLabels) continue;
      if (progress < 0.55) continue;
      final fadeRaw = ((progress - 0.55) / 0.45).clamp(0.0, 1.0);
      final fade = Curves.easeOutCubic.transform(fadeRaw);
      final tp = TextPainter(
        text: TextSpan(
          text: p.label,
          style: axisStyle.copyWith(
            color: fg.withValues(alpha: fade),
            fontWeight: FontWeight.w600,
            shadows: const [],
          ),
        ),
        textDirection: TextDirection.ltr,
        maxLines: 1,
        ellipsis: '…',
      )..layout(maxWidth: 80);
      tp.paint(canvas, Offset(pp.dx + r + 4, pp.dy - tp.height / 2));
    }
  }

  double _radiusFor(double v, double maxV) {
    final t = math.sqrt(v.abs() / maxV).clamp(0.0, 1.0);
    return minRadius + (maxRadius - minRadius) * t;
  }

  @override
  bool shouldRepaint(covariant _BubbleMapPainter old) =>
      old.progress != progress ||
      old.regions != regions ||
      old.points != points ||
      old.animation != animation;
}
