import 'package:flutter/material.dart';

import '../../constants/colors/background_colors.dart';
import '../../constants/colors/icon_colors.dart';
import '../../constants/colors/primary_colors.dart';
import '../../constants/colors/text_colors.dart';
import '../../constants/sizes/app_sizes.dart';
import '../../tokens/app_tokens.dart';

class MyExpansionTileTheme {
  MyExpansionTileTheme._();

  static ExpansionTileThemeData build({
    required PrimaryColors primary,
    required BackgroundColors bg,
    required TextColors text,
    required IconColors icon,
    required AppTokens tokens,
  }) => ExpansionTileThemeData(
    backgroundColor: bg.surface,
    collapsedBackgroundColor: Colors.transparent,
    textColor: primary.primary,
    collapsedTextColor: text.primary,
    iconColor: primary.primary,
    collapsedIconColor: icon.primary,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(tokens.radii.md),
      side: BorderSide(color: bg.outline, width: AppSizes.borderWidthThin),
    ),
    collapsedShape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(tokens.radii.md),
      side: BorderSide(
        color: bg.outlineVariant,
        width: AppSizes.borderWidthThin,
      ),
    ),
    tilePadding: EdgeInsets.symmetric(
      horizontal: tokens.spacing.md,
      vertical: tokens.spacing.xs,
    ),
    childrenPadding: EdgeInsets.fromLTRB(
      tokens.spacing.md,
      tokens.spacing.sm,
      tokens.spacing.md,
      tokens.spacing.sm,
    ),
  );
}
