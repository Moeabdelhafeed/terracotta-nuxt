import 'package:flutter/material.dart';

import '../../../core/animations/animation_presets.dart';
import '../../../core/extensions/theme_colors_extension.dart';
import 'theme/radio_theme.dart';

// ---------------------------------------------------------------------------
// Constants
// ---------------------------------------------------------------------------

const kRadioDefaultSize = 24.0;
const kRadioDefaultBorderWidth = 2.0;
const kRadioDotScale = 0.45;
const kRadioAnimDuration = AppDurations.quick;
const kRadioLabelSpacing = 10.0;
const kRadioGroupSpacing = 12.0;
const kRadioDisabledOpacity = 0.5;
const kRadioHoverOpacity = 0.08;
const kRadioFocusOpacity = 0.12;
const kRadioScaleOnTap = 0.9;
const kRadioScaleDuration = AppDurations.micro;
const kRadioDebounceDuration = AppDurations.normal;
const kRadioTileVerticalPadding = 12.0;
const kRadioTileHorizontalPadding = 16.0;

// ---------------------------------------------------------------------------
// RadioVariant
// ---------------------------------------------------------------------------

/// Visual style of the radio indicator when selected.
enum RadioVariant {
  /// Standard radio with inner dot.
  dot,

  /// Filled circle (entire circle fills with color).
  filled,

  /// Checkmark inside a circle.
  checkmark,
}

// ---------------------------------------------------------------------------
// RadioLabelPosition
// ---------------------------------------------------------------------------

/// Position of the label relative to the radio.
enum RadioLabelPosition {
  /// Label to the trailing side (end).
  trailing,

  /// Label to the leading side (start).
  leading,
}

// ---------------------------------------------------------------------------
// RadioStyle — themeable bag
// ---------------------------------------------------------------------------

/// Themeable visuals for [GlobalRadio] / [GlobalRadioGroup] — the
/// analogue of `CheckboxStyle` / `SwitchStyle`.
///
/// Every field nullable; resolution stacks
/// `caller > GlobalRadioTheme.style > defaults`, then fills color
/// fallbacks from `context.<group>Colors`. See [resolve].
@immutable
class RadioStyle {
  const RadioStyle({
    this.size,
    this.borderWidth,
    this.selectedColor,
    this.unselectedColor,
    this.dotColor,
    this.borderColor,
    this.selectedBorderColor,
    this.disabledColor,
    this.hoverColor,
    this.focusColor,
    this.selectedGradient,
    this.borderGradient,
    this.selectedBorderGradient,
    this.shadow,
    this.selectedShadow,
    this.animationDuration,
    this.animationCurve,
    this.scaleOnTap,
    this.enableHaptic,
    this.dotScale,
    this.checkIcon,
    this.checkIconSize,
  });

  /// Size of the radio (width & height).
  final double? size;

  /// Border width.
  final double? borderWidth;

  /// Selection accent — the dot, filled background and selected border.
  /// Default: `context.primaryColors.primary`.
  final Color? selectedColor;

  /// Background when unselected. Default: transparent.
  final Color? unselectedColor;

  /// Inner-dot override ([RadioVariant.dot]). Default: [selectedColor].
  final Color? dotColor;

  /// Border color when unselected. Default: outline at 40%.
  final Color? borderColor;

  /// Border color when selected. Default: [selectedColor].
  final Color? selectedBorderColor;

  /// Color when disabled. Null → normal colors at reduced opacity.
  final Color? disabledColor;

  /// Hover overlay color (web/desktop).
  final Color? hoverColor;

  /// Focus ring overlay color (web/desktop).
  final Color? focusColor;

  /// Gradient fill when selected. Overrides [selectedColor].
  final Gradient? selectedGradient;

  /// Gradient border when unselected. Overrides [borderColor].
  final Gradient? borderGradient;

  /// Gradient border when selected. Overrides [selectedBorderColor].
  final Gradient? selectedBorderGradient;

