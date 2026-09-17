import 'package:flutter/material.dart';

import '../../../../core/extensions/theme_colors_extension.dart';
import '../../../module/buttons/global_text_button.dart';

/// Text button with a trailing chevron — typical list-row pattern
/// ("See all ›", "Manage subscriptions ›") that hints the action
/// leads somewhere.
class TrailingIconTextButton extends StatelessWidget {
  const TrailingIconTextButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.icon = Icons.chevron_right_rounded,
    this.enabled = true,
  });

  final String text;
  final VoidCallback? onPressed;
  final IconData icon;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final color = context.primaryColors.primary;
    return GlobalTextButton(
      text: text,
      onPressed: onPressed,
      enabled: enabled,
      shrinkWidth: true,
      style: ButtonStateStyle(
        foregroundColor: color,
        trailing: Icon(icon, color: color, size: 18),
      ),
    );
  }
}
