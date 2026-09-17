import 'package:flutter/material.dart';

/// A single item in [GlobalNavigationRail]. API mirrors [BottomNavItem]
/// so callers can map cleanly between the two surfaces.
@immutable
class NavigationRailItem {
  const NavigationRailItem({
    this.icon,
    required this.label,
    this.route,
    this.activeIcon,
    this.badge,
    this.showDot = false,
    this.dotColor,
    this.onTap,
    this.onLongPress,
    this.customIcon,
    this.activeCustomIcon,
    this.disabled = false,
    this.tooltip,
    this.prominent = false,
    this.prominentColor,
    this.prominentSize,
    this.iconGradient,
    this.lottieAsset,
  });

  /// Default icon. Either [icon] or [customIcon] must be provided.
  final IconData? icon;

  /// Icon shown when selected. Falls back to [icon].
  final IconData? activeIcon;

  /// Custom widget for icon (e.g. Image, CircleAvatar). Takes priority
  /// over [icon].
  final Widget? customIcon;

  /// Custom widget shown when selected. Falls back to [customIcon].
  final Widget? activeCustomIcon;

  /// Display label. Rendered next to the icon in extended mode and
  /// below it (when [NavigationRailLabelMode.always]) in collapsed
  /// mode.
  final String label;

  /// GoRouter route path (e.g. '/home'). When [GlobalNavigationRail]
  /// has `autoNavigate: true` (default), tapping the item pushes this
  /// route on the root navigator.
  final String? route;

  /// Badge text (e.g. "5", "NEW"). Rendered as a small chip beside
  /// the icon.
  final String? badge;

  /// Shows a small notification dot near the icon.
  final bool showDot;

  /// Color for the notification dot. Defaults to theme error color.
  final Color? dotColor;

  /// Custom tap callback. Fires before any auto-nav.
  final VoidCallback? onTap;

  /// Long press callback.
  final VoidCallback? onLongPress;

  /// When true, item is greyed out and non-tappable.
  final bool disabled;

  /// Tooltip shown on long press (in collapsed mode the tooltip
  /// surfaces from the icon).
  final String? tooltip;

  /// When true, this item renders larger / elevated — useful for
  /// "primary action" rails (e.g. compose, create).
  final bool prominent;

  /// Background color for [prominent] item. Defaults to primary.
  final Color? prominentColor;

  /// Size override for [prominent] item circle. Defaults to 48.
  final double? prominentSize;

  /// Gradient fill applied to the icon via [ShaderMask] when
  /// selected.
  final Gradient? iconGradient;

  /// Lottie asset path. Plays animation on selection. Use with
  /// GlobalAnimation-compatible `.json` or `.lottie` files.
  final String? lottieAsset;
}

/// Indicator style for the selected rail item.
enum NavigationRailIndicatorStyle {
  /// No indicator — only color change.
  none,

  /// Rounded-rect background behind the selected item.
  pill,

  /// Small dot to the trailing side of the icon.
  dot,

  /// Vertical bar on the leading edge of the rail (aligned with the
  /// selected item).
  leadingBar,

  /// Vertical bar on the trailing edge of the rail.
  trailingBar,

  /// Animated sliding indicator that translates vertically between
  /// items as the selection changes.
  sliding,

  /// Custom widget — set [NavigationRailStyle.customIndicator].
  custom,
}

/// Label display mode for a rail in collapsed (non-extended) mode.
///
/// Note: in [GlobalNavigationRail] `extended: true` mode, labels
/// always render next to the icon regardless of this setting.
enum NavigationRailLabelMode {
  /// Always show labels under the icon (compact + label form).
  always,

  /// Only the selected item shows its label.
  selectedOnly,

  /// Icons only — labels never render in collapsed mode.
  never,
}

