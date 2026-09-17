import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart' show Ticker, TickerProvider;
import 'package:visibility_detector/visibility_detector.dart';

import 'scroll_in_style.dart';
import 'scrollable_models.dart';
import 'theme/scrollable_theme.dart';

export 'scroll_in_style.dart';

/// Edge-zone auto-scroll for drag-and-reorder. Used by `GlobalGrid`'s
/// reflow path and `GlobalList`'s swap path.
///
/// While a drag is live, scrolls the surrounding [Scrollable] when the
/// pointer comes within [edgeZone] of the viewport's leading or
/// trailing edge; the speed ramps from zero at that boundary to
/// [maxSpeed] at the edge itself.
///
/// Owners drive it: [start] on drag begin, [pointerGlobal] on each
/// move, [stop] on drag end.
class DragAutoScroller {
  DragAutoScroller({double? edgeZone, double? maxSpeed})
    : edgeZone = edgeZone ?? ScrollInDefaults.dragEdgeZone,
      maxSpeed = maxSpeed ?? ScrollInDefaults.dragMaxSpeed;

  /// Distance from the edge at which auto-scroll engages.
  final double edgeZone;

  /// Pixels moved per tick (roughly one frame) at the very edge.
  final double maxSpeed;

  Ticker? _ticker;
  Offset? pointerGlobal;
  BuildContext? _ctx;
  ScrollController? _controller;

  /// Runs after each scrolling tick. Owners re-run their hit-tests
  /// from here, so the dragged item interacts with the cells now under
  /// the cursor rather than the ones that scrolled away.
  VoidCallback? onTick;

  bool get isRunning => _ticker?.isActive == true;

  /// Start with a context that finds the surrounding `Scrollable` —
  /// for an owner BELOW the scrollable in the tree.
  void start(TickerProvider vsync, BuildContext context) {
    if (_ticker != null) return;
    _ctx = context;
    _controller = null;
    _ticker = vsync.createTicker(_onTickRaw)..start();
  }

  /// Start with an explicit controller — for an owner ABOVE the
  /// scrollable, holding the controller it passed down.
  void startWithController(TickerProvider vsync, ScrollController controller) {
    if (_ticker != null) return;
    _ctx = null;
    _controller = controller;
    _ticker = vsync.createTicker(_onTickRaw)..start();
  }

  void stop() {
    _ticker?.stop();
    _ticker?.dispose();
    _ticker = null;
    _ctx = null;
    _controller = null;
    pointerGlobal = null;
    onTick = null;
  }

  void _onTickRaw(Duration _) {
    final pointer = pointerGlobal;
    if (pointer == null) {
      onTick?.call();
      return;
    }
    final position = _resolvePosition();
    final viewportBox = _resolveViewportBox();
    if (position == null || viewportBox == null || !viewportBox.attached) {
      onTick?.call();
      return;
    }
    final size = viewportBox.size;
    final local = viewportBox.globalToLocal(pointer);
    final isVertical = position.axis == Axis.vertical;
    final pos = isVertical ? local.dy : local.dx;
    final extent = isVertical ? size.height : size.width;
    final delta = speedAt(pos: pos, extent: extent);
    if (delta != 0) {
      final next = (position.pixels + delta).clamp(
        position.minScrollExtent,
        position.maxScrollExtent,
      );
      if (next != position.pixels) position.jumpTo(next);
    }
    onTick?.call();
  }

  /// Pixels to move this tick for a pointer at [pos] in a viewport
  /// [extent] long. Negative scrolls back, positive scrolls on.
  ///
  /// Pure, so the ramp can be checked without a drag, a ticker or a
  /// viewport — none of which a test can conjure cheaply.
  @visibleForTesting
  double speedAt({required double pos, required double extent}) {
    if (pos < edgeZone) {
      final t = ((edgeZone - pos) / edgeZone).clamp(0.0, 1.0);
      return -maxSpeed * t;
    }
    if (pos > extent - edgeZone) {
      final t = ((pos - (extent - edgeZone)) / edgeZone).clamp(0.0, 1.0);
      return maxSpeed * t;
    }
    return 0;
  }

  ScrollPosition? _resolvePosition() {
    final ctx = _ctx;
    if (ctx != null) return Scrollable.maybeOf(ctx)?.position;
    final ctrl = _controller;
    if (ctrl != null && ctrl.hasClients) return ctrl.position;
    return null;
  }

