import 'package:flutter/material.dart';

import '../../../../core/localization/strings/module_strings.dart';
import 'settings_switch_row.dart';

/// Haptic-feedback preference — feed it into the style bags' `enableHaptic` app-wide via `GlobalCheckboxTheme`/`GlobalSwitchTheme`.
/// Localized (en + ar) preset over [SettingsSwitchRow].
class HapticsSwitchRow extends StatelessWidget {
  const HapticsSwitchRow({
    super.key,
    required this.value,
    required this.onChanged,
    this.description,
    this.enabled = true,
    this.dense = false,
  });

  final bool value;
  final ValueChanged<bool>? onChanged;

  /// Secondary line override.
  final String? description;

  final bool enabled;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    // Locale dependency — the title resolves via Tr/S (static reads).
    Localizations.maybeLocaleOf(context);
    return SettingsSwitchRow(
      leading: Icons.vibration,
      title: SwitchStrings.haptics,
      description: description,
      value: value,
      onChanged: onChanged,
      enabled: enabled,
      dense: dense,
    );
  }
}
