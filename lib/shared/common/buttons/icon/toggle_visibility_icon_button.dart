import 'package:flutter/material.dart';

import '../../../../core/extensions/theme_colors_extension.dart';
import '../../../module/buttons/global_icon_button.dart';

/// Chevron toggle — flips between up/down arrow based on [isHidden].
class ToggleVisibilityIconButton extends StatelessWidget {
  const ToggleVisibilityIconButton({
    super.key,
    required this.onPressed,
    required this.isHidden,
    this.iconSize,
    this.color,
    this.tooltip,
    this.enabled = true,
    this.style,
  });

  final VoidCallback onPressed;
  final bool isHidden;
  final double? iconSize;
  final Color? color;
  final String? tooltip;
  final bool enabled;
  final ButtonStateStyle? style;

  @override
  Widget build(BuildContext context) {
    final base = ButtonStateStyle(
      width: 40,
      backgroundColor: context.backgroundColors.surface,
      elevation: 2,
      foregroundColor: color,
    );
    return GlobalIconButton(
      iconData: isHidden
          ? Icons.arrow_drop_up_rounded
          : Icons.arrow_drop_down_rounded,
      iconSize: iconSize ?? 25,
      tooltip: tooltip,
      enabled: enabled,
      onPressed: onPressed,
      style: base.merge(style),
    );
  }
}
