import 'package:flutter/material.dart';

import '../../../core/extensions/theme_colors_extension.dart';
import '../../../core/localization/number_formatter.dart';
import '../icon/global_icon.dart';
import 'chart_data.dart';
import 'chart_internals.dart';
import 'chart_models.dart';

export 'chart_data.dart' show ScorecardEntry, ChartPoint;
export 'chart_models.dart' show ChartStyle, ScorecardAnimation;

/// Scorecard — KPI tile with big primary value, optional delta /
/// trend arrow, and a small sparkline at the bottom. Render one
/// per metric in a grid.
///
/// ```dart
/// GlobalScorecard(
///   entry: ScorecardEntry(
///     label: 'Revenue',
///     value: 24800,
///     delta: 12.4,
///     deltaSuffix: '%',
///     sparkline: [ChartPoint(0, 18), ChartPoint(1, 22), ...],
///   ),
/// )
/// ```
class GlobalScorecard extends StatelessWidget {
  const GlobalScorecard({
    required this.entry,
    this.style = ChartStyle.standard,
    this.animation = ScorecardAnimation.countUp,
    this.height = 140,
    this.borderRadius,
    this.sparkLineWidth = 2.0,
    this.sparkLineOpacity = 0.85,
    this.sparkFillOpacity = 0.18,
    this.upColor,
    this.downColor,
    this.flatColor,
    this.valueFormatter,
    super.key,
  });

  final ScorecardEntry entry;
  final ChartStyle style;
  final ScorecardAnimation animation;
  final double height;
  final BorderRadius? borderRadius;
  final double sparkLineWidth;
  final double sparkLineOpacity;
  final double sparkFillOpacity;
  final Color? upColor;
  final Color? downColor;
  final Color? flatColor;
  final String Function(double)? valueFormatter;

