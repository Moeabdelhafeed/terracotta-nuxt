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

export 'chart_data.dart' show MapFlow, MapPoint, MapRegion;
export 'chart_models.dart' show ChartStyle, FlowMapAnimation;

/// Flow map — directed bezier arcs between geo points. Arc width
/// is proportional to flow value; optional region/point layers
/// provide spatial context.
///
/// ```dart
/// GlobalFlowMap(
///   regions: [...],
///   flows: [
///     MapFlow(label: 'NY→LA', from: Offset(74, 41),
///         to: Offset(118, 34), value: 320),
///   ],
/// )
/// ```
class GlobalFlowMap extends StatelessWidget {
  const GlobalFlowMap({
    required this.flows,
    this.regions = const [],
    this.points = const [],
    this.style = ChartStyle.standard,
    this.animation = FlowMapAnimation.draw,
    this.minWidth = 1.0,
    this.maxWidth = 6.0,
    this.arcHeight = 0.35,
    this.flowColor,
    this.flowOpacity = 0.7,
    this.regionColor,
    this.regionOutline,
    this.terminalRadius = 3.0,
    this.flipY = true,
    this.valueFormatter,
    super.key,
  });

  final List<MapFlow> flows;
  final List<MapRegion> regions;
  final List<MapPoint> points;
  final ChartStyle style;
  final FlowMapAnimation animation;
  final double minWidth;
  final double maxWidth;

  /// Arc height as a fraction of the from→to distance. Higher =
  /// more curved arcs.
  final double arcHeight;

  final Color? flowColor;
  final double flowOpacity;
  final Color? regionColor;
  final Color? regionOutline;
  final double terminalRadius;
  final bool flipY;
  final String Function(double)? valueFormatter;

  @override
  Widget build(BuildContext context) {
    if (flows.isEmpty && regions.isEmpty) {
      return const SizedBox.shrink();
    }
    final palette = resolveSeriesColors(context, style, 1);
    final color = flowColor ?? palette.first;
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
                      painter: _FlowMapPainter(
                        regions: regions,
                        points: points,
                        flows: flows,
                        regionFill: fillBg,
                        regionOutline: outlineBg,
                        flowColor: color,
                        flowOpacity: flowOpacity,
                        minWidth: minWidth,
                        maxWidth: maxWidth,
                        arcHeight: arcHeight,
                        terminalRadius: terminalRadius,
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
      flows: flows,
      size: size,
      flipY: flipY,
    );
    if (layout == null) return const [];
    var bestI = -1;
    var bestDist = double.infinity;
    for (var i = 0; i < flows.length; i++) {
      final f = flows[i];
      final from = layout.project(f.from);
      final to = layout.project(f.to);
      final mid = _arcMidpoint(from, to, arcHeight);
      final d = (mid - pos).distance;
      if (d < bestDist) {
        bestDist = d;
        bestI = i;
      }
    }
    if (bestI < 0 || bestDist > 22) return const [];
    final f = flows[bestI];
    return [
      TooltipEntry(
        label: f.label,
        value: fmt(f.value),
        color: f.color ?? color,
      ),
    ];
  }

  static Offset _arcMidpoint(Offset a, Offset b, double arcHeight) {
    final mx = (a.dx + b.dx) / 2;
    final my = (a.dy + b.dy) / 2;
    final dx = b.dx - a.dx;
    final dy = b.dy - a.dy;
    final dist = math.sqrt(dx * dx + dy * dy);
    if (dist == 0) return Offset(mx, my);
    final nx = -dy / dist;
    final ny = dx / dist;
    return Offset(
      mx + nx * dist * arcHeight,
      my + ny * dist * arcHeight,
    );
  }
}

class _FlowMapPainter extends CustomPainter {
  _FlowMapPainter({
    required this.regions,
    required this.points,
    required this.flows,
    required this.regionFill,
    required this.regionOutline,
    required this.flowColor,
    required this.flowOpacity,
    required this.minWidth,
    required this.maxWidth,
    required this.arcHeight,
    required this.terminalRadius,
    required this.flipY,
    required this.axisStyle,
    required this.fg,
    required this.animation,
    required this.progress,
    required this.valueFormatter,
  });

