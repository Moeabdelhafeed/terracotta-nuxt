import 'package:flutter/material.dart';

import '../../constants/colors/background_colors.dart';
import '../../constants/colors/primary_colors.dart';
import '../../constants/colors/text_colors.dart';
import '../../tokens/app_tokens.dart';

class MyTimePickerTheme {
  MyTimePickerTheme._();

  static TimePickerThemeData build({
    required PrimaryColors primary,
    required BackgroundColors bg,
    required TextColors text,
    required AppTokens tokens,
  }) => TimePickerThemeData(
    backgroundColor: bg.surface,
    dialBackgroundColor: bg.container,
    dialHandColor: primary.primary,
    dialTextColor: text.primary,
    hourMinuteColor: bg.container,
    hourMinuteTextColor: text.primary,
    dayPeriodColor: bg.container,
    dayPeriodTextColor: text.primary,
    helpTextStyle: TextStyle(
      color: text.secondary,
      fontWeight: FontWeight.w600,
    ),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(tokens.radii.lg),
    ),
    hourMinuteShape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(tokens.radii.md),
    ),
    dayPeriodShape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(tokens.radii.md),
    ),
  );
}
