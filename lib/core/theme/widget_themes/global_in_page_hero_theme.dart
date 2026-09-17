import '../../../shared/module/in_page_hero/global_in_page_hero.dart';
import '../../tokens/app_tokens.dart';

/// Project-tuned defaults for `InPageHero`.
///
/// The app-wide rebrand hook: the house's flight duration, curve and
/// lift, set once. Like the other motion themes it takes [tokens] for
/// symmetry and reads none of them — a flight is motion, not layout.
///
/// No colours either: a flight's shadow is set here only if the house
/// wants one, and the decorations it lerps come from the ENDPOINTS,
/// which are the caller's widgets.
class MyGlobalInPageHeroTheme {
  MyGlobalInPageHeroTheme._();

  static GlobalInPageHeroTheme build({required AppTokens tokens}) =>
      const GlobalInPageHeroTheme(
        // Deliberately empty — the template ships `InPageHeroDefaults`,
        // and an adopter changes it here rather than at every endpoint:
        //
        //   style: InPageHeroStyle(
        //     duration: AppDurations.normal,
        //     curve: Curves.easeOutCubic,
        //   ),
        style: InPageHeroStyle(),
      );
}
