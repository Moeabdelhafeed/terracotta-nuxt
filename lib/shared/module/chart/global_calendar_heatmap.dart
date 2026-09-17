import 'package:flutter/material.dart';
import 'package:intl/intl.dart' hide TextDirection;

import '../../../core/extensions/theme_colors_extension.dart';
import '../../../core/localization/number_formatter.dart';
import 'chart_data.dart';
import 'chart_internals.dart';
import 'chart_models.dart';
import 'chart_tooltip_overlay.dart';
import 'chart_zoom_pan.dart';
import 'custom_paint_tooltip.dart';

export 'chart_data.dart' show CalendarCell;
export 'chart_models.dart' show ChartStyle;

/// Calendar heatmap — date-grid view, columns are weeks (oldest →
/// newest left → right), rows are weekdays. Cell color lerps along
/// [colorRamp] based on value within `[min, max]`. GitHub-style
/// activity calendar.
///
/// ```dart
/// GlobalCalendarHeatmap(
///   cells: [
///     CalendarCell(date: DateTime(2026, 1, 1), value: 4),
///     CalendarCell(date: DateTime(2026, 1, 2), value: 7),
///     ...
///   ],
/// )
/// ```
class GlobalCalendarHeatmap extends StatelessWidget {
  const GlobalCalendarHeatmap({
    required this.cells,
    this.start,
    this.end,
    this.style = ChartStyle.standard,
    this.colorRamp,
    this.cellPadding = 2,
    this.cellRadius = 2,
    this.showMonthLabels = true,
    this.showWeekdayLabels = true,
    this.firstWeekday = DateTime.sunday,
    this.locale,
    super.key,
  });

  final List<CalendarCell> cells;

  /// Override the calendar's start date. Defaults to the earliest
  /// cell date snapped to the previous [firstWeekday].
  final DateTime? start;

  /// Override the calendar's end date. Defaults to the latest cell.
  final DateTime? end;

  final ChartStyle style;

  /// 2+ colors lerped across the value range. Defaults to a
  /// theme-aware ramp from `outlineVariant` → `primary`.
  final List<Color>? colorRamp;

  final double cellPadding;
  final double cellRadius;
  final bool showMonthLabels;
  final bool showWeekdayLabels;

  /// `DateTime.sunday` (default for GitHub-style) or
  /// `DateTime.monday` (ISO).
  final int firstWeekday;

  /// Override locale for month / weekday labels. Falls back to the
  /// active app locale.
  final String? locale;

