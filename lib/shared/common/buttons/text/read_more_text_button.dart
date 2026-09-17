import 'package:flutter/material.dart';

import '../../../../core/extensions/theme_colors_extension.dart';
import '../../../../core/localization/strings/button_strings.dart';
import '../../../module/buttons/global_text_button.dart';

/// Expand / collapse toggle for truncated copy. Caller owns
/// [expanded] + flips it in [onPressed]. Swaps between "Read more"
/// and "Show less" labels automatically; override via [moreLabel] /
/// [lessLabel] for translations.
class ReadMoreTextButton extends StatelessWidget {
  const ReadMoreTextButton({
    super.key,
    required this.expanded,
    required this.onPressed,
    this.moreLabel,
    this.lessLabel,
    this.enabled = true,
  });

  final bool expanded;
  final VoidCallback? onPressed;
  final String? moreLabel;
  final String? lessLabel;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final color = context.primaryColors.primary;
    return GlobalTextButton(
      text: expanded
          ? (lessLabel ?? ButtonStrings.showLess)
          : (moreLabel ?? ButtonStrings.readMore),
      onPressed: onPressed,
      enabled: enabled,
      shrinkWidth: true,
      style: ButtonStateStyle(
        foregroundColor: color,
        trailing: Icon(
          expanded ? Icons.expand_less_rounded : Icons.expand_more_rounded,
          color: color,
          size: 18,
        ),
      ),
    );
  }
}
