import 'package:flutter/material.dart';

import '../../constants/colors/icon_colors.dart';
import '../../constants/colors/primary_colors.dart';
import '../../constants/colors/text_colors.dart';
import '../../constants/sizes/app_sizes.dart';
import '../../tokens/app_tokens.dart';

class MyIconButtonTheme {
  MyIconButtonTheme._();

  static IconButtonThemeData build({
    required PrimaryColors primary,
    required IconColors icon,
    required TextColors text,
    required AppTokens tokens,
  }) => IconButtonThemeData(
    style: IconButton.styleFrom(
      foregroundColor: icon.primary,
      backgroundColor: Colors.transparent,
      disabledForegroundColor: text.disabled,
      hoverColor: primary.primary.withValues(alpha: AppSizes.opacityMuted),
      focusColor: primary.primary.withValues(alpha: AppSizes.opacityMuted),
      highlightColor: primary.primary.withValues(alpha: AppSizes.opacityLight),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(tokens.radii.sm),
      ),
      padding: EdgeInsets.all(tokens.spacing.sm),
    ),
  );
}
