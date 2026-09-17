import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/di/service_locator.dart';
import '../../../../core/localization/strings/drop_down_strings.dart';
import '../../../../core/utils/hijri_date.dart';
import '../../../../data/services/preferences/locale_service.dart';
import '../../../module/drop_down/global_drop_down.dart';
import '../generic/simple_dropdown_field.dart';

/// Which month-name set the picker lists.
enum MonthCalendar {
  /// January … December via the active locale's `DateFormat.MMMM`.
  gregorian,

  /// Muharram … Dhu al-Hijjah — Arabic names on an ar UI,
  /// transliterations elsewhere (from [HijriDate]'s name tables).
  hijri,
}

/// Month picker (1–12). Labels are localized via `intl` using the
/// active [LocaleService] locale; [calendar] switches to the Hijri
/// month names. Set [numeric] to display "01 … 12" instead of names.
class MonthDropdownField extends StatelessWidget {
  const MonthDropdownField({
    super.key,
    required this.value,
    required this.onChanged,
    this.calendar = MonthCalendar.gregorian,
    this.numeric = false,
    this.label,
    this.hint,
    this.enabled = true,
    this.errorText,
  });

  final int? value;
  final ValueChanged<int?>? onChanged;

  /// Gregorian (default) or Hijri month names. Ignored when [numeric].
  final MonthCalendar calendar;

  final bool numeric;
  final String? label;
  final String? hint;
  final bool enabled;
  final String? errorText;

  String _nameFor(int month, String? locale) {
    if (calendar == MonthCalendar.hijri) {
      return (locale?.startsWith('ar') ?? false)
          ? HijriDate.monthNamesAr[month - 1]
          : HijriDate.monthNamesEn[month - 1];
    }
    return DateFormat.MMMM(locale).format(DateTime(2000, month));
  }

  @override
  Widget build(BuildContext context) {
    final locale = getIt.isRegistered<LocaleService>()
        ? getIt<LocaleService>().languageCode
        : null;
    final items = [
      for (var m = 1; m <= 12; m++)
        DropdownItem<int>(
          value: m,
          label: numeric ? m.toString().padLeft(2, '0') : _nameFor(m, locale),
        ),
    ];
    return SimpleDropdownField<int>(
      items: items,
      value: value,
      onChanged: onChanged,
      label: label ?? DropDownStrings.monthLabel,
      hint: hint ?? DropDownStrings.monthHint,
      enabled: enabled,
      errorText: errorText,
    );
  }
}