  /// Shadow when unselected.
  final List<BoxShadow>? shadow;

  /// Shadow when selected.
  final List<BoxShadow>? selectedShadow;

  /// Duration of selection animation. Reduced motion collapses it to
  /// zero regardless.
  final Duration? animationDuration;

  /// Curve for the animation.
  final Curve? animationCurve;

  /// Scale-down effect on tap (skipped under reduced motion).
  final bool? scaleOnTap;

  /// Haptic feedback on select. Default `true`.
  final bool? enableHaptic;

  /// Scale of the inner dot relative to [size] ([RadioVariant.dot]).
  final double? dotScale;

  /// Custom icon for [RadioVariant.checkmark].
  final IconData? checkIcon;

  /// Icon size for [RadioVariant.checkmark]. Null → `size * 0.55`.
  final double? checkIconSize;

  /// Compile-time floor (colors excepted — they resolve from context).
  static const RadioStyle defaults = RadioStyle(
    size: kRadioDefaultSize,
    borderWidth: kRadioDefaultBorderWidth,
    animationDuration: kRadioAnimDuration,
    animationCurve: Curves.easeOutCubic,
    scaleOnTap: true,
    enableHaptic: true,
    dotScale: kRadioDotScale,
    checkIcon: Icons.check_rounded,
  );

  /// Field-by-field overlay: `other` wins where non-null.
  RadioStyle mergedWith(RadioStyle? other) {
    if (other == null) return this;
    return RadioStyle(
      size: other.size ?? size,
      borderWidth: other.borderWidth ?? borderWidth,
      selectedColor: other.selectedColor ?? selectedColor,
      unselectedColor: other.unselectedColor ?? unselectedColor,
      dotColor: other.dotColor ?? dotColor,
      borderColor: other.borderColor ?? borderColor,
      selectedBorderColor: other.selectedBorderColor ?? selectedBorderColor,
      disabledColor: other.disabledColor ?? disabledColor,
      hoverColor: other.hoverColor ?? hoverColor,
      focusColor: other.focusColor ?? focusColor,
      selectedGradient: other.selectedGradient ?? selectedGradient,
      borderGradient: other.borderGradient ?? borderGradient,
      selectedBorderGradient:
          other.selectedBorderGradient ?? selectedBorderGradient,
      shadow: other.shadow ?? shadow,
      selectedShadow: other.selectedShadow ?? selectedShadow,
      animationDuration: other.animationDuration ?? animationDuration,
      animationCurve: other.animationCurve ?? animationCurve,
      scaleOnTap: other.scaleOnTap ?? scaleOnTap,
      enableHaptic: other.enableHaptic ?? enableHaptic,
      dotScale: other.dotScale ?? dotScale,
      checkIcon: other.checkIcon ?? checkIcon,
      checkIconSize: other.checkIconSize ?? checkIconSize,
    );
  }

  /// Creates a copy with the given fields replaced.
  RadioStyle copyWith({
    double? size,
    double? borderWidth,
    Color? selectedColor,
    Color? unselectedColor,
    Color? dotColor,
    Color? borderColor,
    Color? selectedBorderColor,
    Color? disabledColor,
    Color? hoverColor,
    Color? focusColor,
    Gradient? selectedGradient,
    Gradient? borderGradient,
    Gradient? selectedBorderGradient,
    List<BoxShadow>? shadow,
    List<BoxShadow>? selectedShadow,
    Duration? animationDuration,
    Curve? animationCurve,
    bool? scaleOnTap,
    bool? enableHaptic,
    double? dotScale,
    IconData? checkIcon,
    double? checkIconSize,
  }) {
    return mergedWith(
      RadioStyle(
        size: size,
        borderWidth: borderWidth,
        selectedColor: selectedColor,
        unselectedColor: unselectedColor,
        dotColor: dotColor,
        borderColor: borderColor,
        selectedBorderColor: selectedBorderColor,
        disabledColor: disabledColor,
        hoverColor: hoverColor,
        focusColor: focusColor,
        selectedGradient: selectedGradient,
        borderGradient: borderGradient,
        selectedBorderGradient: selectedBorderGradient,
        shadow: shadow,
        selectedShadow: selectedShadow,
        animationDuration: animationDuration,
        animationCurve: animationCurve,
        scaleOnTap: scaleOnTap,
        enableHaptic: enableHaptic,
        dotScale: dotScale,
        checkIcon: checkIcon,
        checkIconSize: checkIconSize,
      ),
    );
  }

