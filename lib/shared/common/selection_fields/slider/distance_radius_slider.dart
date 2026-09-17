import 'package:flutter/material.dart';

import '../../../../core/localization/number_formatter.dart';
import '../../../../core/localization/strings/module_strings.dart';
import 'settings_slider_row.dart';

/// "Within N km" — the search radius on every map screen.
///
/// Localized (en + ar) preset over [SettingsSliderRow].
class DistanceRadiusSlider extends StatelessWidget {
  const DistanceRadiusSlider({
    super.key,
    required this.value,
    required this.onChanged,
    this.min = 1,
    this.max = 50,
    this.imperial = false,
    this.divisions,
    this.onChangeEnd,
    this.enabled = true,
    this.dense = false,
    this.showIcon = true,
  });

  final double value;
  final ValueChanged<double>? onChanged;
  final double min;
  final double max;

  /// Miles rather than kilometres. It changes the WORD only — the
  /// caller owns the number, because converting one behind its back
  /// would report a radius it never asked for.
  final bool imperial;

  final int? divisions;
  final ValueChanged<double>? onChangeEnd;
  final bool enabled;
  final bool dense;
  final bool showIcon;

  @override
  Widget build(BuildContext context) {
    Localizations.maybeLocaleOf(context);
    final unit = imperial ? SliderStrings.mi : SliderStrings.km;

    return SettingsSliderRow(
      title: SliderStrings.distance,
      leading: showIcon ? Icons.place_outlined : null,
      min: min,
      max: max,
      value: value,
      divisions: divisions ?? (max - min).round(),
      enabled: enabled,
      dense: dense,
      onChanged: onChanged,
      onChangeEnd: onChangeEnd,
      valueFormatter: (v) =>
          '${AppNumbers.decimal(v, fractionDigits: 0)} $unit',
    );
  }
}
