import '../../../shared/module/auto_scroller/global_auto_scroller.dart';
import '../../tokens/app_tokens.dart';

/// Project-tuned defaults for [GlobalAutoScroller].
///
/// The app-wide hook is a PACE, not a palette — an auto-scroller
/// paints nothing of its own. Set the speed and the edge behaviour
/// once here and every ambient rail in the app drifts alike.
class MyGlobalAutoScrollerTheme {
  MyGlobalAutoScrollerTheme._();

  static GlobalAutoScrollerTheme build({required AppTokens tokens}) {
    return const GlobalAutoScrollerTheme(style: AutoScrollerStyle());
  }
}
