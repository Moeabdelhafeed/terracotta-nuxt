import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../../core/animations/animation_presets.dart';
import '../../../core/constants/assets/assets.dart';
import '../../../core/extensions/theme_colors_extension.dart';
import '../../../core/localization/strings/home_strings.dart';
import '../../../core/localization/strings/nav_strings.dart';
import '../../../core/responsive/extensions.dart';
import '../../../core/responsive/window_size_class.dart';
import '../../../shared/module/bottom_nav/global_bottom_nav.dart';
import '../../../shared/module/image/global_image.dart';
import '../../../shared/module/navigation_rail/global_navigation_rail.dart';
import '../../../shared/module/toast/global_toast.dart';
import '../tab_history.dart';

/// The five tabs, as the design draws them: one brown bar floating clear
/// of the screen edges, white glyphs, and a lighter square behind the
/// current one.
///
/// ## The measurements
///
/// Taken as RATIOS from the design rather than as pixels — the artwork
/// available was a crop of the bar at an unknown zoom, so absolute
/// numbers off it would have been a guess dressed up as a measurement.
/// Within the bar the design puts the active square at roughly 65% of
/// the bar's height and the glyph at roughly 40%, and those hold at any
/// scale. [_glyphSize] is fixed at 24 and the rest follows from it.
///
/// If the bar wants adjusting, there are only three numbers:
/// [_glyphSize], [_itemPad] (glyph to square) and [_contentPad] (row to
/// bar). Everything else is derived, so nothing can drift out of step.
///
/// ## Its own widget, not the shell's
///
/// `AppShell` exists and is wired to nothing — the shell route in
/// `app_routes.dart` is commented out and every tab is a top-level
/// route. Rather than move the whole app onto a shell to give one page
/// a nav bar, this sits on the page and calls `context.go`, which is
/// what the shell would have done anyway.
///
/// It also makes the bar opt-in per screen, which matters: the booking
/// flow and checkout deliberately do not have one.
class TerracottaNavBar extends StatelessWidget {
  const TerracottaNavBar({
    required this.currentIndex,
    this.scrollController,
    super.key,
  });

  /// Which tab this screen is.
  final int currentIndex;

  /// The page's scroll, so the bar can retreat as the reader goes down.
  /// Without one it simply stays.
  final ScrollController? scrollController;

  /// Whether the arrival has already been spent this run.
  ///
  /// Static, because the thing that must not repeat is the ARRIVAL of
  /// the app's chrome, and every tab builds its own instance of this
  /// bar.
  static bool _played = false;

  /// Claims the one arrival there is.
  static BottomNavEntrance _play() {
    _played = true;
    return BottomNavEntrance.slideFadeStaggered;
  }

  /// Lets a test watch it happen. Nothing in the app calls it: the
  /// entrance belongs to launching the app, and there is one of those.
  @visibleForTesting
  static void resetEntrance() => _played = false;

  /// The bar's own corner, from the design.
  static const _barRadius = 11.0;

  /// And the square behind the current tab — which is also the shape
  /// the tap ripple takes.
  static const _activeRadius = 5.0;

  /// The gap between a glyph and the edge of its square, both ways.
  ///
  /// Was 5, which made the bar read as cramped, then 21, which made it
  /// tall: 26 + 42 of padding put the row at 68 and the whole bar at
  /// 78. This is the number the bar's height comes from, so it is the
  /// one that had to come down.
  static const _itemPad = 14.0;

  /// The gap between one panel and the next.
  ///
  /// Small: the panels fill their cells, so without any gap they touch
  /// and the row reads as one long strip instead of five destinations.
  static const _itemGap = 6.0;

  /// And the gap between the bar's edge and the row of panels.
  ///
  /// Doubled from 5: the panels were sitting almost on the bar's edge,
  /// and the brown around them reads as a frame rather than a hairline.
  /// The bar's HEIGHT still comes from [_itemPad] — which is why the
  /// bar got SHORTER while this got bigger.
  static const _contentPad = 10.0;

