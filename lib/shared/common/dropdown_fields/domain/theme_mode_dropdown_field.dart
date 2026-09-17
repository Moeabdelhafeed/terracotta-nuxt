import 'package:flutter/material.dart';

import '../../../../core/localization/strings/drop_down_strings.dart';
import '../../../../core/localization/strings/theme_mode_strings.dart';
import '../../../module/drop_down/global_drop_down.dart';
import '../generic/simple_dropdown_field.dart';

/// Picker for [ThemeMode] — light / dark / system. Wire to
/// `getIt<ThemeService>().setThemeMode(...)` in [onChanged].
class ThemeModeDropdownField extends StatelessWidget {
  const ThemeModeDropdownField({
    super.key,
    required this.value,
    required this.onChanged,
    this.label,
    this.hint,
    this.enabled = true,
    this.errorText,
  });

  final ThemeMode? value;
  final ValueChanged<ThemeMode?>? onChanged;
  final String? label;
  final String? hint;
  final bool enabled;
  final String? errorText;

  @override
  Widget build(BuildContext context) {
    final items = [
      DropdownItem(
        value: ThemeMode.system,
        label: ThemeModeStrings.system,
        leading: const Icon(Icons.phone_iphone_rounded, size: 20),
      ),
      DropdownItem(
        value: ThemeMode.light,
        label: ThemeModeStrings.light,
        leading: const Icon(Icons.light_mode_rounded, size: 20),
      ),
      DropdownItem(
        value: ThemeMode.dark,
        label: ThemeModeStrings.dark,
        leading: const Icon(Icons.dark_mode_rounded, size: 20),
      ),
    ];
    return SimpleDropdownField<ThemeMode>(
      items: items,
      value: value,
      onChanged: onChanged,
      label: label ?? DropDownStrings.themeLabel,
      hint: hint ?? DropDownStrings.themeHint,
      enabled: enabled,
      errorText: errorText,
    );
  }
}
