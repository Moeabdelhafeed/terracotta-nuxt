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

/// Bubble chart powered by `graphic` — `PointMark` with size encoded
/// from a third axis (`BubblePoint.size`). Range maps to
/// `[minRadius, maxRadius]` pixel diameters.
class GlobalBubbleChart extends StatefulWidget {
  const GlobalBubbleChart({
    required this.bubbles,
    this.style = ChartStyle.standard,
    this.minRadius = 6,
    this.maxRadius = 28,
    this.animation = BubbleChartAnimation.scale,
    this.xAxisFormatter,
    this.yAxisFormatter,
    this.xAxisLabel,
    this.yAxisLabel,
    super.key,
  });

  final List<BubblePoint> bubbles;
  final ChartStyle style;
  final double minRadius;
  final double maxRadius;

  /// Entry animation preset. See [BubbleChartAnimation].
  final BubbleChartAnimation animation;

  final String Function(double value)? xAxisFormatter;
  final String Function(double value)? yAxisFormatter;
  final ChartAxisLabel? xAxisLabel;
  final ChartAxisLabel? yAxisLabel;

  @override
  State<GlobalBubbleChart> createState() => _GlobalBubbleChartState();
}

class _GlobalBubbleChartState extends State<GlobalBubbleChart> {
  StreamController<g.GestureEvent>? _gestureStream;
  StreamController<g.Selected?>? _selectionStream;

  List<BubblePoint> get bubbles => widget.bubbles;
  ChartStyle get style => widget.style;
  double get minRadius => widget.minRadius;
  double get maxRadius => widget.maxRadius;
  String Function(double value)? get xAxisFormatter => widget.xAxisFormatter;
  String Function(double value)? get yAxisFormatter => widget.yAxisFormatter;
  ChartAxisLabel? get xAxisLabel => widget.xAxisLabel;
  ChartAxisLabel? get yAxisLabel => widget.yAxisLabel;
  BubbleChartAnimation get animation => widget.animation;

  bool get _useOverlay => style.enableTooltip;
  ChartTooltipBuilder get _tooltipBuilder =>
      style.tooltipBuilder ?? defaultTooltipBuilder;

  /// Map [BubbleChartAnimation] to graphic's native [g.MarkEntrance].
  /// `drawIn` returns null — that mode disables native entrance and
  /// uses a Flutter-side `ClipRect` reveal instead.
  Set<g.MarkEntrance>? get _markEntrance => switch (animation) {
    BubbleChartAnimation.growUp => const {g.MarkEntrance.y},
    BubbleChartAnimation.slideIn => const {g.MarkEntrance.x},
    BubbleChartAnimation.fade => const {g.MarkEntrance.opacity},
    BubbleChartAnimation.scale => const {
      g.MarkEntrance.size,
      g.MarkEntrance.opacity,
    },
    BubbleChartAnimation.drawIn => null,
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
    if (bubbles.isEmpty) return const SizedBox.shrink();

    final palette = resolveSeriesColors(context, style, bubbles.length);
    final axisStyle = resolveAxisLabelStyle(context, style);
    final gridColor = resolveGridColor(context, style);

    // Per-bubble color: explicit `BubblePoint.color` wins, else rotate
    // through the palette. Apply alpha so overlapping bubbles stay
    // legible.
    final bubbleColors = [
      for (var i = 0; i < bubbles.length; i++)
        (bubbles[i].color ?? palette[i]).withValues(alpha: 0.55),
    ];
    final isMulti = bubbles.length > 1;

    // Gradient handling — graphic forbids both `color` and `gradient`
    // on a mark, so when ANY bubble provides a gradient we switch
    // the whole mark to GradientEncode and synthesize flat gradients
    // for the rest from their resolved color.
    final hasGradient = bubbles.any((b) => b.gradient != null);
    final bubbleGradients = [
      for (var i = 0; i < bubbles.length; i++)
        bubbles[i].gradient ?? flatGradient(bubbleColors[i]),
    ];

    final data = [
      for (var i = 0; i < bubbles.length; i++)
        {
          'x': bubbles[i].x,
          'y': bubbles[i].y,
          'size': bubbles[i].size,
          'label': bubbles[i].label ?? 'Bubble ${i + 1}',
        },
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
            'size': g.Variable(accessor: (m) => (m['size'] as num).toDouble()),
            'label': g.Variable(accessor: (m) => m['label'] as String),
          },
          marks: [
            g.PointMark(
              size: g.SizeEncode(
                variable: 'size',
                // Diameter in px → multiply by 2.
                values: [minRadius * 2, maxRadius * 2],
              ),
              color: hasGradient
                  ? null
                  : (isMulti
                        ? g.ColorEncode(variable: 'label', values: bubbleColors)
                        : g.ColorEncode(value: bubbleColors.first)),
              gradient: hasGradient
                  ? (isMulti
                        ? g.GradientEncode(
                            variable: 'label',
                            values: bubbleGradients,
                          )
                        : g.GradientEncode(value: bubbleGradients.first))
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
                    on: const {g.GestureType.hover, g.GestureType.tapDown},
                    clear: const {g.GestureType.mouseExit},
                  ),
                }
              : null,
          tooltip: _useOverlay ? null : buildChartTooltip(context, style),
        ),
      ),
    );

    // `drawIn` mode: animate a left-anchored ClipRect from 0% width
    // to 100% over the same duration / curve as the native entry.
    final maybeDrawIn =
        (animation == BubbleChartAnimation.drawIn && style.enableAnimation)
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
                _resolveTooltipEntries(selected, bubbleColors),
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

    final entries = <ChartLegendEntry>[
      for (var i = 0; i < bubbles.length; i++)
        ChartLegendEntry(
          label: bubbles[i].label ?? 'Bubble ${i + 1}',
          color: bubbles[i].color ?? palette[i],
        ),
    ];

    return wrapZoomPan(_wrap(entries, titled), style);
  }

  Widget _wrap(List<ChartLegendEntry> entries, Widget chart) {
    final body = Padding(
      padding: style.padding,
      child: chart,
    );

    // Skip legend when no bubble has an explicit label — the auto
    // "Bubble 1, Bubble 2…" fallback isn't useful as a legend.
    final hasLabels = bubbles.any((b) => b.label != null);
    if (!style.effectiveShowLegend || !hasLabels) return _sized(body);

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

  List<TooltipEntry> _resolveTooltipEntries(
    Set<int> selected,
    List<Color> bubbleColors,
  ) {
    if (selected.isEmpty) return const [];
    final out = <TooltipEntry>[];
    for (final i in selected) {
      if (i < 0 || i >= bubbles.length) continue;
      final b = bubbles[i];
      final formatted =
          '(${xAxisFormatter?.call(b.x) ?? formatChartNumber(b.x, style)}, '
          '${yAxisFormatter?.call(b.y) ?? formatChartNumber(b.y, style)}) · '
          '${formatChartNumber(b.size, style)}';
      out.add(
        TooltipEntry(
          label: b.label ?? 'Bubble ${i + 1}',
          value: formatted,
          color: bubbleColors[i],
        ),
      );
    }
    return out;
  }
}
