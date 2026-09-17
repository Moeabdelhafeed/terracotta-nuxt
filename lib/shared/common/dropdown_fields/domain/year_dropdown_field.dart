import 'package:flutter/material.dart';

import '../../../../core/localization/strings/drop_down_strings.dart';
import '../../../module/drop_down/global_drop_down.dart';
import '../generic/searchable_dropdown_field.dart';

/// Year picker — range defaults to `DateTime.now().year` back to
/// `year - 100`. Override [minYear] / [maxYear] for birthday, event,
/// copyright, etc. pickers. [descending] lists newest first (default).
class YearDropdownField extends StatelessWidget {
  const YearDropdownField({
    super.key,
    required this.value,
    required this.onChanged,
    this.minYear,
    this.maxYear,
    this.descending = true,
    this.label,
    this.hint,
    this.enabled = true,
    this.errorText,
  });

  final int? value;
  final ValueChanged<int?>? onChanged;
  final int? minYear;
  final int? maxYear;
  final bool descending;
  final String? label;
  final String? hint;
  final bool enabled;
  final String? errorText;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now().year;
    final max = maxYear ?? now;
    final min = minYear ?? (now - 100);
    final years = [for (var y = min; y <= max; y++) y];
    if (descending) years.sort((a, b) => b.compareTo(a));
    final items = years
        .map((y) => DropdownItem<int>(value: y, label: '$y'))
        .toList();
    return SearchableDropdownField<int>(
      items: items,
      value: value,
      onChanged: onChanged,
      label: label ?? DropDownStrings.yearLabel,
      hint: hint ?? DropDownStrings.yearHint,
      enabled: enabled,
      errorText: errorText,
    );
  }
}
