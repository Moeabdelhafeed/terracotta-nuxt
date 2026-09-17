import 'package:flutter/material.dart';

import '../../../core/extensions/theme_colors_extension.dart';
import '../../../core/localization/number_formatter.dart';
import 'chart_data.dart';
import 'chart_models.dart';
import 'chart_tooltip_overlay.dart';
import 'custom_paint_tooltip.dart';

export 'chart_data.dart' show BulletDatum;
export 'chart_models.dart' show ChartStyle;

/// Bullet chart — KPI gauge with target marker + qualitative bands.
/// Each row shows: gray-scale bands (poor/ok/good ranges), a thin
/// foreground bar (actual value), a vertical tick (target), and an
/// optional second tick (comparative measure).
///
/// ```dart
/// GlobalBullet(
///   data: [
///     BulletDatum(
///       label: 'Revenue',
///       value: 270,
///       target: 300,
///       ranges: [200, 250, 300],
///       comparative: 240,
///       unit: 'K',
///     ),
///   ],
/// )
/// ```
class GlobalBullet extends StatelessWidget {
  const GlobalBullet({
    required this.data,
    this.style = ChartStyle.standard,
    this.rowHeight = 36,
    this.rowGap = 12,
    this.barHeight = 14,
    this.labelWidth = 100,
    this.valueFormatter,
    super.key,
  });

  final List<BulletDatum> data;
  final ChartStyle style;
  final double rowHeight;
  final double rowGap;
  final double barHeight;

  /// Width reserved on the left for the row label.
  final double labelWidth;

  final String Function(double)? valueFormatter;

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final fmt = valueFormatter ?? (v) => AppNumbers.compact(v);
    final fillColor = context.primaryColors.primary;
    final trackColor = context.backgroundColors.outlineVariant;
    final textPrimary = context.textColors.primary;
    final textSecondary = context.textColors.secondary;

    return Padding(
      padding: style.padding,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < data.length; i++) ...[
            if (i > 0) SizedBox(height: rowGap),
            SizedBox(
              height: rowHeight,
              child: Row(
                children: [
                  SizedBox(
                    width: labelWidth,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          data[i].label,
                          style: theme.textTheme.labelLarge?.copyWith(
                            color: textPrimary,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          '${fmt(data[i].value)}${data[i].unit}',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: textSecondary,
                            fontFeatures: const [FontFeature.tabularFigures()],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: CustomPaintTooltipOverlay(
                      hitTest: (pos, size) => _hitTest(
                        pos,
                        size,
                        data[i],
                        data[i].color ?? fillColor,
                        fmt,
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
                            painter: _BulletRowPainter(
                              datum: data[i],
                              fillColor: data[i].color ?? fillColor,
                              trackColor: trackColor,
                              barHeight: barHeight,
                              progress: t,
                            ),
                            size: Size.infinite,
                          );
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// Hit-test for one row. Single tooltip entry per row showing the
  /// label, current value, target — surfaced when the pointer is
  /// over the row's bar / band region.
  List<TooltipEntry> _hitTest(
    Offset pos,
    Size size,
    BulletDatum d,
    Color color,
    String Function(double) fmt,
  ) {
    if (pos.dx < 0 || pos.dx > size.width) return const [];
    if (pos.dy < 0 || pos.dy > size.height) return const [];
    final maxVal = d.ranges.isEmpty ? 0.0 : d.ranges.last;
    final pct = maxVal == 0
        ? 0.0
        : (d.value / maxVal * 100).clamp(0.0, double.infinity);
    return [
      TooltipEntry(
        label: d.label,
        value:
            '${fmt(d.value)}${d.unit} / ${fmt(d.target)}${d.unit} '
            '(${pct.toStringAsFixed(0)}%)',
        color: color,
      ),
    ];
  }
}

class _BulletRowPainter extends CustomPainter {
  _BulletRowPainter({
    required this.datum,
    required this.fillColor,
    required this.trackColor,
    required this.barHeight,
    required this.progress,
  });

  final BulletDatum datum;
  final Color fillColor;
  final Color trackColor;
  final double barHeight;
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;
    final ranges = datum.ranges;
    if (ranges.isEmpty) return;
    final maxVal = ranges.last;
    if (maxVal <= 0) return;

    final cy = size.height / 2;
    final trackTop = cy - size.height * 0.35;
    final trackBottom = cy + size.height * 0.35;

    // Qualitative bands (gray scale) — darker = poorer band.
    var lastEnd = 0.0;
    for (var i = 0; i < ranges.length; i++) {
      final end = ranges[i] / maxVal * size.width;
      final shade =
          0.32 + (i / (ranges.length - 1).clamp(1, double.infinity)) * 0.55;
      canvas.drawRect(
        Rect.fromLTRB(lastEnd, trackTop, end, trackBottom),
        Paint()..color = trackColor.withValues(alpha: shade.clamp(0.25, 0.95)),
      );
      lastEnd = end;
    }

    // Foreground bar — the actual value.
    final barTop = cy - barHeight / 2;
    final barBottom = cy + barHeight / 2;
    final barEnd = (datum.value / maxVal * size.width * progress).clamp(
      0.0,
      size.width,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTRB(0, barTop, barEnd, barBottom),
        const Radius.circular(2),
      ),
      Paint()..color = fillColor,
    );

    // Target tick — vertical line at the target position.
    final targetX = datum.target / maxVal * size.width;
    canvas.drawRect(
      Rect.fromLTWH(targetX - 1, trackTop - 2, 2, trackBottom - trackTop + 4),
      Paint()..color = Colors.black.withValues(alpha: 0.78),
    );

    // Comparative tick — second smaller marker.
    if (datum.comparative != null) {
      final cx = datum.comparative! / maxVal * size.width;
      canvas.drawRect(
        Rect.fromLTWH(cx - 0.75, barTop, 1.5, barBottom - barTop),
        Paint()..color = Colors.black.withValues(alpha: 0.45),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _BulletRowPainter old) =>
      old.progress != progress ||
      old.datum != datum ||
      old.fillColor != fillColor ||
      old.trackColor != trackColor ||
      old.barHeight != barHeight;
}
