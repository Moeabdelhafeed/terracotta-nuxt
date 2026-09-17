import 'package:flutter/material.dart';

import '../../../../core/localization/strings/module_strings.dart';
import 'settings_switch_row.dart';

/// Usage-analytics consent — pair with the Firebase Analytics adapter.
/// Localized (en + ar) preset over [SettingsSwitchRow].
class AnalyticsSwitchRow extends StatelessWidget {
  const AnalyticsSwitchRow({
    super.key,
    required this.value,
    required this.onChanged,
    this.description,
    this.enabled = true,
    this.dense = false,
  });

  final bool value;
  final ValueChanged<bool>? onChanged;

  /// Secondary line override (null → the localized default).
  final String? description;

  final bool enabled;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    // Locale dependency — the title resolves via Tr/S (static reads).
    Localizations.maybeLocaleOf(context);
    return SettingsSwitchRow(
      leading: Icons.insights_outlined,
      title: SwitchStrings.analytics,
      description: description ?? SwitchStrings.analyticsDesc,
      value: value,
      onChanged: onChanged,
      enabled: enabled,
      dense: dense,
    );
  }
}
