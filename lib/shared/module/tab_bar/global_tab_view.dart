import 'package:flutter/material.dart';

import '../../../core/animations/animation_presets.dart';

/// Transition style for tab page changes.
enum TabTransition {
  /// Standard horizontal swipe (default TabBarView behavior).
  swipe,

  /// Crossfade between pages.
  fade,

  /// Scale up from center.
  scale,

  /// Fade + scale combined.
  fadeScale,

  /// Pages travel sideways under the finger, `TabBarView`-style, but
  /// built by this widget — so it keeps what `swipe` cannot give:
  /// stepping over disabled pages, and pages that survive being left.
  slide,

  /// No animation — instant switch.
  none,
}

/// Fraction of the view a drag must cross to commit to the next page.
const _kDragThreshold = 0.3;

/// Fling speed that commits regardless of distance travelled.
const _kVelocityThreshold = 300.0;

const _kSnapDuration = AppDurations.quick;

/// A wrapper around tab content that solves common TabBarView pain points:
///
/// - **State preservation** — keeps page state alive when switching tabs
/// - **Lazy loading** — only builds tabs when first visited
/// - **Custom transitions** — slide, fade, scale, fadeScale, all
///   drag-driven
/// - **Skips disabled pages** — a swipe steps over them (`disabledTabs`)
/// - **Per-tab swipe control** — disable swipe on specific tabs
/// - **Preload adjacent pages** — build next/prev tabs ahead of time
/// - **Dynamic height** — adapts to different content sizes per tab
class GlobalTabView extends StatefulWidget {
  const GlobalTabView({
    super.key,
    required this.children,
    this.controller,
    this.keepAlive = false,
    this.lazy = false,
    this.transition = TabTransition.swipe,
    this.swipeable = true,
    this.swipeablePerTab,
    this.preloadAdjacentPages = false,
    this.dynamicHeight = false,
    this.disabledTabs = const {},
    this.animationDuration = AppDurations.normal,
    this.animationCurve = Curves.easeInOut,
  });

  final List<Widget> children;
  final TabController? controller;
  final bool keepAlive;
  final bool lazy;
  final TabTransition transition;
  final bool swipeable;
  final Map<int, bool>? swipeablePerTab;
  final bool preloadAdjacentPages;
  final bool dynamicHeight;

  /// Indices a SWIPE steps over, as if they were not in the strip.
  ///
  /// Pass the same tabs the bar marks `disabled`. Without this the view
  /// has no idea a tab is dead — it is the bar that knows — so a swipe
  /// would settle on the disabled page and `GlobalTabBar`'s controller
  /// guard would have to drag the user back off it, which means a beat
  /// of content they were never meant to see.
  ///
  /// Only the custom transitions can honour this. `TabTransition.swipe`
  /// hands the paging to Material's own `TabBarView`, which owns its
  /// scrolling and offers no way in.
  final Set<int> disabledTabs;

  final Duration animationDuration;
  final Curve animationCurve;

  @override
  State<GlobalTabView> createState() => _GlobalTabViewState();
}