  RenderBox? _resolveViewportBox() {
    final ctx = _ctx;
    if (ctx != null) {
      final state = Scrollable.maybeOf(ctx);
      return state?.context.findRenderObject() as RenderBox?;
    }
    final ctrl = _controller;
    if (ctrl != null && ctrl.hasClients) {
      return ctrl.position.context.notificationContext?.findRenderObject()
          as RenderBox?;
    }
    return null;
  }
}

/// How reorder gestures fire callbacks.
///
/// * [liveInsert] — fires `onReorder(from, to)` each time the pointer
///   enters a new cell. The caller does `removeAt(from) + insert(to)`;
///   the items between shift live.
/// * [liveSwap] — same firing, but the caller SWAPS the two slots and
///   nothing else moves. Reads best in the grid, where
///   `AnimatedPositioned` interpolates the swap.
/// * [dropSwap] — fires once, on drop. Each tile holds its place until
///   the finger lifts.
enum GridReorderMode { liveInsert, liveSwap, dropSwap }

/// Plays a tile's entrance when it first crosses
/// [ScrollInStyle.threshold] of visibility.
///
/// **This is what solves the cacheExtent problem.** An `initState`-
/// driven animation plays OFFSCREEN: virtualisation mounts tiles a few
/// hundred pixels before they enter the viewport, so by the time the
/// reader scrolls to a row it has already finished arriving. Firing on
/// visibility instead means the animation happens where it can be
/// seen.
///
/// Used by `GlobalList` and `GlobalGrid`. Owners pass a shared [fired]
/// set (the once-per-index dedupe) and a [claimStaggerDelay] that
/// hands back the next slot in the cascade.
class GlobalScrollInAnimator extends StatefulWidget {
  const GlobalScrollInAnimator({
    super.key,
    required this.index,
    required this.fired,
    required this.claimStaggerDelay,
    required this.child,
    this.style,
    this.animationOverride,
    this.onComplete,
  });

  final int index;

  /// The owner's dedupe set. When `style.once` and this already
  /// contains [index], the animator starts finished instead of
  /// replaying. Owners must pass the SAME set across rebuilds.
  final Set<int> fired;

  /// Takes [index] and returns how long to wait before starting.
  /// `Duration.zero` fires immediately.
  final Duration Function(int index) claimStaggerDelay;

  /// Merged over `GlobalScrollableTheme.scrollInStyle` and then the
  /// floor. `style.animation == null` means no entrance at all.
  final ScrollInStyle? style;

  /// Chooses the transition at FIRE time when it returns non-null —
  /// which is how direction-aware mode flips `slideFromBottom` to
  /// `slideFromTop` for a reader scrolling up.
  final ListItemAnimation? Function()? animationOverride;

  /// Fires once when the entrance completes. Skipped on the
  /// already-fired path.
  final void Function(int index)? onComplete;

  final Widget child;

  @override
  State<GlobalScrollInAnimator> createState() => _GlobalScrollInAnimatorState();
}