  @override
  Widget build(BuildContext context) {
    if (cells.isEmpty) return const SizedBox.shrink();

    final ramp =
        colorRamp ??
        [
          context.backgroundColors.outlineVariant,
          context.primaryColors.primary,
        ];
    final axisStyle = resolveAxisLabelStyle(context, style);

    final byDate = <DateTime, CalendarCell>{};
    for (final c in cells) {
      byDate[DateTime(c.date.year, c.date.month, c.date.day)] = c;
    }

    var startDate =
        start ??
        cells
            .map((c) => DateTime(c.date.year, c.date.month, c.date.day))
            .reduce((a, b) => a.isBefore(b) ? a : b);
    final endDate =
        end ??
        cells
            .map((c) => DateTime(c.date.year, c.date.month, c.date.day))
            .reduce((a, b) => a.isAfter(b) ? a : b);

    // Snap start back to the previous firstWeekday so column 0 is a
    // full week.
    final shift = (startDate.weekday - firstWeekday) % 7;
    startDate = startDate.subtract(Duration(days: shift));

    final values = cells.map((c) => c.value).toList(growable: false);
    final vMin = values.reduce((a, b) => a < b ? a : b);
    final vMax = values.reduce((a, b) => a > b ? a : b);

    return wrapZoomPan(
      Center(
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
                hitTest: (pos, size) => _hitTest(
                  pos: pos,
                  size: size,
                  start: startDate,
                  end: endDate,
                  byDate: byDate,
                  colors: ramp,
                  vMin: vMin,
                  vMax: vMax,
                  firstWeekday: firstWeekday,
                ),
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
                      painter: _CalendarHeatmapPainter(
                        start: startDate,
                        end: endDate,
                        byDate: byDate,
                        ramp: ramp,
                        vMin: vMin,
                        vMax: vMax,
                        cellPadding: cellPadding,
                        cellRadius: cellRadius,
                        axisStyle: axisStyle,
                        showMonthLabels: showMonthLabels,
                        showWeekdayLabels: showWeekdayLabels,
                        firstWeekday: firstWeekday,
                        locale: locale,
                        progress: t,
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      ),
      style,
    );
  }

  List<TooltipEntry> _hitTest({
    required Offset pos,
    required Size size,
    required DateTime start,
    required DateTime end,
    required Map<DateTime, CalendarCell> byDate,
    required List<Color> colors,
    required double vMin,
    required double vMax,
    required int firstWeekday,
  }) {
    final layout = _CalendarLayout(
      start: start,
      end: end,
      size: size,
      showMonthLabels: showMonthLabels,
      showWeekdayLabels: showWeekdayLabels,
    );
    if (!layout.plotRect.contains(pos)) return const [];
    final col = ((pos.dx - layout.plotRect.left) / layout.cellSize).floor();
    final row = ((pos.dy - layout.plotRect.top) / layout.cellSize).floor();
    if (col < 0 || col >= layout.weekCount) return const [];
    if (row < 0 || row >= 7) return const [];

    final date = start.add(Duration(days: col * 7 + row));
    if (date.isAfter(end)) return const [];
    final cell = byDate[DateTime(date.year, date.month, date.day)];
    if (cell == null) return const [];

    final t = (cell.value - vMin) / (vMax - vMin == 0 ? 1 : vMax - vMin);
    final color = _lerpRamp(colors, t);
    final dateLabel = DateFormat.yMMMd(
      locale ?? Intl.getCurrentLocale(),
    ).format(cell.date);
    return [
      TooltipEntry(
        label: cell.label ?? dateLabel,
        value: AppNumbers.compact(cell.value),
        color: color,
      ),
    ];
  }

  static Color _lerpRamp(List<Color> ramp, double t) {
    final clamped = t.clamp(0.0, 1.0);
    if (ramp.length == 1) return ramp.first;
    final scaled = clamped * (ramp.length - 1);
    final lo = scaled.floor().clamp(0, ramp.length - 1);
    final hi = (lo + 1).clamp(0, ramp.length - 1);
    final local = scaled - lo;
    return Color.lerp(ramp[lo], ramp[hi], local) ?? ramp[lo];
  }
}

class _CalendarLayout {
  _CalendarLayout({
    required this.start,
    required this.end,
    required this.size,
    required this.showMonthLabels,
    required this.showWeekdayLabels,
  }) {
    final days = end.difference(start).inDays + 1;
    weekCount = (days / 7).ceil();
    final topPad = showMonthLabels ? 16.0 : 0.0;
    // 32dp gutter fits 3-letter weekday labels ("Sun", "Mon") on
    // one line — 24dp wrapped them.
    final leftPad = showWeekdayLabels ? 32.0 : 0.0;
    final availW = size.width - leftPad;
    final availH = size.height - topPad;
    final fitW = (availW / weekCount).clamp(2, 64).toDouble();
    final fitH = (availH / 7).clamp(2, 64).toDouble();
    cellSize = fitW < fitH ? fitW : fitH;
    plotRect = Rect.fromLTWH(
      leftPad,
      topPad,
      cellSize * weekCount,
      cellSize * 7,
    );
  }

  final DateTime start;
  final DateTime end;
  final Size size;
  final bool showMonthLabels;
  final bool showWeekdayLabels;
  late final int weekCount;
  late final double cellSize;
  late final Rect plotRect;
}

class _CalendarHeatmapPainter extends CustomPainter {
  _CalendarHeatmapPainter({
    required this.start,
    required this.end,
    required this.byDate,
    required this.ramp,
    required this.vMin,
    required this.vMax,
    required this.cellPadding,
    required this.cellRadius,
    required this.axisStyle,
    required this.showMonthLabels,
    required this.showWeekdayLabels,
    required this.firstWeekday,
    required this.locale,
    required this.progress,
  });

