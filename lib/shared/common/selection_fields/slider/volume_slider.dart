import 'package:flutter/material.dart';

import '../../../../core/localization/number_formatter.dart';
import '../../../../core/localization/strings/module_strings.dart';
import 'settings_slider_row.dart';

/// Volume, 0–100%, with an icon that follows the level.
///
/// Localized (en + ar) preset over [SettingsSliderRow].
class VolumeSlider extends StatelessWidget {
  const VolumeSlider({
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

  /// The speaker beside the title.
  final bool showIcon;

  /// Mute, low, high — the three states a speaker glyph has.
  IconData get _icon => switch (value) {
    <= 0 => Icons.volume_off_rounded,
    < 50 => Icons.volume_down_rounded,
    _ => Icons.volume_up_rounded,
  };

  @override
  Widget build(BuildContext context) {
    // Locale dependency — the title resolves via Tr/S (static reads).
    Localizations.maybeLocaleOf(context);

    return SettingsSliderRow(
      title: SliderStrings.volume,
      leading: showIcon ? _icon : null,
      min: 0,
      max: 100,
      value: value,
      enabled: enabled,
      dense: dense,
      onChanged: onChanged,
      onChangeEnd: onChangeEnd,
      // Zero is not "0%", it is a STATE — and it belongs in the BADGE
      // beside the title, where the number would have been, rather
      // than on a line of its own under the track.
      valueFormatter: (v) => v <= 0
          ? SliderStrings.muted
          : AppNumbers.percent(v / 100, fractionDigits: 0),
    );
  }
}
