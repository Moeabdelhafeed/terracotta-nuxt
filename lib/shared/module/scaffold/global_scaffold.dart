import 'package:flutter/material.dart';

import '../../../core/responsive/extensions.dart';
import '../bottom_nav/global_bottom_nav.dart';
import '../divider/global_divider.dart';
import '../drawer/global_drawer.dart';
import '../navigation_rail/global_navigation_rail.dart';
import '../tab_bar/global_tab_bar.dart';
import 'scaffold_models.dart';

export 'scaffold_models.dart';

/// Material 3 adaptive nav shell. Picks one of three nav containers
/// (bottom bar / rail / drawer) based on the active `WindowSizeClass`
/// and the configured [GlobalNavStrategy].
///
/// Body content is supplied as a `Widget` (single static body) or a
/// builder list that maps 1:1 with [destinations] — the scaffold then
/// shows the entry matching [selectedIndex].
/// Signature for caller-supplied builders that swap a default nav
/// container with a custom widget while keeping the scaffold's
/// selection plumbing. Receives the destinations + selected index +
/// selection callback. The `extended` flag is only meaningful for
/// the rail builder (true → render in extended mode).
typedef ScaffoldNavBuilder =
    Widget Function(
      BuildContext context,
      List<GlobalDestination> destinations,
      int selectedIndex,
      ValueChanged<int> onSelected, {
      bool extended,
    });

class GlobalScaffold extends StatelessWidget {
  const GlobalScaffold({
    super.key,
    required this.destinations,
    required this.selectedIndex,
    required this.onDestinationSelected,
    this.body,
    this.bodyBuilders,
    this.appBar,
    this.floatingActionButton,
    this.floatingActionButtonLocation,
    this.strategy = GlobalNavStrategy.defaults,
    this.preserveState = true,
    this.railLeading,
    this.railTrailing,
    this.drawerHeader,
    this.drawerFooter,
    this.backgroundColor,
    this.bottomBarBuilder,
    this.railBuilder,
    this.drawerBuilder,
    this.tabsBuilder,
    this.modalDrawerWidth,
  }) : assert(
         body != null || bodyBuilders != null,
         'Provide either body or bodyBuilders',
       ),
       assert(
         bodyBuilders == null || bodyBuilders.length == destinations.length,
         'bodyBuilders must match destinations length',
       );

  final List<GlobalDestination> destinations;
  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;

  final Widget? body;
  final List<WidgetBuilder>? bodyBuilders;

  final PreferredSizeWidget? appBar;

  final Widget? floatingActionButton;
  final FloatingActionButtonLocation? floatingActionButtonLocation;

  final GlobalNavStrategy strategy;

  final bool preserveState;

  final Widget? railLeading;
  final Widget? railTrailing;

  final Widget? drawerHeader;
  final Widget? drawerFooter;

  final Color? backgroundColor;

  /// Override the default `GlobalBottomNav`. Called when the active
  /// mode is [GlobalNavMode.bottomBar]. `extended` is ignored.
  final ScaffoldNavBuilder? bottomBarBuilder;

  /// Override the default `GlobalNavigationRail`. Called for
  /// [GlobalNavMode.rail] and [GlobalNavMode.railExtended] —
  /// `extended` reflects the active mode.
  final ScaffoldNavBuilder? railBuilder;

  /// Override the default `GlobalDrawer`. Called for both
  /// [GlobalNavMode.drawer] (permanent) and [GlobalNavMode.modalDrawer]
  /// (overlay). `extended` is ignored.
  final ScaffoldNavBuilder? drawerBuilder;

  /// Override the default `GlobalTabBar` rendered when the active
  /// mode is [GlobalNavMode.topTabs]. Caller is responsible for
  /// returning a [PreferredSizeWidget] that pins itself above the
  /// body.
  final PreferredSizeWidget Function(
    BuildContext context,
    List<GlobalDestination> destinations,
    int selectedIndex,
    ValueChanged<int> onSelected,
  )?
  tabsBuilder;

  /// Pins the drawer's width in both drawer modes.
  ///
  /// Null — the default — lets `GlobalDrawer` resolve it per breakpoint
  /// (280 / 320 / 360 / 400). It used to default to 280 AND be applied
  /// through a second, outer `Drawer`, so the drawer's own adaptive
  /// width was computed and then thrown away on every screen size.
  final double? modalDrawerWidth;

  Widget _buildBody(BuildContext context) {
    if (body != null) return body!;
    final builders = bodyBuilders!;
    if (preserveState) {
      return IndexedStack(
        index: selectedIndex,
        children: [
          for (var i = 0; i < builders.length; i++)
            Offstage(
              offstage: i != selectedIndex,
              child: TickerMode(
                enabled: i == selectedIndex,
                child: Builder(builder: builders[i]),
              ),
            ),
        ],
      );
    }
    return Builder(builder: builders[selectedIndex]);
  }

