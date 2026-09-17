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

/// Swimlane chart — Gantt-style time bars grouped by
/// [GanttTask.lane]. Lanes render top-to-bottom in the order
/// declared in [lanes]; tasks within each lane stack on rows.
///
/// Adds horizontal lane backgrounds + headers; otherwise behaves
/// like Gantt (per-bar progress, dependency arrows).
///
/// ```dart
/// GlobalSwimlane(
///   lanes: ['Design', 'Eng', 'QA'],
///   tasks: [
///     GanttTask(id: 'a', label: 'Wireframes', start: 0, end: 3, lane: 'Design'),
///     ...
///   ],
/// )
/// ```
class GlobalSwimlane extends StatelessWidget {
  const GlobalSwimlane({
    required this.lanes,
    required this.tasks,
    this.style = ChartStyle.standard,
    this.animation = GanttAnimation.draw,
    this.barHeight = 14,
    this.rowHeight = 28,
    this.lanePadding = 8,
    this.showLabels = true,
    this.showProgress = true,
    this.showDependencies = true,
    this.showAxisLabels = true,
    this.valueFormatter,
    super.key,
  });

  final List<String> lanes;
  final List<GanttTask> tasks;
  final ChartStyle style;
  final GanttAnimation animation;
  final double barHeight;
  final double rowHeight;
  final double lanePadding;
  final bool showLabels;
  final bool showProgress;
  final bool showDependencies;
  final bool showAxisLabels;
  final String Function(double)? valueFormatter;

  @override
  Widget build(BuildContext context) {
    if (tasks.isEmpty || lanes.isEmpty) return const SizedBox.shrink();
    final palette = resolveSeriesColors(context, style, lanes.length);
    final fmt = valueFormatter ?? (v) => AppNumbers.compact(v);
    final axisStyle = resolveAxisLabelStyle(context, style);
    final gridColor = resolveGridColor(context, style);
    final fg = context.textColors.primary;

    // Compute height per lane × tasks-in-lane. Include outer
    // style.padding so axis labels don't collide with bars.
    const topPad = 16.0;
    const bottomPad = 36.0;
    final tasksByLane = <String, int>{};
    for (final lane in lanes) {
      tasksByLane[lane] = 0;
    }
    for (final t in tasks) {
      final lane = t.lane ?? '';
      if (tasksByLane.containsKey(lane)) {
        tasksByLane[lane] = (tasksByLane[lane] ?? 0) + 1;
      }
    }
    var laneStackH = 0.0;
    for (final lane in lanes) {
      final count = tasksByLane[lane] ?? 0;
      laneStackH += count * rowHeight + lanePadding;
    }
    final padV = style.padding is EdgeInsets
        ? (style.padding as EdgeInsets).vertical
        : 24.0;
    final neededHeight = topPad + bottomPad + laneStackH + padV;
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
                      painter: _SwimlanePainter(
                        lanes: lanes,
                        tasks: tasks,
                        palette: palette,
                        barHeight: barHeight,
                        rowHeight: rowHeight,
                        lanePadding: lanePadding,
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
    final layout = _SwimLayout.compute(
      lanes: lanes,
      tasks: tasks,
      size: size,
      rowHeight: rowHeight,
      lanePadding: lanePadding,
      barHeight: barHeight,
    );
    if (layout == null) return const [];
    for (var i = 0; i < layout.bars.length; i++) {
      final b = layout.bars[i];
      if (b.rect.contains(pos)) {
        final task = layout.tasksOrdered[i];
        final laneIdx = lanes.indexOf(task.lane ?? '');
        return [
          TooltipEntry(
            label: '${task.lane ?? '—'} · ${task.label}',
            value: '${fmt(task.start)} → ${fmt(task.end)}',
            color: task.color ?? palette[laneIdx.clamp(0, palette.length - 1)],
          ),
        ];
      }
    }
    return const [];
  }
}

class _SwimBar {
  _SwimBar({required this.rect, required this.center});
  final Rect rect;
  final Offset center;
}

class _SwimLayout {
  _SwimLayout({
    required this.bars,
    required this.tasksOrdered,
    required this.laneRects,
    required this.idIndex,
    required this.left,
    required this.right,
    required this.top,
    required this.bottom,
    required this.xMin,
    required this.xMax,
  });

