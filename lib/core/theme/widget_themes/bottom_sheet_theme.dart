import 'package:flutter/material.dart';

import '../../constants/colors/background_colors.dart';
import '../../constants/colors/text_colors.dart';
import '../../tokens/app_tokens.dart';

class MyBottomSheetTheme {
  MyBottomSheetTheme._();

  static BottomSheetThemeData build({
    required BackgroundColors bg,
    required TextColors text,
    required AppTokens tokens,
  }) => BottomSheetThemeData(
    showDragHandle: true,
    backgroundColor: bg.surface,
    modalBackgroundColor: bg.surface,
    surfaceTintColor: bg.surface,
    dragHandleColor: text.disabled,
    elevation: tokens.elevation.medium,
    modalElevation: tokens.elevation.medium,
    constraints: const BoxConstraints(minWidth: double.infinity),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(
        top: Radius.circular(tokens.radii.xl),
      ),
    ),
  );
}
