import 'package:flutter/material.dart';

import '../../constants/colors/background_colors.dart';
import '../../constants/colors/icon_colors.dart';
import '../../constants/colors/primary_colors.dart';
import '../../constants/colors/status_colors.dart';
import '../../constants/colors/text_colors.dart';
import '../../constants/fonts.dart';
import '../../constants/sizes/app_sizes.dart';

class MyTextFormFieldTheme {
  MyTextFormFieldTheme._();

  static InputDecorationTheme build({
    required PrimaryColors primary,
    required BackgroundColors bg,
    required TextColors text,
    required StatusColors status,
    required IconColors icon,
  }) => InputDecorationTheme(
    errorMaxLines: AppSizes.errorMaxLines,
    prefixIconColor: icon.secondary,
    suffixIconColor: icon.secondary,
    labelStyle: TextStyle(
      fontSize: AppSizes.fontBodyLg,
      color: text.secondary,
      fontFamily: AppFonts.scriptPrimaryFamily(),
      fontFamilyFallback: AppFonts.scriptFallbackFamilies(),
    ),
    hintStyle: TextStyle(
      fontSize: AppSizes.fontBodySm,
      color: text.secondary,
      fontFamily: AppFonts.scriptPrimaryFamily(),
      fontFamilyFallback: AppFonts.scriptFallbackFamilies(),
    ),
    errorStyle: TextStyle(
      fontStyle: FontStyle.normal,
      fontWeight: FontWeight.normal,
      fontSize: AppSizes.fontBodySm,
      color: status.error,
      fontFamily: AppFonts.scriptPrimaryFamily(),
      fontFamilyFallback: AppFonts.scriptFallbackFamilies(),
    ),
    floatingLabelStyle: TextStyle(
      color: primary.primary.withValues(alpha: AppSizes.opacityStrong),
      fontSize: AppSizes.fontBodyLg,
      fontFamily: AppFonts.scriptPrimaryFamily(),
      fontFamilyFallback: AppFonts.scriptFallbackFamilies(),
      fontWeight: FontWeight.w500,
    ),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppSizes.inputFieldRadius),
      borderSide: BorderSide(
        width: AppSizes.borderWidthThin,
        color: bg.outline,
      ),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppSizes.inputFieldRadius),
      borderSide: BorderSide(
        width: AppSizes.borderWidthThin,
        color: bg.outline,
      ),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppSizes.inputFieldRadius),
      borderSide: BorderSide(
        width: AppSizes.borderWidthMedium,
        color: primary.primary,
      ),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppSizes.inputFieldRadius),
      borderSide: BorderSide(
        width: AppSizes.borderWidthThin,
        color: status.error,
      ),
    ),
    focusedErrorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppSizes.inputFieldRadius),
      borderSide: BorderSide(
        width: AppSizes.borderWidthMedium,
        color: status.error,
      ),
    ),
    disabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppSizes.inputFieldRadius),
      borderSide: BorderSide(
        width: AppSizes.borderWidthThin,
        color: bg.outlineVariant,
      ),
    ),
    contentPadding: const EdgeInsets.symmetric(
      horizontal: AppSizes.inputFieldPaddingHorizontal,
      vertical: AppSizes.inputFieldPaddingVertical,
    ),
    filled: true,
    fillColor: bg.inputBackground,
  );
}
