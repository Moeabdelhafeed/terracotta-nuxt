import 'package:flutter/material.dart';

import '../../../../core/localization/strings/drop_down_strings.dart';
import '../../../module/drop_down/global_drop_down.dart';

/// Multi-select dropdown. Caller owns the [values] list and flips
/// it inside [onChanged]. Displays selections as chips in the
/// trigger when [chipDisplay] is true (default).
class MultiSelectDropdownField<T> extends StatelessWidget {
  const MultiSelectDropdownField({
    super.key,
    required this.items,
    required this.values,
    required this.onChanged,
    this.label,
    this.hint,
    this.enabled = true,
    this.enableSearch = true,
    this.chipDisplay = true,
    this.maxSelections,
    this.infoLabel,
    this.onInfoLabelTap,
    this.errorText,
    this.maxHeight = 300,
  });

  final List<DropdownItem<T>> items;
  final List<T> values;
  final ValueChanged<List<T>> onChanged;
  final String? label;
  final String? hint;
  final bool enabled;
  final bool enableSearch;
  final bool chipDisplay;
  final int? maxSelections;
  final String? infoLabel;
  final VoidCallback? onInfoLabelTap;
  final String? errorText;
  final double maxHeight;

  @override
  Widget build(BuildContext context) {
    return GlobalDropdown<T>(
      items: items,
      selectedValues: values,
      onMultiChanged: onChanged,
      multiSelect: true,
      chips: DropdownChips(display: chipDisplay),
      behavior: DropdownBehavior(
        enableSearch: enableSearch,
        maxSelections: maxSelections,
        maxHeight: maxHeight,
      ),
      identifier: label,
      hint: hint ?? DropDownStrings.selectOptions,
      enabled: enabled,
      slots: DropdownSlots(
        infoLabel: infoLabel,
        onInfoLabelTap: onInfoLabelTap,
      ),
      errorText: errorText,
    );
  }
}
