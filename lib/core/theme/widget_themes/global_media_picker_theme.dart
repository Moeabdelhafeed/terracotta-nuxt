import '../../../shared/module/media_picker/index.dart';
import '../../tokens/app_tokens.dart';

/// Project-tuned defaults for the picker family.
///
/// The app-wide rebrand hook: a picked tile rounds by the same token
/// every other surface in the app rounds by, so a picker does not
/// arrive with a corner nothing else has.
///
/// Colours are deliberately NOT set. The accent, the badge and the
/// remove dot resolve from `context.*Colors` at build time so they
/// track role, brightness and saturation, which a constant in here
/// cannot.
class MyGlobalMediaPickerTheme {
  MyGlobalMediaPickerTheme._();

  static GlobalMediaPickerTheme build({required AppTokens tokens}) =>
      GlobalMediaPickerTheme(
        style: MediaPickerStyle(
          tileRadius: tokens.radii.md,
          tileGap: tokens.spacing.sm,
        ),
      );
}
