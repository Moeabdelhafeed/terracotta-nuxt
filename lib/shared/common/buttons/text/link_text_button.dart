// Flutter imports:
import 'package:flutter/material.dart';

// Project imports:
import '../../../../core/extensions/theme_colors_extension.dart';
import '../../../module/buttons/global_text_button.dart';

/// Inline link-style text button. Use for "Forgot password?",
/// "Terms of Service", "Learn more" — things that look like a link
/// within body copy.
class LinkTextButton extends StatelessWidget {
  const LinkTextButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.enabled = true,
    this.underline = true,
  });

  final String text;
  final VoidCallback? onPressed;
  final bool enabled;
  final bool underline;

  @override
  Widget build(BuildContext context) {
    final color = context.textColors.link;
    return GlobalTextButton(
      text: text,
      onPressed: onPressed,
      enabled: enabled,
      shrinkWidth: true,
      style: ButtonStateStyle(
        foregroundColor: color,
        textStyle: TextStyle(
          color: color,
          decoration: underline ? TextDecoration.underline : null,
          decorationColor: color,
        ),
      ),
    );
  }
}
