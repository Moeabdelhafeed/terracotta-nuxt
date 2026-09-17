import 'package:flutter/material.dart';

import '../../../core/animations/animation_presets.dart';
import '../../../core/extensions/context_extensions.dart';
import '../../../core/extensions/theme_colors_extension.dart';
import 'theme/toggle_group_theme.dart';

// ---------------------------------------------------------------------------
// Constants
// ---------------------------------------------------------------------------

const kToggleGroupAnimDuration = AppDurations.quick;
const kToggleGroupDefaultHeight = 40.0;
const kToggleGroupDefaultRadius = 10.0;
const kToggleGroupDefaultPaddingH = 16.0;
const kToggleGroupIconSpacing = 6.0;
const kToggleGroupIconSize = 18.0;
const kToggleGroupDisabledOpacity = 0.5;
const kToggleGroupDividerWidth = 1.0;

/// The hover wash, over the button's own foreground colour.
const kToggleGroupHoverOpacity = 0.06;

/// The focus wash. Heavier than hover on purpose: hover is a hint that
/// something is interactive, focus says where the keyboard IS, and at
/// the same weight the two are indistinguishable.
const kToggleGroupFocusOpacity = 0.18;

// ---------------------------------------------------------------------------
// ToggleGroupVariant
// ---------------------------------------------------------------------------

/// Visual style of the toggle group.
enum ToggleGroupVariant {
  /// Outlined buttons with border — selected gets filled.
  outlined,

  /// Filled buttons — selected gets primary color.
  filled,

  /// Icon-only compact buttons.
  iconOnly,
}

// ---------------------------------------------------------------------------
// ToggleGroupItem
// ---------------------------------------------------------------------------

/// A single item in a [GlobalToggleGroup].
@immutable
class ToggleGroupItem<T> {
  const ToggleGroupItem({
    required this.value,
    required this.label,
    this.icon,
    this.iconWidget,
    this.enabled = true,
    this.tooltip,
  });

  /// The value this item represents.
  final T value;

  /// Text label. Ignored in [ToggleGroupVariant.iconOnly] if [icon] is set.
  final String label;

  /// Leading icon.
  final IconData? icon;

  /// Custom icon widget. Takes priority over [icon].
  final Widget? iconWidget;

  /// Whether this item is selectable.
  final bool enabled;

  /// Tooltip for this item.
  final String? tooltip;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ToggleGroupItem<T> &&
          other.value == value &&
          other.label == label;

  @override
  int get hashCode => Object.hash(value, label);
}

// ---------------------------------------------------------------------------
// ToggleGroupStyle — themeable bag
// ---------------------------------------------------------------------------

/// Themeable visuals for [GlobalToggleGroup] — the analogue of the
/// other selection-control bags.
///
/// Every field nullable; resolution stacks
/// `caller > GlobalToggleGroupTheme.style > defaults`, then fills color
/// fallbacks from `context.<group>Colors`. See [resolve].
@immutable
class ToggleGroupStyle {
  const ToggleGroupStyle({
    this.selectedColor,
    this.selectedGradient,
    this.selectedForegroundColor,
    this.unselectedColor,
    this.unselectedForegroundColor,
    this.disabledColor,
    this.borderColor,
    this.borderGradient,
    this.borderWidth,
    this.borderRadius,
    this.height,
    this.iconSize,
    this.iconSpacing,
    this.itemPadding,
    this.selectedTextStyle,
    this.unselectedTextStyle,
    this.showDividers,
    this.shadow,
    this.animationDuration,
    this.animationCurve,
    this.enableHaptic,
    this.expandEqual,
  });

  /// Background of selected items. Default:
  /// `context.primaryColors.primary`.
  final Color? selectedColor;

  /// Gradient for selected items. Overrides [selectedColor].
  final Gradient? selectedGradient;

  /// Text/icon color for selected items. Default:
  /// `context.textColors.onPrimary`.
  final Color? selectedForegroundColor;

  /// Background of unselected items. Default: transparent.
  final Color? unselectedColor;

  /// Text/icon color for unselected items. Default:
  /// `context.textColors.secondary`.
  final Color? unselectedForegroundColor;

  /// Color for disabled items.
  final Color? disabledColor;

