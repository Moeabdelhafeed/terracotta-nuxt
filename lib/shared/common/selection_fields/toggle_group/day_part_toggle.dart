import 'package:flutter/material.dart';

import '../../../../core/localization/strings/module_strings.dart';
import '../../../module/toggle_group/global_toggle_group.dart';

/// Coarse time-of-day windows.
enum DayPart { morning, afternoon, evening, night }

/// Morning / afternoon / evening / night picker — booking slots,
/// reminder windows, delivery preferences. Multi-select, localized.
class DayPartToggle extends StatelessWidget {
  const DayPartToggle({
    super.key,
    required this.selected,
    required this.onChanged,
    this.style = const ToggleGroupStyle(),
    this.enabled = true,
  });

  final List<DayPart> selected;
  final ValueChanged<List<DayPart>> onChanged;
  final ToggleGroupStyle style;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    // Locale dependency — labels resolve via Tr/S (static reads).
    Localizations.maybeLocaleOf(context);
    return GlobalToggleGroup<DayPart>(
      items: [
        ToggleGroupItem(
          value: DayPart.morning,
          label: ToggleGroupStrings.daypartMorning,
        ),
        ToggleGroupItem(
          value: DayPart.afternoon,
          label: ToggleGroupStrings.daypartAfternoon,
        ),
        ToggleGroupItem(
          value: DayPart.evening,
          label: ToggleGroupStrings.daypartEvening,
        ),
        ToggleGroupItem(
          value: DayPart.night,
          label: ToggleGroupStrings.daypartNight,
        ),
      ],
      selectedValues: selected,
      onChanged: onChanged,
      multiSelect: true,
      // Dense — four buttons, "Afternoon" is wide on a phone.
      style: const ToggleGroupStyle(
        itemPadding: EdgeInsets.symmetric(horizontal: 4),
      ).mergedWith(style),
      enabled: enabled,
    );
  }
}
