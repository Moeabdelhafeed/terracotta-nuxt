import '../../../shared/module/share/share_models.dart';
import '../../../shared/module/share/theme/share_theme.dart';
import '../../tokens/app_tokens.dart';

/// Project-tuned defaults for `GlobalShareButton`.
///
/// The glyph size comes from the TOKENS, so a share button grows with
/// the window like every other icon in the app — it was a bare
/// `24.0` const on the model.
class MyGlobalShareTheme {
  MyGlobalShareTheme._();

  static GlobalShareTheme build({required AppTokens tokens}) {
    return GlobalShareTheme(
      style: ShareButtonStyle(iconSize: tokens.iconSizes.lg),
    );
  }
}
