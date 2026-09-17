import 'package:flutter/material.dart';

import '../../constants/colors/background_colors.dart';
import '../../tokens/app_tokens.dart';

class MyCardTheme {
  MyCardTheme._();

  static CardThemeData build({
    required BackgroundColors bg,
    required AppTokens tokens,
  }) => CardThemeData(
    color: bg.cardBackground,
    surfaceTintColor: bg.cardBackground,
    elevation: tokens.elevation.low,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(tokens.radii.md),
    ),
    margin: EdgeInsets.all(tokens.spacing.xs),
    clipBehavior: Clip.antiAlias,
  );
}
