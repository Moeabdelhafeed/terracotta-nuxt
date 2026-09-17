import '../../loading/loading_style.dart';
import '../../loading/theme/loading_theme.dart';
import '../../tokens/app_tokens.dart';

/// Project-tuned defaults for `LoadingOverlay`.
///
/// The overlay is mounted once, in `MyApp`, so before this its look
/// could only be set there — one of the few surfaces every user sees,
/// and the only one a house could not rebrand.
class MyGlobalLoadingTheme {
  MyGlobalLoadingTheme._();

  static GlobalLoadingTheme build({required AppTokens tokens}) {
    return const GlobalLoadingTheme(style: LoadingStyle());
  }
}
