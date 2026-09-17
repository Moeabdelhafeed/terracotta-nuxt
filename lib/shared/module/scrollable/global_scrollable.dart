import 'package:flutter/gestures.dart' show GestureBinding, PointerScrollEvent;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show ScrollCacheExtent;
import 'package:flutter/scheduler.dart' show Ticker;

import 'global_edge_fade.dart';
import 'global_scroll_overlays.dart';
import 'scrollable_models.dart';
import 'scrollable_style.dart';
import 'theme/scrollable_theme.dart';

export 'global_edge_fade.dart';
export 'global_scroll_in.dart';
export 'global_scroll_overlays.dart';
export 'scrollable_models.dart';
export 'scrollable_style.dart';
export 'theme/scrollable_theme.dart';

/// Advertised by a [GlobalScrollable] whose `passThroughAtEdge` is
/// on. Descendant scrollables read it to switch to clamping physics,
/// so their overscroll emits an [OverscrollNotification] the ancestor
/// can consume instead of absorbing the drag into a rubber band.
class GlobalScrollableScope extends InheritedWidget {
  const GlobalScrollableScope({
    super.key,
    required this.passThroughActive,
    required super.child,
  });

  final bool passThroughActive;

  static GlobalScrollableScope? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<GlobalScrollableScope>();

  @override
  bool updateShouldNotify(GlobalScrollableScope old) =>
      passThroughActive != old.passThroughActive;
}

/// One scroll shell for any page or sub-region.
///
/// Composes the edge fade, the scroll-to-top button, the progress
/// strip, position restoration, the physics preset, smooth wheel
/// scrolling, and nested-scroll handoff — the things every page needs
/// and no two pages should implement differently.
///
/// Visual config is the themeable bag [ScrollableStyle]:
/// `caller > GlobalScrollableTheme.style > ScrollableStyle.defaults`.
///
/// Two shapes:
///
/// * default — a non-scrollable [child], wrapped in a
///   [SingleChildScrollView].
/// * [GlobalScrollable.custom] — [slivers], wrapped in a
///   [CustomScrollView].
class GlobalScrollable extends StatefulWidget {
  const GlobalScrollable({
    super.key,
    required this.child,
    this.controller,
    this.style,
    this.scrollDirection = Axis.vertical,
    this.reverse = false,
    this.shrinkWrap = false,
    this.primary,
    this.physics,
    this.padding,
    this.restorationId,
    this.passThroughAtEdge = false,
    this.scrollToTopBuilder,
    this.clipBehavior = Clip.hardEdge,
  }) : _slivers = null,
       _isCustom = false;

  /// Slivers instead of a box child.
  const GlobalScrollable.custom({
    super.key,
    required List<Widget> slivers,
    this.controller,
    this.style,
    this.scrollDirection = Axis.vertical,
    this.reverse = false,
    this.shrinkWrap = false,
    this.primary,
    this.physics,
    this.padding,
    this.restorationId,
    this.passThroughAtEdge = false,
    this.scrollToTopBuilder,
    this.clipBehavior = Clip.hardEdge,
  }) : child = const SizedBox.shrink(),
       _slivers = slivers,
       _isCustom = true;

  final Widget child;
  final List<Widget>? _slivers;
  final bool _isCustom;

  final ScrollController? controller;

  /// The themeable bag. Everything visual lives here — including the
  /// wheel-smoothing knobs, which were three flat widget parameters
  /// nobody could set app-wide.
  final ScrollableStyle? style;

  final Axis scrollDirection;
  final bool reverse;
  final bool shrinkWrap;
  final bool? primary;

  /// Caller's physics override. Null falls to `style.mode`.
  final ScrollPhysics? physics;

  final EdgeInsetsGeometry? padding;

  /// Wired into a `PageStorageKey`, so the offset survives navigation.
  final String? restorationId;

  /// Listen for `OverscrollNotification` from descendant scrollables
  /// and apply the delta to our own position — nested scroll handoff.
  final bool passThroughAtEdge;

  /// Replaces the default scroll-to-top button.
  final Widget Function(BuildContext, VoidCallback)? scrollToTopBuilder;

  /// How the viewport clips its content. `Clip.none` is for a strip
  /// whose children paint OUTSIDE their own box — an elevated chip's
  /// shadow comes off flat against the edge otherwise.
  final Clip clipBehavior;

  @override
  State<GlobalScrollable> createState() => GlobalScrollableState();
}