class _GlobalScrollInAnimatorState extends State<GlobalScrollInAnimator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late ResolvedScrollInStyle _style;
  CurvedAnimation? _curved;
  bool _started = false;
  ListItemAnimation? _resolvedAnimation;

  /// The pending cascade slot, held so it can be cancelled.
  ///
  /// It was a bare `Future.delayed`, which cannot be — so a list torn
  /// down mid-cascade left one pending callback per queued row, and
  /// every widget test around one failed on "a Timer is still pending
  /// even after the widget tree was disposed".
  Timer? _stagger;

  @override
  void initState() {
    super.initState();
    // Duration is set in `didChangeDependencies` — reduce-motion is an
    // inherited read and `initState` cannot see it.
    _ctrl = AnimationController(vsync: this);
    _ctrl.addStatusListener(_onStatus);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _style = widget.style.resolve(context);
    _applyStyle(first: _curved == null);
  }

  @override
  void didUpdateWidget(GlobalScrollInAnimator old) {
    super.didUpdateWidget(old);
    if (widget.style != old.style) {
      _style = widget.style.resolve(context);
      _applyStyle(first: false);
    }
  }

  void _applyStyle({required bool first}) {
    _ctrl.duration = _style.duration;
    _curved?.dispose();
    _curved = CurvedAnimation(parent: _ctrl, curve: _style.effectiveCurve);
    if (!first) return;

    // The reader asked for no motion: the tile is PLACED. That covers
    // `continuous` too, where binding the transition to the scroll
    // would otherwise animate every tile on every frame of every
    // scroll — the loudest possible reading of "reduce motion".
    if (_style.isOff) {
      _ctrl.value = 1;
      _started = true;
      return;
    }
    if (_style.mode == ScrollInMode.oneShot &&
        _style.once &&
        widget.fired.contains(widget.index)) {
      _ctrl.value = 1;
      _started = true;
    } else if (_style.mode == ScrollInMode.continuous) {
      // Fully hidden; the first visibility report drives it to the
      // current fraction.
      _ctrl.value = 0;
    }
  }

  @override
  void dispose() {
    _stagger?.cancel();
    _ctrl.removeStatusListener(_onStatus);
    _curved?.dispose();
    _ctrl.dispose();
    super.dispose();
  }

  void _onStatus(AnimationStatus status) {
    if (status == AnimationStatus.completed && widget.onComplete != null) {
      widget.onComplete!(widget.index);
    }
  }

  void _onVisibility(VisibilityInfo info) {
    if (!mounted || _style.isOff) return;
    // `VisibilityDetector` asserts on negative dimensions inside
    // `visibleFraction`. Both `info.size` AND `info.visibleBounds.size`
    // can carry them during detach and slide transitions, so both are
    // guarded before the assert can fire.
    final size = info.size;
    if (size.width <= 0 || size.height <= 0) return;
    final vb = info.visibleBounds;
    if (vb.width < 0 || vb.height < 0 || vb.isEmpty) return;
    final double fraction;
    try {
      fraction = info.visibleFraction;
    } catch (_) {
      return;
    }

    if (_style.mode == ScrollInMode.continuous) {
      // Bound to the visible fraction directly: no fire, no stagger,
      // no dedupe. Scroll drives playback and reverses it.
      _resolvedAnimation ??=
          widget.animationOverride?.call() ?? _style.animation;
      final v = fraction.clamp(0.0, 1.0);
      if ((v - _ctrl.value).abs() > 0.001) _ctrl.value = v;
      return;
    }

    if (!_started && fraction >= _style.threshold) {
      _started = true;
      widget.fired.add(widget.index);
      // Resolved at FIRE time, so direction-aware mode can pick from
      // the scroll direction at the moment the tile became visible.
      _resolvedAnimation = widget.animationOverride?.call() ?? _style.animation;
      final delay = widget.claimStaggerDelay(widget.index);
      _stagger?.cancel();
      if (delay == Duration.zero) {
        _ctrl.forward();
      } else {
        _stagger = Timer(delay, () {
          _stagger = null;
          if (mounted) _ctrl.forward();
        });
      }
    } else if (!_style.once && _started && fraction <= 0) {
      // Re-arming while a slot is still queued would fire the old one
      // into a controller that has just been reset.
      _stagger?.cancel();
      _stagger = null;
      _started = false;
      _ctrl.value = 0;
      _resolvedAnimation = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    // No entrance to play — do not put a `VisibilityDetector` in the
    // tree for it. Every one of those is a registration the detector
    // walks on each frame it schedules, and a list has hundreds.
    if (_style.isOff) return widget.child;

    return VisibilityDetector(
      key: widget.key ?? ValueKey<int>(widget.index),
      onVisibilityChanged: _onVisibility,
      child: _buildTransition(widget.child),
    );
  }

  Widget _buildTransition(Widget child) {
    // `slideFromStart` / `slideFromEnd` follow the reader; the
    // physical members pass straight through.
    final anim = (_resolvedAnimation ?? _style.animation)?.resolveDirection(
      Directionality.of(context),
    );
    final curved = _curved!;
    final offset = _style.slideOffset;
    return switch (anim) {
      null => child,
      ListItemAnimation.fadeSize => FadeTransition(
        opacity: curved,
        child: ScaleTransition(scale: curved, child: child),
      ),
      ListItemAnimation.slideFromLeft => _slide(
        curved,
        Offset(-offset, 0),
        child,
      ),
      ListItemAnimation.slideFromRight => _slide(
        curved,
        Offset(offset, 0),
        child,
      ),
      ListItemAnimation.slideFromBottom => _slide(
        curved,
        Offset(0, offset),
        child,
      ),
      ListItemAnimation.slideFromTop => _slide(
        curved,
        Offset(0, -offset),
        child,
      ),
      ListItemAnimation.scale => FadeTransition(
        opacity: curved,
        child: ScaleTransition(scale: curved, child: child),
      ),
      ListItemAnimation.fade => FadeTransition(opacity: curved, child: child),
      // Already mapped onto a physical side above; listed so the
      // switch stays exhaustive.
      ListItemAnimation.slideFromStart ||
      ListItemAnimation.slideFromEnd => child,
    };
  }

  Widget _slide(Animation<double> curved, Offset from, Widget child) =>
      FadeTransition(
        opacity: curved,
        child: SlideTransition(
          position: curved.drive(Tween(begin: from, end: Offset.zero)),
          child: child,
        ),
      );
}

