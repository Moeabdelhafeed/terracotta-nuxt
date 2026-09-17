import 'package:flutter/material.dart';

import '../../../../core/localization/strings/module_strings.dart';
import '../../../module/checkbox/global_checkbox.dart';

/// Free-text must-accept checkbox — "I have read and understood the
/// NDA", disclaimer acknowledgements, safety notices. The caller owns
/// the [label] (role-specific copy can't ship in a template); the
/// must-acknowledge validation and its localized default error are
/// baked in. Wraps [GlobalCheckboxFormField].
class AcknowledgementCheckbox extends StatelessWidget {
  const AcknowledgementCheckbox({
    super.key,
    required this.label,
    this.description,
    this.initialValue = false,
    this.onChanged,
    this.validation,
    this.style = const CheckboxStyle(),
    this.enabled = true,
  });

  /// The acknowledgement sentence (caller-localized).
  final String label;

  /// Secondary line below the label.
  final String? description;

  /// Seeds the FormField ONCE (standard Flutter semantics).
  final bool initialValue;

  final ValueChanged<bool>? onChanged;

  /// Override the default must-acknowledge rule (localized
  /// `CheckboxStrings.acknowledgeRequired`, `onSubmit` mode).
  final CheckboxValidation<bool>? validation;

  final CheckboxStyle style;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return GlobalCheckboxFormField(
      initialValue: initialValue,
      onChanged: onChanged,
      validation:
          validation ??
          CheckboxValidation<bool>(
            validator: (v) =>
                v == true ? null : CheckboxStrings.acknowledgeRequired,
          ),
      style: style,
      enabled: enabled,
      label: label,
      description: description,
    );
  }
}
