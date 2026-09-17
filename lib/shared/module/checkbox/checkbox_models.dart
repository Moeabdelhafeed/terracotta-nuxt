import 'package:flutter/material.dart';

import '../../../core/animations/animation_presets.dart';
import '../../../core/extensions/theme_colors_extension.dart';
import '../text_field/text_field.dart' show ValidationMode;
import 'theme/checkbox_theme.dart';

// ---------------------------------------------------------------------------
// Constants
// ---------------------------------------------------------------------------

const kCheckboxDefaultSize = 24.0;
const kCheckboxDefaultBorderWidth = 2.0;
const kCheckboxDefaultBorderRadius = 6.0;
const kCheckboxCircleBorderRadius = 999.0;
const kCheckboxAnimDuration = AppDurations.quick;
const kCheckboxLabelSpacing = 10.0;
const kCheckboxGroupSpacing = 12.0;
const kCheckboxDisabledOpacity = 0.5;
const kCheckboxHoverOpacity = 0.08;
const kCheckboxFocusOpacity = 0.12;
const kCheckboxScaleOnTap = 0.9;
const kCheckboxScaleDuration = AppDurations.micro;
const kCheckboxDebounceDuration = AppDurations.normal;
const kCheckboxTileVerticalPadding = 12.0;
const kCheckboxTileHorizontalPadding = 16.0;

// ---------------------------------------------------------------------------
// CheckboxVariant
// ---------------------------------------------------------------------------

/// Visual shape/style of the checkbox. For a switch/toggle pill use
/// the dedicated `GlobalSwitch` module — a toggle variant here would
/// only duplicate it.
enum CheckboxVariant {
  /// Standard rounded rectangle checkbox.
  standard,

  /// Circular checkbox.
  circle,
}

// ---------------------------------------------------------------------------
// CheckboxValue
// ---------------------------------------------------------------------------

/// Tri-state value for a checkbox.
enum CheckboxValue {
  /// Unchecked.
  unchecked,

  /// Checked.
  checked,

  /// Indeterminate (dash icon).
  indeterminate,
}

// ---------------------------------------------------------------------------
// CheckboxLabelPosition
// ---------------------------------------------------------------------------

/// Position of the label relative to the checkbox.
enum CheckboxLabelPosition {
  /// Label to the trailing side (end).
  trailing,

  /// Label to the leading side (start).
  leading,
}

// ---------------------------------------------------------------------------
// CheckboxValidation
// ---------------------------------------------------------------------------

/// Validation config for the checkbox `FormField` wrappers — the
/// analogue of `DropdownValidation`. [ValidationMode] is reused from the
/// text field, reinterpreted for a tap control:
///
/// | mode                        | trigger                                |
/// |-----------------------------|----------------------------------------|
/// | `onSubmit` (default)        | `Form.validate()` only                 |
/// | `onInteraction` / `realTime`| every toggle                           |
/// | `onFocusLoss`               | same as `onInteraction` — a checkbox   |
/// |                             | has no meaningful focus-loss moment    |
/// | `none`                      | external `errorText` only              |
@immutable
class CheckboxValidation<V> {
  const CheckboxValidation({
    this.validator,
    this.errorText,
    this.mode = ValidationMode.onSubmit,
    this.deferToParentForm = true,
    this.revalidateKey,
  });

  /// Sync check — return the error string or null.
  final FormFieldValidator<V>? validator;

  /// External error (server-side) — wins over [validator]'s result.
  final String? errorText;

  final ValidationMode mode;

  /// Keep `true` inside a `Form` (only live modes hand the Form
  /// `AutovalidateMode.onUserInteraction`); `false` for standalone
  /// fields so internal triggers drive validation.
  final bool deferToParentForm;

  /// Encode rule inputs (`revalidateKey: (mustAccept, plan)`); when the
  /// key changes, an interacted-with (or error-showing) field
  /// re-validates immediately.
  final Object? revalidateKey;

