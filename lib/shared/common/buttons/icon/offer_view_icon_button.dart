import 'package:flutter/material.dart';

import '../../../../core/extensions/theme_colors_extension.dart';
import '../../../module/buttons/global_icon_button.dart';

/// Toggles between "view offer" and "hide offer" states. Caller owns
/// [isOfferView] and flips it in [onPressed].
class OfferViewIconButton extends StatelessWidget {
  const OfferViewIconButton({
    super.key,
    required this.isOfferView,
    required this.onPressed,
    this.iconSize,
    this.color,
    this.tooltip,
    this.enabled = true,
    this.style,
  });

  final bool isOfferView;
  final VoidCallback onPressed;
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
      backgroundColor: isOfferView ? Colors.white : Colors.transparent,
      elevation: 0,
    );
    return GlobalIconButton(
      iconData: isOfferView ? Icons.visibility_off : Icons.visibility,
      iconSize: iconSize ?? 28,
      tooltip: tooltip,
      enabled: enabled,
      onPressed: onPressed,
      style: base.merge(style),
    );
  }
}
