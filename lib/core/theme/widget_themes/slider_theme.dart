import 'package:flutter/material.dart';

import '../../constants/colors/background_colors.dart';
import '../../constants/colors/primary_colors.dart';
import '../../constants/colors/text_colors.dart';
import '../../constants/sizes/app_sizes.dart';

class MySliderTheme {
  MySliderTheme._();

  static SliderThemeData build({
    required PrimaryColors primary,
    required BackgroundColors bg,
    required TextColors text,
  }) => SliderThemeData(
    activeTrackColor: primary.primary,
    inactiveTrackColor: bg.outlineVariant,
    thumbColor: primary.primary,
    overlayColor: primary.primary.withValues(alpha: AppSizes.opacityMuted),
    valueIndicatorColor: primary.primary,
    valueIndicatorTextStyle: TextStyle(
      color: text.onPrimary,
      fontWeight: FontWeight.w600,
    ),
    trackHeight: AppSizes.progressBarHeight,
    disabledActiveTrackColor: text.disabled,
    disabledInactiveTrackColor: bg.outlineVariant,
    disabledThumbColor: text.disabled,
  );
}
