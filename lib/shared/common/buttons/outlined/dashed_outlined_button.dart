import 'package:dotted_border/dotted_border.dart';
import 'package:flutter/material.dart';

import '../../../../core/extensions/theme_colors_extension.dart';

/// Dashed outline — convention for "add new item" slots in forms
/// (upload a file, add a card, invite a user). Wraps
/// [DottedBorder] around an [InkWell] so it feels like a real button
/// without inheriting the filled outline aesthetic.
class DashedOutlinedButton extends StatelessWidget {
  const DashedOutlinedButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.icon = Icons.add_rounded,
    this.height = 56,
    this.enabled = true,
  });

  final String text;
  final VoidCallback? onPressed;
  final IconData? icon;
  final double height;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final color = enabled
        ? context.primaryColors.primary
        : context.textColors.disabled;
    return DottedBorder(
      options: RoundedRectDottedBorderOptions(
        radius: const Radius.circular(12),
        color: color,
        dashPattern: const [8, 4],
        strokeWidth: 1.5,
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: enabled ? onPressed : null,
        child: SizedBox(
          height: height,
          child: Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (icon != null) ...[
                  Icon(icon, color: color, size: 20),
                  const SizedBox(width: 8),
                ],
                Text(
                  text,
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
