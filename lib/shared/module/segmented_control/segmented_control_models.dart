import 'package:flutter/material.dart';

import '../../../core/animations/animation_presets.dart';
import '../../../core/extensions/context_extensions.dart';
import '../../../core/extensions/theme_colors_extension.dart';
import 'theme/segmented_control_theme.dart';

// ---------------------------------------------------------------------------
// Constants
// ---------------------------------------------------------------------------

const kSegmentedAnimDuration = AppDurations.quick;
const kSegmentedDefaultHeight = 40.0;
const kSegmentedCompactHeight = 32.0;
const kSegmentedLargeHeight = 48.0;
const kSegmentedDefaultRadius = 10.0;
const kSegmentedDefaultPaddingH = 16.0;
const kSegmentedIconSpacing = 6.0;
const kSegmentedIconSize = 18.0;
const kSegmentedDisabledOpacity = 0.5;
const kSegmentedHoverOpacity = 0.06;
const kSegmentedIndicatorPadding = 3.0;
const kSegmentedFocusRingWidth = 2.0;
const kSegmentedFocusRingOpacity = 0.5;

// ---------------------------------------------------------------------------
// SegmentedVariant
// ---------------------------------------------------------------------------

/// Visual style of the segmented control.
enum SegmentedVariant {
  /// Selected segment has a filled background (pill/card).
  filled,

  /// Selected segment has a border highlight, others are borderless.
  outlined,

  /// Subtle tonal background on the selected segment.
  tonal,
}

// ---------------------------------------------------------------------------
// SegmentedSize
// ---------------------------------------------------------------------------

/// Predefined size presets.
enum SegmentedSize {
  compact(kSegmentedCompactHeight),
  regular(kSegmentedDefaultHeight),
  large(kSegmentedLargeHeight);

  const SegmentedSize(this.value);
  final double value;
}

// ---------------------------------------------------------------------------
// SegmentItem
// ---------------------------------------------------------------------------

/// A single segment in a [GlobalSegmentedControl].
@immutable
class SegmentItem<T> {
  const SegmentItem({
    required this.value,
    required this.label,
    this.icon,
    this.iconWidget,
    this.trailing,
    this.enabled = true,
  });

  /// The value this segment represents.
  final T value;

  /// Text label.
  final String label;

  /// Icon displayed before the label. Ignored when [iconWidget] is set.
  final IconData? icon;

  /// Custom icon widget. Takes priority over [icon].
  final Widget? iconWidget;

  /// Drawn AFTER the label, in reading order — a count badge, a dot.
  ///
  /// The leading slot cannot stand in for it: a count belongs behind
  /// the thing it counts, and in Arabic "before" is the right-hand
  /// side, so an icon slot puts it on the wrong end of the words.
  final Widget? trailing;

  /// Whether this segment is selectable.
  final bool enabled;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SegmentItem<T> && other.value == value && other.label == label;

  @override
  int get hashCode => Object.hash(value, label);
}

// ---------------------------------------------------------------------------
// SegmentedStyle — themeable bag
// ---------------------------------------------------------------------------

/// Themeable visuals for [GlobalSegmentedControl] — the analogue of the
/// other selection-control bags.
///
/// Every field nullable; resolution stacks
/// `caller > GlobalSegmentedControlTheme.style > defaults`, then fills
/// color fallbacks from `context.<group>Colors`. See [resolve].
@immutable
class SegmentedStyle {
  const SegmentedStyle({
    this.backgroundColor,
    this.backgroundGradient,
    this.selectedColor,
    this.selectedGradient,
    this.selectedForegroundColor,
    this.unselectedForegroundColor,
    this.disabledColor,
    this.indicatorShadow,
    this.borderColor,
    this.borderGradient,
    this.borderWidth,
    this.borderRadius,
    this.height,
    this.sizePreset,
    this.segmentPadding,
    this.indicatorPadding,
    this.animationDuration,
    this.animationCurve,
    this.selectedTextStyle,
    this.unselectedTextStyle,
    this.iconSize,
    this.iconSpacing,
    this.expandEqual,
    this.enableHaptic,
    this.shadow,
  });

  /// Background of the entire track. Default: outline at 8%.
  final Color? backgroundColor;

  /// Background gradient for the track. Overrides [backgroundColor].
  final Gradient? backgroundGradient;

  /// Background of the selected indicator. Defaults per variant
  /// (filled → surface, tonal → primary at 12%).
  final Color? selectedColor;

  /// Gradient for the selected indicator. Overrides [selectedColor].
  final Gradient? selectedGradient;

  /// Text/icon color for the selected segment.
  final Color? selectedForegroundColor;

  /// Text/icon color for unselected segments. Default:
  /// `context.textColors.secondary`.
  final Color? unselectedForegroundColor;

  /// Color applied to disabled segments.
  final Color? disabledColor;

  /// Shadow on the selected indicator pill.
  final List<BoxShadow>? indicatorShadow;

  /// Border color around the entire track.
  final Color? borderColor;

  /// Gradient border around the track. Overrides [borderColor].
  final Gradient? borderGradient;

