import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:lottie/lottie.dart';

import '../../../core/animations/entrance.dart';
import '../../../core/localization/strings/nav_strings.dart';
import '../../../core/utils/device/info/screen_radius.dart';
import '../badge/global_badge.dart';
import '../marquee/global_marquee.dart';
import '../tooltip/global_tooltip.dart';
import 'bottom_nav_models.dart';
import 'theme/bottom_nav_theme.dart';

export '../../../core/animations/entrance.dart' show EntranceKind;
export 'bottom_nav_as_rail.dart';
export 'bottom_nav_models.dart';
export 'theme/bottom_nav_theme.dart';

/// A highly customizable bottom navigation bar with GoRouter integration,
/// animated indicators, icon bounce, hide on scroll, haptic feedback,
/// notch cutout, border/gradient border, prominent items, gradient icon
/// shader, Lottie icons, tablet side rail, scrollable items, custom indicator.
class GlobalBottomNav extends StatefulWidget {
  const GlobalBottomNav({
    super.key,
    required this.items,
    this.currentIndex,
    this.onTap,
    this.style = const BottomNavStyle(),
    this.floatingActionButton,
    this.autoNavigate = true,
    this.scrollController,
    this.itemBuilder,
  });

  final List<BottomNavItem> items;
  final int? currentIndex;
  final ValueChanged<int>? onTap;
  final BottomNavStyle style;
  final Widget? floatingActionButton;
  final bool autoNavigate;
  final ScrollController? scrollController;
  final Widget Function(
    BuildContext context,
    BottomNavItem item,
    int index,
    bool isSelected,
  )?
  itemBuilder;

  @override
  State<GlobalBottomNav> createState() => _GlobalBottomNavState();
}

