import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:graphic/graphic.dart' as g;

import '../../../core/extensions/theme_colors_extension.dart';
import '../../../core/localization/number_formatter.dart';
import 'chart_data.dart';
import 'chart_internals.dart';
import 'chart_legend.dart';
import 'chart_models.dart';
import 'chart_tooltip_overlay.dart';
import 'custom_paint_tooltip.dart';

export 'chart_data.dart';
export 'chart_legend.dart' show ChartLegendEntry;
export 'chart_models.dart';

/// Pie / donut chart powered by `graphic` (polar coord + interval mark).
///
/// ```dart
/// GlobalPieChart(
///   slices: [
///     PieSlice(label: 'Food', value: 42),
///     PieSlice(label: 'Transit', value: 18),
///   ],
///   donut: true,
///   centerLabel: 'Spending',
/// )
/// ```
class GlobalPieChart extends StatefulWidget {
  const GlobalPieChart({
    required this.slices,
    this.style = ChartStyle.standard,
    this.donut = false,
    this.donutRadiusRatio = 0.55,
    this.showPercentLabels = true,
    this.showSliceLabels = false,
    this.halfCircle = false,
    this.centerLabel,
    this.centerSubLabel,
    this.animation = PieChartAnimation.sweep,
    super.key,
  });

  /// Render the slice's category label just outside its outer arc.
  /// Off by default — legend handles labeling. Turn on to drop the
  /// legend and use spatial labels instead.
  final bool showSliceLabels;

  /// Render only the top semicircle. The slices share the upper
  /// half (-π → 0 in canvas angle). Pairs well with a `centerLabel`
  /// that sits in the lower whitespace as a KPI-style display.
  final bool halfCircle;

  final List<PieSlice> slices;
  final ChartStyle style;
  final bool donut;
  final double donutRadiusRatio;
  final bool showPercentLabels;
  final String? centerLabel;
  final String? centerSubLabel;

  /// Entry animation preset. See [PieChartAnimation].
  final PieChartAnimation animation;

  @override
  State<GlobalPieChart> createState() => _GlobalPieChartState();
}

class _GlobalPieChartState extends State<GlobalPieChart> {
  StreamController<g.GestureEvent>? _gestureStream;
  StreamController<g.Selected?>? _selectionStream;

  List<PieSlice> get slices => widget.slices;
  ChartStyle get style => widget.style;
  bool get donut => widget.donut;
  double get donutRadiusRatio => widget.donutRadiusRatio;
  bool get showPercentLabels => widget.showPercentLabels;
  String? get centerLabel => widget.centerLabel;
  bool get halfCircle => widget.halfCircle;

  // Canvas-angle range the pie occupies. Default = full circle
  // starting at 12 o'clock (-π/2) sweeping clockwise. Half-circle
  // mode = upper hemisphere only (-π → 0).
  double get _arcStartAngle => halfCircle ? -math.pi : -math.pi / 2;
  double get _arcEndAngle => halfCircle ? 0 : 3 * math.pi / 2;
  double get _arcSpan => _arcEndAngle - _arcStartAngle;
  String? get centerSubLabel => widget.centerSubLabel;
  PieChartAnimation get animation => widget.animation;

  bool get _useOverlay => style.enableTooltip;
  ChartTooltipBuilder get _tooltipBuilder =>
      style.tooltipBuilder ?? defaultTooltipBuilder;

