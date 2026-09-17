import 'package:flutter/material.dart';

import '../../constants/colors/background_colors.dart';
import '../../constants/colors/primary_colors.dart';
import '../../constants/colors/text_colors.dart';
import '../../constants/fonts.dart';
import '../../constants/sizes/app_sizes.dart';

class MyTabBarTheme {
  MyTabBarTheme._();

  static TabBarThemeData build({
    required PrimaryColors primary,
    required BackgroundColors bg,
    required TextColors text,
  }) => TabBarThemeData(
    indicatorColor: primary.primary,
    indicatorSize: TabBarIndicatorSize.tab,
    labelColor: primary.primary,
    unselectedLabelColor: text.secondary,
    dividerColor: bg.outlineVariant,
    labelStyle: TextStyle(
      fontSize: AppSizes.fontLabelLg,
      fontWeight: FontWeight.w600,
      fontFamily: AppFonts.scriptPrimaryFamily(),
      fontFamilyFallback: AppFonts.scriptFallbackFamilies(),
    ),
    unselectedLabelStyle: TextStyle(
      fontSize: AppSizes.fontLabelLg,
      fontWeight: FontWeight.w500,
      fontFamily: AppFonts.scriptPrimaryFamily(),
      fontFamilyFallback: AppFonts.scriptFallbackFamilies(),
    ),
    overlayColor: WidgetStateProperty.resolveWith(
      (states) => states.contains(WidgetState.pressed)
          ? primary.primary.withValues(alpha: AppSizes.opacityLight)
          : primary.primary.withValues(alpha: AppSizes.opacitySubtle),
    ),
  );
}
