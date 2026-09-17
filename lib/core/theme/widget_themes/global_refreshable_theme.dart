import '../../../shared/module/refreshable/global_refreshable.dart';
import '../../tokens/app_tokens.dart';

/// Project-tuned defaults for [GlobalRefreshable].
///
/// The app-wide rebrand hook: decide once how long the indicator
/// lingers, whether a pull ticks, and which spinner the app draws, and
/// every pull-to-refresh follows.
///
/// Colours are deliberately NOT set. They resolve from
/// `context.<group>Colors` at build time, so the spinner tracks the
/// active palette, role, brightness and saturation.
class MyGlobalRefreshableTheme {
  MyGlobalRefreshableTheme._();

  static GlobalRefreshableTheme build({required AppTokens tokens}) {
    return const GlobalRefreshableTheme(style: RefreshableStyle());
  }
}
