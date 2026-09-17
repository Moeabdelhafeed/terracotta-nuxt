import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';
import 'package:flutter/widgets.dart' show IconData, Widget;

// ═══════════════════════════════════════════════════════════
// ChartPoint — single (x, y) datum
// ═══════════════════════════════════════════════════════════

/// One data point. `x` is typically an index, timestamp, or category
/// position; `y` is the measured value. [label] is optional metadata
/// surfaced in tooltips / legends.
@immutable
class ChartPoint {
  const ChartPoint(this.x, this.y, {this.label});

  final double x;
  final double y;
  final String? label;
}

// ═══════════════════════════════════════════════════════════
// ChartSeries — named series for multi-line / multi-bar charts
// ═══════════════════════════════════════════════════════════

/// Named series — used by line / bar / scatter charts that support
/// multiple overlapping or grouped series. The widget auto-rotates
/// palette colors when [color] is null.
@immutable
class ChartSeries {
  const ChartSeries({
    required this.name,
    required this.points,
    this.color,
    this.fillColor,
    this.lineGradient,
    this.fillGradient,
    this.pointGradient,
    this.dashed = false,
    this.icon,
    this.iconAsset,
    this.iconWidget,
  });

  final String name;
  final List<ChartPoint> points;

  /// Override the auto-rotated palette color for this series.
  final Color? color;

  /// Optional fill (line area, bar fill on hover). Defaults to
  /// `color.withValues(alpha: 0.18)` when null.
  final Color? fillColor;

  /// Apply a [Gradient] to the line stroke (line / area charts).
  /// When set, takes precedence over [color] for the line. Use a
  /// `LinearGradient` for left-to-right tints, or `RadialGradient`
  /// for spotlight effects. Stops/coords are relative to the mark
  /// item's bounding box.
  final Gradient? lineGradient;

  /// Apply a [Gradient] to the area fill (line charts with
  /// `filled: true`). Independent of [lineGradient] — set both for
  /// matched line + fill, or just one to mix gradient line over a
  /// flat fill.
  final Gradient? fillGradient;

  /// Apply a [Gradient] to scatter dots. `RadialGradient` gives a
  /// pearl / orb look. Wins over [color] for scatter only.
  final Gradient? pointGradient;

  /// Render the line dashed (line/area charts only — bar charts
  /// ignore this).
  final bool dashed;

  /// Optional Material icon shown next to the series name in the
  /// legend. Tinted with [color] (or palette default) unless
  /// [iconWidget] overrides.
  final IconData? icon;

  /// Optional asset path (PNG/JPG) shown in legend instead of the
  /// color swatch.
  final String? iconAsset;

  /// Custom legend icon — wins over [icon] / [iconAsset]. Use for
  /// SVGs, network images, custom shapes.
  final Widget? iconWidget;
}

// ═══════════════════════════════════════════════════════════
// PieSlice — wedge for pie / donut charts
// ═══════════════════════════════════════════════════════════

/// One wedge of a pie / donut. [value] drives the angle; the chart
/// computes percentages by summing all slices.
@immutable
class PieSlice {
  const PieSlice({
    required this.label,
    required this.value,
    this.color,
    this.gradient,
    this.icon,
    this.iconAsset,
    this.iconWidget,
  });

  final String label;
  final double value;
  final Color? color;

  /// Apply a [Gradient] to this slice. Wins over [color]. graphic
  /// forbids both color + gradient on a mark, so when ANY slice
  /// supplies a gradient, the chart switches to gradient encoding
  /// for all slices (others auto-synthesize from their color).
  final Gradient? gradient;

  /// Optional legend icon. See [ChartSeries.icon].
  final IconData? icon;
  final String? iconAsset;
  final Widget? iconWidget;
}

// ═══════════════════════════════════════════════════════════
// BubblePoint — (x, y, size) datum for bubble charts
// ═══════════════════════════════════════════════════════════

/// One bubble — `x`/`y` is position, `size` drives the rendered radius
/// (mapped to a pixel range by the widget). [label] surfaces in the
/// tooltip.
@immutable
class BubblePoint {
  const BubblePoint({
    required this.x,
    required this.y,
    required this.size,
    this.label,
    this.color,
    this.gradient,
  });

