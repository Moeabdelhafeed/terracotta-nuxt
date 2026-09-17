import 'package:flutter/material.dart';

import 'chart_tooltip_overlay.dart' show ChartTooltipBuilder;

const _kChartDefaultAnimationDuration = Duration(milliseconds: 900);

// ═══════════════════════════════════════════════════════════
// Defaults
// ═══════════════════════════════════════════════════════════

const kChartDefaultAspectRatio = 1.7;
const kChartDefaultMinHeight = 180.0;
const kChartDefaultPadding = EdgeInsets.all(12);

// ═══════════════════════════════════════════════════════════
// Enums
// ═══════════════════════════════════════════════════════════

/// Visual density preset — toggles axis labels, grid lines, dot size.
enum ChartDensity {
  /// No grid, no axes — just the data series. For card embeds and
  /// dashboard cells.
  minimal,

  /// Default — grid + both axes + legend.
  standard,

  /// Heavy — denser grid, tick marks, value labels on every point.
  detailed,
}

/// Where the legend renders relative to the chart area.
enum ChartLegendPosition { top, bottom, left, right, hidden }

/// Entry animation preset for line / area charts.
///
/// First four wrap graphic's native `MarkEntrance`. `drawIn` is a
/// Flutter-side clip reveal that wipes the line in left → right.
enum LineChartAnimation {
  /// Line rises from the y=0 baseline. Default — feels organic for
  /// time-series and trend data.
  growUp,

  /// Line slides in from the x=0 column. Each datum's x coordinate
  /// animates from 0 to its final position.
  slideIn,

  /// Line fades in from transparent.
  fade,

  /// Line scales up from zero stroke width / area.
  scale,

  /// Stroke wipes left → right, like a hand drawing the line.
  /// Implemented via a `ClipRect` over the chart canvas.
  drawIn,
}

/// Curve preset for line / area charts.
enum LineChartCurve {
  /// Sharp polyline — direct point-to-point segments.
  straight,

  /// Cardinal spline — smooth curve, default for most "trend" charts.
  smooth,

  /// Monotone cubic — smooth without overshooting min/max (safer for
  /// data where overshoot would be a lie, e.g. probabilities).
  monotone,

  /// Right-angle steps — value holds horizontally then jumps to next
  /// y. Used for discrete-state series (server status, subscription
  /// tiers, audit trails). Step direction follows
  /// [SteppedLinePosition].
  stepped,
}

/// Where the step transition lives in a stepped line segment —
/// before, after, or centered between two data points.
enum SteppedLinePosition {
  /// Step occurs at the start of the segment (jump up first, then
  /// hold horizontally to the next x). Best for "as of" semantics.
  before,

  /// Step occurs at the end of the segment (hold horizontally,
  /// then jump up). Best for "until" semantics. Default.
  after,

  /// Step centered between adjacent points.
  center,
}

/// Entry animation preset for bar charts.
///
/// First four wrap graphic's native `MarkEntrance`. `drawIn` is a
/// Flutter-side clip reveal that wipes bars in left → right.
enum BarChartAnimation {
  /// Bars rise from the y=0 baseline. Default — feels organic for
  /// vertical bars and matches stacked layouts.
  growUp,

  /// Bars slide in from the x=0 column. Good for horizontal bars.
  slideIn,

  /// Bars fade in from transparent.
  fade,

  /// Bars scale up from zero size.
  scale,

  /// Bars wipe left → right via a `ClipRect` overlay.
  drawIn,
}

/// Entry animation preset for scatter charts.
///
/// First four wrap graphic's native `MarkEntrance`. `drawIn` is a
/// Flutter-side clip reveal that wipes dots in left → right.
enum ScatterChartAnimation {
  /// Dots rise from y=0 baseline. Default.
  growUp,

  /// Dots slide in from x=0 column.
  slideIn,

  /// Dots fade in from transparent.
  fade,

  /// Dots scale up from zero size — pop-in effect.
  scale,

  /// Dots wipe left → right via a `ClipRect` overlay.
  drawIn,
}

/// Entry animation preset for bubble charts.
///
/// First four wrap graphic's native `MarkEntrance`. `drawIn` is a
/// Flutter-side clip reveal that wipes bubbles in left → right.
enum BubbleChartAnimation {
  /// Bubbles rise from y=0 baseline.
  growUp,

