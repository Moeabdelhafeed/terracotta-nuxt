import 'package:flutter/material.dart';

import '../../../../core/constants/assets/assets.dart';
import '../../../../core/extensions/theme_colors_extension.dart';
import '../../../module/buttons/global_icon_button.dart';

class NotificationIconButton extends StatelessWidget {
  const NotificationIconButton({
    super.key,
    this.onPressed,
    this.iconSize,
    this.color,
    this.tooltip,
    this.enabled = true,
    this.style,
  });

  final VoidCallback? onPressed;
  final double? iconSize;
  final Color? color;
  final String? tooltip;
  final bool enabled;
  final ButtonStateStyle? style;

  @override
  Widget build(BuildContext context) {
    final base = ButtonStateStyle(
      width: 42,
      foregroundColor: color ?? context.primaryColors.primary,
      backgroundColor: Colors.transparent,
      elevation: 0,
    );
    return GlobalIconButton(
      iconPath: Assets.icons.notification.resolve(context),
      iconSize: iconSize ?? 28,
      tooltip: tooltip,
      enabled: enabled,
      onPressed: onPressed,
      style: base.merge(style),
    );
  }
}
