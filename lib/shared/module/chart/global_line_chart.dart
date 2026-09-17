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

/// Multi-series line / area chart powered by `graphic`.
///
/// ```dart
/// GlobalLineChart(
///   series: [
///     ChartSeries(name: 'Revenue', points: [
///       ChartPoint(0, 12), ChartPoint(1, 18), ChartPoint(2, 15),
///     ]),
///   ],
///   curve: LineChartCurve.smooth,
///   filled: true,
/// )
/// ```
class GlobalLineChart extends StatefulWidget {
  const GlobalLineChart({
    required this.series,
    this.style = ChartStyle.standard,
    this.curve = LineChartCurve.smooth,
    this.filled = false,
    this.animation = LineChartAnimation.growUp,
    this.xAxisFormatter,
    this.yAxisFormatter,
    this.xAxisLabel,
    this.yAxisLabel,
    super.key,
  });

  final List<ChartSeries> series;
  final ChartStyle style;
  final LineChartCurve curve;

  /// Render an area fill below each line.
  final bool filled;

  /// Entry animation preset. See [LineChartAnimation].
  final LineChartAnimation animation;

  final String Function(double value)? xAxisFormatter;
  final String Function(double value)? yAxisFormatter;

  final ChartAxisLabel? xAxisLabel;
  final ChartAxisLabel? yAxisLabel;

  @override
  State<GlobalLineChart> createState() => _GlobalLineChartState();
}

class _GlobalLineChartState extends State<GlobalLineChart> {
  // Re-used across rebuilds when custom tooltip overlay is on.
  StreamController<g.GestureEvent>? _gestureStream;
  StreamController<g.Selected?>? _selectionStream;

  // Convenience getters to keep build() concise.
  List<ChartSeries> get series => widget.series;
  ChartStyle get style => widget.style;
  LineChartCurve get curve => widget.curve;
  bool get filled => widget.filled;
  LineChartAnimation get animation => widget.animation;

  /// Map [LineChartAnimation] to graphic's native [g.MarkEntrance]
  /// set. `drawIn` returns null — that mode disables the native
  /// entrance and uses a Flutter-side `ClipRect` reveal instead.
  Set<g.MarkEntrance>? get _markEntrance => switch (animation) {
    LineChartAnimation.growUp => const {g.MarkEntrance.y},
    LineChartAnimation.slideIn => const {g.MarkEntrance.x},
    LineChartAnimation.fade => const {g.MarkEntrance.opacity},
    LineChartAnimation.scale => const {g.MarkEntrance.size},
    LineChartAnimation.drawIn => null,
  };
  ChartAxisLabel? get xAxisLabel => widget.xAxisLabel;
  ChartAxisLabel? get yAxisLabel => widget.yAxisLabel;
  String Function(double value)? get xAxisFormatter => widget.xAxisFormatter;
  String Function(double value)? get yAxisFormatter => widget.yAxisFormatter;

  bool get _useOverlay => style.enableTooltip;
  ChartTooltipBuilder get _tooltipBuilder =>
      style.tooltipBuilder ?? defaultTooltipBuilder;

  @override
  void initState() {
    super.initState();
    _ensureStreams();
  }

  void _ensureStreams() {
    if (_useOverlay) {
      _gestureStream ??= StreamController<g.GestureEvent>.broadcast();
      _selectionStream ??= StreamController<g.Selected?>.broadcast();
    }
  }

