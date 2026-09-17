import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:graphic/graphic.dart' as g;

import '../../../core/extensions/theme_colors_extension.dart';
import 'chart_data.dart';
import 'chart_internals.dart';
import 'chart_legend.dart';
import 'chart_models.dart';
import 'chart_tooltip_overlay.dart';

export 'chart_data.dart';
export 'chart_legend.dart' show ChartLegendEntry;
export 'chart_models.dart';

/// Multi-series radar chart powered by `graphic` (polar coord +
/// closed line marks).
///
/// ```dart
/// GlobalRadarChart(
///   labels: const ['Speed', 'Power', 'Range', 'Accuracy', 'Cost'],
///   series: [
///     RadarSeries(name: 'Model A', values: [80, 60, 70, 90, 50]),
///     RadarSeries(name: 'Model B', values: [60, 90, 50, 70, 80]),
///   ],
/// )
/// ```
class GlobalRadarChart extends StatefulWidget {
  const GlobalRadarChart({
    required this.labels,
    required this.series,
    this.style = ChartStyle.standard,
    this.tickCount = 4,
    this.shape = RadarShape.polygon,
    this.animation = RadarChartAnimation.growUp,
    super.key,
  });

  final List<String> labels;
  final List<RadarSeries> series;
  final ChartStyle style;
  final int tickCount;
  final RadarShape shape;

  /// Entry animation preset. See [RadarChartAnimation].
  final RadarChartAnimation animation;

  @override
  State<GlobalRadarChart> createState() => _GlobalRadarChartState();
}

class _GlobalRadarChartState extends State<GlobalRadarChart> {
  StreamController<g.GestureEvent>? _gestureStream;
  StreamController<g.Selected?>? _selectionStream;

  List<String> get labels => widget.labels;
  List<RadarSeries> get series => widget.series;
  ChartStyle get style => widget.style;
  int get tickCount => widget.tickCount;
  RadarShape get shape => widget.shape;
  RadarChartAnimation get animation => widget.animation;

  bool get _useOverlay => style.enableTooltip;
  ChartTooltipBuilder get _tooltipBuilder =>
      style.tooltipBuilder ?? defaultTooltipBuilder;

  /// Map [RadarChartAnimation] to graphic's native [g.MarkEntrance].
  /// `scale` and `spin` return null — those modes use Flutter-side
  /// transform wrappers instead (graphic's polar entrances don't
  /// translate cleanly to circular polygon shapes).
  Set<g.MarkEntrance>? get _markEntrance => switch (animation) {
    RadarChartAnimation.growUp => const {g.MarkEntrance.y},
    RadarChartAnimation.fade => const {g.MarkEntrance.opacity},
    RadarChartAnimation.scale => null,
    RadarChartAnimation.spin => null,
  };

  @override
  void initState() {
    super.initState();
    if (_useOverlay) {
      _gestureStream = StreamController<g.GestureEvent>.broadcast();
      _selectionStream = StreamController<g.Selected?>.broadcast();
    }
  }

