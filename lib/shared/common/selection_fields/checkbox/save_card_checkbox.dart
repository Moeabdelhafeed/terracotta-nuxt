import 'package:flutter/material.dart';

import '../../../../core/localization/strings/module_strings.dart';
import '../../../module/checkbox/global_checkbox.dart';

/// Checkout staple — "Save this card for future payments" (localized
/// en + ar). Pair with `PaymentCardForm`.
class SaveCardCheckbox extends StatelessWidget {
  const SaveCardCheckbox({
    super.key,
    required this.value,
    required this.onChanged,
    this.description,
    this.enabled = true,
    this.style = const CheckboxStyle(),
  });

  final bool value;
  final ValueChanged<bool>? onChanged;

  /// Secondary line — e.g. the PSP/tokenization note.
  final String? description;

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
      label: CheckboxStrings.saveCard,
      description: description,
    );
  }
}
