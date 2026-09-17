import 'package:flutter/material.dart';

import '../../../../core/localization/strings/module_strings.dart';
import '../../../module/checkbox/global_checkbox.dart';

/// Age-gate checkbox — "I confirm I am 18 or older" ([minAge]
/// interpolated, localized en + ar) with must-confirm validation baked
/// in. Onboarding/KYC staple; wraps [GlobalCheckboxFormField] so
/// `Form.validate()` and the [ValidationMode] semantics hold.
class AgeConfirmationCheckbox extends StatelessWidget {
  const AgeConfirmationCheckbox({
    super.key,
    this.minAge = 18,
    this.initialValue = false,
    this.onChanged,
    this.validation,
    this.style = const CheckboxStyle(),
    this.enabled = true,
  });

  /// Threshold shown in the label.
  final int minAge;

  /// Seeds the FormField ONCE (standard Flutter semantics).
  final bool initialValue;

  final ValueChanged<bool>? onChanged;

  /// Override the default must-confirm rule (localized
  /// `CheckboxStrings.ageRequired`, `onSubmit` mode).
  final CheckboxValidation<bool>? validation;

  final CheckboxStyle style;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    // Locale dependency — labels resolve via Tr/S (static reads), so
    // register explicitly or a const-constructed instance never
    // rebuilds on a language flip.
    Localizations.maybeLocaleOf(context);
    return GlobalCheckboxFormField(
      initialValue: initialValue,
      onChanged: onChanged,
      validation:
          validation ??
          CheckboxValidation<bool>(
            validator: (v) => v == true ? null : CheckboxStrings.ageRequired,
          ),
      style: style,
      enabled: enabled,
      label: CheckboxStrings.ageConfirm(minAge),
    );
  }
}