class _GlobalTabViewState extends State<GlobalTabView>
    with TickerProviderStateMixin {
  late Set<int> _visitedTabs;
  TabController? _cachedCtrl;

  // Drag tracking for custom transitions
  double _dragProgress =
      0; // -1..1, negative = dragging left (next), positive = dragging right (prev)
  bool _isDragging = false;
  late AnimationController _snapCtrl;
  double _snapFrom = 0;
  double _snapTo = 0;

  /// Crossfade for a change the FINGER did not make — a tab tap, a
  /// keyboard move, `animateTo`. A drag needs none: it already moves the
  /// pages itself, in proportion to the gesture.
  late AnimationController _tapCtrl;

  /// Page being crossfaded away from, for the life of [_tapCtrl].
  int? _tapFrom;

  /// The index the view is showing, or moving toward.
  ///
  /// ANY animated index change notifies twice — once when it starts and
  /// once when it lands — and `TabController.previousIndex` still reads
  /// the same on both. Comparing against the controller alone therefore
  /// could not tell the two apart, and the landing notification looked
  /// exactly like a fresh change, so the view ran the whole transition
  /// again after it had already arrived. Tapping a tab past a disabled
  /// one showed it as a double switch; a skipping swipe showed it as a
  /// second crossfade after landing.
  int? _shownIndex;

  TabController get _ctrl =>
      _cachedCtrl ?? widget.controller ?? DefaultTabController.of(context);

  @override
  void initState() {
    super.initState();
    _visitedTabs = {0};
    _snapCtrl = AnimationController(vsync: this, duration: _kSnapDuration)
      ..addListener(() {
        final newProgress =
            _snapFrom +
            (_snapTo - _snapFrom) * Curves.easeOut.transform(_snapCtrl.value);
        final steps = _stepsToDestination();
        setState(() => _dragProgress = newProgress);
        _ctrl.offset = -newProgress / steps;
      })
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          if (_snapTo.abs() >= 1.0) {
            // Change index directly without animation — offset already at ±1
            final currentIndex = _ctrl.index;
            final targetIndex =
                _neighbour(currentIndex, _snapTo < 0 ? 1 : -1) ?? currentIndex;
            final clampedTarget = targetIndex.clamp(
              0,
              widget.children.length - 1,
            );
            // ORDER MATTERS. Writing the index notifies `_onTabChanged`,
            // and `_isDragging` is deliberately still true at that
            // moment: the drag has already shown this change under the
            // finger, and the listener uses that flag to refuse it a
            // second, animated crossfade on top. Clearing `_isDragging`
            // first would bring the flicker back.
            if (clampedTarget == currentIndex + (_snapTo < 0 ? 1 : -1)) {
              // Adjacent: the indicator already travelled with the
              // finger and sits at ±1, so setting the index is a no-op
              // for it.
              _ctrl.index = clampedTarget;
            } else {
              // A skip: the indicator has been scrubbed as far as the
              // disabled tab, which is as far as `offset` reaches.
              // Animating from there carries it the rest of the way in
              // the same motion.
              _ctrl.animateTo(clampedTarget);
            }
          }
          // `offset` asserts while an index change is in flight, and the
          // skip branch above deliberately leaves one running.
          if (!_ctrl.indexIsChanging) _ctrl.offset = 0;
          _dragProgress = 0;
          _isDragging = false;
        }
      });

    _tapCtrl =
        AnimationController(vsync: this, duration: widget.animationDuration)
          ..addListener(() {
            if (mounted) setState(() {});
          })
          ..addStatusListener((status) {
            if (status == AnimationStatus.completed && mounted) {
              setState(() => _tapFrom = null);
            }
          });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final newCtrl = widget.controller ?? DefaultTabController.of(context);
    if (newCtrl != _cachedCtrl) {
      _cachedCtrl?.removeListener(_onTabChanged);
      _cachedCtrl = newCtrl;
      _cachedCtrl!.addListener(_onTabChanged);
      _shownIndex ??= _cachedCtrl!.index;
      _markVisited(_cachedCtrl!.index);
    }
  }

  @override
  void didUpdateWidget(GlobalTabView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.controller != oldWidget.controller &&
        widget.controller != null) {
      _cachedCtrl?.removeListener(_onTabChanged);
      _cachedCtrl = widget.controller;
      _cachedCtrl!.addListener(_onTabChanged);
    }
  }

  @override
  void dispose() {
    _snapCtrl.dispose();
    _tapCtrl.dispose();
    _cachedCtrl?.removeListener(_onTabChanged);
    super.dispose();
  }

  void _onTabChanged() {
    _markVisited(_ctrl.index);
    if (widget.transition == TabTransition.swipe) return;

    final index = _ctrl.index;
    // The landing half of a change already in progress. Nothing new.
    if (index == _shownIndex) {
      if (mounted) setState(() {});
      return;
    }
    // A blocked tab is never a destination, so the view must not follow
    // the controller through one. `TabBar` owns the InkWell and calls
    // `animateTo` before the bar can refuse, so the controller really
    // does visit the index — tapping a locked tab moved it there and
    // straight back, and the view obligingly animated BOTH hops. Sitting
    // still leaves `_shownIndex` alone, so the return trip is the
    // no-change case above and nothing moves at all.
    if (widget.disabledTabs.contains(index)) {
      if (mounted) setState(() {});
      return;
    }
    final from = _shownIndex ?? _ctrl.previousIndex;
    _shownIndex = index;

    // A drag has already shown this change under the user's finger, so
    // it gets no crossfade of its own. See the snap controller's status
    // listener for why this is still true when the index is committed.
    if (_isDragging || _snapCtrl.isAnimating) {
      _tapFrom = null;
      if (mounted) setState(() {});
      return;
    }

    _tapFrom = from;
    // Reduced motion still SWAPS, it just does not travel.
    _tapCtrl.duration = _reduceMotion
        ? Duration.zero
        : widget.animationDuration;
    _tapCtrl.forward(from: 0);
    if (mounted) setState(() {});
  }

  void _markVisited(int index) {
    if (_recordVisit(index) && mounted) setState(() {});
  }

  /// Records the visit WITHOUT asking for a rebuild.
  ///
  /// The custom-transition build path has to mark the drag's target page
  /// visited before it can render it — and calling `setState` from
  /// inside `build` is "setState() called during build", which the
  /// `LayoutBuilder` around that path turned from latent into a crash on
  /// the first swipe of every non-`swipe` transition. Nothing is lost by
  /// skipping the notification: the build doing the marking is the build
  /// that renders the page.
  bool _recordVisit(int index) {
    var changed = _visitedTabs.add(index);
    if (widget.preloadAdjacentPages) {
      if (index > 0) changed |= _visitedTabs.add(index - 1);
      if (index < widget.children.length - 1) {
        changed |= _visitedTabs.add(index + 1);
      }
    }
    return changed;
  }

  bool _isSwipeableForTab(int index) {
    if (widget.swipeablePerTab != null &&
        widget.swipeablePerTab!.containsKey(index)) {
      return widget.swipeablePerTab![index]!;
    }
    return widget.swipeable;
  }

  // ─── Drag handlers ────────────────────────────────────────

  void _onDragStart(DragStartDetails _) {
    _snapCtrl.stop();
    _isDragging = true;
  }

  /// +1 in LTR, -1 in RTL.
  ///
  /// `_dragProgress` is in PAGE space, not screen space: positive always
  /// means "toward the previous tab". In Arabic the previous tab is to
  /// the right, so a raw pixel delta walks the pages backwards — the
  /// swipe used to fight the tab bar's own indicator, which mirrors
  /// correctly on its own.
  double get _dirSign =>
      Directionality.of(context) == TextDirection.rtl ? -1.0 : 1.0;

  bool get _reduceMotion => MediaQuery.disableAnimationsOf(context);

  void _onDragUpdate(DragUpdateDetails details, double width) {
    if (!_isDragging) return;
    final delta = (details.primaryDelta ?? 0) * _dirSign;
    setState(() {
      _dragProgress += delta / width;
      final currentIndex = _ctrl.index;
      if (currentIndex <= 0 && _dragProgress > 0) _dragProgress = 0;
      if (currentIndex >= widget.children.length - 1 && _dragProgress < 0) {
        _dragProgress = 0;
      }
      _dragProgress = _dragProgress.clamp(-1.0, 1.0);
    });
    _driveIndicator();
  }

  /// Walks the tab bar's indicator with the finger.
  ///
  /// `TabController.offset` is clamped to ±1, so the indicator can never
  /// be aimed further than the ADJACENT tab — a framework limit, not a
  /// choice. When a swipe steps OVER a disabled tab, the destination is
  /// further than that, and the two obvious readings are both wrong:
  /// scrubbing at full rate parks the indicator on the dead tab as
  /// though it were about to be selected, and not scrubbing at all stops
  /// it following the finger.
  ///
  /// So it advances at a fraction of the rate — one tab's worth divided
  /// by the number of tabs being crossed — which keeps it moving with
  /// the gesture while stopping it well short of the tab it is not going
  /// to land on. The commit then animates from wherever it stopped, so
  /// the path stays one continuous motion.
  void _driveIndicator() {
    _ctrl.offset = -_dragProgress / _stepsToDestination();
  }

  /// How many tab positions the current drag would cross, ≥ 1.
  int _stepsToDestination() {
    if (_dragProgress == 0) return 1;
    final current = _ctrl.index;
    final target = _neighbour(current, _dragProgress < 0 ? 1 : -1);
    if (target == null) return 1;
    return (target - current).abs().clamp(1, widget.children.length);
  }

  void _onDragEnd(DragEndDetails details) {
    if (!_isDragging) return;
    final velocity = (details.primaryVelocity ?? 0) * _dirSign;
    final shouldComplete =
        _dragProgress.abs() > _kDragThreshold ||
        velocity.abs() > _kVelocityThreshold;
    final direction = _dragProgress < 0 ? -1.0 : 1.0; // -1 = next, 1 = prev

    _snapFrom = _dragProgress;
    if (shouldComplete && _canNavigate(direction)) {
      _snapTo = direction < 0 ? -1.0 : 1.0;
    } else {
      _snapTo = 0;
    }
    _snapCtrl.forward(from: 0);
  }

  bool _canNavigate(double direction) =>
      _neighbour(_ctrl.index, direction < 0 ? 1 : -1) != null;

  /// The next page in [step]'s direction that a swipe may actually land
  /// on, walking OVER anything in [GlobalTabView.disabledTabs].
  ///
  /// Skipping here rather than correcting afterwards is the whole point:
  /// the disabled page is never built, so it never appears for a beat
  /// before being taken away again.
  int? _neighbour(int from, int step) {
    for (var i = from + step; i >= 0 && i < widget.children.length; i += step) {
      if (!widget.disabledTabs.contains(i)) return i;
    }
    return null;
  }

  // ─── Build ────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    if (widget.transition == TabTransition.swipe) return _buildSwipeView();
    return _buildCustomTransitionView();
  }

  Widget _buildSwipeView() {
    final ctrl = _ctrl;
    final children = _wrapChildren();
    return AnimatedBuilder(
      animation: ctrl,
      builder: (context, _) {
        final canSwipe = _isSwipeableForTab(ctrl.index);
        return TabBarView(
          controller: ctrl,
          physics: canSwipe ? null : const NeverScrollableScrollPhysics(),
          children: children,
        );
      },
    );
  }

  /// Custom transitions measure the drag against the VIEW's own width,
  /// not the window's.
  ///
  /// `MediaQuery.sizeOf(context).width` was the screen — so inside a
  /// `GlobalPane`, a split layout or any padded shell the 30% commit
  /// threshold was measured against a box the view does not occupy, and
  /// a full-width swipe registered as a fraction of one.
  Widget _buildCustomTransitionView() => LayoutBuilder(
    builder: (context, constraints) =>
        _buildCustomTransitionContent(constraints.maxWidth),
  );

  /// Which pages paint this frame: how strongly ([t]) and how far they
  /// have travelled sideways ([dx]).
  ///
  /// One function for both kinds of change, which is what removed the
  /// double transition. A drag already moves the pages under the
  /// finger; when it settled, the index change used to kick off a
  /// SECOND, animated crossfade on top of the one that had just
  /// finished — the flicker of the page you had just left.
  Map<int, ({double t, double dx})> _pageStates(int currentIndex, double w) {
    final dragging = _isDragging || _snapCtrl.isAnimating;
    if (dragging && _dragProgress != 0) {
      final target = _neighbour(currentIndex, _dragProgress < 0 ? 1 : -1);
      if (target != null) {
        final p = _dragProgress.abs().clamp(0.0, 1.0);
        // Travel follows the FINGER, so it mirrors in Arabic — while
        // `_dragProgress` stays in page space, which does not.
        final away = (_dragProgress < 0 ? -1.0 : 1.0) * _dirSign;
        return {
          currentIndex: (t: 1 - p, dx: _slides ? away * p * w : 0.0),
          target: (t: p, dx: _slides ? away * (p - 1) * w : 0.0),
        };
      }
    }
    final from = _tapFrom;
    if (from != null && from != currentIndex) {
      final t = widget.animationCurve.transform(_tapCtrl.value);
      // A tap travels the same way a swipe toward that tab would.
      final away = (from < currentIndex ? -1.0 : 1.0) * _dirSign;
      return {
        currentIndex: (t: t, dx: _slides ? away * (t - 1) * w : 0.0),
        from: (t: 1 - t, dx: _slides ? away * t * w : 0.0),
      };
    }
    return {
      currentIndex: (t: 1.0, dx: 0.0),
    };
  }

  bool get _slides => widget.transition == TabTransition.slide;

  Widget _buildCustomTransitionContent(double width) {
    final ctrl = _ctrl;
    final currentIndex = ctrl.index.clamp(0, widget.children.length - 1);
    final canSwipe = _isSwipeableForTab(currentIndex);

    final states = _pageStates(currentIndex, width);
    // Recorded WITHOUT setState — this runs inside build (and, since the
    // LayoutBuilder, inside layout), where asking for a rebuild is an
    // error. It must happen BEFORE _wrapChildren: under `lazy` an
    // unvisited page is an empty box, so recording afterwards left the
    // page being dragged toward blank for that frame.
    for (final index in states.keys) {
      _recordVisit(index);
    }
    final children = _wrapChildren();

    // EVERY page keeps its own slot, in index order, for the whole life
    // of the view. Two things follow, and both were bugs:
    //
    // * The slot never changes shape, so beginning a swipe cannot
    //   remount the page under it. (It used to return an
    //   AnimatedSwitcher at rest and a bare Stack while dragging, and
    //   swapping between the two disposed every descendant State — a
    //   scrolled list jumped to the top the moment you swiped away.)
    // * A page you leave is only `Offstage`, not gone. Its element and
    //   therefore its scroll position survive, so coming back puts you
    //   where you were. `keepAlive` cannot do this here: it relies on
    //   `AutomaticKeepAliveClientMixin`, which needs a lazy list above
    //   it, and there is none in a Stack.
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onHorizontalDragStart: canSwipe ? _onDragStart : null,
      onHorizontalDragUpdate: canSwipe ? (d) => _onDragUpdate(d, width) : null,
      onHorizontalDragEnd: canSwipe ? _onDragEnd : null,
      child: Stack(
        fit: StackFit.expand,
        children: [
          for (var i = 0; i < widget.children.length; i++)
            Offstage(
              key: ValueKey<int>(i),
              offstage: !states.containsKey(i),
              // A hidden page must not keep animating, or every tab in
              // the view runs its tickers forever.
              child: TickerMode(
                enabled: states.containsKey(i),
                child: _applyTransition(
                  SizedBox.expand(child: children[i]),
                  states[i]?.t ?? 0,
                  states[i]?.dx ?? 0,
                  outgoing: i != currentIndex,
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// [t] is how strongly the page shows (1 = fully), [dx] how far it has
  /// travelled sideways in pixels.
  ///
  /// The shape it returns must not depend on anything that changes at
  /// RUNTIME — only on `widget.transition`, which does not. A wrapper
  /// that comes and goes remounts the page under it, which is what used
  /// to throw away a scrolled list mid-swipe.
  Widget _applyTransition(
    Widget child,
    double t,
    double dx, {
    required bool outgoing,
  }) {
    final inner = switch (widget.transition) {
      // Sliding pages sit side by side rather than on top of each other,
      // so fading either one only makes the pair look washed out.
      TabTransition.slide || TabTransition.swipe => child,
      TabTransition.fade => Opacity(opacity: t.clamp(0.0, 1.0), child: child),
      TabTransition.scale || TabTransition.fadeScale => Opacity(
        opacity: t.clamp(0.0, 1.0),
        child: Transform.scale(
          scale: outgoing ? (0.95 + 0.05 * t) : (0.9 + 0.1 * t),
          child: child,
        ),
      ),
      TabTransition.none => Opacity(opacity: t > 0.5 ? 1.0 : 0.0, child: child),
    };
    return Transform.translate(offset: Offset(dx, 0), child: inner);
  }

  // ─── Wrap children ────────────────────────────────────────

  List<Widget> _wrapChildren() {
    return [
      for (var i = 0; i < widget.children.length; i++)
        _wrapChild(i, widget.children[i]),
    ];
  }

  Widget _wrapChild(int index, Widget child) {
    if (widget.lazy && !_visitedTabs.contains(index)) {
      child = const SizedBox.shrink();
    }
    if (widget.dynamicHeight) {
      child = AnimatedSize(
        duration: widget.animationDuration,
        curve: widget.animationCurve,
        child: SingleChildScrollView(child: child),
      );
    }
    if (widget.keepAlive) child = _KeepAliveWrapper(child: child);
    return child;
  }
}

// ═══════════════════════════════════════════════════════════════
// Keep alive wrapper
// ═══════════════════════════════════════════════════════════════

class _KeepAliveWrapper extends StatefulWidget {
  const _KeepAliveWrapper({required this.child});
  final Widget child;
  @override
  State<_KeepAliveWrapper> createState() => _KeepAliveWrapperState();
}

class _KeepAliveWrapperState extends State<_KeepAliveWrapper>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;
  @override
  Widget build(BuildContext context) {
    super.build(context);
    return widget.child;
  }
}