/// Styling configuration for [GlobalNavigationRail]. Mirrors the
/// shape of `BottomNavStyle` so callers can keep one mental model.
@immutable
class NavigationRailStyle {
  const NavigationRailStyle({
    this.backgroundColor,
    this.backgroundGradient,
    this.blur = 0,
    this.borderRadius,
    this.shadow,
    this.trailingBorder,
    this.trailingBorderGradient,
    this.trailingBorderWidth = 1.0,
    this.border,
    this.borderGradient,
    this.borderWidth = 2.0,
    this.floating = false,
    this.floatingMargin = const EdgeInsets.fromLTRB(12, 12, 0, 12),
    this.useDeviceRadius = true,
    this.selectedColor,
    this.unselectedColor,
    this.disabledColor,
    this.indicatorStyle = NavigationRailIndicatorStyle.pill,
    this.indicatorColor,
    this.indicatorOpacity = 0.1,
    this.indicatorRadius,
    this.indicatorBarThickness = 3.0,
    this.indicatorBarInset = 8.0,
    this.customIndicator,
    this.labelMode = NavigationRailLabelMode.always,
    this.iconSize = 24.0,
    this.selectedFontSize = 12.0,
    this.unselectedFontSize = 11.0,
    this.itemPadding,
    this.width,
    this.extendedWidth = 256.0,
    this.animationDuration = const Duration(milliseconds: 250),
    this.animationCurve = Curves.easeInOut,
    this.compact = false,
    this.itemSpacing = 4.0,
    this.itemAlignment = MainAxisAlignment.start,
    this.resetOnReTap = false,
    this.bounceOnTap = false,
    this.hapticFeedback = false,
    this.scrollable = false,
  });

  /// Background fill for the rail surface.
  final Color? backgroundColor;

  /// Gradient fill, takes precedence over [backgroundColor].
  final Gradient? backgroundGradient;

  /// Blur radius applied behind the rail (glass / acrylic effect).
  /// Pair with a translucent [backgroundColor] for the right look.
  final double blur;

  /// Outer border radius. Defaults to 0 for the docked rail and to
  /// [_kFloatingRadius]-like rounding when [floating] is true.
  final BorderRadius? borderRadius;

  /// Custom shadow list. Defaults to a single soft side shadow.
  final List<BoxShadow>? shadow;

  /// Single-sided border on the trailing edge — useful for a
  /// rail-against-content divider.
  final BorderSide? trailingBorder;

  /// Gradient variant of [trailingBorder].
  final Gradient? trailingBorderGradient;

  /// Width of the trailing edge border (used for both
  /// [trailingBorder] and [trailingBorderGradient]).
  final double trailingBorderWidth;

  /// Full surrounding border.
  final Border? border;

  /// Gradient surrounding border, painted via ShaderMask outline.
  final Gradient? borderGradient;

  /// Width applied to [border] and [borderGradient] outlines.
  final double borderWidth;

  /// When true, the rail floats away from screen edges with rounding
  /// on all sides. Pair with [floatingMargin].
  final bool floating;

  /// Margin around the rail when [floating] is true.
  final EdgeInsets floatingMargin;

  /// When true and [borderRadius] is null, uses the device's
  /// physical screen corner radius.
  final bool useDeviceRadius;

  final Color? selectedColor;
  final Color? unselectedColor;
  final Color? disabledColor;

  final NavigationRailIndicatorStyle indicatorStyle;
  final Color? indicatorColor;
  final double indicatorOpacity;
  final double? indicatorRadius;

  /// Thickness of the bar / sliding indicators.
  final double indicatorBarThickness;

  /// Padding between the bar indicator and the rail edge for
  /// [NavigationRailIndicatorStyle.leadingBar] /
  /// [NavigationRailIndicatorStyle.trailingBar].
  final double indicatorBarInset;

  /// Custom widget used as the indicator when [indicatorStyle] is
  /// [NavigationRailIndicatorStyle.custom].
  final Widget? customIndicator;

  final NavigationRailLabelMode labelMode;
  final double iconSize;
  final double selectedFontSize;
  final double unselectedFontSize;
  final EdgeInsets? itemPadding;

  /// Rail width when collapsed. Defaults vary by [compact].
  final double? width;

  /// Rail width when extended (labels render next to icons).
  final double extendedWidth;

  final Duration animationDuration;
  final Curve animationCurve;

  /// Compact mode tightens vertical padding + drops the label gap.
  final bool compact;

  /// Vertical spacing between items.
  final double itemSpacing;

  /// How items distribute vertically inside the rail — top by
  /// default; center for centered nav blocks.
  final MainAxisAlignment itemAlignment;

  /// When true and a tap repeats the already-selected item, the
  /// caller's `onTap` still fires (useful for "scroll-to-top" on
  /// re-tap).
  final bool resetOnReTap;

  /// Bounce-scale the icon on tap.
  final bool bounceOnTap;

  /// Triggers haptic feedback on tap.
  final bool hapticFeedback;

  /// When true and items overflow the rail height, wrap in a scroll
  /// view instead of clipping.
  final bool scrollable;
}
