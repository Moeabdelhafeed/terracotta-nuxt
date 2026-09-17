import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/di/service_locator.dart';
import '../../../../core/localization/strings/drop_down_strings.dart';
import '../../../../data/services/preferences/locale_service.dart';
import '../../../module/drop_down/global_drop_down.dart';
import '../generic/simple_dropdown_field.dart';

/// Day-of-week picker. Emits `DateTime` weekday ints
/// (`DateTime.monday == 1` … `DateTime.sunday == 7`); labels are
/// localized full names via `DateFormat.EEEE` ("Monday" / "الاثنين").
///
/// Order starts at [firstDay]; when null it follows the locale via
/// `MaterialLocalizations.firstDayOfWeekIndex` (ar → Saturday, en_US →
/// Sunday). That index tracks the `MaterialApp` locale while labels
/// track [LocaleService] — in this template both mirror the same
/// preference.
class WeekdayDropdownField extends StatelessWidget {
  const WeekdayDropdownField({
    super.key,
    required this.value,
    required this.onChanged,
    this.firstDay,
    this.label,
    this.hint,
    this.enabled = true,
    this.errorText,
  }) : assert(
         firstDay == null ||
             (firstDay >= DateTime.monday && firstDay <= DateTime.sunday),
         'firstDay must be a DateTime weekday (1–7).',
       );

  /// Selected weekday (`DateTime.monday` … `DateTime.sunday`).
  final int? value;
  final ValueChanged<int?>? onChanged;

  /// Weekday the list starts on (wraps around). Null → locale default.
  final int? firstDay;

  final String? label;
  final String? hint;
  final bool enabled;
  final String? errorText;

  // 2024-01-01 is a Monday, so Jan 1–7 covers Monday…Sunday in order.
  String _nameFor(int weekday, String? locale) =>
      DateFormat.EEEE(locale).format(DateTime(2024, 1, weekday));

  @override
  Widget build(BuildContext context) {
    final locale = getIt.isRegistered<LocaleService>()
        ? getIt<LocaleService>().languageCode
        : null;
    // firstDayOfWeekIndex is Sunday-zero (0 = Sunday … 6 = Saturday) —
    // remap into DateTime weekday space.
    final index = MaterialLocalizations.of(context).firstDayOfWeekIndex;
    final start = firstDay ?? (index == 0 ? DateTime.sunday : index);
    final items =
        [
              for (var k = 0; k < 7; k++) ((start - 1 + k) % 7) + 1,
            ]
            .map((w) => DropdownItem<int>(value: w, label: _nameFor(w, locale)))
            .toList();
    return SimpleDropdownField<int>(
      items: items,
      value: value,
      onChanged: onChanged,
      label: label ?? DropDownStrings.weekdayLabel,
      hint: hint ?? DropDownStrings.weekdayHint,
      enabled: enabled,
      errorText: errorText,
    );
  }
}
