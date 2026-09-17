import 'package:flutter/material.dart';

import '../../constants/colors/background_colors.dart';
import '../../constants/colors/text_colors.dart';
import '../../constants/fonts.dart';
import '../../constants/sizes/app_sizes.dart';
import '../../tokens/app_tokens.dart';

class MyPopupMenuTheme {
  MyPopupMenuTheme._();

  static PopupMenuThemeData build({
    required BackgroundColors bg,
    required TextColors text,
    required AppTokens tokens,
  }) => PopupMenuThemeData(
    color: bg.surface,
    surfaceTintColor: bg.surface,
    elevation: tokens.elevation.medium,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(tokens.radii.md),
    ),
    labelTextStyle: WidgetStateProperty.all(
      TextStyle(
        fontSize: AppSizes.fontBodyMd,
        color: text.primary,
        fontFamily: AppFonts.scriptPrimaryFamily(),
        fontFamilyFallback: AppFonts.scriptFallbackFamilies(),
      ),
    ),
  );
}
