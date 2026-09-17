import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:graphic/graphic.dart' as g;

import 'chart_data.dart';
import 'chart_internals.dart';
import 'chart_legend.dart';
import 'chart_models.dart';
import 'chart_tooltip_overlay.dart';
import 'custom_paint_tooltip.dart';

export 'chart_data.dart' show PolarSlice;
export 'chart_legend.dart' show ChartLegendEntry;
export 'chart_models.dart'
    show ChartStyle, PolarAreaAnimation, ChartLegendPosition;

/// Polar area / Coxcomb chart — every category gets an equal angular
/// slice; [PolarSlice.value] drives radial length. Striking variant
/// of pie/bar that emphasizes magnitude differences over composition.
///
/// ```dart
/// GlobalPolarArea(
///   slices: [
///     PolarSlice(label: 'Mon', value: 12),
///     PolarSlice(label: 'Tue', value: 18),
///     ...
///   ],
/// )
/// ```
class GlobalPolarArea extends StatefulWidget {
  const GlobalPolarArea({
    required this.slices,
    this.style = ChartStyle.standard,
    this.startRadius = 0,
    this.showLabels = false,
    this.showRadialAxis = false,
    this.showValueLabels = false,
    this.borderRadius,
    this.animation = PolarAreaAnimation.grow,
    this.valueFormatter,
    super.key,
  });

  final List<PolarSlice> slices;
  final ChartStyle style;

  /// Inner radius ratio (0..1). Use > 0 for ring-style polar area.
  final double startRadius;

  /// Show category labels around the perimeter.
  final bool showLabels;

  /// Show numeric radial axis labels (the value scale rings). Off
  /// by default — they tend to read as visual noise behind the
  /// wedges. Turn on for technical / dashboard views.
  final bool showRadialAxis;

  /// Render the slice value text inside each wedge. Halo + drop
  /// shadow applied for legibility against any tint.
  final bool showValueLabels;

  /// Round the outer corner of each wedge. Top of `BorderRadius`
  /// is the outer arc, bottom is the inner radius. Common pattern:
  /// `BorderRadius.vertical(top: Radius.circular(8))` for a soft
  /// outer edge while keeping the inner corner sharp.
  final BorderRadius? borderRadius;

  /// Entry animation preset. See [PolarAreaAnimation].
  final PolarAreaAnimation animation;

  /// Format the in-slice value text. Defaults to locale-aware compact.
  final String Function(double)? valueFormatter;

  @override
  State<GlobalPolarArea> createState() => _GlobalPolarAreaState();
}

class _GlobalPolarAreaState extends State<GlobalPolarArea> {
  StreamController<g.GestureEvent>? _gestureStream;
  StreamController<g.Selected?>? _selectionStream;

  List<PolarSlice> get slices => widget.slices;
  ChartStyle get style => widget.style;

  bool get _useOverlay => style.enableTooltip;
  ChartTooltipBuilder get _tooltipBuilder =>
      style.tooltipBuilder ?? defaultTooltipBuilder;

