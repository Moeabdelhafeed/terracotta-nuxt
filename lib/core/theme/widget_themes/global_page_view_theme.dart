import '../../../shared/module/page_view/global_page_view.dart';
import '../../tokens/app_tokens.dart';

/// Project-tuned defaults for the page FAMILY — `GlobalPageView`,
/// `GlobalCarousel` and `GlobalCarouselView`.
///
/// The app-wide rebrand hook: decide once which indicator a deck of
/// pages shows, where it sits and how a page turn feels, and all three
/// follow.
///
/// The DOTS' own look is deliberately NOT set here — that belongs to
/// `GlobalIndicatorTheme`, beside every other dot in the app. A second
/// place to set a dot colour is a second place for it to be wrong.
class MyGlobalPageViewTheme {
  MyGlobalPageViewTheme._();

  static GlobalPageViewTheme build({required AppTokens tokens}) {
    return const GlobalPageViewTheme(style: GlobalPageViewStyle());
  }
}
