import 'package:flutter/material.dart';

import '../../../../core/extensions/theme_colors_extension.dart';
import '../../../module/buttons/global_icon_button.dart';

class MyLocationIconButton extends StatelessWidget {
  const MyLocationIconButton({
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
      width: 40,
      backgroundColor: context.backgroundColors.surface,
      elevation: 2,
      foregroundColor: color,
    );
    return GlobalIconButton(
      iconData: Icons.my_location_rounded,
      iconSize: iconSize ?? 25,
      tooltip: tooltip,
      enabled: enabled,
      onPressed: onPressed,
      style: base.merge(style),
    );
  }
}
