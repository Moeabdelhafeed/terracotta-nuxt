import 'package:flutter/material.dart';

import '../../../../core/localization/strings/module_strings.dart';
import 'settings_slider_row.dart';

/// Low / Medium / High / Ultra, as four labelled steps.
///
/// The words are the whole point, so they ride `stepLabels` — which
/// also makes them what a screen reader announces, rather than "2".
///
/// Localized (en + ar) preset over [SettingsSliderRow].
class QualitySlider extends StatelessWidget {
  const QualitySlider({
    super.key,
    required this.level,
    required this.onChanged,
    this.onChangeEnd,
    this.enabled = true,
    this.dense = false,
    this.showIcon = true,
  });

  /// 0 = low … 3 = ultra.
  final int level;
  final ValueChanged<int>? onChanged;
  final ValueChanged<int>? onChangeEnd;
  final bool enabled;
  final bool dense;
  final bool showIcon;

  static List<String> get levels => [
    SliderStrings.qualityLow,
    SliderStrings.qualityMedium,
    SliderStrings.qualityHigh,
    SliderStrings.qualityUltra,
  ];

  @override
  Widget build(BuildContext context) {
    Localizations.maybeLocaleOf(context);

    return SettingsSliderRow(
      title: SliderStrings.quality,
      leading: showIcon ? Icons.high_quality_rounded : null,
      min: 0,
      max: (levels.length - 1).toDouble(),
      value: level.toDouble(),
      divisions: levels.length - 1,
      stepLabels: levels,
      enabled: enabled,
      dense: dense,
      // The words under the track already say it; a badge repeating
      // one of them is the same word twice.
      showValue: false,
      onChanged: onChanged == null ? null : (v) => onChanged!(v.round()),
      onChangeEnd: onChangeEnd == null ? null : (v) => onChangeEnd!(v.round()),
    );
  }
}