class _GlobalBottomNavState extends State<GlobalBottomNav>
    with TickerProviderStateMixin {
  late int _selectedIndex;

  /// The style bag, materialized once per dependency change rather than
  /// per build — resolving reads the palette, and the palette is an
  /// inherited lookup.
  late ResolvedBottomNavStyle _rs;

  /// Whether the platform asked for less motion AND this bar agreed to
  /// listen. Chrome that moves is the first thing the setting means to
  /// quiet: the indicator arrives instead of travelling, the tap does
  /// not bounce, and hide-on-scroll cuts instead of sliding.
  bool _reduceMotion = false;

  Duration get _motion => _reduceMotion ? Duration.zero : _rs.animationDuration;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _rs = widget.style.resolve(context);
    _reduceMotion =
        _rs.respectReducedMotion && MediaQuery.disableAnimationsOf(context);
    _bounceCtrl?.duration = _motion;
    _hideCtrl?.duration = _motion;
    // What a full retreat has to cover, alongside the bar itself.
    _bottomInset = MediaQuery.paddingOf(context).bottom * _rs.bottomInsetFactor;

    // Reduce motion means the bar is simply THERE. Starting it and
    // zeroing the duration would still rebuild every frame for nothing.
    final enter = _enterCtrl;
    if (enter != null && enter.status == AnimationStatus.dismissed) {
      enter.duration = _rs.entranceDuration;
      if (_reduceMotion) {
        enter.value = 1;
      } else {
        enter.forward();
      }
    }
    _watchRoute();

    // No controller needed inside a `Scaffold`. `ScrollNotificationObserver`
    // sits above both the body and the bar — the same channel Material's
    // own `AppBar` uses for its scrolled-under elevation — so the body's
    // scrolling reaches the bar with nothing passed through the page,
    // and it keeps working when the scrollable is replaced or nested.
    if (!_rs.hideOnScroll || widget.scrollController != null) return;
    final observer = ScrollNotificationObserver.maybeOf(context);
    if (observer == _observer) return;
    _observer?.removeListener(_onNotification);
    _observer = observer?..addListener(_onNotification);
  }

  AnimationController? _bounceCtrl;
  int _bouncingIndex = -1;

  /// 1 = fully shown, 0 = fully hidden. Driven straight by the scroll
  /// DELTA, not by `forward()` / `reverse()` — see `_applyDelta`.
  AnimationController? _hideCtrl;

  /// Set when the bar is inside a `Scaffold`, which is where the
  /// scrolling comes from without a controller being handed in.
  ScrollNotificationObserverState? _observer;

  double _lastScrollOffset = 0;

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.currentIndex ?? 0;
    // `initState` runs BEFORE `didChangeDependencies`, so the resolved
    // bag does not exist yet — and resolving needs a palette, which is
    // an inherited lookup. These two read the caller's own bag, which
    // is the only thing that can turn a controller on at all: a theme
    // that enables bounce for a caller who never asked is not a thing
    // this module offers.
    if (widget.style.bounceOnTap ?? false) {
      _bounceCtrl = AnimationController(
        vsync: this,
        duration: BottomNavDefaults.animationDuration,
      );
    }
    if (widget.style.hideOnScroll ?? false) {
      _hideCtrl = AnimationController(
        vsync: this,
        duration: BottomNavDefaults.hideAnimDuration,
        value: 1,
      );
    }
    if ((widget.style.hideOnScroll ?? false) &&
        widget.scrollController != null) {
      widget.scrollController!.addListener(_onScroll);
    }

    final entrance = widget.style.entrance ?? BottomNavEntrance.none;
    if (entrance != BottomNavEntrance.none) {
      _enterCtrl = AnimationController(
        vsync: this,
        duration:
            widget.style.entranceDuration ?? BottomNavDefaults.entranceDuration,
      );
    }
  }

  @override
  void dispose() {
    _observer?.removeListener(_onNotification);
    _routeAnimation?.removeListener(_onRouteTick);
    _enterCtrl?.dispose();
    _bounceCtrl?.dispose();
    _hideCtrl?.dispose();
    widget.scrollController?.removeListener(_onScroll);
    super.dispose();
  }

  @override
  void didUpdateWidget(GlobalBottomNav oldWidget) {
    super.didUpdateWidget(oldWidget);
    // RE-RESOLVE on a new bag. `_rs` was materialized only in
    // `didChangeDependencies`, which does not run when the widget is
    // rebuilt with a different `style` — so a caller changing the style
    // at runtime got the old one until something unrelated invalidated
    // an inherited widget. It looked like the bag being ignored.
    if (!identical(widget.style, oldWidget.style)) {
      _rs = widget.style.resolve(context);
      _bounceCtrl?.duration = _motion;
      _hideCtrl?.duration = _motion;
    }
    if (widget.currentIndex != null && widget.currentIndex != _selectedIndex) {
      _selectedIndex = widget.currentIndex!;
    }
    if (oldWidget.scrollController != widget.scrollController) {
      oldWidget.scrollController?.removeListener(_onScroll);
      if ((widget.style.hideOnScroll ?? false) &&
          widget.scrollController != null) {
        widget.scrollController!.addListener(_onScroll);
      }
    }
  }

  void _onNotification(ScrollNotification notification) {
    // depth 0 only: an inner horizontal carousel or a nested list must
    // not drive the page's own chrome.
    if (notification.depth != 0) return;
    if (notification.metrics.axis != Axis.vertical) return;

    // A page that cannot afford to lose the bar keeps it.
    if (!_canHide(notification.metrics)) {
      if (_hideCtrl != null && _hideCtrl!.value != 1) _hideCtrl!.forward();
      return;
    }

    if (notification is ScrollUpdateNotification) {
      _applyDelta(notification.scrollDelta ?? 0, notification.metrics.pixels);
    } else if (notification is ScrollEndNotification) {
      _settle();
    }
  }

  /// Whether there is enough content that hiding does not strand the
  /// reader.
  ///
  /// Hiding frees the bar's own height. On a page with barely more
  /// content than fits, that is enough to make the page unscrollable —
  /// the bar hides, the scroll ends, and no gesture remains that could
  /// bring it back.
  bool _canHide(ScrollMetrics metrics) {
    if (!metrics.hasContentDimensions) return false;
    return metrics.maxScrollExtent >=
        _hideHeight * BottomNavDefaults.hideMinExtentFactor;
  }

  void _onScroll() {
    final controller = widget.scrollController!;
    final offset = controller.offset;
    if (controller.hasClients && !_canHide(controller.position)) {
      _lastScrollOffset = offset;
      if (_hideCtrl != null && _hideCtrl!.value != 1) _hideCtrl!.forward();
      return;
    }
    _applyDelta(offset - _lastScrollOffset, offset);
    _lastScrollOffset = offset;
  }

  /// Positive [delta] means the content moved UP — the reader is going
  /// DOWN the page — so the bar retreats by the same amount.
  ///
  /// It used to hide on ANY scroll past a threshold and come back only
  /// once the page had been still for six hundred milliseconds, so
  /// reading back up the page left the bar away. And it hid on a timer
  /// rather than with the finger, which is a second, slower animation
  /// running beside the one the reader is performing.
  void _applyDelta(double delta, double pixels) {
    final ctrl = _hideCtrl;
    if (ctrl == null) return;
    final height = _hideHeight;
    if (height <= 0) return;

    // Pinned open at the very top, including while a bounce overscroll
    // carries pixels negative.
    if (pixels <= 0) {
      ctrl.value = 1;
      return;
    }
    ctrl.value = (ctrl.value - delta / height).clamp(0.0, 1.0);
  }

  /// Finish to whichever edge is nearer, so the bar is never abandoned
  /// part-way off the bottom.
  void _settle() {
    final ctrl = _hideCtrl;
    if (ctrl == null || ctrl.value <= 0 || ctrl.value >= 1) return;
    if (ctrl.value >= 0.5) {
      ctrl.forward();
    } else {
      ctrl.reverse();
    }
  }

  /// What a full retreat has to cover: the bar plus whatever safe-area
  /// inset is drawn under it.
  double get _hideHeight =>
      _rs.height + (_rs.floating ? _rs.floatingMargin.bottom : _bottomInset);

  double _bottomInset = 0;

  /// One per destination, attached to the indicator box so the ink can
  /// measure the thing it is supposed to sit inside. A fraction of the
  /// cell was a guess, and the pill is content-width — so the ripple
  /// came out visibly wider than the selected state it lands on.
  final _indicatorKeys = <GlobalKey>[];

  /// The arrival, played once on mount. Null when the caller did not
  /// ask for one, which is the default: a bar that animates in on every
  /// route change is a bar that is late on every route change.
  AnimationController? _enterCtrl;

  /// One per destination, so the ink's own focus / hover / press
  /// callbacks can reach the glyph.
  final _reactionKeys = <GlobalKey<_ReactiveIconState>>[];
  final _morphKeys = <GlobalKey<_MorphIconState>>[];

  GlobalKey<_ReactiveIconState> _reactionKey(int index) {
    while (_reactionKeys.length <= index) {
      _reactionKeys.add(GlobalKey<_ReactiveIconState>());
    }
    return _reactionKeys[index];
  }

  final _lottieKeys = <GlobalKey<_MorphLottieState>>[];

  GlobalKey<_MorphLottieState> _lottieKey(int index) {
    while (_lottieKeys.length <= index) {
      _lottieKeys.add(GlobalKey<_MorphLottieState>());
    }
    return _lottieKeys[index];
  }

  GlobalKey<_MorphIconState> _morphKey(int index) {
    while (_morphKeys.length <= index) {
      _morphKeys.add(GlobalKey<_MorphIconState>());
    }
    return _morphKeys[index];
  }

  GlobalKey _indicatorKey(int index) {
    while (_indicatorKeys.length <= index) {
      _indicatorKeys.add(GlobalKey());
    }
    return _indicatorKeys[index];
  }

  int _resolveIndex(BuildContext context) {
    if (widget.currentIndex != null) return widget.currentIndex!;
    try {
      final location = GoRouterState.of(context).matchedLocation;
      for (var i = 0; i < widget.items.length; i++) {
        if (widget.items[i].route != null &&
            location.startsWith(widget.items[i].route!)) {
          return i;
        }
      }
    } catch (_) {}
    return _selectedIndex;
  }

  void _onItemTap(int index) {
    final item = widget.items[index];
    if (item.disabled) return;
    if (_rs.hapticFeedback) HapticFeedback.lightImpact();
    if (_bounceCtrl != null) {
      _bouncingIndex = index;
      _bounceCtrl!.forward(from: 0).then((_) => _bounceCtrl!.reverse());
    }
    if (_rs.resetOnReTap && index == _selectedIndex && item.route != null) {
      try {
        final loc = GoRouterState.of(context).matchedLocation;
        if (loc != item.route) {
          context.go(item.route!);
          widget.onTap?.call(index);
          return;
        }
      } catch (_) {}
    }
    setState(() => _selectedIndex = index);
    widget.onTap?.call(index);
    if (item.onTap != null) {
      item.onTap!();
      return;
    }
    if (widget.autoNavigate && item.route != null) context.go(item.route!);
  }

  // ─── Build ─────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    // All four came off `Theme.of(context).colorScheme` — Material's
    // scheme rather than the app's palette, so a rebrand left every
    // navigation bar in the app behind. They are resolved now.
    final selectedColor = _rs.selectedColor;
    final unselectedColor = _rs.unselectedColor;
    final disabledColor = _rs.disabledColor;
    final bg = _rs.backgroundColor;
    final activeIndex = _resolveIndex(context);
    final height = _rs.height;
    final borderRadius = _resolveRadius();
    final indicatorRadius =
        _rs.indicatorRadius ?? _resolveIndicatorRadius(borderRadius);

    var result = _buildBar(
      context,
      activeIndex,
      selectedColor,
      unselectedColor,
      disabledColor,
      bg,
      height,
      borderRadius,
      indicatorRadius,
    );

    if (_rs.floating) {
      result = Padding(padding: _rs.floatingMargin, child: result);
    }

    result = _withEntrance(result);

    if (_rs.hideOnScroll && _hideCtrl != null) {
      return AnimatedBuilder(
        animation: _hideCtrl!,
        // No ClipRect. It cropped the widget to its own box, which is
        // exactly where the shadow is NOT — so the elevation was shaved
        // off the top edge of the bar for the whole time hide-on-scroll
        // was enabled. A bar translated past the bottom of the screen
        // needs no clip; the screen is the clip.
        builder: (_, child) => _Unclipped(
          // TRANSLATE by a FRACTION of the bar's own height, and leave
          // the laid-out height alone. `Scaffold` hands the bottom bar's
          // rendered height to the body as padding, so a bar that shrank
          // would pull the body down a pixel for every pixel it
          // collapsed — content moving at twice the scroll rate, which
          // reads as the bar lagging the page. The same thing the app
          // bar had.
          child: FractionalTranslation(
            translation: Offset(0, 1 - _hideCtrl!.value),
            child: child,
          ),
        ),
        child: result,
      );
    }

    return result;
  }

  /// FOLLOWS the route's animation rather than reacting to its status.
  ///
  /// A predictive-back drag drives that animation from the finger, so a
  /// listener that only heard "reverse" and then ran its own controller
  /// on its own clock played a fixed departure over a gesture the user
  /// was still holding — and had nothing to say when they let go and
  /// came back. Tracking the value scrubs with the drag, reverses as it
  /// goes and returns if it is cancelled.
  ///
  /// The FIRST arrival is still ours: the entrance has its own duration
  /// and curve, which the route transition does not.
  void _watchRoute() {
    if (_enterCtrl == null || !_rs.reverseEntranceOnExit) return;
    final route = ModalRoute.of(context)?.animation;
    if (identical(route, _routeAnimation)) return;
    _routeAnimation?.removeListener(_onRouteTick);
    _routeAnimation = route?..addListener(_onRouteTick);
  }

  Animation<double>? _routeAnimation;

  /// Following starts when the PAGE has settled, not when the bar has.
  bool _armed = false;

  void _onRouteTick() {
    if (!mounted || _reduceMotion) return;
    final route = _routeAnimation;
    final enter = _enterCtrl;
    if (route == null || enter == null) return;

    // ARM only once the route has finished arriving. The entrance is
    // shorter than the page transition, so following from the moment it
    // finished snapped the bar back to wherever the route had got to —
    // a jump backwards and then a jump to rest, which is the flash at
    // the end of the slide.
    if (!_armed) {
      if (route.status != AnimationStatus.completed) return;
      _armed = true;
      return;
    }
    enter.value = route.value.clamp(0.0, 1.0);
  }

  /// The bar's arrival.
  ///
  /// `staggered` is handled per ITEM instead — see `_withItemEntrance`,
  /// because a stagger is destinations arriving one after another, not
  /// a bar doing something in stages.
  Widget _withEntrance(Widget bar) {
    final ctrl = _enterCtrl;
    if (ctrl == null || _rs.entrance == BottomNavEntrance.staggered) {
      return bar;
    }

    // The BAR's share of the window. For the staggered variant that is
    // the first part of it only — the rest belongs to the destinations,
    // and a surface still fading up underneath them hides what they are
    // doing. See [BottomNavDefaults.staggerBarWindow].
    final t = CurvedAnimation(
      parent: ctrl,
      curve: _rs.entrance == BottomNavEntrance.slideFadeStaggered
          ? Interval(
              0,
              BottomNavDefaults.staggerBarWindow,
              curve: _rs.entranceCurve,
            )
          : _rs.entranceCurve,
    );
    return KeyedSubtree(
      key: BottomNavDefaults.entranceKey,
      child: AnimatedBuilder(
        animation: t,
        builder: (_, child) => switch (_rs.entrance) {
          BottomNavEntrance.none || BottomNavEntrance.staggered => child!,
          BottomNavEntrance.slideFadeStaggered => Opacity(
            opacity: t.value,
            child: FractionalTranslation(
              translation: Offset(
                0,
                (1 - t.value) * BottomNavDefaults.entranceSlide,
              ),
              child: child,
            ),
          ),
          BottomNavEntrance.fade => Opacity(opacity: t.value, child: child),
          BottomNavEntrance.slide => FractionalTranslation(
            translation: Offset(
              0,
              (1 - t.value) * BottomNavDefaults.entranceSlide,
            ),
            child: child,
          ),
          BottomNavEntrance.scale => Transform.scale(
            scale: lerpDouble(
              BottomNavDefaults.entranceScaleFrom,
              1,
              t.value,
            )!,
            child: child,
          ),
          BottomNavEntrance.slideFade => Opacity(
            opacity: t.value,
            child: FractionalTranslation(
              translation: Offset(
                0,
                (1 - t.value) * BottomNavDefaults.entranceSlide,
              ),
              child: child,
            ),
          ),
        },
        child: bar,
      ),
    );
  }

  /// One destination's share of a staggered arrival.
  ///
  /// The interval is taken in READING order, so Arabic staggers from
  /// the right — "the one before it" is a reading position, not a
  /// physical one.
  Widget _withItemEntrance(Widget item, int index) {
    final ctrl = _enterCtrl;
    if (ctrl == null || !isStaggered(_rs.entrance)) return item;

    final within = staggerStart(
      index: index,
      count: widget.items.length,
      spread: BottomNavDefaults.staggerSpread,
    );

    // BEHIND THE BAR, not alongside it.
    //
    // `staggerStart` answers "how far into the stagger", and for the
    // combined variant the stagger does not begin at zero — the
    // surface is still arriving there. The slice is remapped into what
    // is left of the window so the destinations land on a bar that is
    // already mostly there, which is what makes them read as arriving
    // one after another rather than as one block fading up.
    final start = _rs.entrance == BottomNavEntrance.slideFadeStaggered
        ? BottomNavDefaults.staggerItemStart +
              within * (1 - BottomNavDefaults.staggerItemStart)
        : within;

    final t = CurvedAnimation(
      parent: ctrl,
      curve: Interval(start.clamp(0.0, 0.99), 1, curve: _rs.entranceCurve),
    );
    return AnimatedBuilder(
      animation: t,
      builder: (_, child) => Opacity(
        opacity: t.value,
        child: FractionalTranslation(
          translation: Offset(
            0,
            (1 - t.value) * BottomNavDefaults.entranceSlide,
          ),
          child: child,
        ),
      ),
      child: item,
    );
  }

  // ─── Radius ───────────────────────────────────────────────

  /// The bar's corner.
  ///
  /// The device's own screen radius is for a FLOATING bar only. A
  /// floating bar sits inside the screen's rounded corners and has to
  /// agree with them; a flush one is against the bottom edge, where the
  /// screen's corners are the screen's, not the bar's — rounding its
  /// TOP corners to a number measured off the hardware is copying a
  /// radius from the wrong two corners.
  ///
  /// A caller's own always wins, and a flush bar that wants a corner
  /// says so.
  BorderRadius _resolveRadius() {
    if (_rs.borderRadius != null) return _rs.borderRadius!;
    if (!_rs.floating) return BorderRadius.zero;
    if (_rs.useDeviceRadius && DeviceRadius.hasRoundedCorners) {
      return DeviceRadius.borderRadiusPadded;
    }
    return BorderRadius.circular(BottomNavDefaults.floatingRadius);
  }

  /// The pill's corner, and with it the INK's.
  ///
  /// A floating bar wears the device's own screen radius, so the pill
  /// inside it should read as concentric with that rather than as a
  /// separate shape — the same principle the notch cutout follows.
  double _resolveIndicatorRadius(BorderRadius barRadius) {
    final avg =
        (barRadius.topLeft.x +
            barRadius.topRight.x +
            barRadius.bottomLeft.x +
            barRadius.bottomRight.x) /
        4;
    return avg > 0 ? avg : BottomNavDefaults.fallbackIndicatorRadius;
  }

  // ─── Bar container ────────────────────────────────────────

  Widget _buildBar(
    BuildContext context,
    int activeIndex,
    Color selectedColor,
    Color unselectedColor,
    Color disabledColor,
    Color bg,
    double height,
    BorderRadius borderRadius,
    double indicatorRadius,
  ) {
    // The system's home-indicator inset, scaled. All of it is correct
    // and also a lot of empty bar under the labels — the indicator is a
    // thin line, not 34 points of hardware.
    // The SURFACE covers the whole inset; only the CONTENT's padding is
    // scaled. Scaling the surface too left the last few points of the
    // home-indicator strip painted by whatever is behind the bar — a
    // pale band under a dark bar, which is the thing that made this
    // look broken rather than tight.
    final safeFull = MediaQuery.of(context).padding.bottom;
    final safePadding = safeFull * _rs.bottomInsetFactor;
    final totalHeight = height + (_rs.floating ? 0 : safeFull);
    final hasBlur = _rs.blur > 0;
    // The scrim, not `Colors.black`: a shadow is the palette's own
    // "something dark over the page".
    final shadow = _rs.shadow;
    // A notched bar paints its own, behind the clip — see below.
    final decorationShadow = (_rs.notch && widget.floatingActionButton != null)
        ? const <BoxShadow>[]
        : shadow;
    final hasNotch = _rs.notch && widget.floatingActionButton != null;
    final hasBorderGradient = _rs.borderGradient != null;

    // Build items
    final isScrollable = _rs.scrollable;
    Widget itemsRow;
    final itemWidgets = <Widget>[
      for (var i = 0; i < widget.items.length; i++)
        _buildItem(
          i,
          activeIndex,
          selectedColor,
          unselectedColor,
          disabledColor,
          indicatorRadius,
          wrapExpanded: !isScrollable,
        ),
    ];

    if (isScrollable) {
      itemsRow = SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: itemWidgets
              .map(
                (w) => SizedBox(
                  width: BottomNavDefaults.scrollItemWidth,
                  child: w,
                ),
              )
              .toList(),
        ),
      );
    } else if (hasNotch) {
      final midPoint = widget.items.length ~/ 2;
      itemsRow = Row(
        children: [
          for (var i = 0; i < midPoint; i++) itemWidgets[i],
          const SizedBox(width: BottomNavDefaults.notchFabGap),
          for (var i = midPoint; i < widget.items.length; i++) itemWidgets[i],
        ],
      );
    } else {
      itemsRow = Row(spacing: _rs.itemSpacing ?? 0, children: itemWidgets);
    }

    // Sliding indicator
    if (_rs.indicatorStyle == BottomNavIndicatorStyle.sliding) {
      itemsRow = Stack(
        children: [
          AnimatedPositioned(
            duration: _motion,
            curve: _rs.animationCurve,
            left: _calcSlidingPosition(activeIndex, context, hasNotch),
            top: 0,
            child: Container(
              width: BottomNavDefaults.slidingIndicatorWidth,
              height: BottomNavDefaults.slidingIndicatorHeight,
              decoration: BoxDecoration(
                color: _rs.indicatorColor,
                borderRadius: BorderRadius.circular(
                  BottomNavDefaults.slidingIndicatorHeight,
                ),
              ),
            ),
          ),
          itemsRow,
        ],
      );
    }

    // Custom indicator overlay
    if (_rs.indicatorStyle == BottomNavIndicatorStyle.custom &&
        _rs.customIndicator != null) {
      itemsRow = Stack(
        children: [
          AnimatedPositioned(
            duration: _motion,
            curve: _rs.animationCurve,
            left: _calcSlidingPosition(activeIndex, context, hasNotch),
            top: 0,
            bottom: 0,
            child: SizedBox(
              width: BottomNavDefaults.slidingIndicatorWidth * 2,
              child: Center(child: _rs.customIndicator!),
            ),
          ),
          itemsRow,
        ],
      );
    }

    final hasProminent = widget.items.any((i) => i.prominent);

    // How far a prominent circle rises above the row it sits in.
    //
    // The bar's own box has to COVER it. Flutter hit-tests a render box
    // against its size and never outside it, so a circle drawn above
    // the bar was a circle nobody could tap where they could see it —
    // the tap went straight through to whatever the page had there.
    final lift = hasProminent ? -BottomNavDefaults.prominentOffset : 0.0;

    final itemsPadded = Padding(
      padding: EdgeInsets.only(bottom: _rs.floating ? 0 : safePadding),
      // The `Material` belongs HERE, inside the bar, not around it.
      //
      // An ink feature paints on its Material's own canvas, which sits
      // BENEATH that Material's child — so a transparent Material
      // wrapped around the whole bar drew every splash, hover and focus
      // ring underneath the bar's opaque background, where nothing
      // could see it. Tapping a destination looked completely dead, and
      // keyboard focus was invisible for the same reason.
      child: Material(
        type: MaterialType.transparency,
        child: SizedBox(
          height: height,
          // INSIDE the height, not around it, so `height` stays the
          // bar's total and a caller can size the surface to its
          // contents rather than to the contents plus an inset it did
          // not ask for.
          child: _rs.contentPadding == null
              ? itemsRow
              : Padding(padding: _rs.contentPadding!, child: itemsRow),
        ),
      ),
    );

    Widget? topBorderWidget;
    if (_rs.topBorderGradient != null) {
      topBorderWidget = Container(
        height: _rs.topBorderWidth,
        decoration: BoxDecoration(gradient: _rs.topBorderGradient),
      );
    }

    // Background decoration
    BoxDecoration bgDecoration;
    if (hasBorderGradient) {
      bgDecoration = BoxDecoration(
        gradient: _rs.borderGradient,
        borderRadius: borderRadius,
        boxShadow: decorationShadow,
      );
    } else {
      bgDecoration = BoxDecoration(
        color: hasBlur
            ? bg.withValues(alpha: BottomNavDefaults.blurBgOpacity)
            : (_rs.backgroundGradient == null ? bg : null),
        gradient: _rs.backgroundGradient,
        borderRadius: borderRadius,
        // A solid top border is part of the DECORATION, so it follows
        // the corner. It used to be a plain full-width `Container`
        // stacked above the bar — a straight line across a rounded box,
        // overhanging both corners.
        border:
            _rs.border ??
            (_rs.topBorder != null ? Border(top: _rs.topBorder!) : null),
        boxShadow: decorationShadow,
      );
    }

    // Inner container for gradient border
    BoxDecoration? innerDecoration;
    if (hasBorderGradient) {
      innerDecoration = BoxDecoration(
        color: hasBlur
            ? bg.withValues(alpha: BottomNavDefaults.blurBgOpacity)
            : (_rs.backgroundGradient == null ? bg : null),
        gradient: _rs.backgroundGradient,
        borderRadius: borderRadius.subtract(
          BorderRadius.all(Radius.circular(_rs.borderWidth)),
        ),
      );
    }

    Widget result;

    if (hasProminent) {
      // Stack: background at bottom (clipped), items on top (overflow visible)
      Widget bgBox;
      if (hasBorderGradient) {
        bgBox = Container(
          decoration: bgDecoration,
          child: Container(
            margin: EdgeInsets.all(_rs.borderWidth),
            decoration: innerDecoration,
          ),
        );
      } else {
        bgBox = Container(decoration: bgDecoration);
      }

      // The box is `lift` TALLER than the bar, and both layers start
      // that far down: the surface and the row sit exactly where they
      // did, and the strip above them — which is what the circle rises
      // into — is now inside the bar's own render box instead of
      // outside it. `_TapAbove` is what makes a tap up there count.
      result = SizedBox(
        height: totalHeight + lift,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            // Background — fills the bar area, clipped to borderRadius
            Positioned(
              top: lift,
              left: 0,
              right: 0,
              bottom: 0,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ?topBorderWidget,
                  Expanded(child: bgBox),
                ],
              ),
            ),
            // Items — overflow visible for prominent items
            Positioned(
              top: lift,
              left: 0,
              right: 0,
              bottom: 0,
              child: _TapAbove(extent: lift, child: itemsPadded),
            ),
          ],
        ),
      );
    } else {
      // Normal: wrap items inside the background container
      Widget bar = Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ?topBorderWidget,
          SizedBox(
            height: totalHeight,
            // BOTTOM-aligned: the box is as tall as the FULL inset so
            // the surface reaches the screen edge, and the row sits its
            // scaled padding up from the bottom of it. Top-aligned, the
            // row stays put and the factor does nothing at all — the
            // gap it is supposed to shrink is below the row either way.
            child: Align(
              alignment: Alignment.bottomCenter,
              child: itemsPadded,
            ),
          ),
        ],
      );

      if (hasBorderGradient) {
        result = Container(
          decoration: bgDecoration,
          child: Container(
            margin: EdgeInsets.all(_rs.borderWidth),
            decoration: innerDecoration,
            clipBehavior: Clip.antiAlias,
            child: bar,
          ),
        );
      } else {
        result = Container(
          decoration: bgDecoration,
          clipBehavior: borderRadius != BorderRadius.zero
              ? Clip.antiAlias
              : Clip.none,
          child: bar,
        );
      }
    }

    if (hasNotch) {
      // The shadow goes BEHIND and outside the clip. A `ClipPath` cuts
      // everything its child paints, and a shadow is painted outside
      // the shape by definition — so notching the bar also erased its
      // elevation, and the top edge went flat and hard.
      result = _wrapNotchClip(result, borderRadius);
      if (shadow.isNotEmpty) {
        result = CustomPaint(
          painter: _NotchedShadowPainter(
            shape: _notchShape,
            notchRadius: BottomNavDefaults.notchRadius,
            notchMargin: _rs.notchMargin,
            borderRadius: borderRadius,
            fabSize: _rs.notchFabSize,
            shadows: shadow,
          ),
          child: result,
        );
      }
      // The outline has to TRACE the cutout. A `BoxDecoration` border is
      // a rounded rectangle, and the clip then takes out the stretch
      // that crosses the notch — so the line stopped dead at one lip of
      // the hole and picked up again at the other. Stroking the clip's
      // own path is the only way round it, and it is the only place a
      // gradient border can follow the curve too.
      final outline = _rs.borderGradient != null
          ? null
          : (_rs.border?.top ?? _rs.topBorder);
      if (outline != null || _rs.borderGradient != null) {
        result = CustomPaint(
          foregroundPainter: _NotchedOutlinePainter(
            shape: _notchShape,
            notchRadius: BottomNavDefaults.notchRadius,
            notchMargin: _rs.notchMargin,
            borderRadius: borderRadius,
            fabSize: _rs.notchFabSize,
            color: outline?.color,
            gradient: _rs.borderGradient,
            width: outline?.width ?? _rs.borderWidth,
          ),
          child: result,
        );
      }
    }
    if (hasBlur) result = _wrapBlur(result, borderRadius);
    return result;
  }

  Widget _wrapBlur(Widget child, BorderRadius borderRadius) => ClipRRect(
    borderRadius: borderRadius,
    // WITH A SAVE LAYER: a plain antialiased clip does not contain a
    // `BackdropFilter`, so the bar's rounded corners come back SQUARE.
    clipBehavior: Clip.antiAliasWithSaveLayer,
    child: BackdropFilter(
      filter: ImageFilter.blur(sigmaX: _rs.blur, sigmaY: _rs.blur),
      child: child,
    ),
  );

  /// The shape the notch is cut to.
  ///
  /// A caller's own wins. Otherwise it is taken from the BUTTON: a
  /// `FloatingActionButton` that declares a `shape` gets that shape
  /// traced, which is what makes a squircle FAB sit in a squircle hole
  /// instead of a round one. Only a bare FAB falls back to a circle.
  NotchedShape get _notchShape {
    final given = _rs.notchShape;
    if (given != null) return given;

    // The button's corner, from whichever of the three knows it.
    var radius = _rs.notchFabRadius;

    final fab = widget.floatingActionButton;
    final theme = Theme.of(context);
    final shape =
        (fab is FloatingActionButton ? fab.shape : null) ??
        theme.floatingActionButtonTheme.shape;

    if (shape is RoundedRectangleBorder) {
      radius = shape.borderRadius.resolve(Directionality.of(context)).topLeft.x;
    } else if (shape is CircleBorder || shape is StadiumBorder) {
      // A round button's cutout is a half-circle, which is the corner
      // running the full half-width.
      radius = _rs.notchFabSize / 2;
    } else if (!theme.useMaterial3) {
      // Material 2's FAB is a circle.
      radius = _rs.notchFabSize / 2;
    }

    return FabNotchedShape(
      // CONCENTRIC: the cutout is outside the button by the gap, so its
      // corner is the button's plus that gap. Reusing the button's own
      // radius on a larger shape is the mistake the second image is
      // about.
      cornerRadius: radius + _rs.notchMargin,
      lipRadius: _rs.notchLipRadius,
    );
  }

  Widget _wrapNotchClip(Widget child, BorderRadius borderRadius) => ClipPath(
    clipper: _NotchClipper(
      shape: _notchShape,
      notchRadius: BottomNavDefaults.notchRadius,
      notchMargin: _rs.notchMargin,
      borderRadius: borderRadius,
      fabSize: _rs.notchFabSize,
    ),
    child: child,
  );

  double _calcSlidingPosition(int index, BuildContext context, bool hasNotch) {
    var barWidth =
        MediaQuery.of(context).size.width -
        (_rs.floating ? _rs.floatingMargin.horizontal : 0);
    // Account for gradient border inset
    if (_rs.borderGradient != null) barWidth -= _rs.borderWidth * 2;
    final itemCount = widget.items.length;
    final itemWidth = hasNotch
        ? (barWidth - BottomNavDefaults.notchFabGap) / itemCount
        : barWidth / itemCount;
    final midPoint = widget.items.length ~/ 2;
    final offset = (hasNotch && index >= midPoint)
        ? index * itemWidth + BottomNavDefaults.notchFabGap
        : index * itemWidth;
    final borderInset = _rs.borderGradient != null ? _rs.borderWidth : 0.0;
    return offset +
        (itemWidth - BottomNavDefaults.slidingIndicatorWidth) / 2 +
        borderInset;
  }

  // ─── Item ─────────────────────────────────────────────────

  Widget _buildItem(
    int index,
    int activeIndex,
    Color selectedColor,
    Color unselectedColor,
    Color disabledColor,
    double indicatorRadius, {
    bool wrapExpanded = true,
  }) {
    final item = widget.items[index];
    final isSelected = index == activeIndex;
    final isDisabled = item.disabled;
    final fg = isDisabled
        ? disabledColor
        : (isSelected ? selectedColor : unselectedColor);
    final compact = _rs.compact;
    final vPad = compact
        ? BottomNavDefaults.compactItemVPad
        : BottomNavDefaults.itemVPad;
    final showLabel = switch (_rs.labelMode) {
      BottomNavLabelMode.always => true,
      BottomNavLabelMode.selectedOnly => isSelected,
      BottomNavLabelMode.never => false,
    };

    // Custom builder
    if (widget.itemBuilder != null) {
      final custom = InkResponse(
        onTap: isDisabled ? null : () => _onItemTap(index),
        canRequestFocus: !isDisabled,
        hoverColor: selectedColor.withValues(alpha: 0.06),
        focusColor: selectedColor.withValues(alpha: 0.12),
        highlightColor: selectedColor.withValues(alpha: 0.1),
        splashColor: selectedColor.withValues(alpha: 0.18),
        child: widget.itemBuilder!(context, item, index, isSelected),
      );
      return wrapExpanded ? Expanded(child: custom) : custom;
    }

    // Resolve icon
    Widget icon;
    if (item.lottieAsset != null) {
      // A designed animation, driven by the SAME trigger the Material
      // morphs use. It used to render only while selected and play
      // once, so it could not answer a press or a hover and showed
      // nothing at all the rest of the time.
      icon = _MorphLottie(
        key: _lottieKey(index),
        asset: item.lottieAsset!,
        trigger: item.animatedIconTrigger ?? BottomNavIconTrigger.selection,
        selected: isSelected,
        size: BottomNavDefaults.lottieSize,
        repeat: item.lottieRepeat,
        reduceMotion: _reduceMotion,
      );
    } else if (item.animatedIcon != null) {
      // A glyph that MORPHS, rather than one that is nudged. The
      // reaction still applies on top, so a morphing icon can grow
      // under a press as well.
      icon = _MorphIcon(
        key: _morphKey(index),
        icon: item.animatedIcon!,
        trigger: item.animatedIconTrigger ?? BottomNavIconTrigger.selection,
        selected: isSelected,
        size: _rs.iconSize,
        color: fg,
        duration: _reduceMotion ? Duration.zero : _rs.animationDuration,
        curve: _rs.animationCurve,
      );
    } else if (item.customIcon != null) {
      icon = isSelected
          ? (item.activeCustomIcon ?? item.customIcon!)
          : item.customIcon!;
    } else {
      final iconData = isSelected ? (item.activeIcon ?? item.icon) : item.icon;
      // CROSS-FADE between the two shapes, and keyed on the glyph so
      // the switcher knows they are different. A plain `Icon` swap is a
      // cut in the middle of a transition everything else is easing.
      icon = AnimatedSwitcher(
        duration: _motion,
        switchInCurve: _rs.animationCurve,
        switchOutCurve: _rs.animationCurve,
        child: Icon(
          iconData,
          key: ValueKey(iconData),
          size: _rs.iconSize,
        ),
      );
    }

    // The COLOUR eases too. It was passed straight to the glyph, so the
    // selection landed instantly while the pill, the label weight and
    // the indicator were all still moving — one part of the item
    // arriving before the rest.
    icon = TweenAnimationBuilder<Color?>(
      tween: ColorTween(end: fg),
      duration: _motion,
      curve: _rs.animationCurve,
      builder: (context, color, child) => IconTheme.merge(
        data: IconThemeData(color: color ?? fg, size: _rs.iconSize),
        child: child!,
      ),
      child: icon,
    );

    // The reaction wraps the GLYPH, inside the pill.
    //
    // Around the whole tap target it sat between the ink's reference
    // box and the indicator, and `getRectCallback` measures through it
    // — so pressing a destination grew the glyph AND the highlight by
    // the same amount, and the highlight stopped matching the pill it
    // lands in.
    icon = _ReactiveIcon(
      key: _reactionKey(index),
      reaction: _rs.iconReaction,
      amount: _rs.iconReactionScale,
      duration: _reduceMotion ? Duration.zero : _rs.animationDuration,
      curve: _rs.animationCurve,
      enabled: !isDisabled,
      child: icon,
    );

    // The gradient is applied to the whole item further down, not
    // here: a shader on the glyph alone left the label in a flat colour
    // beneath a gradient icon, which reads as two different states of
    // the same destination.

    // Bounce
    if (_bounceCtrl != null && _bouncingIndex == index) {
      icon = AnimatedBuilder(
        animation: _bounceCtrl!,
        builder: (_, child) => Transform.scale(
          scale:
              1.0 +
              (BottomNavDefaults.bounceScale - 1.0) *
                  Curves.easeOut.transform(_bounceCtrl!.value),
          child: child,
        ),
        child: icon,
      );
    }

    // Badge / dot — `GlobalBadge`, which also puts them on the reading
    // END rather than the physical right, so they mirror in Arabic.
    if (item.badge != null || item.showDot) {
      icon = Stack(
        clipBehavior: Clip.none,
        children: [
          icon,
          if (item.badge != null)
            PositionedDirectional(
              top: BottomNavDefaults.badgeOffset,
              end: BottomNavDefaults.badgeOffset,
              child: GlobalBadge.standalone(
                label: item.badge,
                style: BadgeStyle(
                  backgroundColor: isDisabled ? disabledColor : selectedColor,
                ),
              ),
            )
          else if (item.showDot)
            PositionedDirectional(
              top: BottomNavDefaults.dotOffset,
              end: BottomNavDefaults.dotOffset,
              child: GlobalBadge.standalone(
                style: BadgeStyle(
                  backgroundColor: isDisabled
                      ? disabledColor
                      : (item.dotColor ?? selectedColor),
                ),
              ),
            ),
        ],
      );
    }

    // Prominent item
    if (item.prominent) {
      return _buildProminentItem(
        index,
        icon,
        item,
        isSelected,
        selectedColor,
        isDisabled,
        showLabel,
        fg,
        wrapExpanded: wrapExpanded,
      );
    }

    // Label
    Widget? label;
    if (showLabel) {
      final labelStyle = TextStyle(
        fontSize: isSelected ? _rs.selectedFontSize : _rs.unselectedFontSize,
        fontWeight: isSelected
            ? BottomNavDefaults.labelSelectedWeight
            : BottomNavDefaults.labelUnselectedWeight,
        color: fg,
      );

      // A destination is a fifth of the screen wide, so a label that
      // does not fit is common rather than exotic — and an ellipsis on
      // a two-word label leaves "Not…", which names nothing.
      // `GlobalMarquee` only scrolls what actually overflows; a label
      // that fits is a plain `Text` inside it.
      label = AnimatedDefaultTextStyle(
        duration: _motion,
        style: labelStyle,
        child: _rs.marqueeLabels
            ? GlobalMarquee(
                semanticLabel: item.label,
                style: _rs.marqueeStyle,
                child: Text(
                  item.label,
                  maxLines: 1,
                  softWrap: false,
                  style: labelStyle,
                ),
              )
            : Text(item.label, maxLines: 1, overflow: TextOverflow.ellipsis),
      );
    }

    // Build content
    Widget itemContent;
    final indStyle = _rs.indicatorStyle;

    if (indStyle == BottomNavIndicatorStyle.pill) {
      itemContent = AnimatedContainer(
        duration: _motion,
        curve: _rs.animationCurve,
        // `itemPadding` wins where a caller set one. The pill branch
        // used to ignore it and reach straight for the defaults, so a
        // design with its own measurements — a snug square around the
        // glyph rather than Material's roomy lozenge — had no way to
        // ask for it, and the field looked like it did nothing.
        //
        // Applied to BOTH states so the glyph does not shift as the
        // selection moves: an unselected cell with different padding is
        // a different size, and the row re-flows on every tap.
        padding:
            _rs.itemPadding ??
            EdgeInsets.symmetric(
              horizontal: isSelected
                  ? BottomNavDefaults.pillHPad
                  : BottomNavDefaults.itemHPad,
              // Compact has 52dp for a 24dp glyph, a gap and a label.
              // The roomy padding made that 53, and a `Column` one
              // pixel over its box overflows on every frame.
              vertical: compact
                  ? BottomNavDefaults.compactPillVPad
                  : BottomNavDefaults.pillVPad,
            ),
        decoration: BoxDecoration(
          color: isSelected
              ? (_rs.indicatorColor).withValues(alpha: _rs.indicatorOpacity)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(indicatorRadius),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            icon,
            _labelSlot(label, compact),
          ],
        ),
      );

      final width = _rs.indicatorWidth;
      if (width != null) {
        // A MINIMUM, not a fixed width. Tight, every pill is the same
        // and a label longer than it is CLIPPED, which is worse than
        // the unevenness it fixes. And no `LayoutBuilder`: a builder
        // here re-runs whenever the marquee measures its child, and the
        // marquee measures whenever it is rebuilt — the two chase each
        // other and the frame never completes.
        itemContent = ConstrainedBox(
          constraints: BoxConstraints(minWidth: width),
          child: itemContent,
        );
      }
    } else {
      itemContent = Padding(
        padding:
            _rs.itemPadding ??
            EdgeInsets.symmetric(
              horizontal: BottomNavDefaults.itemHPad,
              vertical: vPad,
            ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (indStyle == BottomNavIndicatorStyle.topBar)
              _buildBarIndicator(
                isSelected,
                selectedColor,
                bottom: BottomNavDefaults.indicatorMargin,
              ),
            icon,
            _labelSlot(label, compact),
            if (indStyle == BottomNavIndicatorStyle.bottomBar)
              _buildBarIndicator(
                isSelected,
                selectedColor,
                top: BottomNavDefaults.indicatorMargin,
              ),
            if (indStyle == BottomNavIndicatorStyle.dot)
              AnimatedContainer(
                duration: _motion,
                curve: _rs.animationCurve,
                width: isSelected ? BottomNavDefaults.dotIndicatorSize : 0,
                height: isSelected ? BottomNavDefaults.dotIndicatorSize : 0,
                margin: const EdgeInsets.only(
                  top: BottomNavDefaults.indicatorMargin,
                ),
                decoration: BoxDecoration(
                  color: _rs.indicatorColor,
                  shape: BoxShape.circle,
                ),
              ),
          ],
        ),
      );
    }

    // NEVER overflow the bar, whatever the caller configured.
    //
    // A destination's height is icon plus gap plus label plus padding,
    // and every one of those is a knob: a bigger glyph, a larger type
    // scale, a compact bar, a font the platform substituted. Each
    // combination that came out a point or two over the bar was a
    // separate yellow-and-black stripe and a separate fix. Scaling down
    // only when it does not fit costs nothing when it does, and turns
    // the whole class of bug into a slightly smaller label.
    itemContent = _FitHeight(child: itemContent);

    // GRADIENT over the whole destination — glyph and label together.
    if (item.iconGradient != null && isSelected) {
      itemContent = ShaderMask(
        shaderCallback: (bounds) => item.iconGradient!.createShader(bounds),
        blendMode: BlendMode.srcIn,
        child: itemContent,
      );
    }

    // Tooltip
    Widget tapTarget = Center(
      child: KeyedSubtree(key: _indicatorKey(index), child: itemContent),
    );
    if (item.tooltip != null) {
      tapTarget = GlobalTooltip(
        message: item.tooltip,
        preferBelow: false,
        child: tapTarget,
      );
    }

    // The whole cell takes the TAP; the ink is confined to the
    // indicator. An `InkWell` fills its box, so the ripple was a slab
    // running corner to corner of the cell — far wider than the pill it
    // is meant to sit inside, and nothing like the shape it lands in.
    final reaction = _reactionKey(index);
    final morph = _morphKey(index);
    final lottie = _lottieKey(index);
    final result = _IndicatorInkWell(
      // The INK owns the focus node, so it is the only thing that knows
      // about keyboard focus. The reaction used to listen on a `Focus`
      // of its own, placed as a DESCENDANT of that node — which never
      // hears it, because focus travels down from the node that has it.
      onFocusChange: (v) {
        reaction.currentState?.setFocused(v);
        morph.currentState?.setPointer(focused: v);
        lottie.currentState?.setPointer(focused: v);
      },
      onHover: (v) {
        reaction.currentState?.setHovered(v);
        morph.currentState?.setPointer(hovered: v);
        lottie.currentState?.setPointer(hovered: v);
      },
      onHighlightChanged: (v) {
        reaction.currentState?.setPressed(v);
        morph.currentState?.setPressed(v);
        lottie.currentState?.setPressed(v);
      },
      indicatorKey: _indicatorKey(index),
      inkRadius: indicatorRadius,
      vPad: vPad,
      onTap: isDisabled ? null : () => _onItemTap(index),
      onLongPress: isDisabled ? null : item.onLongPress,
      canRequestFocus: !isDisabled,
      hoverColor: selectedColor.withValues(alpha: 0.06),
      focusColor: selectedColor.withValues(alpha: 0.14),
      highlightColor: selectedColor.withValues(alpha: 0.1),
      splashColor: selectedColor.withValues(alpha: 0.18),
      customBorder: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(indicatorRadius),
      ),
      child: Opacity(
        opacity: isDisabled ? BottomNavDefaults.disabledOpacity : 1.0,
        child: tapTarget,
      ),
    );
    final node = _withItemEntrance(
      _withItemSemantics(result, item, index, isSelected, isDisabled),
      index,
    );
    return wrapExpanded ? Expanded(child: node) : node;
  }

  /// ONE node per destination, and everything under it excluded.
  ///
  /// There was not a single `Semantics` in this module. An `InkWell`
  /// around an icon and a `Text` announces the text and nothing else —
  /// no "selected", no "tab 2 of 5", no "disabled" — so a screen reader
  /// got five unlabelled buttons that all looked alike, on the one
  /// surface that decides where the whole app goes.
  ///
  /// The badge and the dot ARE information ("Inbox, 9"), so they go
  /// into the label rather than being dropped with the rest.
  Widget _withItemSemantics(
    Widget child,
    BottomNavItem item,
    int index,
    bool isSelected,
    bool isDisabled,
  ) {
    final badge = item.badge;
    final label = badge != null && badge.isNotEmpty
        ? '${item.label}, $badge'
        : item.label;

    return Semantics(
      container: true,
      button: true,
      selected: isSelected,
      enabled: !isDisabled,
      label: label,
      // Position in the bar. A destination is one of a set, and which
      // one it is cannot be worked out from its own name.
      hint: NavStrings.tabPosition(index + 1, widget.items.length),
      onTap: isDisabled ? null : () => _onItemTap(index),
      excludeSemantics: true,
      child: child,
    );
  }

  /// The label's slot, which ANIMATES open and shut.
  ///
  /// Under `selectedOnly` the label used to be built or not built, so
  /// it appeared and vanished between two frames while the pill around
  /// it was still easing — the one part of the item that jumped.
  /// `AnimatedSize` gives the row its height back over the same
  /// duration, and the text fades rather than blinking.
  Widget _labelSlot(Widget? label, bool compact) {
    final gap = compact
        ? BottomNavDefaults.compactIconLabelGap
        : BottomNavDefaults.iconLabelGap;
    return AnimatedSize(
      duration: _motion,
      curve: _rs.animationCurve,
      // From the TOP: the label grows downward out of the glyph rather
      // than pushing it up.
      alignment: Alignment.topCenter,
      child: label == null
          // SHRINK, not an infinite width. The pill is fitted with
          // `BoxFit.scaleDown`, which hands its child UNBOUNDED
          // constraints — and an infinite width under those is a
          // hard layout error, not a stretch. The width was there to
          // hold the row open before the indicator had a minimum of
          // its own, which it now does.
          ? const SizedBox.shrink()
          : Padding(
              padding: EdgeInsets.only(top: gap),
              child: AnimatedOpacity(
                duration: _motion,
                opacity: 1,
                child: label,
              ),
            ),
    );
  }

  // ─── Prominent item ───────────────────────────────────────

  Widget _buildProminentItem(
    int index,
    Widget icon,
    BottomNavItem item,
    bool isSelected,
    Color selectedColor,
    bool isDisabled,
    bool showLabel,
    Color fg, {
    bool wrapExpanded = true,
  }) {
    // CLAMPED to what the bar can hold. The circle is lifted, so it
    // only claims `size + prominentOffset` of height — but a compact
    // bar is 52 points and that plus a label came to 55, which is a
    // stripe on every frame.
    final labelRoom = showLabel
        ? _rs.unselectedFontSize * BottomNavDefaults.labelLineFactor
        : 0.0;
    final size = math.min(
      item.prominentSize ?? BottomNavDefaults.prominentSize,
      math.max(
        _rs.height - labelRoom - BottomNavDefaults.prominentOffset,
        BottomNavDefaults.iconSize,
      ),
    );
    final color = item.prominentColor ?? selectedColor;

    Widget? label;
    if (showLabel) {
      label = Padding(
        padding: const EdgeInsets.only(
          top: BottomNavDefaults.prominentLabelTopPad,
        ),
        child: Text(
          item.label,
          style: TextStyle(
            fontSize: _rs.unselectedFontSize,
            fontWeight: BottomNavDefaults.labelUnselectedWeight,
            color: fg,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      );
    }

    final content = InkResponse(
      onTap: isDisabled ? null : () => _onItemTap(index),
      canRequestFocus: !isDisabled,
      customBorder: const CircleBorder(),
      hoverColor: color.withValues(alpha: 0.12),
      focusColor: color.withValues(alpha: 0.22),
      highlightColor: color.withValues(alpha: 0.16),
      splashColor: color.withValues(alpha: 0.28),
      child: Opacity(
        opacity: isDisabled ? BottomNavDefaults.disabledOpacity : 1.0,
        // NOT a `FittedBox` here: it hands its child unbounded
        // constraints, and the lift's `OverflowBox` cannot take those.
        // The circle is clamped to the bar instead — see `size`.
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // The circle is LIFTED out of the bar, so it must not claim
            // the height it paints. `Transform.translate` moves the paint
            // and leaves the layout where it was: 48 of circle plus a
            // label in a 64dp bar overflowed by exactly the four points
            // the lift was supposed to save.
            SizedBox(
              height: size + BottomNavDefaults.prominentOffset,
              child: OverflowBox(
                maxHeight: size,
                alignment: Alignment.topCenter,
                child: Transform.translate(
                  offset: const Offset(0, BottomNavDefaults.prominentOffset),
                  child: Container(
                    width: size,
                    height: size,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: color.withValues(alpha: 0.4),
                          blurRadius: BottomNavDefaults.prominentBlur,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Center(
                      child: IconTheme(
                        // What reads ON the prominent fill. It was
                        // `Colors.white`, which is wrong the moment that fill
                        // is a light colour.
                        data: IconThemeData(
                          color: _rs.prominentIconColor,
                          size: _rs.iconSize,
                        ),
                        child: icon,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            if (label != null) label,
          ],
        ),
      ),
    );
    // The circle paints `prominentOffset` above this item's own box,
    // and a render box takes no hit outside its size. Without this the
    // top of the button is a picture of a button.
    final tappable = _TapAbove(
      extent: -BottomNavDefaults.prominentOffset,
      child: content,
    );
    return wrapExpanded ? Expanded(child: tappable) : tappable;
  }

  // ─── Bar indicator ────────────────────────────────────────

  Widget _buildBarIndicator(
    bool isSelected,
    Color selectedColor, {
    double top = 0,
    double bottom = 0,
  }) => AnimatedContainer(
    duration: _motion,
    curve: _rs.animationCurve,
    width: isSelected ? BottomNavDefaults.barIndicatorWidth : 0,
    height: isSelected ? _rs.indicatorBarThickness : 0,
    margin: EdgeInsets.only(top: top, bottom: bottom),
    decoration: BoxDecoration(
      color: _rs.indicatorColor,
      borderRadius: BorderRadius.circular(_rs.indicatorBarThickness),
    ),
  );
}

// ═══════════════════════════════════════════════════════════════
// Tapping what is painted above the box
// ═══════════════════════════════════════════════════════════════

/// Lets a tap land on what a child PAINTS above its own box.
///
/// A prominent destination's circle is lifted out of the bar by
/// `prominentOffset`, and Flutter hit-tests a render box against its
/// size and nothing else — so the part above the edge took no taps at
/// all. They fell through to whatever was behind the bar, which on a
/// `Scaffold` is the page: pressing the button silently pressed the
/// content underneath it.
///
/// A position in the strip is CLAMPED onto the top edge and offered to
/// the child as an ordinary hit, so nothing that did not already accept
/// a tap starts accepting one. An ordinary destination's box begins
/// below the strip and goes on refusing it.
class _TapAbove extends SingleChildRenderObjectWidget {
  const _TapAbove({required this.extent, required Widget super.child});

  /// How far above the box a tap still counts. Zero is a no-op.
  final double extent;

  @override
  RenderObject createRenderObject(BuildContext context) =>
      _RenderTapAbove(extent);

  @override
  void updateRenderObject(BuildContext context, _RenderTapAbove renderObject) {
    renderObject.extent = extent;
  }
}

class _RenderTapAbove extends RenderProxyBox {
  _RenderTapAbove(this.extent);

  /// Hit testing only, so a change needs no layout and no repaint.
  double extent;

  @override
  bool hitTest(BoxHitTestResult result, {required Offset position}) {
    if (position.dy >= 0 || position.dy < -extent) {
      return super.hitTest(result, position: position);
    }
    if (position.dx < 0 || position.dx >= size.width) return false;
    return super.hitTest(result, position: Offset(position.dx, 0));
  }
}

// ═══════════════════════════════════════════════════════════════
// Notch clipper with smooth curves
// ═══════════════════════════════════════════════════════════════

/// An `InkResponse` whose ink is bounded by the INDICATOR, not by the
/// cell it lives in.
///
/// The same trick Material's own `NavigationBar` uses: the tap target
/// stays the full destination, so a finger anywhere in the column
/// works, while the splash, the hover wash and the focus ring are drawn
/// inside the pill.
class _IndicatorInkWell extends InkResponse {
  const _IndicatorInkWell({
    required this.indicatorKey,
    super.onFocusChange,
    super.onHover,
    super.onHighlightChanged,
    required this.inkRadius,
    required this.vPad,
    required super.child,
    super.onTap,
    super.onLongPress,
    super.canRequestFocus,
    super.hoverColor,
    super.focusColor,
    super.highlightColor,
    super.splashColor,
    super.customBorder,
  }) : super(containedInkWell: true, highlightShape: BoxShape.rectangle);

  /// Points at the indicator box itself, so the ink can be MEASURED
  /// against it rather than guessed at as a fraction of the cell.
  final GlobalKey indicatorKey;

  final double inkRadius;
  final double vPad;

  @override
  RectCallback getRectCallback(RenderBox referenceBox) => () {
    final cell = referenceBox.size;

    // The indicator's own rect, in this cell's coordinates. The pill is
    // content-width — icon, label and padding — so a fraction of the
    // cell came out visibly wider than the selected state the ripple
    // lands on.
    final target = indicatorKey.currentContext?.findRenderObject();
    if (target is RenderBox && target.hasSize && referenceBox.attached) {
      final origin = target.localToGlobal(
        Offset.zero,
        ancestor: referenceBox,
      );
      final rect = origin & target.size;
      // Only if it actually sits inside: a stale key during a rebuild
      // must not push the ink somewhere it cannot be seen.
      if (rect.width > 0 && rect.height > 0) return rect;
    }

    // Before first layout there is nothing to measure.
    final width = math.min(
      cell.width * BottomNavDefaults.inkWidthFraction,
      cell.width - BottomNavDefaults.inkMinInset * 2,
    );
    return Rect.fromCenter(
      center: Offset(cell.width / 2, cell.height / 2),
      width: math.max(width, 0),
      height: math.max(cell.height - vPad * 2, BottomNavDefaults.inkMinInset),
    );
  };
}

/// The bar's silhouette with a cutout for the button, built as a PATH
/// rather than subtracted as a shape.
///
/// Subtracting the button's own border gives no control over two things
/// that matter:
///
///   * the CORNER of the cutout, which is not the button's corner.
///     Concentric shapes share a centre, so the outer radius is the
///     inner radius plus the distance between them — a cutout drawn at
///     the button's own radius reads tight at the corners against the
///     button sitting in it. `cornerRadius` is `fabRadius + gap`.
///   * the LIPS, where the cutout meets the top edge. A subtraction
///     leaves a sharp corner there; a fillet is a quadratic whose
///     control point IS that corner, so the edge leaves tangentially.
///     Zero gives the sharp version back.
@visibleForTesting
class FabNotchedShape extends NotchedShape {
  const FabNotchedShape({
    required this.cornerRadius,
    required this.lipRadius,
  });

  /// The CUTOUT's corner, not the button's.
  final double cornerRadius;

  /// Zero is a sharp lip.
  final double lipRadius;

  @override
  Path getOuterPath(Rect host, Rect? guest) {
    if (guest == null || !host.overlaps(guest)) {
      return Path()..addRect(host);
    }

    // Never wider than the bar, and never deeper than it either.
    final depth = math.min(guest.bottom - host.top, host.height);
    final corner = math.min(
      cornerRadius,
      math.min(guest.width / 2, math.max(depth, 0)),
    );
    final lip = math.max(lipRadius, 0.0);

    final left = math.max(guest.left, host.left);
    final right = math.min(guest.right, host.right);
    final bottom = host.top + math.max(depth, 0);

    return Path()
      ..moveTo(host.left, host.top)
      ..lineTo(left - lip, host.top)
      // Into the cutout. The control point is the corner the
      // subtraction would have left, so the edge leaves tangentially.
      ..quadraticBezierTo(left, host.top, left, host.top + lip)
      ..lineTo(left, bottom - corner)
      ..arcToPoint(
        Offset(left + corner, bottom),
        radius: Radius.circular(corner.toDouble()),
        clockwise: false,
      )
      ..lineTo(right - corner, bottom)
      ..arcToPoint(
        Offset(right, bottom - corner),
        radius: Radius.circular(corner.toDouble()),
        clockwise: false,
      )
      ..lineTo(right, host.top + lip)
      ..quadraticBezierTo(right, host.top, right + lip, host.top)
      ..lineTo(host.right, host.top)
      ..lineTo(host.right, host.bottom)
      ..lineTo(host.left, host.bottom)
      ..close();
  }
}

/// A glyph that REACTS to the pointer.
///
/// Distinct from the tap bounce, which fires once when a destination is
/// chosen. This tracks press, focus and hover for as long as they last
/// — the feedback that makes a destination feel like a control rather
/// than a picture of one.
///
/// It listens for itself rather than being told by the ink: `InkWell`
/// reports its highlights through callbacks that fire during a build,
/// and a `setState` from there is an error. A `MouseRegion` and a
/// `Listener` are cheap and answer to nobody.
class _ReactiveIcon extends StatefulWidget {
  const _ReactiveIcon({
    required this.reaction,
    required this.amount,
    required this.duration,
    required this.curve,
    required this.enabled,
    required this.child,
    super.key,
  });

  final BottomNavIconReaction reaction;
  final double amount;
  final Duration duration;
  final Curve curve;
  final bool enabled;
  final Widget child;

  @override
  State<_ReactiveIcon> createState() => _ReactiveIconState();
}

class _ReactiveIconState extends State<_ReactiveIcon> {
  bool _pressed = false;
  bool _hovered = false;
  bool _focused = false;

  /// Driven from the INK, which owns the focus node and is therefore
  /// the only thing that knows about keyboard focus. A `Focus` of this
  /// widget's own sits BELOW that node and never hears it — focus
  /// travels down from the node that has it, not up.
  void setPressed(bool v) => _set(() => _pressed = v);
  void setHovered(bool v) => _set(() => _hovered = v);
  void setFocused(bool v) => _set(() => _focused = v);

  void _set(VoidCallback change) {
    if (mounted) setState(change);
  }

  /// A press is stronger than a hover, which is stronger than focus.
  double get _t {
    if (!widget.enabled) return 0;
    if (_pressed) return 1;
    if (_hovered) return 0.6;
    if (_focused) return 0.45;
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    if (widget.reaction == BottomNavIconReaction.none || !widget.enabled) {
      return widget.child;
    }
    // The TWEEN carries the reaction, not the transform: applied
    // straight from the state it snaps, which is a flicker rather than
    // feedback.
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(end: _t),
      duration: widget.duration,
      curve: widget.curve,
      builder: (_, t, child) => _transform(t, child!),
      child: widget.child,
    );
  }

  Widget _transform(double t, Widget child) => switch (widget.reaction) {
    BottomNavIconReaction.none => child,
    BottomNavIconReaction.grow => Transform.scale(
      scale: 1 + widget.amount * t,
      child: child,
    ),
    // Shrinks under the press, the way a physical key gives.
    BottomNavIconReaction.press => Transform.scale(
      scale: 1 - widget.amount * t,
      child: child,
    ),
    BottomNavIconReaction.tilt => Transform.rotate(
      angle: BottomNavDefaults.iconReactionTilt * t,
      child: child,
    ),
    BottomNavIconReaction.lift => Transform.translate(
      offset: Offset(0, -BottomNavDefaults.iconReactionLift * t),
      child: child,
    ),
  };
}

/// A glyph that MORPHS, driven by whatever its trigger says.
///
/// `iconReaction` nudges a static glyph about — grows it, tilts it.
/// This plays an actual animation between two shapes, which is a
/// different thing: a morph has a state at each end, so what it means
/// depends entirely on what moves it.
class _MorphIcon extends StatefulWidget {
  const _MorphIcon({
    required this.icon,
    required this.trigger,
    required this.selected,
    required this.size,
    required this.color,
    required this.duration,
    required this.curve,
    super.key,
  });

  final AnimatedIconData icon;
  final BottomNavIconTrigger trigger;
  final bool selected;
  final double size;
  final Color color;
  final Duration duration;
  final Curve curve;

  @override
  State<_MorphIcon> createState() => _MorphIconState();
}

class _MorphIconState extends State<_MorphIcon>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(
    vsync: this,
    duration: widget.duration,
    // Selection already HAS a value when the bar first builds; starting
    // at zero morphs every selected destination on mount for no reason.
    value: widget.trigger == BottomNavIconTrigger.selection && widget.selected
        ? 1
        : 0,
  );

  bool _pressed = false;
  bool _hovered = false;
  bool _focused = false;

  void setPressed(bool v) {
    _pressed = v;
    _drive();
  }

  void setPointer({bool? hovered, bool? focused}) {
    if (hovered != null) _hovered = hovered;
    if (focused != null) _focused = focused;
    _drive();
  }

  void _drive() {
    if (!mounted) return;
    final forward = switch (widget.trigger) {
      BottomNavIconTrigger.selection => widget.selected,
      BottomNavIconTrigger.press => _pressed,
      BottomNavIconTrigger.hover => _hovered || _focused,
    };
    if (forward) {
      _ctrl.forward();
    } else {
      _ctrl.reverse();
    }
  }

  @override
  void didUpdateWidget(_MorphIcon oldWidget) {
    super.didUpdateWidget(oldWidget);
    _ctrl.duration = widget.duration;
    if (widget.selected != oldWidget.selected ||
        widget.trigger != oldWidget.trigger) {
      _drive();
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedIcon(
    icon: widget.icon,
    progress: CurvedAnimation(parent: _ctrl, curve: widget.curve),
    size: widget.size,
    color: widget.color,
  );
}

/// An animated ASSET, driven by the same trigger the Material morphs
/// use.
///
/// A designed animation rather than two shapes interpolated: the file
/// decides what it does, and the trigger only decides when.
class _MorphLottie extends StatefulWidget {
  const _MorphLottie({
    required this.asset,
    required this.trigger,
    required this.selected,
    required this.size,
    required this.repeat,
    required this.reduceMotion,
    super.key,
  });

  final String asset;
  final BottomNavIconTrigger trigger;
  final bool selected;
  final double size;
  final bool repeat;
  final bool reduceMotion;

  @override
  State<_MorphLottie> createState() => _MorphLottieState();
}

class _MorphLottieState extends State<_MorphLottie>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(vsync: this);

  bool _pressed = false;
  bool _hovered = false;
  bool _focused = false;

  void setPressed(bool v) {
    _pressed = v;
    _drive();
  }

  void setPointer({bool? hovered, bool? focused}) {
    if (hovered != null) _hovered = hovered;
    if (focused != null) _focused = focused;
    _drive();
  }

  bool get _forward => switch (widget.trigger) {
    BottomNavIconTrigger.selection => widget.selected,
    BottomNavIconTrigger.press => _pressed,
    BottomNavIconTrigger.hover => _hovered || _focused,
  };

  void _drive() {
    if (!mounted || _ctrl.duration == null) return;
    // Reduce motion holds the END frame rather than playing to it: the
    // asset is the content, and a still frame of it still says which
    // state the destination is in.
    if (widget.reduceMotion) {
      _ctrl.value = _forward ? 1 : 0;
      return;
    }
    if (_forward) {
      if (widget.repeat) {
        _ctrl.repeat();
      } else {
        _ctrl.forward();
      }
    } else {
      _ctrl.stop();
      _ctrl.reverse();
    }
  }

  @override
  void didUpdateWidget(_MorphLottie oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selected != oldWidget.selected ||
        widget.trigger != oldWidget.trigger ||
        widget.reduceMotion != oldWidget.reduceMotion) {
      _drive();
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => SizedBox(
    width: widget.size,
    height: widget.size,
    child: Lottie.asset(
      widget.asset,
      controller: _ctrl,
      fit: BoxFit.contain,
      onLoaded: (composition) {
        // The FILE owns its own duration; the controller only plays it.
        _ctrl.duration = composition.duration;
        _drive();
      },
    ),
  );
}

/// Scales a destination down ONLY when it is too TALL, and passes the
/// incoming width through untouched.
///
/// `FittedBox(scaleDown)` was the first answer and it was the wrong
/// one: it unbounds BOTH axes, so a long label never reaches the width
/// that would make it ellipsise or marquee — it lays out at its full
/// natural length, makes the destination enormously wide, and the fit
/// then shrinks the whole thing, glyph included, to something unreadable.
///
/// Width is the label's problem and it already knows how to solve it.
/// Height is the one that has no other answer, because it comes from
/// the caller's own numbers: a bigger glyph, a larger type scale, a
/// compact bar.
class _FitHeight extends SingleChildRenderObjectWidget {
  const _FitHeight({required Widget super.child});

  @override
  RenderObject createRenderObject(BuildContext context) => _RenderFitHeight();
}

class _RenderFitHeight extends RenderProxyBox {
  double _scale = 1;

  @override
  void performLayout() {
    final child = this.child;
    if (child == null) {
      size = constraints.smallest;
      return;
    }

    // The WIDTH is handed straight down, so the label sees a real limit
    // and can ellipsise or scroll against it. Only the height is let
    // loose, because that is the axis being measured.
    child.layout(
      BoxConstraints(
        minWidth: constraints.minWidth,
        maxWidth: constraints.maxWidth,
      ),
      parentUsesSize: true,
    );

    _scale = constraints.hasBoundedHeight && child.size.height > 0
        ? math.min(1, constraints.maxHeight / child.size.height)
        : 1;
    size = constraints.constrain(
      Size(child.size.width, child.size.height * _scale),
    );
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    final child = this.child;
    if (child == null) return;
    if (_scale == 1) {
      context.paintChild(child, offset);
      return;
    }
    // Scaled about the top-centre: a destination that has to shrink
    // should lose room at the bottom, where the label is, rather than
    // drift up away from the glyph above it.
    final dx = (size.width - child.size.width * _scale) / 2;
    context.pushTransform(
      needsCompositing,
      offset,
      Matrix4.identity()
        ..translateByDouble(dx, 0, 0, 1)
        ..scaleByDouble(_scale, _scale, 1, 1),
      (inner, innerOffset) => inner.paintChild(child, innerOffset),
    );
  }

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) {
    // The whole destination takes the tap either way — the ink's own
    // rect is what shapes the highlight, not this.
    return false;
  }
}

/// Lets a child paint outside its own box.
///
/// `ClipRect` was here to keep a translated bar tidy, and it cropped
/// the shadow off with it.
class _Unclipped extends StatelessWidget {
  const _Unclipped({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) => child;
}

/// Paints the bar's elevation along the NOTCHED path, behind the clip.
class _NotchedShadowPainter extends CustomPainter {
  const _NotchedShadowPainter({
    required this.shape,
    required this.notchRadius,
    required this.notchMargin,
    required this.borderRadius,
    required this.fabSize,
    required this.shadows,
  });

  final NotchedShape shape;
  final double notchRadius;
  final double notchMargin;
  final BorderRadius borderRadius;
  final double fabSize;
  final List<BoxShadow> shadows;

  @override
  void paint(Canvas canvas, Size size) {
    if (shadows.isEmpty) return;
    final path = _NotchClipper.pathFor(
      shape: shape,
      size: size,
      notchRadius: notchRadius,
      notchMargin: notchMargin,
      borderRadius: borderRadius,
      fabSize: fabSize,
    );
    for (final shadow in shadows) {
      canvas.drawPath(
        path.shift(shadow.offset),
        shadow.toPaint()..style = PaintingStyle.fill,
      );
    }
  }

  @override
  bool shouldRepaint(_NotchedShadowPainter old) =>
      shape != old.shape ||
      notchRadius != old.notchRadius ||
      notchMargin != old.notchMargin ||
      borderRadius != old.borderRadius ||
      fabSize != old.fabSize ||
      shadows != old.shadows;
}

/// Strokes the bar's own outline, notch and all.
class _NotchedOutlinePainter extends CustomPainter {
  const _NotchedOutlinePainter({
    required this.shape,
    required this.notchRadius,
    required this.notchMargin,
    required this.borderRadius,
    required this.fabSize,
    required this.width,
    this.color,
    this.gradient,
  });

  final NotchedShape shape;
  final double notchRadius;
  final double notchMargin;
  final BorderRadius borderRadius;
  final double fabSize;
  final double width;
  final Color? color;
  final Gradient? gradient;

  @override
  void paint(Canvas canvas, Size size) {
    if (width <= 0) return;
    final path = _NotchClipper.pathFor(
      shape: shape,
      size: size,
      notchRadius: notchRadius,
      notchMargin: notchMargin,
      borderRadius: borderRadius,
      fabSize: fabSize,
    );

    final paint = Paint()
      ..style = PaintingStyle.stroke
      // The clip cuts along the centre of the line, so half of any
      // stroke lands outside it and is thrown away. Doubling puts the
      // asked-for width back inside.
      ..strokeWidth = width * 2
      ..color = color ?? const Color(0xFF000000);

    if (gradient != null) {
      paint.shader = gradient!.createShader(Offset.zero & size);
    }
    canvas.save();
    canvas.clipPath(path);
    canvas.drawPath(path, paint);
    canvas.restore();
  }

  @override
  bool shouldRepaint(_NotchedOutlinePainter old) =>
      shape != old.shape ||
      notchRadius != old.notchRadius ||
      notchMargin != old.notchMargin ||
      borderRadius != old.borderRadius ||
      fabSize != old.fabSize ||
      width != old.width ||
      color != old.color ||
      gradient != old.gradient;
}

class _NotchClipper extends CustomClipper<Path> {
  const _NotchClipper({
    required this.shape,
    required this.notchRadius,
    required this.notchMargin,
    required this.borderRadius,
    required this.fabSize,
  });

  /// Circular by default, or whatever the button declares.
  final NotchedShape shape;

  final double notchRadius;
  final double notchMargin;
  final BorderRadius borderRadius;
  final double fabSize;

  /// The bar's corner, with a notch that MORPHS into its edge.
  ///
  /// It used to be a hand-rolled cubic into an arc and back out, which
  /// meets the top edge at an angle — the cut looked stamped out of the
  /// bar rather than shaped around the button. `CircularNotchedRectangle`
  /// is the same geometry Material's own `BottomAppBar` uses, and its
  /// s-curves leave the edge tangentially, so the bar swells up to the
  /// button and back down.
  ///
  /// It notches a plain rectangle, so the rounded corners come from
  /// INTERSECTING it with the rounded box. Two shapes, each doing the
  /// one thing it is good at.
  @override
  Path getClip(Size size) {
    final host = Offset.zero & size;
    // The BUTTON plus the gap on every side.
    final diameter = fabSize + notchMargin * 2;
    final guest = Rect.fromCenter(
      center: Offset(size.width / 2, 0),
      width: diameter,
      height: diameter,
    );

    final notched = shape.getOuterPath(host, guest);
    final rounded = Path()..addRRect(borderRadius.toRRect(host));

    return Path.combine(PathOperation.intersect, notched, rounded);
  }

  @override
  bool shouldReclip(_NotchClipper oldClipper) =>
      shape != oldClipper.shape ||
      notchRadius != oldClipper.notchRadius ||
      notchMargin != oldClipper.notchMargin ||
      borderRadius != oldClipper.borderRadius ||
      fabSize != oldClipper.fabSize;

  /// The same path the clipper cuts, so a border can be STROKED along
  /// it. A `BoxDecoration` border is a rounded rectangle and the clip
  /// then removes the stretch that crosses the notch — the outline
  /// stopped dead at one side of the cutout and picked up again at the
  /// other. Tracing needs the real path.
  static Path pathFor({
    required NotchedShape shape,
    required Size size,
    required double notchRadius,
    required double notchMargin,
    required BorderRadius borderRadius,
    required double fabSize,
  }) => _NotchClipper(
    shape: shape,
    notchRadius: notchRadius,
    notchMargin: notchMargin,
    borderRadius: borderRadius,
    fabSize: fabSize,
  ).getClip(size);
}
