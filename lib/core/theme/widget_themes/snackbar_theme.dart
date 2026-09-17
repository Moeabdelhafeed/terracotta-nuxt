import 'package:flutter/material.dart';

import '../../constants/colors/background_colors.dart';
import '../../constants/colors/text_colors.dart';
import '../../constants/fonts.dart';
import '../../tokens/app_tokens.dart';

class MySnackBarTheme {
  MySnackBarTheme._();

  static SnackBarThemeData build({
    required BackgroundColors bg,
    required TextColors text,
    required bool isDark,
    required AppTokens tokens,
  }) => SnackBarThemeData(
    // Dark mode: surface container. Light mode: inverted (dark bg for contrast).
    backgroundColor: isDark ? bg.container : text.primary,
    contentTextStyle: TextStyle(
      color: text.onPrimary,
      fontFamily: AppFonts.scriptPrimaryFamily(),
      fontFamilyFallback: AppFonts.scriptFallbackFamilies(),
    ),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(tokens.radii.md),
    ),
    behavior: SnackBarBehavior.floating,
  );
}
