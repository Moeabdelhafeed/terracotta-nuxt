import '../../../shared/module/preferences_pickers/picker_style.dart';
import '../../../shared/module/preferences_pickers/theme/picker_theme.dart';
import '../../tokens/app_tokens.dart';

/// App-wide defaults for the preference pickers.
///
/// Deliberately thin, and deliberately empty. Every control a picker
/// draws — the chip, the radio, the tile, the dropdown, the segmented
/// control — carries its own bag and its own theme extension, so a
/// house rebrands those once and the pickers follow. What is left
/// here is the picker's own spacing, and the floor in
/// `PickerDefaults` is a sensible one.
class MyGlobalPickerTheme {
  MyGlobalPickerTheme._();

  static GlobalPickerTheme build({required AppTokens tokens}) {
    return const GlobalPickerTheme(style: PickerStyle());
  }
}
