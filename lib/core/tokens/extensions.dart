import 'package:flutter/material.dart';

import '../responsive/extensions.dart';
import 'app_elevation.dart';
import 'app_icon_sizes.dart';
import 'app_radii.dart';
import 'app_spacing.dart';
import 'app_tokens.dart';
import 'app_typography_scale.dart';

/// Quick access to bucket-aware design tokens. Reads from
/// `Theme.of(context).extension<AppTokens>()` when present (pre-lerped
/// during theme animation); falls back to a fresh bundle derived from
/// `context.windowSize` if the theme extension isn't registered.
extension AppTokensContext on BuildContext {
  AppTokens get tokens {
    final fromTheme = Theme.of(this).extension<AppTokens>();
    if (fromTheme != null) return fromTheme;
    return AppTokens.forBucket(windowSize);
  }

  AppSpacing get spacing => tokens.spacing;
  AppRadii get radii => tokens.radii;
  AppIconSizes get iconSizes => tokens.iconSizes;
  AppElevation get elevation => tokens.elevation;
  AppTypographyScale get typeScale => tokens.typography;
}
