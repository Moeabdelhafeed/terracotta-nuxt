import 'package:flutter/material.dart';

import '../../constants/colors/background_colors.dart';
import '../../constants/colors/primary_colors.dart';
import '../../constants/colors/text_colors.dart';
import '../../constants/sizes/app_sizes.dart';

class MyRadioTheme {
  MyRadioTheme._();

  static RadioThemeData build({
    required PrimaryColors primary,
    required BackgroundColors bg,
    required TextColors text,
  }) => RadioThemeData(
    fillColor: WidgetStateProperty.resolveWith((states) {
      if (states.contains(WidgetState.disabled)) return text.disabled;
      if (states.contains(WidgetState.selected)) return primary.primary;
      return bg.outline;
    }),
    splashRadius: AppSizes.splashRadius,
    visualDensity: VisualDensity.compact,
  );
}
