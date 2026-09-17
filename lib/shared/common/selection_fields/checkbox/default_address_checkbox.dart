import 'package:flutter/material.dart';

import '../../../../core/localization/strings/module_strings.dart';
import '../../../module/checkbox/global_checkbox.dart';

/// Address-book staple — "Set as default address" (localized en + ar).
/// Pair with `AddressForm`.
class DefaultAddressCheckbox extends StatelessWidget {
  const DefaultAddressCheckbox({
    super.key,
    required this.value,
    required this.onChanged,
    this.enabled = true,
    this.style = const CheckboxStyle(),
  });

  final bool value;
  final ValueChanged<bool>? onChanged;
  final bool enabled;
  final CheckboxStyle style;

  @override
  Widget build(BuildContext context) {
    // Locale dependency — labels resolve via Tr/S (static reads), so
    // register explicitly or a const-constructed instance never
    // rebuilds on a language flip.
    Localizations.maybeLocaleOf(context);
    return GlobalCheckbox.simple(
      value: value,
      onChanged: onChanged,
      enabled: enabled,
      style: style,
      label: CheckboxStrings.defaultAddress,
    );
  }
}