  /// The glyph itself.
  static const _glyphSize = 26.0;

  /// The height of the square behind the current tab.
  ///
  /// Its WIDTH is not this: the background fills its whole cell, so the
  /// five destinations divide the bar evenly and the current one is a
  /// panel rather than a badge floating in the middle of its share.
  /// `indicatorWidth` is a MINIMUM, so asking for an unbounded one and
  /// letting the cell clamp it is how that is said.
  static const _activeSize = _glyphSize + _itemPad * 2;

  /// The bar's total height: the row of squares plus [_contentPad]
  /// above and below it, and nothing else.
  ///
  /// The module's default is 64, which centres a 34pt row and leaves 15
  /// of air top and bottom — Material's proportions, sized for a glyph
  /// with a label under it. This bar has no labels, so it is drawn to
  /// its contents.
  static const _barHeight = _activeSize + _contentPad * 2;

  /// How far the bar floats clear of the screen's edges.
  ///
  /// The bottom is the one that shows: on a phone the home indicator
  /// sits right under it, and 12 put the bar close enough to read as
  /// stuck to it.
  /// Written symmetrically rather than as `fromLTRB`, which the design
  /// conventions ban outright: a left/right inset is a direction, and a
  /// direction has to be logical. This one has no side to it — the bar
  /// floats the same distance from both edges in either language — so
  /// saying `symmetric` is both true and allowed.
  static final _margin = const EdgeInsets.symmetric(
    horizontal: 12,
  ).copyWith(bottom: 24);

  /// What a page has to leave clear at the bottom.
  ///
  /// The bar floats OVER the page — the `Scaffold` reserves nothing for
  /// it, because reserving would leave a white band behind when it
  /// retreats. So the page pads itself by the bar plus the gap it
  /// floats in.
  ///
  /// ZERO in a short window, where the destinations are on a rail down
  /// the side instead and there is nothing along the bottom to clear.
  static double reservedHeightIn(BuildContext context) =>
      isShort(context) ? 0 : reservedHeight;

  /// The portrait figure, for anything that cannot read a context.
  static const reservedHeight = _barHeight + 24.0;

  /// The rail's own width plus the gap it floats in — what a page has
  /// to leave clear at its END edge in a short window.
  static const reservedWidth = _railWidth + 12.0;

  /// What a page has to leave clear at its end edge. Zero in
  /// portrait, where the destinations are along the bottom.
  static double reservedWidthIn(BuildContext context) =>
      isShort(context) ? reservedWidth : 0;

  /// What goes in the `Scaffold`'s bottom slot.
  ///
  /// NOTHING in a short window. The slot lays its child out at the
  /// bottom with no height limit, so a rail asking for the full height
  /// GETS it — which is why the whole screen turned brown with five
  /// glyphs down the middle of it. A rail is not a bottom bar.
  static Widget? bottomSlot(
    BuildContext context, {
    required int currentIndex,
    ScrollController? scrollController,
  }) => isShort(context)
      ? null
      : TerracottaNavBar(
          currentIndex: currentIndex,
          scrollController: scrollController,
        );

