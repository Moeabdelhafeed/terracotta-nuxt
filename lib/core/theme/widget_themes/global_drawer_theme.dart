import 'package:flutter/widgets.dart';

import '../../../shared/module/drawer/global_drawer.dart';
import '../../tokens/app_tokens.dart';

/// Project-tuned defaults for [GlobalDrawer].
///
/// The app-wide rebrand hook: set the drawer's shape and row treatment
/// once here and every navigation surface follows, instead of repeating
/// the same `DrawerStyle(...)` at each call site.
///
/// Colors are deliberately NOT set. They resolve from
/// `context.<group>Colors` at build time, so they track the active
/// palette, role, brightness and saturation — pinning them here would
/// freeze the drawer against every one of those.
///
/// `width` is left null too: it resolves per breakpoint, and a themed
/// number would pin a phone-sized drawer onto a desktop.
class MyGlobalDrawerTheme {
  MyGlobalDrawerTheme._();

  static GlobalDrawerTheme build({required AppTokens tokens}) {
    return GlobalDrawerTheme(
      style: DrawerStyle(
        // Rides the token bucket, so a density change moves the rows'
        // corner rounding with every other surface instead of leaving
        // them pinned to a phone-sized constant.
        itemBorderRadius: BorderRadius.circular(tokens.radii.md),
        itemPadding: EdgeInsetsDirectional.symmetric(
          horizontal: tokens.spacing.md,
        ),
      ),
    );
  }
}