  /// Bubbles slide in from x=0 column.
  slideIn,

  /// Bubbles fade in from transparent.
  fade,

  /// Bubbles scale up from zero size — pop-in effect. Default.
  scale,

  /// Bubbles wipe left → right via a `ClipRect` overlay.
  drawIn,
}

/// Bar layout when multiple series are present.
enum BarChartLayout {
  /// Bars sit side-by-side per category.
  grouped,

  /// Bars stack on top of each other.
  stacked,

  /// Stacked but normalized to 100% — composition view.
  stackedPercent,
}

/// Bar orientation — vertical bars (most common) or horizontal
/// (long category labels, ranking lists).
enum BarChartOrientation { vertical, horizontal }

/// Entry animation preset for pie / donut charts.
///
/// First three wrap graphic's native `MarkEntrance`. `spin` is a
/// Flutter-side `Transform.rotate` that whirls the whole pie into
/// place during the entrance.
enum PieChartAnimation {
  /// Wedges sweep in from zero angle. Default.
  sweep,

  /// Wedges fade in from transparent.
  fade,

  /// Wedges scale up from zero size.
  scale,

  /// Pie spins into place — Transform.rotate from -π to 0 over the
  /// animation duration. Combines with the underlying sweep.
  spin,
}

/// Entry animation preset for radar charts.
///
/// First three wrap graphic's native `MarkEntrance`. `spin` is a
/// Flutter-side `Transform.rotate` over the whole radar plot during
/// the entrance.
enum RadarChartAnimation {
  /// Polygon vertices grow from center outward (y dimension entrance).
  /// Default — feels organic for radar shapes.
  growUp,

  /// Polygon fades in from transparent.
  fade,

  /// Polygon scales up from zero size.
  scale,

  /// Radar spins into place — `Transform.rotate` from -π to 0.
  spin,
}

/// Entry animation preset for heatmap charts.
enum HeatmapAnimation {
  /// All cells fade in together. Default.
  fade,

  /// Each cell scales 0→1 with a stagger based on its grid index
  /// — cascading pop-in from top-left.
  popIn,

  /// Cells reveal in a left-to-right wave (column-major stagger).
  waveIn,

  /// Cells reveal radially outward from the grid center.
  bloomOut,

  /// No animation — cells render at final state instantly.
  none,
}

/// Entry animation preset for polar-area / Coxcomb charts.
enum PolarAreaAnimation {
  /// Wedges grow outward from the center (radial extent animates).
  /// Default — feels organic but can clip rounded corners when the
  /// wedge is mid-grow.
  grow,

  /// Wedges fade in from transparent. Plays well with rounded
  /// corners since the geometry never collapses.
  fade,

  /// Whole chart spins into place (`Transform.rotate` -π → 0).
  spin,

  /// Whole chart scales 0 → 1 from center.
  scale,
}

/// Entry animation preset for network / force-directed graphs.
enum NetworkGraphAnimation {
  /// Force simulation runs to settle, nodes + edges fade in.
  settle,

  /// Whole graph fades in (positions pre-settled).
  fade,

  /// Nodes ripple in from center outward.
  ripple,
}

/// Layout for partition charts (treemap variants + icicle).
enum PartitionLayout {
  /// Squarified treemap — aspect-ratio aware tile packing.
  squarified,

  /// Slice-and-dice — alternates horizontal / vertical splits per
  /// depth level. Great for ordered hierarchies.
  sliceAndDice,

  /// Icicle (top-down) — root row across the top, children stack
  /// downward. Like a sunburst rolled flat.
  icicleTopDown,

  /// Icicle (left-right) — root column on the left, children
  /// stack rightward.
  icicleLeftRight,
}

/// Entry animation preset for partition charts.
enum PartitionAnimation {
  /// Each tile grows from its parent's edge.
  grow,

  /// Whole chart fades in.
  fade,

  /// Cells reveal depth-by-depth.
  cascade,
}

/// Entry animation preset for word clouds.
enum WordCloudAnimation {
  /// Words pop in by weight (heaviest first).
  pop,

  /// All words fade in together.
  fade,

  /// Words fly in from random offsets.
  fly,
}

/// Entry animation preset for renko / kagi / point-and-figure.
enum FinancialChartAnimation {
  /// Bricks / lines / columns reveal sequentially.
  sequential,