  /// Whether this mode validates on every toggle.
  bool get validatesOnChange =>
      mode == ValidationMode.onInteraction ||
      mode == ValidationMode.realTime ||
      mode == ValidationMode.onFocusLoss;
}

// ---------------------------------------------------------------------------
// CheckboxStyle — themeable bag
// ---------------------------------------------------------------------------

/// Themeable visuals for [GlobalCheckbox] — the analogue of
/// `TextFieldStyle` / `DropdownStyle`.
///
/// Every field nullable; resolution stacks
/// `caller > GlobalCheckboxTheme.style > defaults`, then fills color
/// fallbacks from `context.<group>Colors`. See [resolve].
@immutable
class CheckboxStyle {
  const CheckboxStyle({
    this.size,
    this.borderWidth,
    this.borderRadius,
    this.checkedColor,
    this.uncheckedColor,
    this.checkColor,
    this.borderColor,
    this.checkedBorderColor,
    this.disabledColor,
    this.hoverColor,
    this.focusColor,
    this.checkedGradient,
    this.borderGradient,
    this.checkedBorderGradient,
    this.shadow,
    this.checkedShadow,
    this.animationDuration,
    this.animationCurve,
    this.checkIcon,
    this.indeterminateIcon,
    this.iconSize,
    this.scaleOnTap,
    this.enableHaptic,
  });

  /// Size of the checkbox (width & height).
  final double? size;

  /// Border width.
  final double? borderWidth;

  /// Border radius. Null → per-variant default (rounded rect / circle).
  final BorderRadius? borderRadius;

  /// Background color when checked. Default:
  /// `context.primaryColors.primary`.
  final Color? checkedColor;

  /// Background color when unchecked. Default: transparent.
  final Color? uncheckedColor;

  /// Color of the check icon. Default: `context.textColors.onPrimary`.
  final Color? checkColor;

  /// Border color when unchecked. Default: outline at 40%.
  final Color? borderColor;

  /// Border color when checked. Default: [checkedColor].
  final Color? checkedBorderColor;

  /// Background and border color when disabled. Null → the normal
  /// colors at reduced opacity.
  final Color? disabledColor;

  /// Hover overlay color (web/desktop). Null → check color at 15% when
  /// checked, [checkedColor] at 8% when unchecked.
  final Color? hoverColor;

  /// Focus ring overlay color (web/desktop). Null → check color at 25%
  /// when checked, [checkedColor] at 12% when unchecked.
  final Color? focusColor;

  /// Gradient background when checked. Overrides [checkedColor].
  final Gradient? checkedGradient;

  /// Gradient border when unchecked. Overrides [borderColor].
  final Gradient? borderGradient;

  /// Gradient border when checked. Overrides [checkedBorderColor].
  final Gradient? checkedBorderGradient;

  /// Shadow when unchecked.
  final List<BoxShadow>? shadow;

  /// Shadow when checked.
  final List<BoxShadow>? checkedShadow;

  /// Duration of check/uncheck animation. Reduced motion collapses it
  /// to zero regardless.
  final Duration? animationDuration;

  /// Curve for the animation.
  final Curve? animationCurve;

  /// Custom check icon.
  final IconData? checkIcon;

  /// Custom indeterminate icon.
  final IconData? indeterminateIcon;

  /// Size of the check icon. Null → `size * 0.65`.
  final double? iconSize;

  /// Scale-down effect on tap (skipped under reduced motion).
  final bool? scaleOnTap;

  /// Haptic feedback on toggle. Default `true`.
  final bool? enableHaptic;

  /// Compile-time floor (colors excepted — they resolve from context).
  static const CheckboxStyle defaults = CheckboxStyle(
    size: kCheckboxDefaultSize,
    borderWidth: kCheckboxDefaultBorderWidth,
    animationDuration: kCheckboxAnimDuration,
    animationCurve: Curves.easeOutCubic,
    checkIcon: Icons.check_rounded,
    indeterminateIcon: Icons.remove_rounded,
    scaleOnTap: true,
    enableHaptic: true,
  );

