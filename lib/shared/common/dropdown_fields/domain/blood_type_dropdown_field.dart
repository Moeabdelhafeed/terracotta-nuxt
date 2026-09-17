import 'package:flutter/material.dart';

import '../../../../core/localization/strings/drop_down_strings.dart';
import '../../../module/drop_down/global_drop_down.dart';
import '../generic/simple_dropdown_field.dart';

/// The eight ABO/Rh blood groups. Labels are the universal medical
/// notation ("A+", "O−") — locale-agnostic by design, like
/// `ColorFormat.label`.
enum BloodType {
  aPositive,
  aNegative,
  bPositive,
  bNegative,
  abPositive,
  abNegative,
  oPositive,
  oNegative,
}

extension BloodTypeLabel on BloodType {
  String get label => switch (this) {
    BloodType.aPositive => 'A+',
    BloodType.aNegative => 'A−',
    BloodType.bPositive => 'B+',
    BloodType.bNegative => 'B−',
    BloodType.abPositive => 'AB+',
    BloodType.abNegative => 'AB−',
    BloodType.oPositive => 'O+',
    BloodType.oNegative => 'O−',
  };
}

/// Blood-group picker — medical/KYC profile staple. Only the field
/// chrome (label / hint) localizes; the group notation itself is
/// universal.
class BloodTypeDropdownField extends StatelessWidget {
  const BloodTypeDropdownField({
    super.key,
    required this.value,
    required this.onChanged,
    this.label,
    this.hint,
    this.enabled = true,
    this.errorText,
  });

  final BloodType? value;
  final ValueChanged<BloodType?>? onChanged;
  final String? label;
  final String? hint;
  final bool enabled;
  final String? errorText;

  /// Canonical blood-group row.
  static DropdownItem<BloodType> itemFor(BloodType t) => DropdownItem(
    value: t,
    label: t.label,
    leading: const Icon(Icons.bloodtype_outlined, size: 20),
  );

  @override
  Widget build(BuildContext context) {
    return SimpleDropdownField<BloodType>(
      items: BloodType.values.map(itemFor).toList(),
      value: value,
      onChanged: onChanged,
      label: label ?? DropDownStrings.bloodTypeLabel,
      hint: hint ?? DropDownStrings.bloodTypeHint,
      enabled: enabled,
      errorText: errorText,
    );
  }
}