  /// Whole chart fades in.
  fade,
}

/// Entry animation preset for Gantt / swimlane.
enum GanttAnimation {
  /// Each bar draws left → right.
  draw,

  /// Whole chart fades in.
  fade,

  /// Rows reveal one after another (top → bottom).
  cascade,
}

/// Entry animation preset for QQ plots.
enum QQPlotAnimation {
  /// Reference line draws first, then dots pop in by quantile.
  sequential,

  /// All elements fade in together.
  fade,

  /// Dots scatter in from random offsets.
  scatter,
}

/// Entry animation preset for ECDF charts.
enum EcdfAnimation {
  /// Step function draws L→R.
  draw,

  /// Y-axis grows from 0 → 1.
  rise,

  /// Whole chart fades in.
  fade,
}

/// Entry animation preset for scorecard tiles.
enum ScorecardAnimation {
  /// Numeric value counts up; sparkline draws L→R after.
  countUp,

  /// Whole tile fades in.
  fade,

  /// Tile scales in from 0.8 → 1.0.
  pop,
}

/// Entry animation preset for calendar grids.
enum CalendarGridAnimation {
  /// Cells ripple in by date order (day-by-day).
  ripple,

  /// Cells fade in together with stagger by value.
  byValue,

  /// All cells fade in simultaneously.
  fade,
}

/// Entry animation preset for comparison matrix.
enum ComparisonMatrixAnimation {
  /// Each cell's sparkline draws L→R, staggered by row.
  draw,

  /// All cells fade in together.
  fade,

  /// Cells fill in cell-by-cell, row-major order.
  cascade,
}

/// Entry animation preset for fan charts.
enum FanAnimation { expand, draw, fade }

/// Entry animation preset for beeswarm charts.
enum BeeswarmAnimation { pop, fade, fall }

/// Entry animation preset for strip plots.
enum StripPlotAnimation { rise, fade, drift }

/// Entry animation preset for step-area charts.
enum StepAreaAnimation { draw, expand, fade }

/// Entry animation preset for marginal histogram.
enum MarginalHistogramAnimation { sequential, fade }

/// Entry animation preset for bump charts.
enum BumpAnimation { draw, ripple, fade }

/// Entry animation preset for spiral charts.
enum SpiralAnimation { draw, unwind, fade }

/// Entry animation preset for choropleth maps.
enum ChoroplethAnimation {
  /// All regions fade in together.
  fade,

  /// Regions fill in by value (lowest first → highest last).
  fillIn,

  /// Regions ripple in radially from the chart center.
  ripple,
}

/// Entry animation preset for bubble maps.
enum BubbleMapAnimation {
  /// Bubbles scale up in place, staggered by value (largest first).
  pop,

  /// All bubbles fade in together.
  fade,

  /// Bubbles ripple in radially from chart center.
  ripple,
}

/// Entry animation preset for flow maps.
enum FlowMapAnimation {
  /// Each arc draws from source → target.
  draw,

  /// Arcs fade in together with terminal dots.
  fade,

  /// Arcs draw, then animated pulse runs from source → target.
  pulse,
}

/// Entry animation preset for violin charts.
enum ViolinAnimation {
  /// Each violin grows horizontally outward from its centerline.
  spread,

  /// Each violin grows vertically from baseline to top.
  rise,

  /// Whole chart fades in.
  fade,
}

/// Entry animation preset for hexbin charts.
enum HexbinAnimation {
  /// Hex cells scale up in place, staggered by density.
  pop,

  /// Whole chart fades in.
  fade,
}

/// Entry animation preset for pictogram charts.
enum PictogramAnimation {
  /// Icons fill in left → right (or top → bottom for vertical).
  fillIn,

  /// All icons fade in together with stagger by index.
  fade,

  /// Icons scale up in place.
  pop,
}

/// Entry animation preset for dendrogram charts.
enum DendrogramAnimation {
  /// Branches grow from root outward to leaves.
  grow,

  /// Whole chart fades in.
  fade,

  /// Tree draws by stage (depth-by-depth reveal).
  cascade,
}

/// Entry animation preset for streamgraph charts.
enum StreamgraphAnimation {
  /// Bands grow vertically from the centerline outward.
  expand,

  /// Whole chart fades in.
  fade,

  /// Path draws left → right per band.
  draw,
}