  /// Map [PolarAreaAnimation] to graphic's native [g.MarkEntrance].
  /// `spin` and `scale` return null — Flutter `Transform` wrappers
  /// handle those modes so wedges keep their final geometry
  /// (rounded corners don't clip mid-grow).
  Set<g.MarkEntrance>? get _markEntrance => switch (widget.animation) {
    PolarAreaAnimation.grow => const {g.MarkEntrance.y},
    PolarAreaAnimation.fade => const {g.MarkEntrance.opacity},
    PolarAreaAnimation.spin => null,
    PolarAreaAnimation.scale => null,
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

    final palette = resolveSeriesColors(context, style, slices.length);
    final colors = [
      for (var i = 0; i < slices.length; i++) slices[i].color ?? palette[i],
    ];
    final hasGradient = slices.any((s) => s.gradient != null);
    final gradients = [
      for (var i = 0; i < slices.length; i++)
        slices[i].gradient ?? flatGradient(colors[i]),
    ];
    final axisStyle = resolveAxisLabelStyle(context, style);
    final gridColor = resolveGridColor(context, style);

    final data = [
      for (var i = 0; i < slices.length; i++)
        {'label': slices[i].label, 'value': slices[i].value},
    ];

    final isMulti = slices.length > 1;

    final chart = EntranceGate(
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
              scale: g.LinearScale(
                min: 0,
                formatter: (v) => formatChartNumber(v, style),
              ),
            ),
          },
          // graphic computes the inner arc corner radius via
          // `borderRadius.bottom.x / startRadius`. With
          // `startRadius == 0` and any borderRadius this yields
          // `0/0 = NaN`, killing the sector path → empty wedges.
          // Bump startRadius to a tiny non-zero floor when
          // borderRadius is set so the math stays finite.
          coord: g.PolarCoord(
            startRadius: widget.borderRadius != null && widget.startRadius == 0
                ? 0.001
                : widget.startRadius,
          ),
          marks: [
            g.IntervalMark(
              color: hasGradient
                  ? null
                  : (isMulti
                        ? g.ColorEncode(variable: 'label', values: colors)
                        : g.ColorEncode(value: colors.first)),
              gradient: hasGradient
                  ? (isMulti
                        ? g.GradientEncode(variable: 'label', values: gradients)
                        : g.GradientEncode(value: gradients.first))
                  : null,
              shape: g.ShapeEncode(
                value: g.RectShape(borderRadius: widget.borderRadius),
              ),
              // Labels + values rendered via Flutter overlay
              // (`_PolarLabelOverlay`) so they can fade + count-up
              // animate, anchor at slice centroid, and skip narrow
              // wedges. graphic's `LabelEncode` is static.
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
            // Angular axis line + labels handled by Flutter overlay
            // (`_PolarLabelOverlay`) for per-slice positioning +
            // count-up animation. graphic axis hidden.
            g.AxisGuide(
              line: g.PaintStyle(strokeColor: const Color(0x00000000)),
            ),
            // Radial axis (numeric scale rings) — hidden by default,
            // opt in via [showRadialAxis] when the values need
            // surfacing.
            g.AxisGuide(
              label: widget.showRadialAxis
                  ? g.LabelStyle(textStyle: axisStyle.copyWith(fontSize: 9))
                  : null,
              line: g.PaintStyle(strokeColor: const Color(0x00000000)),
              grid: widget.showRadialAxis && style.effectiveShowGrid
                  ? g.PaintStyle(strokeColor: gridColor, strokeWidth: 0.5)
                  : null,
            ),
          ],
          selections: style.enableTooltip
              ? {
                  // Position-based hit only — `variable: 'label'`
                  // selected ALL data with same label and made
                  // hover ambiguous near chart center.
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

    // Per-slice label / value overlay — paints text at each
    // slice's angular centroid. Skips narrow wedges, animates
    // count-up + fade once the entrance settles.
    final maxValue = slices.map((s) => s.value).reduce((a, b) => a > b ? a : b);
    Widget chartWithOverlay = chart;
    if (widget.showLabels || widget.showValueLabels) {
      // `Clip.none` lets the overlay paint outside the Stack's
      // bounds — labels positioned beyond the chart's outer ring
      // won't be cut off at the parent edges.
      chartWithOverlay = Stack(
        fit: StackFit.expand,
        clipBehavior: Clip.none,
        children: [
          chart,
          _PolarLabelOverlay(
            slices: slices,
            colors: colors,
            maxValue: maxValue,
            startRadius: widget.borderRadius != null && widget.startRadius == 0
                ? 0.001
                : widget.startRadius,
            showLabel: widget.showLabels,
            showValue: widget.showValueLabels,
            valueFormatter:
                widget.valueFormatter ?? (v) => formatChartNumber(v, style),
            startDelay: style.enableAnimation
                ? style.effectiveAnimationDuration
                : Duration.zero,
            duration: const Duration(milliseconds: 600),
          ),
        ],
      );
    }

    // Spin / scale wrap Flutter Transform around the chart so
    // wedges keep their final geometry — preserving rounded
    // corners that would otherwise clip mid-animation when the
    // radial extent grows from zero.
    var transformed = chartWithOverlay;
    if (style.enableAnimation) {
      if (widget.animation == PolarAreaAnimation.spin) {
        transformed = _PolarSpinIn(
          duration: style.effectiveAnimationDuration,
          curve: style.effectiveAnimationCurve,
          child: transformed,
        );
      } else if (widget.animation == PolarAreaAnimation.scale) {
        transformed = _PolarScaleIn(
          duration: style.effectiveAnimationDuration,
          curve: style.effectiveAnimationCurve,
          child: transformed,
        );
      }
    }

    // graphic's stream-based PointSelection misfires on polar
    // (nearest-Euclidean lookup picks neighbor wedges when cursor
    // is deep inside a tall slice). Use custom polar hit-test
    // instead: cursor → polar (r, θ) → angular slot index → slice.
    final framed = _useOverlay
        ? CustomPaintTooltipOverlay(
            hitTest: (pos, size) => _polarHitTest(pos, size, maxValue, colors),
            builder: _tooltipBuilder,
            child: transformed,
          )
        : transformed;

    final entries = [
      for (var i = 0; i < slices.length; i++)
        ChartLegendEntry(label: slices[i].label, color: colors[i]),
    ];

    return _wrap(entries, framed);
  }

  /// Polar hit-test — converts cursor `(x, y)` to polar `(r, θ)`
  /// relative to chart center, then maps θ to a slice index by
  /// angular sector. Verifies `r` is inside the slice's
  /// value-driven outer edge (and outside the donut hole). Mirrors
  /// the painter's geometry exactly so hover always matches the
  /// wedge under the cursor.
  List<TooltipEntry> _polarHitTest(
    Offset pos,
    Size size,
    double maxValue,
    List<Color> colors,
  ) {
    final center = size.center(Offset.zero);
    final outerR = (size.shortestSide / 2) - 10;
    if (outerR <= 0) return const [];
    final effectiveStart =
        widget.borderRadius != null && widget.startRadius == 0
        ? 0.001
        : widget.startRadius;
    final innerR = effectiveStart * outerR;

    final dx = pos.dx - center.dx;
    final dy = pos.dy - center.dy;
    final r = math.sqrt(dx * dx + dy * dy);
    if (r < innerR || r > outerR) return const [];

    // graphic places the first slice at 12 o'clock and sweeps
    // clockwise. atan2(dx, -dy) gives an angle from north (12),
    // increasing clockwise — matches the painter's convention.
    var angle = math.atan2(dx, -dy);
    if (angle < 0) angle += 2 * math.pi; // [0, 2π]

    final n = slices.length;
    final sweep = 2 * math.pi / n;
    final i = (angle / sweep).floor().clamp(0, n - 1);
    final s = slices[i];

    // Cursor must also be inside the wedge's actual radial extent
    // (value-driven outer edge), not just the chart's max ring.
    final valueR = innerR + (outerR - innerR) * (s.value / maxValue);
    if (r > valueR) return const [];

    return [
      TooltipEntry(
        label: s.label,
        value: formatChartNumber(s.value, style),
        color: colors[i],
      ),
    ];
  }

  // ignore: unused_element
  List<TooltipEntry> _resolveTooltipEntries(
    Set<int> selected,
    List<Color> colors,
  ) {
    if (selected.isEmpty) return const [];
    final out = <TooltipEntry>[];
    for (final i in selected) {
      if (i < 0 || i >= slices.length) continue;
      out.add(
        TooltipEntry(
          label: slices[i].label,
          value: formatChartNumber(slices[i].value, style),
          color: colors[i],
        ),
      );
    }
    return out;
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
            maxWidth: resolveSquareChartMaxWidth(context, style),
          ),
          child: AspectRatio(aspectRatio: 1, child: child),
        ),
      ),
    );
  }
}

