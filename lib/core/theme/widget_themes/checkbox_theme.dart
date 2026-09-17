import 'package:flutter/material.dart';

import '../../constants/colors/background_colors.dart';
import '../../constants/colors/primary_colors.dart';
import '../../constants/colors/text_colors.dart';
import '../../constants/sizes/app_sizes.dart';
import '../../tokens/app_tokens.dart';

class MyCheckboxTheme {
  MyCheckboxTheme._();

  static CheckboxThemeData build({
    required PrimaryColors primary,
    required TextColors text,
    required BackgroundColors bg,
    required AppTokens tokens,
  }) => CheckboxThemeData(
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(tokens.radii.xs),
    ),
    checkColor: WidgetStateProperty.resolveWith(
      (states) => states.contains(WidgetState.selected)
          ? text.onPrimary
          : Colors.transparent,
    ),
    fillColor: WidgetStateProperty.resolveWith(
      (states) => states.contains(WidgetState.selected)
          ? primary.primary
          : Colors.transparent,
    ),
    side: WidgetStateBorderSide.resolveWith(
      (states) => states.contains(WidgetState.disabled)
          ? BorderSide(width: AppSizes.borderWidthThin, color: text.disabled)
          : states.contains(WidgetState.selected)
          ? BorderSide(
              width: AppSizes.borderWidthMedium,
              color: primary.primary,
            )
          : BorderSide(width: AppSizes.borderWidthMedium, color: bg.outline),
    ),
    visualDensity: VisualDensity.compact,
    splashRadius: AppSizes.splashRadius,
  );
}
