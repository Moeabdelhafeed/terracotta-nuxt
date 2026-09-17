import 'package:flutter/material.dart';

import '../../../../core/extensions/theme_colors_extension.dart';
import '../../../module/buttons/global_filled_button.dart';

/// Gradient-filled CTA — promo, onboarding, upgrade flows where the
/// primary action deserves extra visual weight. Defaults to the app's
/// primary→accent gradient; pass a custom [gradient] for a one-off.
class GradientElevatedButton extends StatelessWidget {
  const GradientElevatedButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.gradient,
    this.isLoading = false,
    this.enabled = true,
    this.icon,
    this.shrinkWidth = false,
    this.tooltip,
  });

  final String text;
  final VoidCallback? onPressed;
  final Gradient? gradient;
  final bool isLoading;
  final bool enabled;
  final Widget? icon;
  final bool shrinkWidth;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    final primary = context.primaryColors;
    return GlobalFilledButton(
      text: text,
      onPressed: onPressed,
      enabled: enabled,
      isLoading: isLoading,
      tooltip: tooltip,
      shrinkWidth: shrinkWidth,
      style: ButtonStateStyle(
        backgroundGradient:
            gradient ??
            LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [primary.primary, primary.accent],
            ),
        foregroundColor: context.textColors.onPrimary,
        leading: icon,
      ),
    );
  }
}
