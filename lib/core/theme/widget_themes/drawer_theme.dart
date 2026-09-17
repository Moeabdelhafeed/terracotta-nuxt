import 'package:flutter/material.dart';

import '../../constants/colors/background_colors.dart';
import '../../constants/sizes/app_sizes.dart';
import '../../tokens/app_tokens.dart';

class MyDrawerTheme {
  MyDrawerTheme._();

  static DrawerThemeData build({
    required BackgroundColors bg,
    required AppTokens tokens,
  }) => DrawerThemeData(
    backgroundColor: bg.surface,
    surfaceTintColor: bg.surface,
    elevation: tokens.elevation.medium,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.horizontal(
        right: Radius.circular(AppSizes.sheetRadius),
      ),
    ),
  );
}
