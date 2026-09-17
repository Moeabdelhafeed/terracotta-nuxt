import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/di/service_locator.dart';
import '../../../../core/localization/strings/drop_down_strings.dart';
import '../../../../data/services/preferences/locale_service.dart';
import '../../../module/drop_down/global_drop_down.dart';
import '../generic/simple_dropdown_field.dart';

/// Hour picker. Defaults to 24-hour (`0`–`23`); pass
/// [use12HourClock] for a `12 AM` … `11 PM` display that still emits
/// the 24-hour integer.
class HourDropdownField extends StatelessWidget {
  const HourDropdownField({
    super.key,
    required this.value,
    required this.onChanged,
    this.use12HourClock = false,
    this.label,
    this.hint,
    this.enabled = true,
    this.errorText,
  });

  final int? value;
  final ValueChanged<int?>? onChanged;
  final bool use12HourClock;
  final String? label;
  final String? hint;
  final bool enabled;
  final String? errorText;

  @override
  Widget build(BuildContext context) {
    final items = [
      for (var h = 0; h < 24; h++)
        DropdownItem<int>(value: h, label: _format(h)),
    ];
    return SimpleDropdownField<int>(
      items: items,
      value: value,
      onChanged: onChanged,
      label: label ?? DropDownStrings.hourLabel,
      hint: hint ?? DropDownStrings.hourHint,
      enabled: enabled,
      errorText: errorText,
    );
  }

  String _format(int h) {
    if (!use12HourClock) return h.toString().padLeft(2, '0');
    // Locale-aware "1 AM" … "12 PM" (Arabic renders ص / م).
    final locale = getIt.isRegistered<LocaleService>()
        ? getIt<LocaleService>().languageCode
        : null;
    return DateFormat('h a', locale).format(DateTime(2000, 1, 1, h));
  }
}
