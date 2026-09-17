import 'package:flutter/material.dart';

import '../../../../core/localization/strings/module_strings.dart';
import '../../../module/checkbox/global_checkbox.dart';

/// Marketing/newsletter opt-in — "Send me offers and product updates"
/// (localized en + ar). Plain controlled checkbox: opt-ins are never
/// required, so no Form wiring.
class MarketingOptInCheckbox extends StatelessWidget {
  const MarketingOptInCheckbox({
    super.key,
    required this.value,
    required this.onChanged,
    this.description,
    this.enabled = true,
    this.style = const CheckboxStyle(),
  });

  final bool value;
  final ValueChanged<bool>? onChanged;

  /// Secondary line — e.g. the channels ("Email and SMS, weekly").
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
      label: CheckboxStrings.marketingOptIn,
      description: description,
    );
  }
}
