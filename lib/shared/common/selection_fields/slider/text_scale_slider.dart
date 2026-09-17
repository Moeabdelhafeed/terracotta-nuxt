import 'package:flutter/material.dart';

import '../../../../core/localization/number_formatter.dart';
import '../../../../core/localization/strings/module_strings.dart';
import '../../../../data/blocs/preferences/preferences_cubit.dart';
import 'settings_slider_row.dart';

/// The reader's own type scale, as a slider.
///
/// Its bounds are [PreferencesCubit]'s, which is the ONLY range the
/// preference is stored in — `setFontScale` clamps to them, so a
/// slider with any other bounds reports values the cubit silently
/// rewrites.
///
/// It is NOT `AppTypographyScale`. That one is the WINDOW-size
/// multiplier — 1.00 on a phone up to 1.20 on a desktop, chosen by the
/// bucket rather than by a reader — and binding the slider to it made
/// the whole of this widget's range 1.00–1.20, which is a fifth of
/// what the preference actually allows.
///
/// Localized (en + ar) preset over [SettingsSliderRow].
class TextScaleSlider extends StatelessWidget {
  const TextScaleSlider({
    super.key,
    required this.value,
    required this.onChanged,
    this.onChangeEnd,
    this.min = PreferencesCubit.minFontScale,
    this.max = PreferencesCubit.maxFontScale,
    this.divisions = defaultDivisions,
    this.enabled = true,
    this.dense = false,
    this.showIcon = true,
  });

  /// The stored preference — what `PreferencesCubit.setFontScale`
  /// takes.
  final double value;
  final ValueChanged<double>? onChanged;
  final ValueChanged<double>? onChangeEnd;
  final double min;
  final double max;

  /// 5% a step across the default range.
  final int? divisions;

  final bool enabled;
  final bool dense;
  final bool showIcon;

  /// 0.70 → 2.00 in steps of 0.05.
  static const int defaultDivisions = 26;

  @override
  Widget build(BuildContext context) {
    Localizations.maybeLocaleOf(context);

    return SettingsSliderRow(
      title: SliderStrings.textSize,
      leading: showIcon ? Icons.format_size_rounded : null,
      min: min,
      max: max,
      value: value,
      divisions: divisions,
      enabled: enabled,
      dense: dense,
      onChanged: onChanged,
      onChangeEnd: onChangeEnd,
      // The factor is meaningless to a reader; the ENLARGEMENT is not.
      valueFormatter: (v) => AppNumbers.percent(v, fractionDigits: 0),
      minLabel: AppNumbers.percent(min, fractionDigits: 0),
      maxLabel: AppNumbers.percent(max, fractionDigits: 0),
      showMinMaxLabels: true,
    );
  }
}