  final List<MapRegion> regions;
  final List<MapPoint> points;
  final List<MapFlow> flows;
  final Color regionFill;
  final Color regionOutline;
  final Color flowColor;
  final double flowOpacity;
  final double minWidth;
  final double maxWidth;
  final double arcHeight;
  final double terminalRadius;
  final bool flipY;
  final TextStyle axisStyle;
  final Color fg;
  final FlowMapAnimation animation;
  final double progress;
  final String Function(double) valueFormatter;

  @override
  void paint(Canvas canvas, Size size) {
    final layout = MapProjection.fit(
      regions: regions,
      points: points,
      flows: flows,
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

    // Flow widths.
    var maxV = 0.0;
    for (final f in flows) {
      if (f.value.abs() > maxV) maxV = f.value.abs();
    }
    if (maxV == 0) maxV = 1;

    for (var i = 0; i < flows.length; i++) {
      final f = flows[i];
      final from = layout.project(f.from);
      final to = layout.project(f.to);
      final dx = to.dx - from.dx;
      final dy = to.dy - from.dy;
      final dist = math.sqrt(dx * dx + dy * dy);
      if (dist == 0) continue;
      // Perpendicular for arc bow.
      final nx = -dy / dist;
      final ny = dx / dist;
      final ctrl = Offset(
        (from.dx + to.dx) / 2 + nx * dist * arcHeight,
        (from.dy + to.dy) / 2 + ny * dist * arcHeight,
      );
      final w = minWidth + (maxWidth - minWidth) * (f.value.abs() / maxV);

      // Animation params.
      final delay = i / flows.length * 0.15;
      final flowT = ((progress - delay) / (1 - delay)).clamp(0.0, 1.0);
      double drawProgress;
      double opacity;
      var pulseT = -1.0;
      switch (animation) {
        case FlowMapAnimation.draw:
          drawProgress = flowT;
          opacity = 1.0;
        case FlowMapAnimation.fade:
          drawProgress = 1.0;
          opacity = progress;
        case FlowMapAnimation.pulse:
          drawProgress = flowT.clamp(0.0, 0.6) / 0.6;
          opacity = 1.0;
          if (flowT > 0.6) {
            pulseT = ((flowT - 0.6) / 0.4).clamp(0.0, 1.0);
          }
      }
      if (drawProgress <= 0) continue;

      final c = (f.color ?? flowColor).withValues(
        alpha: flowOpacity * opacity,
      );
      final cBright = (f.color ?? flowColor).withValues(alpha: opacity);

      // Draw partial bezier from `from` to (1 - drawProgress) along
      // the curve via De Casteljau subdivision.
      final endT = drawProgress;
      const samples = 32;
      var prev = from;
      final paint = Paint()
        ..color = c
        ..strokeWidth = w
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;
      for (var s = 1; s <= samples; s++) {
        final t = (s / samples) * endT;
        final pt = _quad(from, ctrl, to, t);
        canvas.drawLine(prev, pt, paint);
        prev = pt;
      }

      // Terminal dot at "from".
      canvas.drawCircle(
        from,
        terminalRadius,
        Paint()..color = cBright,
      );

      // Terminal dot at "to" once draw completes.
      if (drawProgress >= 1) {
        canvas.drawCircle(
          to,
          terminalRadius * 1.3,
          Paint()..color = cBright,
        );
        canvas.drawCircle(
          to,
          terminalRadius * 1.3,
          Paint()
            ..color = Colors.white.withValues(alpha: opacity)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.2,
        );
      }

      // Pulse traveling along the curve.
      if (pulseT > 0) {
        final pp = _quad(from, ctrl, to, pulseT);
        canvas.drawCircle(
          pp,
          w * 1.1,
          Paint()
            ..color = cBright
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
        );
        canvas.drawCircle(
          pp,
          w * 0.6,
          Paint()..color = cBright,
        );
      }
    }

    // Optional points overlay.
    for (final p in points) {
      final pp = layout.project(p.position);
      canvas.drawCircle(
        pp,
        terminalRadius * 1.4,
        Paint()..color = (p.color ?? flowColor).withValues(alpha: progress),
      );
    }
  }

  Offset _quad(Offset a, Offset c, Offset b, double t) {
    final omt = 1 - t;
    return Offset(
      omt * omt * a.dx + 2 * omt * t * c.dx + t * t * b.dx,
      omt * omt * a.dy + 2 * omt * t * c.dy + t * t * b.dy,
    );
  }

  @override
  bool shouldRepaint(covariant _FlowMapPainter old) =>
      old.progress != progress ||
      old.flows != flows ||
      old.regions != regions ||
      old.animation != animation;
}