  /// Field-by-field overlay: `other` wins where non-null.
  CheckboxStyle mergedWith(CheckboxStyle? other) {
    if (other == null) return this;
    return CheckboxStyle(
      size: other.size ?? size,
      borderWidth: other.borderWidth ?? borderWidth,
      borderRadius: other.borderRadius ?? borderRadius,
      checkedColor: other.checkedColor ?? checkedColor,
      uncheckedColor: other.uncheckedColor ?? uncheckedColor,
      checkColor: other.checkColor ?? checkColor,
      borderColor: other.borderColor ?? borderColor,
      checkedBorderColor: other.checkedBorderColor ?? checkedBorderColor,
      disabledColor: other.disabledColor ?? disabledColor,
      hoverColor: other.hoverColor ?? hoverColor,
      focusColor: other.focusColor ?? focusColor,
      checkedGradient: other.checkedGradient ?? checkedGradient,
      borderGradient: other.borderGradient ?? borderGradient,
      checkedBorderGradient:
          other.checkedBorderGradient ?? checkedBorderGradient,
      shadow: other.shadow ?? shadow,
      checkedShadow: other.checkedShadow ?? checkedShadow,
      animationDuration: other.animationDuration ?? animationDuration,
      animationCurve: other.animationCurve ?? animationCurve,
      checkIcon: other.checkIcon ?? checkIcon,
      indeterminateIcon: other.indeterminateIcon ?? indeterminateIcon,
      iconSize: other.iconSize ?? iconSize,
      scaleOnTap: other.scaleOnTap ?? scaleOnTap,
      enableHaptic: other.enableHaptic ?? enableHaptic,
    );
  }

  /// Creates a copy with the given fields replaced.
  CheckboxStyle copyWith({
    double? size,
    double? borderWidth,
    BorderRadius? borderRadius,
    Color? checkedColor,
    Color? uncheckedColor,
    Color? checkColor,
    Color? borderColor,
    Color? checkedBorderColor,
    Color? disabledColor,
    Color? hoverColor,
    Color? focusColor,
    Gradient? checkedGradient,
    Gradient? borderGradient,
    Gradient? checkedBorderGradient,
    List<BoxShadow>? shadow,
    List<BoxShadow>? checkedShadow,
    Duration? animationDuration,
    Curve? animationCurve,
    IconData? checkIcon,
    IconData? indeterminateIcon,
    double? iconSize,
    bool? scaleOnTap,
    bool? enableHaptic,
  }) {
    return CheckboxStyle(
      size: size ?? this.size,
      borderWidth: borderWidth ?? this.borderWidth,
      borderRadius: borderRadius ?? this.borderRadius,
      checkedColor: checkedColor ?? this.checkedColor,
      uncheckedColor: uncheckedColor ?? this.uncheckedColor,
      checkColor: checkColor ?? this.checkColor,
      borderColor: borderColor ?? this.borderColor,
      checkedBorderColor: checkedBorderColor ?? this.checkedBorderColor,
      disabledColor: disabledColor ?? this.disabledColor,
      hoverColor: hoverColor ?? this.hoverColor,
      focusColor: focusColor ?? this.focusColor,
      checkedGradient: checkedGradient ?? this.checkedGradient,
      borderGradient: borderGradient ?? this.borderGradient,
      checkedBorderGradient:
          checkedBorderGradient ?? this.checkedBorderGradient,
      shadow: shadow ?? this.shadow,
      checkedShadow: checkedShadow ?? this.checkedShadow,
      animationDuration: animationDuration ?? this.animationDuration,
      animationCurve: animationCurve ?? this.animationCurve,
      checkIcon: checkIcon ?? this.checkIcon,
      indeterminateIcon: indeterminateIcon ?? this.indeterminateIcon,
      iconSize: iconSize ?? this.iconSize,
      scaleOnTap: scaleOnTap ?? this.scaleOnTap,
      enableHaptic: enableHaptic ?? this.enableHaptic,
    );
  }

