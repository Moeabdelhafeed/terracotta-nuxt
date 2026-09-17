import 'package:flutter/material.dart';

import '../../../core/extensions/theme_colors_extension.dart';
import '../../../core/localization/number_formatter.dart';
import 'chart_data.dart';
import 'chart_internals.dart';
import 'chart_models.dart';
import 'chart_tooltip_overlay.dart';
import 'chart_zoom_pan.dart';
import 'custom_paint_tooltip.dart';

export 'chart_data.dart' show CalendarCell;
export 'chart_models.dart' show ChartStyle, CalendarGridAnimation;

/// Multi-year calendar heatmap — stacks N years' worth of daily
/// cells vertically, each year arranged as a 7-row × 53-col grid
/// (rows = day of week, cols = ISO week of year).
///
/// Reuses [CalendarCell] for input. Cell color comes from a
/// sequential ramp by value.
///
/// ```dart
/// GlobalCalendarGrid(
///   cells: [
///     CalendarCell(date: DateTime(2024, 1, 1), value: 3),
///     ...
///   ],
///   years: [2023, 2024],
/// )
/// ```
class GlobalCalendarGrid extends StatelessWidget {
  const GlobalCalendarGrid({
    required this.cells,
    required this.years,
    this.style = ChartStyle.standard,
    this.animation = CalendarGridAnimation.ripple,
    this.cellSize = 12,
    this.cellGap = 2,
    this.minColor,
    this.maxColor,
    this.emptyColor,
    this.showYearLabels = true,
    this.showMonthLabels = true,
    this.valueFormatter,
    super.key,
  });

  final List<CalendarCell> cells;

  /// Years to render (e.g. `[2022, 2023, 2024]`). Stacked top to
  /// bottom in the order given.
  final List<int> years;

  final ChartStyle style;
  final CalendarGridAnimation animation;
  final double cellSize;
  final double cellGap;
  final Color? minColor;
  final Color? maxColor;
  final Color? emptyColor;
  final bool showYearLabels;
  final bool showMonthLabels;
  final String Function(double)? valueFormatter;