  /// The whole page, with the rail down its END edge when the window
  /// is short.
  ///
  /// ## Around the SCAFFOLD, not around its body
  ///
  /// Wrapping the body alone put the rail behind the app bar and left
  /// the bar starting at the screen edge — so the title sat under the
  /// rail and the rail read as a stripe painted over the page. The app
  /// bar is a sibling of the body inside the `Scaffold`; nothing
  /// wrapped around the body can get in front of it or move it.
  ///
  /// So the rail goes OUTSIDE. The scaffold is inset by the rail's
  /// width — which moves the app bar, its title and its actions along
  /// with everything else — and the rail is painted after it, in
  /// front.
  ///
  /// The leading INSET is part of that width. In landscape the housing
  /// moves to a side and `DeviceNotch` has already corrected
  /// `MediaQuery.padding` app-wide, so this is the real side or
  /// nothing.
  static Widget wrapScaffold(
    BuildContext context, {
    required int currentIndex,
    required Widget child,
  }) {
    if (!isShort(context)) return child;

    // THE END EDGE, not the start.
    //
    // Material puts a rail at the start, but the start is where the
    // app bar's title lives and where a page's headings begin — the
    // rail crowded all of it. At the end it sits under the reader's
    // thumb and against the edge nothing else is using. It still
    // MIRRORS: the end is the left in Arabic and the right in English.
    final rtl = Directionality.of(context) == TextDirection.rtl;
    final padding = MediaQuery.paddingOf(context);
    final inset = rtl ? padding.left : padding.right;

    return Stack(
      children: [
        // The page, moved along by exactly what the rail occupies.
        Padding(
          padding: EdgeInsetsDirectional.only(end: reservedWidth + inset),
          // And told there is no longer an inset on that side, so the
          // `SafeArea`s inside it do not apply it a second time.
          child: MediaQuery.removePadding(
            context: context,
            removeLeft: rtl,
            removeRight: !rtl,
            child: child,
          ),
        ),
        // IN FRONT, and last in the stack for that reason.
        PositionedDirectional(
          top: 0,
          bottom: 0,
          end: 0,
          child: TerracottaNavBar(currentIndex: currentIndex),
        ),
      ],
    );
  }

  /// Whether this window is too SHORT for a bar along the bottom.
  ///
  /// A landscape phone has roughly 390dp of height to spend. The bar
  /// and the gap it floats in take 78 of them — a fifth of the screen,
  /// for five destinations that would sit perfectly happily down the
  /// side where there is width to spare. The module's own advice, and
  /// Material's.
  ///
  /// HEIGHT, not orientation: a tall tablet held sideways is not
  /// short, and it keeps its bar.
  static bool isShort(BuildContext context) =>
      context.windowHeight == WindowHeightClass.compact;

  /// The rail's width when it is standing in for the bar.
  ///
  /// Wide enough for the same 26pt glyph in the same square, and no
  /// wider: it is the bar stood on its end, not a menu.
  static const _railWidth = _activeSize + _contentPad * 2;

  /// Kept parallel to the items below, so a tab and its destination
  /// cannot drift apart.
  static const paths = <String>[
    '/home',
    '/gallery',
    '/workshops',
    '/shop',
    '/profile',
  ];

  /// Whether [path] is one of the five tabs.
  static bool isTabPath(String path) => paths.contains(path);

  /// Whether the navigation now being built was a TAB SWAP.
  ///
  /// Set for one navigation only, and read by `AppRoutes._page` to
  /// collapse the transition — see the note there. A flag rather than
  /// an extra because `go` replaces the stack and the destination's
  /// page builder is what has to know; an extra would also have to
  /// survive the tab's own rebuilds, which it does not.
  static bool leftATab = false;

  /// Records that the reader is leaving [path] by tapping another tab.
  static void _leavingTab(String path) {
    TabHistory.leaving(path);
    leftATab = true;
    // Cleared after the frame that builds the destination, so the
    // NEXT navigation — a push into a detail page, say — animates
    // normally.
    WidgetsBinding.instance.addPostFrameCallback((_) => leftATab = false);
  }