  final double x;
  final double y;
  final double size;
  final String? label;
  final Color? color;

  /// Apply a [Gradient] to this bubble. Wins over [color]. graphic
  /// forbids both color + gradient on a mark, so when ANY bubble
  /// supplies a gradient, all bubbles switch to gradient encoding
  /// (others auto-synthesize from their color).
  final Gradient? gradient;
}

// ═══════════════════════════════════════════════════════════
// RadarSeries — one closed polygon on a radar chart
// ═══════════════════════════════════════════════════════════

/// One overlay on a radar chart. Every series in a chart should have
/// the same [values] length — that count drives the polygon's vertices
/// (and the per-axis labels).
@immutable
class RadarSeries {
  const RadarSeries({
    required this.name,
    required this.values,
    this.color,
    this.fillColor,
    this.lineGradient,
    this.fillGradient,
    this.icon,
    this.iconAsset,
    this.iconWidget,
  });

  final String name;
  final List<double> values;
  final Color? color;
  final Color? fillColor;

  /// Apply a [Gradient] to the radar polygon's outline. Wins over
  /// [color] for the line. graphic forbids both color + gradient on
  /// a mark, so when ANY series supplies a lineGradient, all series
  /// switch to gradient encoding.
  final Gradient? lineGradient;

  /// Apply a [Gradient] to the polygon's filled area. Independent
  /// of [lineGradient].
  final Gradient? fillGradient;

  /// Optional legend icon. See [ChartSeries.icon].
  final IconData? icon;
  final String? iconAsset;
  final Widget? iconWidget;
}

// ═══════════════════════════════════════════════════════════
// BarGroup — one cluster on a bar chart x-axis
// ═══════════════════════════════════════════════════════════

/// One x-axis category in a bar chart. [bars] holds one entry per
/// series in that group — all groups should have the same length when
/// rendering grouped/stacked layouts.
@immutable
class BarGroup {
  const BarGroup({
    required this.label,
    required this.bars,
  });

  final String label;
  final List<double> bars;
}

// ═══════════════════════════════════════════════════════════
// HeatmapCell — one cell in a 2D heatmap
// ═══════════════════════════════════════════════════════════

/// One cell of a heatmap grid. [x] / [y] are categorical labels (e.g.
/// weekday × hour) and [value] drives the cell color.
@immutable
class HeatmapCell {
  const HeatmapCell({
    required this.x,
    required this.y,
    required this.value,
    this.label,
  });

  final String x;
  final String y;
  final double value;

  /// Optional tooltip override. Falls back to `'(x, y) · value'`.
  final String? label;
}

// ═══════════════════════════════════════════════════════════
// FunnelStage — one band of a funnel chart
// ═══════════════════════════════════════════════════════════

/// One stage of a funnel chart. [value] drives the band's width;
/// the chart renders stages stacked vertically with each band's
/// width proportional to its [value].
@immutable
class FunnelStage {
  const FunnelStage({
    required this.label,
    required this.value,
    this.color,
    this.gradient,
    this.icon,
    this.iconAsset,
    this.iconWidget,
  });

  final String label;
  final double value;
  final Color? color;
  final Gradient? gradient;
  final IconData? icon;
  final String? iconAsset;
  final Widget? iconWidget;
}

// ═══════════════════════════════════════════════════════════
// Candle — OHLC datum for candlestick charts
// ═══════════════════════════════════════════════════════════

// ═══════════════════════════════════════════════════════════
// BulletDatum — bullet chart row (KPI + target + ranges)
// ═══════════════════════════════════════════════════════════

/// One row of a bullet chart — actual measure, target marker, and
/// qualitative ranges (poor / ok / good bands).
@immutable
class BulletDatum {
  const BulletDatum({
    required this.label,
    required this.value,
    required this.target,
    required this.ranges,
    this.comparative,
    this.unit = '',
    this.color,
  });

  final String label;

  /// The actual measure (rendered as the foreground bar).
  final double value;

  /// Target marker — a vertical tick across the bar.
  final double target;

