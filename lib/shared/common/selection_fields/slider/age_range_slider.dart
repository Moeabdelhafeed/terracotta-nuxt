import 'package:flutter/material.dart';

import '../../../../core/localization/number_formatter.dart';
import '../../../../core/localization/strings/module_strings.dart';
import 'settings_range_row.dart';

/// An age filter, in whole years.
///
/// Localized (en + ar) preset over [SettingsRangeRow].
class AgeRangeSlider extends StatelessWidget {
  const AgeRangeSlider({
    super.key,
    required this.values,
    required this.onChanged,
    this.min = 18,
    this.max = 80,
    this.onChangeEnd,
    this.enabled = true,
    this.dense = false,
    this.showIcon = true,
  });

  final RangeValues values;
  final ValueChanged<RangeValues>? onChanged;

  /// 18 by default — the commonest floor, and the one a caller who
  /// wants another will pass.
  final double min;
  final double max;

  final ValueChanged<double>? onChangeEnd;
  final bool enabled;
  final bool dense;
  final bool showIcon;

  @override
  Widget build(BuildContext context) {
    Localizations.maybeLocaleOf(context);

    return SettingsRangeRow(
      title: SliderStrings.ageRange,
      leading: showIcon ? Icons.cake_outlined : null,
      min: min,
      max: max,
      values: values,
      // Whole years: half an age is not a thing anyone filters by.
      divisions: (max - min).round(),
      enabled: enabled,
      dense: dense,
      onChanged: onChanged,
      onChangeEnd: onChangeEnd,
      valueFormatter: (v) => AppNumbers.decimal(v, fractionDigits: 0),
      minLabel:
          '${AppNumbers.decimal(min, fractionDigits: 0)} '
          '${SliderStrings.years}',
      maxLabel:
          '${AppNumbers.decimal(max, fractionDigits: 0)} '
          '${SliderStrings.years}',
    );
  }
}