/// Entry animation preset for ridgeline / joy-plot charts.
enum RidgelineAnimation {
  /// Each row's curve grows vertically from its baseline.
  rise,

  /// Path draws left → right.
  draw,

  /// Whole chart fades in.
  fade,
}

/// Entry animation preset for parallel-coordinates charts.
enum ParallelCoordinatesAnimation {
  /// Polylines draw left → right.
  draw,

  /// Each row fades in with stagger.
  fade,

  /// Polylines drop from above into place.
  drop,
}

/// Entry animation preset for chord diagrams.
enum ChordAnimation {
  /// Arcs draw clockwise, ribbons fade in after.
  sweep,

  /// Whole diagram fades in.
  fade,

  /// Whole diagram spins into place.
  spin,
}

/// Entry animation preset for Sankey diagrams.
enum SankeyAnimation {
  /// Everything fades in together. Default.
  fade,

  /// Links draw left → right, then nodes pop in.
  flow,

  /// Nodes fall in from above, links fade in after.
  drop,

  /// Stages animate one after another, left → right.
  wave,

  /// Nodes grow vertically from their center, links fade in last.
  grow,
}

/// Entry animation preset for sunburst charts.
enum SunburstAnimation {
  /// Rings fan out clockwise from 12 o'clock.
  sweep,

  /// Rings grow radially from the center outward.
  grow,

  /// Whole chart fades in.
  fade,

  /// Whole chart spins into place.
  spin,
}

/// Entry animation preset for lollipop charts.
enum LollipopAnimation {
  /// Stems extend from baseline to value, dots pop at the end.
  /// Default — feels physical.
  stretch,

  /// Dots travel from baseline to value (stems trail behind).
  rise,

  /// Whole chart fades in.
  fade,

  /// Stems and dots scale up in place.
  pop,
}

/// Entry animation preset for dumbbell charts.
enum DumbbellAnimation {
  /// Bar grows start → end, then dots pop.
  grow,

  /// Both dots fade in and the connector bar fades after.
  fade,

  /// Each row slides in from the leading edge.
  slide,
}

/// Polygon vs circular outline for radar charts.
enum RadarShape {
  /// Sharp polygon — straight lines between axis points.
  polygon,

  /// Smooth closed curve through axis points.
  circle,
}

/// Which side of an axis the title sits on.
///
/// - `start` for the x-axis = bottom; for the y-axis = left.
/// - `end` for the x-axis = top; for the y-axis = right.
enum AxisTitlePosition { start, end }

/// Title rendered alongside an axis (axis label / unit / caption).
/// Lives outside the data area — graphic-side tick labels are
/// untouched.
@immutable
class ChartAxisLabel {
  const ChartAxisLabel({
    required this.text,
    this.style,
    this.position = AxisTitlePosition.start,
    this.alignment = Alignment.center,
    this.padding = const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
    this.gap = 6,
  });

  final String text;

  /// When null, falls back to `Theme.textTheme.labelMedium` with
  /// `w600` weight + secondary text color.
  final TextStyle? style;

  /// Side of the axis the title sits on. Defaults to `start`
  /// (bottom for x-axis, left for y-axis).
  final AxisTitlePosition position;

  /// Anchoring of the text within its axis-side strip.
  final Alignment alignment;

  /// Padding inside the axis-title strip.
  final EdgeInsets padding;

  /// Gap between the axis-title strip and the chart body.
  final double gap;

  ChartAxisLabel copyWith({
    String? text,
    TextStyle? style,
    AxisTitlePosition? position,
    Alignment? alignment,
    EdgeInsets? padding,
    double? gap,
  }) {
    return ChartAxisLabel(
      text: text ?? this.text,
      style: style ?? this.style,
      position: position ?? this.position,
      alignment: alignment ?? this.alignment,
      padding: padding ?? this.padding,
      gap: gap ?? this.gap,
    );
  }
}

// ═══════════════════════════════════════════════════════════
// Style
// ═══════════════════════════════════════════════════════════