  /// Cumulative thresholds defining the qualitative bands. Should
  /// be ascending (e.g. `[60, 80, 100]` = poor 0–60, ok 60–80,
  /// good 80–100). The last entry is the row's max.
  final List<double> ranges;

  /// Optional second-tick comparison value (e.g. previous period).
  final double? comparative;

  final String unit;

  /// Foreground bar color. Falls back to theme primary.
  final Color? color;
}

// ═══════════════════════════════════════════════════════════
// HistogramBin — pre-computed bin of continuous data
// ═══════════════════════════════════════════════════════════

/// One bin in a histogram. `[start, end)` defines the value range,
/// `count` is the number of observations in the range.
@immutable
class HistogramBin {
  const HistogramBin({
    required this.start,
    required this.end,
    required this.count,
  });

  final double start;
  final double end;
  final int count;
}

// ═══════════════════════════════════════════════════════════
// WaterfallStep — one increment in a waterfall chart
// ═══════════════════════════════════════════════════════════

/// Waterfall step type — drives bar color and offset behavior.
enum WaterfallType {
  /// Adds to the running total. Tinted green by default.
  positive,

  /// Subtracts from the running total. Tinted red by default.
  negative,

  /// Rendered as a fixed-baseline bar (start / subtotal / end).
  /// Tinted blue by default.
  total,
}

/// One step in a waterfall chart. [WaterfallType] drives the visual
/// (positive bars stack up, negative bars stack down, totals reset
/// to the baseline).
@immutable
class WaterfallStep {
  const WaterfallStep({
    required this.label,
    required this.value,
    this.type = WaterfallType.positive,
    this.color,
  });

  final String label;
  final double value;
  final WaterfallType type;
  final Color? color;
}

// ═══════════════════════════════════════════════════════════
// CalendarCell — date-grid heatmap datum
// ═══════════════════════════════════════════════════════════

/// One cell in a calendar heatmap. [date] is positioned on the grid
/// (week column × weekday row), [value] drives color.
@immutable
class CalendarCell {
  const CalendarCell({
    required this.date,
    required this.value,
    this.label,
  });

  final DateTime date;
  final double value;

  /// Optional tooltip override. Falls back to formatted date · value.
  final String? label;
}

// ═══════════════════════════════════════════════════════════
// BoxPlotDatum — five-number summary per category
// ═══════════════════════════════════════════════════════════

/// Five-number summary for a box plot category. Either provide the
/// stats directly or use [BoxPlotDatum.fromValues] to compute them
/// from raw observations.
@immutable
class BoxPlotDatum {
  const BoxPlotDatum({
    required this.label,
    required this.min,
    required this.q1,
    required this.median,
    required this.q3,
    required this.max,
    this.outliers = const [],
    this.color,
  });

  /// Compute quartiles from raw observations.
  factory BoxPlotDatum.fromValues({
    required String label,
    required List<double> values,
    Color? color,
    bool detectOutliers = true,
  }) {
    assert(values.isNotEmpty, 'values cannot be empty');
    final sorted = [...values]..sort();
    double quantile(double q) {
      final pos = (sorted.length - 1) * q;
      final lo = pos.floor();
      final hi = pos.ceil();
      if (lo == hi) return sorted[lo];
      return sorted[lo] + (sorted[hi] - sorted[lo]) * (pos - lo);
    }

    final q1 = quantile(0.25);
    final med = quantile(0.5);
    final q3 = quantile(0.75);
    final iqr = q3 - q1;
    final lowFence = q1 - 1.5 * iqr;
    final highFence = q3 + 1.5 * iqr;

    final outliers = <double>[];
    var minIn = sorted.first;
    var maxIn = sorted.last;
    if (detectOutliers) {
      minIn = double.infinity;
      maxIn = double.negativeInfinity;
      for (final v in sorted) {
        if (v < lowFence || v > highFence) {
          outliers.add(v);
        } else {
          if (v < minIn) minIn = v;
          if (v > maxIn) maxIn = v;
        }
      }
      if (minIn == double.infinity) minIn = sorted.first;
      if (maxIn == double.negativeInfinity) maxIn = sorted.last;
    }

    return BoxPlotDatum(
      label: label,
      min: minIn,
      q1: q1,
      median: med,
      q3: q3,
      max: maxIn,
      outliers: outliers,
      color: color,
    );
  }

