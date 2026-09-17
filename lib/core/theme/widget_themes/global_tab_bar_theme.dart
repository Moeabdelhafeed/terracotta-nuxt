import 'package:flutter/widgets.dart';

import '../../../shared/module/tab_bar/global_tab_bar.dart';
import '../../tokens/app_tokens.dart';

/// Project-tuned defaults for [GlobalTabBar].
///
/// The app-wide rebrand hook: set the indicator treatment and density
/// once here and every tab bar follows, instead of repeating the same
/// `TabBarStyle(...)` at each call site.
///
/// Colors are deliberately NOT set. They resolve from
/// `context.<group>Colors` at build time, so they track the active
/// palette, role, brightness and saturation — pinning them here would
/// freeze the bar against every one of those.
///
/// `height` must not be set here either: `preferredSize` is a getter
/// with no `BuildContext` and cannot read a theme, so a themed height
/// would paint one size while the Scaffold laid out another.
/// `GlobalTabBarTheme` asserts against it.
class MyGlobalTabBarTheme {
  MyGlobalTabBarTheme._();

  static GlobalTabBarTheme build({required AppTokens tokens}) {
    return GlobalTabBarTheme(
      style: TabBarStyle(
        // Rides the token bucket, so a density change moves the tab's
        // breathing room with every other surface instead of leaving it
        // pinned to a phone-sized constant.
        tabPadding: EdgeInsetsDirectional.symmetric(
          horizontal: tokens.spacing.md,
        ),
        // The pill is a fully rounded chip at every density; taking the
        // radius from tokens keeps it matched to buttons and chips.
        pillRadius: tokens.radii.full,
      ),
    );
  }
}