  /// Map [PieChartAnimation] to graphic's native [g.MarkEntrance].
  /// `spin` falls back to `y` (sweep) and adds a Flutter
  /// `Transform.rotate` on top. `scale` returns null — graphic's
  /// native size-entrance doesn't translate well to polar wedges
  /// (collapses to a thin ring), so we use a Flutter
  /// `Transform.scale` wrapper instead for a cleaner zoom-in.
  Set<g.MarkEntrance>? get _markEntrance => switch (animation) {
    PieChartAnimation.sweep => const {g.MarkEntrance.y},
    PieChartAnimation.fade => const {g.MarkEntrance.opacity},
    PieChartAnimation.scale => null,
    PieChartAnimation.spin => const {g.MarkEntrance.y},
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
    if (slices.isEmpty) return const SizedBox.shrink();

    final total = slices.fold<double>(0, (a, s) => a + s.value);
    if (total <= 0) return const SizedBox.shrink();

    final colors = resolveSeriesColors(context, style, slices.length);
    final paletteColors = [
      for (var i = 0; i < slices.length; i++) slices[i].color ?? colors[i],
    ];

    final hasGradient = slices.any((s) => s.gradient != null);
    final sliceGradients = [
      for (var i = 0; i < slices.length; i++)
        slices[i].gradient ?? flatGradient(paletteColors[i]),
    ];

    final data = [
      for (var i = 0; i < slices.length; i++)
        {'label': slices[i].label, 'value': slices[i].value, 'index': i},
    ];

    final isMulti = slices.length > 1;
    final pie = EntranceGate(
      enabled: style.enableAnimation,
      duration: style.effectiveAnimationDuration,
      builder: (playEntrance) => IgnorePointer(
        ignoring: playEntrance,
        child: g.Chart<Map<String, dynamic>>(
          gestureStream: _useOverlay ? _gestureStream : null,
          data: data,
          variables: {
            'label': g.Variable(accessor: (m) => m['label'] as String),
            'value': g.Variable(
              accessor: (m) => (m['value'] as num).toDouble(),
            ),
          },
          transforms: [
            g.Proportion(variable: 'value', as: 'percent'),
          ],
          coord: g.PolarCoord(
            startAngle: _arcStartAngle,
            endAngle: _arcEndAngle,
            transposed: true,
            dimCount: 1,
            startRadius: donut ? donutRadiusRatio : 0,
          ),
          marks: [
            g.IntervalMark(
              position: g.Varset('percent') / g.Varset('label'),
              // labelPosition: 0.5 forces sector labels to use
              // `Alignment.center` (default `1` aligns to outer-quadrant
              // and pushes the % toward the slice edge).
              shape: g.ShapeEncode(value: g.RectShape(labelPosition: 0.5)),
              color: hasGradient
                  ? null
                  : (isMulti
                        ? g.ColorEncode(
                            variable: 'label',
                            values: paletteColors,
                          )
                        : g.ColorEncode(value: paletteColors.first)),
              gradient: hasGradient
                  ? (isMulti
                        ? g.GradientEncode(
                            variable: 'label',
                            values: sliceGradients,
                          )
                        : g.GradientEncode(value: sliceGradients.first))
                  : null,
              selectionStream: _useOverlay ? _selectionStream : null,
              modifiers: [g.StackModifier()],
              // Percent labels are rendered via Flutter overlay
              // ([_PiePercentOverlay]) so they can run a count-up + fade
              // tween after slices finish sweeping in. graphic's
              // [LabelEncode] has no per-label animation timeline.
              transition: playEntrance
                  ? g.Transition(
                      duration: style.effectiveAnimationDuration,
                      curve: style.effectiveAnimationCurve,
                    )
                  : null,
              entrance: playEntrance ? _markEntrance : null,
            ),
          ],
          // Tooltip is handled via `CustomPaintTooltipOverlay` with a
          // manual polar hit-test (graphic's nearest-Euclidean lookup
          // misfires on polar — picks neighbor wedges when cursor is
          // deep inside one).
          selections: null,
          tooltip: _useOverlay ? null : buildChartTooltip(context, style),
        ),
      ),
    );

    // Spin / scale animations transform only the pie wedges, leaving
    // the percent overlay + center label still — otherwise text
    // moves along with the pie which reads as motion-sick.
    Widget transformedPie = pie;
    if (style.enableAnimation) {
      if (animation == PieChartAnimation.spin) {
        transformedPie = _SpinIn(
          duration: style.effectiveAnimationDuration,
          curve: style.effectiveAnimationCurve,
          child: transformedPie,
        );
      } else if (animation == PieChartAnimation.scale) {
        transformedPie = _ScaleIn(
          duration: style.effectiveAnimationDuration,
          curve: style.effectiveAnimationCurve,
          child: transformedPie,
        );
      }
    }

    // Percent overlay sits above the pie. Waits for slice sweep to
    // finish, then count-ups + fades each percent in. Skips the wait
    // when animation is disabled.
    final pieWithPercents = showPercentLabels && total > 0
        ? Stack(
            fit: StackFit.expand,
            children: [
              transformedPie,
              _PiePercentOverlay(
                percentages: [for (final s in slices) s.value / total],
                donut: donut,
                donutRadiusRatio: donutRadiusRatio,
                arcStartAngle: _arcStartAngle,
                arcSpan: _arcSpan,
                startDelay: style.enableAnimation
                    ? style.effectiveAnimationDuration
                    : Duration.zero,
                animationDuration: const Duration(milliseconds: 600),
              ),
            ],
          )
        : transformedPie;

    // Optional slice labels around the perimeter — Flutter overlay
    // anchored at each slice's mid-angle, just outside the outer
    // arc. Per-angle anchor keeps text extending OUTWARD.
    final pieWithSliceLabels = widget.showSliceLabels
        ? Stack(
            fit: StackFit.expand,
            clipBehavior: Clip.none,
            children: [
              pieWithPercents,
              _PieSliceLabelOverlay(
                slices: slices,
                colors: paletteColors,
                total: total,
                donutRadiusRatio: donut ? donutRadiusRatio : 0,
                arcStartAngle: _arcStartAngle,
                arcSpan: _arcSpan,
                startDelay: style.enableAnimation
                    ? style.effectiveAnimationDuration
                    : Duration.zero,
                duration: const Duration(milliseconds: 600),
              ),
            ],
          )
        : pieWithPercents;

    final pieWithLabel = (donut && centerLabel != null)
        ? Stack(
            alignment: Alignment.center,
            children: [
              pieWithSliceLabels,
              // Half-circle center label sits at the bottom of the
              // arc (where the flat edge meets the donut hole).
              // Offset up by ~half-radius so it visually centers in
              // the upper half-disk instead of the chart center.
              if (halfCircle)
                FractionalTranslation(
                  translation: const Offset(0, -1),
                  child: _CenterLabel(
                    label: centerLabel!,
                    subLabel: centerSubLabel,
                  ),
                )
              else
                _CenterLabel(
                  label: centerLabel!,
                  subLabel: centerSubLabel,
                ),
            ],
          )
        : pieWithSliceLabels;

    // Manual polar hit-test for accurate hover-to-slice mapping.
    final framed = _useOverlay
        ? CustomPaintTooltipOverlay(
            hitTest: (pos, size) =>
                _polarHitTest(pos, size, total, paletteColors),
            builder: _tooltipBuilder,
            child: pieWithLabel,
          )
        : pieWithLabel;

    final entries = [
      for (var i = 0; i < slices.length; i++)
        ChartLegendEntry(
          label: slices[i].label,
          color: paletteColors[i],
          icon: slices[i].icon,
          iconAsset: slices[i].iconAsset,
          iconWidget: slices[i].iconWidget,
        ),
    ];

    return _wrap(entries, framed);
  }

