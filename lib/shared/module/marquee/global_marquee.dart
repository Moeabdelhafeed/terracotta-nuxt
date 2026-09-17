import 'dart:async';

import 'package:flutter/material.dart';

import 'marquee_models.dart';
import 'marquee_theme.dart';

export 'marquee_models.dart';
export 'marquee_theme.dart';

// ---------------------------------------------------------------------------
// GlobalMarquee
// ---------------------------------------------------------------------------

/// Auto-scrolling widget for overflowing text or any child content.
/// Only scrolls when the content actually overflows the available space.
class GlobalMarquee extends StatefulWidget {
  const GlobalMarquee({
    super.key,
    required this.child,
    this.style = const MarqueeStyle(),
    this.semanticLabel,
  });

  /// The content to scroll. Can be text, a Row, or any widget.
  final Widget child;

  /// Styling configuration.
  final MarqueeStyle style;

  /// Accessibility label.
  final String? semanticLabel;

  /// Scroll drives started since the app began, across every marquee.
  ///
  /// The re-entry cascade this module guards against is invisible from
  /// outside — it produces no frames, no exception and no log, so the
  /// only way to assert it is gone is to count the drives a single
  /// rebuild is allowed to start. See `_GlobalMarqueeState._drive`.
  @visibleForTesting
  static int debugDriveCount = 0;

  /// Convenience: marquee with text.
  factory GlobalMarquee.text(
    String text, {
    Key? key,
    TextStyle? textStyle,
    MarqueeStyle style = const MarqueeStyle(),
  }) {
    return GlobalMarquee(
      key: key,
      style: style,
      semanticLabel: text,
      child: Text(text, style: textStyle, maxLines: 1, softWrap: false),
    );
  }

  @override
  State<GlobalMarquee> createState() => _GlobalMarqueeState();
}

class _GlobalMarqueeState extends State<GlobalMarquee> {
  late ScrollController _scrollController;

  /// Materialized once in didChangeDependencies — caller > theme >
  /// defaults > tokens. The animation loop reads this, never the raw bag.
  late ResolvedMarqueeStyle _st;

  /// Scrolling text is exactly what `disableAnimations` is meant to
  /// stop: it moves forever and cannot be opted out of by looking away.
  /// When set, the content is laid out statically and clipped.
  bool _reduceMotion = false;

  /// The FIRST copy of the content, so it can be measured on its own.
  ///
  /// See [_contentExtent]: once this is looping there are two copies on
  /// screen, and asking the scroll view whether it overflows then is
  /// asking whether two copies are wider than one viewport. They always
  /// are. That is the whole bug — the answer could go from no to yes
  /// and never back, so a label that stopped overflowing kept
  /// scrolling for the life of the screen.
  final _firstCopy = GlobalKey();

  bool _overflows = false;
  bool _paused = false;
  bool _hovered = false;
  bool _touching = false;
  Timer? _initialPauseTimer;
  Timer? _endPauseTimer;

  // For bounce mode: track direction
  bool _forward = true;

  /// Generation token for the in-flight scroll drive.
  ///
  /// Beginning a scroll activity DISPOSES the one before it, and
  /// disposing a `DrivenScrollActivity` COMPLETES its `done` future. So
  /// a second `_animate` while one is already running does not replace
  /// it — it wakes it. The superseded `.then` runs a microtask later,
  /// jumps, and starts another drive, which completes the one that just
  /// started, whose `.then` runs a microtask later… Each turn schedules
  /// exactly one more, the queue never drains, and the isolate never
  /// gets back to the event loop: no frames, no timers, no exception.
  /// A silent hard freeze needing a restart.
  ///
  /// Every callback checks it is still the current generation first, so
  /// a superseded drive does nothing at all.
  int _drive = 0;

