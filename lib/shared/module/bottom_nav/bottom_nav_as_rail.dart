import '../navigation_rail/global_navigation_rail.dart';
import 'bottom_nav_models.dart';

/// The bar's look, turned ninety degrees.
///
/// A bar and its rail are two ORIENTATIONS of one surface, and an app
/// that themes one should get the other for free. Before this they were
/// two components that happened to sit in the same app: `BottomNavStyle`
/// is themeable through `GlobalBottomNavTheme`, `NavigationRailStyle` is
/// a bag of non-nullable defaults with no extension behind it, so a
/// rebrand moved the bar and left the rail on Material's numbers.
///
/// `GlobalBottomNav` used to carry an `enableSideRail` flag that did the
/// swap itself. It could not work: a widget handed to
/// `Scaffold.bottomNavigationBar` cannot move itself to
/// `body: Row([rail, body])`, and what it actually produced was a rail
/// filling the entire screen with the page collapsed to zero height
/// behind it. Choosing the surface is the SCAFFOLD's job —
/// `GlobalScaffold` already switches on `context.windowSize` — and this
/// is what keeps the two looking alike once it has chosen.
NavigationRailStyle railStyleFrom(
  ResolvedBottomNavStyle rs, {

  /// The bar resolves this itself; a caller mapping the bag has to
  /// pass it, because motion is a property of the surface rather than
  /// of which way up it is.
  bool reduceMotion = false,
}) => NavigationRailStyle(
  backgroundColor: rs.backgroundColor,
  backgroundGradient: rs.backgroundGradient,
  blur: rs.blur,
  borderRadius: rs.borderRadius,
  shadow: rs.shadow,
  // The bar's TOP border is the edge that faces the CONTENT. On a rail
  // that edge is the trailing one, so the same declaration draws the
  // same divider after the surface turns.
  trailingBorder: rs.topBorder,
  trailingBorderGradient: rs.topBorderGradient,
  trailingBorderWidth: rs.topBorderWidth,
  border: rs.border,
  borderGradient: rs.borderGradient,
  borderWidth: rs.borderWidth,
  floating: rs.floating,
  useDeviceRadius: rs.useDeviceRadius,
  selectedColor: rs.selectedColor,
  unselectedColor: rs.unselectedColor,
  disabledColor: rs.disabledColor,
  indicatorStyle: railIndicatorFrom(rs.indicatorStyle),
  indicatorColor: rs.indicatorColor,
  indicatorOpacity: rs.indicatorOpacity,
  indicatorRadius: rs.indicatorRadius,
  indicatorBarThickness: rs.indicatorBarThickness,
  customIndicator: rs.customIndicator,
  labelMode: switch (rs.labelMode) {
    BottomNavLabelMode.always => NavigationRailLabelMode.always,
    BottomNavLabelMode.selectedOnly => NavigationRailLabelMode.selectedOnly,
    BottomNavLabelMode.never => NavigationRailLabelMode.never,
  },
  iconSize: rs.iconSize,
  selectedFontSize: rs.selectedFontSize,
  unselectedFontSize: rs.unselectedFontSize,
  itemPadding: rs.itemPadding,
  animationDuration: rs.respectReducedMotion && reduceMotion
      ? Duration.zero
      : rs.animationDuration,
  animationCurve: rs.animationCurve,
  compact: rs.compact,
  resetOnReTap: rs.resetOnReTap,
  bounceOnTap: rs.bounceOnTap && !(rs.respectReducedMotion && reduceMotion),
  hapticFeedback: rs.hapticFeedback,
  scrollable: rs.scrollable,
);

/// The indicator, turned ninety degrees.
///
/// `topBar` is the edge FACING THE CONTENT and `bottomBar` the one
/// against the screen edge, which on a rail are the trailing and the
/// leading edges. Mapping them by NAME instead — top to leading, since
/// both words mean "first" — puts the line on the wrong side of every
/// destination.
///
/// A notch has no vertical meaning; it is not an indicator style here,
/// so there is nothing to fall back to.
NavigationRailIndicatorStyle railIndicatorFrom(
  BottomNavIndicatorStyle s,
) => switch (s) {
  BottomNavIndicatorStyle.none => NavigationRailIndicatorStyle.none,
  BottomNavIndicatorStyle.pill => NavigationRailIndicatorStyle.pill,
  BottomNavIndicatorStyle.dot => NavigationRailIndicatorStyle.dot,
  BottomNavIndicatorStyle.topBar => NavigationRailIndicatorStyle.trailingBar,
  BottomNavIndicatorStyle.bottomBar => NavigationRailIndicatorStyle.leadingBar,
  BottomNavIndicatorStyle.sliding => NavigationRailIndicatorStyle.sliding,
  BottomNavIndicatorStyle.custom => NavigationRailIndicatorStyle.custom,
};

/// One destination, crossed over.
///
/// `route` and `onTap` cross too — a rail built from these navigates on
/// its own the way a bar does. A caller that already routes in its own
/// `onTap` should clear them.
///
/// `animatedIcon`, `animatedIconTrigger`, `lottieRepeat`, the icon
/// reaction and the marquee have NO counterpart on the rail and are
/// dropped. See the module's known gaps.
NavigationRailItem railItemFrom(BottomNavItem item) => NavigationRailItem(
  icon: item.icon,
  activeIcon: item.activeIcon,
  customIcon: item.customIcon,
  activeCustomIcon: item.activeCustomIcon,
  label: item.label,
  route: item.route,
  badge: item.badge,
  showDot: item.showDot,
  dotColor: item.dotColor,
  onTap: item.onTap,
  onLongPress: item.onLongPress,
  disabled: item.disabled,
  tooltip: item.tooltip,
  prominent: item.prominent,
  prominentColor: item.prominentColor,
  prominentSize: item.prominentSize,
  iconGradient: item.iconGradient,
  lottieAsset: item.lottieAsset,
);
