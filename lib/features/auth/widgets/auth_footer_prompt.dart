import 'package:flutter/material.dart';

import '../../../core/extensions/context_extensions.dart';
import '../../../core/extensions/theme_colors_extension.dart';
import '../../../shared/module/buttons/global_text_button.dart';
import 'auth_scaffold.dart' show kAuthLinkFontSize;

/// "Don't have an account? Create one" and its mirror on register.
///
/// The prompt and the action are two separate strings on purpose: a
/// single sentence with the link embedded forces one locale's grammar
/// onto the other, and Arabic puts the verb somewhere English does not.
/// A `Row` orders them logically, so the link follows the prompt in
/// both reading directions without a second layout.
class AuthFooterPrompt extends StatelessWidget {
  const AuthFooterPrompt({
    required this.prompt,
    required this.action,
    required this.onPressed,
    super.key,
  });

  final String prompt;
  final String action;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => Wrap(
    // Wrap, not Row: `MainAxisSize.min` with a `Flexible` child forces
    // an infinite width and blows up layout. Wrap also does the thing
    // this actually needs — the Arabic prompt is longer than the
    // English one and has to be allowed to break onto a second line
    // rather than overflow.
    alignment: WrapAlignment.center,
    crossAxisAlignment: WrapCrossAlignment.center,
    children: [
      Text(
        prompt,
        // The design paints the WHOLE line in the link brown, prompt
        // included — not a dark question with a coloured answer.
        style: context.textTheme.bodySmall?.copyWith(
          color: context.primaryColors.primary,
          fontSize: kAuthLinkFontSize,
        ),
      ),
      GlobalTextButton(
        text: action,
        onPressed: onPressed,
        shrinkWidth: true,
        style: const ButtonStateStyle(
          textStyle: TextStyle(fontSize: kAuthLinkFontSize),
        ),
      ),
    ],
  );
}
