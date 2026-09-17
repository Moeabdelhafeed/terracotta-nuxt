import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/animations/animation_presets.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/extensions/theme_colors_extension.dart';
import '../../../../core/tokens/extensions.dart';
import '../../../module/switch/global_switch.dart';

/// The settings-page staple: full-width tappable row with title,
/// optional description + leading icon, and a trailing [GlobalSwitch]
/// — the switch-module counterpart of `GlobalCheckboxTile` (the switch
/// module deliberately ships no tile of its own).
class SettingsSwitchRow extends StatelessWidget {
  const SettingsSwitchRow({
    super.key,
    required this.value,
    required this.onChanged,
    required this.title,
    this.description,
    this.leading,
    this.enabled = true,
    this.enableHaptic = true,
    this.dense = false,
    this.contentPadding,
  });

  final bool value;
  final ValueChanged<bool>? onChanged;
  final String title;
  final String? description;

  /// Leading icon (tinted to the icon palette).
  final IconData? leading;

  final bool enabled;

  /// Haptic on toggle (row tap AND switch drag).
  final bool enableHaptic;

  final bool dense;
  final EdgeInsetsGeometry? contentPadding;

  @override
  Widget build(BuildContext context) {
    final isDisabled = !enabled || onChanged == null;
    final radius = BorderRadius.circular(context.radii.md);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: isDisabled
            ? null
            : () {
                if (enableHaptic) HapticFeedback.lightImpact();
                onChanged?.call(!value);
              },
        borderRadius: radius,
        child: AnimatedOpacity(
          opacity: isDisabled ? 0.5 : 1.0,
          duration: AppDurations.quick,
          child: Padding(
            padding:
                contentPadding ??
                EdgeInsets.symmetric(
                  vertical: dense ? context.spacing.xs : context.spacing.sm,
                  horizontal: context.spacing.md,
                ),
            child: Row(
              children: [
                if (leading != null) ...[
                  Icon(leading, color: context.iconColors.primary),
                  SizedBox(width: context.spacing.sm),
                ],
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        title,
                        style: context.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w500,
                          color: isDisabled
                              ? context.textColors.disabled
                              : null,
                        ),
                      ),
                      if (description != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          description!,
                          style: context.textTheme.bodySmall?.copyWith(
                            color: context.textColors.secondary,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                SizedBox(width: context.spacing.sm),
                // The row's InkWell owns the tap (and the haptic) — the
                // switch stays display-only so the two never double-fire.
                IgnorePointer(
                  child: GlobalSwitch(
                    value: value,
                    onChanged: isDisabled ? null : (_) {},
                    style: const SwitchStyle(enableHaptic: false),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
