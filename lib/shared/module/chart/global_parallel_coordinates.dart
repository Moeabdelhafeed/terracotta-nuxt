import 'package:flutter/material.dart';

import '../../../core/extensions/theme_colors_extension.dart';
import '../../../core/localization/number_formatter.dart';
import 'chart_data.dart';
import 'chart_internals.dart';
import 'chart_models.dart';
import 'chart_tooltip_overlay.dart';
import 'custom_paint_tooltip.dart';

export 'chart_data.dart' show ParallelAxis, ParallelRow;
export 'chart_models.dart' show ChartStyle, ParallelCoordinatesAnimation;

/// Parallel-coordinates chart — N vertical axes, one polyline per
/// row crossing every axis at `row.values[axis.key]`. Reveals
/// multi-dimensional patterns / clusters in tabular data.
///
/// Each axis can have its own min/max; if omitted, the chart
/// auto-fits to the data on that key.
///
/// ```dart
/// GlobalParallelCoordinates(
///   axes: [
///     ParallelAxis(key: 'mpg',  label: 'MPG'),
///     ParallelAxis(key: 'hp',   label: 'HP'),
///     ParallelAxis(key: 'wt',   label: 'Weight'),
///   ],
///   rows: [
///     ParallelRow(label: 'Civic', values: {'mpg': 32, 'hp': 158, 'wt': 2.7}),
///     ...
///   ],
/// )
/// ```
class GlobalParallelCoordinates extends StatelessWidget {
  const GlobalParallelCoordinates({
    required this.axes,
    required this.rows,
    this.style = ChartStyle.standard,
    this.animation = ParallelCoordinatesAnimation.draw,
    this.lineWidth = 1.6,
    this.lineOpacity = 0.55,
    this.smooth = true,
    this.highlightedRow,
    this.colorByGroup = false,
    this.showAxisValues = true,
    super.key,
  });

  final List<ParallelAxis> axes;
  final List<ParallelRow> rows;
  final ChartStyle style;
  final ParallelCoordinatesAnimation animation;
  final double lineWidth;
  final double lineOpacity;

  /// Cubic interpolation between axis nodes — gives a smoother
  /// stream-like look. Set false for sharp polylines.
  final bool smooth;

  /// Index of a row to render at full opacity / above all others.
  final int? highlightedRow;

  /// When true, distinct [ParallelRow.group] values share a color
  /// from the palette instead of one color per row.
  final bool colorByGroup;

  final bool showAxisValues;