/// Universal chart style — every `Global*Chart` accepts this. Use
/// presets ([ChartStyle.minimal], [ChartStyle.standard],
/// [ChartStyle.detailed]) and `copyWith` to tweak per-call.
@immutable
class ChartStyle {
  const ChartStyle({
    this.density = ChartDensity.standard,
    this.legendPosition = ChartLegendPosition.bottom,
    this.aspectRatio = kChartDefaultAspectRatio,
    this.minHeight = kChartDefaultMinHeight,
    this.maxWidth,
    this.padding = kChartDefaultPadding,
    this.enableAnimation = true,
    this.animationDuration,
    this.animationCurve,
    this.enableTooltip = true,
    this.enableCrosshair = true,
    this.enableZoom = false,
    this.showGrid,
    this.showAxisLabels,
    this.showLegend,
    this.gridColor,
    this.axisLabelStyle,
    this.tooltipBackgroundColor,
    this.tooltipTextStyle,
    this.numberFormatter,
    this.seriesColors,
    this.tooltipBuilder,
    this.enableAxisShadow = false,
    this.axisShadowColor,
    this.axisShadowHighlightColor,
    this.axisShadowBlur = 8,
    this.axisShadowInset = const EdgeInsetsDirectional.fromSTEB(40, 4, 8, 20),
    this.axisShadowCornerRadius = 4,
  });

  // ─── Layout ────────────────────────────────────────────────

  final ChartDensity density;
  final ChartLegendPosition legendPosition;
  final double aspectRatio;
  final double minHeight;

  /// Optional max width override. When null, the chart caps its width
  /// per `WindowSizeClass` bucket (compact: full, expanded: 720,
  /// large: 880, extraLarge: 1000) so it doesn't sprawl across wide
  /// screens. Set to `double.infinity` to opt out of the cap.
  final double? maxWidth;

  final EdgeInsetsGeometry padding;

  // ─── Animation ─────────────────────────────────────────────

  final bool enableAnimation;
  final Duration? animationDuration;
  final Curve? animationCurve;

  // ─── Interaction ───────────────────────────────────────────

  final bool enableTooltip;
  final bool enableCrosshair;

  /// Pinch-to-zoom on the data area. Off by default — opt-in per
  /// chart since it conflicts with parent scroll views.
  final bool enableZoom;

  // ─── Visibility overrides (override [density] defaults) ────

  final bool? showGrid;
  final bool? showAxisLabels;
  final bool? showLegend;

  // ─── Colors / typography ───────────────────────────────────

  final Color? gridColor;
  final TextStyle? axisLabelStyle;
  final Color? tooltipBackgroundColor;
  final TextStyle? tooltipTextStyle;

  /// Format the numeric value shown in tooltips + axis labels. Falls
  /// back to a locale-aware compact formatter (`AppNumbers.compact`).
  final String Function(num value)? numberFormatter;

  /// Override the auto-rotated palette (which pulls from
  /// `context.primaryColors` / `statusColors`). Pass an explicit list
  /// for brand colors / fixed series identity.
  final List<Color>? seriesColors;

  /// Custom tooltip builder. When set, the chart wraps in a
  /// `ChartTooltipOverlay` and disables graphic's built-in canvas
  /// tooltip. Receives the `BuildContext` + selected `TooltipEntry`s
  /// (label / value / color / icon). Use for rich tooltips with
  /// icons, images, badges, or custom layouts.
  final ChartTooltipBuilder? tooltipBuilder;

  // ─── Axis shadow ───────────────────────────────────────────

  /// Paint a soft drop shadow behind the X- and Y-axis lines so they
  /// appear elevated above the plot area. Off by default.
  final bool enableAxisShadow;

  /// Axis shadow color. Falls back to
  /// `Colors.black.withValues(alpha: 0.4)`.
  final Color? axisShadowColor;

  /// Bevel highlight color — paints a subtle light line on the
  /// opposite side of each axis so the line reads as raised, not
  /// just shadowed. Falls back to `Colors.white.withValues(alpha: 0.6)`.
  /// Pass `Colors.transparent` to disable.
  final Color? axisShadowHighlightColor;

  /// Axis shadow blur radius (Gaussian) — also controls how far the
  /// inner shadow penetrates into the plot area.
  final double axisShadowBlur;

  /// Insets the plot rectangle from the chart edges. Drives where
  /// the synthetic axis shadow strips are painted (graphic doesn't
  /// expose axis positions — these are hand-tuned to match the
  /// default left-axis + bottom-axis layout).
  final EdgeInsetsDirectional axisShadowInset;