  final String label;
  final double min;
  final double q1;
  final double median;
  final double q3;
  final double max;
  final List<double> outliers;
  final Color? color;
}

// ═══════════════════════════════════════════════════════════
// TreemapNode — flat or hierarchical proportion
// ═══════════════════════════════════════════════════════════

/// Node in a treemap. `value` drives the rectangle's area.
/// Nested [children] enable hierarchical (folder-style) treemaps;
/// when set, [value] is ignored — the parent's area is the sum of
/// its children's values.
@immutable
class TreemapNode {
  const TreemapNode({
    required this.label,
    this.value = 0,
    this.color,
    this.children = const [],
  });

  final String label;
  final double value;
  final Color? color;
  final List<TreemapNode> children;

  /// Effective value — sum of children's values when grouped, else
  /// [value] for leaves.
  double get totalValue {
    if (children.isEmpty) return value;
    return children.fold(0, (sum, c) => sum + c.totalValue);
  }
}

// ═══════════════════════════════════════════════════════════
// SlopeDatum — two-point change for slope charts
// ═══════════════════════════════════════════════════════════

/// One row of a slope chart — a single category's value at two
/// time points (`before` → `after`). The chart draws a line per
/// row connecting the two columns.
@immutable
class SlopeDatum {
  const SlopeDatum({
    required this.label,
    required this.before,
    required this.after,
    this.color,
    this.icon,
    this.iconAsset,
    this.iconWidget,
  });

  final String label;
  final double before;
  final double after;
  final Color? color;
  final IconData? icon;
  final String? iconAsset;
  final Widget? iconWidget;

  double get delta => after - before;
}

// ═══════════════════════════════════════════════════════════
// PolarSlice — wedge for polar-area / Coxcomb charts
// ═══════════════════════════════════════════════════════════

/// One wedge of a polar-area chart. Every wedge spans the same
/// angular slice (`2π / N`); [value] drives the radial length —
/// all wedges share their center on the chart and grow outward.
@immutable
class PolarSlice {
  const PolarSlice({
    required this.label,
    required this.value,
    this.color,
    this.gradient,
  });

  final String label;
  final double value;
  final Color? color;
  final Gradient? gradient;
}

// ═══════════════════════════════════════════════════════════
// BandPoint — confidence interval / area band
// ═══════════════════════════════════════════════════════════

/// One point in an area band — `x` is the position, `low` / `high`
/// are the band's vertical extents at that x. [mid] is optional
/// (e.g. the central trend / forecast median).
@immutable
class BandPoint {
  const BandPoint({
    required this.x,
    required this.low,
    required this.high,
    this.mid,
  });

  final double x;
  final double low;
  final double high;
  final double? mid;
}

// ═══════════════════════════════════════════════════════════
// MarimekkoColumn / MarimekkoSegment — variable-width stacked bar
// ═══════════════════════════════════════════════════════════

/// One column of a Marimekko chart. The column's width is
/// proportional to the sum of its segment values; each segment's
/// height is proportional to its share within that column.
@immutable
class MarimekkoColumn {
  const MarimekkoColumn({
    required this.label,
    required this.segments,
  });

  final String label;
  final List<MarimekkoSegment> segments;

  double get total => segments.fold<double>(0, (sum, s) => sum + s.value);
}

@immutable
class MarimekkoSegment {
  const MarimekkoSegment({
    required this.label,
    required this.value,
    this.color,
    this.gradient,
  });

  final String label;
  final double value;
  final Color? color;
  final Gradient? gradient;
}

/// One candle in a candlestick / OHLC chart.
/// - [open] / [close] are the body's vertical extents.
/// - [high] / [low] are the wicks.
/// - [time] is the x-coordinate (typically a millisecond timestamp).
@immutable
class Candle {
  const Candle({
    required this.time,
    required this.open,
    required this.high,
    required this.low,
    required this.close,
  });

  final double time;
  final double open;
  final double high;
  final double low;
  final double close;

