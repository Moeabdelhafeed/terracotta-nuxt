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

/// Multi-series bar chart powered by `graphic`.
///
/// ```dart
/// GlobalBarChart(
///   groups: [
///     BarGroup(label: 'Mon', bars: [12, 8]),
///     BarGroup(label: 'Tue', bars: [18, 14]),
///   ],
///   seriesNames: const ['Sales', 'Returns'],
///   layout: BarChartLayout.grouped,
/// )
/// ```
class GlobalBarChart extends StatefulWidget {
  const GlobalBarChart({
    required this.groups,
    this.seriesNames = const [],
    this.seriesIcons = const [],
    this.seriesGradients = const [],
    this.style = ChartStyle.standard,
    this.layout = BarChartLayout.grouped,
    this.orientation = BarChartOrientation.vertical,
    this.animation = BarChartAnimation.growUp,
    this.barWidth = 14,
    this.borderRadius = 4,
    this.yAxisFormatter,
    this.xAxisLabel,
    this.yAxisLabel,
    super.key,
  });

  final List<BarGroup> groups;
  final List<String> seriesNames;

  /// Optional Material icons paired with [seriesNames] — appear in
  /// the legend next to each series label. Length should match
  /// [seriesNames]; missing entries fall back to the color swatch.
  final List<IconData?> seriesIcons;

  /// Optional [Gradient] per series — when ANY entry is non-null,
  /// the bars switch to gradient fill (graphic forbids combining
  /// `color` and `gradient`). Missing/null entries auto-synthesize
  /// flat gradients from the resolved series color so lengths line
  /// up across series. Length should match [seriesNames].
  final List<Gradient?> seriesGradients;

  final ChartStyle style;
  final BarChartLayout layout;
  final BarChartOrientation orientation;

  /// Entry animation preset. See [BarChartAnimation].
  final BarChartAnimation animation;

  final double barWidth;
  final double borderRadius;
  final String Function(double value)? yAxisFormatter;

  final ChartAxisLabel? xAxisLabel;
  final ChartAxisLabel? yAxisLabel;

  @override
  State<GlobalBarChart> createState() => _GlobalBarChartState();
}

class _GlobalBarChartState extends State<GlobalBarChart> {
  StreamController<g.GestureEvent>? _gestureStream;
  StreamController<g.Selected?>? _selectionStream;

  List<BarGroup> get groups => widget.groups;
  List<String> get seriesNames => widget.seriesNames;
  List<IconData?> get seriesIcons => widget.seriesIcons;
  List<Gradient?> get seriesGradients => widget.seriesGradients;
  ChartStyle get style => widget.style;
  BarChartLayout get layout => widget.layout;
  BarChartOrientation get orientation => widget.orientation;
  BarChartAnimation get animation => widget.animation;
  double get barWidth => widget.barWidth;
  double get borderRadius => widget.borderRadius;
  String Function(double value)? get yAxisFormatter => widget.yAxisFormatter;
  ChartAxisLabel? get xAxisLabel => widget.xAxisLabel;
  ChartAxisLabel? get yAxisLabel => widget.yAxisLabel;

  int get _seriesCount => groups.isEmpty ? 0 : groups.first.bars.length;
  bool get _useOverlay => style.enableTooltip;
  ChartTooltipBuilder get _tooltipBuilder =>
      style.tooltipBuilder ?? defaultTooltipBuilder;

