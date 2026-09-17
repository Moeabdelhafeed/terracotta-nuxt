// Flutter imports:
import 'package:flutter/material.dart';

// Project imports:
import '../../../../core/extensions/theme_colors_extension.dart';
import '../../../../core/localization/strings/button_strings.dart';
import '../../../module/buttons/global_icon_button.dart';

/// Toggleable heart. Caller owns [isFavorite] + flips it in
/// [onPressed] — button doesn't manage its own state so it stays in
/// sync with the Cubit / Bloc that holds the real answer.
class FavoriteIconButton extends StatelessWidget {
  const FavoriteIconButton({
    super.key,
    required this.isFavorite,
    required this.onPressed,
    this.iconSize,
    this.color,
    this.tooltip,
    this.enabled = true,
    this.style,
  });

  final bool isFavorite;
  final VoidCallback onPressed;
  final double? iconSize;
  final Color? color;
  final String? tooltip;
  final bool enabled;
  final ButtonStateStyle? style;

  @override
  Widget build(BuildContext context) {
    final resolvedColor =
        color ??
        (isFavorite
            ? context.statusColors.error
            : context.textColors.secondary);
    final base = ButtonStateStyle(foregroundColor: resolvedColor);
    return GlobalIconButton(
      iconData: isFavorite ? Icons.favorite : Icons.favorite_border,
      iconSize: iconSize ?? 24,
      tooltip:
          tooltip ??
          (isFavorite
              ? ButtonStrings.removeFavoriteTooltip
              : ButtonStrings.addFavoriteTooltip),
      enabled: enabled,
      onPressed: onPressed,
      style: base.merge(style),
    );
  }
}
