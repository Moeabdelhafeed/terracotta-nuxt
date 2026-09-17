import 'package:flutter/material.dart';

import '../../../../core/extensions/theme_colors_extension.dart';
import '../../../module/buttons/global_filled_button.dart';

/// Green confirm / positive action — "Mark as paid", "Accept",
/// "Approve". Use sparingly; overusing reserves no visual space for
/// the primary CTA.
class SuccessElevatedButton extends StatelessWidget {
  const SuccessElevatedButton({
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
        backgroundColor: context.statusColors.success,
        foregroundColor: context.textColors.onPrimary,
        leading: icon,
      ),
    );
  }
}
