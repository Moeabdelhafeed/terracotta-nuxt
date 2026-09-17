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

export 'chart_data.dart' show MapRegion;
export 'chart_models.dart' show ChartStyle, ChoroplethAnimation;

/// Choropleth — colored map regions. Each [MapRegion] is filled
/// with a color interpolated from a sequential ramp by its value.
///
/// The chart auto-fits to the union of all polygons. Coordinates
/// are pre-projected (the chart never transforms lat/lng) — the
/// caller passes whatever 2D coords they have.
///
/// ```dart
/// GlobalChoropleth(
///   regions: [
///     MapRegion(id: 'na', label: 'NA', polygons: [...], value: 320),
///     MapRegion(id: 'eu', label: 'EU', polygons: [...], value: 220),
///   ],
/// )
/// ```
class GlobalChoropleth extends StatelessWidget {
  const GlobalChoropleth({
    required this.regions,
    this.style = ChartStyle.standard,
    this.animation = ChoroplethAnimation.fillIn,
    this.minColor,
    this.maxColor,
    this.outlineColor,
    this.outlineWidth = 0.8,
    this.showLabels = true,
    this.showValues = false,
    this.flipY = true,
    this.valueFormatter,
    super.key,
  });

  final List<MapRegion> regions;
  final ChartStyle style;
  final ChoroplethAnimation animation;
  final Color? minColor;
  final Color? maxColor;
  final Color? outlineColor;
  final double outlineWidth;
  final bool showLabels;
  final bool showValues;

  /// When true (default), larger source-y values render higher on
  /// the canvas — matches geographic convention (north = top).
  /// Set to false if your input already uses screen-y direction.
  final bool flipY;

  final String Function(double)? valueFormatter;

  @override
  Widget build(BuildContext context) {
    if (regions.isEmpty) return const SizedBox.shrink();
    final palette = resolveSeriesColors(context, style, 1);
    final base = palette.first;
    final lo = minColor ?? base.withValues(alpha: 0.18);
    final hi = maxColor ?? base;
    final outline = outlineColor ?? context.backgroundColors.cardBackground;
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
                hitTest: (pos, size) => _hitTest(pos, size, fmt, lo, hi),
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
                      painter: _ChoroplethPainter(
                        regions: regions,
                        lo: lo,
                        hi: hi,
                        outline: outline,
                        outlineWidth: outlineWidth,
                        showLabels: showLabels,
                        showValues: showValues,
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
    String Function(double) fmt,
    Color lo,
    Color hi,
  ) {
    final layout = MapProjection.fit(
      regions: regions,
      points: const [],
      flows: const [],
      size: size,
      flipY: flipY,
    );
    if (layout == null) return const [];
    var bounds = _ValueBounds.compute(regions);
    for (var i = 0; i < regions.length; i++) {
      final r = regions[i];
      for (final ring in r.polygons) {
        final projected = ring.map(layout.project).toList();
        if (_pointInPolygon(pos, projected)) {
          final color = bounds.span > 0
              ? Color.lerp(lo, hi, (r.value - bounds.lo) / bounds.span)!
              : hi;
          return [
            TooltipEntry(
              label: r.label,
              value: fmt(r.value),
              color: r.color ?? color,
            ),
          ];
        }
      }
    }
    return const [];
  }

  static bool _pointInPolygon(Offset p, List<Offset> poly) {
    var inside = false;
    final n = poly.length;
    for (var i = 0, j = n - 1; i < n; j = i++) {
      final pi = poly[i];
      final pj = poly[j];
      final cond =
          (pi.dy > p.dy) != (pj.dy > p.dy) &&
          p.dx <
              (pj.dx - pi.dx) *
                      (p.dy - pi.dy) /
                      ((pj.dy - pi.dy) == 0 ? 1e-9 : pj.dy - pi.dy) +
                  pi.dx;
      if (cond) inside = !inside;
    }
    return inside;
  }
}

class _ValueBounds {
  _ValueBounds(this.lo, this.hi);
  final double lo;
  final double hi;
  double get span => hi - lo;
  static _ValueBounds compute(List<MapRegion> rs) {
    var lo = double.infinity;
    var hi = -double.infinity;
    for (final r in rs) {
      if (r.value < lo) lo = r.value;
      if (r.value > hi) hi = r.value;
    }
    if (lo == double.infinity) {
      lo = 0;
      hi = 1;
    }
    if (hi == lo) hi = lo + 1;
    return _ValueBounds(lo, hi);
  }
}

/// Shared projection helper — fits any combination of regions /
/// points / flows into the available canvas with consistent scale.
class MapProjection {
  MapProjection({
    required this.xMin,
    required this.xMax,
    required this.yMin,
    required this.yMax,
    required this.left,
    required this.right,
    required this.top,
    required this.bottom,
    required this.flipY,
  });

