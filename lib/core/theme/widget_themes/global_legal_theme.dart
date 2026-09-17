import '../../../shared/module/legal/legal_style.dart';
import '../../../shared/module/legal/theme/legal_theme.dart';
import '../../tokens/app_tokens.dart';

/// Project-tuned defaults for the about / legal pages.
///
/// **This is where an adopter puts their own app mark.** The default
/// is a gradient plate with a Flutter glyph on it — unmistakably a
/// placeholder, which is right for a template and wrong for a shipped
/// app. Setting `markBuilder` here replaces it everywhere at once,
/// instead of editing the page.
class MyGlobalLegalTheme {
  MyGlobalLegalTheme._();

  static GlobalLegalTheme build({required AppTokens tokens}) {
    return GlobalLegalTheme(
      style: LegalStyle(
        sectionGap: tokens.spacing.lg,
        labelGap: tokens.spacing.sm,
        tileRadius: tokens.radii.md,
        headerRadius: tokens.radii.lg,
      ),
    );
  }
}