  /// True while [_drive] is the live generation for this callback.
  bool _current(int drive) => mounted && !_paused && drive == _drive;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkOverflow());
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _st = widget.style.resolve(context);
    final reduce = MediaQuery.disableAnimationsOf(context);
    if (reduce != _reduceMotion) {
      _reduceMotion = reduce;
      if (_reduceMotion) {
        _stopScrolling();
      } else {
        WidgetsBinding.instance.addPostFrameCallback((_) => _checkOverflow());
      }
    }
  }

  @override
  void didUpdateWidget(GlobalMarquee oldWidget) {
    super.didUpdateWidget(oldWidget);
    _st = widget.style.resolve(context);
    // Old RAW bag against new RAW bag. This compared the old bag's
    // NULLABLE fields against the newly RESOLVED ones, so a marquee left
    // on its defaults saw `null != 40.0` and restarted itself on every
    // rebuild of any ancestor — which is what fed the re-entry cascade
    // that [_drive] now guards.
    final before = oldWidget.style;
    final after = widget.style;
    if (before.speed != after.speed ||
        before.direction != after.direction ||
        before.mode != after.mode ||
        before.gap != after.gap) {
      _stopScrolling();
      WidgetsBinding.instance.addPostFrameCallback((_) => _checkOverflow());
      return;
    }

    // THE CONTENT CAN CHANGE WITHOUT THE STYLE CHANGING.
    //
    // A language switch swaps «تصفح الفئات» for "Browse categories" in
    // the same chip, and the two do not overflow it the same way — so
    // the Arabic label kept scrolling a line that now fits, and the
    // English one sat still while running off the end. The verdict was
    // reached once, on the first frame, and never revisited.
    //
    // Re-measured on every update, but [_remeasure] only ACTS when the
    // verdict flips. Restarting on every rebuild is what fed the
    // re-entry cascade the comparison above exists to avoid.
    WidgetsBinding.instance.addPostFrameCallback((_) => _remeasure());
  }

  /// Ask again whether the content overflows, and act only on a change.
  void _remeasure() {
    final m = _measure();
    if (m == null) return;

    final overflowsNow = m.content > m.viewport + 0.5;
    if (overflowsNow == _overflows) return;

    if (!overflowsNow) {
      // It FITS now. Stop, and put it back to the start — a label left
      // wherever the scroll had got to reads as clipped text.
      _stopScrolling();
      if (_scrollController.offset != 0) _scrollController.jumpTo(0);
      setState(() => _overflows = false);
      return;
    }

    setState(() => _overflows = true);
    if (!_paused) _startScrolling();
  }

  @override
  void dispose() {
    _initialPauseTimer?.cancel();
    _endPauseTimer?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  bool get _isHorizontal => _st.isHorizontal;
  bool get _isReversed => _st.isReversed;

  // ─── Overflow detection ────────────────────────────────────

  /// How long the content is, ON ITS OWN, and how much room it has.
  ///
  /// Measured off the first copy rather than off `maxScrollExtent`,
  /// which counts whatever the marquee happens to be drawing — and
  /// when it is looping that is two copies and a gap, so the extent is
  /// positive whatever the words say.
  ({double content, double viewport})? _measure() {
    if (!mounted || !_scrollController.hasClients) return null;

    final position = _scrollController.position;
    // `hasClients` is NOT enough: a position is attached before it has
    // been laid out, and `viewportDimension` is a null-check on a field
    // only `applyViewportDimension` sets.
    if (!position.hasViewportDimension) return null;
    if (position.viewportDimension <= 0) return null;

    final box = _firstCopy.currentContext?.findRenderObject();
    if (box is! RenderBox || !box.hasSize) return null;

    return (
      content: _isHorizontal ? box.size.width : box.size.height,
      viewport: position.viewportDimension,
    );
  }

  void _checkOverflow() {
    if (!mounted || !_scrollController.hasClients) return;

    // A viewport with no extent belongs to something mid-collapse — a
    // banner being hidden, a sheet closing. Its scroll metrics flap
    // between "overflows" and "does not" on every frame, and each flip
    // is a `setState` that schedules the frame that flips it back.
    final position = _scrollController.position;
    // `hasClients` is NOT enough. A position is attached before it has
    // been laid out, and `viewportDimension` is a null-check on a field
    // that is only set by `applyViewportDimension` — so a marquee whose
    // first post-frame lands before its viewport exists threw
    // "Null check operator used on a null value" out of a scheduler
    // callback. Found by the breadcrumbs module, whose labels sit in an
    // intrinsic-width row.
    if (!position.hasViewportDimension) return;
    if (position.viewportDimension <= 0) return;

    final m = _measure();
    if (m == null) return;
    // A HAIR of tolerance: a text that fills its box exactly is not
    // concealing anything, and sub-pixel layout noise either side of
    // equality would flip this on alternate frames.
    final didOverflow = m.content > m.viewport + 0.5;

    if (didOverflow != _overflows) {
      setState(() => _overflows = didOverflow);
    }

    if (_overflows && !_paused) {
      _startScrolling();
    }
  }

  // ─── Scroll control ────────────────────────────────────────

  void _startScrolling() {
    if (!_overflows || !mounted || _reduceMotion) return;

    final st = _st;
    if (st.initialPause > Duration.zero && _scrollController.offset == 0) {
      final drive = _drive;
      _initialPauseTimer?.cancel();
      _initialPauseTimer = Timer(st.initialPause, () {
        if (_current(drive)) _animate();
      });
    } else {
      _animate();
    }
  }

  void _animate() {
    if (!mounted || !_scrollController.hasClients || _paused) return;
    if (_reduceMotion) return;

    final st = _st;
    final maxScroll = _scrollController.position.maxScrollExtent;
    if (maxScroll <= 0) return;

    // Anything still holding an older token is now superseded and will
    // do nothing when it wakes.
    final drive = ++_drive;
    GlobalMarquee.debugDriveCount += 1;

    if (st.mode == MarqueeMode.bounce) {
      _animateBounce(maxScroll, drive);
    } else {
      _animateLoop(maxScroll, drive);
    }
  }

  /// Distance that makes the reset invisible: one copy plus the gap.
  ///
  /// The looped content is `[copy0][gap][copy1]`, so at this offset copy1
  /// sits exactly where copy0 started and `jumpTo(0)` cannot be seen.
  /// Derived from the scroll metrics rather than measuring the child:
  ///   content = 2·copy + gap,  copy = (content − gap) / 2,
  ///   cycle   = copy + gap    = (max + viewport + gap) / 2.
  double _loopCycle(double maxScroll, double viewport, double gap) {
    final cycle = (maxScroll + viewport + gap) / 2;
    // Guard the degenerate case where a single copy already fits: then
    // the cycle would exceed the scrollable range and animateTo would
    // clamp, stalling the loop.
    return cycle.clamp(1.0, maxScroll);
  }

  void _animateLoop(double maxScroll, int drive) {
    final st = _st;
    final pos = _scrollController.position;
    // Scrolling to maxScrollExtent — the END of the second copy — and
    // then resetting to 0 is what produced the visible jump: those two
    // positions do not show the same thing.
    final cycle = _loopCycle(maxScroll, pos.viewportDimension, st.gap);
    final distance = cycle - pos.pixels;
    if (distance <= 0) {
      // Deferred to the next frame, NOT re-entered here. `_animate`
      // calling itself synchronously is an unbounded recursion whenever
      // the reset does not move `pixels` below `cycle` — a viewport
      // that is mid-resize can produce exactly that, and it locks the
      // UI thread rather than dropping a frame.
      _scrollController.jumpTo(0);
      _scheduleNextCycle(drive);
      return;
    }

    final duration = Duration(
      milliseconds: (distance / st.speed * 1000).round(),
    );

    if (duration <= Duration.zero) {
      // A zero-length `animateTo` completes on the next microtask, so
      // re-entering from its callback spins the microtask queue and
      // starves the frame loop — the same lock-up as a synchronous
      // recursion, with a different stack.
      _scheduleNextCycle(drive);
      return;
    }

    _scrollController
        .animateTo(cycle, duration: duration, curve: Curves.linear)
        .then((_) {
          if (!_current(drive)) return;
          _scrollController.jumpTo(0);
          _animate();
        });
  }

  /// Re-enters the cycle on the NEXT frame.
  ///
  /// Every path that would otherwise call `_animate` again without any
  /// time passing goes through here: a marquee whose numbers degenerate
  /// should drop to doing nothing, not take the UI thread with it.
  void _scheduleNextCycle(int drive) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_current(drive)) _animate();
    });
  }

  void _animateBounce(double maxScroll, int drive) {
    final st = _st;
    final target = _forward ? maxScroll : 0.0;
    final distance = (_scrollController.offset - target).abs();
    if (distance <= 0) {
      _forward = !_forward;
      _scheduleNextCycle(drive);
      return;
    }

    final duration = Duration(
      milliseconds: (distance / st.speed * 1000).round(),
    );

    _scrollController
        .animateTo(target, duration: duration, curve: Curves.linear)
        .then((_) {
          if (!_current(drive)) return;
          _forward = !_forward;

          if (st.endPause > Duration.zero) {
            _endPauseTimer?.cancel();
            _endPauseTimer = Timer(st.endPause, () {
              if (_current(drive)) _animate();
            });
          } else {
            _animate();
          }
        });
  }

  void _stopScrolling() {
    // Retires the live generation: a drive completed by the `jumpTo`
    // below must NOT re-enter the cycle from its own callback.
    _drive += 1;
    _initialPauseTimer?.cancel();
    _endPauseTimer?.cancel();
    if (_scrollController.hasClients) {
      _scrollController.jumpTo(_scrollController.offset);
    }
  }

  void _pause() {
    _paused = true;
    _stopScrolling();
  }

  void _resume() {
    _paused = false;
    if (_overflows) _animate();
  }

  // ─── Hover / Touch ─────────────────────────────────────────

  void _onHoverEnter() {
    if (!_st.pauseOnHover) return;
    _hovered = true;
    _pause();
  }

  void _onHoverExit() {
    if (!_st.pauseOnHover) return;
    _hovered = false;
    if (!_touching) _resume();
  }

  void _onTouchStart() {
    if (!_st.pauseOnTouch) return;
    _touching = true;
    _pause();
  }

  void _onTouchEnd() {
    if (!_st.pauseOnTouch) return;
    _touching = false;
    if (!_hovered) _resume();
  }

  // ─── Build ─────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final st = _st;
    final isH = _isHorizontal;
    final axis = isH ? Axis.horizontal : Axis.vertical;

    Widget scrollView = SingleChildScrollView(
      controller: _scrollController,
      scrollDirection: axis,
      physics: const NeverScrollableScrollPhysics(),
      child: st.mode == MarqueeMode.loop && _overflows
          ? _buildLoopContent(isH, st)
          // KEYED in both states, because [_measure] has to find the
          // content whether or not it is currently being duplicated.
          : KeyedSubtree(key: _firstCopy, child: widget.child),
    );

    // Reverse direction via Transform flip (doesn't affect text direction)
    if (_isReversed) {
      scrollView = Transform.flip(
        flipX: st.direction == MarqueeDirection.ltr,
        flipY: st.direction == MarqueeDirection.down,
        child: scrollView,
      );
    }

    // Fade edges
    if (st.fadeEdges && _overflows) {
      scrollView = _buildFadeEdges(context, scrollView, isH, st);
    }

    // Hover + touch handlers — installed ONLY when a pause is actually
    // wanted. They used to be unconditional, with the callbacks
    // early-returning on the flags, which meant a marquee always put a
    // pan recognizer into the gesture arena: it stole drags from
    // swipeable parents and would swallow taps if embedded in a button.
    if (st.pauseOnHover) {
      scrollView = MouseRegion(
        onEnter: (_) => _onHoverEnter(),
        onExit: (_) => _onHoverExit(),
        child: scrollView,
      );
    }
    if (st.pauseOnTouch) {
      scrollView = GestureDetector(
        onPanDown: (_) => _onTouchStart(),
        onPanEnd: (_) => _onTouchEnd(),
        onPanCancel: _onTouchEnd,
        child: scrollView,
      );
    }

    // Semantics
    if (widget.semanticLabel != null) {
      return Semantics(
        label: widget.semanticLabel,
        excludeSemantics: true,
        child: scrollView,
      );
    }

    return scrollView;
  }

  /// For loop mode: duplicate the child with a gap so the scroll loops seamlessly.
  Widget _buildLoopContent(bool isH, ResolvedMarqueeStyle st) {
    if (isH) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          KeyedSubtree(key: _firstCopy, child: widget.child),
          SizedBox(width: st.gap),
          KeyedSubtree(
            key: const ValueKey('marquee-copy-1'),
            child: widget.child,
          ),
        ],
      );
    }
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        KeyedSubtree(key: _firstCopy, child: widget.child),
        SizedBox(height: st.gap),
        KeyedSubtree(
          key: const ValueKey('marquee-copy-1'),
          child: widget.child,
        ),
      ],
    );
  }

  /// Fades only the edges that are actually CONCEALING content.
  ///
  /// Fading both ends unconditionally is the giveaway of a cheap
  /// marquee: at rest against the start there is nothing hidden on the
  /// leading side, so a ramp there just looks like the text is damaged.
  /// The ramps follow the live scroll offset and ease in/out, so an edge
  /// appears as content slides under it rather than popping.
  ///
  /// `dstOut` punches the ramp OUT of the child, leaving real
  /// transparency — so it works over any background. (The old
  /// `fadeColor` knob was a no-op: with dstOut only the source ALPHA is
  /// read, never its colour.)
  Widget _buildFadeEdges(
    BuildContext context,
    Widget child,
    bool isH,
    ResolvedMarqueeStyle st,
  ) {
    return AnimatedBuilder(
      animation: _scrollController,
      builder: (context, inner) {
        var lead = 0.0;
        var trail = 0.0;
        if (st.mode == MarqueeMode.loop) {
          // A loop has no ends: content is entering on one side and
          // leaving on the other at every instant, so both ramps stay
          // fully on. Deriving them from the offset made the fades blink
          // out for a frame whenever the cycle reset to 0 — the offset
          // said "nothing is hidden on the left" while the trailing copy
          // was in fact still covering it.
          lead = 1;
          trail = 1;
        } else if (_scrollController.hasClients) {
          final pos = _scrollController.position;
          final ramp = st.fadeWidth;
          if (ramp > 0) {
            // Bounce DOES have ends: ramp up over one fade-width of
            // travel, so an edge grows in as content slides under it and
            // stays absent while that side conceals nothing.
            lead = (pos.pixels / ramp).clamp(0.0, 1.0);
            trail = ((pos.maxScrollExtent - pos.pixels) / ramp).clamp(0.0, 1.0);
          }
        }
        if (lead <= 0 && trail <= 0) return inner!;

        return ShaderMask(
          shaderCallback: (bounds) {
            final extent = isH ? bounds.width : bounds.height;
            if (extent <= 0) return _clearShader(bounds, isH);
            final w = (st.fadeWidth / extent).clamp(0.0, 0.5);
            return LinearGradient(
              begin: isH ? Alignment.centerLeft : Alignment.topCenter,
              end: isH ? Alignment.centerRight : Alignment.bottomCenter,
              colors: [
                Colors.black.withValues(alpha: lead),
                Colors.transparent,
                Colors.transparent,
                Colors.black.withValues(alpha: trail),
              ],
              stops: [0.0, w, 1.0 - w, 1.0],
            ).createShader(bounds);
          },
          blendMode: BlendMode.dstOut,
          child: inner,
        );
      },
      child: child,
    );
  }

  Shader _clearShader(Rect bounds, bool isH) => const LinearGradient(
    colors: [Colors.transparent, Colors.transparent],
  ).createShader(bounds);
}
