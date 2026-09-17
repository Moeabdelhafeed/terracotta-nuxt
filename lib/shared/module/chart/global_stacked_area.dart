import 'dart:async';

import 'package:flutter/material.dart';
import 'package:graphic/graphic.dart' as g;

import 'chart_data.dart';
import 'chart_internals.dart';
import 'chart_legend.dart';
import 'chart_models.dart';
import 'chart_tooltip_overlay.dart';
import 'chart_zoom_pan.dart';

export 'chart_data.dart' show ChartPoint, ChartSeries;
export 'chart_legend.dart' show ChartLegendEntry;
export 'chart_models.dart' show ChartStyle, LineChartCurve, ChartLegendPosition;

/// Stacked area chart — series stacked on top of each other with
/// filled bands. Cumulative composition over time. Each series
/// contributes its `y` to the running total.
///
/// ```dart
/// GlobalStackedArea(
///   series: [
///     ChartSeries(name: 'iOS',    points: [ChartPoint(0, 12), ...]),
///     ChartSeries(name: 'Android', points: [ChartPoint(0, 18), ...]),
///     ChartSeries(name: 'Web',    points: [ChartPoint(0, 6),  ...]),
///   ],
/// )
/// ```
class GlobalStackedArea extends StatefulWidget {
  const GlobalStackedArea({
    required this.series,
    this.style = ChartStyle.standard,
    this.curve = LineChartCurve.smooth,
    this.normalize = false,
    this.strokeWidth = 1.5,
    this.xAxisFormatter,
    this.yAxisFormatter,
    super.key,
  });

  final List<ChartSeries> series;
  final ChartStyle style;

  /// Curve preset for the upper line of each band.
  final LineChartCurve curve;

  /// Stretch every column's stack to 100% — composition view.
  final bool normalize;

  /// Stroke width on the band's top line.
  final double strokeWidth;

  final String Function(double)? xAxisFormatter;
  final String Function(double)? yAxisFormatter;

  @override
  State<GlobalStackedArea> createState() => _GlobalStackedAreaState();
}

class _GlobalStackedAreaState extends State<GlobalStackedArea> {
  StreamController<g.GestureEvent>? _gestureStream;
  StreamController<g.Selected?>? _selectionStream;

  List<ChartSeries> get series => widget.series;
  ChartStyle get style => widget.style;
  LineChartCurve get curve => widget.curve;
  bool get normalize => widget.normalize;
  double get strokeWidth => widget.strokeWidth;
  String Function(double)? get xAxisFormatter => widget.xAxisFormatter;
  String Function(double)? get yAxisFormatter => widget.yAxisFormatter;

  bool get _useOverlay => style.enableTooltip;
  ChartTooltipBuilder get _tooltipBuilder =>
      style.tooltipBuilder ?? defaultTooltipBuilder;

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
    if (series.isEmpty) return const SizedBox.shrink();

    final colors = resolveSeriesColors(context, style, series.length);
    final axisStyle = resolveAxisLabelStyle(context, style);
    final gridColor = resolveGridColor(context, style);
    final smooth = curve != LineChartCurve.straight;

    // Flatten with stack ordering preserved by series index.
    final data = <Map<String, dynamic>>[];
    for (var i = 0; i < series.length; i++) {
      for (final p in series[i].points) {
        data.add({'x': p.x, 'y': p.y, 'series': series[i].name});
      }
    }

    final fillColors = [for (final c in colors) c.withValues(alpha: 0.55)];

    // Compute stack max so the y-scale fits the cumulative sum at
    // each x — graphic's auto scale uses raw values, which clips
    // stacked tops above the chart frame in the non-normalize case.
    double? stackMax;
    if (!normalize) {
      final byX = <double, double>{};
      for (final s in series) {
        for (final p in s.points) {
          byX[p.x] = (byX[p.x] ?? 0) + p.y;
        }
      }
      if (byX.isNotEmpty) {
        stackMax = byX.values.reduce((a, b) => a > b ? a : b);
      }
    }

