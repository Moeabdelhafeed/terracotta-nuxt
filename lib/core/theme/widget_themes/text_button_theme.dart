import 'package:flutter/material.dart';

import '../../constants/colors/primary_colors.dart';
import '../../constants/colors/text_colors.dart';
import '../../constants/fonts.dart';
import '../../constants/sizes/app_sizes.dart';
import '../../tokens/app_tokens.dart';

class MyTextButtonTheme {
  MyTextButtonTheme._();

  static TextButtonThemeData build({
    required PrimaryColors primary,
    required TextColors text,
    required AppTokens tokens,
  }) => TextButtonThemeData(
    style: TextButton.styleFrom(
      foregroundColor: primary.primary,
      disabledForegroundColor: text.disabled,
      padding: EdgeInsets.symmetric(
        vertical: tokens.spacing.sm,
        horizontal: tokens.spacing.md,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSizes.buttonRadiusMd),
      ),
      textStyle: TextStyle(
        fontSize: AppSizes.fontBodyLg,
        fontWeight: FontWeight.w600,
        fontFamily: AppFonts.scriptPrimaryFamily(),
        fontFamilyFallback: AppFonts.scriptFallbackFamilies(),
        letterSpacing: AppSizes.letterSpacingWide,
      ),
    ),
  );
}
