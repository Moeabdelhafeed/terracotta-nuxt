import 'package:flutter/material.dart';

import '../constants/colors/background_colors.dart';
import '../constants/colors/buttons_colors.dart';
import '../constants/colors/icon_colors.dart';
import '../constants/colors/overlay_colors.dart';
import '../constants/colors/primary_colors.dart';
import '../constants/colors/shimmer_colors.dart';
import '../constants/colors/status_colors.dart';
import '../constants/colors/text_colors.dart';
import '../constants/enums/app/app_role.dart';
import '../theme/app_palette.dart';

/// Read role + saturation-aware colors from the active theme.
///
/// Saturation is baked into the [AppPalette] `ThemeExtension` at theme
/// build time (see `AppTheme.getTheme`), so these accessors and the
/// matching [ColorScheme] entries always agree. If the palette
/// extension is missing (e.g. tests with a bare `ThemeData()`), the
/// getters fall back to the user-role default for the current
/// brightness with `saturation = 1.0`.
extension ThemeColorsExtension on BuildContext {
  AppPalette get _palette {
    final fromTheme = Theme.of(this).extension<AppPalette>();
    if (fromTheme != null) return fromTheme;
    final isDark = Theme.of(this).brightness == Brightness.dark;
    return AppPalette.build(
      appRole: AppRole.user,
      isDark: isDark,
      saturation: 1.0,
    );
  }

  PrimaryColors get primaryColors => _palette.primary;
  ButtonsColors get buttonsColors => _palette.buttons;
  TextColors get textColors => _palette.text;
  BackgroundColors get backgroundColors => _palette.background;
  StatusColors get statusColors => _palette.status;
  IconColors get iconColors => _palette.icon;
  ShimmerColors get shimmerColors => _palette.shimmer;
  OverlayColors get overlayColors => _palette.overlay;
}
