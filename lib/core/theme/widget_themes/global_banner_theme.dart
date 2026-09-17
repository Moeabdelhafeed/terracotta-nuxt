import 'package:flutter/material.dart';

import '../../../shared/module/banner/global_banner.dart';
import '../../tokens/app_tokens.dart';

/// Project-tuned defaults for [GlobalBanner].
///
/// The app-wide rebrand hook: set the corner, the inset and the motion
/// of every notice in the app once here.
///
/// Colors are deliberately NOT set. They resolve from
/// `context.statusColors` at build time and depend on the banner's
/// TYPE, so a notice tracks the active palette, role, brightness and
/// saturation.
class MyGlobalBannerTheme {
  MyGlobalBannerTheme._();

  static GlobalBannerTheme build({required AppTokens tokens}) {
    return GlobalBannerTheme(
      style: BannerStyle(
        borderRadius: BorderRadius.circular(tokens.radii.md),
        // UNIFORM. This was `horizontal: md, vertical: sm` and it WINS
        // over `BannerDefaults.padding`, so making the module's own
        // inset uniform changed nothing in the app: every banner still
        // sat closer to its top edge than to its start one.
        padding: EdgeInsets.all(tokens.spacing.md),
        iconSpacing: tokens.spacing.sm,
      ),
    );
  }
}