class GlobalScrollableState extends State<GlobalScrollable>
    with SingleTickerProviderStateMixin {
  late ScrollController _scrollCtrl;
  bool _ownsScroll = false;
  late ResolvedScrollableStyle _style;

  /// Moving target for wheel-driven smooth scroll. Successive wheel
  /// events add to it; the ticker lerps the position toward it.
  double? _wheelTarget;
  Ticker? _wheelTicker;

  @override
  void initState() {
    super.initState();
    _scrollCtrl = widget.controller ?? ScrollController();
    _ownsScroll = widget.controller == null;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // The palette and `MediaQuery.disableAnimationsOf` are INHERITED
    // reads. `initState` cannot see either.
    _style = widget.style.resolve(context);
  }

  @override
  void didUpdateWidget(GlobalScrollable oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.style != oldWidget.style) _style = widget.style.resolve(context);
    if (widget.controller != oldWidget.controller) {
      _stopWheel();
      if (_ownsScroll) _scrollCtrl.dispose();
      _scrollCtrl = widget.controller ?? ScrollController();
      _ownsScroll = widget.controller == null;
    }
  }

  @override
  void dispose() {
    // STOP first. `Ticker.dispose` throws on a ticker that is still
    // active, and a page torn down mid-wheel-glide is exactly that —
    // it took a fast scroll and an immediate back gesture to hit.
    _stopWheel();
    _wheelTicker?.dispose();
    if (_ownsScroll) _scrollCtrl.dispose();
    super.dispose();
  }

  void _stopWheel() {
    _wheelTarget = null;
    if (_wheelTicker?.isActive ?? false) _wheelTicker!.stop();
  }

  /// Wheel / trackpad signals.
  ///
  /// Registers with the global `PointerSignalResolver` — only the
  /// FIRST registered callback fires, so by living INSIDE the
  /// scrollable's content (deeper in hit-test order than the
  /// scrollable's own wheel handler) this wins the resolver and the
  /// framework's discrete-jump handler is bypassed.
  ///
  /// Each event ADDS to `_wheelTarget` and restarts the lerp; new
  /// events update the target mid-flight without restarting the loop.
  void _onPointerSignal(PointerScrollEvent event) {
    if (!_scrollCtrl.hasClients) return;
    GestureBinding.instance.pointerSignalResolver.register(event, (e) {
      final scrollEvent = e as PointerScrollEvent;
      if (!_scrollCtrl.hasClients) return;
      final pos = _scrollCtrl.position;
      if (pos.maxScrollExtent <= 0) return;
      final delta = widget.scrollDirection == Axis.vertical
          ? scrollEvent.scrollDelta.dy
          : scrollEvent.scrollDelta.dx;
      if (delta == 0) return;
      final base = _wheelTarget ?? pos.pixels;
      final target = (base + delta * _style.wheelMultiplier).clamp(
        0.0,
        pos.maxScrollExtent,
      );
      if (target == base) return;
      _wheelTarget = target;
      _ensureWheelTickerRunning();
    });
  }

  void _ensureWheelTickerRunning() {
    // `createTicker`, not `Ticker(...)`: a raw ticker ignores
    // `TickerMode`, so a glide kept running under a pushed route.
    _wheelTicker ??= createTicker(_wheelTick);
    if (!_wheelTicker!.isActive) _wheelTicker!.start();
  }

  void _wheelTick(Duration elapsed) {
    if (!_scrollCtrl.hasClients || _wheelTarget == null) {
      _wheelTicker?.stop();
      return;
    }
    final pos = _scrollCtrl.position;
    final current = pos.pixels;
    final diff = _wheelTarget! - current;
    if (diff.abs() < 0.5) {
      pos.jumpTo(_wheelTarget!);
      _wheelTarget = null;
      _wheelTicker?.stop();
      return;
    }
    final next = (current + diff * _style.wheelSmoothness).clamp(
      0.0,
      pos.maxScrollExtent,
    );
    pos.jumpTo(next);
  }

  /// Animate to an offset. Honours the bag's duration, which reduced
  /// motion resolves to zero — so this becomes a jump rather than a
  /// fast slide.
  Future<void> scrollToOffset(
    double offset, {
    Duration? duration,
    Curve curve = ScrollableDefaults.scrollToTopCurve,
  }) async {
    if (!_scrollCtrl.hasClients) return;
    final clamped = offset.clamp(0.0, _scrollCtrl.position.maxScrollExtent);
    final d = duration ?? _style.scrollToOffsetDuration;
    if (d == Duration.zero) {
      _scrollCtrl.jumpTo(clamped);
      return;
    }
    await _scrollCtrl.animateTo(clamped, duration: d, curve: curve);
  }

  Key? get _storageKey => widget.restorationId == null
      ? null
      : PageStorageKey<String>(widget.restorationId!);

  /// Effective physics, in order:
  ///
  /// 1. the caller's `physics`;
  /// 2. `style.mode`, when it is not `platform`;
  /// 3. an inherited [GlobalScrollableScope] with pass-through on —
  ///    clamping, so overscroll emits the notification the ancestor
  ///    catches (bouncing would absorb the drag into a rubber band);
  /// 4. the platform default.
  ScrollPhysics? _resolveEffectivePhysics(BuildContext context) {
    if (widget.physics != null) return widget.physics;
    if (_style.mode != ScrollableMode.platform) {
      return resolvePhysics(_style.mode);
    }
    final scope = GlobalScrollableScope.maybeOf(context);
    if (scope?.passThroughActive == true) {
      return const ClampingScrollPhysics(
        parent: AlwaysScrollableScrollPhysics(),
      );
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final style = _style;
    final physics = _resolveEffectivePhysics(context);
    final padding = widget.padding ?? EdgeInsets.zero;

    Widget scrollable;
    if (widget._isCustom) {
      scrollable = CustomScrollView(
        key: _storageKey,
        controller: _scrollCtrl,
        scrollDirection: widget.scrollDirection,
        reverse: widget.reverse,
        physics: physics,
        primary: widget.primary,
        shrinkWrap: widget.shrinkWrap,
        clipBehavior: widget.clipBehavior,
        keyboardDismissBehavior: style.keyboardDismissBehavior,
        scrollCacheExtent: style.cacheExtent == null
            ? null
            : ScrollCacheExtent.pixels(style.cacheExtent!),
        slivers: [
          if (padding != EdgeInsets.zero)
            SliverPadding(
              padding: padding,
              sliver: SliverMainAxisGroup(slivers: widget._slivers!),
            )
          else
            ...widget._slivers!,
        ],
      );
      // Slivers do not host arbitrary box widgets, so there is nowhere
      // inside the viewport to put a deeper `Listener`. Smooth wheel
      // is skipped for `.custom` — those fall back to the framework's
      // discrete wheel handling.
    } else {
      // `SingleChildScrollView` builds its child WHOLE — there is no
      // virtualisation, so there is no cache to extend and no
      // parameter to pass it to. Setting `cacheExtent` here did
      // nothing, silently, which is worse than not offering it: a
      // caller tuning a janky list would have moved the number,
      // measured no change, and concluded the number does not matter.
      //
      // Only the CALLER is caught. A theme may set it app-wide for the
      // sliver scrollables that can use it, and must not start
      // asserting on every box one in the app.
      assert(
        widget.style?.cacheExtent == null,
        'cacheExtent has no effect on GlobalScrollable(child:) — a '
        'SingleChildScrollView builds its child whole and caches '
        'nothing. Use GlobalScrollable.custom(slivers:) for content '
        'big enough to want a cache.',
      );
      // The `Listener` wraps the CHILD, deeper than `Scrollable`'s own
      // wheel listener. Touch drags go through `onPointerMove`, a
      // separate path, so mobile is untouched.
      var innerChild = widget.child;
      if (style.smoothWheelScroll) {
        innerChild = Listener(
          behavior: HitTestBehavior.translucent,
          onPointerSignal: (e) {
            if (e is PointerScrollEvent) _onPointerSignal(e);
          },
          child: innerChild,
        );
      }
      scrollable = SingleChildScrollView(
        key: _storageKey,
        controller: _scrollCtrl,
        scrollDirection: widget.scrollDirection,
        reverse: widget.reverse,
        physics: physics,
        primary: widget.primary,
        padding: padding,
        clipBehavior: widget.clipBehavior,
        keyboardDismissBehavior: style.keyboardDismissBehavior,
        child: innerChild,
      );
    }

    var content = scrollable;

    // The fade wraps the scrollable so the bands hug the viewport.
    if (!style.edgeFade.isOff) {
      content = GlobalEdgeFade(
        controller: _scrollCtrl,
        style: widget.style?.edgeFade,
        axis: widget.scrollDirection,
        child: content,
      );
    }

    // The chrome sits ABOVE the fade, or the button at the bottom
    // edge would be faded out by it.
    if (style.showScrollToTop || style.showScrollProgress) {
      content = GlobalScrollOverlays(
        controller: _scrollCtrl,
        axis: widget.scrollDirection,
        style: widget.style,
        scrollToTopBuilder: widget.scrollToTopBuilder,
        child: content,
      );
    }

    // Catches `OverscrollNotification` from descendants and applies
    // the delta to our own position. `depth > 0` filters out our own.
    if (widget.passThroughAtEdge) {
      content = NotificationListener<ScrollNotification>(
        onNotification: _handleDescendantOverscroll,
        child: GlobalScrollableScope(passThroughActive: true, child: content),
      );
    }

    return content;
  }

  bool _handleDescendantOverscroll(ScrollNotification n) {
    if (n.depth == 0) return false;
    if (n is! OverscrollNotification) return false;
    if (!_scrollCtrl.hasClients) return false;
    // Same axis only. A horizontal carousel inside a vertical page
    // must not bleed into the page's scroll.
    if (n.metrics.axis != _scrollCtrl.position.axis) return false;
    final pos = _scrollCtrl.position;

    // A DRAG overscroll carries `dragDetails`. Apply the delta so the
    // page tracks the finger.
    if (n.dragDetails != null) {
      final next = (pos.pixels + n.overscroll).clamp(0.0, pos.maxScrollExtent);
      if (next != pos.pixels) {
        pos.jumpTo(next);
        return true;
      }
      return false;
    }

    // A FLING overscroll has no drag and a velocity: the inner
    // finished its ballistic run at its boundary, so hand the
    // remaining velocity to our position and keep coasting.
    // `goBallistic` lives on the concrete type `Scrollable` uses.
    if (n.velocity != 0 &&
        pos.pixels >= 0 &&
        pos.pixels <= pos.maxScrollExtent &&
        pos is ScrollPositionWithSingleContext) {
      pos.goBallistic(n.velocity);
      return true;
    }
    return false;
  }
}
