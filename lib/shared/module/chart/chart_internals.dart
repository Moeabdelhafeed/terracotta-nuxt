import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:graphic/graphic.dart' as g;

import '../../../core/extensions/theme_colors_extension.dart';
import '../../../core/localization/number_formatter.dart';
import '../../../core/responsive/extensions.dart';
import '../../../core/responsive/window_size_class.dart';
import 'chart_models.dart';

/// Resolve the palette of series colors. Honors [ChartStyle.seriesColors]
/// if provided; otherwise rotates through palette + status colors so
/// successive series get distinct, theme-aware hues.
List<Color> resolveSeriesColors(
  BuildContext context,
  ChartStyle style,
  int count,
) {
  if (style.seriesColors != null && style.seriesColors!.isNotEmpty) {
    return List.generate(
      count,
      (i) => style.seriesColors![i % style.seriesColors!.length],
    );
  }
  final p = context.primaryColors;
  final s = context.statusColors;
  final palette = <Color>[
    p.primary,
    p.secondary,
    p.accent,
    s.success,
    s.info,
    s.warning,
    s.error,
  ];
  return List.generate(count, (i) => palette[i % palette.length]);
}

/// Default tooltip + axis number formatter — locale-aware compact
/// (`1.2K`, `3.5M`, locale-native digits in Arabic locales). Custom
/// formatters override via [ChartStyle.numberFormatter].
String formatChartNumber(num value, ChartStyle style) {
  if (style.numberFormatter != null) return style.numberFormatter!(value);
  return AppNumbers.compact(value);
}

/// Resolved axis label text style. Pulls from
/// `Theme.of(c).textTheme.labelMedium` so the chart inherits the app's
/// active font family — the script-aware family pair is honored automatically.
///
/// Bumped weight + size vs. the default so axis labels read as
/// proper UI chrome rather than incidental grid annotations.
/// Applies a background-matched halo so labels stay readable when
/// they cross grid lines or other chart geometry.
TextStyle resolveAxisLabelStyle(BuildContext context, ChartStyle style) {
  final base =
      style.axisLabelStyle ??
      Theme.of(context).textTheme.labelMedium ??
      const TextStyle(fontSize: 12);
  final fill = base.color ?? context.textColors.secondary;
  return outlinedLabelStyle(
    context: context,
    fill: fill,
    base: base,
    fontWeight: base.fontWeight ?? FontWeight.w600,
    haloWidth: 2.5,
  ).copyWith(letterSpacing: 0.2);
}

/// Resolved grid line color. Falls back to outline variant.
Color resolveGridColor(BuildContext context, ChartStyle style) {
  return style.gridColor ?? context.backgroundColors.outlineVariant;
}

/// Token-themed tooltip with refined chrome — rounded corners,
/// generous padding, soft elevation, subtle border. Use everywhere
/// for consistency.
g.TooltipGuide? buildChartTooltip(BuildContext context, ChartStyle style) {
  if (!style.enableTooltip) return null;
  final base =
      Theme.of(context).textTheme.bodySmall ??
      const TextStyle(fontSize: 12, fontWeight: FontWeight.w600);
  return g.TooltipGuide(
    followPointer: const [false, true],
    align: Alignment.topLeft,
    offset: const Offset(-12, -12),
    backgroundColor:
        style.tooltipBackgroundColor ?? context.backgroundColors.cardBackground,
    radius: const Radius.circular(10),
    elevation: 6,
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    textStyle: (style.tooltipTextStyle ?? base).copyWith(
      color: style.tooltipTextStyle?.color ?? context.textColors.primary,
      fontWeight: style.tooltipTextStyle?.fontWeight ?? FontWeight.w600,
      height: 1.4,
    ),
    constrained: true,
  );
}

