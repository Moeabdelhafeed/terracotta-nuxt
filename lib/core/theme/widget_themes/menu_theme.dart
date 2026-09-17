import 'package:flutter/material.dart';

import '../../constants/colors/background_colors.dart';
import '../../constants/colors/primary_colors.dart';
import '../../constants/colors/text_colors.dart';
import '../../constants/sizes/app_sizes.dart';
import '../../tokens/app_tokens.dart';

/// Themes for the Material 3 menu primitives: [MenuAnchor], [MenuBar],
/// and [MenuItemButton] / [SubmenuButton].
class MyMenuTheme {
  MyMenuTheme._();

  static MenuThemeData buildMenu({
    required BackgroundColors bg,
    required AppTokens tokens,
  }) => MenuThemeData(
    style: MenuStyle(
      backgroundColor: WidgetStatePropertyAll(bg.surface),
      surfaceTintColor: const WidgetStatePropertyAll(Colors.transparent),
      elevation: WidgetStatePropertyAll(tokens.elevation.medium),
      side: WidgetStatePropertyAll(
        BorderSide(color: bg.outline, width: AppSizes.borderWidthThin),
      ),
      shape: WidgetStatePropertyAll(
        RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(tokens.radii.md),
        ),
      ),
      padding: WidgetStatePropertyAll(
        EdgeInsets.symmetric(vertical: tokens.spacing.xs),
      ),
    ),
  );

  static MenuBarThemeData buildBar({
    required BackgroundColors bg,
    required AppTokens tokens,
  }) => MenuBarThemeData(
    style: MenuStyle(
      backgroundColor: WidgetStatePropertyAll(bg.surface),
      surfaceTintColor: const WidgetStatePropertyAll(Colors.transparent),
      elevation: WidgetStatePropertyAll(tokens.elevation.low),
      shape: WidgetStatePropertyAll(
        RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(tokens.radii.sm),
        ),
      ),
    ),
  );

  static MenuButtonThemeData buildButton({
    required PrimaryColors primary,
    required TextColors text,
    required AppTokens tokens,
  }) => MenuButtonThemeData(
    style: ButtonStyle(
      foregroundColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.disabled)) return text.disabled;
        return text.primary;
      }),
      iconColor: WidgetStatePropertyAll(text.secondary),
      overlayColor: WidgetStatePropertyAll(
        primary.primary.withValues(alpha: AppSizes.opacityMuted),
      ),
      padding: WidgetStatePropertyAll(
        EdgeInsets.symmetric(
          horizontal: tokens.spacing.md,
          vertical: tokens.spacing.sm,
        ),
      ),
    ),
  );
}
