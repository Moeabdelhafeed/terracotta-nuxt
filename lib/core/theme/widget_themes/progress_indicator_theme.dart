import 'package:flutter/material.dart';

import '../../constants/colors/background_colors.dart';
import '../../constants/colors/primary_colors.dart';
import '../../constants/sizes/app_sizes.dart';

class MyProgressIndicatorTheme {
  MyProgressIndicatorTheme._();

  static ProgressIndicatorThemeData build({
    required PrimaryColors primary,
    required BackgroundColors bg,
  }) => ProgressIndicatorThemeData(
    color: primary.primary,
    linearTrackColor: bg.outlineVariant,
    circularTrackColor: bg.outlineVariant,
    linearMinHeight: AppSizes.progressBarHeight,
  );
}
