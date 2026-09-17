import 'package:flutter/material.dart';

import '../../constants/colors/primary_colors.dart';
import '../../constants/colors/text_colors.dart';
import '../../tokens/app_tokens.dart';

class MyFabTheme {
  MyFabTheme._();

  static FloatingActionButtonThemeData build({
    required PrimaryColors primary,
    required TextColors text,
    required AppTokens tokens,
  }) => FloatingActionButtonThemeData(
    backgroundColor: primary.primary,
    foregroundColor: text.onPrimary,
    elevation: tokens.elevation.medium,
    focusElevation: tokens.elevation.medium,
    hoverElevation: tokens.elevation.medium,
    highlightElevation: tokens.elevation.medium,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(tokens.radii.lg),
    ),
  );
}
