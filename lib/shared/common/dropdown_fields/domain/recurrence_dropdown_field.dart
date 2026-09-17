import 'package:flutter/material.dart';

import '../../../../core/localization/strings/drop_down_strings.dart';
import '../../../../core/localization/strings/schedule_strings.dart';
import '../../../module/drop_down/global_drop_down.dart';
import '../generic/simple_dropdown_field.dart';

/// How an event/reminder repeats. [Recurrence.none] is the "does not
/// repeat" sentinel — hide it via
/// [RecurrenceDropdownField.includeNone] when repetition is mandatory.
enum Recurrence { none, daily, weekly, monthly, yearly }

extension RecurrenceLabel on Recurrence {
  String get label => switch (this) {
    Recurrence.none => RecurrenceStrings.none,
    Recurrence.daily => RecurrenceStrings.daily,
    Recurrence.weekly => RecurrenceStrings.weekly,
    Recurrence.monthly => RecurrenceStrings.monthly,
    Recurrence.yearly => RecurrenceStrings.yearly,
  };

  IconData get icon => switch (this) {
    Recurrence.none => Icons.block_rounded,
    Recurrence.daily => Icons.today_rounded,
    Recurrence.weekly => Icons.date_range_rounded,
    Recurrence.monthly => Icons.calendar_month_rounded,
    Recurrence.yearly => Icons.event_repeat_rounded,
  };
}

/// Repeat-cadence picker for reminders / bookings. Labels are
/// localized (`RecurrenceStrings`, en + ar).
class RecurrenceDropdownField extends StatelessWidget {
  const RecurrenceDropdownField({
    super.key,
    required this.value,
    required this.onChanged,
    this.includeNone = true,
    this.label,
    this.hint,
    this.enabled = true,
    this.errorText,
  });

  final Recurrence? value;
  final ValueChanged<Recurrence?>? onChanged;

  /// Offer the "does not repeat" option. Flipping this off after the
  /// user picked [Recurrence.none] doesn't clear the already-seeded
  /// selection — the parent owns clearing its stored value.
  final bool includeNone;

  final String? label;
  final String? hint;
  final bool enabled;
  final String? errorText;

  /// Canonical recurrence row.
  static DropdownItem<Recurrence> itemFor(Recurrence r) => DropdownItem(
    value: r,
    label: r.label,
    leading: Icon(r.icon, size: 20),
  );

  @override
  Widget build(BuildContext context) {
    final options = [
      for (final r in Recurrence.values)
        if (includeNone || r != Recurrence.none) r,
    ];
    return SimpleDropdownField<Recurrence>(
      items: options.map(itemFor).toList(),
      value: value,
      onChanged: onChanged,
      label: label ?? DropDownStrings.recurrenceLabel,
      hint: hint ?? DropDownStrings.recurrenceHint,
      enabled: enabled,
      errorText: errorText,
    );
  }
}