  final DateTime start;
  final DateTime end;
  final Map<DateTime, CalendarCell> byDate;
  final List<Color> ramp;
  final double vMin;
  final double vMax;
  final double cellPadding;
  final double cellRadius;
  final TextStyle axisStyle;
  final bool showMonthLabels;
  final bool showWeekdayLabels;
  final int firstWeekday;
  final String? locale;
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;

    final layout = _CalendarLayout(
      start: start,
      end: end,
      size: size,
      showMonthLabels: showMonthLabels,
      showWeekdayLabels: showWeekdayLabels,
    );
    final cellSize = layout.cellSize;
    if (cellSize <= 0) return;

    // Cells.
    var lastMonthLabeled = -1;
    final monthFmt = DateFormat.MMM(locale ?? Intl.getCurrentLocale());
    for (var col = 0; col < layout.weekCount; col++) {
      for (var row = 0; row < 7; row++) {
        final date = start.add(Duration(days: col * 7 + row));
        if (date.isAfter(end)) continue;
        final cell = byDate[DateTime(date.year, date.month, date.day)];
        final left = layout.plotRect.left + col * cellSize + cellPadding / 2;
        final top = layout.plotRect.top + row * cellSize + cellPadding / 2;
        final w = cellSize - cellPadding;
        final h = cellSize - cellPadding;
        if (w <= 0 || h <= 0) continue;
        if (cell == null) {
          canvas.drawRRect(
            RRect.fromRectAndRadius(
              Rect.fromLTWH(left, top, w, h),
              Radius.circular(cellRadius),
            ),
            Paint()..color = ramp.first.withValues(alpha: 0.35 * progress),
          );
          continue;
        }
        final t = (cell.value - vMin) / (vMax - vMin == 0 ? 1 : vMax - vMin);
        final color = GlobalCalendarHeatmap._lerpRamp(ramp, t);
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(left, top, w, h),
            Radius.circular(cellRadius),
          ),
          Paint()..color = color.withValues(alpha: color.a * progress),
        );
      }

      if (showMonthLabels) {
        final firstDate = start.add(Duration(days: col * 7));
        if (firstDate.month != lastMonthLabeled) {
          lastMonthLabeled = firstDate.month;
          final tp = TextPainter(
            text: TextSpan(text: monthFmt.format(firstDate), style: axisStyle),
            textDirection: TextDirection.ltr,
          )..layout();
          tp.paint(
            canvas,
            Offset(layout.plotRect.left + col * cellSize, 0),
          );
        }
      }
    }

    if (showWeekdayLabels) {
      final wkFmt = DateFormat.E(locale ?? Intl.getCurrentLocale());
      const weekdaySymbols = [
        'Mon',
        'Tue',
        'Wed',
        'Thu',
        'Fri',
        'Sat',
        'Sun',
      ];
      for (var row = 0; row < 7; row += 2) {
        final dayOffset = row;
        final sample = start.add(Duration(days: dayOffset));
        var label = '';
        try {
          label = wkFmt.format(sample);
        } catch (_) {
          label = weekdaySymbols[(firstWeekday - 1 + row) % 7];
        }
        final tp =
            TextPainter(
              text: TextSpan(text: label, style: axisStyle),
              textDirection: TextDirection.ltr,
              maxLines: 1,
            )..layout(
              maxWidth: (layout.plotRect.left - 4).clamp(0.0, double.infinity),
            );
        tp.paint(
          canvas,
          Offset(
            layout.plotRect.left - tp.width - 4,
            layout.plotRect.top + row * cellSize + (cellSize - tp.height) / 2,
          ),
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _CalendarHeatmapPainter old) =>
      old.progress != progress ||
      old.start != start ||
      old.end != end ||
      old.byDate.length != byDate.length ||
      old.cellPadding != cellPadding ||
      old.cellRadius != cellRadius ||
      old.showMonthLabels != showMonthLabels ||
      old.showWeekdayLabels != showWeekdayLabels;
}