/// Build a `TextStyle` with a soft halo around glyphs — for in-chart
/// labels that may overlap colored fills (pie %, bar value labels,
/// axis ticks crossing grid lines). Works as a "mask" by setting
/// [stroke] to the active background color, so glyphs appear to be
/// cut out of the background regardless of what's behind them.
///
/// Inherits the app font family from `Theme.of(c).textTheme.bodySmall`
/// (or whatever [base] is passed). Apply only the halo + fill;
/// preserves family / letter spacing / etc. from base.
///
/// Faked via two zero-offset blurred shadows. graphic accepts any
/// Flutter `TextStyle` so this works backend-agnostically.
TextStyle outlinedLabelStyle({
  required BuildContext context,
  required Color fill,
  Color? stroke,
  TextStyle? base,
  double? fontSize,
  FontWeight? fontWeight,
  double haloWidth = 3,
}) {
  final s = stroke ?? context.backgroundColors.background;
  final baseStyle =
      base ??
      Theme.of(context).textTheme.labelSmall ??
      const TextStyle(fontSize: 12);
  return baseStyle.copyWith(
    color: fill,
    fontSize: fontSize ?? baseStyle.fontSize,
    fontWeight: fontWeight ?? baseStyle.fontWeight ?? FontWeight.w600,
    shadows: [
      // Two stacked blurred shadows = denser halo, smoother edges
      // than cardinal-offset zero-blur shadows (which look blocky).
      Shadow(color: s, blurRadius: haloWidth),
      Shadow(color: s, blurRadius: haloWidth / 2),
    ],
  );
}

/// Bucket-aware max width for charts. Stops charts from sprawling
/// across wide screens. Override per call via [ChartStyle.maxWidth].
double resolveChartMaxWidth(BuildContext context, ChartStyle style) {
  if (style.maxWidth != null) return style.maxWidth!;
  return switch (context.windowSize) {
    WindowSizeClass.compact => double.infinity,
    WindowSizeClass.medium => double.infinity,
    WindowSizeClass.expanded => 720,
    WindowSizeClass.large => 880,
    WindowSizeClass.extraLarge => 1000,
  };
}

/// Bucket-aware max width for sparklines. Tighter than full charts —
/// sparklines are meant for card embeds, not standalone display.
double resolveSparklineMaxWidth(BuildContext context, [double? override]) {
  if (override != null) return override;
  return switch (context.windowSize) {
    WindowSizeClass.compact => double.infinity,
    WindowSizeClass.medium => 320,
    WindowSizeClass.expanded => 360,
    WindowSizeClass.large => 400,
    WindowSizeClass.extraLarge => 440,
  };
}

/// Bucket-aware max width for square charts (pie / radar). Tighter
/// than [resolveChartMaxWidth] because square aspect ratio means
/// width also drives height — a 1000-px pie is a 1000-px-tall pie.
double resolveSquareChartMaxWidth(BuildContext context, ChartStyle style) {
  if (style.maxWidth != null) return style.maxWidth!;
  return switch (context.windowSize) {
    WindowSizeClass.compact => double.infinity,
    WindowSizeClass.medium => 380,
    WindowSizeClass.expanded => 440,
    WindowSizeClass.large => 480,
    WindowSizeClass.extraLarge => 520,
  };
}

// ═══════════════════════════════════════════════════════════
// Axis title frame
// ═══════════════════════════════════════════════════════════

/// Resolved axis-title text style. Pulls from
/// `Theme.textTheme.labelMedium` so the title inherits the app font,
/// and bumps weight + adds halo so it reads as proper UI chrome.
TextStyle resolveAxisTitleStyle(BuildContext context, TextStyle? override) {
  if (override != null) return override;
  final base =
      Theme.of(context).textTheme.labelMedium ?? const TextStyle(fontSize: 12);
  return base.copyWith(
    fontWeight: FontWeight.w700,
    color: context.textColors.secondary,
    letterSpacing: 0.3,
  );
}