/// Combined quarter-turn rotate + scale-in for a polished entrance.
/// Rotates from -π/4 → 0 (45° clockwise sweep) while scaling 0.7
/// → 1 with `easeOutBack`. Feels designed; the hard 180° spin was
/// disorienting at chart sizes.
class _PolarSpinIn extends StatefulWidget {
  const _PolarSpinIn({
    required this.duration,
    required this.curve,
    required this.child,
  });

  final Duration duration;
  final Curve curve;
  final Widget child;

  @override
  State<_PolarSpinIn> createState() => _PolarSpinInState();
}

class _PolarSpinInState extends State<_PolarSpinIn>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _t;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration);
    _t = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutBack,
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
      animation: _t,
      builder: (context, child) {
        final t = _t.value.clamp(0.0, 1.5);
        final angle = -math.pi / 4 * (1 - _t.value);
        final scale = 0.7 + 0.3 * t;
        return Transform.rotate(
          angle: angle,
          child: Transform.scale(scale: scale, child: child),
        );
      },
      child: widget.child,
    );
  }
}

/// Scales [child] 0 → 1 once on mount.
class _PolarScaleIn extends StatefulWidget {
  const _PolarScaleIn({
    required this.duration,
    required this.curve,
    required this.child,
  });

  final Duration duration;
  final Curve curve;
  final Widget child;

  @override
  State<_PolarScaleIn> createState() => _PolarScaleInState();
}

class _PolarScaleInState extends State<_PolarScaleIn>
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

/// Per-slice label / value overlay. Paints text at each slice's
/// angular centroid (mid-angle, mid-radius). Skips wedges too
/// narrow to host the text. Animates count-up + fade after the
/// chart entrance settles.
class _PolarLabelOverlay extends StatefulWidget {
  const _PolarLabelOverlay({
    required this.slices,
    required this.colors,
    required this.maxValue,
    required this.startRadius,
    required this.showLabel,
    required this.showValue,
    required this.valueFormatter,
    required this.startDelay,
    required this.duration,
  });