  @override
  void dispose() {
    _gestureStream?.close();
    _selectionStream?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (series.isEmpty || labels.isEmpty) return const SizedBox.shrink();

    final colors = resolveSeriesColors(context, style, series.length);
    final axisStyle = resolveAxisLabelStyle(context, style);
    final gridColor = resolveGridColor(context, style);

    // Flatten: [{ 'axis': label, 'value': v, 'series': name }, …]
    final data = <Map<String, dynamic>>[];
    for (var s = 0; s < series.length; s++) {
      final ser = series[s];
      for (var i = 0; i < ser.values.length && i < labels.length; i++) {
        data.add({
          'axis': labels[i],
          'value': ser.values[i],
          'series': ser.name,
        });
      }
    }

    final smooth = shape == RadarShape.circle;
    final isMulti = series.length > 1;
    final fillColors = [for (final c in colors) c.withValues(alpha: 0.18)];
    final isPolygon = shape == RadarShape.polygon;

    // Gradient handling — graphic forbids both `color` and `gradient`
    // on a mark, so when ANY series provides a gradient we switch
    // the whole mark to GradientEncode and synthesize flat gradients
    // for the rest from their resolved color.
    final hasLineGradient = series.any((s) => s.lineGradient != null);
    final hasFillGradient = series.any((s) => s.fillGradient != null);
    final lineGradients = [
      for (var i = 0; i < series.length; i++)
        series[i].lineGradient ?? flatGradient(series[i].color ?? colors[i]),
    ];
    final fillGradients = [
      for (var i = 0; i < series.length; i++)
        series[i].fillGradient ?? flatGradient(fillColors[i]),
    ];

    final chart = EntranceGate(
      enabled: style.enableAnimation,
      duration: style.effectiveAnimationDuration,
      builder: (playEntrance) => IgnorePointer(
        ignoring: playEntrance,
        child: g.Chart<Map<String, dynamic>>(
          gestureStream: _useOverlay ? _gestureStream : null,
          data: data,
          variables: {
            'axis': g.Variable(accessor: (m) => m['axis'] as String),
            'value': g.Variable(
              accessor: (m) => (m['value'] as num).toDouble(),
              scale: g.LinearScale(
                formatter: (v) => formatChartNumber(v, style),
              ),
            ),
            'series': g.Variable(accessor: (m) => m['series'] as String),
          },
          coord: g.PolarCoord(),
          marks: [
            // Filled area for visual weight.
            g.AreaMark(
              position: isMulti
                  ? g.Varset('axis') * g.Varset('value') / g.Varset('series')
                  : null,
              shape: g.ShapeEncode(
                value: g.BasicAreaShape(smooth: smooth, loop: true),
              ),
              color: hasFillGradient
                  ? null
                  : (isMulti
                        ? g.ColorEncode(variable: 'series', values: fillColors)
                        : g.ColorEncode(value: fillColors.first)),
              gradient: hasFillGradient
                  ? (isMulti
                        ? g.GradientEncode(
                            variable: 'series',
                            values: fillGradients,
                          )
                        : g.GradientEncode(value: fillGradients.first))
                  : null,
              transition: playEntrance && _markEntrance != null
                  ? g.Transition(
                      duration: style.effectiveAnimationDuration,
                      curve: style.effectiveAnimationCurve,
                    )
                  : null,
              entrance: playEntrance ? _markEntrance : null,
            ),
            // Border line.
            g.LineMark(
              position: isMulti
                  ? g.Varset('axis') * g.Varset('value') / g.Varset('series')
                  : null,
              shape: g.ShapeEncode(
                value: g.BasicLineShape(smooth: smooth, loop: true),
              ),
              color: hasLineGradient
                  ? null
                  : (isMulti
                        ? g.ColorEncode(variable: 'series', values: colors)
                        : g.ColorEncode(value: colors.first)),
              gradient: hasLineGradient
                  ? (isMulti
                        ? g.GradientEncode(
                            variable: 'series',
                            values: lineGradients,
                          )
                        : g.GradientEncode(value: lineGradients.first))
                  : null,
              size: g.SizeEncode(value: 2),
              transition: playEntrance && _markEntrance != null
                  ? g.Transition(
                      duration: style.effectiveAnimationDuration,
                      curve: style.effectiveAnimationCurve,
                    )
                  : null,
              entrance: playEntrance ? _markEntrance : null,
            ),
            // Vertices.
            if (style.density != ChartDensity.minimal)
              g.PointMark(
                position: isMulti
                    ? g.Varset('axis') * g.Varset('value') / g.Varset('series')
                    : null,
                color: hasLineGradient
                    ? null
                    : (isMulti
                          ? g.ColorEncode(variable: 'series', values: colors)
                          : g.ColorEncode(value: colors.first)),
                gradient: hasLineGradient
                    ? (isMulti
                          ? g.GradientEncode(
                              variable: 'series',
                              values: lineGradients,
                            )
                          : g.GradientEncode(value: lineGradients.first))
                    : null,
                size: g.SizeEncode(value: 6),
                selectionStream: _useOverlay ? _selectionStream : null,
                transition: playEntrance && _markEntrance != null
                    ? g.Transition(
                        duration: style.effectiveAnimationDuration,
                        curve: style.effectiveAnimationCurve,
                      )
                    : null,
                entrance: playEntrance ? _markEntrance : null,
              ),
          ],
          axes: [
            // Angular axis — categorical labels around perimeter.
            // `position: 1` anchors labels at the outer radius
            // (default 0 places them at center). Polar coord forbids
            // tickLine on the angular axis.
            g.AxisGuide(
              position: 1,
              label: g.LabelStyle(textStyle: axisStyle),
              line: g.PaintStyle(strokeColor: gridColor.withValues(alpha: 0.0)),
              // Polygon mode draws its own grid via [_RadarPolygonPainter].
              grid: isPolygon
                  ? null
                  : g.PaintStyle(strokeColor: gridColor, strokeWidth: 0.5),
            ),
            // Radial axis — value rings.
            g.AxisGuide(
              label: g.LabelStyle(
                textStyle: axisStyle.copyWith(
                  color: context.textColors.disabled,
                  fontSize: 9,
                ),
              ),
              line: g.PaintStyle(strokeColor: gridColor),
              grid: isPolygon
                  ? null
                  : g.PaintStyle(strokeColor: gridColor, strokeWidth: 0.5),
            ),
          ],
          selections: style.enableTooltip
              ? {
                  'tooltip': g.PointSelection(
                    on: const {
                      g.GestureType.hover,
                      g.GestureType.tapDown,
                    },
                    clear: const {g.GestureType.mouseExit},
                  ),
                }
              : null,
          tooltip: _useOverlay ? null : buildChartTooltip(context, style),
        ),
      ),
    );

    final entries = <ChartLegendEntry>[
      for (var i = 0; i < series.length; i++)
        ChartLegendEntry(
          label: series[i].name,
          color: series[i].color ?? colors[i],
          icon: series[i].icon,
          iconAsset: series[i].iconAsset,
          iconWidget: series[i].iconWidget,
        ),
    ];

    final framed = isPolygon
        ? Stack(
            fit: StackFit.expand,
            children: [
              CustomPaint(
                painter: _RadarPolygonPainter(
                  axisCount: labels.length,
                  tickCount: tickCount,
                  color: gridColor,
                ),
              ),
              chart,
            ],
          )
        : chart;

    // Spin / scale animations transform the whole radar plot
    // (chart + polygon backdrop). Tooltip overlay sits on top so
    // pointer math stays anchored to the post-transform plot bounds.
    var transformed = framed;
    if (style.enableAnimation) {
      if (animation == RadarChartAnimation.spin) {
        transformed = _RadarSpinIn(
          duration: style.effectiveAnimationDuration,
          curve: style.effectiveAnimationCurve,
          child: transformed,
        );
      } else if (animation == RadarChartAnimation.scale) {
        transformed = _RadarScaleIn(
          duration: style.effectiveAnimationDuration,
          curve: style.effectiveAnimationCurve,
          child: transformed,
        );
      }
    }

    final withTooltip = _useOverlay
        ? ChartTooltipOverlay(
            gestureStream: _gestureStream!,
            selectionStream: _selectionStream!,
            builder: _tooltipBuilder,
            resolveEntries: (selected) =>
                _resolveTooltipEntries(selected, data, colors),
            child: transformed,
          )
        : transformed;

    return _wrap(entries, withTooltip);
  }

