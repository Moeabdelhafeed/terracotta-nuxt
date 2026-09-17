import 'dart:ui' show Color;
import '../../../shared/module/app_bar/global_app_bar.dart';
import '../../tokens/app_tokens.dart';

/// Project-tuned defaults for [GlobalAppBar] and [GlobalSliverAppBar].
///
/// The app-wide rebrand hook: set the bar's shape and depth once here
/// and every screen follows, instead of repeating the same
/// `AppBarStyle(...)` at each call site.
///
/// The bar's SURFACE colours are deliberately not set. They resolve
/// from `context.<group>Colors` at build time, so they track the active
/// palette, role, brightness and saturation — pinning them here would
/// freeze the bar against every one of those.
///
/// The BUTTON pill is different, and it is set here on purpose. Every
/// bar in the app draws its back arrow, its bell and its language
/// toggle as one tinted plate with a brown glyph, and a page that
/// forgot to say so got a bare chevron next to a plated action — which
/// is what happened on the product detail screen. Setting it once means
/// a new screen inherits the chrome instead of having to remember it,
/// and the values are passed IN rather than hardcoded so dark mode
/// still resolves.
///
/// `toolbarHeight` must not be set here either: `preferredSize` is a
/// getter with no `BuildContext` and cannot read a theme, so a themed
/// height would paint one size while the Scaffold laid out another.
/// `GlobalAppBarTheme` asserts against it.
class MyGlobalAppBarTheme {
  MyGlobalAppBarTheme._();

  /// The plate behind a bar button, light mode. A warm tint off the
  /// page rather than a palette role: it is the app's chrome, and the
  /// container colours are picked to sit under content.
  static const lightButtonPlate = Color(0xFFF7F0EB);

  static GlobalAppBarTheme build({
    required AppTokens tokens,
    required Color buttonPlate,
    required Color buttonGlyph,
  }) {
    return GlobalAppBarTheme(
      style: AppBarStyle(
        // The bar's own glyphs — the back arrow's colour. A title sets
        // its own through `titleStyle`.
        foregroundColor: buttonGlyph,
        buttonBackgroundColor: buttonPlate,
        // The SAME square the actions paint.
        //
        // Every action in this app is a `ButtonSize.small` icon button,
        // which paints 40 inside its 48dp touch box. The module's back
        // button painted the full 48, so the two plates were different
        // sizes AND different distances from their edges — the paint is
        // centred in the touch box, so a 40 sits 4dp further in than a
        // 48 does. Matching the size matches both.
        backButtonSize: 40,
        // And its glyph, for the same reason: `GlobalIconButton`
        // defaults to 24 and the module's back arrow asked for 22.
        backIconSize: 24,
        // Rides the token bucket, so a density change moves the bar's
        // depth with every other surface instead of leaving it pinned.
        // `flat` is the app bar's designed resting state — it sits ON
        // the surface, not above it.
        elevation: tokens.elevation.flat,
      ),
    );
  }
}
