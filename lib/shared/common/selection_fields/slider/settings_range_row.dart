import 'package:flutter/material.dart';

import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/extensions/theme_colors_extension.dart';
import '../../../../core/tokens/extensions.dart';
import '../../../module/slider/global_slider.dart';

/// [SettingsSliderRow]'s two-thumbed twin — the shape every filter
/// sheet in the app wants.
///
/// It is a separate widget rather than a flag because the value type
/// changes: one takes a `double` and reports one, this takes a
/// `RangeValues` and reports that, and a row that could be either
/// would hand every caller a nullable of each.
class SettingsRangeRow extends StatelessWidget {
  const SettingsRangeRow({
    super.key,
    required this.values,
    required this.onChanged,
    required this.title,
    required this.min,
    required this.max,
    this.description,
    this.leading,
    this.divisions,
    this.valueFormatter,
    this.semanticFormatter,
    this.minLabel,
    this.maxLabel,
    this.segments = const [],
    this.enabled = true,
    this.dense = false,
    this.showValue = true,
    this.showMinMaxLabels = true,
    this.onChangeEnd,
    this.style,
    this.contentPadding,
  });

  final RangeValues values;
  final ValueChanged<RangeValues>? onChanged;
  final String title;
  final double min;
  final double max;
  final String? description;
  final IconData? leading;
  final int? divisions;
  final String Function(double)? valueFormatter;
  final String Function(double)? semanticFormatter;
  final String? minLabel;
  final String? maxLabel;
  final List<double> segments;
  final bool enabled;
  final bool dense;
  final bool showValue;

  /// On by default here, unlike the single row: a range's badge says
  /// what is SELECTED, and without the end labels there is nothing
  /// saying what the whole scale is.
  final bool showMinMaxLabels;

  final ValueChanged<double>? onChangeEnd;
  final SliderStyle? style;
  final EdgeInsetsGeometry? contentPadding;

  @override
  Widget build(BuildContext context) {
    final isDisabled = !enabled || onChanged == null;

    return Padding(
      padding:
          contentPadding ??
          EdgeInsets.symmetric(
            vertical: dense ? context.spacing.xs : context.spacing.sm,
            horizontal: context.spacing.md,
          ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          GlobalSlider.range(
            label: title,
            // Before the LABEL, in the same row. On its own line it
            // floated above the title with nothing beside it whenever
            // there was no description to share the row with.
            leading: leading == null
                ? null
                : Icon(
                    leading,
                    color: isDisabled
                        ? context.iconColors.secondary
                        : context.iconColors.primary,
                    size: context.iconSizes.md,
                  ),
            min: min,
            max: max,
            rangeValues: values,
            divisions: divisions,
            segments: segments,
            enabled: !isDisabled,
            showValue: showValue,
            showMinMaxLabels: showMinMaxLabels,
            valueFormatter: valueFormatter,
            semanticFormatter: semanticFormatter,
            minLabel: minLabel,
            maxLabel: maxLabel,
            onRangeChanged: onChanged ?? (_) {},
            onChangeEnd: onChangeEnd,
            style: SliderStyle.bare.mergedWith(style),
          ),
          if (description != null)
            Padding(
              // Under the header, indented past nothing: it explains
              // the whole row, not the icon.
              padding: EdgeInsets.only(top: context.spacing.xs),
              child: Text(
                description!,
                style: context.textTheme.bodySmall?.copyWith(
                  color: context.textColors.secondary,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
