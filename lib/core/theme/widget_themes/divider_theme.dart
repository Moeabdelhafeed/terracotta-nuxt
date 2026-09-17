import 'package:flutter/material.dart';

import '../../constants/colors/background_colors.dart';
import '../../constants/sizes/app_sizes.dart';
import '../../tokens/app_tokens.dart';

class MyDividerTheme {
  MyDividerTheme._();

  static DividerThemeData build({
    required BackgroundColors bg,
    required AppTokens tokens,
  }) => DividerThemeData(
    color: bg.outlineVariant,
    thickness: AppSizes.borderWidthThin,
    space: tokens.spacing.sm,
  );
}
