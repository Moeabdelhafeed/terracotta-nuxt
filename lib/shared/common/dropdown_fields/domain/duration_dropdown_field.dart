import 'package:flutter/material.dart';

import '../../../../core/localization/strings/drop_down_strings.dart';
import '../../../../core/localization/strings/schedule_strings.dart';
import '../../../module/drop_down/global_drop_down.dart';
import '../generic/simple_dropdown_field.dart';

/// Duration picker over a preset list — the booking / reminder staple
/// ("15 min", "1 h 30 min", "1 d"). Emits a [Duration]; pass your own
/// [durations] to change the ladder. For free-form hh:mm:ss input use
/// `DurationField` (text_form_fields) instead.
class DurationDropdownField extends StatelessWidget {
  const DurationDropdownField({
    super.key,
    required this.value,
    required this.onChanged,
    this.durations = defaultDurations,
    this.label,
    this.hint,
    this.enabled = true,
    this.errorText,
  });

  /// The common booking ladder — override per screen.
  static const List<Duration> defaultDurations = [
    Duration(minutes: 15),
    Duration(minutes: 30),
    Duration(minutes: 45),
    Duration(hours: 1),
    Duration(hours: 1, minutes: 30),
    Duration(hours: 2),
    Duration(hours: 3),
    Duration(hours: 4),
    Duration(hours: 6),
    Duration(hours: 8),
    Duration(hours: 12),
    Duration(days: 1),
  ];

  final Duration? value;
  final ValueChanged<Duration?>? onChanged;

  /// The offered ladder. Shrinking it after a pick doesn't clear an
  /// already-seeded selection — the parent owns clearing its stored
  /// value.
  final List<Duration> durations;
  final String? label;
  final String? hint;
  final bool enabled;
  final String? errorText;

  /// Humanized label — whole days as "N d", then "H h M min" composed
  /// from the localized unit strings. Positive durations only (Dart's
  /// truncating division would silently drop the sign: -30 min would
  /// render "30 min").
  static String labelFor(Duration d) {
    assert(!d.isNegative, 'labelFor expects a non-negative duration');
    if (d.inDays >= 1 && d.inMinutes == d.inDays * 24 * 60) {
      return DurationStrings.days(d.inDays);
    }
    final h = d.inHours;
    final m = d.inMinutes % 60;
    if (h == 0) return DurationStrings.minutes(m);
    if (m == 0) return DurationStrings.hours(h);
    return DurationStrings.hoursMinutes(h, m);
  }

  /// Canonical duration row.
  static DropdownItem<Duration> itemFor(Duration d) =>
      DropdownItem(value: d, label: labelFor(d));

  @override
  Widget build(BuildContext context) {
    return SimpleDropdownField<Duration>(
      items: durations.map(itemFor).toList(),
      value: value,
      onChanged: onChanged,
      label: label ?? DropDownStrings.durationLabel,
      hint: hint ?? DropDownStrings.durationHint,
      enabled: enabled,
      errorText: errorText,
    );
  }
}
