import 'package:flutter/material.dart';

import '../../../../core/extensions/theme_colors_extension.dart';
import '../../../module/buttons/global_filled_button.dart';

/// Amber/yellow caution — "Pause subscription", "Archive",
/// reversible-but-attention actions. Sits between primary and
/// destructive in severity.
class WarningElevatedButton extends StatelessWidget {
  const WarningElevatedButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.isLoading = false,
    this.enabled = true,
    this.icon,
    this.shrinkWidth = false,
    this.tooltip,
  });

  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool enabled;
  final Widget? icon;
  final bool shrinkWidth;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    return GlobalFilledButton(
      text: text,
      onPressed: onPressed,
      enabled: enabled,
      isLoading: isLoading,
      tooltip: tooltip,
      shrinkWidth: shrinkWidth,
      style: ButtonStateStyle(
        backgroundColor: context.statusColors.warning,
        foregroundColor: context.textColors.onPrimary,
        leading: icon,
      ),
    );
  }
}
