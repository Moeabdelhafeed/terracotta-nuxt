import 'package:flutter/material.dart';

import '../../../core/responsive/window_size_class.dart';

/// One destination in a [GlobalScaffold]. Shared model — every nav
/// flavor (bottom bar / rail / drawer) renders the same list via
/// the corresponding `Global*` widget. Keep field names aligned
/// with `BottomNavItem` / `NavigationRailItem` / `DrawerItem` so
/// the adapter is a 1:1 mapping.
@immutable
class GlobalDestination {
  const GlobalDestination({
    required this.icon,
    required this.label,
    this.selectedIcon,
    this.tooltip,
    this.badge,
    this.showDot = false,
    this.dotColor,
  });

  final IconData icon;
  final IconData? selectedIcon;
  final String label;
  final String? tooltip;

  /// Badge text (e.g. "5", "NEW"). Rendered as a small pill on the
  /// trailing-top corner of the destination's icon.
  final String? badge;

  /// Notification dot (for "has unread, no count").
  final bool showDot;

  /// Color of the notification dot. Defaults to error / primary
  /// per the underlying nav widget.
  final Color? dotColor;
}

/// Which nav container the [GlobalScaffold] is currently rendering.
enum GlobalNavMode {
  /// `GlobalBottomNav` pinned to the bottom edge. Compact phones.
  bottomBar,

  /// `GlobalNavigationRail` collapsed (icon-only). Tablets portrait.
  rail,

  /// `GlobalNavigationRail` extended (label-next-to-icon). Tablets
  /// landscape / small laptops.
  railExtended,

  /// `GlobalDrawer` permanently pinned (always-visible side panel).
  /// Desktops / large windows.
  drawer,

  /// `GlobalDrawer` shown as a modal overlay via the Scaffold's
  /// built-in drawer slot. The provided `appBar` (or a fallback)
  /// gets a hamburger icon that toggles it. Useful for content-
  /// heavy phone layouts with many destinations.
  modalDrawer,

  /// `GlobalTabBar` pinned to the top of the body. Tap a tab to
  /// switch destinations. Useful for desktop-y top-nav patterns.
  topTabs,

  /// No nav container — body only. Useful for onboarding / auth /
  /// detail-only screens that still want the rest of [GlobalScaffold]'s
  /// chrome (app bar, FAB).
  none,
}

/// Strategy for picking a [GlobalNavMode] from a [WindowSizeClass].
@immutable
class GlobalNavStrategy {
  const GlobalNavStrategy({
    this.forCompact = GlobalNavMode.bottomBar,
    this.forMedium = GlobalNavMode.rail,
    this.forExpanded = GlobalNavMode.railExtended,
    this.forLarge = GlobalNavMode.drawer,
    this.forExtraLarge = GlobalNavMode.drawer,
    this.forShort = GlobalNavMode.rail,
  });

  final GlobalNavMode forCompact;
  final GlobalNavMode forMedium;
  final GlobalNavMode forExpanded;
  final GlobalNavMode forLarge;
  final GlobalNavMode forExtraLarge;

  /// What a SHORT window gets, whatever its width. A RAIL by default.
  ///
  /// The width buckets alone get a landscape phone wrong at both ends.
  /// A small one (568x320) is compact by width, so it kept a bottom bar
  /// — 56 points of a 320-point screen, a fifth of it, on the axis there
  /// is none of. A big one (874x402) is `expanded` by width, so it got
  /// the EXTENDED rail: 256 points of nav across a screen that has 874.
  /// Neither is what the window is actually asking for.
  ///
  /// A bar costs VERTICAL room and a rail costs HORIZONTAL room, and a
  /// short window is exactly the one with plenty of the second and none
  /// of the first. Set it to null to go back to width alone.
  final GlobalNavMode? forShort;

  /// Picks the surface from BOTH axes.
  ///
  /// [windowHeight] is optional so an existing caller keeps compiling,
  /// but `GlobalScaffold` always passes it — without it the short-window
  /// rule can never fire, which is the whole point of the field.
  GlobalNavMode resolve(
    WindowSizeClass windowSize, {
    WindowHeightClass? windowHeight,
  }) {
    final byWidth = switch (windowSize) {
      WindowSizeClass.compact => forCompact,
      WindowSizeClass.medium => forMedium,
      WindowSizeClass.expanded => forExpanded,
      WindowSizeClass.large => forLarge,
      WindowSizeClass.extraLarge => forExtraLarge,
    };

    // `none` is a page saying it wants NO navigation, which is a
    // decision rather than a layout — a short window does not overrule
    // it into growing a rail.

    // `none` is a page saying it wants NO navigation, which is a
    // decision rather than a layout — a short window does not overrule
    // it into growing a rail.
    if (byWidth == GlobalNavMode.none) return byWidth;

    final short = forShort;
    if (short != null && (windowHeight?.isCompact ?? false)) return short;
    return byWidth;
  }

  static const defaults = GlobalNavStrategy();

  static const drawerOnly = GlobalNavStrategy(
    forCompact: GlobalNavMode.drawer,
    forMedium: GlobalNavMode.drawer,
    forExpanded: GlobalNavMode.drawer,
    forLarge: GlobalNavMode.drawer,
    forExtraLarge: GlobalNavMode.drawer,
  );

  static const railOnly = GlobalNavStrategy(
    forCompact: GlobalNavMode.rail,
    forMedium: GlobalNavMode.rail,
    forExpanded: GlobalNavMode.railExtended,
    forLarge: GlobalNavMode.drawer,
    forExtraLarge: GlobalNavMode.drawer,
  );

  /// Top-tabs at every bucket — useful for desktop-y top-nav apps
  /// (settings consoles, admin panels) that prefer horizontal nav
  /// over a vertical rail.
  static const topTabs = GlobalNavStrategy(
    forCompact: GlobalNavMode.topTabs,
    forMedium: GlobalNavMode.topTabs,
    forExpanded: GlobalNavMode.topTabs,
    forLarge: GlobalNavMode.topTabs,
    forExtraLarge: GlobalNavMode.topTabs,
  );

  /// Modal drawer on compact (deep-nav phone apps), permanent drawer
  /// elsewhere.
  static const modalDrawerOnCompact = GlobalNavStrategy(
    forCompact: GlobalNavMode.modalDrawer,
    forMedium: GlobalNavMode.rail,
    forExpanded: GlobalNavMode.railExtended,
    forLarge: GlobalNavMode.drawer,
    forExtraLarge: GlobalNavMode.drawer,
  );

  /// No nav container at any bucket. Body-only layout — caller
  /// usually pairs this with their own `appBar` chrome.
  static const none = GlobalNavStrategy(
    forCompact: GlobalNavMode.none,
    forMedium: GlobalNavMode.none,
    forExpanded: GlobalNavMode.none,
    forLarge: GlobalNavMode.none,
    forExtraLarge: GlobalNavMode.none,
  );
}
