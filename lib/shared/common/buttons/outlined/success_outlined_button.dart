import 'package:flutter/material.dart';

import '../../../../core/extensions/theme_colors_extension.dart';
import '../../../module/buttons/global_outlined_button.dart';

/// Quieter positive action — "Approve" in a list where you don't
/// want every row screaming green. For the headline confirm action
/// use `SuccessElevatedButton`.
class SuccessOutlinedButton extends StatelessWidget {
  const SuccessOutlinedButton({
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
    final color = context.statusColors.success;
    return GlobalOutlinedButton(
      text: text,
      onPressed: onPressed,
      enabled: enabled,
      isLoading: isLoading,
      tooltip: tooltip,
      shrinkWidth: shrinkWidth,
      style: ButtonStateStyle(
        foregroundColor: color,
        border: BorderSide(color: color),
        leading: icon,
      ),
    );
  }
}
