import 'package:flutter/material.dart';

import '../../constants/colors/background_colors.dart';
import '../../constants/colors/primary_colors.dart';
import '../../constants/colors/text_colors.dart';
import '../../constants/sizes/app_sizes.dart';
import '../../tokens/app_tokens.dart';

class MySearchBarTheme {
  MySearchBarTheme._();

  static SearchBarThemeData build({
    required PrimaryColors primary,
    required BackgroundColors bg,
    required TextColors text,
    required AppTokens tokens,
  }) => SearchBarThemeData(
    backgroundColor: WidgetStatePropertyAll(bg.inputBackground),
    surfaceTintColor: const WidgetStatePropertyAll(Colors.transparent),
    overlayColor: WidgetStatePropertyAll(
      primary.primary.withValues(alpha: AppSizes.opacityMuted),
    ),
    elevation: WidgetStatePropertyAll(tokens.elevation.flat),
    shape: WidgetStatePropertyAll(
      RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(tokens.radii.full),
        side: BorderSide(color: bg.outline, width: AppSizes.borderWidthThin),
      ),
    ),
    padding: WidgetStatePropertyAll(
      EdgeInsets.symmetric(horizontal: tokens.spacing.md),
    ),
    hintStyle: WidgetStatePropertyAll(TextStyle(color: text.secondary)),
    textStyle: WidgetStatePropertyAll(TextStyle(color: text.primary)),
  );
}
