import 'package:flutter/material.dart';

import '../../../../core/extensions/theme_colors_extension.dart';
import '../../../../data/services/navigation_service.dart';
import '../../../module/buttons/global_icon_button.dart';

/// Smart back — pops the smart-nav history first, regular history
/// second, renders nothing if there's nothing to pop.
class BackIconButton extends StatelessWidget {
  const BackIconButton({
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
    final nav = context.navigationService;
    if (nav.smartHistoryLength == 0 && !nav.canGoBack()) {
      return const SizedBox.shrink();
    }

    final base = ButtonStateStyle(
      width: 42,
      backgroundColor: context.backgroundColors.surface,
      elevation: 0,
      foregroundColor: color,
    );
    return GlobalIconButton(
      iconData: Icons.arrow_back_rounded,
      iconSize: iconSize ?? 28,
      tooltip: tooltip,
      enabled: enabled,
      onPressed: onPressed ?? nav.smartPop,
      style: base.merge(style),
    );
  }
}