  @override
  Widget build(BuildContext context) {
    // BOTH axes. A bar costs vertical room and a rail costs horizontal
    // room, and a landscape phone has none of the first and plenty of
    // the second — see `GlobalNavStrategy.forShort`.
    final mode = strategy.resolve(
      context.windowSize,
      windowHeight: context.windowHeight,
    );
    final body = _buildBody(context);

    return switch (mode) {
      GlobalNavMode.bottomBar => Scaffold(
        backgroundColor: backgroundColor,
        appBar: appBar,
        body: body,
        floatingActionButton: floatingActionButton,
        floatingActionButtonLocation: floatingActionButtonLocation,
        bottomNavigationBar: bottomBarBuilder != null
            ? bottomBarBuilder!(
                context,
                destinations,
                selectedIndex,
                onDestinationSelected,
              )
            : _NavBottomBar(
                destinations: destinations,
                selectedIndex: selectedIndex,
                onSelected: onDestinationSelected,
              ),
      ),
      GlobalNavMode.rail || GlobalNavMode.railExtended => Scaffold(
        backgroundColor: backgroundColor,
        appBar: appBar,
        floatingActionButton: floatingActionButton,
        floatingActionButtonLocation: floatingActionButtonLocation,
        body: Row(
          children: [
            railBuilder != null
                ? railBuilder!(
                    context,
                    destinations,
                    selectedIndex,
                    onDestinationSelected,
                    extended: mode == GlobalNavMode.railExtended,
                  )
                : _NavRail(
                    destinations: destinations,
                    selectedIndex: selectedIndex,
                    onSelected: onDestinationSelected,
                    extended: mode == GlobalNavMode.railExtended,
                    leading: railLeading,
                    trailing: railTrailing,
                  ),
            GlobalDivider.vertical(),
            // The rail already covered the LEADING inset — the notch
            // is on its side of the screen, not the body's. Left in,
            // the page would inset itself a second time and sit a
            // notch's width away from the rail it is beside.
            Expanded(child: _bodyBesideRail(context, body)),
          ],
        ),
      ),
      GlobalNavMode.drawer => Scaffold(
        backgroundColor: backgroundColor,
        appBar: appBar,
        floatingActionButton: floatingActionButton,
        floatingActionButtonLocation: floatingActionButtonLocation,
        body: Row(
          children: [
            drawerBuilder != null
                ? drawerBuilder!(
                    context,
                    destinations,
                    selectedIndex,
                    onDestinationSelected,
                  )
                : _buildNavDrawer(
                    destinations: destinations,
                    selectedIndex: selectedIndex,
                    onSelected: onDestinationSelected,
                    header: drawerHeader,
                    footer: drawerFooter,
                    width: modalDrawerWidth,
                  ),
            GlobalDivider.vertical(),
            // Same as the rail: the permanent drawer stands on the
            // leading edge and has already covered that inset.
            Expanded(child: _bodyBesideRail(context, body)),
          ],
        ),
      ),
      GlobalNavMode.modalDrawer => _buildModalDrawerScaffold(context, body),
      GlobalNavMode.topTabs => _buildTopTabsScaffold(context, body),
      GlobalNavMode.none => Scaffold(
        backgroundColor: backgroundColor,
        appBar: appBar,
        body: body,
        floatingActionButton: floatingActionButton,
        floatingActionButtonLocation: floatingActionButtonLocation,
      ),
    };
  }

  /// The page NEXT TO a leading surface.
  ///
  /// A rail or a permanent drawer sits at the reading edge and already
  /// spans the notch inset on that side. `GlobalContainer.shell` — which
  /// every top-level page goes through — reads `MediaQuery.padding` and
  /// would apply the same inset again, leaving the page floating a
  /// notch's width away from the surface it is beside.
  Widget _bodyBesideRail(BuildContext context, Widget body) {
    final ltr = Directionality.of(context) == TextDirection.ltr;
    return MediaQuery.removePadding(
      context: context,
      removeLeft: ltr,
      removeRight: !ltr,
      child: body,
    );
  }

  // ─── Modal drawer mode ─────────────────────────────────────