  final List<_SwimBar> bars;
  final List<GanttTask> tasksOrdered;
  final List<Rect> laneRects;
  final Map<String, int> idIndex;
  final double left;
  final double right;
  final double top;
  final double bottom;
  final double xMin;
  final double xMax;

  static _SwimLayout? compute({
    required List<String> lanes,
    required List<GanttTask> tasks,
    required Size size,
    required double rowHeight,
    required double lanePadding,
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

    // Group tasks by lane.
    final byLane = <String, List<GanttTask>>{};
    for (final lane in lanes) {
      byLane[lane] = [];
    }
    for (final t in tasks) {
      final lane = t.lane ?? '';
      if (byLane.containsKey(lane)) {
        byLane[lane]!.add(t);
      }
    }

    final tasksOrdered = <GanttTask>[];
    final bars = <_SwimBar>[];
    final laneRects = <Rect>[];
    final idIndex = <String, int>{};

    var cursorY = top;
    for (final lane in lanes) {
      final laneTasks = byLane[lane] ?? const [];
      final laneRowCount = laneTasks.length;
      final laneInner = laneRowCount * rowHeight;
      final laneRect = Rect.fromLTWH(
        left,
        cursorY,
        right - left,
        laneInner + lanePadding,
      );
      laneRects.add(laneRect);

      for (var ri = 0; ri < laneTasks.length; ri++) {
        final t = laneTasks[ri];
        final cy = cursorY + lanePadding / 2 + rowHeight * (ri + 0.5);
        final x0 = left + (t.start - xMin) / (xMax - xMin) * (right - left);
        final x1 = left + (t.end - xMin) / (xMax - xMin) * (right - left);
        idIndex[t.id] = tasksOrdered.length;
        tasksOrdered.add(t);
        bars.add(
          _SwimBar(
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
      cursorY += laneInner + lanePadding;
    }

    return _SwimLayout(
      bars: bars,
      tasksOrdered: tasksOrdered,
      laneRects: laneRects,
      idIndex: idIndex,
      left: left,
      right: right,
      top: top,
      bottom: bottom,
      xMin: xMin,
      xMax: xMax,
    );
  }
}

class _SwimlanePainter extends CustomPainter {
  _SwimlanePainter({
    required this.lanes,
    required this.tasks,
    required this.palette,
    required this.barHeight,
    required this.rowHeight,
    required this.lanePadding,
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

  final List<String> lanes;
  final List<GanttTask> tasks;
  final List<Color> palette;
  final double barHeight;
  final double rowHeight;
  final double lanePadding;
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
    final layout = _SwimLayout.compute(
      lanes: lanes,
      tasks: tasks,
      size: size,
      rowHeight: rowHeight,
      lanePadding: lanePadding,
      barHeight: barHeight,
    );
    if (layout == null) return;

    // Lane bg + header.
    for (var li = 0; li < lanes.length; li++) {
      final r = layout.laneRects[li];
      final laneColor = palette[li % palette.length];
      canvas.drawRect(
        r,
        Paint()..color = laneColor.withValues(alpha: 0.06),
      );
      // Lane separator line.
      canvas.drawLine(
        Offset(r.left, r.bottom),
        Offset(r.right, r.bottom),
        Paint()
          ..color = gridColor.withValues(alpha: 0.3)
          ..strokeWidth = 0.5,
      );
      // Lane label in left gutter — fade in early + smoothly.
      if (showLabels && progress > 0.05) {
        final fadeRaw = ((progress - 0.05) / 0.5).clamp(0.0, 1.0);
        final fade = Curves.easeOutCubic.transform(fadeRaw);
        final tp = TextPainter(
          text: TextSpan(
            text: lanes[li],
            style: axisStyle.copyWith(
              color: laneColor.withValues(alpha: fade * 0.92),
              fontWeight: FontWeight.w700,
              letterSpacing: 0.4,
              shadows: const [],
            ),
          ),
          textDirection: TextDirection.ltr,
          maxLines: 2,
          ellipsis: '…',
        )..layout(maxWidth: layout.left - 8);
        tp.paint(
          canvas,
          Offset(8, r.center.dy - tp.height / 2),
        );
      }
    }

    // Bars.
    for (var i = 0; i < layout.tasksOrdered.length; i++) {
      final t = layout.tasksOrdered[i];
      final r = layout.bars[i].rect;
      final laneIdx = lanes.indexOf(t.lane ?? '');
      final c = t.color ?? palette[laneIdx.clamp(0, palette.length - 1)];

      final rowDelay = i / layout.tasksOrdered.length * 0.25;
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
      if (showProgress && t.progress > 0) {
        final pr = Rect.fromLTRB(
          r.left,
          r.top,
          r.left + r.width * t.progress * drawT,
          r.bottom,
        );
        canvas.drawRRect(
          RRect.fromRectAndRadius(pr, const Radius.circular(4)),
          Paint()..color = c.withValues(alpha: opacity),
        );
      }
      canvas.drawRRect(
        rr,
        Paint()
          ..color = c.withValues(alpha: opacity)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.0,
      );

      // Task label — pick text color from bar luminance so it
      // reads on both the tinted backdrop and the progress fill.
      // If the bar is too narrow for the label, render to the
      // right of the bar where plain bg is reliable.
      if (showLabels && drawT > 0.1) {
        final fadeRaw = ((drawT - 0.1) / 0.9).clamp(0.0, 1.0);
        final fade = Curves.easeOutCubic.transform(fadeRaw);
        final lum = c.computeLuminance();
        final inBarColor = lum > 0.55
            ? const Color(0xFF1A1A1A)
            : const Color(0xFFF4F4F4);
        // Try to fit inside.
        final inside = TextPainter(
          text: TextSpan(
            text: t.label,
            style: axisStyle.copyWith(
              color: inBarColor.withValues(alpha: fade),
              fontWeight: FontWeight.w600,
              fontSize: (axisStyle.fontSize ?? 11) - 1,
              shadows: const [],
            ),
          ),
          textDirection: TextDirection.ltr,
          maxLines: 1,
          ellipsis: '…',
        )..layout(maxWidth: r.width - 8);
        if (inside.width <= r.width - 8 && r.width > 40) {
          inside.paint(
            canvas,
            Offset(r.left + 4, r.center.dy - inside.height / 2),
          );
        } else {
          // Too narrow — render outside (right of bar).
          final outside = TextPainter(
            text: TextSpan(
              text: t.label,
              style: axisStyle.copyWith(
                color: fg.withValues(alpha: fade * 0.92),
                fontWeight: FontWeight.w600,
                fontSize: (axisStyle.fontSize ?? 11) - 1,
                shadows: const [],
              ),
            ),
            textDirection: TextDirection.ltr,
            maxLines: 1,
            ellipsis: '…',
          )..layout(maxWidth: 160);
          outside.paint(
            canvas,
            Offset(r.right + 6, r.center.dy - outside.height / 2),
          );
        }
      }
    }

    // Dependency arrows.
    if (showDependencies && progress > 0.6) {
      final fade = ((progress - 0.6) / 0.4).clamp(0.0, 1.0);
      for (var i = 0; i < layout.tasksOrdered.length; i++) {
        final t = layout.tasksOrdered[i];
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
            ..strokeCap = StrokeCap.round
            ..style = PaintingStyle.stroke;
          canvas.drawLine(start, Offset(midX, start.dy), paint);
          canvas.drawLine(Offset(midX, start.dy), Offset(midX, end.dy), paint);
          canvas.drawLine(Offset(midX, end.dy), end, paint);
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
  bool shouldRepaint(covariant _SwimlanePainter old) =>
      old.progress != progress ||
      old.tasks != tasks ||
      old.lanes != lanes ||
      old.animation != animation;
}
