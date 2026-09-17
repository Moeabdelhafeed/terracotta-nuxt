import 'package:flutter/material.dart';

import '../../switch/global_switch.dart';
import '../debug_overlay_models.dart';

/// THE on/off toggle for debug-overlay views — a [GlobalSwitch] wearing
/// the console palette so the overlay's previously hand-rolled
/// `Switch.adaptive` copies share one look and one implementation.
///
/// Fully controlled, like the primitive: displays [value], reports via
/// [onChanged].
class DebugSwitch extends StatelessWidget {
  const DebugSwitch({
    super.key,
    required this.value,
    required this.onChanged,
    this.activeColor,
    this.semanticLabel,
  });

  final bool value;
  final ValueChanged<bool>? onChanged;

  /// Active thumb/track tint. Null → [DebugOverlayTheme.accent]. The
  /// RC-overrides rows pass their "overridden" red.
  final Color? activeColor;

  /// Accessibility label. Null → the module's localized On/Off state.
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final accent = activeColor ?? DebugOverlayTheme.accent;
    return GlobalSwitch(
      value: value,
      onChanged: onChanged,
      semanticLabel: semanticLabel,
      size: SwitchSize.small,
      style: SwitchStyle(
        activeColor: accent.withValues(alpha: 0.4),
        activeThumbColor: accent,
        inactiveColor: DebugOverlayTheme.surfaceHigh,
        inactiveThumbColor: DebugOverlayTheme.textDim,
        borderColor: DebugOverlayTheme.border,
        borderWidth: 1,
      ),
    );
  }
}
