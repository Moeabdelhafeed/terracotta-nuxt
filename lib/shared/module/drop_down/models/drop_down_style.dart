import 'package:flutter/material.dart';

import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/extensions/theme_colors_extension.dart';
import '../../../../core/tokens/extensions.dart';
import '../../list/list_models.dart' show EdgeFadeMode, EdgeFadeStyle;
import '../theme/drop_down_theme.dart';

export '../../list/list_models.dart' show EdgeFadeMode, EdgeFadeStyle;

// ---------------------------------------------------------------------------
// DropdownStyle — themeable overlay-row visual bag
// ---------------------------------------------------------------------------

/// Themeable visuals for the OPEN surface's rows — the analogue of
/// `TextFieldStyle` for the overlay side of the dropdown (the trigger is
/// themed by `TextFieldStyle` already).
///
/// Every field nullable; resolution stacks
/// `caller > GlobalDropdownTheme.style > defaults`, then fills color
/// fallbacks from `context.<group>Colors`. See [resolve].
@immutable
class DropdownStyle {
  const DropdownStyle({
    this.accentColor,
    this.selectedTint,
    this.flashTint,
    this.accentBarWidth,
    this.itemPadding,
    this.itemTextStyle,
    this.selectedItemTextStyle,
    this.groupHeaderTextStyle,
    this.checkboxSize,
    this.enableHaptic,
    this.edgeFade,
  });

  /// Drives selected-row text, check icon/checkbox, the selected accent
  /// bar and group headers. Default: `context.primaryColors.primary`.
  final Color? accentColor;

  /// Selected-row background. Default: [accentColor] at 8% alpha.
  final Color? selectedTint;

  /// Single-select post-tap flash. Default: [accentColor] at 20% alpha.
  final Color? flashTint;

  /// Width of the leading accent bar on a selected row. `0` hides it.
  final double? accentBarWidth;

  /// Row padding. Default: `md` horizontal / `sm + xs` vertical.
  final EdgeInsetsGeometry? itemPadding;

  /// Base row label style. Default: `textTheme.bodyMedium`.
  final TextStyle? itemTextStyle;

  /// Selected row label style. Default: [itemTextStyle] in
  /// [accentColor] at `w500`.
  final TextStyle? selectedItemTextStyle;

  /// Group header label style. Default: `labelSmall` in [accentColor],
  /// `w700`, letter-spaced.
  final TextStyle? groupHeaderTextStyle;

  /// Multi-select checkbox edge length.
  final double? checkboxSize;

  /// Haptic feedback on select / chip delete / clear. Default `true`.
  final bool? enableHaptic;

  /// Scroll-edge effect on the open list (same [EdgeFadeStyle] family
  /// as `GlobalList` / `GlobalScrollable` — shader / scrim /
  /// innerShadow / blur). Default: smart inner shadow — the list reads
  /// as recessed and the shadowed bottom edge doubles as the "more
  /// rows below" affordance. `EdgeFadeStyle.off` disables.
  final EdgeFadeStyle? edgeFade;

  /// Compile-time floor (colors excepted — they resolve from context).
  static const DropdownStyle defaults = DropdownStyle(
    accentBarWidth: 2,
    checkboxSize: 18,
    enableHaptic: true,
    edgeFade: EdgeFadeStyle(mode: EdgeFadeMode.innerShadow, size: 20),
  );

  /// Field-by-field overlay: `other` wins where non-null.
  DropdownStyle mergedWith(DropdownStyle? other) {
    if (other == null) return this;
    return DropdownStyle(
      accentColor: other.accentColor ?? accentColor,
      selectedTint: other.selectedTint ?? selectedTint,
      flashTint: other.flashTint ?? flashTint,
      accentBarWidth: other.accentBarWidth ?? accentBarWidth,
      itemPadding: other.itemPadding ?? itemPadding,
      itemTextStyle: other.itemTextStyle ?? itemTextStyle,
      selectedItemTextStyle:
          other.selectedItemTextStyle ?? selectedItemTextStyle,
      groupHeaderTextStyle: other.groupHeaderTextStyle ?? groupHeaderTextStyle,
      checkboxSize: other.checkboxSize ?? checkboxSize,
      enableHaptic: other.enableHaptic ?? enableHaptic,
      edgeFade: other.edgeFade ?? edgeFade,
    );
  }

