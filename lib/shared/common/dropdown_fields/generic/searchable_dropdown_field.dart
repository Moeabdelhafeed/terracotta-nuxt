import 'package:flutter/material.dart';

import '../../../../core/localization/strings/drop_down_strings.dart';
import '../../../module/drop_down/global_drop_down.dart';
import '../../../module/text_field/global_text_field.dart' show ValidationMode;

/// Single-select with a search input inside the overlay — use when
/// the choice set is > ~10 items or the user knows what they want
/// without scanning the list.
class SearchableDropdownField<T> extends StatelessWidget {
  const SearchableDropdownField({
    super.key,
    required this.items,
    required this.value,
    required this.onChanged,
    this.label,
    this.hint,
    this.searchIdentifier,
    this.errorText,
    this.enabled = true,
    this.validator,
    this.infoLabel,
    this.onInfoLabelTap,
    this.showClearButton = true,
    this.maxHeight = 300,
    this.autovalidateMode = AutovalidateMode.disabled,
  });

  final List<DropdownItem<T>> items;
  final T? value;
  final ValueChanged<T?>? onChanged;
  final String? label;
  final String? hint;

  /// Token matched against each [DropdownItem.label] during search.
  /// Defaults to case-insensitive substring match when null.
  final String? searchIdentifier;

  final String? errorText;
  final bool enabled;
  final FormFieldValidator<T>? validator;
  final String? infoLabel;
  final VoidCallback? onInfoLabelTap;
  final bool showClearButton;
  final double maxHeight;
  final AutovalidateMode autovalidateMode;

  @override
  Widget build(BuildContext context) {
    return GlobalDropdownFormField<T>(
      items: items,
      initialValue: value,
      onChanged: onChanged,
      identifier: label,
      hint: hint ?? DropDownStrings.selectOption,
      behavior: DropdownBehavior(
        enableSearch: true,
        searchIdentifier: searchIdentifier,
        maxHeight: maxHeight,
        showClearButton: showClearButton,
      ),
      enabled: enabled,
      slots: DropdownSlots(
        infoLabel: infoLabel,
        onInfoLabelTap: onInfoLabelTap,
      ),
      validation: DropdownValidation(
        validator: (v) => errorText ?? validator?.call(v),
        mode: autovalidateMode == AutovalidateMode.disabled
            ? ValidationMode.onSubmit
            : ValidationMode.onInteraction,
      ),
    );
  }
}