  @override
  Widget build(BuildContext context) {
    // THE CHROME, not the brand-as-control. `primary` is lifted in
    // dark so it can be read as text and pressed as a button — which
    // makes it a light surface, and the design's white labels measure
    // 3.2:1 on it. `chrome` is the same brown in both themes, which is
    // what the design specifies and what those labels were drawn for.
    final primary = context.primaryColors.chrome;

    // The design's own exports, not Material's lookalikes — the home
    // tab in particular is the studio's vessel, which no icon font has.
    // The box is imposed from OUT HERE, and the image is given no
    // width or height of its own.
    //
    // `GlobalImage` turns an explicit width and height into `cacheWidth`
    // and `cacheHeight`, and `Image.asset` given BOTH decodes to exactly
    // that many pixels — it does not preserve the aspect. The vessel is
    // 421 x 592, so asking for 26 x 26 squashed it into a square bitmap
    // before `fit` ever ran, and `BoxFit.contain` cannot undo pixels
    // that are already wrong. It looked vertically compressed because
    // it WAS.
    //
    // Sized from the outside, the decode keeps the source aspect and
    // `contain` letterboxes it into the square.

    final items = <({String label, String asset})>[
      (label: HomeStrings.title, asset: Assets.logos.mark.defaultPath),
      (
        label: NavStrings.gallery,
        asset: 'assets/icons/streamline-plump_gallery_2_remix.svg',
      ),
      (
        label: NavStrings.workshops,
        asset: 'assets/icons/heroicons_paint_brush_16_solid.svg',
      ),
      (
        label: NavStrings.shop,
        asset: 'assets/icons/boxicons_cart_filled.svg',
      ),
      (
        label: NavStrings.profile,
        asset: 'assets/icons/iconamoon_profile_fill.svg',
      ),
    ];

    // OUT OF THE WAY as a page covers the tab.
    //
    // The bar belongs to the tab, and a pushed page arrives over it —
    // so it used to sit there, fully drawn, while a detail slid across
    // it and then vanish when the old route was finally taken down.
    // `secondaryAnimation` is the route's own account of being covered
    // (0 → 1 as something arrives on top, back to 0 as that leaves), so
    // riding it takes the bar down with the page arriving and brings it
    // back with the page leaving — a back-SWIPE included, because that
    // drives the same animation with the reader's finger.
    // AND BACK GOES TO THE TAB BEFORE THIS ONE.
    //
    // `context.go` replaces the stack rather than growing it, so a tab
    // route has nothing to pop and the system back button closed the
    // app from wherever the reader happened to be. `TabHistory` keeps
    // the trail; this is what spends it.
    //
    // It lives INSIDE the bar because the bar is in every tab's
    // subtree and `PopScope` registers with the enclosing route
    // wherever it sits — one place instead of five pages remembering
    // to do it.
    return PopScope(
      // NEVER the platform's. Two different jobs need the gesture:
      // walking back through the tab trail, and — at the bottom of it —
      // asking before the app closes.
      //
      // `false` is also what turns the PREDICTIVE animation off. A
      // back that is going to be swallowed must not first peel the app
      // away to show the launcher behind it, or «اسحب مرة أخرى للخروج»
      // arrives over a screen that already looks like it left.
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;

        final previous = TabHistory.back();
        if (previous != null) {
          // Back through the tab history is the same swap, backwards.
          ExitGuard.disarm();
          leftATab = true;
          WidgetsBinding.instance.addPostFrameCallback(
            (_) => leftATab = false,
          );
          context.go(previous);
          return;
        }

        // THE BOTTOM OF THE STACK. One more back leaves the app, and
        // on a gesture phone that is a swipe from the edge of a screen
        // somebody is reading. See [ExitGuard].
        if (ExitGuard.isArmed) {
          ExitGuard.disarm();
          unawaited(SystemNavigator.pop());
          return;
        }
        ExitGuard.arm();
        GlobalToast.info(NavStrings.exitConfirm);
      },
      child: _LeavesWhenCovered(
        // A RAIL WHEN THE WINDOW IS SHORT.
        //
        // Landscape leaves a phone about 390dp of height, and the bar
        // spends a fifth of it on five destinations that would sit
        // happily down the side where there is width going spare. The
        // rail is the same bar stood on its end: same brown, same
        // glyphs, same square behind the current one.
        //
        // The SAFE AREA is the other half of the job. In landscape the
        // housing moves to a SIDE, and `DeviceNotch` has already
        // corrected `MediaQuery.padding` app-wide so only the real
        // side reports an inset. Chrome sitting ON an edge grows by
        // that inset rather than being pushed in by it — see `_rail`.
        child: isShort(context)
            ? _rail(context, primary, items)
            : GlobalBottomNav(
                currentIndex: currentIndex,
                scrollController: scrollController,
                // This drives navigation itself; the module's `autoNavigate` would
                // need a `route` per item and then both would be steering.
                autoNavigate: false,
                onTap: (i) {
                  if (i == currentIndex) return;
                  // The tab being LEFT, recorded before leaving it — and
                  // flagged, so the swap does not animate.
                  _leavingTab(paths[currentIndex]);
                  context.go(paths[i]);
                },
                items: [
                  for (final (index, item) in items.indexed)
                    BottomNavItem(
                      label: item.label,
                      customIcon: glyph(
                        item.asset,
                        selected: index == currentIndex,
                      ),
                      activeCustomIcon: glyph(item.asset, selected: true),
                    ),
                ],
                style: BottomNavStyle(
                  // The bar rises and fades in, and its five destinations
                  // stagger on top of that — one arrival with depth, rather than
                  // a row of parts assembling themselves.
                  //
                  // ONCE PER RUN, not per route. Every tab is a top-level route
                  // and `context.go` disposes this State, so left on it would
                  // replay on every single tab switch — which is the module's own
                  // warning: chrome that animates in on every route change is
                  // chrome that is LATE on every route change.
                  entrance: _played ? BottomNavEntrance.none : _play(),
                  // LONGER than the house default, because this one window holds
                  // two movements: the bar arriving, and then five destinations
                  // arriving across it. At 300ms the second was three frames per
                  // item and read as nothing.
                  entranceDuration: AppDurations.deliberate,
                  floating: true,
                  floatingMargin: _margin,
                  height: _barHeight,
                  contentPadding: const EdgeInsets.all(_contentPad),
                  itemSpacing: _itemGap,
                  backgroundColor: primary,
                  selectedColor: Colors.white,
                  unselectedColor: Colors.white70,
                  // The design's own measurements, not Material's.
                  borderRadius: const BorderRadius.all(
                    Radius.circular(_barRadius),
                  ),
                  // 5 all round the glyph — a snug square, not Material's roomy
                  // lozenge. Applied to selected and unselected alike so the row
                  // does not re-flow as the selection moves.
                  itemPadding: const EdgeInsets.all(_itemPad),
                  // The lighter square behind the current tab, as drawn. This
                  // radius shapes the TAP RIPPLE too: the module confines the ink
                  // to the indicator, so the splash lands in the same square
                  // rather than as a slab across the whole cell.
                  indicatorStyle: BottomNavIndicatorStyle.pill,
                  indicatorColor: Colors.white,
                  indicatorOpacity: 0.16,
                  indicatorRadius: _activeRadius,
                  // Clamped by the cell, which is what makes it fill one.
                  indicatorWidth: double.infinity,
                  // Glyphs only — the labels are what the screen's own heading
                  // already says. They stay on the items for a screen reader.
                  labelMode: BottomNavLabelMode.never,
                  // Retreats with the page, like the app bar above it.
                  hideOnScroll: true,
                ),
              ),
      ),
    );
  }

  /// One destination's artwork, shared by the bar and the rail.
  ///
  /// A method rather than a closure inside `build` because the rail
  /// draws the same five glyphs, at the same size, in the same square.
  @visibleForTesting
  Widget glyph(String path, {required bool selected}) => SizedBox.square(
    dimension: _glyphSize,
    child: GlobalImage.a(
      path,
      // A nav glyph is small and always sits on the brown; a shimmer
      // over it would be larger than the thing it stands in for.
      placeholder: const SizedBox.shrink(),
      style: ImageStyle(
        // CONTAIN, not the house default of `cover`, which fills a
        // square box by cropping the long axis of a portrait glyph.
        fit: BoxFit.contain,
        // NO corner radius. `GlobalImage` rounds every image by 8 —
        // right for a photo in a card, ruinous on a small glyph,
        // where 8 eats a third of each corner: the cart lost its
        // wheels, the person their shoulders and the gallery its
        // square. The vase looked fine only because a vessel never
        // reaches its corners.
        borderRadius: BorderRadius.zero,
        color: selected ? Colors.white : Colors.white70,
        // srcIn: these are solid silhouettes on transparency, and the
        // default srcATop would tint the transparent field with them.
        overlayBlendMode: BlendMode.srcIn,
      ),
    ),
  );

  /// The bar, stood on its end for a short window.
  Widget _rail(
    BuildContext context,
    Color primary,
    List<({String label, String asset})> items,
  ) {
    // GROWS BY the inset on ITS edge rather than being pushed in by
    // it. `DeviceNotch` has already removed UIKit's mirrored
    // duplicate, so this is the real housing side or nothing.
    final rtl = Directionality.of(context) == TextDirection.rtl;
    final padding = MediaQuery.paddingOf(context);
    final inset = rtl ? padding.left : padding.right;

    return Padding(
      padding: EdgeInsetsDirectional.only(end: inset),
      child: GlobalNavigationRail(
        currentIndex: currentIndex,
        autoNavigate: false,
        onTap: (i) {
          if (i == currentIndex) return;
          _leavingTab(paths[currentIndex]);
          context.go(paths[i]);
        },
        items: [
          for (final (index, item) in items.indexed)
            NavigationRailItem(
              label: item.label,
              customIcon: glyph(item.asset, selected: index == currentIndex),
              activeCustomIcon: glyph(item.asset, selected: true),
            ),
        ],
        style: NavigationRailStyle(
          floating: true,
          // Clear of three edges, and flush against the one the
          // reader's thumb reaches for — which mirrors with the
          // language, so it is written as a side rather than a
          // literal left or right.
          floatingMargin: const EdgeInsets.symmetric(
            vertical: 12,
          ).copyWith(left: rtl ? 12 : 0, right: rtl ? 0 : 12),
          width: _railWidth,
          backgroundColor: primary,
          selectedColor: Colors.white,
          unselectedColor: Colors.white70,
          borderRadius: const BorderRadius.all(Radius.circular(_barRadius)),
          itemPadding: const EdgeInsets.all(_itemPad),
          itemSpacing: _itemGap,
          // CENTRED down the rail. Aligned to the top they sit in a
          // clump with a field of brown under them; the bar centres
          // its row and this is the same row turned.
          itemAlignment: MainAxisAlignment.center,
          indicatorStyle: NavigationRailIndicatorStyle.pill,
          indicatorColor: Colors.white,
          indicatorOpacity: 0.16,
          indicatorRadius: _activeRadius,
          // Glyphs only, exactly as along the bottom — the labels are
          // what each screen's own heading already says.
          labelMode: NavigationRailLabelMode.never,
          // SCROLLS RATHER THAN OVERFLOWS. Five destinations fit a
          // landscape phone with about thirty points to spare, which
          // is not enough margin to be sure of: a taller status inset,
          // a larger text scale or a sixth tab all spend it, and the
          // result was a rail reporting "OVERFLOWED BY 2" over the
          // page. A rail that runs out of room should scroll.
          scrollable: true,
        ),
      ),
    );
  }
}

/// Slides its child out of the bottom as a route arrives over this one.
///
/// PINNED CHROME only. Page content is carried off by the transition
/// already, and a second movement inside a moving page reads as mush —
/// this is for the things that are not moving with it.
class _LeavesWhenCovered extends StatelessWidget {
  const _LeavesWhenCovered({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.disableAnimationsOf(context)) return child;

    final covering = ModalRoute.of(context)?.secondaryAnimation;
    if (covering == null) return child;

    return AnimatedBuilder(
      animation: covering,
      builder: (context, inner) => FractionalTranslation(
        // Its OWN height, so it is gone by the time the page above has
        // finished arriving whatever height the bar happens to be.
        translation: Offset(0, covering.value),
        child: Opacity(opacity: 1 - covering.value, child: inner),
      ),
      child: child,
    );
  }
}
