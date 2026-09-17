import 'package:flutter/material.dart';

import '../../../core/animations/animation_presets.dart';

// ---------------------------------------------------------------------------
// Constants
// ---------------------------------------------------------------------------

/// Geometry and tolerances that only change when this module changes.
/// Anything an app would rebrand lives on [ChipStyle] instead.
abstract final class ChipDefaults {
  static const borderRadius = 8.0;
  static const pillBorderRadius = 20.0;
  static const borderWidth = 1.0;
  static const elevation = 0.0;
  static const selectedElevation = 2.0;

  /// Inset around the LABEL, inside the chip's own padding.
  static const labelPadding = EdgeInsets.symmetric(horizontal: 4);

  /// The gradient path draws its own box, so it needs a full inset —
  /// Material's `Chip` supplies one and a hand-painted `Stack` does not.
  static const gradientPadding = EdgeInsets.symmetric(
    horizontal: 12,
    vertical: 8,
  );

  static const animationDuration = AppDurations.quick;
  static const deleteAnimationDuration = Duration(milliseconds: 250);

  static const iconSize = 18.0;
  static const deleteIconSize = 18.0;
  static const checkmarkSize = 16.0;
  static const loadingSize = 14.0;
  static const loadingStrokeWidth = 2.0;

  /// The count pill rides `GlobalBadge`, but a chip count is a NEUTRAL
  /// number rather than an alert, so it takes a wash of the chip's own
  /// foreground instead of the badge's error red.
  static const countFontSize = 11.0;
  static const countBackgroundOpacity = 0.2;

  /// Gaps between the label and whatever follows it.
  static const countGap = 6.0;
  static const trailingGap = 4.0;

  /// How much of its colour a disabled chip keeps, and how faint the
  /// resting borders are.
  static const disabledOpacity = 0.5;
  static const disabledBorderOpacity = 0.2;
  static const restingBorderOpacity = 0.2;
  static const outlinedBorderOpacity = 0.3;

  /// Tonal fill, at rest and selected.
  static const tonalOpacity = 0.08;
  static const tonalSelectedOpacity = 0.2;

  /// Selected fill for an OUTLINED chip — a tint, since the border is
  /// doing the work.
  static const outlinedSelectedOpacity = 0.1;

  /// Shadow spread, as a multiple of the elevation.
  static const shadowBlurFactor = 2.5;
}

// ---------------------------------------------------------------------------
// ChipVariant
// ---------------------------------------------------------------------------

/// Determines the visual style of the chip.
enum ChipVariant {
  /// Filled background when selected, outlined when not.
  filled,

  /// Always outlined with a border.
  outlined,

  /// Flat / tonal with a subtle background.
  tonal,
}

// ---------------------------------------------------------------------------
// ChipStyle
// ---------------------------------------------------------------------------

/// Themeable styling bag for `GlobalChip` — EVERY field nullable.
///
/// Resolution order, materialized once per build by `resolve`:
/// `caller > GlobalChipTheme.style > ChipStyle.defaults > palette`.
///
/// Adding a themed field means touching five places: here, [mergedWith],
/// [copyWith], [ResolvedChipStyle] and `GlobalChipTheme.lerp`.
@immutable
class ChipStyle {
  const ChipStyle({
    this.backgroundColor,
    this.selectedColor,
    this.disabledColor,
    this.labelColor,
    this.selectedLabelColor,
    this.disabledLabelColor,
    this.borderColor,
    this.selectedBorderColor,
    this.backgroundGradient,
    this.selectedBackgroundGradient,
    this.borderGradient,
    this.selectedBorderGradient,
    this.shadowColor,
    this.selectedShadowColor,
    this.labelStyle,
    this.labelPadding,
    this.padding,
    this.borderRadius,
    this.borderWidth,
    this.elevation,
    this.selectedElevation,
    this.checkmarkColor,
    this.deleteIconColor,
    this.animationDuration,
    this.animationCurve,
    this.deleteAnimationDuration,
    this.animateCheckmark,
    this.enableHaptic,
  });

  /// Compile-time floor. Colours are deliberately absent: they resolve
  /// from `context.<group>Colors` at build time so a chip tracks role,
  /// brightness and saturation.
  static const ChipStyle defaults = ChipStyle(
    labelPadding: ChipDefaults.labelPadding,
    borderRadius: BorderRadius.all(Radius.circular(ChipDefaults.borderRadius)),
    borderWidth: ChipDefaults.borderWidth,
    elevation: ChipDefaults.elevation,
    selectedElevation: ChipDefaults.selectedElevation,
    animationDuration: ChipDefaults.animationDuration,
    animationCurve: Curves.easeOut,
    deleteAnimationDuration: ChipDefaults.deleteAnimationDuration,
    animateCheckmark: true,
    enableHaptic: true,
  );

