import 'package:flutter/material.dart';

import '../../constants/colors/background_colors.dart';
import '../../constants/colors/primary_colors.dart';
import '../../constants/colors/text_colors.dart';
import '../../constants/sizes/app_sizes.dart';
import '../../tokens/app_tokens.dart';

class MySegmentedButtonTheme {
  MySegmentedButtonTheme._();

  static SegmentedButtonThemeData build({
    required PrimaryColors primary,
    required BackgroundColors bg,
    required TextColors text,
    required AppTokens tokens,
  }) => SegmentedButtonThemeData(
    style: ButtonStyle(
      side: WidgetStatePropertyAll(
        BorderSide(color: bg.outline, width: AppSizes.borderWidthThin),
      ),
      shape: WidgetStatePropertyAll(
        RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(tokens.radii.md),
        ),
      ),
      backgroundColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) return primary.primary;
        return Colors.transparent;
      }),
      foregroundColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) return text.onPrimary;
        if (states.contains(WidgetState.disabled)) return text.disabled;
        return text.primary;
      }),
      textStyle: const WidgetStatePropertyAll(
        TextStyle(fontWeight: FontWeight.w600),
      ),
    ),
  );
}