  /// Renders the scaffold with a drawer slot (modal overlay). Uses
  /// the caller's [appBar] when supplied; otherwise inserts a
  /// minimal AppBar with a hamburger that the Scaffold auto-wires
  /// to the drawer's open state.
  Widget _buildModalDrawerScaffold(BuildContext context, Widget body) {
    final drawerWidget = drawerBuilder != null
        ? drawerBuilder!(
            context,
            destinations,
            selectedIndex,
            (i) {
              // Auto-close on selection so the drawer dismisses after
              // a tap — mirrors stock Material drawer behaviour.
              Navigator.of(context).maybePop();
              onDestinationSelected(i);
            },
          )
        : _buildNavDrawer(
            destinations: destinations,
            selectedIndex: selectedIndex,
            onSelected: (i) {
              Navigator.of(context).maybePop();
              onDestinationSelected(i);
            },
            header: drawerHeader,
            footer: drawerFooter,
            width: modalDrawerWidth,
          );
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: appBar ?? AppBar(title: const Text('')),
      // `GlobalDrawer` already BUILDS a `Drawer`, sized and shaped from
      // its own resolved style. Wrapping it in a second one nested two
      // shells, painted the scaffold background behind a drawer that had
      // already painted its own, and overrode the width it had just
      // worked out. A caller's own `drawerBuilder` widget is not a
      // drawer, so that one still gets a shell.
      drawer: drawerWidget is GlobalDrawer
          ? drawerWidget
          : Drawer(
              width: modalDrawerWidth,
              backgroundColor: Theme.of(context).scaffoldBackgroundColor,
              child: drawerWidget,
            ),
      // The scrim lives on the drawer's style and is painted here — see
      // `DrawerStyle.scrimColor`.
      drawerScrimColor: GlobalDrawer.scrimOf(drawerWidget),
      body: body,
      floatingActionButton: floatingActionButton,
      floatingActionButtonLocation: floatingActionButtonLocation,
    );
  }

  // ─── Top tabs mode ─────────────────────────────────────────

  /// Renders the scaffold with a top tab bar above the body. The
  /// tab bar is composed via [tabsBuilder] when supplied; otherwise
  /// a default `GlobalTabBar` is built from the destinations.
  Widget _buildTopTabsScaffold(BuildContext context, Widget body) {
    final tabBar = tabsBuilder != null
        ? tabsBuilder!(
            context,
            destinations,
            selectedIndex,
            onDestinationSelected,
          )
        : _ScaffoldTopTabs(
            destinations: destinations,
            selectedIndex: selectedIndex,
            onSelected: onDestinationSelected,
            existingAppBar: appBar,
          );

    // When the caller supplies an AppBar AND we built the default
    // tab bar via [_ScaffoldTopTabs], the tab bar widget already
    // stacks itself below the AppBar in its preferredSize so we
    // can pass it directly to Scaffold.appBar.
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: tabBar,
      body: body,
      floatingActionButton: floatingActionButton,
      floatingActionButtonLocation: floatingActionButtonLocation,
    );
  }
}

/// Glues a [GlobalTabBar] to the scaffold's selection plumbing and
/// stacks itself beneath the caller's [existingAppBar] when one is
/// supplied. Exposed as a [PreferredSizeWidget] so [Scaffold]
/// accepts it directly as its `appBar`.
class _ScaffoldTopTabs extends StatefulWidget implements PreferredSizeWidget {
  const _ScaffoldTopTabs({
    required this.destinations,
    required this.selectedIndex,
    required this.onSelected,
    this.existingAppBar,
  });

  final List<GlobalDestination> destinations;
  final int selectedIndex;
  final ValueChanged<int> onSelected;
  final PreferredSizeWidget? existingAppBar;

  static const _kTabBarHeight = 48.0;

  @override
  Size get preferredSize {
    const base = _kTabBarHeight;
    final appBarHeight = existingAppBar?.preferredSize.height ?? 0;
    return Size.fromHeight(base + appBarHeight);
  }

  @override
  State<_ScaffoldTopTabs> createState() => _ScaffoldTopTabsState();
}

class _ScaffoldTopTabsState extends State<_ScaffoldTopTabs>
    with SingleTickerProviderStateMixin {
  late TabController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = TabController(
      length: widget.destinations.length,
      initialIndex: widget.selectedIndex,
      vsync: this,
    )..addListener(_onTabChanged);
  }

  void _onTabChanged() {
    if (_ctrl.indexIsChanging) return;
    if (_ctrl.index != widget.selectedIndex) {
      widget.onSelected(_ctrl.index);
    }
  }

  @override
  void didUpdateWidget(_ScaffoldTopTabs old) {
    super.didUpdateWidget(old);
    if (widget.destinations.length != old.destinations.length) {
      _ctrl
        ..removeListener(_onTabChanged)
        ..dispose();
      _ctrl = TabController(
        length: widget.destinations.length,
        initialIndex: widget.selectedIndex,
        vsync: this,
      )..addListener(_onTabChanged);
    } else if (widget.selectedIndex != _ctrl.index) {
      _ctrl.animateTo(widget.selectedIndex);
    }
  }

  @override
  void dispose() {
    _ctrl
      ..removeListener(_onTabChanged)
      ..dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tabBar = GlobalTabBar(
      controller: _ctrl,
      onTap: widget.onSelected,
      tabs: [for (final d in widget.destinations) d.toTabBarItem()],
    );
    if (widget.existingAppBar == null) return tabBar;
    return PreferredSize(
      preferredSize: widget.preferredSize,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          widget.existingAppBar!,
          tabBar,
        ],
      ),
    );
  }
}