  final double xMin;
  final double xMax;
  final double yMin;
  final double yMax;
  final double left;
  final double right;
  final double top;
  final double bottom;
  final bool flipY;

  Offset project(Offset src) {
    final tx = (src.dx - xMin) / (xMax - xMin);
    final ty = (src.dy - yMin) / (yMax - yMin);
    final x = left + tx * (right - left);
    final yLin = top + ty * (bottom - top);
    return Offset(x, flipY ? bottom - (yLin - top) : yLin);
  }

  static MapProjection? fit({
    required List<MapRegion> regions,
    required List<MapPoint> points,
    required List<MapFlow> flows,
    required Size size,
    required bool flipY,
    double pad = 12,
  }) {
    if (size.width <= 0 || size.height <= 0) return null;
    var xLo = double.infinity;
    var xHi = -double.infinity;
    var yLo = double.infinity;
    var yHi = -double.infinity;
    void touch(double x, double y) {
      if (x < xLo) xLo = x;
      if (x > xHi) xHi = x;
      if (y < yLo) yLo = y;
      if (y > yHi) yHi = y;
    }

    for (final r in regions) {
      for (final ring in r.polygons) {
        for (final p in ring) {
          touch(p.dx, p.dy);
        }
      }
    }
    for (final p in points) {
      touch(p.position.dx, p.position.dy);
    }
    for (final f in flows) {
      touch(f.from.dx, f.from.dy);
      touch(f.to.dx, f.to.dy);
    }
    if (xLo == double.infinity) return null;
    if (xHi == xLo) xHi = xLo + 1;
    if (yHi == yLo) yHi = yLo + 1;

    // Aspect-fit into available size.
    final canvasW = size.width - pad * 2;
    final canvasH = size.height - pad * 2;
    final dataAspect = (xHi - xLo) / (yHi - yLo);
    final canvasAspect = canvasW / canvasH;
    double drawW;
    double drawH;
    if (dataAspect > canvasAspect) {
      drawW = canvasW;
      drawH = canvasW / dataAspect;
    } else {
      drawH = canvasH;
      drawW = canvasH * dataAspect;
    }
    final left = pad + (canvasW - drawW) / 2;
    final right = left + drawW;
    final top = pad + (canvasH - drawH) / 2;
    final bottom = top + drawH;

    return MapProjection(
      xMin: xLo,
      xMax: xHi,
      yMin: yLo,
      yMax: yHi,
      left: left,
      right: right,
      top: top,
      bottom: bottom,
      flipY: flipY,
    );
  }
}

class _ChoroplethPainter extends CustomPainter {
  _ChoroplethPainter({
    required this.regions,
    required this.lo,
    required this.hi,
    required this.outline,
    required this.outlineWidth,
    required this.showLabels,
    required this.showValues,
    required this.flipY,
    required this.axisStyle,
    required this.fg,
    required this.animation,
    required this.progress,
    required this.valueFormatter,
  });

  final List<MapRegion> regions;
  final Color lo;
  final Color hi;
  final Color outline;
  final double outlineWidth;
  final bool showLabels;
  final bool showValues;
  final bool flipY;
  final TextStyle axisStyle;
  final Color fg;
  final ChoroplethAnimation animation;
  final double progress;
  final String Function(double) valueFormatter;