  bool get isBullish => close >= open;
}

// ═══════════════════════════════════════════════════════════
// SankeyNode / SankeyLink — flow diagram
// ═══════════════════════════════════════════════════════════

/// One node in a Sankey diagram. [stage] places the node in a
/// vertical column; nodes within the same stage stack on the
/// y-axis, sized by their throughput (sum of incoming or outgoing
/// link values, whichever is larger).
@immutable
class SankeyNode {
  const SankeyNode({
    required this.id,
    required this.label,
    required this.stage,
    this.color,
    this.icon,
    this.iconAsset,
    this.iconWidget,
  });

  final String id;
  final String label;
  final int stage;
  final Color? color;
  final IconData? icon;
  final String? iconAsset;
  final Widget? iconWidget;
}

/// A weighted flow between two Sankey nodes. The link's thickness
/// is proportional to [value]. [source]/[target] reference node
/// ids; [color] overrides the auto-derived gradient.
@immutable
class SankeyLink {
  const SankeyLink({
    required this.source,
    required this.target,
    required this.value,
    this.color,
  });

  final String source;
  final String target;
  final double value;
  final Color? color;
}

// ═══════════════════════════════════════════════════════════
// LollipopDatum — bar+dot single-value entry
// ═══════════════════════════════════════════════════════════

/// One row of a lollipop chart — a thin stem from baseline to a
/// dot at the value. Sparser visual than bars; great for ranked
/// lists where values cluster narrowly.
@immutable
class LollipopDatum {
  const LollipopDatum({
    required this.label,
    required this.value,
    this.color,
    this.icon,
    this.iconAsset,
    this.iconWidget,
  });

  final String label;
  final double value;
  final Color? color;
  final IconData? icon;
  final String? iconAsset;
  final Widget? iconWidget;
}

// ═══════════════════════════════════════════════════════════
// DumbbellDatum — paired-dots before/after row
// ═══════════════════════════════════════════════════════════

/// One row of a dumbbell chart — two dots connected by a bar,
/// representing a value at two states (before/after, min/max,
/// male/female, etc.) for the same category.
@immutable
class DumbbellDatum {
  const DumbbellDatum({
    required this.label,
    required this.start,
    required this.end,
    this.startColor,
    this.endColor,
    this.icon,
    this.iconAsset,
    this.iconWidget,
  });

  final String label;
  final double start;
  final double end;
  final Color? startColor;
  final Color? endColor;
  final IconData? icon;
  final String? iconAsset;
  final Widget? iconWidget;

  double get delta => end - start;
}

// ═══════════════════════════════════════════════════════════
// ParallelAxis / ParallelRow — parallel coordinates
// ═══════════════════════════════════════════════════════════

/// One vertical axis in a parallel-coordinates chart. [min] / [max]
/// drive the axis's pixel mapping; if null, the chart auto-fits to
/// the data on that key.
@immutable
class ParallelAxis {
  const ParallelAxis({
    required this.key,
    required this.label,
    this.min,
    this.max,
    this.formatter,
  });

  final String key;
  final String label;
  final double? min;
  final double? max;
  final String Function(double)? formatter;
}

/// One row in a parallel-coordinates chart. Each row draws as a
/// polyline crossing every axis at `values[axisKey]`. [color]
/// overrides the auto palette; [group] enables coloring by group
/// label instead of per-row palette rotation.
@immutable
class ParallelRow {
  const ParallelRow({
    required this.label,
    required this.values,
    this.color,
    this.group,
  });

  final String label;
  final Map<String, double> values;
  final Color? color;
  final String? group;
}

// ═══════════════════════════════════════════════════════════
// ChordFlow — circular flow matrix
// ═══════════════════════════════════════════════════════════

/// One directed flow between two chord-diagram entities. Flow
/// thickness is proportional to [value]. Source and target both
/// reference [ChordEntity.id].
@immutable
class ChordFlow {
  const ChordFlow({
    required this.source,
    required this.target,
    required this.value,
    this.color,
  });

  final String source;
  final String target;
  final double value;
  final Color? color;
}