    final chart = EntranceGate(
      enabled: style.enableAnimation,
      duration: style.effectiveAnimationDuration,
      builder: (playEntrance) => IgnorePointer(
        ignoring: playEntrance,
        child: g.Chart<Map<String, dynamic>>(
          gestureStream: _useOverlay ? _gestureStream : null,
          data: data,
          variables: {
            'x': g.Variable(
              accessor: (m) => (m['x'] as num).toDouble(),
              scale: g.LinearScale(
                marginMin: 0,
                marginMax: 0,
                formatter: (v) =>
                    xAxisFormatter?.call(v.toDouble()) ??
                    formatChartNumber(v, style),
              ),
            ),
            'y': g.Variable(
              accessor: (m) => (m['y'] as num).toDouble(),
              scale: g.LinearScale(
                min: 0,
                max: stackMax,
                formatter: (v) =>
                    yAxisFormatter?.call(v.toDouble()) ??
                    formatChartNumber(v, style),
              ),
            ),
            'series': g.Variable(accessor: (m) => m['series'] as String),
          },
          transforms: [
            if (normalize)
              g.Proportion(variable: 'y', as: 'percent', nest: g.Varset('x')),
          ],
          marks: [
            g.AreaMark(
              position: normalize
                  ? g.Varset('x') * g.Varset('percent') / g.Varset('series')
                  : g.Varset('x') * g.Varset('y') / g.Varset('series'),
              shape: g.ShapeEncode(value: g.BasicAreaShape(smooth: smooth)),
              color: g.ColorEncode(variable: 'series', values: fillColors),
              modifiers: [g.StackModifier()],
              transition: playEntrance
                  ? g.Transition(
                      duration: style.effectiveAnimationDuration,
                      curve: style.effectiveAnimationCurve,
                    )
                  : null,
              entrance: playEntrance ? const {g.MarkEntrance.y} : null,
            ),
            g.LineMark(
              position: normalize
                  ? g.Varset('x') * g.Varset('percent') / g.Varset('series')
                  : g.Varset('x') * g.Varset('y') / g.Varset('series'),
              shape: g.ShapeEncode(value: g.BasicLineShape(smooth: smooth)),
              color: g.ColorEncode(variable: 'series', values: colors),
              size: g.SizeEncode(value: strokeWidth),
              selectionStream: _useOverlay ? _selectionStream : null,
              modifiers: [g.StackModifier()],
              transition: playEntrance
                  ? g.Transition(
                      duration: style.effectiveAnimationDuration,
                      curve: style.effectiveAnimationCurve,
                    )
                  : null,
              entrance: playEntrance ? const {g.MarkEntrance.y} : null,
            ),
          ],
          axes: style.effectiveShowAxisLabels
              ? [
                  g.AxisGuide(
                    label: g.LabelStyle(textStyle: axisStyle),
                    line: g.PaintStyle(
                      strokeColor: gridColor,
                      strokeWidth: 0.5,
                    ),
                    tickLine: g.TickLine(
                      style: g.PaintStyle(strokeColor: gridColor),
                    ),
                    grid: style.effectiveShowGrid
                        ? g.PaintStyle(strokeColor: gridColor, strokeWidth: 0.5)
                        : null,
                  ),
                  g.AxisGuide(
                    label: g.LabelStyle(textStyle: axisStyle),
                    line: g.PaintStyle(
                      strokeColor: gridColor,
                      strokeWidth: 0.5,
                    ),
                    tickLine: g.TickLine(
                      style: g.PaintStyle(strokeColor: gridColor),
                    ),
                    grid: style.effectiveShowGrid
                        ? g.PaintStyle(strokeColor: gridColor, strokeWidth: 0.5)
                        : null,
                  ),
                ]
              : null,
          selections: style.enableTooltip
              ? {
                  'tooltip': g.PointSelection(
                    on: const {
                      g.GestureType.hover,
                      g.GestureType.tapDown,
                      g.GestureType.longPressMoveUpdate,
                    },
                    clear: const {g.GestureType.mouseExit},
                    dim: g.Dim.x,
                    variable: 'x',
                  ),
                }
              : null,
          tooltip: _useOverlay ? null : buildChartTooltip(context, style),
        ),
      ),
    );

    final tooltipFramed = _useOverlay
        ? ChartTooltipOverlay(
            gestureStream: _gestureStream!,
            selectionStream: _selectionStream!,
            builder: _tooltipBuilder,
            resolveEntries: (selected) =>
                _resolveTooltipEntries(selected, data, colors),
            child: chart,
          )
        : chart;

    final entries = [
      for (var i = 0; i < series.length; i++)
        ChartLegendEntry(
          label: series[i].name,
          color: series[i].color ?? colors[i],
          icon: series[i].icon,
          iconAsset: series[i].iconAsset,
          iconWidget: series[i].iconWidget,
        ),
    ];

    return wrapZoomPan(_wrap(entries, tooltipFramed), style);
  }

  List<TooltipEntry> _resolveTooltipEntries(
    Set<int> selected,
    List<Map<String, dynamic>> data,
    List<Color> colors,
  ) {
    if (selected.isEmpty) return const [];
    final byName = <String, ChartSeries>{
      for (final s in series) s.name: s,
    };
    final out = <String, TooltipEntry>{};
    for (final i in selected) {
      if (i < 0 || i >= data.length) continue;
      final row = data[i];
      final name = row['series'] as String;
      final ser = byName[name];
      final color =
          ser?.color ??
          colors[series
              .indexWhere((s) => s.name == name)
              .clamp(0, colors.length - 1)];
      final yVal = (row['y'] as num).toDouble();
      out[name] = TooltipEntry(
        label: name,
        value: yAxisFormatter?.call(yVal) ?? formatChartNumber(yVal, style),
        color: color,
        icon: ser?.icon,
        iconAsset: ser?.iconAsset,
        iconWidget: ser?.iconWidget,
      );
    }
    return out.values.toList(growable: false);
  }

  Widget _wrap(List<ChartLegendEntry> entries, Widget chart) {
    final body = Padding(padding: style.padding, child: chart);
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
            maxWidth: resolveChartMaxWidth(context, style),
          ),
          child: AspectRatio(aspectRatio: style.aspectRatio, child: child),
        ),
      ),
    );
  }
}