  @override
  Widget build(BuildContext context) {
    final fmt = valueFormatter ?? (v) => AppNumbers.compact(v);
    final fg = context.textColors.primary;
    final secondary = context.textColors.secondary;
    final palette = resolveSeriesColors(context, style, 1);
    final accent = entry.color ?? palette.first;
    final upCol = upColor ?? context.statusColors.success;
    final downCol = downColor ?? context.statusColors.error;
    final flatCol = flatColor ?? secondary;

    final delta = entry.delta;
    Color trendColor;
    IconData trendIcon;
    if (delta == null || delta == 0) {
      trendColor = flatCol;
      trendIcon = Icons.remove_rounded;
    } else if (delta > 0) {
      trendColor = upCol;
      trendIcon = Icons.arrow_upward_rounded;
    } else {
      trendColor = downCol;
      trendIcon = Icons.arrow_downward_rounded;
    }

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: style.enableAnimation ? 0.0 : 1.0, end: 1.0),
      duration: style.enableAnimation
          ? style.effectiveAnimationDuration
          : Duration.zero,
      curve: style.effectiveAnimationCurve,
      builder: (context, t, _) {
        final displayedValue = animation == ScorecardAnimation.countUp
            ? entry.value * t
            : entry.value;
        final valueStr = entry.formattedValue ?? fmt(displayedValue);
        final tile = Container(
          height: height,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: context.backgroundColors.cardBackground,
            borderRadius: borderRadius ?? BorderRadius.circular(14),
            border: Border.all(
              color: context.backgroundColors.outlineVariant,
              width: 0.6,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  if (entry.icon != null) ...[
                    GlobalIcon(
                      icon: entry.icon!,
                      style: IconStyle(
                        size: 16,
                        color: accent,
                        backgroundColor: accent,
                        backgroundOpacity: 0.14,
                        containerShape: IconContainerShape.rounded,
                        padding: const EdgeInsets.all(6),
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                  Expanded(
                    child: Text(
                      entry.label,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: secondary,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Flexible(
                    child: Text(
                      '$valueStr${entry.unit}',
                      style: Theme.of(context).textTheme.headlineMedium
                          ?.copyWith(
                            color: fg,
                            fontWeight: FontWeight.w700,
                            height: 1.1,
                          ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (delta != null) ...[
                    const SizedBox(width: 8),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(trendIcon, size: 14, color: trendColor),
                          const SizedBox(width: 2),
                          Text(
                            '${delta.abs() * t}${entry.deltaSuffix}'
                                .replaceAllMapped(
                                  RegExp(r'\.?0+$'),
                                  (_) => '',
                                ),
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
                                  color: trendColor,
                                  fontWeight: FontWeight.w700,
                                ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
              if (entry.subtitle != null) ...[
                const SizedBox(height: 2),
                Text(
                  entry.subtitle!,
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: secondary),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              const Spacer(),
              if (entry.sparkline.isNotEmpty)
                Expanded(
                  flex: 2,
                  child: CustomPaint(
                    size: Size.infinite,
                    painter: _SparkPainter(
                      points: entry.sparkline,
                      color: accent,
                      lineWidth: sparkLineWidth,
                      lineOpacity: sparkLineOpacity,
                      fillOpacity: sparkFillOpacity,
                      progress: t,
                      animation: animation,
                    ),
                  ),
                ),
            ],
          ),
        );
        switch (animation) {
          case ScorecardAnimation.fade:
            return Opacity(opacity: t, child: tile);
          case ScorecardAnimation.pop:
            return Transform.scale(scale: 0.85 + 0.15 * t, child: tile);
          case ScorecardAnimation.countUp:
            return tile;
        }
      },
    );
  }
}

class _SparkPainter extends CustomPainter {
  _SparkPainter({
    required this.points,
    required this.color,
    required this.lineWidth,
    required this.lineOpacity,
    required this.fillOpacity,
    required this.progress,
    required this.animation,
  });

  final List<ChartPoint> points;
  final Color color;
  final double lineWidth;
  final double lineOpacity;
  final double fillOpacity;
  final double progress;
  final ScorecardAnimation animation;

  @override
  void paint(Canvas canvas, Size size) {
    if (points.isEmpty || size.width <= 0 || size.height <= 0) return;
    final sorted = [...points]..sort((a, b) => a.x.compareTo(b.x));
    var xLo = sorted.first.x;
    var xHi = sorted.last.x;
    if (xHi == xLo) xHi = xLo + 1;
    var yLo = sorted.first.y;
    var yHi = sorted.first.y;
    for (final p in sorted) {
      if (p.y < yLo) yLo = p.y;
      if (p.y > yHi) yHi = p.y;
    }
    if (yHi == yLo) yHi = yLo + 1;
    const padX = 2.0;
    const padY = 4.0;
    final w = size.width - padX * 2;
    final h = size.height - padY * 2;

    Offset proj(ChartPoint p) {
      final tx = (p.x - xLo) / (xHi - xLo);
      final ty = (p.y - yLo) / (yHi - yLo);
      return Offset(padX + tx * w, padY + h - ty * h);
    }

    // Animation handling.
    double drawT;
    double opacity;
    switch (animation) {
      case ScorecardAnimation.countUp:
        // Sparkline draws L→R only after value count starts.
        drawT = ((progress - 0.3) / 0.7).clamp(0.0, 1.0);
        opacity = 1.0;
      case ScorecardAnimation.fade:
        drawT = 1.0;
        opacity = progress;
      case ScorecardAnimation.pop:
        drawT = progress;
        opacity = 1.0;
    }
    final cutoffX = padX + w * drawT;

    final fillPath = Path();
    final strokePath = Path();
    var first = true;
    for (var i = 0; i < sorted.length; i++) {
      final pos = proj(sorted[i]);
      if (pos.dx > cutoffX) {
        // Interp.
        if (i > 0) {
          final prev = proj(sorted[i - 1]);
          final t = (cutoffX - prev.dx) / (pos.dx - prev.dx);
          final y = prev.dy + (pos.dy - prev.dy) * t;
          strokePath.lineTo(cutoffX, y);
          fillPath.lineTo(cutoffX, y);
        }
        break;
      }
      if (first) {
        strokePath.moveTo(pos.dx, pos.dy);
        fillPath.moveTo(pos.dx, padY + h);
        fillPath.lineTo(pos.dx, pos.dy);
        first = false;
      } else {
        final prev = proj(sorted[i - 1]);
        final cx = (prev.dx + pos.dx) / 2;
        strokePath.cubicTo(cx, prev.dy, cx, pos.dy, pos.dx, pos.dy);
        fillPath.cubicTo(cx, prev.dy, cx, pos.dy, pos.dx, pos.dy);
      }
    }
    fillPath.lineTo(cutoffX, padY + h);
    fillPath.close();

    canvas.drawPath(
      fillPath,
      Paint()..color = color.withValues(alpha: fillOpacity * opacity),
    );
    canvas.drawPath(
      strokePath,
      Paint()
        ..color = color.withValues(alpha: lineOpacity * opacity)
        ..strokeWidth = lineWidth
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  bool shouldRepaint(covariant _SparkPainter old) =>
      old.progress != progress ||
      old.points != points ||
      old.animation != animation;
}
