import 'package:flutter/material.dart';

import '../../../core/extensions/theme_colors_extension.dart';
import '../image/global_image.dart';
import 'chart_models.dart';

/// Token-themed chart legend. Renders one chip per series with a
/// color swatch + name. RTL-aware via ambient `Directionality`.
class ChartLegend extends StatelessWidget {
  const ChartLegend({
    required this.entries,
    this.position = ChartLegendPosition.bottom,
    super.key,
  });

  final List<ChartLegendEntry> entries;
  final ChartLegendPosition position;

  @override
  Widget build(BuildContext context) {
    if (entries.isEmpty || position == ChartLegendPosition.hidden) {
      return const SizedBox.shrink();
    }

    // Use labelMedium for slightly more presence, keep w600 for
    // legibility, inherit app font family via theme.
    final textStyle = Theme.of(context).textTheme.labelMedium?.copyWith(
      color: context.textColors.primary,
      fontWeight: FontWeight.w600,
      height: 1.1,
      letterSpacing: 0.1,
    );

    final chips = entries
        .map((e) => _LegendChip(entry: e, textStyle: textStyle))
        .toList(growable: false);

    final isVertical =
        position == ChartLegendPosition.left ||
        position == ChartLegendPosition.right;

    if (isVertical) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final chip in chips)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: chip,
            ),
        ],
      );
    }

    return Wrap(
      spacing: 14,
      runSpacing: 8,
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: chips,
    );
  }
}

@immutable
class ChartLegendEntry {
  const ChartLegendEntry({
    required this.label,
    required this.color,
    this.icon,
    this.iconAsset,
    this.iconWidget,
  });

  final String label;
  final Color color;

  /// Optional icon to show before the label. Tinted with [color]
  /// unless overridden by a wrapping `IconTheme`.
  final IconData? icon;

  /// Optional asset path for an image icon (PNG/JPG/SVG). When set
  /// and [iconWidget] is null, renders an `Image.asset(...)` sized
  /// to match the swatch.
  final String? iconAsset;

  /// Fully custom icon widget — wins over [icon] / [iconAsset].
  /// Use for `Image.network`, `SvgPicture.asset`, custom shapes, etc.
  final Widget? iconWidget;
}

class _LegendChip extends StatelessWidget {
  const _LegendChip({required this.entry, required this.textStyle});

  final ChartLegendEntry entry;
  final TextStyle? textStyle;

  @override
  Widget build(BuildContext context) {
    final bg = context.backgroundColors.container;
    final border = context.backgroundColors.outlineVariant;

    return Container(
      padding: const EdgeInsets.fromLTRB(8, 4, 10, 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: border, width: 0.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _LegendMark(entry: entry),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              entry.label,
              style: textStyle,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class _LegendMark extends StatelessWidget {
  const _LegendMark({required this.entry});

  final ChartLegendEntry entry;

  @override
  Widget build(BuildContext context) {
    const size = 14.0;
    final widget =
        entry.iconWidget ??
        (entry.iconAsset != null
            ? GlobalImage.a(entry.iconAsset!, width: size, height: size)
            : entry.icon != null
            ? Icon(entry.icon, size: size, color: entry.color)
            : null);
    if (widget != null) {
      return SizedBox(width: size, height: size, child: widget);
    }
    return Container(
      width: 12,
      height: 12,
      decoration: BoxDecoration(
        color: entry.color,
        borderRadius: BorderRadius.circular(3),
      ),
    );
  }
}
