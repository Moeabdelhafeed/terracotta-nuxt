import 'package:flutter/material.dart';

import '../../constants/colors/primary_colors.dart';
import '../../constants/colors/text_colors.dart';
import '../../constants/fonts.dart';
import '../../constants/sizes/app_sizes.dart';
import '../../tokens/app_tokens.dart';

class MyOutlinedButtonTheme {
  MyOutlinedButtonTheme._();

  static OutlinedButtonThemeData build({
    required PrimaryColors primary,
    required TextColors text,
    required AppTokens tokens,
  }) => OutlinedButtonThemeData(
    style: OutlinedButton.styleFrom(
      elevation: tokens.elevation.flat,
      foregroundColor: text.primary,
      backgroundColor: Colors.transparent,
      disabledForegroundColor: text.disabled,
      disabledBackgroundColor: Colors.transparent,
      side: BorderSide(
        color: primary.primary,
        width: AppSizes.borderWidthMedium,
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
        color: text.primary,
        fontWeight: FontWeight.w600,
        fontFamily: AppFonts.scriptPrimaryFamily(),
        fontFamilyFallback: AppFonts.scriptFallbackFamilies(),
        letterSpacing: AppSizes.letterSpacingWide,
      ),
    ),
  );
}