/// One entity around the chord-diagram ring.
@immutable
class ChordEntity {
  const ChordEntity({
    required this.id,
    required this.label,
    this.color,
  });

  final String id;
  final String label;
  final Color? color;
}

// ═══════════════════════════════════════════════════════════
// ViolinDatum — distribution per category
// ═══════════════════════════════════════════════════════════

/// One category in a violin chart. [values] is the raw sample —
/// the chart computes a kernel-density estimate to draw the
/// mirrored shape. Optional [median] / [q1] / [q3] override the
/// computed quartile box; if null the chart calculates them.
@immutable
class ViolinDatum {
  const ViolinDatum({
    required this.label,
    required this.values,
    this.color,
    this.median,
    this.q1,
    this.q3,
  });

  final String label;
  final List<double> values;
  final Color? color;
  final double? median;
  final double? q1;
  final double? q3;
}

// ═══════════════════════════════════════════════════════════
// HexPoint — single observation for hexbin density
// ═══════════════════════════════════════════════════════════

/// One observation in a hexbin chart — `(x, y)` is the position;
/// [weight] lets you pre-aggregate dense data (default 1 per
/// observation).
@immutable
class HexPoint {
  const HexPoint(this.x, this.y, {this.weight = 1});

  final double x;
  final double y;
  final double weight;
}

// ═══════════════════════════════════════════════════════════
// PictogramDatum — icon-array proportion entry
// ═══════════════════════════════════════════════════════════

/// One row of a pictogram chart — value drives the icon count.
/// Multiple rows render as side-by-side icon arrays for category
/// comparison.
@immutable
class PictogramDatum {
  const PictogramDatum({
    required this.label,
    required this.value,
    this.icon,
    this.color,
  });

  final String label;
  final double value;
  final IconData? icon;
  final Color? color;
}

// ═══════════════════════════════════════════════════════════
// MapRegion / MapPoint / MapFlow — geographic charts
// ═══════════════════════════════════════════════════════════

/// One region polygon for choropleth / map backdrops. [polygons]
/// is a list of outer rings; each ring is a closed list of points
/// in the chart's coordinate space (pre-projected — the chart
/// auto-fits to the union bounds across all regions).
@immutable
class MapRegion {
  const MapRegion({
    required this.id,
    required this.label,
    required this.polygons,
    this.value = 0,
    this.color,
  });

  final String id;
  final String label;
  final List<List<Offset>> polygons;
  final double value;
  final Color? color;
}

/// One marker / bubble on a map. [position] uses the same
/// coordinate space as the surrounding regions.
@immutable
class MapPoint {
  const MapPoint({
    required this.label,
    required this.position,
    required this.value,
    this.color,
    this.icon,
  });

  final String label;
  final Offset position;
  final double value;
  final Color? color;
  final IconData? icon;
}

/// Directed flow between two map positions — drawn as a bezier
/// arc with thickness proportional to [value].
@immutable
class MapFlow {
  const MapFlow({
    required this.label,
    required this.from,
    required this.to,
    required this.value,
    this.color,
  });

  final String label;
  final Offset from;
  final Offset to;
  final double value;
  final Color? color;
}

// ═══════════════════════════════════════════════════════════
// FanBand / FanForecast — confidence bands for fan charts
// ═══════════════════════════════════════════════════════════

/// One confidence band layer in a fan chart. [points] is a list of
/// `(x, lo, hi)` per time step. Multiple bands stack — narrower
/// (e.g. 50%) drawn over wider (e.g. 95%) for the classic fan look.
@immutable
class FanBand {
  const FanBand({
    required this.label,
    required this.points,
    this.color,
    this.opacity = 0.25,
  });

  final String label;
  final List<BandPoint> points;
  final Color? color;
  final double opacity;
}

// ═══════════════════════════════════════════════════════════
// BumpRow — rank-over-time series for bump charts
// ═══════════════════════════════════════════════════════════

/// One row in a bump chart — a single contender's value at each
/// time slot. The chart computes ranks per time-slot so callers
/// can pass raw values; [color] / [icon] follow the same palette
/// rotation as other series.
@immutable
class BumpRow {
  const BumpRow({
    required this.label,
    required this.points,
    this.color,
    this.icon,
    this.iconAsset,
    this.iconWidget,
  });

