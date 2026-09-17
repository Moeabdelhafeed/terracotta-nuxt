import 'package:flutter/material.dart';

import '../../../../core/extensions/theme_colors_extension.dart';
import '../../../module/buttons/global_icon_button.dart';

/// Info / help circle. Tap usually opens a tooltip, popover, or
/// glossary entry explaining the adjacent field.
class InfoIconButton extends StatelessWidget {
  const InfoIconButton({
    super.key,
    required this.onPressed,
    this.iconSize,
    this.color,
    this.tooltip,
    this.enabled = true,
    this.style,
  });

  final VoidCallback onPressed;
  final double? iconSize;
  final Color? color;
  final String? tooltip;
  final bool enabled;
  final ButtonStateStyle? style;

  @override
  Widget build(BuildContext context) {
    final base = ButtonStateStyle(
      foregroundColor: color ?? context.statusColors.info,
    );
    return GlobalIconButton(
      iconData: Icons.info_outline_rounded,
      iconSize: iconSize ?? 20,
      tooltip: tooltip,
      enabled: enabled,
      onPressed: onPressed,
      style: base.merge(style),
    );
  }
}
