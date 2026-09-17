/// Reusable, embeddable preference pickers. Each reads + writes the
/// global `PreferencesCubit` and supports six visual variants via
/// [PickerOptions.variant]: pillRow · list · segmented · dropdown ·
/// sheet · dialog.
///
/// Drop into any subtree:
/// ```dart
/// const ThemeModePicker()
/// const LanguagePicker()
/// const FontScalePicker()
/// const SaturationPicker()
/// const DynamicColorToggle()
/// const ResetPreferencesButton()
/// const QuickPreferenceActions()   // AppBar actions slot
/// ```
library;

export 'app_role_picker.dart';
export 'font_scale_picker.dart';
export 'language_picker.dart';
export 'picker_item.dart';
export 'picker_options.dart';
export 'picker_shell.dart';
export 'picker_style.dart';
export 'quick_preference_actions.dart';
export 'reset_preferences_button.dart';
export 'reveal_pickers.dart';
export 'saturation_picker.dart';
export 'theme/picker_theme.dart';
export 'theme_mode_picker.dart';
