import 'package:flutter/material.dart';

import '../../../../core/localization/strings/drop_down_strings.dart';
import '../../../module/drop_down/global_drop_down.dart';

/// Dropdown with visually-separated groups — use when items fall
/// into 2+ categories that help the user scan. Each group has a
/// header + its own list of items.
class GroupedDropdownField<T> extends StatelessWidget {
  const GroupedDropdownField({
    super.key,
    required this.groups,
    required this.value,
    required this.onChanged,
    this.label,
    this.hint,
    this.enabled = true,
    this.enableSearch = false,
    this.errorText,
    this.infoLabel,
    this.onInfoLabelTap,
    this.maxHeight = 320,
  });

  final List<DropdownGroup<T>> groups;
  final T? value;
  final ValueChanged<T?>? onChanged;
  final String? label;
  final String? hint;
  final bool enabled;
  final bool enableSearch;
  final String? errorText;
  final String? infoLabel;
  final VoidCallback? onInfoLabelTap;
  final double maxHeight;

  @override
  Widget build(BuildContext context) {
    return GlobalDropdown<T>(
      // `items` kept non-null for constructor signature; groups take
      // precedence inside the overlay.
      items: const [],
      groups: groups,
      selectedValue: value,
      onChanged: onChanged,
      identifier: label,
      hint: hint ?? DropDownStrings.selectOption,
      enabled: enabled,
      errorText: errorText,
      behavior: DropdownBehavior(
        enableSearch: enableSearch,
        maxHeight: maxHeight,
      ),
      slots: DropdownSlots(
        infoLabel: infoLabel,
        onInfoLabelTap: onInfoLabelTap,
      ),
    );
  }
}