  /// Border color around the entire group. Default: outline at 20%.
  final Color? borderColor;

  /// Gradient border. Overrides [borderColor].
  final Gradient? borderGradient;

  /// Border width.
  final double? borderWidth;

  /// Border radius.
  final BorderRadius? borderRadius;

  /// Height of the toggle group.
  final double? height;

  /// Icon size.
  final double? iconSize;

  /// Spacing between icon and label.
  final double? iconSpacing;

  /// Horizontal padding inside each button. Shrink it for dense sets
  /// (7 weekdays on a phone) — the default 16 eats the row.
  final EdgeInsets? itemPadding;

  /// Text style for selected items.
  final TextStyle? selectedTextStyle;

  /// Text style for unselected items.
  final TextStyle? unselectedTextStyle;

  /// Show dividers between items.
  final bool? showDividers;

  /// Shadow behind the group.
  final List<BoxShadow>? shadow;

  /// Animation duration. Reduced motion collapses it to zero.
  final Duration? animationDuration;

  /// Animation curve.
  final Curve? animationCurve;

  /// Haptic feedback on selection. Default `true`.
  final bool? enableHaptic;

  /// When true, all items have equal width.
  final bool? expandEqual;

  /// Compile-time floor (colors excepted — they resolve from context).
  static const ToggleGroupStyle defaults = ToggleGroupStyle(
    borderWidth: kToggleGroupDividerWidth,
    height: kToggleGroupDefaultHeight,
    iconSize: kToggleGroupIconSize,
    iconSpacing: kToggleGroupIconSpacing,
    itemPadding: EdgeInsets.symmetric(horizontal: kToggleGroupDefaultPaddingH),
    showDividers: true,
    animationDuration: kToggleGroupAnimDuration,
    animationCurve: Curves.easeInOut,
    enableHaptic: true,
    expandEqual: true,
  );

  /// Field-by-field overlay: `other` wins where non-null.
  ToggleGroupStyle mergedWith(ToggleGroupStyle? other) {
    if (other == null) return this;
    return ToggleGroupStyle(
      selectedColor: other.selectedColor ?? selectedColor,
      selectedGradient: other.selectedGradient ?? selectedGradient,
      selectedForegroundColor:
          other.selectedForegroundColor ?? selectedForegroundColor,
      unselectedColor: other.unselectedColor ?? unselectedColor,
      unselectedForegroundColor:
          other.unselectedForegroundColor ?? unselectedForegroundColor,
      disabledColor: other.disabledColor ?? disabledColor,
      borderColor: other.borderColor ?? borderColor,
      borderGradient: other.borderGradient ?? borderGradient,
      borderWidth: other.borderWidth ?? borderWidth,
      borderRadius: other.borderRadius ?? borderRadius,
      height: other.height ?? height,
      iconSize: other.iconSize ?? iconSize,
      iconSpacing: other.iconSpacing ?? iconSpacing,
      itemPadding: other.itemPadding ?? itemPadding,
      selectedTextStyle: other.selectedTextStyle ?? selectedTextStyle,
      unselectedTextStyle: other.unselectedTextStyle ?? unselectedTextStyle,
      showDividers: other.showDividers ?? showDividers,
      shadow: other.shadow ?? shadow,
      animationDuration: other.animationDuration ?? animationDuration,
      animationCurve: other.animationCurve ?? animationCurve,
      enableHaptic: other.enableHaptic ?? enableHaptic,
      expandEqual: other.expandEqual ?? expandEqual,
    );
  }

