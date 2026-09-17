import 'package:flutter/material.dart';

import '../../constants/colors/icon_colors.dart';
import '../../tokens/app_tokens.dart';

class MyIconTheme {
  MyIconTheme._();

  static IconThemeData build({
    required IconColors icon,
    required AppTokens tokens,
  }) => IconThemeData(
    color: icon.primary,
    size: tokens.iconSizes.lg,
  );
}