  /// Corner radius applied at the L-corner where the X- and Y-axis
  /// shadow strips meet — smooths the join.
  final double axisShadowCornerRadius;

  // ─── Resolved getters (apply density defaults) ────────────

  bool get effectiveShowGrid => showGrid ?? density != ChartDensity.minimal;
  bool get effectiveShowAxisLabels =>
      showAxisLabels ?? density != ChartDensity.minimal;
  bool get effectiveShowLegend =>
      showLegend ??
      (legendPosition != ChartLegendPosition.hidden &&
          density != ChartDensity.minimal);
  Duration get effectiveAnimationDuration =>
      animationDuration ?? _kChartDefaultAnimationDuration;
  Curve get effectiveAnimationCurve => animationCurve ?? Curves.easeOutCubic;

  // ─── Presets ───────────────────────────────────────────────

  /// Bare minimum — just the series. Card embeds, sparkline-style.
  static const ChartStyle minimal = ChartStyle(
    density: ChartDensity.minimal,
    legendPosition: ChartLegendPosition.hidden,
  );

  /// Default — grid + axes + legend.
  static const ChartStyle standard = ChartStyle();

  /// Heavy — extra grid lines, tick marks, value labels.
  static const ChartStyle detailed = ChartStyle(density: ChartDensity.detailed);

  ChartStyle copyWith({
    ChartDensity? density,
    ChartLegendPosition? legendPosition,
    double? aspectRatio,
    double? minHeight,
    double? maxWidth,
    EdgeInsetsGeometry? padding,
    bool? enableAnimation,
    Duration? animationDuration,
    Curve? animationCurve,
    bool? enableTooltip,
    bool? enableCrosshair,
    bool? enableZoom,
    bool? showGrid,
    bool? showAxisLabels,
    bool? showLegend,
    Color? gridColor,
    TextStyle? axisLabelStyle,
    Color? tooltipBackgroundColor,
    TextStyle? tooltipTextStyle,
    String Function(num value)? numberFormatter,
    List<Color>? seriesColors,
    ChartTooltipBuilder? tooltipBuilder,
    bool? enableAxisShadow,
    Color? axisShadowColor,
    Color? axisShadowHighlightColor,
    double? axisShadowBlur,
    EdgeInsetsDirectional? axisShadowInset,
    double? axisShadowCornerRadius,
  }) {
    return ChartStyle(
      density: density ?? this.density,
      legendPosition: legendPosition ?? this.legendPosition,
      aspectRatio: aspectRatio ?? this.aspectRatio,
      minHeight: minHeight ?? this.minHeight,
      maxWidth: maxWidth ?? this.maxWidth,
      padding: padding ?? this.padding,
      enableAnimation: enableAnimation ?? this.enableAnimation,
      animationDuration: animationDuration ?? this.animationDuration,
      animationCurve: animationCurve ?? this.animationCurve,
      enableTooltip: enableTooltip ?? this.enableTooltip,
      enableCrosshair: enableCrosshair ?? this.enableCrosshair,
      enableZoom: enableZoom ?? this.enableZoom,
      showGrid: showGrid ?? this.showGrid,
      showAxisLabels: showAxisLabels ?? this.showAxisLabels,
      showLegend: showLegend ?? this.showLegend,
      gridColor: gridColor ?? this.gridColor,
      axisLabelStyle: axisLabelStyle ?? this.axisLabelStyle,
      tooltipBackgroundColor:
          tooltipBackgroundColor ?? this.tooltipBackgroundColor,
      tooltipTextStyle: tooltipTextStyle ?? this.tooltipTextStyle,
      numberFormatter: numberFormatter ?? this.numberFormatter,
      seriesColors: seriesColors ?? this.seriesColors,
      tooltipBuilder: tooltipBuilder ?? this.tooltipBuilder,
      enableAxisShadow: enableAxisShadow ?? this.enableAxisShadow,
      axisShadowColor: axisShadowColor ?? this.axisShadowColor,
      axisShadowHighlightColor:
          axisShadowHighlightColor ?? this.axisShadowHighlightColor,
      axisShadowBlur: axisShadowBlur ?? this.axisShadowBlur,
      axisShadowInset: axisShadowInset ?? this.axisShadowInset,
      axisShadowCornerRadius:
          axisShadowCornerRadius ?? this.axisShadowCornerRadius,
    );
  }
}