  /// Materialize: `defaults → GlobalRadioTheme → this`, then context
  /// color fallbacks. Call once per build.
  ResolvedRadioStyle resolve(BuildContext context) {
    final theme = GlobalRadioTheme.maybeOf(context);
    final s = defaults.mergedWith(theme?.style).mergedWith(this);
    final selected = s.selectedColor ?? context.primaryColors.primary;
    return ResolvedRadioStyle._(
      size: s.size!,
      borderWidth: s.borderWidth!,
      selectedColor: selected,
      unselectedColor: s.unselectedColor ?? Colors.transparent,
      dotColor: s.dotColor ?? selected,
      borderColor:
          s.borderColor ??
          context.backgroundColors.outline.withValues(alpha: 0.4),
      selectedBorderColor: s.selectedBorderColor ?? selected,
      disabledColor: s.disabledColor,
      hoverColor: s.hoverColor,
      focusColor: s.focusColor,
      selectedGradient: s.selectedGradient,
      borderGradient: s.borderGradient,
      selectedBorderGradient: s.selectedBorderGradient,
      shadow: s.shadow,
      selectedShadow: s.selectedShadow,
      animationDuration: s.animationDuration!,
      animationCurve: s.animationCurve!,
      scaleOnTap: s.scaleOnTap!,
      enableHaptic: s.enableHaptic!,
      dotScale: s.dotScale!,
      checkIcon: s.checkIcon!,
      checkIconSize: s.checkIconSize ?? s.size! * 0.55,
      onPrimary: context.textColors.onPrimary,
    );
  }
}

/// Non-null snapshot of [RadioStyle] after [RadioStyle.resolve]
/// (genuinely opt-in fields — gradients, shadows, disabled/hover/focus
/// overrides — stay nullable).
@immutable
class ResolvedRadioStyle {
  const ResolvedRadioStyle._({
    required this.size,
    required this.borderWidth,
    required this.selectedColor,
    required this.unselectedColor,
    required this.dotColor,
    required this.borderColor,
    required this.selectedBorderColor,
    required this.disabledColor,
    required this.hoverColor,
    required this.focusColor,
    required this.selectedGradient,
    required this.borderGradient,
    required this.selectedBorderGradient,
    required this.shadow,
    required this.selectedShadow,
    required this.animationDuration,
    required this.animationCurve,
    required this.scaleOnTap,
    required this.enableHaptic,
    required this.dotScale,
    required this.checkIcon,
    required this.checkIconSize,
    required this.onPrimary,
  });

  final double size;
  final double borderWidth;
  final Color selectedColor;
  final Color unselectedColor;
  final Color dotColor;
  final Color borderColor;
  final Color selectedBorderColor;
  final Color? disabledColor;
  final Color? hoverColor;
  final Color? focusColor;
  final Gradient? selectedGradient;
  final Gradient? borderGradient;
  final Gradient? selectedBorderGradient;
  final List<BoxShadow>? shadow;
  final List<BoxShadow>? selectedShadow;
  final Duration animationDuration;
  final Curve animationCurve;
  final bool scaleOnTap;
  final bool enableHaptic;
  final double dotScale;
  final IconData checkIcon;
  final double checkIconSize;

  /// `context.textColors.onPrimary` — the filled variant's check color.
  final Color onPrimary;
}
