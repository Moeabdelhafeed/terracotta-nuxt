import 'package:flutter/material.dart';

import '../../../core/extensions/theme_colors_extension.dart';
import '../../../core/localization/number_formatter.dart';
import 'chart_data.dart';
import 'chart_internals.dart';
import 'chart_models.dart';

export 'chart_data.dart' show PictogramDatum;
export 'chart_models.dart' show ChartStyle, PictogramAnimation;

/// Pictogram chart — icon-array proportions. Each row renders a
/// grid of icons where the count is proportional to its value
/// (one icon per [unitsPerIcon]). Reads instantly without scale
/// interpretation — great for storytelling / KPIs.
///
/// ```dart
/// GlobalPictogram(
///   data: const [
///     PictogramDatum(label: 'Free', value: 80),
///     PictogramDatum(label: 'Pro',  value: 60),
///   ],
///   unitsPerIcon: 5,  // each icon = 5 units
/// )
/// ```
class GlobalPictogram extends StatelessWidget {
  const GlobalPictogram({
    required this.data,
    this.style = ChartStyle.standard,
    this.animation = PictogramAnimation.fillIn,
    this.unitsPerIcon = 1,
    this.iconSize = 18,
    this.iconGap = 4,
    this.columns = 10,
    this.defaultIcon = Icons.person_rounded,
    this.dimColor,
    this.showValues = true,
    this.valueFormatter,
    super.key,
  });

  final List<PictogramDatum> data;
  final ChartStyle style;
  final PictogramAnimation animation;

  /// One icon represents this many real units. The chart paints
  /// `(value / unitsPerIcon).round()` filled icons per row, plus a
  /// trailing partially-filled icon if there's a fractional unit.
  final double unitsPerIcon;

  final double iconSize;
  final double iconGap;

  /// Icons per row.
  final int columns;

  /// Fallback icon when [PictogramDatum.icon] is null.
  final IconData defaultIcon;

  /// Color for unfilled "remainder" icons within the grid. Defaults
  /// to a faint outline.
  final Color? dimColor;

  final bool showValues;
  final String Function(double)? valueFormatter;

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) return const SizedBox.shrink();
    final palette = resolveSeriesColors(context, style, data.length);
    final fmt = valueFormatter ?? (v) => AppNumbers.compact(v);
    final dim =
        dimColor ?? context.textColors.secondary.withValues(alpha: 0.18);

    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          minHeight: style.minHeight,
          maxWidth: resolveChartMaxWidth(context, style),
        ),
        child: Padding(
          padding: style.padding,
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: style.enableAnimation ? 0.0 : 1.0, end: 1.0),
            duration: style.enableAnimation
                ? style.effectiveAnimationDuration
                : Duration.zero,
            curve: style.effectiveAnimationCurve,
            builder: (context, t, _) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (var i = 0; i < data.length; i++)
                    _Row(
                      datum: data[i],
                      color: data[i].color ?? palette[i % palette.length],
                      dimColor: dim,
                      defaultIcon: defaultIcon,
                      unitsPerIcon: unitsPerIcon,
                      iconSize: iconSize,
                      iconGap: iconGap,
                      columns: columns,
                      showValues: showValues,
                      valueFormatter: fmt,
                      animation: animation,
                      progress: t,
                      rowIndex: i,
                      totalRows: data.length,
                    ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({
    required this.datum,
    required this.color,
    required this.dimColor,
    required this.defaultIcon,
    required this.unitsPerIcon,
    required this.iconSize,
    required this.iconGap,
    required this.columns,
    required this.showValues,
    required this.valueFormatter,
    required this.animation,
    required this.progress,
    required this.rowIndex,
    required this.totalRows,
  });

  final PictogramDatum datum;
  final Color color;
  final Color dimColor;
  final IconData defaultIcon;
  final double unitsPerIcon;
  final double iconSize;
  final double iconGap;
  final int columns;
  final bool showValues;
  final String Function(double) valueFormatter;
  final PictogramAnimation animation;
  final double progress;
  final int rowIndex;
  final int totalRows;

  @override
  Widget build(BuildContext context) {
    final units = datum.value / unitsPerIcon;
    final filledFloor = units.floor();
    final partial = units - filledFloor;
    final iconCount = (units.ceil()).clamp(0, 100000);
    // Round up to a multiple of `columns` for the dimmed grid.
    final rows = (iconCount / columns).ceil().clamp(0, 100);
    final totalSlots = rows * columns;

    final rowDelay = rowIndex / totalRows * 0.2;
    final rowT = ((progress - rowDelay) / (1 - rowDelay)).clamp(0.0, 1.0);

    final icon = datum.icon ?? defaultIcon;
    final textTheme = Theme.of(context).textTheme;

    Widget cell(int slotIdx) {
      // How "filled" is this slot for the current animation?
      double slotFill;
      double slotScale;
      double slotOpacity;
      switch (animation) {
        case PictogramAnimation.fillIn:
          // Stagger each slot — fill 0 → 1 over a tiny window per slot.
          final start = (slotIdx / totalSlots) * 0.85;
          slotFill = ((rowT - start) / 0.15).clamp(0.0, 1.0);
          slotScale = 1.0;
          slotOpacity = 1.0;
        case PictogramAnimation.fade:
          slotFill = 1.0;
          slotScale = 1.0;
          slotOpacity = rowT;
        case PictogramAnimation.pop:
          final start = (slotIdx / totalSlots) * 0.7;
          final s = ((rowT - start) / 0.3).clamp(0.0, 1.0);
          slotFill = 1.0;
          slotScale = s;
          slotOpacity = s;
      }

      // Fill state at progress=1 (final state):
      double finalFill;
      if (slotIdx < filledFloor) {
        finalFill = 1.0;
      } else if (slotIdx == filledFloor && partial > 0) {
        finalFill = partial;
      } else {
        finalFill = 0.0;
      }
      // Apply animation fill on top of final.
      final effectiveFill = finalFill * slotFill;

      return SizedBox(
        width: iconSize + iconGap,
        height: iconSize + iconGap,
        child: Center(
          child: Transform.scale(
            scale: slotScale,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Icon(icon, size: iconSize, color: dimColor),
                if (effectiveFill > 0)
                  ClipRect(
                    clipper: _LeftClipClipper(effectiveFill),
                    child: Icon(
                      icon,
                      size: iconSize,
                      color: color.withValues(alpha: slotOpacity),
                    ),
                  ),
              ],
            ),
          ),
        ),
      );
    }

    final gridSlots = List<int>.generate(totalSlots, (k) => k);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Label column.
          SizedBox(
            width: 100,
            child: Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    datum.label,
                    style: textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (showValues)
                    Text(
                      valueFormatter(datum.value),
                      style: textTheme.bodySmall?.copyWith(
                        color: context.textColors.secondary,
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Wrap(
              children: [
                for (final k in gridSlots) cell(k),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LeftClipClipper extends CustomClipper<Rect> {
  _LeftClipClipper(this.fraction);
  final double fraction;
  @override
  Rect getClip(Size size) =>
      Rect.fromLTWH(0, 0, size.width * fraction, size.height);
  @override
  bool shouldReclip(covariant _LeftClipClipper old) => old.fraction != fraction;
}
