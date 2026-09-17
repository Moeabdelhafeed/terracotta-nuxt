import 'package:flutter/material.dart';

import '../../../../core/a11y/contrast_checker.dart';
import '../../../../core/extensions/theme_colors_extension.dart';
import '../../../../core/tokens/extensions.dart';

/// Compact WCAG-contrast readout for a [color]: how it fares as text on white
/// and on black — the measured ratio + the highest level it passes
/// (AAA ≥ 7 · AA ≥ 4.5 · AA-large ≥ 3 · else Fail). Pair it with a color
/// field so designers see readability at a glance.
class ColorContrastInfo extends StatelessWidget {
  const ColorContrastInfo({super.key, required this.color});

  final Color color;

  static String levelFor(double ratio) => ratio >= 7
      ? 'AAA'
      : ratio >= 4.5
      ? 'AA'
      : ratio >= 3
      ? 'AA large'
      : 'Fail';

  Widget _pill(BuildContext context, Color background) {
    final ratio = ContrastChecker.ratio(color, background);
    final meta = background.computeLuminance() > 0.5
        ? Colors.black
        : Colors.white;
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: context.spacing.sm,
        vertical: context.spacing.xs,
      ),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(context.radii.sm),
        border: Border.all(
          color: context.backgroundColors.outline.withValues(alpha: 0.4),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Sample text in the color, on this background.
          Text(
            'Aa',
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w700,
              fontSize: 14,
            ),
          ),
          SizedBox(width: context.spacing.sm),
          Text(
            '${ratio.toStringAsFixed(1)}:1 · ${levelFor(ratio)}',
            style: TextStyle(color: meta.withValues(alpha: 0.9), fontSize: 12),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: context.spacing.sm,
      runSpacing: context.spacing.sm,
      children: [
        _pill(context, Colors.white),
        _pill(context, Colors.black),
      ],
    );
  }
}
