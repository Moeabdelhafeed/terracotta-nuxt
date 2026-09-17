import 'package:flutter/material.dart';

import '../../../core/extensions/theme_colors_extension.dart';
import '../../../core/localization/number_formatter.dart';
import 'chart_data.dart';
import 'chart_internals.dart';
import 'chart_models.dart';
import 'chart_tooltip_overlay.dart';
import 'chart_zoom_pan.dart';
import 'custom_paint_tooltip.dart';

export 'chart_data.dart' show GanttTask;
export 'chart_models.dart' show ChartStyle, GanttAnimation;

/// Gantt chart — horizontal time bars per task. One row per
/// [GanttTask], bar spans `[start, end]` along the x-axis.
/// Optional progress fills the inner portion. Dependency arrows
/// drawn between linked tasks.
///
/// Rows ordered by their position in [tasks] (index 0 at top).
///
/// ```dart
/// GlobalGantt(
///   tasks: [
///     GanttTask(id: 'a', label: 'Plan', start: 0, end: 5),
///     GanttTask(id: 'b', label: 'Build', start: 4, end: 12,
///       dependencies: ['a']),
///   ],
/// )
/// ```
class GlobalGantt extends StatelessWidget {
  const GlobalGantt({
    required this.tasks,
    this.style = ChartStyle.standard,
    this.animation = GanttAnimation.draw,
    this.barHeight = 14,
    this.rowHeight = 28,
    this.showLabels = true,
    this.showProgress = true,
    this.showDependencies = true,
    this.showAxisLabels = true,
    this.valueFormatter,
    super.key,
  });

  final List<GanttTask> tasks;
  final ChartStyle style;
  final GanttAnimation animation;
  final double barHeight;
  final double rowHeight;
  final bool showLabels;
  final bool showProgress;
  final bool showDependencies;
  final bool showAxisLabels;
  final String Function(double)? valueFormatter;