  /// Polar hit-test — converts cursor `(x, y)` to polar `(r, θ)`
  /// from chart center, then maps θ to the slice whose cumulative
  /// angular range contains it. Pie slice angles vary per value
  /// share, unlike polar-area's equal sectors.
  List<TooltipEntry> _polarHitTest(
    Offset pos,
    Size size,
    double total,
    List<Color> paletteColors,
  ) {
    final center = size.center(Offset.zero);
    final outerR = (size.shortestSide / 2) - 10;
    if (outerR <= 0) return const [];
    final innerR = donut ? donutRadiusRatio * outerR : 0.0;

    final dx = pos.dx - center.dx;
    final dy = pos.dy - center.dy;
    final r = math.sqrt(dx * dx + dy * dy);
    if (r < innerR || r > outerR) return const [];

    // Cursor canvas angle (graphic convention: 0 = right, π/2 =
    // down, π = left, -π/2 = up). Pie's arc spans
    // `[arcStartAngle, arcEndAngle]` in this same convention.
    var canvasAngle = math.atan2(dy, dx);
    // Wrap into the pie's arc range.
    while (canvasAngle < _arcStartAngle) {
      canvasAngle += 2 * math.pi;
    }
    if (canvasAngle > _arcEndAngle) return const [];

    final relativeAngle = canvasAngle - _arcStartAngle; // [0, span]

    var cum = 0.0;
    for (var i = 0; i < slices.length; i++) {
      final sweep = (slices[i].value / total) * _arcSpan;
      if (relativeAngle >= cum && relativeAngle < cum + sweep) {
        final s = slices[i];
        return [
          TooltipEntry(
            label: s.label,
            value: formatChartNumber(s.value, style),
            color: paletteColors[i],
            icon: s.icon,
            iconAsset: s.iconAsset,
            iconWidget: s.iconWidget,
          ),
        ];
      }
      cum += sweep;
    }
    return const [];
  }