  /// Pill geometry, for `GlobalChip.pill` and for anyone who wants the
  /// shape without the factory.
  static const ChipStyle pill = ChipStyle(
    borderRadius: BorderRadius.all(
      Radius.circular(ChipDefaults.pillBorderRadius),
    ),
  );

  final Color? backgroundColor;
  final Color? selectedColor;
  final Color? disabledColor;

  final Color? labelColor;
  final Color? selectedLabelColor;
  final Color? disabledLabelColor;

  final Color? borderColor;
  final Color? selectedBorderColor;

  final Gradient? backgroundGradient;
  final Gradient? selectedBackgroundGradient;
  final Gradient? borderGradient;
  final Gradient? selectedBorderGradient;

  final Color? shadowColor;
  final Color? selectedShadowColor;

  final TextStyle? labelStyle;

  /// Inset around the label, inside [padding].
  final EdgeInsetsGeometry? labelPadding;

  /// Inset around the chip's whole content.
  final EdgeInsetsGeometry? padding;

  final BorderRadius? borderRadius;
  final double? borderWidth;

  final double? elevation;
  final double? selectedElevation;

  final Color? checkmarkColor;
  final Color? deleteIconColor;

  final Duration? animationDuration;
  final Curve? animationCurve;

  /// How long a chip takes to shrink away when `animateDelete` is on.
  final Duration? deleteAnimationDuration;

  /// Whether the checkmark springs in, or simply appears.
  final bool? animateCheckmark;

  /// Whether selecting a chip plays a haptic.
  final bool? enableHaptic;

  /// Whether any gradient is set. A gradient chip renders through a
  /// different path, since `Border` takes colours, not gradients.
  bool get hasGradient =>
      backgroundGradient != null ||
      selectedBackgroundGradient != null ||
      borderGradient != null ||
      selectedBorderGradient != null;

  /// Field-by-field override — anything set on [other] wins.
  ChipStyle mergedWith(ChipStyle? other) {
    if (other == null) return this;
    return ChipStyle(
      backgroundColor: other.backgroundColor ?? backgroundColor,
      selectedColor: other.selectedColor ?? selectedColor,
      disabledColor: other.disabledColor ?? disabledColor,
      labelColor: other.labelColor ?? labelColor,
      selectedLabelColor: other.selectedLabelColor ?? selectedLabelColor,
      disabledLabelColor: other.disabledLabelColor ?? disabledLabelColor,
      borderColor: other.borderColor ?? borderColor,
      selectedBorderColor: other.selectedBorderColor ?? selectedBorderColor,
      backgroundGradient: other.backgroundGradient ?? backgroundGradient,
      selectedBackgroundGradient:
          other.selectedBackgroundGradient ?? selectedBackgroundGradient,
      borderGradient: other.borderGradient ?? borderGradient,
      selectedBorderGradient:
          other.selectedBorderGradient ?? selectedBorderGradient,
      shadowColor: other.shadowColor ?? shadowColor,
      selectedShadowColor: other.selectedShadowColor ?? selectedShadowColor,
      labelStyle: other.labelStyle ?? labelStyle,
      labelPadding: other.labelPadding ?? labelPadding,
      padding: other.padding ?? padding,
      borderRadius: other.borderRadius ?? borderRadius,
      borderWidth: other.borderWidth ?? borderWidth,
      elevation: other.elevation ?? elevation,
      selectedElevation: other.selectedElevation ?? selectedElevation,
      checkmarkColor: other.checkmarkColor ?? checkmarkColor,
      deleteIconColor: other.deleteIconColor ?? deleteIconColor,
      animationDuration: other.animationDuration ?? animationDuration,
      animationCurve: other.animationCurve ?? animationCurve,
      deleteAnimationDuration:
          other.deleteAnimationDuration ?? deleteAnimationDuration,
      animateCheckmark: other.animateCheckmark ?? animateCheckmark,
      enableHaptic: other.enableHaptic ?? enableHaptic,
    );
  }