  /// Border width.
  final double? borderWidth;

  /// Border radius of the track and indicator.
  final BorderRadius? borderRadius;

  /// Explicit height. Overrides [sizePreset].
  final double? height;

  /// Predefined size preset.
  final SegmentedSize? sizePreset;

  /// Padding inside each segment (around label).
  final EdgeInsets? segmentPadding;

  /// Padding between the track edge and the indicator.
  final double? indicatorPadding;

  /// Duration of the sliding indicator animation. Reduced motion
  /// collapses it to zero.
  final Duration? animationDuration;

  /// Curve for the sliding animation.
  final Curve? animationCurve;

  /// Text style for the selected segment label.
  final TextStyle? selectedTextStyle;

  /// Text style for unselected segment labels.
  final TextStyle? unselectedTextStyle;

  /// Size of segment icons.
  final double? iconSize;

  /// Spacing between icon and label.
  final double? iconSpacing;

  /// When true, all segments have equal width. When false, intrinsic.
  final bool? expandEqual;

  /// Haptic feedback on selection change. Default `true`.
  final bool? enableHaptic;

  /// Shadow on the entire track.
  final List<BoxShadow>? shadow;

  /// Compile-time floor (colors excepted — they resolve from context).
  static const SegmentedStyle defaults = SegmentedStyle(
    borderWidth: 1.0,
    indicatorPadding: kSegmentedIndicatorPadding,
    animationDuration: kSegmentedAnimDuration,
    animationCurve: Curves.easeInOut,
    iconSize: kSegmentedIconSize,
    iconSpacing: kSegmentedIconSpacing,
    expandEqual: true,
    enableHaptic: true,
  );

  /// Field-by-field overlay: `other` wins where non-null.
  SegmentedStyle mergedWith(SegmentedStyle? other) {
    if (other == null) return this;
    return SegmentedStyle(
      backgroundColor: other.backgroundColor ?? backgroundColor,
      backgroundGradient: other.backgroundGradient ?? backgroundGradient,
      selectedColor: other.selectedColor ?? selectedColor,
      selectedGradient: other.selectedGradient ?? selectedGradient,
      selectedForegroundColor:
          other.selectedForegroundColor ?? selectedForegroundColor,
      unselectedForegroundColor:
          other.unselectedForegroundColor ?? unselectedForegroundColor,
      disabledColor: other.disabledColor ?? disabledColor,
      indicatorShadow: other.indicatorShadow ?? indicatorShadow,
      borderColor: other.borderColor ?? borderColor,
      borderGradient: other.borderGradient ?? borderGradient,
      borderWidth: other.borderWidth ?? borderWidth,
      borderRadius: other.borderRadius ?? borderRadius,
      height: other.height ?? height,
      sizePreset: other.sizePreset ?? sizePreset,
      segmentPadding: other.segmentPadding ?? segmentPadding,
      indicatorPadding: other.indicatorPadding ?? indicatorPadding,
      animationDuration: other.animationDuration ?? animationDuration,
      animationCurve: other.animationCurve ?? animationCurve,
      selectedTextStyle: other.selectedTextStyle ?? selectedTextStyle,
      unselectedTextStyle: other.unselectedTextStyle ?? unselectedTextStyle,
      iconSize: other.iconSize ?? iconSize,
      iconSpacing: other.iconSpacing ?? iconSpacing,
      expandEqual: other.expandEqual ?? expandEqual,
      enableHaptic: other.enableHaptic ?? enableHaptic,
      shadow: other.shadow ?? shadow,
    );
  }

  /// Creates a copy with the given fields replaced.
  SegmentedStyle copyWith({
    Color? backgroundColor,
    Gradient? backgroundGradient,
    Color? selectedColor,
    Gradient? selectedGradient,
    Color? selectedForegroundColor,
    Color? unselectedForegroundColor,
    Color? disabledColor,
    List<BoxShadow>? indicatorShadow,
    Color? borderColor,
    Gradient? borderGradient,
    double? borderWidth,
    BorderRadius? borderRadius,
    double? height,
    SegmentedSize? sizePreset,
    EdgeInsets? segmentPadding,
    double? indicatorPadding,
    Duration? animationDuration,
    Curve? animationCurve,
    TextStyle? selectedTextStyle,
    TextStyle? unselectedTextStyle,
    double? iconSize,
    double? iconSpacing,
    bool? expandEqual,
    bool? enableHaptic,
    List<BoxShadow>? shadow,
  }) {
    return mergedWith(
      SegmentedStyle(
        backgroundColor: backgroundColor,
        backgroundGradient: backgroundGradient,
        selectedColor: selectedColor,
        selectedGradient: selectedGradient,
        selectedForegroundColor: selectedForegroundColor,
        unselectedForegroundColor: unselectedForegroundColor,
        disabledColor: disabledColor,
        indicatorShadow: indicatorShadow,
        borderColor: borderColor,
        borderGradient: borderGradient,
        borderWidth: borderWidth,
        borderRadius: borderRadius,
        height: height,
        sizePreset: sizePreset,
        segmentPadding: segmentPadding,
        indicatorPadding: indicatorPadding,
        animationDuration: animationDuration,
        animationCurve: animationCurve,
        selectedTextStyle: selectedTextStyle,
        unselectedTextStyle: unselectedTextStyle,
        iconSize: iconSize,
        iconSpacing: iconSpacing,
        expandEqual: expandEqual,
        enableHaptic: enableHaptic,
        shadow: shadow,
      ),
    );
  }