  @override
  Widget build(BuildContext context) {
    if (cells.isEmpty || years.isEmpty) return const SizedBox.shrink();
    final palette = resolveSeriesColors(context, style, 1);
    final lo = minColor ?? palette.first.withValues(alpha: 0.18);
    final hi = maxColor ?? palette.first;
    final empty =
        emptyColor ??
        context.backgroundColors.outlineVariant.withValues(alpha: 0.4);
    final fmt = valueFormatter ?? (v) => AppNumbers.compact(v);
    final axisStyle = resolveAxisLabelStyle(context, style);
    final fg = context.textColors.primary;

    // Compute concrete size — calendar can exceed viewport width,
    // so wrap in horizontal scroll. Vertical bounds match years.
    final cellStep = cellSize + cellGap;
    final leftPad = showYearLabels ? 36.0 : 8.0;
    final topPad = showMonthLabels ? 16.0 : 8.0;
    const rightPad = 8.0;
    const bottomPad = 8.0;
    const yearGap = 16.0;
    final yearH = cellStep * 7;
    final totalH =
        topPad +
        bottomPad +
        years.length * yearH +
        (years.length - 1) * yearGap;
    // 54 weeks max coverage to avoid clipping when Jan 1 starts late.
    final totalW = leftPad + rightPad + cellStep * 54;

    return wrapZoomPan(
      Padding(
        padding: style.padding,
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: SizedBox(
            width: totalW,
            height: totalH,
            child: CustomPaintTooltipOverlay(
              hitTest: (pos, size) => _hitTest(pos, size, lo, hi, fmt),
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
                    size: Size(totalW, totalH),
                    painter: _CalendarGridPainter(
                      cells: cells,
                      years: years,
                      cellSize: cellSize,
                      cellGap: cellGap,
                      lo: lo,
                      hi: hi,
                      empty: empty,
                      showYearLabels: showYearLabels,
                      showMonthLabels: showMonthLabels,
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
      style,
    );
  }

  List<TooltipEntry> _hitTest(
    Offset pos,
    Size size,
    Color lo,
    Color hi,
    String Function(double) fmt,
  ) {
    final layout = _CalendarGridLayout.compute(
      cells: cells,
      years: years,
      size: size,
      cellSize: cellSize,
      cellGap: cellGap,
      showYearLabels: showYearLabels,
      showMonthLabels: showMonthLabels,
    );
    if (layout == null) return const [];
    for (final cell in layout.cells) {
      if (cell.rect.contains(pos)) {
        final v = cell.value;
        final color = layout.maxValue > 0 && v > 0
            ? Color.lerp(lo, hi, (v / layout.maxValue).clamp(0.0, 1.0))!
            : hi;
        return [
          TooltipEntry(
            label:
                '${cell.date.year}-'
                '${cell.date.month.toString().padLeft(2, '0')}-'
                '${cell.date.day.toString().padLeft(2, '0')}',
            value: v == 0 ? '—' : fmt(v),
            color: color,
          ),
        ];
      }
    }
    return const [];
  }
}

class _PlacedCell {
  _PlacedCell(this.rect, this.date, this.value);
  final Rect rect;
  final DateTime date;
  final double value;
}

class _CalendarGridLayout {
  _CalendarGridLayout({
    required this.cells,
    required this.maxValue,
    required this.yearRects,
    required this.monthLabels,
    required this.cellSize,
    required this.cellGap,
  });

  final List<_PlacedCell> cells;
  final double maxValue;

  /// Per year: top-left of that year's grid (for row label).
  final Map<int, Rect> yearRects;

  /// Per year: list of (label, x position) for month tickmarks.
  final Map<int, List<(String, double)>> monthLabels;
  final double cellSize;
  final double cellGap;

  static _CalendarGridLayout? compute({
    required List<CalendarCell> cells,
    required List<int> years,
    required Size size,
    required double cellSize,
    required double cellGap,
    required bool showYearLabels,
    required bool showMonthLabels,
  }) {
    if (size.width <= 0 || size.height <= 0) return null;

    var maxValue = 0.0;
    final byDate = <DateTime, double>{};
    for (final c in cells) {
      final key = DateTime(c.date.year, c.date.month, c.date.day);
      byDate[key] = (byDate[key] ?? 0) + c.value;
      if ((byDate[key] ?? 0) > maxValue) maxValue = byDate[key]!;
    }
    if (maxValue == 0) maxValue = 1;

    final leftPad = showYearLabels ? 36.0 : 8.0;
    final topPad = showMonthLabels ? 16.0 : 8.0;

    final placed = <_PlacedCell>[];
    final yearRects = <int, Rect>{};
    final monthLabels = <int, List<(String, double)>>{};
    final rowH = cellSize + cellGap;
    final yearH = rowH * 7;
    const yearGap = 16.0;

    for (var yi = 0; yi < years.length; yi++) {
      final year = years[yi];
      final yearTop = topPad + yi * (yearH + yearGap);
      yearRects[year] = Rect.fromLTWH(
        0,
        yearTop,
        size.width,
        yearH,
      );

      // Find Jan 1 → place it in column based on its weekday.
      final jan1 = DateTime(year, 1, 1);
      // Use ISO weekday: Mon=1..Sun=7. Map so Monday is row 0.
      final jan1Row = (jan1.weekday - 1) % 7;
      // Determine each day's column = (dayOfYear - 1 + jan1Row) ~/ 7.
      final daysInYear =
          DateTime(year, 12, 31).difference(DateTime(year, 1, 1)).inDays + 1;
      final months = <(String, double)>[];
      var lastMonth = -1;
      for (var d = 0; d < daysInYear; d++) {
        final date = jan1.add(Duration(days: d));
        final col = (d + jan1Row) ~/ 7;
        final row = (d + jan1Row) % 7;
        final x = leftPad + col * (cellSize + cellGap);
        final y = yearTop + row * (cellSize + cellGap);
        final v = byDate[DateTime(date.year, date.month, date.day)] ?? 0;
        placed.add(
          _PlacedCell(
            Rect.fromLTWH(x, y, cellSize, cellSize),
            date,
            v,
          ),
        );
        if (showMonthLabels && date.month != lastMonth && row == 0) {
          months.add((_monthName(date.month), x));
          lastMonth = date.month;
        }
      }
      monthLabels[year] = months;
    }

    return _CalendarGridLayout(
      cells: placed,
      maxValue: maxValue,
      yearRects: yearRects,
      monthLabels: monthLabels,
      cellSize: cellSize,
      cellGap: cellGap,
    );
  }

  static String _monthName(int m) {
    const names = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return names[m - 1];
  }
}

class _CalendarGridPainter extends CustomPainter {
  _CalendarGridPainter({
    required this.cells,
    required this.years,
    required this.cellSize,
    required this.cellGap,
    required this.lo,
    required this.hi,
    required this.empty,
    required this.showYearLabels,
    required this.showMonthLabels,
    required this.axisStyle,
    required this.fg,
    required this.animation,
    required this.progress,
  });

  final List<CalendarCell> cells;
  final List<int> years;
  final double cellSize;
  final double cellGap;
  final Color lo;
  final Color hi;
  final Color empty;
  final bool showYearLabels;
  final bool showMonthLabels;
  final TextStyle axisStyle;
  final Color fg;
  final CalendarGridAnimation animation;
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final layout = _CalendarGridLayout.compute(
      cells: cells,
      years: years,
      size: size,
      cellSize: cellSize,
      cellGap: cellGap,
      showYearLabels: showYearLabels,
      showMonthLabels: showMonthLabels,
    );
    if (layout == null) return;

    final totalCells = layout.cells.length;

    for (var i = 0; i < layout.cells.length; i++) {
      final cell = layout.cells[i];
      double cellOpacity;
      switch (animation) {
        case CalendarGridAnimation.ripple:
          // Day-by-day stagger.
          final delay = i / totalCells * 0.7;
          cellOpacity = ((progress - delay) / (1 - delay)).clamp(0.0, 1.0);
        case CalendarGridAnimation.byValue:
          // Lower values fade in first.
          final rank = layout.maxValue > 0
              ? (1 - cell.value / layout.maxValue).clamp(0.0, 1.0)
              : 0.0;
          final delay = rank * 0.6;
          cellOpacity = ((progress - delay) / (1 - delay)).clamp(0.0, 1.0);
        case CalendarGridAnimation.fade:
          cellOpacity = progress;
      }
      if (cellOpacity <= 0) continue;
      final v = cell.value;
      final color = v > 0
          ? Color.lerp(lo, hi, (v / layout.maxValue).clamp(0.0, 1.0))!
          : empty;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          cell.rect,
          const Radius.circular(2),
        ),
        Paint()..color = color.withValues(alpha: cellOpacity),
      );
    }

    // Year labels.
    if (showYearLabels && progress > 0.4) {
      final fadeRaw = ((progress - 0.4) / 0.6).clamp(0.0, 1.0);
      final fade = Curves.easeOutCubic.transform(fadeRaw);
      for (final entry in layout.yearRects.entries) {
        final tp = TextPainter(
          text: TextSpan(
            text: entry.key.toString(),
            style: axisStyle.copyWith(
              color: fg.withValues(alpha: fade),
              fontWeight: FontWeight.w700,
            ),
          ),
          textDirection: TextDirection.ltr,
        )..layout();
        tp.paint(
          canvas,
          Offset(
            4,
            entry.value.top + entry.value.height / 2 - tp.height / 2,
          ),
        );
      }
    }

    // Month labels.
    if (showMonthLabels && progress > 0.4) {
      final fadeRaw = ((progress - 0.4) / 0.6).clamp(0.0, 1.0);
      final fade = Curves.easeOutCubic.transform(fadeRaw);
      for (final entry in layout.monthLabels.entries) {
        final yearTop = layout.yearRects[entry.key]!.top;
        for (final (label, x) in entry.value) {
          final tp = TextPainter(
            text: TextSpan(
              text: label,
              style: axisStyle.copyWith(
                color: axisStyle.color?.withValues(alpha: fade),
              ),
            ),
            textDirection: TextDirection.ltr,
          )..layout();
          tp.paint(canvas, Offset(x, yearTop - tp.height - 2));
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant _CalendarGridPainter old) =>
      old.progress != progress ||
      old.cells != cells ||
      old.years != years ||
      old.animation != animation;
}