  @override
  void didUpdateWidget(covariant GlobalLineChart old) {
    super.didUpdateWidget(old);
    _ensureStreams();
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

    // Flatten series into [{ 'x': .., 'y': .., 'series': name }, …]
    final data = <Map<String, dynamic>>[];
    for (var i = 0; i < series.length; i++) {
      for (final p in series[i].points) {
        data.add({'x': p.x, 'y': p.y, 'series': series[i].name});
      }
    }

    final isMulti = series.length > 1;
    final smooth = curve != LineChartCurve.straight;
    final fillColors = [for (final c in colors) c.withValues(alpha: 0.22)];
    final lineShapes = [
      for (final s in series)
        g.BasicLineShape(smooth: smooth, dash: s.dashed ? const [6, 4] : null),
    ];
    final areaShapes = [
      for (final _ in series) g.BasicAreaShape(smooth: smooth),
    ];

    // Gradient handling — graphic forbids both `color` and `gradient`
    // on a mark, so when ANY series provides a gradient we switch the
    // whole mark to GradientEncode and synthesize flat gradients for
    // the rest from their resolved color.
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
            'x': g.Variable(
              accessor: (m) => m['x'] as num,
              scale: g.LinearScale(
                // No padding before/after data range — line should
                // touch chart edges horizontally.
                marginMin: 0,
                marginMax: 0,
                formatter: (v) =>
                    xAxisFormatter?.call(v.toDouble()) ??
                    formatChartNumber(v, style),
              ),
            ),
            'y': g.Variable(
              accessor: (m) => m['y'] as num,
              scale: g.LinearScale(
                formatter: (v) =>
                    yAxisFormatter?.call(v.toDouble()) ??
                    formatChartNumber(v, style),
              ),
            ),
            'series': g.Variable(accessor: (m) => m['series'] as String),
          },
          marks: [
            if (filled)
              g.AreaMark(
                position: isMulti
                    ? g.Varset('x') * g.Varset('y') / g.Varset('series')
                    : null,
                shape: isMulti
                    ? g.ShapeEncode(variable: 'series', values: areaShapes)
                    : g.ShapeEncode(value: areaShapes.first),
                color: hasFillGradient
                    ? null
                    : (isMulti
                          ? g.ColorEncode(
                              variable: 'series',
                              values: fillColors,
                            )
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
            g.LineMark(
              position: isMulti
                  ? g.Varset('x') * g.Varset('y') / g.Varset('series')
                  : null,
              shape: isMulti
                  ? g.ShapeEncode(variable: 'series', values: lineShapes)
                  : g.ShapeEncode(value: lineShapes.first),
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
              size: g.SizeEncode(value: 2.5),
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
                    labelMapper: xAxisFormatter == null
                        ? null
                        : (text, index, total) => g.LabelStyle(
                            textStyle: axisStyle,
                            offset: const Offset(0, 6),
                          ),
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
          crosshair: style.enableCrosshair
              ? g.CrosshairGuide(
                  styles: [
                    g.PaintStyle(
                      strokeColor: colors.first.withValues(alpha: 0.4),
                      strokeWidth: 1,
                      dash: const [4, 4],
                    ),
                    g.PaintStyle(
                      strokeColor: gridColor.withValues(alpha: 0),
                    ),
                  ],
                )
              : null,
        ),
      ),
    );

    // `drawIn` mode: animate a left-anchored ClipRect from 0% width
    // to 100% over the same duration / curve as the native entry,
    // making the line appear to "draw" left to right. Disabled when
    // animation is off or already replayed by the EntranceGate.
    final maybeDrawIn =
        (animation == LineChartAnimation.drawIn && style.enableAnimation)
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

    return wrapZoomPan(
      _wrap(_LegendEntries.from(series, colors), titled),
      style,
    );
  }

  /// Map graphic's flat-data indexes back to per-series tooltip rows.
  /// Each selected index points to one row in [data]; we group by
  /// series name, take the latest selected datum per series, and
  /// produce one [TooltipEntry] per unique series.
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
    final out = <String, TooltipEntry>{};
    for (final i in selected) {
      if (i < 0 || i >= data.length) continue;
      final row = data[i];
      final name = row['series'] as String;
      final ser = byName[name];
      final color = colorByName[name] ?? Colors.grey;
      final yVal = row['y'] as num;
      final formatted =
          yAxisFormatter?.call(yVal.toDouble()) ??
          formatChartNumber(yVal, style);
      out[name] = TooltipEntry(
        label: name,
        value: formatted,
        color: color,
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
            maxWidth: resolveChartMaxWidth(context, style),
          ),
          child: AspectRatio(aspectRatio: style.aspectRatio, child: child),
        ),
      ),
    );
  }
}

class _LegendEntries {
  static List<ChartLegendEntry> from(
    List<ChartSeries> series,
    List<Color> colors,
  ) {
    return [
      for (var i = 0; i < series.length; i++)
        ChartLegendEntry(
          label: series[i].name,
          color: series[i].color ?? colors[i],
          icon: series[i].icon,
          iconAsset: series[i].iconAsset,
          iconWidget: series[i].iconWidget,
        ),
    ];
  }
}