  final String label;
  final List<ChartPoint> points;
  final Color? color;
  final IconData? icon;
  final String? iconAsset;
  final Widget? iconWidget;
}

// ═══════════════════════════════════════════════════════════
// ScorecardEntry — KPI tile with sparkline
// ═══════════════════════════════════════════════════════════

/// One scorecard tile — big primary value + small comparison and
/// trend sparkline. Render multiple in a grid for KPI dashboards.
@immutable
class ScorecardEntry {
  const ScorecardEntry({
    required this.label,
    required this.value,
    this.formattedValue,
    this.delta,
    this.deltaSuffix = '',
    this.sparkline = const [],
    this.icon,
    this.color,
    this.subtitle,
    this.unit = '',
  });

  final String label;
  final double value;

  /// Override the formatted display string. When null, the chart
  /// formats `value` via the standard number formatter.
  final String? formattedValue;

  /// Optional change vs comparison period. Sign drives the trend
  /// arrow + tint (green / red / neutral).
  final double? delta;

  /// Trailing string for the delta (e.g. `'%'`, `' wow'`).
  final String deltaSuffix;

  final List<ChartPoint> sparkline;
  final IconData? icon;
  final Color? color;
  final String? subtitle;
  final String unit;
}

// ═══════════════════════════════════════════════════════════
// MatrixCell — comparison matrix small-multiples
// ═══════════════════════════════════════════════════════════

/// One cell in a comparison matrix — defines which (row, col) it
/// occupies and the sparkline-style data to render.
@immutable
class MatrixCell {
  const MatrixCell({
    required this.row,
    required this.col,
    required this.sparkline,
    this.value,
    this.delta,
    this.color,
  });

  final String row;
  final String col;
  final List<ChartPoint> sparkline;

  /// Optional summary number to display alongside the sparkline.
  final double? value;

  /// Optional change number — drives the trend tint.
  final double? delta;

  final Color? color;
}

// ═══════════════════════════════════════════════════════════
// GraphNode / GraphEdge — network / force-directed graph
// ═══════════════════════════════════════════════════════════

/// One node in a network graph. [value] drives the node's radius;
/// [group] enables coloring by community.
@immutable
class GraphNode {
  const GraphNode({
    required this.id,
    required this.label,
    this.value = 1,
    this.group,
    this.color,
  });

  final String id;
  final String label;
  final double value;
  final String? group;
  final Color? color;
}

/// Edge between two graph nodes. [weight] influences edge thickness
/// + spring length (heavier weight pulls nodes closer).
@immutable
class GraphEdge {
  const GraphEdge({
    required this.source,
    required this.target,
    this.weight = 1,
    this.color,
  });

  final String source;
  final String target;
  final double weight;
  final Color? color;
}

// ═══════════════════════════════════════════════════════════
// WordCloudWord — single word for word-cloud chart
// ═══════════════════════════════════════════════════════════

/// One word in a word cloud. Font size is interpolated from
/// `weight` against the cloud's min/max weight range.
@immutable
class WordCloudWord {
  const WordCloudWord({
    required this.text,
    required this.weight,
    this.color,
  });

  final String text;
  final double weight;
  final Color? color;
}

// ═══════════════════════════════════════════════════════════
// GanttTask — Gantt / swimlane time-bar entry
// ═══════════════════════════════════════════════════════════

/// One task in a Gantt / swimlane chart. [start] / [end] are
/// numeric x-coords (e.g. day index, timestamp). [lane] groups
/// tasks into horizontal swim lanes; null means default lane.
@immutable
class GanttTask {
  const GanttTask({
    required this.id,
    required this.label,
    required this.start,
    required this.end,
    this.lane,
    this.progress = 0,
    this.color,
    this.dependencies = const [],
  });

  final String id;
  final String label;
  final double start;
  final double end;
  final String? lane;

  /// 0..1 fraction completed — drives the inner progress bar.
  final double progress;

  final Color? color;

  /// IDs of tasks this task depends on (for dependency arrows).
  final List<String> dependencies;
}
