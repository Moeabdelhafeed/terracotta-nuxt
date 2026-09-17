import 'package:flutter/material.dart';

import '../../constants/colors/background_colors.dart';
import '../../constants/colors/text_colors.dart';
import '../../constants/sizes/app_sizes.dart';
import '../../tokens/app_tokens.dart';

class MyBannerTheme {
  MyBannerTheme._();

  static MaterialBannerThemeData build({
    required BackgroundColors bg,
    required TextColors text,
    required AppTokens tokens,
  }) => MaterialBannerThemeData(
    backgroundColor: bg.surface,
    surfaceTintColor: Colors.transparent,
    elevation: tokens.elevation.low,
    shadowColor: Colors.black.withValues(alpha: AppSizes.opacityLight),
    dividerColor: bg.outline,
    contentTextStyle: TextStyle(
      color: text.primary,
      fontSize: AppSizes.fontBodyLg,
    ),
    padding: EdgeInsets.symmetric(
      horizontal: tokens.spacing.md,
      vertical: tokens.spacing.sm,
    ),
  );
}