  List<TooltipEntry> _resolveTooltipEntries(
    Set<int> selected,
    List<Map<String, dynamic>> data,
    List<Color> colors,
  ) {
    if (selected.isEmpty) return const [];
    final byName = <String, RadarSeries>{
      for (final s in series) s.name: s,
    };
    final colorByName = <String, Color>{
      for (var i = 0; i < series.length; i++)
        series[i].name: series[i].color ?? colors[i],
    };
    final out = <String, TooltipEntry>{};
    for (final i in selected) {
      if (i < 0 || i >= data.length) continue;
      final row = data[i];
      final name = row['series'] as String;
      final ser = byName[name];
      final axis = row['axis'] as String;
      final val = (row['value'] as num).toDouble();
      final formatted = '$axis · ${formatChartNumber(val, style)}';
      out[name] = TooltipEntry(
        label: name,
        value: formatted,
        color: colorByName[name] ?? Colors.grey,
        icon: ser?.icon,
        iconAsset: ser?.iconAsset,
        iconWidget: ser?.iconWidget,
      );
    }
    return out.values.toList(growable: false);
  }

  Widget _wrap(List<ChartLegendEntry> entries, Widget chart) {
    final body = Padding(
      padding: style.padding,
      child: chart,
    );

    if (!style.effectiveShowLegend) return _sized(body);

    final legend = ChartLegend(
      entries: entries,
      position: style.legendPosition,
    );

    switch (style.legendPosition) {
      case ChartLegendPosition.top:
        return _sized(
          Column(
            children: [
              legend,
              const SizedBox(height: 8),
              Expanded(child: body),
            ],
          ),
        );
      case ChartLegendPosition.bottom:
        return _sized(
          Column(
            children: [
              Expanded(child: body),
              const SizedBox(height: 8),
              legend,
            ],
          ),
        );
      case ChartLegendPosition.left:
        return _sized(
          Row(
            children: [
              legend,
              const SizedBox(width: 8),
              Expanded(child: body),
            ],
          ),
        );
      case ChartLegendPosition.right:
        return _sized(
          Row(
            children: [
              Expanded(child: body),
              const SizedBox(width: 8),
              legend,
            ],
          ),
        );
      case ChartLegendPosition.hidden:
        return _sized(body);
    }
  }

