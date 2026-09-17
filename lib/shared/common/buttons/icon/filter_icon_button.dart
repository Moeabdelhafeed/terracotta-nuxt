import 'package:flutter/material.dart';

import '../../../../core/extensions/theme_colors_extension.dart';
import '../../../../core/localization/strings/button_strings.dart';
import '../../../module/buttons/global_icon_button.dart';

/// Filter icon with an optional "active" dot overlay to signal the
/// user has filters applied. Caller passes [hasActiveFilters].
class FilterIconButton extends StatelessWidget {
  const FilterIconButton({
    super.key,
    required this.onPressed,
    this.hasActiveFilters = false,
    this.iconSize,
    this.color,
    this.tooltip,
    this.enabled = true,
    this.style,
  });

  final VoidCallback onPressed;
  final bool hasActiveFilters;
  final double? iconSize;
  final Color? color;
  final String? tooltip;
  final bool enabled;
  final ButtonStateStyle? style;

  @override
  Widget build(BuildContext context) {
    final resolvedColor = color ?? context.textColors.primary;
    final base = ButtonStateStyle(foregroundColor: resolvedColor);
    return Stack(
      clipBehavior: Clip.none,
      children: [
        GlobalIconButton(
          iconData: Icons.filter_list_rounded,
          iconSize: iconSize ?? 24,
          tooltip: tooltip ?? ButtonStrings.filterTooltip,
          enabled: enabled,
          onPressed: onPressed,
          style: base.merge(style),
        ),
        if (hasActiveFilters)
          Positioned(
            top: 8,
            right: 8,
            child: Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: context.primaryColors.primary,
                shape: BoxShape.circle,
              ),
            ),
          ),
      ],
    );
  }
}
