import 'package:flutter/material.dart';

import 'package:flutter/services.dart';

import '../../../core/animations/animation_presets.dart';
import '../../../core/localization/strings/module_strings.dart';
import '../../../core/painters/gradient_border_painter.dart';
import '../progress/global_progress.dart';
import '../tooltip/global_tooltip.dart';
import 'switch_models.dart';

export 'switch_models.dart';
export 'theme/switch_theme.dart';

part 'switch_state.dart';

// ---------------------------------------------------------------------------
// GlobalSwitch
// ---------------------------------------------------------------------------

/// Animated on/off switch with drag, labels (outside / in-track /
/// in-thumb), icons, loading and pulse-on-mount.
///
/// Fully controlled — displays [value] as passed and reports taps/drags
/// via [onChanged], never mutates. Visuals come from the themeable
/// [SwitchStyle] bag (`caller > GlobalSwitchTheme > defaults > context
/// colors`); haptics gate on the resolved `enableHaptic` (default
/// true). Content (icons, label text) and behavior (drag, debounce,
/// loading) stay widget-side.
class GlobalSwitch extends StatefulWidget {
  const GlobalSwitch({
    super.key,
    required this.value,
    required this.onChanged,
    this.style = const SwitchStyle(),
    this.size,
    this.enabled = true,
    // Content
    this.activeIcon,
    this.inactiveIcon,
    this.activeLabel,
    this.inactiveLabel,
    this.showLabels = false,
    this.activeTrackLabel,
    this.inactiveTrackLabel,
    this.activeThumbText,
    this.inactiveThumbText,
    // Behavior
    this.loading = false,
    this.enableDrag = false,
    this.debounce = false,
    this.tooltip,
    this.disabledTooltip,
    this.semanticLabel,
    this.pulseOnMount = false,
    this.isVertical = false,
  });

  // ─── Core ──────────────────────────────────────────────────

  final bool value;
  final ValueChanged<bool>? onChanged;

  /// Themeable styling — see [SwitchStyle.resolve] for the merge order.
  final SwitchStyle style;

  /// Size preset — wins over the style bag's width/height/thumbSize.
  final SwitchSize? size;

  /// Whether the switch is interactive (also disabled when [onChanged]
  /// is null).
  final bool enabled;

  // ─── Content ───────────────────────────────────────────────

  /// Icon inside the thumb per state.
  final Widget? activeIcon;
  final Widget? inactiveIcon;

  /// Labels OUTSIDE the track (start/end — top/bottom when vertical).
  final String? activeLabel;
  final String? inactiveLabel;
  final bool showLabels;

  /// Text INSIDE the track ("ON"/"OFF").
  final String? activeTrackLabel;
  final String? inactiveTrackLabel;

  /// Text inside the thumb (e.g. "I"/"O").
  final String? activeThumbText;
  final String? inactiveThumbText;

  // ─── Behavior ──────────────────────────────────────────────

  /// Spinner in the thumb; interaction blocked while loading.
  final bool loading;

  /// Enable drag/swipe gesture to toggle.
  final bool enableDrag;

  /// Debounce rapid taps — ignores toggles within 300ms.
  final bool debounce;

  /// Tooltip text (uses GlobalTooltip).
  final String? tooltip;

  /// Tooltip shown only when the switch is disabled.
  final String? disabledTooltip;

  /// Accessibility label. Null → localized On/Off state.
  final String? semanticLabel;

  /// Subtle pulse ring on the thumb when first mounted (skipped under
  /// reduced motion).
  final bool pulseOnMount;

  /// Vertical orientation.
  final bool isVertical;

  // ─── Convenience factories ─────────────────────────────────

  /// iOS-style switch — the deliberate Cupertino palette (these two
  /// hex values ARE the iOS look; they don't follow the app palette).
  factory GlobalSwitch.ios({
    Key? key,
    required bool value,
    required ValueChanged<bool>? onChanged,
    Color? activeColor,
  }) {
    return GlobalSwitch(
      key: key,
      value: value,
      onChanged: onChanged,
      enableDrag: true,
      style: SwitchStyle(
        activeColor: activeColor ?? const Color(0xFF34C759),
        inactiveColor: const Color(0xFFE9E9EA),
        width: 51,
        height: 31,
        thumbSize: 27,
        padding: const EdgeInsets.all(2),
        animationDuration: AppDurations.fast,
        animationCurve: Curves.easeOut,
        elevation: 0,
      ),
    );
  }

  /// Material 3-style switch (growing thumb, state icons).
  factory GlobalSwitch.material({
    Key? key,
    required bool value,
    required ValueChanged<bool>? onChanged,
    Color? activeColor,
    Widget? activeIcon,
    Widget? inactiveIcon,
  }) {
    return GlobalSwitch(
      key: key,
      value: value,
      onChanged: onChanged,
      activeIcon: activeIcon,
      inactiveIcon: inactiveIcon,
      style: SwitchStyle(
        activeColor: activeColor,
        width: 52,
        height: 32,
        thumbSize: 24,
        padding: const EdgeInsets.all(4),
        animateThumbSize: true,
      ),
    );
  }

  /// Small preset for dense rows.
  factory GlobalSwitch.compact({
    Key? key,
    required bool value,
    required ValueChanged<bool>? onChanged,
    Color? activeColor,
  }) {
    return GlobalSwitch(
      key: key,
      value: value,
      onChanged: onChanged,
      size: SwitchSize.small,
      style: SwitchStyle(activeColor: activeColor),
    );
  }

  @override
  State<GlobalSwitch> createState() => _GlobalSwitchState();
}