  @override
  void paint(Canvas canvas, Size size) {
    final layout = MapProjection.fit(
      regions: regions,
      points: const [],
      flows: const [],
      size: size,
      flipY: flipY,
    );
    if (layout == null) return;
    final bounds = _ValueBounds.compute(regions);
    final cx = (layout.left + layout.right) / 2;
    final cy = (layout.top + layout.bottom) / 2;
    final maxR = math.sqrt(
      math.pow(layout.right - cx, 2) + math.pow(layout.bottom - cy, 2),
    );

    // Sort regions by value for fillIn animation.
    final sorted = List<int>.generate(regions.length, (i) => i)
      ..sort((a, b) => regions[a].value.compareTo(regions[b].value));
    final orderRank = List<int>.filled(regions.length, 0);
    for (var k = 0; k < sorted.length; k++) {
      orderRank[sorted[k]] = k;
    }

    for (var i = 0; i < regions.length; i++) {
      final r = regions[i];
      double opacity;
      switch (animation) {
        case ChoroplethAnimation.fade:
          opacity = progress;
        case ChoroplethAnimation.fillIn:
          final rankT = orderRank[i] / regions.length.toDouble();
          opacity = ((progress - rankT * 0.6) / (1 - rankT * 0.6)).clamp(
            0.0,
            1.0,
          );
        case ChoroplethAnimation.ripple:
          // Stagger by distance from chart center.
          final pp = r.polygons.first;
          var sumX = 0.0;
          var sumY = 0.0;
          for (final p in pp) {
            final pr = layout.project(p);
            sumX += pr.dx;
            sumY += pr.dy;
          }
          final cxr = sumX / pp.length;
          final cyr = sumY / pp.length;
          final d = math.sqrt(math.pow(cxr - cx, 2) + math.pow(cyr - cy, 2));
          final delay = (d / maxR) * 0.6;
          opacity = ((progress - delay) / (1 - delay)).clamp(0.0, 1.0);
      }
      if (opacity <= 0) continue;

      final base = bounds.span > 0
          ? Color.lerp(lo, hi, (r.value - bounds.lo) / bounds.span)!
          : hi;
      final fillColor = (r.color ?? base).withValues(alpha: opacity);

      for (final ring in r.polygons) {
        final path = _ringPath(ring, layout);
        canvas.drawPath(path, Paint()..color = fillColor);
        if (outlineWidth > 0) {
          canvas.drawPath(
            path,
            Paint()
              ..color = outline.withValues(alpha: opacity)
              ..strokeWidth = outlineWidth
              ..style = PaintingStyle.stroke
              ..strokeJoin = StrokeJoin.round,
          );
        }
      }

      // Label inside polygon centroid (if room).
      if (!showLabels && !showValues) continue;
      if (progress < 0.55) continue;
      final fadeRaw = ((progress - 0.55) / 0.45).clamp(0.0, 1.0);
      final fade = Curves.easeOutCubic.transform(fadeRaw);
      final centroid = _polygonCentroid(r.polygons.first, layout);
      final lblColor = _labelColorFor(base);
      final text = StringBuffer();
      if (showLabels) text.write(r.label);
      if (showValues) {
        if (text.isNotEmpty) text.write('\n');
        text.write(valueFormatter(r.value));
      }
      final tp = TextPainter(
        text: TextSpan(
          text: text.toString(),
          style: axisStyle.copyWith(
            color: lblColor.withValues(alpha: fade),
            fontWeight: FontWeight.w600,
            shadows: const [],
          ),
        ),
        textDirection: TextDirection.ltr,
        textAlign: TextAlign.center,
        maxLines: 2,
        ellipsis: '…',
      )..layout(maxWidth: 90);
      tp.paint(
        canvas,
        Offset(centroid.dx - tp.width / 2, centroid.dy - tp.height / 2),
      );
    }
  }

  Path _ringPath(List<Offset> ring, MapProjection layout) {
    final path = Path();
    if (ring.isEmpty) return path;
    final first = layout.project(ring.first);
    path.moveTo(first.dx, first.dy);
    for (var i = 1; i < ring.length; i++) {
      final p = layout.project(ring[i]);
      path.lineTo(p.dx, p.dy);
    }
    path.close();
    return path;
  }

  Offset _polygonCentroid(List<Offset> ring, MapProjection layout) {
    if (ring.isEmpty) return Offset.zero;
    var sumX = 0.0;
    var sumY = 0.0;
    for (final p in ring) {
      final pr = layout.project(p);
      sumX += pr.dx;
      sumY += pr.dy;
    }
    return Offset(sumX / ring.length, sumY / ring.length);
  }

  Color _labelColorFor(Color bg) {
    final lum = bg.computeLuminance();
    return lum > 0.55 ? const Color(0xFF1A1A1A) : const Color(0xFFEDEDED);
  }

  @override
  bool shouldRepaint(covariant _ChoroplethPainter old) =>
      old.progress != progress ||
      old.regions != regions ||
      old.animation != animation;
}
