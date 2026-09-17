import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/di/service_locator.dart';
import '../../../../data/services/preferences/locale_service.dart';
import '../../../module/toggle_group/global_toggle_group.dart';

/// Multi-select weekday picker — recurrence rules, business hours,
/// reminder schedules. Emits `DateTime` weekday ints
/// (`DateTime.monday == 1` … `DateTime.sunday == 7`); labels are
/// localized short names via `DateFormat.E`. Order starts at
/// [firstDay]; when null it follows the locale
/// (`MaterialLocalizations.firstDayOfWeekIndex` — ar → Saturday).
class WeekdaysToggleGroup extends StatelessWidget {
  const WeekdaysToggleGroup({
    super.key,
    required this.selected,
    required this.onChanged,
    this.firstDay,
    this.style = const ToggleGroupStyle(),
    this.enabled = true,
  }) : assert(
         firstDay == null ||
             (firstDay >= DateTime.monday && firstDay <= DateTime.sunday),
         'firstDay must be a DateTime weekday (1–7).',
       );

  /// Selected weekdays (`DateTime.monday` … `DateTime.sunday`).
  final List<int> selected;

  final ValueChanged<List<int>> onChanged;

  /// Weekday the row starts on (wraps). Null → locale default.
  final int? firstDay;

  final ToggleGroupStyle style;
  final bool enabled;

  // 2024-01-01 is a Monday, so Jan 1–7 covers Monday…Sunday in order.
  String _nameFor(int weekday, String? locale) =>
      DateFormat.E(locale).format(DateTime(2024, 1, weekday));

  @override
  Widget build(BuildContext context) {
    final locale = getIt.isRegistered<LocaleService>()
        ? getIt<LocaleService>().languageCode
        : null;
    // firstDayOfWeekIndex is Sunday-zero — remap into DateTime space.
    final index = MaterialLocalizations.of(context).firstDayOfWeekIndex;
    final start = firstDay ?? (index == 0 ? DateTime.sunday : index);
    final days = [for (var k = 0; k < 7; k++) ((start - 1 + k) % 7) + 1];
    return GlobalToggleGroup<int>(
      items: [
        for (final d in days)
          ToggleGroupItem(value: d, label: _nameFor(d, locale)),
      ],
      selectedValues: selected,
      onChanged: onChanged,
      multiSelect: true,
      // Compact default padding — 7 buttons at the module's 16px eat a
      // phone-width row and ellipsize every label. Caller style wins.
      style: const ToggleGroupStyle(
        itemPadding: EdgeInsets.symmetric(horizontal: 4),
      ).mergedWith(style),
      enabled: enabled,
    );
  }
}