  /// Materialize: `defaults → GlobalSegmentedControlTheme → this`, then
  /// context color fallbacks. [variant] picks the indicator defaults.
  /// Call once per build.
  ResolvedSegmentedStyle resolve(
    BuildContext context, {
    SegmentedVariant variant = SegmentedVariant.filled,
  }) {
    final theme = GlobalSegmentedControlTheme.maybeOf(context);
    final s = defaults.mergedWith(theme?.style).mergedWith(this);
    return ResolvedSegmentedStyle._(
      backgroundColor:
          s.backgroundColor ??
          context.backgroundColors.outline.withValues(alpha: 0.08),
      backgroundGradient: s.backgroundGradient,
      selectedColor: switch (variant) {
        SegmentedVariant.filled =>
          s.selectedColor ?? context.backgroundColors.surface,
        SegmentedVariant.outlined => s.selectedColor ?? Colors.transparent,
        SegmentedVariant.tonal =>
          s.selectedColor ??
              context.primaryColors.primary.withValues(alpha: 0.12),
      },
      outlineAccent: s.selectedColor ?? context.primaryColors.primary,
      selectedGradient: s.selectedGradient,
      selectedForegroundColor:
          s.selectedForegroundColor ??
          (variant == SegmentedVariant.tonal
              ? context.primaryColors.primary
              : context.textColors.primary),
      unselectedForegroundColor:
          s.unselectedForegroundColor ?? context.textColors.secondary,
      disabledColor: s.disabledColor,
      disabledForegroundColor: context.textColors.disabled,
      indicatorShadow: s.indicatorShadow,
      borderColor: s.borderColor,
      borderGradient: s.borderGradient,
      borderWidth: s.borderWidth!,
      borderRadius:
          s.borderRadius ?? BorderRadius.circular(kSegmentedDefaultRadius),
      height: s.height ?? s.sizePreset?.value ?? kSegmentedDefaultHeight,
      segmentPadding: s.segmentPadding,
      indicatorPadding: s.indicatorPadding!,
      animationDuration: s.animationDuration!,
      animationCurve: s.animationCurve!,
      selectedTextStyle:
          s.selectedTextStyle ??
          context.textTheme.labelLarge?.copyWith(
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
      unselectedTextStyle:
          s.unselectedTextStyle ??
          context.textTheme.labelLarge?.copyWith(
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
      iconSize: s.iconSize!,
      iconSpacing: s.iconSpacing!,
      expandEqual: s.expandEqual!,
      enableHaptic: s.enableHaptic!,
      shadow: s.shadow,
      focusRingColor: context.primaryColors.primary.withValues(
        alpha: kSegmentedFocusRingOpacity,
      ),
    );
  }
}

/// Non-null snapshot of [SegmentedStyle] after [SegmentedStyle.resolve].
@immutable
class ResolvedSegmentedStyle {
  const ResolvedSegmentedStyle._({
    required this.backgroundColor,
    required this.backgroundGradient,
    required this.selectedColor,
    required this.outlineAccent,
    required this.selectedGradient,
    required this.selectedForegroundColor,
    required this.unselectedForegroundColor,
    required this.disabledColor,
    required this.disabledForegroundColor,
    required this.indicatorShadow,
    required this.borderColor,
    required this.borderGradient,
    required this.borderWidth,
    required this.borderRadius,
    required this.height,
    required this.segmentPadding,
    required this.indicatorPadding,
    required this.animationDuration,
    required this.animationCurve,
    required this.selectedTextStyle,
    required this.unselectedTextStyle,
    required this.iconSize,
    required this.iconSpacing,
    required this.expandEqual,
    required this.enableHaptic,
    required this.shadow,
    required this.focusRingColor,
  });

  final Color backgroundColor;
  final Gradient? backgroundGradient;
  final Color selectedColor;

  /// The outlined variant's border accent (caller selectedColor or
  /// primary).
  final Color outlineAccent;
  final Gradient? selectedGradient;
  final Color selectedForegroundColor;
  final Color unselectedForegroundColor;
  final Color? disabledColor;
  final Color disabledForegroundColor;
  final List<BoxShadow>? indicatorShadow;
  final Color? borderColor;
  final Gradient? borderGradient;
  final double borderWidth;
  final BorderRadius borderRadius;
  final double height;
  final EdgeInsets? segmentPadding;
  final double indicatorPadding;
  final Duration animationDuration;
  final Curve animationCurve;
  final TextStyle? selectedTextStyle;
  final TextStyle? unselectedTextStyle;
  final double iconSize;
  final double iconSpacing;
  final bool expandEqual;
  final bool enableHaptic;
  final List<BoxShadow>? shadow;
  final Color focusRingColor;
}
