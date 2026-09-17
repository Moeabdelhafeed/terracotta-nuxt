import 'package:flutter/material.dart';

import '../../constants/colors/primary_colors.dart';
import '../../constants/colors/text_colors.dart';
import '../../constants/fonts.dart';
import '../../constants/sizes/app_sizes.dart';
import '../../tokens/app_tokens.dart';

class MyFilledButtonTheme {
  MyFilledButtonTheme._();

  static FilledButtonThemeData build({
    required PrimaryColors primary,
    required TextColors text,
    required AppTokens tokens,
  }) => FilledButtonThemeData(
    style: FilledButton.styleFrom(
      elevation: tokens.elevation.flat,
      foregroundColor: text.onPrimary,
      backgroundColor: primary.primary,
      disabledForegroundColor: text.disabled,
      disabledBackgroundColor: primary.primary.withValues(
        alpha: AppSizes.opacityHigh,
      ),
      padding: EdgeInsets.symmetric(
        vertical: tokens.spacing.sm,
        horizontal: tokens.spacing.md,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSizes.buttonRadiusMd),
      ),
      textStyle: TextStyle(
        fontSize: AppSizes.fontBodyLg,
        color: text.onPrimary,
        fontWeight: FontWeight.w600,
        fontFamily: AppFonts.scriptPrimaryFamily(),
        fontFamilyFallback: AppFonts.scriptFallbackFamilies(),
        letterSpacing: AppSizes.letterSpacingWide,
      ),
    ),
  );
}