  @override
  Widget build(BuildContext context) {
    if (axes.isEmpty || rows.isEmpty) return const SizedBox.shrink();

    // Resolve colors. When colorByGroup is set, palette index is by
    // group name; otherwise by row index.
    final groups = <String>[];
    if (colorByGroup) {
      for (final r in rows) {
        final g = r.group ?? '';
        if (!groups.contains(g)) groups.add(g);
      }
    }
    final palette = resolveSeriesColors(
      context,
      style,
      colorByGroup ? groups.length.clamp(1, 12) : rows.length,
    );
    final rowColors = <Color>[
      for (var i = 0; i < rows.length; i++)
        rows[i].color ??
            (colorByGroup
                ? palette[groups.indexOf(rows[i].group ?? '') % palette.length]
                : palette[i % palette.length]),
    ];

    final axisStyle = resolveAxisLabelStyle(context, style);
    final gridColor = resolveGridColor(context, style);
    final fg = context.textColors.primary;

    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          minHeight: style.minHeight,
          maxWidth: resolveChartMaxWidth(context, style),
        ),
        child: AspectRatio(
          aspectRatio: style.aspectRatio,
          child: Padding(
            padding: style.padding,
            child: CustomPaintTooltipOverlay(
              hitTest: (pos, size) => _hitTest(pos, size, rowColors),
              builder: style.tooltipBuilder ?? defaultTooltipBuilder,
              child: TweenAnimationBuilder<double>(
                tween: Tween(
                  begin: style.enableAnimation ? 0.0 : 1.0,
                  end: 1.0,
                ),
                duration: style.enableAnimation
                    ? style.effectiveAnimationDuration
                    : Duration.zero,
                curve: style.effectiveAnimationCurve,
                builder: (context, t, _) {
                  return CustomPaint(
                    painter: _ParallelPainter(
                      axes: axes,
                      rows: rows,
                      colors: rowColors,
                      lineWidth: lineWidth,
                      lineOpacity: lineOpacity,
                      smooth: smooth,
                      highlightedRow: highlightedRow,
                      showAxisValues: showAxisValues,
                      gridColor: gridColor,
                      axisStyle: axisStyle,
                      fg: fg,
                      animation: animation,
                      progress: t,
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  List<TooltipEntry> _hitTest(
    Offset pos,
    Size size,
    List<Color> rowColors,
  ) {
    final layout = _ParallelLayout.compute(
      axes: axes,
      rows: rows,
      size: size,
    );
    if (layout == null) return const [];

    // Find closest polyline at pos.dx — compute y at pos.dx for
    // every row, return nearest.
    if (pos.dx < layout.axisX.first || pos.dx > layout.axisX.last) {
      return const [];
    }
    var bestI = -1;
    var bestDist = double.infinity;
    for (var i = 0; i < rows.length; i++) {
      final ys = layout.rowYs[i];
      if (ys.isEmpty) continue;
      // Find segment containing pos.dx.
      var seg = -1;
      for (var k = 0; k < layout.axisX.length - 1; k++) {
        if (pos.dx >= layout.axisX[k] && pos.dx <= layout.axisX[k + 1]) {
          seg = k;
          break;
        }
      }
      if (seg < 0) continue;
      final t =
          (pos.dx - layout.axisX[seg]) /
          (layout.axisX[seg + 1] - layout.axisX[seg]);
      final yLine = ys[seg] + (ys[seg + 1] - ys[seg]) * t;
      final d = (yLine - pos.dy).abs();
      if (d < bestDist) {
        bestDist = d;
        bestI = i;
      }
    }
    if (bestI < 0 || bestDist > 18) return const [];
    final r = rows[bestI];
    // Build a compact summary across axes.
    final parts = <String>[];
    for (final a in axes) {
      final v = r.values[a.key];
      if (v == null) continue;
      final fmt = a.formatter ?? (double v) => AppNumbers.compact(v);
      parts.add('${a.label}: ${fmt(v)}');
    }
    return [
      TooltipEntry(
        label: r.label,
        value: parts.join(' · '),
        color: rowColors[bestI],
      ),
    ];
  }
}

class _ParallelLayout {
  _ParallelLayout({
    required this.axisX,
    required this.axisTop,
    required this.axisBottom,
    required this.axisMin,
    required this.axisMax,
    required this.rowYs,
  });

  final List<double> axisX;
  final double axisTop;
  final double axisBottom;
  final List<double> axisMin;
  final List<double> axisMax;

  /// Per row, per axis: y pixel position.
  final List<List<double>> rowYs;

  static _ParallelLayout? compute({
    required List<ParallelAxis> axes,
    required List<ParallelRow> rows,
    required Size size,
  }) {
    if (size.width <= 0 || size.height <= 0) return null;
    if (axes.isEmpty || rows.isEmpty) return null;

    const leftPad = 24.0;
    const rightPad = 24.0;
    const topPad = 28.0;
    const bottomPad = 36.0;
    const left = leftPad;
    final right = size.width - rightPad;
    const top = topPad;
    final bottom = size.height - bottomPad;
    if (right <= left || bottom <= top) return null;

    // Per-axis ranges: prefer explicit min/max, fall back to data.
    final mins = <double>[];
    final maxs = <double>[];
    for (final a in axes) {
      var lo = a.min;
      var hi = a.max;
      if (lo == null || hi == null) {
        var dLo = double.infinity;
        var dHi = -double.infinity;
        for (final r in rows) {
          final v = r.values[a.key];
          if (v == null) continue;
          if (v < dLo) dLo = v;
          if (v > dHi) dHi = v;
        }
        lo ??= (dLo == double.infinity ? 0 : dLo);
        hi ??= (dHi == -double.infinity ? 1 : dHi);
      }
      if (hi == lo) hi = lo + 1;
      mins.add(lo);
      maxs.add(hi);
    }

    // X positions for each axis.
    final axisX = <double>[];
    final n = axes.length;
    for (var i = 0; i < n; i++) {
      final t = n == 1 ? 0.5 : i / (n - 1);
      axisX.add(left + (right - left) * t);
    }

    final rowYs = <List<double>>[];
    for (final r in rows) {
      final ys = <double>[];
      for (var i = 0; i < axes.length; i++) {
        final a = axes[i];
        final v = r.values[a.key];
        if (v == null) {
          ys.add(double.nan);
          continue;
        }
        final norm = ((v - mins[i]) / (maxs[i] - mins[i])).clamp(0.0, 1.0);
        ys.add(bottom - norm * (bottom - top));
      }
      rowYs.add(ys);
    }

    return _ParallelLayout(
      axisX: axisX,
      axisTop: top,
      axisBottom: bottom,
      axisMin: mins,
      axisMax: maxs,
      rowYs: rowYs,
    );
  }
}

class _ParallelPainter extends CustomPainter {
  _ParallelPainter({
    required this.axes,
    required this.rows,
    required this.colors,
    required this.lineWidth,
    required this.lineOpacity,
    required this.smooth,
    required this.highlightedRow,
    required this.showAxisValues,
    required this.gridColor,
    required this.axisStyle,
    required this.fg,
    required this.animation,
    required this.progress,
  });

  final List<ParallelAxis> axes;
  final List<ParallelRow> rows;
  final List<Color> colors;
  final double lineWidth;
  final double lineOpacity;
  final bool smooth;
  final int? highlightedRow;
  final bool showAxisValues;
  final Color gridColor;
  final TextStyle axisStyle;
  final Color fg;
  final ParallelCoordinatesAnimation animation;
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final layout = _ParallelLayout.compute(
      axes: axes,
      rows: rows,
      size: size,
    );
    if (layout == null) return;

    // Axes (vertical guides + caps).
    final axisLine = Paint()
      ..color = gridColor.withValues(alpha: 0.6)
      ..strokeWidth = 1.0;
    for (final x in layout.axisX) {
      canvas.drawLine(
        Offset(x, layout.axisTop),
        Offset(x, layout.axisBottom),
        axisLine,
      );
    }

    // Polylines.
    final order = List<int>.generate(rows.length, (i) => i);
    if (highlightedRow != null) {
      // Move highlight to the end so it paints last.
      order.remove(highlightedRow);
      order.add(highlightedRow!);
    }

    for (final ri in order) {
      final ys = layout.rowYs[ri];
      if (ys.isEmpty) continue;
      final c = colors[ri];

      // Stagger per row.
      final rowDelay = ri / rows.length * 0.2;
      final rowT = ((progress - rowDelay) / (1 - rowDelay)).clamp(0.0, 1.0);

      var rightCutoff = layout.axisX.last;
      var opacity = 1.0;
      var yShift = 0.0;
      switch (animation) {
        case ParallelCoordinatesAnimation.draw:
          rightCutoff =
              layout.axisX.first +
              (layout.axisX.last - layout.axisX.first) * rowT;
        case ParallelCoordinatesAnimation.fade:
          opacity = rowT;
        case ParallelCoordinatesAnimation.drop:
          yShift = -(1 - rowT) * 32;
          opacity = rowT;
      }

      final highlighted = highlightedRow == ri;
      final base = c.withValues(
        alpha: (highlighted ? 1.0 : lineOpacity) * opacity,
      );

      final path = Path();
      var first = true;
      for (var k = 0; k < layout.axisX.length; k++) {
        final x = layout.axisX[k];
        if (x > rightCutoff && k > 0) {
          // Interp at cutoff.
          final px = layout.axisX[k - 1];
          final py = ys[k - 1];
          final cy = ys[k];
          if (py.isFinite && cy.isFinite) {
            final t = (rightCutoff - px) / (x - px);
            final y = py + (cy - py) * t + yShift;
            path.lineTo(rightCutoff, y);
          }
          break;
        }
        final y = ys[k];
        if (!y.isFinite) continue;
        final pyShifted = y + yShift;
        if (first) {
          path.moveTo(x, pyShifted);
          first = false;
        } else {
          if (smooth) {
            final pxNorm = layout.axisX[k - 1];
            final ppy = ys[k - 1] + yShift;
            final cx1 = (pxNorm + x) / 2;
            path.cubicTo(cx1, ppy, cx1, pyShifted, x, pyShifted);
          } else {
            path.lineTo(x, pyShifted);
          }
        }
      }

      canvas.drawPath(
        path,
        Paint()
          ..color = base
          ..strokeWidth = highlighted ? lineWidth + 1.4 : lineWidth
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round,
      );
    }

    // Axis labels + min/max captions.
    if (progress < 0.4) return;
    final fadeRaw = ((progress - 0.4) / 0.6).clamp(0.0, 1.0);
    final fade = Curves.easeOutCubic.transform(fadeRaw);
    final headerStyle = axisStyle.copyWith(
      color: fg.withValues(alpha: fade),
      fontWeight: FontWeight.w700,
      letterSpacing: 0.3,
    );
    final captionStyle = axisStyle.copyWith(
      color: axisStyle.color?.withValues(alpha: fade * 0.8),
      fontSize: (axisStyle.fontSize ?? 11) - 1,
    );
    for (var i = 0; i < axes.length; i++) {
      final x = layout.axisX[i];
      final tp = TextPainter(
        text: TextSpan(text: axes[i].label, style: headerStyle),
        textDirection: TextDirection.ltr,
        maxLines: 1,
        ellipsis: '…',
      )..layout();
      tp.paint(
        canvas,
        Offset(x - tp.width / 2, layout.axisTop - 18),
      );
      if (showAxisValues) {
        final fmt = axes[i].formatter ?? (double v) => AppNumbers.compact(v);
        final hi = TextPainter(
          text: TextSpan(text: fmt(layout.axisMax[i]), style: captionStyle),
          textDirection: TextDirection.ltr,
        )..layout();
        hi.paint(canvas, Offset(x - hi.width / 2, layout.axisTop - 4));
        final lo = TextPainter(
          text: TextSpan(text: fmt(layout.axisMin[i]), style: captionStyle),
          textDirection: TextDirection.ltr,
        )..layout();
        lo.paint(canvas, Offset(x - lo.width / 2, layout.axisBottom + 4));
      }
    }
  }

  @override
  bool shouldRepaint(covariant _ParallelPainter old) =>
      old.progress != progress ||
      old.rows != rows ||
      old.axes != axes ||
      old.animation != animation ||
      old.highlightedRow != highlightedRow;
}
