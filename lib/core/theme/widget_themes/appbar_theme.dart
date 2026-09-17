import 'package:flutter/material.dart';

import '../../constants/colors/background_colors.dart';
import '../../constants/colors/icon_colors.dart';
import '../../constants/colors/text_colors.dart';
import '../../constants/fonts.dart';
import '../../constants/sizes/app_sizes.dart';
import '../../tokens/app_tokens.dart';

class MyAppBarTheme {
  MyAppBarTheme._();

  static AppBarTheme build({
    required BackgroundColors bg,
    required TextColors text,
    required IconColors icon,
    required AppTokens tokens,
  }) => AppBarTheme(
    elevation: tokens.elevation.flat,
    centerTitle: false,
    scrolledUnderElevation: tokens.elevation.flat,
    backgroundColor: bg.background,
    surfaceTintColor: bg.background,
    iconTheme: IconThemeData(color: icon.primary, size: tokens.iconSizes.lg),
    actionsIconTheme: IconThemeData(
      color: icon.primary,
      size: tokens.iconSizes.lg,
    ),
    titleTextStyle: TextStyle(
      fontSize: AppSizes.fontHeadlineLg,
      fontWeight: FontWeight.w600,
      color: text.primary,
      fontFamily: AppFonts.scriptPrimaryFamily(),
      fontFamilyFallback: AppFonts.scriptFallbackFamilies(),
      letterSpacing: AppSizes.letterSpacingMd,
      height: AppSizes.lineHeightCompact,
    ),
  );
}