/// The cascade's slot allocator. Owners hold one in their State and
/// dispatch to it from [GlobalScrollInAnimator.claimStaggerDelay].
///
/// Both modes cap how far ahead they queue and reset on an idle gap,
/// so a fast scroll never leaves the animation trailing the viewport.
class ScrollInStaggerCursor {
  ScrollInStaggerCursor({int Function()? clock}) : _clock = clock ?? _wallClock;

  /// The clock, injectable.
  ///
  /// It was a bare `DateTime.now()` inside the algorithm, which made
  /// every rule below — the idle reset, the queue cap, the row anchor
  /// — untestable: they are all decisions about elapsed milliseconds,
  /// and a test cannot make real time pass.
  final int Function() _clock;

  static int _wallClock() => DateTime.now().millisecondsSinceEpoch;

  // byOrder — a single monotonic cursor.
  int _lastFireMs = 0;

  // byRow — an anchor captured at the start of a batch.
  int _anchorMs = 0;
  int _anchorRow = -1;

  /// The delay before the tile at [index] should start.
  Duration claim(
    Duration stagger,
    int index, {
    ScrollInStaggerMode mode = ScrollInStaggerMode.byOrder,
    int cols = 1,
    Duration idleReset = ScrollInDefaults.staggerIdleReset,
    Duration maxQueue = ScrollInDefaults.staggerMaxQueue,
  }) {
    if (stagger == Duration.zero) return Duration.zero;
    final stepMs = stagger.inMilliseconds;
    if (stepMs <= 0) return Duration.zero;
    final nowMs = _clock();
    return switch (mode) {
      ScrollInStaggerMode.byOrder => _claimByOrder(
        nowMs,
        stepMs,
        idleReset.inMilliseconds,
        maxQueue.inMilliseconds,
      ),
      ScrollInStaggerMode.byRow => _claimByRow(
        nowMs,
        stepMs,
        index,
        cols.clamp(1, 1024),
        idleReset.inMilliseconds,
        maxQueue.inMilliseconds,
      ),
    };
  }

  Duration _claimByOrder(int nowMs, int stepMs, int idleMs, int queueMs) {
    if (_lastFireMs < nowMs - idleMs) {
      _lastFireMs = nowMs;
      return Duration.zero;
    }
    final next = _lastFireMs + stepMs;
    if (next - nowMs > queueMs) {
      _lastFireMs = nowMs;
      return Duration.zero;
    }
    _lastFireMs = next;
    return Duration(milliseconds: next - nowMs);
  }

  Duration _claimByRow(
    int nowMs,
    int stepMs,
    int index,
    int cols,
    int idleMs,
    int queueMs,
  ) {
    final row = index ~/ cols;
    // A new batch — an idle gap, or the first claim ever.
    if (_anchorRow < 0 || _anchorMs < nowMs - idleMs) {
      _anchorMs = nowMs;
      _anchorRow = row;
      return Duration.zero;
    }
    final rowOffset = (row - _anchorRow) * stepMs;
    var targetMs = _anchorMs + rowOffset;
    // A same-row tile arriving a little after its row's anchor fires
    // WITH the row, not after it.
    if (targetMs < nowMs) targetMs = nowMs;
    if (targetMs - nowMs > queueMs) {
      // Queue saturated — re-anchor and fire now.
      _anchorMs = nowMs;
      _anchorRow = row;
      return Duration.zero;
    }
    return Duration(milliseconds: targetMs - nowMs);
  }
}
