import 'package:flutter/material.dart';

import '../../../core/extensions/theme_colors_extension.dart';
import 'chart_data.dart';
import 'chart_internals.dart';
import 'chart_models.dart';
import 'chart_tooltip_overlay.dart';
import 'chart_zoom_pan.dart';
import 'custom_paint_tooltip.dart';

export 'chart_data.dart' show BumpRow, ChartPoint;
export 'chart_models.dart' show ChartStyle, BumpAnimation;

/// Bump chart — rank changes over time. Each [BumpRow]'s line
/// shows where that contender ranks at each x-slot. Lower x runs
/// left, lower rank renders higher.
///
/// The chart converts raw values to ranks per time-slot — pass any
/// numeric values and the higher-is-better ordering is applied.
///
/// ```dart
/// GlobalBumpChart(
///   rows: [
///     BumpRow(label: 'A', points: [ChartPoint(0, 80), ChartPoint(1, 92), ...]),
///     BumpRow(label: 'B', points: [ChartPoint(0, 70), ChartPoint(1, 85), ...]),
///   ],
/// )
/// ```
class GlobalBumpChart extends StatelessWidget {
  const GlobalBumpChart({
    required this.rows,
    this.style = ChartStyle.standard,
    this.animation = BumpAnimation.draw,
    this.smooth = true,
    this.lineWidth = 3.0,
    this.dotRadius = 5.0,
    this.showLabels = true,
    this.showRanks = false,
    this.invertRanks = false,
    super.key,
  });

  final List<BumpRow> rows;
  final ChartStyle style;
  final BumpAnimation animation;
  final bool smooth;
  final double lineWidth;
  final double dotRadius;
  final bool showLabels;
  final bool showRanks;

  /// When `true`, lower raw values rank HIGHER (e.g. golf scores).
  /// Default: higher values rank higher.
  final bool invertRanks;

  @override
  Widget build(BuildContext context) {
    if (rows.isEmpty) return const SizedBox.shrink();
    final palette = resolveSeriesColors(context, style, rows.length);
    final axisStyle = resolveAxisLabelStyle(context, style);
    final gridColor = resolveGridColor(context, style);
    final fg = context.textColors.primary;

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
                hitTest: (pos, size) => _hitTest(pos, size, palette),
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
                      painter: _BumpPainter(
                        rows: rows,
                        colors: palette,
                        smooth: smooth,
                        lineWidth: lineWidth,
                        dotRadius: dotRadius,
                        showLabels: showLabels,
                        showRanks: showRanks,
                        invertRanks: invertRanks,
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
      ),
      style,
    );
  }

  List<TooltipEntry> _hitTest(
    Offset pos,
    Size size,
    List<Color> palette,
  ) {
    final layout = _BumpLayout.compute(
      rows: rows,
      size: size,
      invertRanks: invertRanks,
    );
    if (layout == null) return const [];
    if (pos.dx < layout.left || pos.dx > layout.right) return const [];
    var bestI = -1;
    var bestDy = double.infinity;
    final t = (pos.dx - layout.left) / (layout.right - layout.left);
    final col = (t * (layout.timeCount - 1)).round().clamp(
      0,
      layout.timeCount - 1,
    );
    for (var ri = 0; ri < rows.length; ri++) {
      final rank = layout.rankAt[ri][col];
      if (rank < 0) continue;
      final y = layout.yForRank(rank);
      final d = (y - pos.dy).abs();
      if (d < bestDy) {
        bestDy = d;
        bestI = ri;
      }
    }
    if (bestI < 0 || bestDy > 18) return const [];
    final r = rows[bestI];
    final rank = layout.rankAt[bestI][col];
    return [
      TooltipEntry(
        label: r.label,
        value: 'rank ${rank + 1}',
        color: r.color ?? palette[bestI],
        icon: r.icon,
        iconAsset: r.iconAsset,
        iconWidget: r.iconWidget,
      ),
    ];
  }
}

class _BumpLayout {
  _BumpLayout({
    required this.timeXs,
    required this.rankAt,
    required this.left,
    required this.right,
    required this.top,
    required this.bottom,
    required this.timeCount,
    required this.rankCount,
  });

  final List<double> timeXs;

  /// Per row, per time-slot index: 0-based rank (-1 = no data).
  final List<List<int>> rankAt;
  final double left;
  final double right;
  final double top;
  final double bottom;
  final int timeCount;
  final int rankCount;