  final List<PolarSlice> slices;
  final List<Color> colors;
  final double maxValue;
  final double startRadius;
  final bool showLabel;
  final bool showValue;
  final String Function(double) valueFormatter;
  final Duration startDelay;
  final Duration duration;

  @override
  State<_PolarLabelOverlay> createState() => _PolarLabelOverlayState();
}

class _PolarLabelOverlayState extends State<_PolarLabelOverlay> {
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
    final valueStyle = theme.textTheme.labelSmall?.copyWith(
      color: Colors.white.withValues(alpha: 0.95),
      fontWeight: FontWeight.w700,
      fontFeatures: const [FontFeature.tabularFigures()],
      shadows: [
        Shadow(
          color: Colors.black.withValues(alpha: 0.55),
          blurRadius: 4,
          offset: const Offset(0, 1),
        ),
        Shadow(color: Colors.black.withValues(alpha: 0.35), blurRadius: 2),
      ],
    );

    return IgnorePointer(
      child: LayoutBuilder(
        builder: (context, c) {
          final size = Size(c.maxWidth, c.maxHeight);
          final center = size.center(Offset.zero);
          // graphic insets the polar region by ~10dp; matches `pie`.
          final outerR = (size.shortestSide / 2) - 10;
          if (outerR <= 0) return const SizedBox.shrink();
          final innerR = widget.startRadius * outerR;

          final n = widget.slices.length;
          if (n == 0) return const SizedBox.shrink();
          final sweep = 2 * math.pi / n;

          // Outside-slice label color matches surface text — must
          // contrast with the page bg, not the slice tint.
          final outsideLabelStyle = theme.textTheme.labelMedium?.copyWith(
            color: theme.textTheme.bodyMedium?.color,
            fontWeight: FontWeight.w600,
          );

          return TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.0, end: _ready ? 1.0 : 0.0),
            duration: widget.duration,
            curve: Curves.easeOutCubic,
            builder: (context, t, _) {
              final positioned = <Widget>[];
              for (var i = 0; i < n; i++) {
                final s = widget.slices[i];
                // graphic places first slice at top (12 o'clock)
                // and sweeps clockwise.
                final mid = -math.pi / 2 + (i + 0.5) * sweep;
                // Slice's outer edge is value-driven.
                final valueR =
                    innerR + (outerR - innerR) * (s.value / widget.maxValue);
                final midR = (innerR + valueR) / 2;

                // ── Outside-slice label (next to slice's outer
                // edge). Anchored at this SLICE's value-driven
                // outer edge so labels track each wedge's actual
                // length — short wedges get inner labels, tall
                // wedges get outer labels. Per-angle anchor keeps
                // text extending OUTWARD from chart center.
                if (widget.showLabel) {
                  const outsideOffset = 6.0;
                  final labelR = valueR + outsideOffset;
                  final ldx = center.dx + labelR * math.cos(mid);
                  final ldy = center.dy + labelR * math.sin(mid);
                  // Translation = `-0.5 + 0.5 * cos/sin(angle)`.
                  // At angle 0 (east) → (0, -0.5): text starts at
                  // anchor + extends right. At angle π/2 (south)
                  // → (-0.5, 0): text top-anchored, extends down.
                  // Etc — text always extends radially outward.
                  final tx = -0.5 + 0.5 * math.cos(mid);
                  final ty = -0.5 + 0.5 * math.sin(mid);
                  positioned.add(
                    Positioned(
                      left: ldx,
                      top: ldy,
                      child: FractionalTranslation(
                        translation: Offset(tx, ty),
                        child: Opacity(
                          opacity: t,
                          child: Text(s.label, style: outsideLabelStyle),
                        ),
                      ),
                    ),
                  );
                }

                // ── In-slice value (count-up). Skip when wedge is
                // too narrow — arc length at midR < ~26dp.
                if (widget.showValue) {
                  final arcLen = sweep * midR;
                  if (arcLen < 26) continue;
                  final shown = s.value * t;
                  final dx = center.dx + midR * math.cos(mid);
                  final dy = center.dy + midR * math.sin(mid);
                  positioned.add(
                    Positioned(
                      left: dx,
                      top: dy,
                      child: FractionalTranslation(
                        translation: const Offset(-0.5, -0.5),
                        child: Opacity(
                          opacity: t,
                          child: Text(
                            widget.valueFormatter(shown),
                            style: valueStyle,
                          ),
                        ),
                      ),
                    ),
                  );
                }
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