  // ignore: unused_element
  List<TooltipEntry> _resolveTooltipEntries(
    Set<int> selected,
    List<Color> paletteColors,
  ) {
    if (selected.isEmpty) return const [];
    final out = <TooltipEntry>[];
    for (final i in selected) {
      if (i < 0 || i >= slices.length) continue;
      final slice = slices[i];
      final formatted = formatChartNumber(slice.value, style);
      out.add(
        TooltipEntry(
          label: slice.label,
          value: formatted,
          color: paletteColors[i],
          icon: slice.icon,
          iconAsset: slice.iconAsset,
          iconWidget: slice.iconWidget,
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

    if (halfCircle) return _wrapHalfCircle(body, legend);

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

  // Half-circle wrap: chart self-crops to ~62% of width via OverflowBox,
  // legend lives in normal flow outside the cropped region so it stays
  // visible. Avoids the bug where _sized would clamp Column[chart, legend]
  // total height to 62% of width and push legend offscreen.
  Widget _wrapHalfCircle(Widget body, Widget legend) {
    Widget halfChart() => LayoutBuilder(
      builder: (_, c) {
        final w = c.maxWidth.isFinite ? c.maxWidth : 360.0;
        return SizedBox(
          width: w,
          height: w * 0.62,
          child: OverflowBox(
            maxHeight: w,
            alignment: Alignment.topCenter,
            child: SizedBox(width: w, height: w, child: body),
          ),
        );
      },
    );

    return Builder(
      builder: (context) {
        final maxW = resolveSquareChartMaxWidth(context, style);
        Widget content;
        switch (style.legendPosition) {
          case ChartLegendPosition.top:
            content = Column(
              mainAxisSize: MainAxisSize.min,
              children: [legend, const SizedBox(height: 8), halfChart()],
            );
          case ChartLegendPosition.bottom:
            content = Column(
              mainAxisSize: MainAxisSize.min,
              children: [halfChart(), const SizedBox(height: 8), legend],
            );
          case ChartLegendPosition.left:
            content = Row(
              children: [
                legend,
                const SizedBox(width: 8),
                Expanded(child: halfChart()),
              ],
            );
          case ChartLegendPosition.right:
            content = Row(
              children: [
                Expanded(child: halfChart()),
                const SizedBox(width: 8),
                legend,
              ],
            );
          case ChartLegendPosition.hidden:
            content = halfChart();
        }
        return Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxW),
            child: content,
          ),
        );
      },
    );
  }

  Widget _sized(Widget child) {
    return Builder(
      builder: (context) {
        final maxW = resolveSquareChartMaxWidth(context, style);
        if (!halfCircle) {
          return Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: style.minHeight,
                maxWidth: maxW,
              ),
              child: AspectRatio(aspectRatio: 1, child: child),
            ),
          );
        }
        // Half-circle: graphic polar uses `min(W, H)` as diameter,
        // so the chart needs a square canvas internally to draw
        // a full-width arc. ClipRect + OverflowBox crops the
        // bottom whitespace so outer layout reports ~62% height
        // instead of wasting space below the arc.
        return Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxW),
            child: LayoutBuilder(
              builder: (_, c) {
                final w = c.maxWidth.isFinite ? c.maxWidth : 360.0;
                // No ClipRect — slice labels / center labels can
                // paint outside the reported height. SizedBox sets
                // the layout-reported height (~62% of width) so
                // surrounding widgets (legend, page) don't waste
                // space, while OverflowBox lets the chart render
                // at full square + labels bleed into the freed
                // bottom area.
                return SizedBox(
                  width: w,
                  height: w * 0.62,
                  child: OverflowBox(
                    maxHeight: w,
                    alignment: Alignment.topCenter,
                    child: SizedBox(
                      width: w,
                      height: w,
                      child: child,
                    ),
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }
}

class _CenterLabel extends StatelessWidget {
  const _CenterLabel({required this.label, this.subLabel});

  final String label;
  final String? subLabel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).textTheme;
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: theme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
            color: context.textColors.primary,
          ),
        ),
        if (subLabel != null) ...[
          const SizedBox(height: 2),
          Text(
            subLabel!,
            style: theme.bodySmall?.copyWith(
              color: context.textColors.secondary,
            ),
          ),
        ],
      ],
    );
  }
}

