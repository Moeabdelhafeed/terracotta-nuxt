import 'dart:async';

import 'package:flutter/material.dart';
import 'package:graphic/graphic.dart' as g;

import 'chart_data.dart';
import 'chart_internals.dart';
import 'chart_legend.dart';
import 'chart_models.dart';
import 'chart_tooltip_overlay.dart';
import 'chart_zoom_pan.dart';

export 'chart_data.dart';
export 'chart_legend.dart' show ChartLegendEntry;
export 'chart_models.dart';

/// Multi-series scatter plot powered by `graphic`.
class GlobalScatterChart extends StatefulWidget {
  const GlobalScatterChart({
    required this.series,
    this.style = ChartStyle.standard,
    this.dotRadius = 6,
    this.animation = ScatterChartAnimation.scale,
    this.xAxisFormatter,
    this.yAxisFormatter,
    this.xAxisLabel,
    this.yAxisLabel,
    super.key,
  });

  final List<ChartSeries> series;
  final ChartStyle style;
  final double dotRadius;

  /// Entry animation preset. See [ScatterChartAnimation].
  final ScatterChartAnimation animation;

  final String Function(double value)? xAxisFormatter;
  final String Function(double value)? yAxisFormatter;
  final ChartAxisLabel? xAxisLabel;
  final ChartAxisLabel? yAxisLabel;

  @override
  State<GlobalScatterChart> createState() => _GlobalScatterChartState();
}

class _GlobalScatterChartState extends State<GlobalScatterChart> {
  StreamController<g.GestureEvent>? _gestureStream;
  StreamController<g.Selected?>? _selectionStream;

  List<ChartSeries> get series => widget.series;
  ChartStyle get style => widget.style;
  double get dotRadius => widget.dotRadius;
  String Function(double value)? get xAxisFormatter => widget.xAxisFormatter;
  String Function(double value)? get yAxisFormatter => widget.yAxisFormatter;
  ChartAxisLabel? get xAxisLabel => widget.xAxisLabel;
  ChartAxisLabel? get yAxisLabel => widget.yAxisLabel;
  ScatterChartAnimation get animation => widget.animation;

  bool get _useOverlay => style.enableTooltip;
  ChartTooltipBuilder get _tooltipBuilder =>
      style.tooltipBuilder ?? defaultTooltipBuilder;

  /// Map [ScatterChartAnimation] to graphic's native [g.MarkEntrance].
  /// `drawIn` returns null — that mode disables native entrance and
  /// uses a Flutter-side `ClipRect` reveal instead.
  Set<g.MarkEntrance>? get _markEntrance => switch (animation) {
    ScatterChartAnimation.growUp => const {g.MarkEntrance.y},
    ScatterChartAnimation.slideIn => const {g.MarkEntrance.x},
    ScatterChartAnimation.fade => const {g.MarkEntrance.opacity},
    // Pair size + opacity for a smoother pop (size alone reads
    // a bit hard-edged on small dots).
    ScatterChartAnimation.scale => const {
      g.MarkEntrance.size,
      g.MarkEntrance.opacity,
    },
    ScatterChartAnimation.drawIn => null,
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
    if (series.isEmpty) return const SizedBox.shrink();

    final colors = resolveSeriesColors(context, style, series.length);
    final axisStyle = resolveAxisLabelStyle(context, style);
    final gridColor = resolveGridColor(context, style);

    final data = <Map<String, dynamic>>[];
    for (var i = 0; i < series.length; i++) {
      for (final p in series[i].points) {
        data.add({'x': p.x, 'y': p.y, 'series': series[i].name});
      }
    }

    final isMulti = series.length > 1;

    // Gradient handling — graphic forbids both `color` and `gradient`
    // on a mark, so when ANY series provides a pointGradient we
    // switch the whole mark to GradientEncode and synthesize flat
    // gradients for the rest from their resolved color.
    final hasGradient = series.any((s) => s.pointGradient != null);
    final pointGradients = [
      for (var i = 0; i < series.length; i++)
        series[i].pointGradient ?? flatGradient(series[i].color ?? colors[i]),
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
                formatter: (v) =>
                    yAxisFormatter?.call(v.toDouble()) ??
                    formatChartNumber(v, style),
              ),
            ),
            'series': g.Variable(accessor: (m) => m['series'] as String),
          },
          marks: [
            g.PointMark(
              position: isMulti
                  ? g.Varset('x') * g.Varset('y') / g.Varset('series')
                  : null,
              size: g.SizeEncode(value: dotRadius * 2),
              color: hasGradient
                  ? null
                  : (isMulti
                        ? g.ColorEncode(variable: 'series', values: colors)
                        : g.ColorEncode(value: colors.first)),
              gradient: hasGradient
                  ? (isMulti
                        ? g.GradientEncode(
                            variable: 'series',
                            values: pointGradients,
                          )
                        : g.GradientEncode(value: pointGradients.first))
                  : null,
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

    // `drawIn` mode: animate a left-anchored ClipRect from 0% width
    // to 100% over the same duration / curve as the native entry.
    final maybeDrawIn =
        (animation == ScatterChartAnimation.drawIn && style.enableAnimation)
        ? DrawInRevealer(
            duration: style.effectiveAnimationDuration,
            curve: style.effectiveAnimationCurve,
            child: chart,
          )
        : chart;

    final tooltipFramed = _useOverlay
        ? ChartTooltipOverlay(
            gestureStream: _gestureStream!,
            selectionStream: _selectionStream!,
            builder: _tooltipBuilder,
            resolveEntries: (selected) =>
                _resolveTooltipEntries(selected, data, colors),
            child: maybeDrawIn,
          )
        : maybeDrawIn;

    final shadowFramed = axisShadowFrame(
      context: context,
      child: tooltipFramed,
      style: style,
    );
    final titled = axisTitleFrame(
      context: context,
      chart: shadowFramed,
      xAxisLabel: xAxisLabel,
      yAxisLabel: yAxisLabel,
    );

    return wrapZoomPan(_wrap(entries, titled), style);
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
    final colorByName = <String, Color>{
      for (var i = 0; i < series.length; i++)
        series[i].name: series[i].color ?? colors[i],
    };
    final out = <TooltipEntry>[];
    for (final i in selected) {
      if (i < 0 || i >= data.length) continue;
      final row = data[i];
      final name = row['series'] as String;
      final ser = byName[name];
      final xVal = (row['x'] as num).toDouble();
      final yVal = (row['y'] as num).toDouble();
      final formatted =
          '(${xAxisFormatter?.call(xVal) ?? formatChartNumber(xVal, style)}, '
          '${yAxisFormatter?.call(yVal) ?? formatChartNumber(yVal, style)})';
      out.add(
        TooltipEntry(
          label: name,
          value: formatted,
          color: colorByName[name] ?? Colors.grey,
          icon: ser?.icon,
          iconAsset: ser?.iconAsset,
          iconWidget: ser?.iconWidget,
        ),
      );
    }
    return out;
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
            maxWidth: resolveChartMaxWidth(context, style),
          ),
          child: AspectRatio(aspectRatio: style.aspectRatio, child: child),
        ),
      ),
    );
  }
}