  /// Map [BarChartAnimation] to graphic's native [g.MarkEntrance].
  /// `drawIn` returns null — that mode disables the native entrance
  /// and uses a Flutter-side `ClipRect` reveal instead.
  Set<g.MarkEntrance>? get _markEntrance => switch (animation) {
    BarChartAnimation.growUp => const {g.MarkEntrance.y},
    BarChartAnimation.slideIn => const {g.MarkEntrance.x},
    BarChartAnimation.fade => const {g.MarkEntrance.opacity},
    BarChartAnimation.scale => const {g.MarkEntrance.size},
    BarChartAnimation.drawIn => null,
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
    if (groups.isEmpty) return const SizedBox.shrink();

    final colors = resolveSeriesColors(context, style, _seriesCount);
    final axisStyle = resolveAxisLabelStyle(context, style);
    final gridColor = resolveGridColor(context, style);
    final isHorizontal = orientation == BarChartOrientation.horizontal;
    final isPercent = layout == BarChartLayout.stackedPercent;
    final isStacked = layout != BarChartLayout.grouped;

    // Flatten groups → [{ 'group': label, 'series': name, 'value': v }, …]
    final data = <Map<String, dynamic>>[];
    for (final g in groups) {
      for (var i = 0; i < g.bars.length; i++) {
        final name = i < seriesNames.length
            ? seriesNames[i]
            : 'Series ${i + 1}';
        data.add({'group': g.label, 'series': name, 'value': g.bars[i]});
      }
    }

    final isMulti = _seriesCount > 1;

    // Gradient handling — graphic forbids both `color` and `gradient`
    // on a mark, so when ANY series provides a gradient we switch the
    // whole mark to GradientEncode and synthesize flat gradients for
    // the rest from their resolved color.
    final hasGradient = seriesGradients.any((g) => g != null);
    final barGradients = [
      for (var i = 0; i < _seriesCount; i++)
        (i < seriesGradients.length ? seriesGradients[i] : null) ??
            flatGradient(colors[i]),
    ];

    // Compute y-axis max so stacked sums fit; graphic's scale otherwise
    // derives from raw values and clips post-stack tops.
    double? scaleMax;
    if (isStacked && !isPercent) {
      var max = 0.0;
      for (final grp in groups) {
        final sum = grp.bars.fold<double>(0, (a, b) => a + b);
        if (sum > max) max = sum;
      }
      scaleMax = max == 0 ? null : max;
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
            'group': g.Variable(accessor: (m) => m['group'] as String),
            'value': g.Variable(
              accessor: (m) => (m['value'] as num).toDouble(),
              scale: g.LinearScale(
                min: 0,
                max: scaleMax,
                formatter: (v) =>
                    yAxisFormatter?.call(v.toDouble()) ??
                    formatChartNumber(v, style),
              ),
            ),
            'series': g.Variable(accessor: (m) => m['series'] as String),
          },
          transforms: [
            if (isPercent)
              g.Proportion(
                variable: 'value',
                as: 'percent',
                nest: g.Varset('group'),
              ),
          ],
          coord: isHorizontal ? g.RectCoord(transposed: true) : null,
          marks: [
            g.IntervalMark(
              position: isPercent
                  ? g.Varset('group') * g.Varset('percent') / g.Varset('series')
                  : g.Varset('group') * g.Varset('value') / g.Varset('series'),
              color: hasGradient
                  ? null
                  : (isMulti
                        ? g.ColorEncode(variable: 'series', values: colors)
                        : g.ColorEncode(value: colors.first)),
              gradient: hasGradient
                  ? (isMulti
                        ? g.GradientEncode(
                            variable: 'series',
                            values: barGradients,
                          )
                        : g.GradientEncode(value: barGradients.first))
                  : null,
              size: g.SizeEncode(value: barWidth),
              selectionStream: _useOverlay ? _selectionStream : null,
              modifiers: isStacked
                  ? [g.StackModifier()]
                  : [g.DodgeModifier(ratio: 0.1)],
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
                    variable: 'group',
                    dim: g.Dim.x,
                  ),
                }
              : null,
          tooltip: _useOverlay ? null : buildChartTooltip(context, style),
        ),
      ),
    );

    final entries = <ChartLegendEntry>[
      for (var i = 0; i < _seriesCount; i++)
        ChartLegendEntry(
          label: i < seriesNames.length ? seriesNames[i] : 'Series ${i + 1}',
          color: colors[i],
          icon: i < seriesIcons.length ? seriesIcons[i] : null,
        ),
    ];

    // `drawIn` mode: animate a left-anchored ClipRect from 0% width
    // to 100% over the same duration / curve as the native entry,
    // making bars sweep in left to right.
    final maybeDrawIn =
        (animation == BarChartAnimation.drawIn && style.enableAnimation)
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

  /// Map flat-data indexes back to per-series tooltip rows.
  List<TooltipEntry> _resolveTooltipEntries(
    Set<int> selected,
    List<Map<String, dynamic>> data,
    List<Color> colors,
  ) {
    if (selected.isEmpty) return const [];
    final colorByName = <String, Color>{
      for (var i = 0; i < _seriesCount; i++)
        (i < seriesNames.length ? seriesNames[i] : 'Series ${i + 1}'):
            colors[i],
    };
    final iconByName = <String, IconData?>{
      for (var i = 0; i < _seriesCount; i++)
        (i < seriesNames.length ? seriesNames[i] : 'Series ${i + 1}'):
            (i < seriesIcons.length ? seriesIcons[i] : null),
    };
    // Show one entry per selected datum (could be one series or many
    // when hovering a stacked column).
    final out = <String, TooltipEntry>{};
    for (final i in selected) {
      if (i < 0 || i >= data.length) continue;
      final row = data[i];
      final name = row['series'] as String;
      final group = row['group'] as String;
      final yVal = row['value'] as num;
      final formatted =
          yAxisFormatter?.call(yVal.toDouble()) ??
          formatChartNumber(yVal, style);
      out[name] = TooltipEntry(
        label: '$group · $name',
        value: formatted,
        color: colorByName[name] ?? Colors.grey,
        icon: iconByName[name],
      );
    }
    return out.values.toList(growable: false);
  }

  Widget _wrap(List<ChartLegendEntry> entries, Widget chart) {
    final body = Padding(
      padding: style.padding,
      child: chart,
    );

    if (!style.effectiveShowLegend || _seriesCount <= 1) return _sized(body);

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
