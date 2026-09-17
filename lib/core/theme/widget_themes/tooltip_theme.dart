import 'package:flutter/material.dart';

import '../../animations/animation_presets.dart';
import '../../constants/colors/text_colors.dart';
import '../../constants/fonts.dart';
import '../../constants/sizes/app_sizes.dart';
import '../../tokens/app_tokens.dart';

class MyTooltipTheme {
  MyTooltipTheme._();

  static TooltipThemeData build({
    required TextColors text,
    required bool isDark,
    required AppTokens tokens,
  }) => TooltipThemeData(
    decoration: BoxDecoration(
      color: isDark ? text.secondary : text.primary,
      borderRadius: BorderRadius.circular(tokens.radii.sm),
    ),
    textStyle: TextStyle(
      color: text.onPrimary,
      fontSize: AppSizes.fontBodySm,
      fontFamily: AppFonts.scriptPrimaryFamily(),
      fontFamilyFallback: AppFonts.scriptFallbackFamilies(),
    ),
    padding: EdgeInsets.symmetric(
      horizontal: tokens.spacing.sm,
      vertical: tokens.spacing.sm,
    ),
    waitDuration: AppDurations.deliberate,
  );
}