  /// Materialize: `defaults → GlobalCheckboxTheme → this`, then context
  /// color fallbacks. [variant] picks the default border radius. Call
  /// once per build.
  ResolvedCheckboxStyle resolve(
    BuildContext context, {
    CheckboxVariant variant = CheckboxVariant.standard,
  }) {
    final theme = GlobalCheckboxTheme.maybeOf(context);
    final s = defaults.mergedWith(theme?.style).mergedWith(this);
    final checked = s.checkedColor ?? context.primaryColors.primary;
    return ResolvedCheckboxStyle._(
      size: s.size!,
      borderWidth: s.borderWidth!,
      borderRadius:
          s.borderRadius ??
          switch (variant) {
            CheckboxVariant.standard => BorderRadius.circular(
              kCheckboxDefaultBorderRadius,
            ),
            CheckboxVariant.circle => BorderRadius.circular(
              kCheckboxCircleBorderRadius,
            ),
          },
      checkedColor: checked,
      uncheckedColor: s.uncheckedColor ?? Colors.transparent,
      checkColor: s.checkColor ?? context.textColors.onPrimary,
      borderColor:
          s.borderColor ??
          context.backgroundColors.outline.withValues(alpha: 0.4),
      checkedBorderColor: s.checkedBorderColor ?? checked,
      disabledColor: s.disabledColor,
      hoverColor: s.hoverColor,
      focusColor: s.focusColor,
      checkedGradient: s.checkedGradient,
      borderGradient: s.borderGradient,
      checkedBorderGradient: s.checkedBorderGradient,
      shadow: s.shadow,
      checkedShadow: s.checkedShadow,
      animationDuration: s.animationDuration!,
      animationCurve: s.animationCurve!,
      checkIcon: s.checkIcon!,
      indeterminateIcon: s.indeterminateIcon!,
      iconSize: s.iconSize ?? s.size! * 0.65,
      scaleOnTap: s.scaleOnTap!,
      enableHaptic: s.enableHaptic!,
    );
  }
}

/// Non-null snapshot of [CheckboxStyle] after [CheckboxStyle.resolve]
/// (genuinely opt-in fields — gradients, shadows, disabled/hover/focus
/// overrides — stay nullable).
@immutable
class ResolvedCheckboxStyle {
  const ResolvedCheckboxStyle._({
    required this.size,
    required this.borderWidth,
    required this.borderRadius,
    required this.checkedColor,
    required this.uncheckedColor,
    required this.checkColor,
    required this.borderColor,
    required this.checkedBorderColor,
    required this.disabledColor,
    required this.hoverColor,
    required this.focusColor,
    required this.checkedGradient,
    required this.borderGradient,
    required this.checkedBorderGradient,
    required this.shadow,
    required this.checkedShadow,
    required this.animationDuration,
    required this.animationCurve,
    required this.checkIcon,
    required this.indeterminateIcon,
    required this.iconSize,
    required this.scaleOnTap,
    required this.enableHaptic,
  });

  final double size;
  final double borderWidth;
  final BorderRadius borderRadius;
  final Color checkedColor;
  final Color uncheckedColor;
  final Color checkColor;
  final Color borderColor;
  final Color checkedBorderColor;
  final Color? disabledColor;
  final Color? hoverColor;
  final Color? focusColor;
  final Gradient? checkedGradient;
  final Gradient? borderGradient;
  final Gradient? checkedBorderGradient;
  final List<BoxShadow>? shadow;
  final List<BoxShadow>? checkedShadow;
  final Duration animationDuration;
  final Curve animationCurve;
  final IconData checkIcon;
  final IconData indeterminateIcon;
  final double iconSize;
  final bool scaleOnTap;
  final bool enableHaptic;
}