  Widget _sized(Widget child) {
    return Builder(
      builder: (context) => Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minHeight: style.minHeight,
            maxWidth: resolveSquareChartMaxWidth(context, style),
          ),
          child: AspectRatio(aspectRatio: 1, child: child),
        ),
      ),
    );
  }
}

/// Paints concentric polygons + radial spokes behind the radar chart
/// when [RadarShape.polygon] is selected. graphic only renders
/// circular polar grids natively, so polygon backgrounds need this
/// underlay.
class _RadarPolygonPainter extends CustomPainter {
  const _RadarPolygonPainter({
    required this.axisCount,
    required this.tickCount,
    required this.color,
  });

  final int axisCount;
  final int tickCount;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    if (axisCount < 3 || tickCount < 1) return;

    final center = size.center(Offset.zero);
    // Match graphic's polar default — slightly inset from edges so
    // the polygon sits flush with the data area (graphic reserves
    // ~10dp around the polar region).
    final maxR = (size.shortestSide / 2) - 10;
    if (maxR <= 0) return;

    final paint = Paint()
      ..color = color
      ..strokeWidth = 0.5
      ..style = PaintingStyle.stroke;

    // Concentric polygon rings.
    for (var t = 1; t <= tickCount; t++) {
      final r = maxR * (t / tickCount);
      canvas.drawPath(_polygonPath(center, r), paint);
    }

    // Radial spokes from center to outermost vertices.
    for (var i = 0; i < axisCount; i++) {
      final angle = -math.pi / 2 + (2 * math.pi * i / axisCount);
      final tipX = center.dx + maxR * math.cos(angle);
      final tipY = center.dy + maxR * math.sin(angle);
      canvas.drawLine(center, Offset(tipX, tipY), paint);
    }
  }

  Path _polygonPath(Offset center, double r) {
    final path = Path();
    for (var i = 0; i <= axisCount; i++) {
      final angle = -math.pi / 2 + (2 * math.pi * i / axisCount);
      final x = center.dx + r * math.cos(angle);
      final y = center.dy + r * math.sin(angle);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    return path..close();
  }

  @override
  bool shouldRepaint(covariant _RadarPolygonPainter old) =>
      old.axisCount != axisCount ||
      old.tickCount != tickCount ||
      old.color != color;
}

/// Rotates [child] from -π to 0 once on mount — radar dials into place.
class _RadarSpinIn extends StatefulWidget {
  const _RadarSpinIn({
    required this.duration,
    required this.curve,
    required this.child,
  });

  final Duration duration;
  final Curve curve;
  final Widget child;

  @override
  State<_RadarSpinIn> createState() => _RadarSpinInState();
}

class _RadarSpinInState extends State<_RadarSpinIn>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _angle;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration);
    _angle = Tween<double>(begin: -math.pi, end: 0).animate(
      CurvedAnimation(parent: _controller, curve: widget.curve),
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _angle,
      builder: (context, child) =>
          Transform.rotate(angle: _angle.value, child: child),
      child: widget.child,
    );
  }
}

/// Scales [child] from 0 to 1 once on mount — radar grows from center.
class _RadarScaleIn extends StatefulWidget {
  const _RadarScaleIn({
    required this.duration,
    required this.curve,
    required this.child,
  });

  final Duration duration;
  final Curve curve;
  final Widget child;

  @override
  State<_RadarScaleIn> createState() => _RadarScaleInState();
}

class _RadarScaleInState extends State<_RadarScaleIn>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration);
    _scale = CurvedAnimation(parent: _controller, curve: widget.curve);
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _scale,
      builder: (context, child) =>
          Transform.scale(scale: _scale.value, child: child),
      child: widget.child,
    );
  }
}
