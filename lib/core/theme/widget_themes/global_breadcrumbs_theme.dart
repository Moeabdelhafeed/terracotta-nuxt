import '../../../shared/module/breadcrumbs/global_breadcrumbs.dart';
import '../../tokens/app_tokens.dart';

/// Project-tuned defaults for [GlobalBreadcrumbs].
///
/// The app-wide rebrand hook: set the separator, the type size and the
/// collapse budget of every trail in the app once here.
///
/// Colors are deliberately NOT set. They resolve from
/// `context.<group>Colors` at build time, so a trail tracks the active
/// palette, role, brightness and saturation.
class MyGlobalBreadcrumbsTheme {
  MyGlobalBreadcrumbsTheme._();

  static GlobalBreadcrumbsTheme build({required AppTokens tokens}) =>
      GlobalBreadcrumbsTheme(
        style: BreadcrumbsStyle(itemRadius: tokens.radii.xs),
      );
}