  DropdownStyle copyWith({
    Color? accentColor,
    Color? selectedTint,
    Color? flashTint,
    double? accentBarWidth,
    EdgeInsetsGeometry? itemPadding,
    TextStyle? itemTextStyle,
    TextStyle? selectedItemTextStyle,
    TextStyle? groupHeaderTextStyle,
    double? checkboxSize,
    bool? enableHaptic,
    EdgeFadeStyle? edgeFade,
  }) {
    return DropdownStyle(
      accentColor: accentColor ?? this.accentColor,
      selectedTint: selectedTint ?? this.selectedTint,
      flashTint: flashTint ?? this.flashTint,
      accentBarWidth: accentBarWidth ?? this.accentBarWidth,
      itemPadding: itemPadding ?? this.itemPadding,
      itemTextStyle: itemTextStyle ?? this.itemTextStyle,
      selectedItemTextStyle:
          selectedItemTextStyle ?? this.selectedItemTextStyle,
      groupHeaderTextStyle: groupHeaderTextStyle ?? this.groupHeaderTextStyle,
      checkboxSize: checkboxSize ?? this.checkboxSize,
      enableHaptic: enableHaptic ?? this.enableHaptic,
      edgeFade: edgeFade ?? this.edgeFade,
    );
  }

  /// Materialize: `defaults → GlobalDropdownTheme → this`, then context
  /// color/text fallbacks. Call once per build.
  ResolvedDropdownStyle resolve(BuildContext context) {
    final theme = GlobalDropdownTheme.maybeOf(context);
    final s = defaults.mergedWith(theme?.style).mergedWith(this);
    final accent = s.accentColor ?? context.primaryColors.primary;
    final itemStyle =
        s.itemTextStyle ??
        context.textTheme.bodyMedium!.copyWith(
          color: context.textColors.primary,
        );
    return ResolvedDropdownStyle._(
      accentColor: accent,
      selectedTint: s.selectedTint ?? accent.withValues(alpha: 0.08),
      flashTint: s.flashTint ?? accent.withValues(alpha: 0.2),
      accentBarWidth: s.accentBarWidth!,
      itemPadding:
          s.itemPadding ??
          EdgeInsets.symmetric(
            horizontal: context.spacing.md,
            vertical: context.spacing.sm + context.spacing.xs,
          ),
      itemTextStyle: itemStyle,
      selectedItemTextStyle:
          s.selectedItemTextStyle ??
          itemStyle.copyWith(color: accent, fontWeight: FontWeight.w500),
      groupHeaderTextStyle:
          s.groupHeaderTextStyle ??
          context.textTheme.labelSmall!.copyWith(
            color: accent,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.2,
          ),
      checkboxSize: s.checkboxSize!,
      enableHaptic: s.enableHaptic!,
      edgeFade: s.edgeFade!,
    );
  }
}

/// Non-null snapshot of [DropdownStyle] after [DropdownStyle.resolve].
@immutable
class ResolvedDropdownStyle {
  const ResolvedDropdownStyle._({
    required this.accentColor,
    required this.selectedTint,
    required this.flashTint,
    required this.accentBarWidth,
    required this.itemPadding,
    required this.itemTextStyle,
    required this.selectedItemTextStyle,
    required this.groupHeaderTextStyle,
    required this.checkboxSize,
    required this.enableHaptic,
    required this.edgeFade,
  });

  final Color accentColor;
  final Color selectedTint;
  final Color flashTint;
  final double accentBarWidth;
  final EdgeInsetsGeometry itemPadding;
  final TextStyle itemTextStyle;
  final TextStyle selectedItemTextStyle;
  final TextStyle groupHeaderTextStyle;
  final double checkboxSize;
  final bool enableHaptic;
  final EdgeFadeStyle edgeFade;
}
