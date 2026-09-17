import 'package:flutter/material.dart';

import '../../../shared/module/text_field/text_field.dart';
import '../../animations/animation_presets.dart';
import '../../tokens/app_tokens.dart';

/// Project-tuned defaults for the [GlobalTextFormField] module.
///
/// Binds the active token bucket to a [GlobalTextFieldTheme] so every text
/// field in the app inherits the same corner radius + motion timing.
/// Per-call [TextFieldStyle] overrides still win.
///
/// Colors are intentionally left null here — they resolve at build time
/// from `context.<group>Colors` (role + saturation aware), so the field
/// tracks the active palette without the factory hard-binding swatches.
///
/// Wired in `theme.dart`'s `extensions:` list alongside `tokens` /
/// `palette` / `MyGlobalPopupTheme`.
class MyGlobalTextFieldTheme {
  MyGlobalTextFieldTheme._();

  static GlobalTextFieldTheme build({required AppTokens tokens}) {
    return GlobalTextFieldTheme(
      style: TextFieldStyle(
        borderRadius: BorderRadius.circular(TextFieldDefaults.borderRadius),
        border: const TextFieldBorderStyle(
          focused: TextFieldBorderSide(
            width: TextFieldDefaults.focusedBorderWidth,
          ),
        ),
      ),
      animationDuration: AppDurations.quick,
    );
  }
}