/// Rotates [child] from -π to 0 once on mount — pairs with the
/// underlying mark sweep so the pie spins into place. Holds at the
/// final angle afterwards so subsequent rebuilds (hover, selection)
/// don't replay.
class _SpinIn extends StatefulWidget {
  const _SpinIn({
    required this.duration,
    required this.curve,
    required this.child,
  });

  final Duration duration;
  final Curve curve;
  final Widget child;

  @override
  State<_SpinIn> createState() => _SpinInState();
}

class _SpinInState extends State<_SpinIn> with SingleTickerProviderStateMixin {
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

/// Scales [child] from 0 to 1 once on mount — pie wedges grow from
/// the chart center outward. Holds at scale 1 afterwards so
/// subsequent rebuilds (hover, selection) don't replay.
class _ScaleIn extends StatefulWidget {
  const _ScaleIn({
    required this.duration,
    required this.curve,
    required this.child,
  });

  final Duration duration;
  final Curve curve;
  final Widget child;

  @override
  State<_ScaleIn> createState() => _ScaleInState();
}

class _ScaleInState extends State<_ScaleIn>
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

/// Renders animated percentage labels on top of the pie. Each label
/// fades in and counts up from `0%` to its target after [startDelay]
/// — meant to fire once the slices have finished sweeping in.
///
/// Positions are computed from slice midpoint angles (graphic draws
/// pie slices clockwise from 12 o'clock by default). Radius sits at
/// the midpoint between inner (donut hole) and outer edges.
class _PiePercentOverlay extends StatefulWidget {
  const _PiePercentOverlay({
    required this.percentages,
    required this.donut,
    required this.donutRadiusRatio,
    required this.arcStartAngle,
    required this.arcSpan,
    required this.startDelay,
    required this.animationDuration,
  });

  final List<double> percentages;
  final bool donut;
  final double donutRadiusRatio;
  final double arcStartAngle;
  final double arcSpan;
  final Duration startDelay;
  final Duration animationDuration;

  @override
  State<_PiePercentOverlay> createState() => _PiePercentOverlayState();
}

class _PiePercentOverlayState extends State<_PiePercentOverlay> {
  bool _ready = false;
  Timer? _delay;

  @override
  void initState() {
    super.initState();
    if (widget.startDelay == Duration.zero) {
      _ready = true;
    } else {
      _delay = Timer(widget.startDelay, () {
        if (mounted) setState(() => _ready = true);
      });
    }
  }

  @override
  void dispose() {
    _delay?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: LayoutBuilder(
        builder: (context, c) {
          final size = Size(c.maxWidth, c.maxHeight);
          final center = size.center(Offset.zero);
          // graphic insets the polar area by ~10dp.
          final outerR = (size.shortestSide / 2) - 10;
          if (outerR <= 0) return const SizedBox.shrink();
          final innerR = widget.donut ? widget.donutRadiusRatio * outerR : 0.0;
          final midR = (innerR + outerR) / 2;

          var cum = 0.0;
          final children = <Widget>[];
          for (var i = 0; i < widget.percentages.length; i++) {
            final p = widget.percentages[i];
            final sweep = p * widget.arcSpan;
            final mid = widget.arcStartAngle + cum + sweep / 2;
            cum += sweep;
            // Skip slivers — too small to fit a percent label.
            if (p < 0.03) continue;
            final pos = Offset(
              center.dx + midR * math.cos(mid),
              center.dy + midR * math.sin(mid),
            );
            children.add(
              Positioned(
                left: pos.dx,
                top: pos.dy,
                child: FractionalTranslation(
                  translation: const Offset(-0.5, -0.5),
                  child: _AnimatedPercent(
                    percent: p,
                    duration: widget.animationDuration,
                    play: _ready,
                  ),
                ),
              ),
            );
          }

          return Stack(children: children);
        },
      ),
    );
  }
}

