import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/constants/enums/app/color_saturation.dart';
import '../../../core/localization/strings/preferences_strings.dart';
import '../../../data/blocs/preferences/preferences_cubit.dart';
import '../../../data/blocs/preferences/preferences_state.dart';
import '../../common/selection_fields/selection_fields.dart';
import 'picker_item.dart';
import 'picker_options.dart';
import 'picker_shell.dart';

/// Color saturation picker. Three steps: Muted · Normal · Vibrant.
/// All variants supported via [PickerOptions.variant].
class SaturationPicker extends StatelessWidget {
  const SaturationPicker({
    this.options,
    this.style = const PickerStyle(),
    super.key,
  });

  static PickerOptions get _defaults => PickerOptions(
    title: PreferencesStrings.colorSaturationTitle,
    subtitle: PreferencesStrings.colorSaturationSubtitle,
    icon: Icons.palette_outlined,
  );

  /// `null` renders the localized defaults.
  final PickerOptions? options;

  /// How the picker LOOKS — spacing, whether rows are ruled. The
  /// controls it draws carry their own bags; this one is thin.
  final PickerStyle style;

  static List<PickerItem<ColorSaturation>> get _items => [
    PickerItem<ColorSaturation>(
      value: ColorSaturation.muted,
      label: PreferencesStrings.saturationMuted,
      icon: Icons.water_drop_outlined,
    ),
    PickerItem<ColorSaturation>(
      value: ColorSaturation.normal,
      label: PreferencesStrings.saturationNormal,
      icon: Icons.water_drop_rounded,
    ),
    PickerItem<ColorSaturation>(
      value: ColorSaturation.vibrant,
      label: PreferencesStrings.saturationVibrant,
      icon: Icons.invert_colors_rounded,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PreferencesCubit, PreferencesState>(
      // The LANGUAGE is in the condition too, and has to be: every
      // label this builds comes from `PreferencesStrings`, so a
      // locale change rewrites all of them — and a `buildWhen` that
      // only watched its own field filtered that rebuild out. The
      // options stayed in the old language until something unrelated
      // moved, or the app was hot-reloaded.
      buildWhen: (a, b) =>
          a.colorSaturation != b.colorSaturation ||
          a.language.locale != b.language.locale,
      builder: (context, prefs) {
        return PickerShell<ColorSaturation>(
          items: _items,
          value: prefs.colorSaturation,
          onChanged: context.read<PreferencesCubit>().setColorSaturation,
          options: (options ?? const PickerOptions()).mergedOver(_defaults),
          style: style,
        );
      },
    );
  }
}

/// Toggle for Material You / OS-driven dynamic color. Disabled
/// platforms (iOS, web, < Android 12) still let the toggle flip but
/// `DynamicColorBuilder` returns null schemes there, so the OS
/// override is silently skipped.
class DynamicColorToggle extends StatelessWidget {
  const DynamicColorToggle({this.dense = false, super.key});

  final bool dense;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PreferencesCubit, PreferencesState>(
      buildWhen: (a, b) =>
          a.dynamicColor != b.dynamicColor ||
          a.language.locale != b.language.locale,
      builder: (context, prefs) {
        final cubit = context.read<PreferencesCubit>();
        return SettingsSwitchRow(
          value: prefs.dynamicColor,
          onChanged: cubit.setDynamicColor,
          title: PreferencesStrings.dynamicColorTitle,
          description: PreferencesStrings.dynamicColorSubtitle,
          leading: Icons.color_lens_outlined,
          dense: dense,
          contentPadding: EdgeInsets.zero,
        );
      },
    );
  }
}