  ChipStyle copyWith({
    Color? backgroundColor,
    Color? selectedColor,
    Color? disabledColor,
    Color? labelColor,
    Color? selectedLabelColor,
    Color? disabledLabelColor,
    Color? borderColor,
    Color? selectedBorderColor,
    Gradient? backgroundGradient,
    Gradient? selectedBackgroundGradient,
    Gradient? borderGradient,
    Gradient? selectedBorderGradient,
    Color? shadowColor,
    Color? selectedShadowColor,
    TextStyle? labelStyle,
    EdgeInsetsGeometry? labelPadding,
    EdgeInsetsGeometry? padding,
    BorderRadius? borderRadius,
    double? borderWidth,
    double? elevation,
    double? selectedElevation,
    Color? checkmarkColor,
    Color? deleteIconColor,
    Duration? animationDuration,
    Curve? animationCurve,
    Duration? deleteAnimationDuration,
    bool? animateCheckmark,
    bool? enableHaptic,
  }) => ChipStyle(
    backgroundColor: backgroundColor ?? this.backgroundColor,
    selectedColor: selectedColor ?? this.selectedColor,
    disabledColor: disabledColor ?? this.disabledColor,
    labelColor: labelColor ?? this.labelColor,
    selectedLabelColor: selectedLabelColor ?? this.selectedLabelColor,
    disabledLabelColor: disabledLabelColor ?? this.disabledLabelColor,
    borderColor: borderColor ?? this.borderColor,
    selectedBorderColor: selectedBorderColor ?? this.selectedBorderColor,
    backgroundGradient: backgroundGradient ?? this.backgroundGradient,
    selectedBackgroundGradient:
        selectedBackgroundGradient ?? this.selectedBackgroundGradient,
    borderGradient: borderGradient ?? this.borderGradient,
    selectedBorderGradient:
        selectedBorderGradient ?? this.selectedBorderGradient,
    shadowColor: shadowColor ?? this.shadowColor,
    selectedShadowColor: selectedShadowColor ?? this.selectedShadowColor,
    labelStyle: labelStyle ?? this.labelStyle,
    labelPadding: labelPadding ?? this.labelPadding,
    padding: padding ?? this.padding,
    borderRadius: borderRadius ?? this.borderRadius,
    borderWidth: borderWidth ?? this.borderWidth,
    elevation: elevation ?? this.elevation,
    selectedElevation: selectedElevation ?? this.selectedElevation,
    checkmarkColor: checkmarkColor ?? this.checkmarkColor,
    deleteIconColor: deleteIconColor ?? this.deleteIconColor,
    animationDuration: animationDuration ?? this.animationDuration,
    animationCurve: animationCurve ?? this.animationCurve,
    deleteAnimationDuration:
        deleteAnimationDuration ?? this.deleteAnimationDuration,
    animateCheckmark: animateCheckmark ?? this.animateCheckmark,
    enableHaptic: enableHaptic ?? this.enableHaptic,
  );
}

// ---------------------------------------------------------------------------
// ResolvedChipStyle
// ---------------------------------------------------------------------------

/// [ChipStyle] after `caller > theme > defaults > palette`, for the
/// chip's CURRENT state. Every themed field is non-null, so build code
/// reads `rs.foreground` with no `??` ladder behind it.
///
/// Both fills are carried rather than just the active one, because
/// Material's `ChoiceChip` takes `backgroundColor` AND `selectedColor`
/// so it can cross-fade between them itself.
@immutable
class ResolvedChipStyle {
  const ResolvedChipStyle({
    required this.background,
    required this.selectedBackground,
    required this.disabledBackground,
    required this.foreground,
    required this.border,
    required this.labelStyle,
    required this.labelPadding,
    required this.borderRadius,
    required this.borderWidth,
    required this.elevation,
    required this.checkmarkColor,
    required this.deleteIconColor,
    required this.countBackground,
    required this.animationDuration,
    required this.animationCurve,
    required this.deleteAnimationDuration,
    required this.animateCheckmark,
    required this.enableHaptic,
    required this.hasGradient,
    this.padding,
    this.backgroundGradient,
    this.borderGradient,
    this.shadowColor,
  });

  /// Fill at rest and when selected. Material animates between them.
  final Color background;
  final Color selectedBackground;
  final Color disabledBackground;

  /// Label, checkmark and delete-icon colour for the CURRENT state.
  final Color foreground;

  /// Border for the CURRENT state.
  final BorderSide border;

  final TextStyle labelStyle;
  final EdgeInsetsGeometry labelPadding;
  final EdgeInsetsGeometry? padding;
  final BorderRadius borderRadius;
  final double borderWidth;

  /// Elevation for the CURRENT state.
  final double elevation;

  final Color checkmarkColor;
  final Color deleteIconColor;

  /// Wash behind the count pill.
  final Color countBackground;

  final Duration animationDuration;
  final Curve animationCurve;
  final Duration deleteAnimationDuration;
  final bool animateCheckmark;
  final bool enableHaptic;

  /// Whether the caller asked for any gradient, which decides the build
  /// path — `Border` takes colours, not gradients.
  final bool hasGradient;

  /// Gradients for the CURRENT state.
  final Gradient? backgroundGradient;
  final Gradient? borderGradient;

  /// Shadow colour for the CURRENT state; null means no custom shadow.
  final Color? shadowColor;

  /// The shape Material and the gradient painter both draw.
  RoundedRectangleBorder get shape =>
      RoundedRectangleBorder(borderRadius: borderRadius, side: border);

  /// Whether a custom shadow paints at all.
  bool get hasShadow => shadowColor != null && elevation > 0;

  /// Blur for [hasShadow], derived so raising the elevation spreads the
  /// shadow with it rather than leaving a fixed smudge.
  double get shadowBlur => elevation * ChipDefaults.shadowBlurFactor;
}
