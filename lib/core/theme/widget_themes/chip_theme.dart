import 'package:flutter/material.dart';

import '../../constants/colors/background_colors.dart';
import '../../constants/colors/icon_colors.dart';
import '../../constants/colors/primary_colors.dart';
import '../../constants/colors/text_colors.dart';
import '../../constants/fonts.dart';
import '../../constants/sizes/app_sizes.dart';
import '../../tokens/app_tokens.dart';

class MyChipTheme {
  MyChipTheme._();

  static ChipThemeData build({
    required PrimaryColors primary,
    required BackgroundColors bg,
    required TextColors text,
    required IconColors icon,
    required bool isDark,
    required AppTokens tokens,
  }) => ChipThemeData(
    checkmarkColor: text.onPrimary,
    selectedColor: primary.primary,
    disabledColor: text.disabled,
    backgroundColor: bg.background,
    padding: EdgeInsets.symmetric(
      horizontal: tokens.spacing.sm,
      vertical: tokens.spacing.sm,
    ),
    labelStyle: TextStyle(
      color: text.primary,
      fontSize: AppSizes.fontLabelSm,
      fontFamily: AppFonts.scriptPrimaryFamily(),
      fontFamilyFallback: AppFonts.scriptFallbackFamilies(),
      fontWeight: FontWeight.normal,
    ),
    secondaryLabelStyle: TextStyle(
      color: text.onPrimary,
      fontSize: AppSizes.fontLabelSm,
      fontFamily: AppFonts.scriptPrimaryFamily(),
      fontFamilyFallback: AppFonts.scriptFallbackFamilies(),
      fontWeight: FontWeight.w500,
    ),
    shape: StadiumBorder(
      side: BorderSide(color: bg.outline, width: AppSizes.borderWidthThin),
    ),
    elevation: tokens.elevation.flat,
    pressElevation: tokens.elevation.low,
    iconTheme: IconThemeData(color: icon.secondary, size: tokens.iconSizes.md),
    brightness: isDark ? Brightness.dark : Brightness.light,
  );
}