  double yForRank(int rank) {
    if (rankCount <= 1) return (top + bottom) / 2;
    return top + rank / (rankCount - 1) * (bottom - top);
  }

  static _BumpLayout? compute({
    required List<BumpRow> rows,
    required Size size,
    required bool invertRanks,
  }) {
    if (size.width <= 0 || size.height <= 0) return null;
    if (rows.isEmpty) return null;
    // Collect all unique x values across rows.
    final xs = <double>{};
    for (final r in rows) {
      for (final p in r.points) {
        xs.add(p.x);
      }
    }
    if (xs.isEmpty) return null;
    final times = xs.toList()..sort();
    const leftPad = 80.0;
    const rightPad = 80.0;
    const topPad = 24.0;
    const bottomPad = 24.0;
    const left = leftPad;
    final right = size.width - rightPad;
    const top = topPad;
    final bottom = size.height - bottomPad;
    final timeCount = times.length;
    final timeXs = List<double>.generate(timeCount, (i) {
      if (timeCount == 1) return (left + right) / 2;
      return left + i / (timeCount - 1) * (right - left);
    });

    // Per row, per time-slot: lookup value (interp not needed —
    // assume each row provides values at the shared time slots,
    // missing = -infinity → no rank).
    final values = <List<double?>>[];
    for (final r in rows) {
      final sorted = [...r.points]..sort((a, b) => a.x.compareTo(b.x));
      final row = <double?>[];
      for (final t in times) {
        final idx = sorted.indexWhere((p) => p.x == t);
        row.add(idx >= 0 ? sorted[idx].y : null);
      }
      values.add(row);
    }

    // Per time-slot: compute ranks.
    final rankAt = <List<int>>[
      for (var i = 0; i < rows.length; i++) List<int>.filled(timeCount, -1),
    ];
    for (var t = 0; t < timeCount; t++) {
      final indexed = <(int, double)>[];
      for (var ri = 0; ri < rows.length; ri++) {
        final v = values[ri][t];
        if (v == null) continue;
        indexed.add((ri, v));
      }
      indexed.sort(
        (a, b) => invertRanks ? a.$2.compareTo(b.$2) : b.$2.compareTo(a.$2),
      );
      for (var k = 0; k < indexed.length; k++) {
        rankAt[indexed[k].$1][t] = k;
      }
    }

    return _BumpLayout(
      timeXs: timeXs,
      rankAt: rankAt,
      left: left,
      right: right,
      top: top,
      bottom: bottom,
      timeCount: timeCount,
      rankCount: rows.length,
    );
  }
}

class _BumpPainter extends CustomPainter {
  _BumpPainter({
    required this.rows,
    required this.colors,
    required this.smooth,
    required this.lineWidth,
    required this.dotRadius,
    required this.showLabels,
    required this.showRanks,
    required this.invertRanks,
    required this.gridColor,
    required this.axisStyle,
    required this.fg,
    required this.animation,
    required this.progress,
  });

  final List<BumpRow> rows;
  final List<Color> colors;
  final bool smooth;
  final double lineWidth;
  final double dotRadius;
  final bool showLabels;
  final bool showRanks;
  final bool invertRanks;
  final Color gridColor;
  final TextStyle axisStyle;
  final Color fg;
  final BumpAnimation animation;
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final layout = _BumpLayout.compute(
      rows: rows,
      size: size,
      invertRanks: invertRanks,
    );
    if (layout == null) return;

    // Subtle vertical guides per time-slot.
    for (final x in layout.timeXs) {
      canvas.drawLine(
        Offset(x, layout.top),
        Offset(x, layout.bottom),
        Paint()
          ..color = gridColor.withValues(alpha: 0.4)
          ..strokeWidth = 0.5,
      );
    }

