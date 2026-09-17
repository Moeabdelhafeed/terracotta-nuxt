import 'package:flutter/material.dart';

import '../../../../core/localization/number_formatter.dart';
import '../../../../core/localization/strings/module_strings.dart';
import 'settings_slider_row.dart';

/// Playback speed, on the seven steps every player offers.
///
/// A slider rather than a menu because the reader is comparing
/// neighbours — 1.25× against 1.5× — and a menu makes that two taps
/// and a re-open.
///
/// Localized (en + ar) preset over [SettingsSliderRow].
class PlaybackSpeedSlider extends StatelessWidget {
  const PlaybackSpeedSlider({
    super.key,
    required this.speed,
    required this.onChanged,
    this.onChangeEnd,
    this.enabled = true,
    this.dense = false,
    this.showIcon = true,
  });

  /// One of [speeds]; anything else snaps to the nearest.
  final double speed;
  final ValueChanged<double>? onChanged;
  final ValueChanged<double>? onChangeEnd;
  final bool enabled;
  final bool dense;
  final bool showIcon;

  /// The rungs. Evenly spaced on the TRACK even though they are not
  /// evenly spaced in value — 0.5× to 1× matters as much as 1.5× to
  /// 2×, and a linear track would give the fast half twice the room.
  static const List<double> speeds = [0.5, 0.75, 1, 1.25, 1.5, 1.75, 2];

  static double _speedFor(double index) =>
      speeds[index.round().clamp(0, speeds.length - 1)];

  @override
  Widget build(BuildContext context) {
    Localizations.maybeLocaleOf(context);

    var index = speeds.indexOf(speed).toDouble();
    if (index < 0) {
      // Nearest rung, so a stored 1.3 from an older build still lands
      // somewhere sensible instead of at 0.5.
      index = 0;
      for (var i = 1; i < speeds.length; i++) {
        if ((speeds[i] - speed).abs() < (speeds[index.toInt()] - speed).abs()) {
          index = i.toDouble();
        }
      }
    }

    return SettingsSliderRow(
      title: SliderStrings.playbackSpeed,
      leading: showIcon ? Icons.speed_rounded : null,
      min: 0,
      max: (speeds.length - 1).toDouble(),
      value: index,
      divisions: speeds.length - 1,
      enabled: enabled,
      dense: dense,
      onChanged: onChanged == null ? null : (v) => onChanged!(_speedFor(v)),
      onChangeEnd: onChangeEnd == null
          ? null
          : (v) => onChangeEnd!(_speedFor(v)),
      valueFormatter: (v) =>
          '${AppNumbers.decimal(_speedFor(v), fractionDigits: 2)}×',
    );
  }
}
