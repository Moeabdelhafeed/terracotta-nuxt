import 'package:flutter/material.dart';

import '../../constants/colors/background_colors.dart';
import '../../constants/colors/icon_colors.dart';
import '../../constants/colors/primary_colors.dart';
import '../../constants/colors/text_colors.dart';
import '../../constants/sizes/app_sizes.dart';
import '../../tokens/app_tokens.dart';

class MyListTileTheme {
  MyListTileTheme._();

  static ListTileThemeData build({
    required PrimaryColors primary,
    required BackgroundColors bg,
    required TextColors text,
    required IconColors icon,
    required AppTokens tokens,
  }) => ListTileThemeData(
    tileColor: Colors.transparent,
    selectedTileColor: primary.primary.withValues(alpha: AppSizes.opacityMuted),
    selectedColor: primary.primary,
    textColor: text.primary,
    iconColor: icon.primary,
    titleTextStyle: TextStyle(
      color: text.primary,
      fontSize: AppSizes.fontBodyLg,
      fontWeight: FontWeight.w500,
    ),
    subtitleTextStyle: TextStyle(
      color: text.secondary,
      fontSize: AppSizes.fontBodySm,
    ),
    leadingAndTrailingTextStyle: TextStyle(
      color: text.secondary,
      fontSize: AppSizes.fontBodySm,
    ),
    contentPadding: EdgeInsets.symmetric(
      horizontal: tokens.spacing.md,
      vertical: tokens.spacing.xs,
    ),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(tokens.radii.sm),
    ),
  );
}