/// Wrap [chart] with axis-title strips on the configured sides.
/// Y-axis title is rotated -90° (or 90° for `end` position).
Widget axisTitleFrame({
  required BuildContext context,
  required Widget chart,
  required ChartAxisLabel? xAxisLabel,
  required ChartAxisLabel? yAxisLabel,
}) {
  var core = chart;

  if (yAxisLabel != null) {
    final style = resolveAxisTitleStyle(context, yAxisLabel.style);
    final rotated = RotatedBox(
      // start (left): turns=3 → text reads bottom-up
      // end (right): turns=1 → text reads top-down
      quarterTurns: yAxisLabel.position == AxisTitlePosition.start ? 3 : 1,
      child: Text(yAxisLabel.text, style: style, textAlign: TextAlign.center),
    );
    final strip = Padding(
      padding: yAxisLabel.padding,
      child: Align(alignment: yAxisLabel.alignment, child: rotated),
    );
    final gap = SizedBox(width: yAxisLabel.gap);
    core = yAxisLabel.position == AxisTitlePosition.start
        ? Row(
            children: [
              strip,
              gap,
              Expanded(child: core),
            ],
          )
        : Row(
            children: [
              Expanded(child: core),
              gap,
              strip,
            ],
          );
  }

  if (xAxisLabel != null) {
    final style = resolveAxisTitleStyle(context, xAxisLabel.style);
    final strip = Padding(
      padding: xAxisLabel.padding,
      child: Align(
        alignment: xAxisLabel.alignment,
        child: Text(xAxisLabel.text, style: style),
      ),
    );
    final gap = SizedBox(height: xAxisLabel.gap);
    core = xAxisLabel.position == AxisTitlePosition.start
        ? Column(
            children: [
              Expanded(child: core),
              gap,
              strip,
            ],
          )
        : Column(
            children: [
              strip,
              gap,
              Expanded(child: core),
            ],
          );
  }

  return core;
}

// ═══════════════════════════════════════════════════════════
// Axis shadow frame
// ═══════════════════════════════════════════════════════════

/// Paints an inner shadow along the X- and Y-axis lines that
/// radiates only INTO the plot area — axes appear to be the raised
/// edges of a recessed well. Implemented as a single L-shaped
/// stroke clipped to the plot rect, so the Gaussian blur leaks only
/// inward (the outer half is clipped away). Optional highlight is a
/// crisp 1px stroke painted ON the axis line for an embossed edge.
Widget axisShadowFrame({
  required BuildContext context,
  required Widget child,
  required ChartStyle style,
}) {
  if (!style.enableAxisShadow) return child;
  final shadow = style.axisShadowColor ?? Colors.black.withValues(alpha: 0.45);
  final highlight = style.axisShadowHighlightColor ?? Colors.transparent;
  return Stack(
    fit: StackFit.expand,
    children: [
      IgnorePointer(
        child: CustomPaint(
          painter: _AxisShadowPainter(
            shadow: shadow,
            highlight: highlight,
            blur: style.axisShadowBlur,
            inset: style.axisShadowInset,
            cornerRadius: style.axisShadowCornerRadius,
          ),
          size: Size.infinite,
        ),
      ),
      child,
    ],
  );
}

class _AxisShadowPainter extends CustomPainter {
  _AxisShadowPainter({
    required this.shadow,
    required this.highlight,
    required this.blur,
    required this.inset,
    required this.cornerRadius,
  });

  final Color shadow;
  final Color highlight;
  final double blur;
  final EdgeInsetsDirectional inset;
  final double cornerRadius;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;
    final left = inset.start;
    final right = size.width - inset.end;
    final top = inset.top;
    final bottom = size.height - inset.bottom;
    if (right <= left || bottom <= top) return;

    final r = cornerRadius.clamp(0.0, math.min(right - left, bottom - top) / 2);

    // L-path traces the axis lines: down the Y-axis, rounded corner
    // at intersection, right along the X-axis. Path sits exactly on
    // the axis lines (no offset) — clipping does the heavy lifting.
    final axisPath = Path()
      ..moveTo(left, top)
      ..lineTo(left, bottom - r);
    if (r > 0) {
      axisPath.arcToPoint(
        Offset(left + r, bottom),
        radius: Radius.circular(r),
      );
    }
    axisPath.lineTo(right, bottom);

    // Clip to plot rect → blur only radiates INTO the plot area.
    canvas.save();
    canvas.clipRect(Rect.fromLTRB(left, top, right, bottom));

