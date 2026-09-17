import 'package:flutter/material.dart';

import '../../../../core/extensions/theme_colors_extension.dart';
import '../../../../data/services/navigation_service.dart';
import '../../../module/buttons/global_icon_button.dart';

class MenuIconButton extends StatelessWidget {
  const MenuIconButton({
    super.key,
    required this.menuRoute,
    this.iconSize,
    this.color,
    this.tooltip,
    this.enabled = true,
    this.style,
  });

  final String menuRoute;
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
      iconData: Icons.menu_rounded,
      iconSize: iconSize ?? 25,
      tooltip: tooltip,
      enabled: enabled,
      onPressed: () => context.navigationService.push(menuRoute),
      style: base.merge(style),
    );
  }
}
