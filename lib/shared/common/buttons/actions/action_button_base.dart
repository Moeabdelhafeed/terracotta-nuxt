import 'package:flutter/material.dart';

import '../../../../core/extensions/theme_colors_extension.dart';
import '../../../module/buttons/global_filled_button.dart';
import '../../../module/buttons/global_icon_button.dart';
import '../../../module/buttons/global_outlined_button.dart';
import '../../../module/buttons/global_text_button.dart';

export '../../../module/buttons/button_models.dart';

/// Emphasis variant for the action-button family. One class per ACTION
/// (DeleteButton, SaveButton, …); the paint style is this parameter —
/// never a separate class per look.
enum CommonButtonVariant { filled, tonal, outlined, text, icon }

/// Shared renderer behind every `<Action>Button` wrapper AND the public
/// escape hatch for one-off actions:
///
/// ```dart
/// CommonActionButton(
///   label: Tr.t('order.reorder', S.current.order_reorder),
///   icon: Icons.replay_rounded,
///   variant: CommonButtonVariant.tonal,
///   onPressed: _reorder,
/// )
/// ```
///
/// Contracts:
///  - [label] doubles as the icon variant's tooltip + semantics label,
///    so icon buttons are never announced generically.
///  - [danger] recolours EVERY variant from `statusColors.error`
///    (filled bg, tonal tint, outlined border+label, text label, icon
///    glyph) — callers never restate destructive styling.
///  - Callers pass ALREADY-LOCALIZED labels (the action wrappers read
///    CommonStrings/SheetStrings). The build registers a locale
///    dependency so const call sites still rebuild on language flip.
class CommonActionButton extends StatelessWidget {
  const CommonActionButton({
    super.key,
    required this.label,
    required this.icon,
    required this.onPressed,
    this.variant = CommonButtonVariant.filled,
    this.danger = false,
    this.showIcon = false,
    this.onLongPress,
    this.enabled = true,
    this.isLoading = false,
    this.loadingStyle,
    this.result = ButtonResult.none,
    this.onResultShown,
    this.size,
    this.shrinkWidth = false,
    this.tooltip,
    this.enableHaptic,
    this.onDisabledPressed,
    this.style,
  });

  /// Localized label. Icon variant uses it as tooltip + semantics.
  final String label;

  /// Glyph for the icon variant and the optional leading slot.
  final IconData icon;

  final VoidCallback? onPressed;
  final CommonButtonVariant variant;

  /// Destructive action — recolours every variant from
  /// `statusColors.error`.
  final bool danger;

  /// Renders [icon] as a leading slot on the label variants (the icon
  /// variant always shows it).
  final bool showIcon;

  final VoidCallback? onLongPress;
  final bool enabled;
  final bool isLoading;
  final ButtonLoadingStyle? loadingStyle;
  final ButtonResult result;
  final VoidCallback? onResultShown;
  final ButtonSize? size;
  final bool shrinkWidth;

  /// Tooltip override — defaults to [label] on the icon variant.
  final String? tooltip;
  final bool? enableHaptic;
  final VoidCallback? onDisabledPressed;

  /// Merged over the variant's danger/default styling.
  final ButtonStateStyle? style;

  @override
  Widget build(BuildContext context) {
    // Locale dependency — labels resolve via Tr/S (static reads), and
    // const wrappers would otherwise never rebuild on language flip.
    Localizations.maybeLocaleOf(context);

    final error = context.statusColors.error;

    // Danger base per variant; caller [style] merges over it.
    ButtonStateStyle? dangerStyle;
    if (danger) {
      dangerStyle = switch (variant) {
        CommonButtonVariant.filled => ButtonStateStyle(
          backgroundColor: error,
          foregroundColor: context.textColors.onPrimary,
        ),
        CommonButtonVariant.tonal => ButtonStateStyle(
          backgroundColor: Color.alphaBlend(
            error.withValues(alpha: 0.14),
            context.backgroundColors.surface,
          ),
          foregroundColor: error,
        ),
        CommonButtonVariant.outlined => ButtonStateStyle(
          foregroundColor: error,
          border: BorderSide(color: error, width: 1.5),
        ),
        CommonButtonVariant.text => ButtonStateStyle(foregroundColor: error),
        CommonButtonVariant.icon => ButtonStateStyle(foregroundColor: error),
      };
    }

    final effStyle = dangerStyle == null ? style : dangerStyle.merge(style);

    switch (variant) {
      case CommonButtonVariant.filled:
      case CommonButtonVariant.tonal:
        return GlobalFilledButton(
          text: label,
          icon: showIcon ? icon : null,
          tonal: variant == CommonButtonVariant.tonal,
          onPressed: onPressed,
          onLongPress: onLongPress,
          enabled: enabled,
          isLoading: isLoading,
          loadingStyle: loadingStyle,
          result: result,
          onResultShown: onResultShown,
          size: size,
          shrinkWidth: shrinkWidth,
          tooltip: tooltip,
          enableHaptic: enableHaptic,
          onDisabledPressed: onDisabledPressed,
          style: effStyle,
        );
      case CommonButtonVariant.outlined:
        return GlobalOutlinedButton(
          text: label,
          icon: showIcon ? icon : null,
          onPressed: onPressed,
          onLongPress: onLongPress,
          enabled: enabled,
          isLoading: isLoading,
          loadingStyle: loadingStyle,
          result: result,
          onResultShown: onResultShown,
          size: size,
          shrinkWidth: shrinkWidth,
          tooltip: tooltip,
          enableHaptic: enableHaptic,
          onDisabledPressed: onDisabledPressed,
          style: effStyle,
        );
      case CommonButtonVariant.text:
        return GlobalTextButton(
          text: label,
          icon: showIcon ? icon : null,
          onPressed: onPressed,
          onLongPress: onLongPress,
          enabled: enabled,
          isLoading: isLoading,
          loadingStyle: loadingStyle,
          result: result,
          onResultShown: onResultShown,
          size: size,
          shrinkWidth: shrinkWidth,
          tooltip: tooltip,
          enableHaptic: enableHaptic,
          onDisabledPressed: onDisabledPressed,
          style: effStyle,
        );
      case CommonButtonVariant.icon:
        return GlobalIconButton(
          iconData: icon,
          onPressed: onPressed,
          onLongPress: onLongPress,
          enabled: enabled,
          isLoading: isLoading,
          loadingStyle: loadingStyle,
          result: result,
          onResultShown: onResultShown,
          size: size,
          tooltip: tooltip ?? label,
          semanticLabel: label,
          enableHaptic: enableHaptic,
          onDisabledPressed: onDisabledPressed,
          style: effStyle,
        );
    }
  }
}
