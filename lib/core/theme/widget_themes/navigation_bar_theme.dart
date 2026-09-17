import 'package:flutter/material.dart';

import '../../constants/colors/background_colors.dart';
import '../../constants/colors/primary_colors.dart';
import '../../constants/colors/text_colors.dart';
import '../../constants/fonts.dart';
import '../../constants/sizes/app_sizes.dart';
import '../../tokens/app_tokens.dart';

class MyNavigationBarTheme {
  MyNavigationBarTheme._();

  static NavigationBarThemeData build({
    required PrimaryColors primary,
    required BackgroundColors bg,
    required TextColors text,
    required AppTokens tokens,
  }) => NavigationBarThemeData(
    backgroundColor: bg.surface,
    surfaceTintColor: bg.surface,
    indicatorColor: primary.primary.withValues(
      alpha: AppSizes.opacityIndicator,
    ),
    elevation: tokens.elevation.low,
    height: AppSizes.bottomNavHeight,
    labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
    iconTheme: WidgetStateProperty.resolveWith((states) {
      if (states.contains(WidgetState.selected)) {
        return IconThemeData(color: primary.primary, size: tokens.iconSizes.lg);
      }
      return IconThemeData(color: text.secondary, size: tokens.iconSizes.lg);
    }),
    labelTextStyle: WidgetStateProperty.resolveWith((states) {
      if (states.contains(WidgetState.selected)) {
        return TextStyle(
          fontSize: AppSizes.fontLabelSm,
          fontWeight: FontWeight.w600,
          color: primary.primary,
          fontFamily: AppFonts.scriptPrimaryFamily(),
          fontFamilyFallback: AppFonts.scriptFallbackFamilies(),
        );
      }
      return TextStyle(
        fontSize: AppSizes.fontLabelSm,
        fontWeight: FontWeight.w500,
        color: text.secondary,
        fontFamily: AppFonts.scriptPrimaryFamily(),
        fontFamilyFallback: AppFonts.scriptFallbackFamilies(),
      );
    }),
  );
}
