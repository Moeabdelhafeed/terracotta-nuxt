import 'package:flutter/material.dart';

import '../../../../core/localization/strings/module_strings.dart';
import '../../../module/checkbox/global_checkbox.dart';

/// Dialog/sheet footer staple — "Don't show this again" (localized
/// en + ar). The caller owns persisting the preference.
class DontShowAgainCheckbox extends StatelessWidget {
  const DontShowAgainCheckbox({
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
      label: CheckboxStrings.dontShowAgain,
    );
  }
}