  /// Creates a copy with the given fields replaced.
  ToggleGroupStyle copyWith({
    Color? selectedColor,
    Gradient? selectedGradient,
    Color? selectedForegroundColor,
    Color? unselectedColor,
    Color? unselectedForegroundColor,
    Color? disabledColor,
    Color? borderColor,
    Gradient? borderGradient,
    double? borderWidth,
    BorderRadius? borderRadius,
    double? height,
    double? iconSize,
    double? iconSpacing,
    EdgeInsets? itemPadding,
    TextStyle? selectedTextStyle,
    TextStyle? unselectedTextStyle,
    bool? showDividers,
    List<BoxShadow>? shadow,
    Duration? animationDuration,
    Curve? animationCurve,
    bool? enableHaptic,
    bool? expandEqual,
  }) {
    return mergedWith(
      ToggleGroupStyle(
        selectedColor: selectedColor,
        selectedGradient: selectedGradient,
        selectedForegroundColor: selectedForegroundColor,
        unselectedColor: unselectedColor,
        unselectedForegroundColor: unselectedForegroundColor,
        disabledColor: disabledColor,
        borderColor: borderColor,
        borderGradient: borderGradient,
        borderWidth: borderWidth,
        borderRadius: borderRadius,
        height: height,
        iconSize: iconSize,
        iconSpacing: iconSpacing,
        itemPadding: itemPadding,
        selectedTextStyle: selectedTextStyle,
        unselectedTextStyle: unselectedTextStyle,
        showDividers: showDividers,
        shadow: shadow,
        animationDuration: animationDuration,
        animationCurve: animationCurve,
        enableHaptic: enableHaptic,
        expandEqual: expandEqual,
      ),
    );
  }

  /// Materialize: `defaults → GlobalToggleGroupTheme → this`, then
  /// context color fallbacks. Call once per build.
  ResolvedToggleGroupStyle resolve(BuildContext context) {
    final theme = GlobalToggleGroupTheme.maybeOf(context);
    final s = defaults.mergedWith(theme?.style).mergedWith(this);
    return ResolvedToggleGroupStyle._(
      selectedColor: s.selectedColor ?? context.primaryColors.primary,
      selectedGradient: s.selectedGradient,
      selectedForegroundColor:
          s.selectedForegroundColor ?? context.textColors.onPrimary,
      unselectedColor: s.unselectedColor ?? Colors.transparent,
      unselectedForegroundColor:
          s.unselectedForegroundColor ?? context.textColors.secondary,
      disabledColor: s.disabledColor,
      disabledForegroundColor: context.textColors.disabled,
      borderColor:
          s.borderColor ??
          context.backgroundColors.outline.withValues(alpha: 0.2),
      borderGradient: s.borderGradient,
      borderWidth: s.borderWidth!,
      borderRadius:
          s.borderRadius ?? BorderRadius.circular(kToggleGroupDefaultRadius),
      height: s.height!,
      iconSize: s.iconSize!,
      iconSpacing: s.iconSpacing!,
      itemPadding: s.itemPadding!,
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
      showDividers: s.showDividers!,
      shadow: s.shadow,
      animationDuration: s.animationDuration!,
      animationCurve: s.animationCurve!,
      enableHaptic: s.enableHaptic!,
      expandEqual: s.expandEqual!,
    );
  }
}

/// Non-null snapshot of [ToggleGroupStyle] after
/// [ToggleGroupStyle.resolve].
@immutable
class ResolvedToggleGroupStyle {
  const ResolvedToggleGroupStyle._({
    required this.selectedColor,
    required this.selectedGradient,
    required this.selectedForegroundColor,
    required this.unselectedColor,
    required this.unselectedForegroundColor,
    required this.disabledColor,
    required this.disabledForegroundColor,
    required this.borderColor,
    required this.borderGradient,
    required this.borderWidth,
    required this.borderRadius,
    required this.height,
    required this.iconSize,
    required this.iconSpacing,
    required this.itemPadding,
    required this.selectedTextStyle,
    required this.unselectedTextStyle,
    required this.showDividers,
    required this.shadow,
    required this.animationDuration,
    required this.animationCurve,
    required this.enableHaptic,
    required this.expandEqual,
  });

  final Color selectedColor;
  final Gradient? selectedGradient;
  final Color selectedForegroundColor;
  final Color unselectedColor;
  final Color unselectedForegroundColor;
  final Color? disabledColor;
  final Color disabledForegroundColor;
  final Color borderColor;
  final Gradient? borderGradient;
  final double borderWidth;
  final BorderRadius borderRadius;
  final double height;
  final double iconSize;
  final double iconSpacing;
  final EdgeInsets itemPadding;
  final TextStyle? selectedTextStyle;
  final TextStyle? unselectedTextStyle;
  final bool showDividers;
  final List<BoxShadow>? shadow;
  final Duration animationDuration;
  final Curve animationCurve;
  final bool enableHaptic;
  final bool expandEqual;
}