    final shadowPaint = Paint()
      ..color = shadow
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, blur);
    canvas.drawPath(axisPath, shadowPaint);

    canvas.restore();

    // Highlight is a crisp light edge on the axis line itself —
    // painted unclipped, but with low alpha + tiny blur so it
    // reads as a subtle bevel rather than a hard line.
    if (highlight.a > 0) {
      final highlightPaint = Paint()
        ..color = highlight
        ..strokeWidth = 1
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 0.6);
      canvas.drawPath(axisPath, highlightPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _AxisShadowPainter old) =>
      old.shadow != shadow ||
      old.highlight != highlight ||
      old.blur != blur ||
      old.inset != inset ||
      old.cornerRadius != cornerRadius;
}

// ═══════════════════════════════════════════════════════════
// Gradient + draw-in reveal helpers (shared by line + bar)
// ═══════════════════════════════════════════════════════════

/// Synthesize a single-color [LinearGradient] for series that don't
/// supply their own gradient — keeps `GradientEncode.values` lengths
/// aligned across series when at least one provides a real gradient.
LinearGradient flatGradient(Color c) => LinearGradient(colors: [c, c]);

/// Wraps a chart with a left-anchored [ClipRect] that animates from
/// 0% to 100% width once on mount — produces a "drawn" reveal. Stays
/// at full width afterwards so subsequent rebuilds (hover, selection)
/// don't replay.
class DrawInRevealer extends StatefulWidget {
  const DrawInRevealer({
    required this.duration,
    required this.curve,
    required this.child,
    super.key,
  });

  final Duration duration;
  final Curve curve;
  final Widget child;

  @override
  State<DrawInRevealer> createState() => _DrawInRevealerState();
}

class _DrawInRevealerState extends State<DrawInRevealer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration);
    _animation = CurvedAnimation(parent: _controller, curve: widget.curve);
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
      animation: _animation,
      builder: (context, child) {
        return ClipRect(
          clipper: _LeftRevealClipper(_animation.value),
          child: child,
        );
      },
      child: widget.child,
    );
  }
}

class _LeftRevealClipper extends CustomClipper<Rect> {
  _LeftRevealClipper(this.t);

  final double t;

  @override
  Rect getClip(Size size) =>
      Rect.fromLTWH(0, 0, size.width * t.clamp(0.0, 1.0), size.height);

  @override
  bool shouldReclip(covariant _LeftRevealClipper old) => old.t != t;
}

// ═══════════════════════════════════════════════════════════
// EntranceGate — play entry animation once, then never again
// ═══════════════════════════════════════════════════════════

/// Mounts the chart with `playEntrance: true` for [duration], then
/// flips the flag to `false` so subsequent rebuilds (e.g. driven by
/// hover / selection events inside `graphic`) don't replay the entry.
///
/// Pair with `entrance: playEntrance ? const {MarkEntrance.y} : null`
/// inside the chart spec. After the gate flips, entrance is null and
/// marks render at their final state instantly — hover-driven repaints
/// no longer reset to frame 0.
class EntranceGate extends StatefulWidget {
  const EntranceGate({
    required this.duration,
    required this.builder,
    this.enabled = true,
    super.key,
  });

  /// When false, builds with `playEntrance: false` from the first
  /// frame — chart renders at final state with no entry animation.
  final bool enabled;
  final Duration duration;
  final Widget Function(bool playEntrance) builder;

  @override
  State<EntranceGate> createState() => _EntranceGateState();
}

class _EntranceGateState extends State<EntranceGate> {
  late bool _play;

  @override
  void initState() {
    super.initState();
    _play = widget.enabled;
    if (widget.enabled) {
      // Delay slightly past `duration` so the animation finishes naturally
      // before we strip entrance from the spec.
      Future.delayed(widget.duration + const Duration(milliseconds: 100), () {
        if (mounted) setState(() => _play = false);
      });
    }
  }

  @override
  Widget build(BuildContext context) => widget.builder(_play);
}
