import 'package:flutter/material.dart';

import '../../../../core/localization/strings/common_strings.dart';
import 'action_button_base.dart';

export 'action_button_base.dart' show CommonButtonVariant;

/// Refresh/reload — defaults to the icon variant.
///
/// Label, icon, semantics are baked in and localized;
/// pick the look with [variant].
class RefreshButton extends StatelessWidget {
  const RefreshButton({
    super.key,
    required this.onPressed,
    this.variant = CommonButtonVariant.icon,
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

  final VoidCallback? onPressed;
  final CommonButtonVariant variant;
  final bool showIcon;
  final VoidCallback? onLongPress;
  final bool enabled;
  final bool isLoading;
  final ButtonLoadingStyle? loadingStyle;
  final ButtonResult result;
  final VoidCallback? onResultShown;
  final ButtonSize? size;
  final bool shrinkWidth;
  final String? tooltip;
  final bool? enableHaptic;
  final VoidCallback? onDisabledPressed;
  final ButtonStateStyle? style;

  @override
  Widget build(BuildContext context) {
    // Locale dependency at THIS layer: the label getter is evaluated
    // here, so this build must rerun on language flip. Registering it
    // only in CommonActionButton left const call sites passing a stale
    // label until hot reload.
    Localizations.maybeLocaleOf(context);
    return CommonActionButton(
      label: CommonStrings.refresh,
      icon: Icons.refresh_rounded,
      variant: variant,
      showIcon: showIcon,
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
      style: style,
    );
  }
}