    for (var ri = 0; ri < rows.length; ri++) {
      final r = rows[ri];
      final c = r.color ?? colors[ri];
      final ranks = layout.rankAt[ri];

      // Per-row stagger.
      final rowDelay = ri / rows.length * 0.2;
      final rowT = ((progress - rowDelay) / (1 - rowDelay)).clamp(0.0, 1.0);
      var rightCutoff = layout.right;
      var opacity = 1.0;
      switch (animation) {
        case BumpAnimation.draw:
          rightCutoff = layout.left + (layout.right - layout.left) * rowT;
        case BumpAnimation.ripple:
          opacity = rowT;
        case BumpAnimation.fade:
          opacity = progress;
      }

      // Build path through rank positions.
      final path = Path();
      var first = true;
      for (var i = 0; i < layout.timeCount; i++) {
        final rank = ranks[i];
        if (rank < 0) continue;
        final x = layout.timeXs[i];
        if (x > rightCutoff && i > 0) {
          // Interp.
          final prevRank = ranks[i - 1];
          if (prevRank >= 0) {
            final prevX = layout.timeXs[i - 1];
            final t = (rightCutoff - prevX) / (x - prevX);
            final prevY = layout.yForRank(prevRank);
            final cy = layout.yForRank(rank);
            path.lineTo(rightCutoff, prevY + (cy - prevY) * t);
          }
          break;
        }
        final y = layout.yForRank(rank);
        if (first) {
          path.moveTo(x, y);
          first = false;
        } else {
          if (smooth && i > 0) {
            final prevRank = ranks[i - 1];
            if (prevRank >= 0) {
              final prevX = layout.timeXs[i - 1];
              final prevY = layout.yForRank(prevRank);
              final cx = (prevX + x) / 2;
              path.cubicTo(cx, prevY, cx, y, x, y);
            } else {
              path.moveTo(x, y);
            }
          } else {
            path.lineTo(x, y);
          }
        }
      }
      canvas.drawPath(
        path,
        Paint()
          ..color = c.withValues(alpha: opacity)
          ..strokeWidth = lineWidth
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round,
      );

      // Dots at each time-slot.
      for (var i = 0; i < layout.timeCount; i++) {
        final rank = ranks[i];
        if (rank < 0) continue;
        final x = layout.timeXs[i];
        if (x > rightCutoff) break;
        final y = layout.yForRank(rank);
        canvas.drawCircle(
          Offset(x, y),
          dotRadius,
          Paint()..color = c.withValues(alpha: opacity),
        );
        canvas.drawCircle(
          Offset(x, y),
          dotRadius,
          Paint()
            ..color = Colors.white.withValues(alpha: opacity)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.5,
        );

        if (showRanks && progress > 0.7) {
          final fade = ((progress - 0.7) / 0.3).clamp(0.0, 1.0);
          final tp = TextPainter(
            text: TextSpan(
              text: '${rank + 1}',
              style: axisStyle.copyWith(
                color: fg.withValues(alpha: fade),
                fontWeight: FontWeight.w700,
                fontSize: (axisStyle.fontSize ?? 11) - 2,
              ),
            ),
            textDirection: TextDirection.ltr,
          )..layout();
          tp.paint(canvas, Offset(x - tp.width / 2, y - tp.height / 2));
        }
      }

      // Endpoint labels.
      if (showLabels && progress > 0.6) {
        final fade = ((progress - 0.6) / 0.4).clamp(0.0, 1.0);
        final lblStyle = axisStyle.copyWith(
          color: axisStyle.color?.withValues(alpha: fade),
          fontWeight: FontWeight.w600,
        );
        // Left label.
        final firstRank = ranks.firstWhere((r) => r >= 0, orElse: () => -1);
        if (firstRank >= 0) {
          final firstIdx = ranks.indexWhere((r) => r >= 0);
          final y = layout.yForRank(firstRank);
          final tp = TextPainter(
            text: TextSpan(text: r.label, style: lblStyle),
            textDirection: TextDirection.ltr,
            maxLines: 1,
            ellipsis: '…',
          )..layout(maxWidth: 70);
          tp.paint(
            canvas,
            Offset(layout.timeXs[firstIdx] - tp.width - 8, y - tp.height / 2),
          );
        }
        // Right label (if line drew that far).
        var lastRank = -1;
        var lastIdx = -1;
        for (var i = layout.timeCount - 1; i >= 0; i--) {
          if (ranks[i] >= 0 && layout.timeXs[i] <= rightCutoff) {
            lastRank = ranks[i];
            lastIdx = i;
            break;
          }
        }
        if (lastRank >= 0 && lastIdx > 0) {
          final y = layout.yForRank(lastRank);
          final tp = TextPainter(
            text: TextSpan(text: r.label, style: lblStyle),
            textDirection: TextDirection.ltr,
            maxLines: 1,
            ellipsis: '…',
          )..layout(maxWidth: 70);
          tp.paint(
            canvas,
            Offset(layout.timeXs[lastIdx] + 8, y - tp.height / 2),
          );
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant _BumpPainter old) =>
      old.progress != progress ||
      old.rows != rows ||
      old.animation != animation;
}