// ─── Adapter helpers ────────────────────────────────────────
//
// `GlobalDestination` maps 1:1 to each surface's item model so the
// scaffold can compose the standalone `Global*` widgets instead of
// owning its own private nav containers.

extension _DestinationAdapter on GlobalDestination {
  BottomNavItem toBottomNavItem() => BottomNavItem(
    icon: icon,
    activeIcon: selectedIcon,
    label: label,
    tooltip: tooltip,
    badge: badge,
    showDot: showDot,
    dotColor: dotColor,
  );

  NavigationRailItem toRailItem() => NavigationRailItem(
    icon: icon,
    activeIcon: selectedIcon,
    label: label,
    tooltip: tooltip,
    badge: badge,
    showDot: showDot,
    dotColor: dotColor,
  );

  DrawerItem toDrawerItem({
    required bool selected,
    required VoidCallback onTap,
  }) => DrawerItem(
    title: label,
    icon: selected ? (selectedIcon ?? icon) : icon,
    badge: badge,
    showDot: showDot,
    dotColor: dotColor,
    selected: selected,
    onTap: onTap,
  );

  GlobalTabItem toTabBarItem() => GlobalTabItem(
    icon: icon,
    activeIcon: selectedIcon,
    label: label,
    badge: badge,
    showDot: showDot,
    dotColor: dotColor,
  );
}

class _NavBottomBar extends StatelessWidget {
  const _NavBottomBar({
    required this.destinations,
    required this.selectedIndex,
    required this.onSelected,
  });

  final List<GlobalDestination> destinations;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    return GlobalBottomNav(
      currentIndex: selectedIndex,
      onTap: onSelected,
      autoNavigate: false,
      items: [for (final d in destinations) d.toBottomNavItem()],
    );
  }
}

class _NavRail extends StatelessWidget {
  const _NavRail({
    required this.destinations,
    required this.selectedIndex,
    required this.onSelected,
    this.extended = false,
    this.leading,
    this.trailing,
  });

  final List<GlobalDestination> destinations;
  final int selectedIndex;
  final ValueChanged<int> onSelected;
  final bool extended;
  final Widget? leading;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    // The rail wears the BAR's bag. This scaffold swaps one surface for
    // the other on a window-size boundary, and they used to be styled
    // from two unrelated places — `GlobalBottomNavTheme` for the bar and
    // `NavigationRailStyle`'s own non-nullable defaults for the rail —
    // so crossing that boundary changed the app's look rather than its
    // layout. Resolving the bar's bag here and mapping it across is what
    // makes the swap an orientation change.
    final rs = const BottomNavStyle().resolve(context);

    return GlobalNavigationRail(
      currentIndex: selectedIndex,
      onTap: onSelected,
      autoNavigate: false,
      extended: extended,
      leading: leading,
      trailing: trailing,
      style: railStyleFrom(
        rs,
        reduceMotion: MediaQuery.disableAnimationsOf(context),
      ),
      items: [for (final d in destinations) d.toRailItem()],
    );
  }
}

/// The scaffold's own drawer, as a `GlobalDrawer` rather than a wrapper
/// widget around one.
///
/// It used to be a `StatelessWidget` that built a `GlobalDrawer` inside
/// a `SizedBox(width: 280)`. Two things followed: the hard-coded width
/// defeated the drawer's breakpoint-aware one, and the modal path could
/// not tell that what it was holding was ALREADY a drawer, so it wrapped
/// it in a second `Drawer`.
///
/// [width] null lets the drawer resolve its own.
GlobalDrawer _buildNavDrawer({
  required List<GlobalDestination> destinations,
  required int selectedIndex,
  required ValueChanged<int> onSelected,
  Widget? header,
  Widget? footer,
  double? width,
}) {
  return GlobalDrawer(
    header: header,
    footer: footer,
    style: DrawerStyle(width: width),
    sections: [
      DrawerSection(
        items: [
          for (var i = 0; i < destinations.length; i++)
            destinations[i].toDrawerItem(
              selected: i == selectedIndex,
              onTap: () => onSelected(i),
            ),
        ],
      ),
    ],
  );
}
