import 'package:flutter/material.dart';

import '../../../../core/extensions/theme_colors_extension.dart';
import '../../../../core/localization/strings/button_strings.dart';
import '../../../module/buttons/global_icon_button.dart';

/// Three-dot "more actions" button. Typical list-row trailing item;
/// tap usually shows a menu / bottom sheet.
class MoreIconButton extends StatelessWidget {
  const MoreIconButton({
    super.key,
    required this.onPressed,
    this.vertical = true,
    this.iconSize,
    this.color,
    this.tooltip,
    this.enabled = true,
    this.style,
  });

  final VoidCallback onPressed;

  /// `true` → vertical three-dot (`⋮`). `false` → horizontal (`⋯`).
  final bool vertical;

  final double? iconSize;
  final Color? color;
  final String? tooltip;
  final bool enabled;
  final ButtonStateStyle? style;

  @override
  Widget build(BuildContext context) {
    final base = ButtonStateStyle(
      foregroundColor: color ?? context.textColors.secondary,
    );
    return GlobalIconButton(
      iconData: vertical ? Icons.more_vert_rounded : Icons.more_horiz_rounded,
      iconSize: iconSize ?? 24,
      tooltip: tooltip ?? ButtonStrings.moreTooltip,
      enabled: enabled,
      onPressed: onPressed,
      style: base.merge(style),
    );
  }
}