  @override
  Widget build(BuildContext context) {
    if (tasks.isEmpty) return const SizedBox.shrink();
    final palette = resolveSeriesColors(context, style, tasks.length);
    final fmt = valueFormatter ?? (v) => AppNumbers.compact(v);
    final axisStyle = resolveAxisLabelStyle(context, style);
    final gridColor = resolveGridColor(context, style);
    final fg = context.textColors.primary;

    // Compute height from task count — Gantt fits row-by-row, no
    // free aspect ratio (would leave whitespace below). Include
    // outer style.padding so axis labels don't collide with bars.
    const topPad = 16.0;
    const bottomPad = 36.0;
    final padV = style.padding is EdgeInsets
        ? (style.padding as EdgeInsets).vertical
        : 24.0;
    final neededHeight = topPad + bottomPad + tasks.length * rowHeight + padV;
    return wrapZoomPan(
      Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: resolveChartMaxWidth(context, style),
          ),
          child: SizedBox(
            height: neededHeight,
            child: Padding(
              padding: style.padding,
              child: CustomPaintTooltipOverlay(
                hitTest: (pos, size) => _hitTest(pos, size, palette, fmt),
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
                      painter: _GanttPainter(
                        tasks: tasks,
                        palette: palette,
                        barHeight: barHeight,
                        rowHeight: rowHeight,
                        showLabels: showLabels,
                        showProgress: showProgress,
                        showDependencies: showDependencies,
                        showAxisLabels: showAxisLabels,
                        gridColor: gridColor,
                        axisStyle: axisStyle,
                        fg: fg,
                        animation: animation,
                        progress: t,
                        valueFormatter: fmt,
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

  List<TooltipEntry> _hitTest(
    Offset pos,
    Size size,
    List<Color> palette,
    String Function(double) fmt,
  ) {
    final layout = _GanttLayout.compute(
      tasks: tasks,
      size: size,
      rowHeight: rowHeight,
      barHeight: barHeight,
    );
    if (layout == null) return const [];
    for (var i = 0; i < layout.bars.length; i++) {
      final b = layout.bars[i];
      if (b.rect.contains(pos)) {
        return [
          TooltipEntry(
            label: tasks[i].label,
            value:
                '${fmt(tasks[i].start)} → ${fmt(tasks[i].end)}'
                '${tasks[i].progress > 0 ? ' · ${(tasks[i].progress * 100).toStringAsFixed(0)}%' : ''}',
            color: tasks[i].color ?? palette[i % palette.length],
          ),
        ];
      }
    }
    return const [];
  }
}

class _GanttBar {
  _GanttBar({required this.rect, required this.center});
  final Rect rect;
  final Offset center;
}

class _GanttLayout {
  _GanttLayout({
    required this.bars,
    required this.idIndex,
    required this.left,
    required this.right,
    required this.top,
    required this.bottom,
    required this.xMin,
    required this.xMax,
    required this.barHeight,
    required this.rowHeight,
  });

  final List<_GanttBar> bars;
  final Map<String, int> idIndex;
  final double left;
  final double right;
  final double top;
  final double bottom;
  final double xMin;
  final double xMax;
  final double barHeight;
  final double rowHeight;

  double xFor(double v) {
    return left + (v - xMin) / (xMax - xMin) * (right - left);
  }

  double rowY(int i) => top + rowHeight * (i + 0.5);

  static _GanttLayout? compute({
    required List<GanttTask> tasks,
    required Size size,
    required double rowHeight,
    required double barHeight,
  }) {
    if (size.width <= 0 || size.height <= 0) return null;
    if (tasks.isEmpty) return null;
    var xMin = double.infinity;
    var xMax = -double.infinity;
    for (final t in tasks) {
      if (t.start < xMin) xMin = t.start;
      if (t.end > xMax) xMax = t.end;
    }
    if (xMax == xMin) xMax = xMin + 1;
    final pad = (xMax - xMin) * 0.02;
    xMin -= pad;
    xMax += pad;

    const leftPad = 110.0;
    const rightPad = 16.0;
    const topPad = 16.0;
    const bottomPad = 36.0;
    const left = leftPad;
    final right = size.width - rightPad;
    const top = topPad;
    final bottom = size.height - bottomPad;

    final bars = <_GanttBar>[];
    final idIndex = <String, int>{};
    for (var i = 0; i < tasks.length; i++) {
      idIndex[tasks[i].id] = i;
    }
    for (var i = 0; i < tasks.length; i++) {
      final t = tasks[i];
      final x0 = left + (t.start - xMin) / (xMax - xMin) * (right - left);
      final x1 = left + (t.end - xMin) / (xMax - xMin) * (right - left);
      final cy = top + rowHeight * (i + 0.5);
      bars.add(
        _GanttBar(
          rect: Rect.fromLTRB(
            x0,
            cy - barHeight / 2,
            x1,
            cy + barHeight / 2,
          ),
          center: Offset((x0 + x1) / 2, cy),
        ),
      );
    }

    return _GanttLayout(
      bars: bars,
      idIndex: idIndex,
      left: left,
      right: right,
      top: top,
      bottom: bottom,
      xMin: xMin,
      xMax: xMax,
      barHeight: barHeight,
      rowHeight: rowHeight,
    );
  }
}

class _GanttPainter extends CustomPainter {
  _GanttPainter({
    required this.tasks,
    required this.palette,
    required this.barHeight,
    required this.rowHeight,
    required this.showLabels,
    required this.showProgress,
    required this.showDependencies,
    required this.showAxisLabels,
    required this.gridColor,
    required this.axisStyle,
    required this.fg,
    required this.animation,
    required this.progress,
    required this.valueFormatter,
  });

  final List<GanttTask> tasks;
  final List<Color> palette;
  final double barHeight;
  final double rowHeight;
  final bool showLabels;
  final bool showProgress;
  final bool showDependencies;
  final bool showAxisLabels;
  final Color gridColor;
  final TextStyle axisStyle;
  final Color fg;
  final GanttAnimation animation;
  final double progress;
  final String Function(double) valueFormatter;

  @override
  void paint(Canvas canvas, Size size) {
    final layout = _GanttLayout.compute(
      tasks: tasks,
      size: size,
      rowHeight: rowHeight,
      barHeight: barHeight,
    );
    if (layout == null) return;

    // Row gridlines.
    for (var i = 0; i < tasks.length; i++) {
      final y = layout.top + rowHeight * (i + 0.5);
      canvas.drawLine(
        Offset(layout.left, y + barHeight / 2 + 2),
        Offset(layout.right, y + barHeight / 2 + 2),
        Paint()
          ..color = gridColor.withValues(alpha: 0.3)
          ..strokeWidth = 0.5,
      );
    }

    // Bars.
    for (var i = 0; i < tasks.length; i++) {
      final t = tasks[i];
      final r = layout.bars[i].rect;
      final c = t.color ?? palette[i % palette.length];

      final rowDelay = i / tasks.length * 0.25;
      final rowT = ((progress - rowDelay) / (1 - rowDelay)).clamp(0.0, 1.0);
      double drawT;
      double opacity;
      switch (animation) {
        case GanttAnimation.draw:
          drawT = rowT;
          opacity = 1.0;
        case GanttAnimation.fade:
          drawT = 1.0;
          opacity = progress;
        case GanttAnimation.cascade:
          drawT = 1.0;
          opacity = rowT;
      }
      if (drawT <= 0 || opacity <= 0) continue;

      final visibleR = Rect.fromLTRB(
        r.left,
        r.top,
        r.left + r.width * drawT,
        r.bottom,
      );
      final rr = RRect.fromRectAndRadius(visibleR, const Radius.circular(4));
      canvas.drawRRect(
        rr,
        Paint()..color = c.withValues(alpha: 0.25 * opacity),
      );
      // Progress fill.
      if (showProgress && t.progress > 0) {
        final progRect = Rect.fromLTRB(
          r.left,
          r.top,
          r.left + r.width * t.progress * drawT,
          r.bottom,
        );
        final pr = RRect.fromRectAndRadius(progRect, const Radius.circular(4));
        canvas.drawRRect(pr, Paint()..color = c.withValues(alpha: opacity));
      }
      // Outline.
      canvas.drawRRect(
        rr,
        Paint()
          ..color = c.withValues(alpha: opacity)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.0,
      );

      // Task label on the left gutter.
      if (showLabels && progress > 0.4) {
        final fadeRaw = ((progress - 0.4) / 0.6).clamp(0.0, 1.0);
        final fade = Curves.easeOutCubic.transform(fadeRaw);
        final tp = TextPainter(
          text: TextSpan(
            text: t.label,
            style: axisStyle.copyWith(
              color: fg.withValues(alpha: fade),
              fontWeight: FontWeight.w600,
            ),
          ),
          textDirection: TextDirection.ltr,
          maxLines: 1,
          ellipsis: '…',
        )..layout(maxWidth: layout.left - 8);
        tp.paint(
          canvas,
          Offset(layout.left - 8 - tp.width, r.center.dy - tp.height / 2),
        );
      }
    }

    // Dependency arrows — drawn AFTER bars so they overlay clearly.
    if (showDependencies && progress > 0.6) {
      final fade = ((progress - 0.6) / 0.4).clamp(0.0, 1.0);
      for (var i = 0; i < tasks.length; i++) {
        final t = tasks[i];
        for (final depId in t.dependencies) {
          final depIdx = layout.idIndex[depId];
          if (depIdx == null) continue;
          final depBar = layout.bars[depIdx];
          final tBar = layout.bars[i];
          final start = Offset(depBar.rect.right, depBar.center.dy);
          final end = Offset(tBar.rect.left, tBar.center.dy);
          final midX = start.dx + (end.dx - start.dx) * 0.5;
          final paint = Paint()
            ..color = fg.withValues(alpha: 0.5 * fade)
            ..strokeWidth = 1.0
            ..style = PaintingStyle.stroke
            ..strokeCap = StrokeCap.round;
          canvas.drawLine(start, Offset(midX, start.dy), paint);
          canvas.drawLine(Offset(midX, start.dy), Offset(midX, end.dy), paint);
          canvas.drawLine(Offset(midX, end.dy), end, paint);
          // Arrow head.
          final ah = Path()
            ..moveTo(end.dx, end.dy)
            ..lineTo(end.dx - 6, end.dy - 3)
            ..lineTo(end.dx - 6, end.dy + 3)
            ..close();
          canvas.drawPath(
            ah,
            Paint()..color = fg.withValues(alpha: 0.5 * fade),
          );
        }
      }
    }

    // Axis range labels.
    if (!showAxisLabels) return;
    if (progress < 0.4) return;
    final fadeRaw = ((progress - 0.4) / 0.6).clamp(0.0, 1.0);
    final fade = Curves.easeOutCubic.transform(fadeRaw);
    final lblStyle = axisStyle.copyWith(
      color: axisStyle.color?.withValues(alpha: fade),
    );
    void drawText(String s, Offset at, {bool right = false}) {
      final tp = TextPainter(
        text: TextSpan(text: s, style: lblStyle),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(right ? at.dx - tp.width : at.dx, at.dy));
    }

    drawText(
      valueFormatter(layout.xMin),
      Offset(layout.left, layout.bottom + 4),
    );
    drawText(
      valueFormatter(layout.xMax),
      Offset(layout.right, layout.bottom + 4),
      right: true,
    );
  }

  @override
  bool shouldRepaint(covariant _GanttPainter old) =>
      old.progress != progress ||
      old.tasks != tasks ||
      old.animation != animation;
}
