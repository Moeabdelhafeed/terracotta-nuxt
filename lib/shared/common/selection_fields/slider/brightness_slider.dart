import 'package:flutter/material.dart';

import '../../../../core/localization/number_formatter.dart';
import '../../../../core/localization/strings/module_strings.dart';
import 'settings_slider_row.dart';

/// Screen brightness, 0–100%.
///
/// Localized (en + ar) preset over [SettingsSliderRow].
class BrightnessSlider extends StatelessWidget {
  const BrightnessSlider({
    super.key,
    required this.value,
    required this.onChanged,
    this.onChangeEnd,
    this.enabled = true,
    this.dense = false,
    this.showIcon = true,
  });

  /// 0–100.
  final double value;
  final ValueChanged<double>? onChanged;
  final ValueChanged<double>? onChangeEnd;
  final bool enabled;
  final bool dense;
  final bool showIcon;

  @override
  Widget build(BuildContext context) {
    Localizations.maybeLocaleOf(context);

    return SettingsSliderRow(
      title: SliderStrings.brightness,
      leading: showIcon
          ? (value < 50
                ? Icons.brightness_low_rounded
                : Icons.brightness_high_rounded)
          : null,
      min: 0,
      max: 100,
      value: value,
      enabled: enabled,
      dense: dense,
      onChanged: onChanged,
      onChangeEnd: onChangeEnd,
      valueFormatter: (v) => AppNumbers.percent(v / 100, fractionDigits: 0),
    );
  }
}
