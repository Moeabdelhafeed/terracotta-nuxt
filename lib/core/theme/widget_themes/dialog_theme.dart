import 'package:flutter/material.dart';

import '../../constants/colors/background_colors.dart';
import '../../constants/colors/text_colors.dart';
import '../../constants/fonts.dart';
import '../../constants/sizes/app_sizes.dart';

class MyDialogTheme {
  MyDialogTheme._();

  static DialogThemeData build({
    required BackgroundColors bg,
    required TextColors text,
  }) => DialogThemeData(
    backgroundColor: bg.surface,
    surfaceTintColor: bg.surface,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppSizes.sheetRadius),
    ),
    titleTextStyle: TextStyle(
      fontSize: AppSizes.fontTitleLg,
      fontWeight: FontWeight.w600,
      color: text.primary,
      fontFamily: AppFonts.scriptPrimaryFamily(),
      fontFamilyFallback: AppFonts.scriptFallbackFamilies(),
      height: AppSizes.lineHeightMd,
    ),
    contentTextStyle: TextStyle(
      fontSize: AppSizes.fontBodyMd,
      fontWeight: FontWeight.normal,
      color: text.secondary,
      fontFamily: AppFonts.scriptPrimaryFamily(),
      fontFamilyFallback: AppFonts.scriptFallbackFamilies(),
      height: AppSizes.lineHeightLoose,
    ),
  );
}
