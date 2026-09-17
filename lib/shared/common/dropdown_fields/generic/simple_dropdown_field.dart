import 'package:flutter/material.dart';

import '../../../../core/localization/strings/drop_down_strings.dart';
import '../../../module/drop_down/global_drop_down.dart';
import '../../../module/text_field/global_text_field.dart';

/// Labeled single-select dropdown — the default pick when the
/// choice set is ≤ ~10 items and known ahead of time.
///
/// Canonical contract: `value` / `onChanged` / `label` / `hint` /
/// `errorText` / `enabled` / `validator` / `infoLabel` +
/// domain-specific fields (here: `items`).
///
/// For search, see `SearchableDropdownField`.
/// For many selections, see `MultiSelectDropdownField`.
/// For remote data, see `AsyncDropdownField`.
class SimpleDropdownField<T> extends StatelessWidget {
  const SimpleDropdownField({
    super.key,
    required this.items,
    required this.value,
    required this.onChanged,
    this.label,
    this.hint,
    this.errorText,
    this.enabled = true,
    this.validator,
    this.infoLabel,
    this.onInfoLabelTap,
    this.showClearButton = false,
    this.autovalidateMode = AutovalidateMode.disabled,
  });

  final List<DropdownItem<T>> items;
  final T? value;
  final ValueChanged<T?>? onChanged;
  final String? label;
  final String? hint;
  final String? errorText;
  final bool enabled;
  final FormFieldValidator<T>? validator;
  final String? infoLabel;
  final VoidCallback? onInfoLabelTap;
  final bool showClearButton;
  final AutovalidateMode autovalidateMode;

  @override
  Widget build(BuildContext context) {
    return GlobalDropdownFormField<T>(
      items: items,
      initialValue: value,
      onChanged: onChanged,
      identifier: label,
      hint: hint ?? DropDownStrings.selectOption,
      enabled: enabled,
      behavior: DropdownBehavior(showClearButton: showClearButton),
      slots: DropdownSlots(
        infoLabel: infoLabel,
        onInfoLabelTap: onInfoLabelTap,
      ),
      validation: DropdownValidation(
        validator: (v) => errorText ?? validator?.call(v),
        mode: autovalidateMode == AutovalidateMode.onUserInteraction
            ? ValidationMode.onInteraction
            : ValidationMode.onSubmit,
      ),
    );
  }
}