class _AnimatedPercent extends StatelessWidget {
  const _AnimatedPercent({
    required this.percent,
    required this.duration,
    required this.play,
  });

  final double percent;
  final Duration duration;
  final bool play;

  @override
  Widget build(BuildContext context) {
    final style = outlinedLabelStyle(
      context: context,
      fill: Colors.white,
      stroke: Colors.black.withValues(alpha: 0.55),
      fontWeight: FontWeight.w700,
    );
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: play ? 1.0 : 0.0),
      duration: duration,
      curve: Curves.easeOutCubic,
      builder: (context, t, _) {
        return Opacity(
          opacity: t,
          child: Text(
            AppNumbers.percent(percent * t),
            style: style,
          ),
        );
      },
    );
  }
}

/// Per-slice label overlay for pie charts. Each label sits just
/// outside its slice's outer arc at the slice's mid-angle. Pie
/// slice mid-angles depend on cumulative value share (unlike
/// polar-area's equal sectors). Per-angle anchor keeps text
/// extending OUTWARD so labels never overlap the wedges.
class _PieSliceLabelOverlay extends StatefulWidget {
  const _PieSliceLabelOverlay({
    required this.slices,
    required this.colors,
    required this.total,
    required this.donutRadiusRatio,
    required this.arcStartAngle,
    required this.arcSpan,
    required this.startDelay,
    required this.duration,
  });

  final List<PieSlice> slices;
  final List<Color> colors;
  final double total;
  final double donutRadiusRatio;
  final double arcStartAngle;
  final double arcSpan;
  final Duration startDelay;
  final Duration duration;

  @override
  State<_PieSliceLabelOverlay> createState() => _PieSliceLabelOverlayState();
}

class _PieSliceLabelOverlayState extends State<_PieSliceLabelOverlay> {
  bool _ready = false;
  Timer? _delay;

  @override
  void initState() {
    super.initState();
    if (widget.startDelay == Duration.zero) {
      _ready = true;
    } else {
      _delay = Timer(widget.startDelay, () {
        if (mounted) setState(() => _ready = true);
      });
    }
  }

  @override
  void dispose() {
    _delay?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final labelStyle = theme.textTheme.labelMedium?.copyWith(
      color: theme.textTheme.bodyMedium?.color,
      fontWeight: FontWeight.w600,
    );

    return IgnorePointer(
      child: LayoutBuilder(
        builder: (context, c) {
          final size = Size(c.maxWidth, c.maxHeight);
          final center = size.center(Offset.zero);
          final outerR = (size.shortestSide / 2) - 10;
          if (outerR <= 0) return const SizedBox.shrink();

          return TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.0, end: _ready ? 1.0 : 0.0),
            duration: widget.duration,
            curve: Curves.easeOutCubic,
            builder: (context, t, _) {
              final positioned = <Widget>[];
              var cum = 0.0;
              for (var i = 0; i < widget.slices.length; i++) {
                final s = widget.slices[i];
                if (widget.total <= 0) continue;
                final sweep = (s.value / widget.total) * widget.arcSpan;
                final mid = widget.arcStartAngle + cum + sweep / 2;
                cum += sweep;

                // Skip slivers — too narrow to host a label.
                if (s.value / widget.total < 0.02) continue;

                const offset = 6.0;
                final labelR = outerR + offset;
                final dx = center.dx + labelR * math.cos(mid);
                final dy = center.dy + labelR * math.sin(mid);

                // Per-angle anchor — text extends radially outward.
                final tx = -0.5 + 0.5 * math.cos(mid);
                final ty = -0.5 + 0.5 * math.sin(mid);

                positioned.add(
                  Positioned(
                    left: dx,
                    top: dy,
                    child: FractionalTranslation(
                      translation: Offset(tx, ty),
                      child: Opacity(
                        opacity: t,
                        child: Text(s.label, style: labelStyle),
                      ),
                    ),
                  ),
                );
              }
              return Stack(
                clipBehavior: Clip.none,
                children: positioned,
              );
            },
          );
        },
      ),
    );
  }
}
