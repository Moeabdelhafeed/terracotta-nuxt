import 'package:flutter/material.dart';

import '../../constants/colors/background_colors.dart';
import '../../constants/colors/primary_colors.dart';
import '../../constants/colors/text_colors.dart';
import '../../constants/sizes/app_sizes.dart';
import '../../tokens/app_tokens.dart';

class MyDatePickerTheme {
  MyDatePickerTheme._();

  static DatePickerThemeData build({
    required PrimaryColors primary,
    required BackgroundColors bg,
    required TextColors text,
    required AppTokens tokens,
  }) => DatePickerThemeData(
    backgroundColor: bg.surface,
    surfaceTintColor: Colors.transparent,
    headerBackgroundColor: primary.primary,
    headerForegroundColor: text.onPrimary,
    dividerColor: bg.outline,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(tokens.radii.lg),
    ),
    dayForegroundColor: WidgetStateProperty.resolveWith((states) {
      if (states.contains(WidgetState.selected)) return text.onPrimary;
      if (states.contains(WidgetState.disabled)) return text.disabled;
      return text.primary;
    }),
    dayBackgroundColor: WidgetStateProperty.resolveWith((states) {
      if (states.contains(WidgetState.selected)) return primary.primary;
      return Colors.transparent;
    }),
    todayForegroundColor: WidgetStateProperty.resolveWith((states) {
      if (states.contains(WidgetState.selected)) return text.onPrimary;
      return primary.primary;
    }),
    todayBorder: BorderSide(
      color: primary.primary,
      width: AppSizes.borderWidthThin,
    ),
    yearForegroundColor: WidgetStateProperty.resolveWith((states) {
      if (states.contains(WidgetState.selected)) return text.onPrimary;
      return text.primary;
    }),
    yearBackgroundColor: WidgetStateProperty.resolveWith((states) {
      if (states.contains(WidgetState.selected)) return primary.primary;
      return Colors.transparent;
    }),
  );
}
