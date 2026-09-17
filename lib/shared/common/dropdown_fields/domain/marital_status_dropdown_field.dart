import 'package:flutter/material.dart';

import '../../../../core/localization/strings/drop_down_strings.dart';
import '../../../../core/localization/strings/marital_status_strings.dart';
import '../../../module/drop_down/global_drop_down.dart';
import '../generic/simple_dropdown_field.dart';

/// Standard marital-status set — the regional-form staple quartet.
enum MaritalStatus { single, married, divorced, widowed }

extension MaritalStatusLabel on MaritalStatus {
  String get label => switch (this) {
    MaritalStatus.single => MaritalStatusStrings.single,
    MaritalStatus.married => MaritalStatusStrings.married,
    MaritalStatus.divorced => MaritalStatusStrings.divorced,
    MaritalStatus.widowed => MaritalStatusStrings.widowed,
  };
}

/// Marital-status picker. Labels are localized
/// (`MaritalStatusStrings`, en + ar).
class MaritalStatusDropdownField extends StatelessWidget {
  const MaritalStatusDropdownField({
    super.key,
    required this.value,
    required this.onChanged,
    this.label,
    this.hint,
    this.enabled = true,
    this.errorText,
  });

  final MaritalStatus? value;
  final ValueChanged<MaritalStatus?>? onChanged;
  final String? label;
  final String? hint;
  final bool enabled;
  final String? errorText;

  /// Canonical marital-status row.
  static DropdownItem<MaritalStatus> itemFor(MaritalStatus s) =>
      DropdownItem(value: s, label: s.label);

  @override
  Widget build(BuildContext context) {
    return SimpleDropdownField<MaritalStatus>(
      items: MaritalStatus.values.map(itemFor).toList(),
      value: value,
      onChanged: onChanged,
      label: label ?? DropDownStrings.maritalStatusLabel,
      hint: hint ?? DropDownStrings.maritalStatusHint,
      enabled: enabled,
      errorText: errorText,
    );
  }
}
