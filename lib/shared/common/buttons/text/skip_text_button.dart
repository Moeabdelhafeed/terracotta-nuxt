// Flutter imports:
import 'package:flutter/material.dart';

// Project imports:
import '../../../../core/extensions/theme_colors_extension.dart';
import '../../../../core/localization/strings/common_strings.dart';
import '../../../module/buttons/global_text_button.dart';

/// "Skip" button — onboarding carousels, optional fields, permission
/// prompts that have a deferred path.
class SkipTextButton extends StatelessWidget {
  const SkipTextButton({
    super.key,
    required this.onPressed,
    this.text,
  });

  final VoidCallback? onPressed;
  final String? text;

  @override
  Widget build(BuildContext context) {
    return GlobalTextButton(
      text: text ?? CommonStrings.skip,
      onPressed: onPressed,
      shrinkWidth: true,
      style: ButtonStateStyle(
        foregroundColor: context.textColors.secondary,
      ),
    );
  }
}
