import 'package:flutter/material.dart';

import '../../../../core/localization/strings/theme_mode_strings.dart';
import '../../../module/segmented_control/global_segmented_control.dart';

/// System / light / dark picker — the settings-page counterpart of
/// `ThemeModeDropdownField`, sharing `ThemeModeStrings`. Wire to
/// `PreferencesCubit`/`ThemeService` in [onChanged].
class ThemeModeSegmented extends StatelessWidget {
  const ThemeModeSegmented({
    super.key,
    required this.value,
    required this.onChanged,
    this.variant = SegmentedVariant.filled,
    this.style = const SegmentedStyle(),
    this.enabled = true,
  });

  final ThemeMode value;
  final ValueChanged<ThemeMode>? onChanged;
  final SegmentedVariant variant;
  final SegmentedStyle style;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    // Locale dependency — labels resolve via Tr/S (static reads).
    Localizations.maybeLocaleOf(context);
    return GlobalSegmentedControl<ThemeMode>(
      segments: [
        SegmentItem(
          value: ThemeMode.system,
          label: ThemeModeStrings.system,
          icon: Icons.phone_iphone_rounded,
        ),
        SegmentItem(
          value: ThemeMode.light,
          label: ThemeModeStrings.light,
          icon: Icons.light_mode_rounded,
        ),
        SegmentItem(
          value: ThemeMode.dark,
          label: ThemeModeStrings.dark,
          icon: Icons.dark_mode_rounded,
        ),
      ],
      value: value,
      onChanged: onChanged,
      variant: variant,
      style: style,
      enabled: enabled,
    );
  }
}
