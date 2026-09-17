import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart'
    show
        HapticFeedback,
        KeyDownEvent,
        KeyEvent,
        KeyRepeatEvent,
        LogicalKeyboardKey;
import 'package:visibility_detector/visibility_detector.dart';

import '../../../core/localization/strings/list_strings.dart';
import '../indicator/global_story_indicator.dart';
import 'page_chrome_insets.dart';
import 'page_indicator_overlay.dart';
import 'page_view_controller.dart';
import 'page_view_models.dart';
import 'theme/page_view_theme.dart';

export '../indicator/global_story_indicator.dart';
export '../indicator/indicator_models.dart';
export 'page_indicator_overlay.dart';
export 'page_view_controller.dart';
export 'page_view_models.dart';
export 'theme/page_view_theme.dart';

typedef GlobalPageItemBuilder<T> =
    Widget Function(BuildContext context, T item, int index);

/// Typed page view with built-in indicator overlay + optional loop.
///
/// Wraps Flutter's [PageView.builder] with:
/// * typed `items` list + indexed builder
/// * indicator overlay (dots / bar / numbered)
/// * `loop: true` for infinite wrap
/// * direction (horizontal / vertical)
class GlobalPageView<T> extends StatefulWidget {
  const GlobalPageView({
    super.key,
    required this.items,
    required this.itemBuilder,
    this.controller,
    this.pageViewController,
    this.autoPlay = false,
    this.pauseWhenOffscreen = true,
    this.onPageChanged,
    this.scrollDirection = Axis.horizontal,
    this.reverse = false,
    this.physics,
    this.allowImplicitScrolling = false,
    this.padEnds = true,
    this.loop = false,
    this.showIndicator = true,
    this.style = const GlobalPageViewStyle(),
    this.indicatorBuilder,
    this.storyMode = false,
    this.storyDefaultDuration,
    this.storyDurations,
    this.storyPauseOnHold = true,
    this.storyTapToAdvance = true,
    this.onStoryComplete,
    this.headerBuilder,
    this.footerBuilder,
    this.backgroundBuilder,
    this.thumbnailBuilder,
    this.enableKeyboardNav = false,
    this.swipeToDismiss = false,
    this.swipeToDismissDirection = SwipeDismissDirection.down,
    this.onItemDismissed,
    this.pinchToZoom = false,
    this.pinchToZoomMax = 4.0,
    this.hoverPeek = false,
    this.hoverPeekDuration,
  });

  final List<T> items;
  final GlobalPageItemBuilder<T> itemBuilder;
  final PageController? controller;

  /// Drives the deck in LOGICAL pages from outside the tree.
  ///
  /// Flutter's own [controller] counts VIRTUAL pages — a looping deck
  /// starts at `items.length * 1000` so it can wrap both ways — so
  /// `jumpToPage(2)` on it lands a thousand laps from where a caller
  /// meant. This one speaks the indices the caller's list has.
  final GlobalPageViewController? pageViewController;

  /// Turns the page by itself every
  /// [GlobalPageViewStyle.autoPlayInterval].
  ///
  /// It holds while a finger is down and while the deck is off screen,
  /// and [GlobalPageViewController.pauseAutoPlay] holds it for the
  /// reasons only the caller knows. On a deck that does not [loop] it
  /// stops at the last page rather than snapping back to the first:
  /// a banner that rewinds itself reads as a bug.
  final bool autoPlay;

  /// Whether a story or an auto-playing deck stops while it is
  /// scrolled out of view.
  ///
  /// `TickerMode` only covers a covered ROUTE, so a deck still built
  /// and merely off screen went on burning pages nobody could see —
  /// the same call `GlobalAnimation.pauseWhenOffscreen` makes.
  final bool pauseWhenOffscreen;

  /// Fires with the LOGICAL page index (0..items.length-1), not the
  /// raw PageView index — when [loop] is true the raw index runs in
  /// a wider range to enable wrapping.
  final void Function(int logicalPage)? onPageChanged;

  final Axis scrollDirection;
  final bool reverse;
  final ScrollPhysics? physics;
  final bool allowImplicitScrolling;
  final bool padEnds;

  /// When `true`, swiping past the last page wraps to the first
  /// (and vice versa). Implemented by mapping a large virtual
  /// index range to logical pages via modulo.
  final bool loop;

  final bool showIndicator;
  final GlobalPageViewStyle style;

  /// Override the default indicator with a caller-built widget.
  /// Receives `(context, currentLogicalPage, totalPages)`.
  final Widget Function(BuildContext context, int current, int total)?
  indicatorBuilder;

  // ─── Story mode (Instagram / WhatsApp style) ────────────

  /// When `true`, switches to story mode: the indicator becomes a
  /// segmented progress bar (one segment per page) that fills over
  /// the page's duration, then auto-advances. Disables the regular
  /// `style.indicatorStyle` and instead renders [GlobalStoryIndicator]
  /// at the top by default (override via [indicatorBuilder]).
  final bool storyMode;

  /// Default per-page duration when [storyDurations] doesn't supply
  /// one for a given index.
  /// Falls back to `GlobalPageViewStyle.storyDuration`, so a house can
  /// set the pace once.
  final Duration? storyDefaultDuration;

  /// Per-page durations (length should match `items.length`). When
  /// shorter or null, falls back to [storyDefaultDuration].
  final List<Duration>? storyDurations;

  /// When `true`, holding the screen pauses progress. Releasing
  /// resumes from the held progress.
  final bool storyPauseOnHold;

  /// When `true`, tapping the right half advances to the next page;
  /// the left half goes back. Drag-to-page still works normally.
  final bool storyTapToAdvance;

  /// Fires when the LAST page finishes its progress (when loop is
  /// off) — caller can use to dismiss the story view.
  final VoidCallback? onStoryComplete;

  // ─── Chrome slots (persist across pages) ────────────────

  /// Sticky header overlay. Receives the current logical page
  /// index + total. Useful for back button + page title.
  final Widget Function(BuildContext, int current, int total)? headerBuilder;

  /// Sticky footer overlay. Same signature as [headerBuilder].
  final Widget Function(BuildContext, int current, int total)? footerBuilder;

  /// Background widget cross-faded between pages. Receives the
  /// logical index — caller returns a per-page background. The
  /// page view stacks the previous + current backgrounds and fades
  /// between them by the controller's `page` fraction.
  final Widget Function(BuildContext, int logicalIndex)? backgroundBuilder;

  /// Builds a thumbnail strip overlay (one tile per page) above the
  /// page view. Tap a thumbnail to jump pages. Use the same builder
  /// you'd use for full-size content but scaled down.
  final Widget Function(BuildContext, int logicalIndex, bool isActive)?
  thumbnailBuilder;

  /// When `true`, registers a keyboard listener — arrow left/right
  /// (horizontal mode) or up/down (vertical) advance pages.
  final bool enableKeyboardNav;

  // ─── Dismiss / zoom / hover ────────────────────────────

  /// When `true`, each individual page can be dismissed by dragging
  /// orthogonal to the scroll axis. Fires [onItemDismissed] with
  /// the logical index of the dismissed page; caller mutates the
  /// items list + the page view updates (indicator follows).
  final bool swipeToDismiss;
  final SwipeDismissDirection swipeToDismissDirection;

  /// Fires when a page is dismissed via swipe. Caller MUST remove
  /// the item from the items list synchronously — otherwise
  /// Dismissible asserts that the dismissed widget is still in the
  /// tree.
  final void Function(int index)? onItemDismissed;

  /// When `true`, the page view wraps in `InteractiveViewer` so
  /// users can pinch-zoom into individual pages. Disables page
  /// dragging while zoomed in (caller can still swipe at scale=1).
  final bool pinchToZoom;
  final double pinchToZoomMax;

  /// When `true`, hovering over a dot in the indicator previews
  /// the target page WITHOUT navigating away. Release → snap back.
  /// Pointer-based — has no effect on touch-only devices.
  final bool hoverPeek;

  /// Falls back to `GlobalPageViewStyle.hoverPeekDuration`.
  final Duration? hoverPeekDuration;

  @override
  State<GlobalPageView<T>> createState() => GlobalPageViewState<T>();
}

/// Public so callers can grab it via [GlobalKey] for programmatic
/// page jumps without owning a [PageController].
class GlobalPageViewState<T> extends State<GlobalPageView<T>>
    with SingleTickerProviderStateMixin, PageChromeInsets<GlobalPageView<T>> {
  late PageController _ctrl;
  bool _ownsCtrl = false;
  int _currentLogical = 0;

  // ─── Story-mode state ──────────────────────────────────────
  /// Drives the per-page progress fill. Runs `value: 0 → 1` over
  /// the current page's duration; on completion auto-advances.
  AnimationController? _storyCtrl;

  /// True while the user is holding the screen (long-press) — the
  /// story controller is paused. Used to gate ticker advancement.
  // ─── What is holding the clock ─────────────────────────────
  // Three independent reasons, because they overlap: a finger can go
  // down while the deck is off screen, and releasing it must not
  // start a story nobody can see. One bool could not say that.
  bool _pausedByPointer = false;
  bool _pausedByOffscreen = false;
  bool _pausedByCaller = false;

  bool get _clockHeld =>
      _pausedByPointer || _pausedByOffscreen || _pausedByCaller;

  /// The auto-play timer. Null when the deck does not auto-play, or
  /// while something is holding it.
  Timer? _autoPlayTimer;

  /// Latch so the `onStoryComplete` callback fires exactly once for
  /// the final page (when loop is off).
  bool _storyCompleteFired = false;

  // ─── The resolved bag ──────────────────────────────────────
  late ResolvedPageViewStyle _rs;

  // ─── Keyboard focus ────────────────────────────────────────
  final FocusNode _keyboardFocus = FocusNode(debugLabel: 'GlobalPageView');

  // ─── Hover-peek state ────────────────────────────────────
  /// Logical page the user was on before hover-peek started. Used
  /// to snap back when the cursor leaves the indicator without
  /// committing to a new page.
  int? _hoverPeekOrigin;

  /// The caller's answer first, then the bag's — and zero under
  /// reduced motion either way.
  Duration get _hoverDuration => _rs.still
      ? Duration.zero
      : (widget.hoverPeekDuration ?? _rs.hoverPeekDuration);

  void _onIndicatorHover(int? idx) {
    if (!widget.hoverPeek) return;
    if (idx == null) {
      // Pointer left the indicator — snap back to where the user
      // was before hover started.
      final origin = _hoverPeekOrigin;
      if (origin != null) {
        animateToPage(origin, duration: _hoverDuration);
        _hoverPeekOrigin = null;
      }
      return;
    }
    _hoverPeekOrigin ??= _currentLogical;
    if (idx != _currentLogical) {
      animateToPage(idx, duration: _hoverDuration);
    }
  }

  // ─── Thumbnail strip auto-scroll ─────────────────────────
  /// Owned scroll controller for the optional thumbnail strip.
  /// Lazy — only created when `thumbnailBuilder` is non-null on
  /// first build.
  ScrollController? _thumbCtrl;

  /// Last animated-to-active thumbnail. Used to skip redundant
  /// animateTo calls when the page didn't change.
  int _thumbLastTarget = -1;

  /// Estimated thumbnail width (px) + horizontal padding/spacing
  /// used by [_centerThumbnail]. Keep these in sync with the
  /// strip's ListView.separated padding + thumb constraints.

  static const double _kThumbSeparator = 6;

  void _centerThumbnail() {
    final ctrl = _thumbCtrl;
    if (ctrl == null || !ctrl.hasClients || widget.items.isEmpty) return;
    if (_thumbLastTarget == _currentLogical) return;
    _thumbLastTarget = _currentLogical;
    final viewport = ctrl.position.viewportDimension;
    final tileStride = _rs.thumbTileWidth + _kThumbSeparator;
    final activeCenter =
        _rs.thumbStripPadding +
        _currentLogical * tileStride +
        _rs.thumbTileWidth / 2;
    final desiredOffset = (activeCenter - viewport / 2).clamp(
      ctrl.position.minScrollExtent,
      ctrl.position.maxScrollExtent,
    );
    // Zero under reduced motion, which `animateTo` treats as a jump.
    ctrl.animateTo(
      desiredOffset,
      duration: _rs.thumbScrollDuration,
      curve: _rs.pageCurve,
    );
  }

  static const int _loopOriginMultiplier = 1000;

  int get _loopOrigin => widget.items.length * _loopOriginMultiplier;

  Duration _storyDurationFor(int logicalIndex) {
    final list = widget.storyDurations;
    if (list != null && logicalIndex >= 0 && logicalIndex < list.length) {
      return list[logicalIndex];
    }
    // The WIDGET's answer first, then the bag's — a caller that set
    // one meant it, and a house sets the pace for the rest.
    return widget.storyDefaultDuration ?? _rs.storyDuration;
  }

  void _initStoryCtrl() {
    final duration = _storyDurationFor(_currentLogical);
    _storyCtrl = AnimationController(vsync: this, duration: duration)
      ..addStatusListener(_onStoryStatus)
      ..addListener(_onStoryTick);
    _storyCtrl!.forward();
  }

  void _resetStoryCtrl() {
    if (_storyCtrl == null) return;
    _storyCtrl!.duration = _storyDurationFor(_currentLogical);
    _storyCtrl!
      ..reset()
      ..forward();
    _storyCompleteFired = false;
  }

  void _onStoryStatus(AnimationStatus status) {
    if (status != AnimationStatus.completed) return;
    final n = widget.items.length;
    if (n == 0) return;
    final atEnd = !widget.loop && _currentLogical >= n - 1;
    if (atEnd) {
      if (!_storyCompleteFired) {
        _storyCompleteFired = true;
        widget.onStoryComplete?.call();
      }
      return;
    }
    animateToPage(
      widget.loop ? (_currentLogical + 1) % n : _currentLogical + 1,
    );
  }

  void _onStoryTick() {
    // Force rebuild so the indicator's `progress` reflects the
    // controller's value. setState only marks dirty — cost is
    // limited to the indicator overlay subtree.
    if (mounted) setState(() {});
  }

  /// Starts or stops the story clock and the auto-play timer to match
  /// [_clockHeld]. The ONE place either is turned on or off.
  void _syncClock() {
    if (_clockHeld) {
      _storyCtrl?.stop();
      _autoPlayTimer?.cancel();
      _autoPlayTimer = null;
      return;
    }
    if (widget.storyMode && _storyCtrl != null) {
      _storyCtrl!.forward();
    }
    if (widget.autoPlay && !widget.storyMode && _autoPlayTimer == null) {
      _autoPlayTimer = Timer.periodic(_rs.autoPlayInterval, (_) {
        if (!mounted || _clockHeld) return;
        final n = widget.items.length;
        if (n < 2) return;
        // A deck that does not loop STOPS at the end rather than
        // snapping back: a banner that rewinds itself reads as a bug.
        if (!widget.loop && _currentLogical >= n - 1) {
          _autoPlayTimer?.cancel();
          _autoPlayTimer = null;
          return;
        }
        _step(1);
      });
    }
    // NO `notify()` here. `_syncClock` runs from
    // `didChangeDependencies`, which is inside the build phase, and a
    // `ChangeNotifier` fired there marks its `ListenableBuilder` dirty
    // mid-build — `setState() or markNeedsBuild() called during
    // build`. The callers that change a HOLD notify instead; they run
    // from a gesture or a visibility callback.
  }

  void _setPaused(bool Function() read, void Function(bool) write, bool v) {
    if (read() == v) return;
    write(v);
    _syncClock();
    widget.pageViewController?.notify();
  }

  void _pauseStory() => _setPaused(
    () => _pausedByPointer,
    (v) => _pausedByPointer = v,
    true,
  );

  void _resumeStory() => _setPaused(
    () => _pausedByPointer,
    (v) => _pausedByPointer = v,
    false,
  );

  void _setOffscreen({required bool offscreen}) => _setPaused(
    () => _pausedByOffscreen,
    (v) => _pausedByOffscreen = v,
    offscreen,
  );

  /// The caller's own hold — see
  /// [GlobalPageViewController.pauseAutoPlay].
  void _setCallerPaused({required bool paused}) => _setPaused(
    () => _pausedByCaller,
    (v) => _pausedByCaller = v,
    paused,
  );

  @override
  void initState() {
    super.initState();
    _ctrl =
        widget.controller ??
        PageController(initialPage: widget.loop ? _loopOrigin : 0);
    _ownsCtrl = widget.controller == null;
    _currentLogical = 0;
    // The story controller is NOT started here: its duration can come
    // from the bag, and the bag is resolved in
    // `didChangeDependencies`, which runs after this. Reading it here
    // threw `LateInitializationError` on any story that did not set
    // `storyDefaultDuration` itself.
    _attach(widget.pageViewController);
  }

  void _attach(GlobalPageViewController? controller) {
    controller?.attach(
      owner: this,
      animateToPage: animateToPage,
      jumpToPage: jumpToPage,
      step: _step,
      page: () => _currentLogical,
      count: () => widget.items.length,
      setAutoPlayPaused: ({required bool paused}) =>
          _setCallerPaused(paused: paused),
      autoPlayPaused: () => _pausedByCaller,
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Here, not `initState`: the theme extension and
    // `disableAnimationsOf` are both inherited reads.
    _rs = widget.style.resolve(context);
    if (widget.storyMode && widget.items.isNotEmpty && _storyCtrl == null) {
      _initStoryCtrl();
    }
    // The auto-play timer wants the resolved interval, so it starts
    // here for the same reason the story controller does.
    _syncClock();
  }

  @override
  void didUpdateWidget(GlobalPageView<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.style != oldWidget.style) _rs = widget.style.resolve(context);
    if (widget.pageViewController != oldWidget.pageViewController) {
      oldWidget.pageViewController?.detach(owner: this);
      _attach(widget.pageViewController);
    }
    if (widget.autoPlay != oldWidget.autoPlay) {
      _autoPlayTimer?.cancel();
      _autoPlayTimer = null;
      _syncClock();
    }
    if (widget.storyMode != oldWidget.storyMode) {
      if (widget.storyMode && _storyCtrl == null) {
        _initStoryCtrl();
      } else if (!widget.storyMode && _storyCtrl != null) {
        _storyCtrl!.dispose();
        _storyCtrl = null;
      }
    }
  }

  @override
  void dispose() {
    widget.pageViewController?.detach(owner: this);
    _autoPlayTimer?.cancel();
    _storyCtrl?.dispose();
    _thumbCtrl?.dispose();
    _keyboardFocus.dispose();
    if (_ownsCtrl) _ctrl.dispose();
    super.dispose();
  }

  /// Animate to a logical page index.
  ///
  /// [duration] and [curve] default to the resolved bag, so a house
  /// that slowed its page turns down once gets it everywhere — and
  /// reduced motion zeroes them, which `animateToPage` treats as a
  /// jump.
  Future<void> animateToPage(
    int logicalPage, {
    Duration? duration,
    Curve? curve,
  }) {
    if (!_ctrl.hasClients) return Future.value();
    duration ??= _rs.pageDuration;
    curve ??= _rs.pageCurve;
    if (widget.loop) {
      // Move to nearest virtual index that matches the requested
      // logical page so the animation distance is minimal.
      final currentVirtual = _ctrl.page?.round() ?? _loopOrigin;
      final currentLogical =
          ((currentVirtual % widget.items.length) + widget.items.length) %
          widget.items.length;
      final delta = logicalPage - currentLogical;
      return _ctrl.animateToPage(
        currentVirtual + delta,
        duration: duration,
        curve: curve,
      );
    }
    return _ctrl.animateToPage(logicalPage, duration: duration, curve: curve);
  }

  /// Jump to a logical page index without animation.
  void jumpToPage(int logicalPage) {
    // `_hasSinglePosition`, not `hasClients` — see its doc.
    if (!_hasSinglePosition) return;
    if (widget.items.isEmpty) return;
    if (widget.loop) {
      final currentVirtual = _ctrl.page?.round() ?? _loopOrigin;
      final currentLogical =
          ((currentVirtual % widget.items.length) + widget.items.length) %
          widget.items.length;
      final delta = logicalPage - currentLogical;
      _ctrl.jumpToPage(currentVirtual + delta);
    } else {
      _ctrl.jumpToPage(logicalPage);
    }
  }

  /// What to hand the indicator as its continuous position, or null to
  /// let the indicator animate the change itself.
  ///
  /// In continuous mode the indicator derives `from = floor(value)` and
  /// `to = ceil(value)`, so it can only ever animate between ADJACENT
  /// dots. That is exactly right while a finger drags between two
  /// pages — and exactly wrong across a loop's wrap, where the marks
  /// run 0..n-1 and the swipe runs off the end: the value went 3.99 to
  /// 0.0 in a frame, so the last dot held and the first one lit
  /// instantly.
  ///
  /// Null in that last segment, which hands the wrap back to the
  /// indicator's own controller — and THAT is where the discrete
  /// effects live, `chain` included.
  double? _continuousFor(double raw, int n) {
    if (!widget.loop) return raw;
    if (n <= 1) return null;
    final logical = ((raw % n) + n) % n;
    return logical >= n - 1 ? null : logical;
  }

  /// Whether the controller has exactly ONE attached view.
  ///
  /// `ScrollController.position` asserts when it has more than one,
  /// and a page view briefly does: adding a header or a footer changes
  /// the depth of the `Stack` the `PageView` sits in, so for one frame
  /// the outgoing view and the incoming one are both attached. Every
  /// read of `position` goes through this — `hasClients` alone is not
  /// the same question and was what threw.
  bool get _hasSinglePosition => _ctrl.positions.length == 1;

  /// The controller's page, or a fallback while it cannot be asked.
  double _pageOr(double fallback) {
    if (!_hasSinglePosition || !_ctrl.position.haveDimensions) return fallback;
    return _ctrl.page ?? fallback;
  }

  /// Whether the page in progress is being turned by a FINGER.
  ///
  /// A swipe already has the page moving under the thumb, so a tick
  /// there is noise. The changes worth feeling are the ones a finger
  /// did not make: a tap on the indicator, a keyboard arrow, a story
  /// advancing on its own.
  bool get _draggedByFinger =>
      _hasSinglePosition && _ctrl.position.isScrollingNotifier.value;

  void _maybeTick() {
    if (!_rs.enableHaptic || _draggedByFinger) return;
    HapticFeedback.selectionClick();
  }

  void _onPageChanged(int rawIndex) {
    if (widget.items.isEmpty) return;
    final logical = widget.loop
        ? ((rawIndex % widget.items.length) + widget.items.length) %
              widget.items.length
        : rawIndex;
    if (logical != _currentLogical) {
      setState(() => _currentLogical = logical);
      widget.onPageChanged?.call(logical);
      widget.pageViewController?.notify();
      _maybeTick();
      if (widget.storyMode) _resetStoryCtrl();
      if (widget.thumbnailBuilder != null) {
        // Defer one frame so the strip's ScrollController has up-to-
        // date dimensions (the active thumbnail's new width).
        WidgetsBinding.instance.addPostFrameCallback((_) => _centerThumbnail());
      }
    }
  }

  int? _resolveItemCount() {
    if (widget.items.isEmpty) return 0;
    return widget.loop ? null : widget.items.length;
  }

  @override
  Widget build(BuildContext context) {
    final n = widget.items.length;
    // Scheduled whenever there is chrome to measure OR a stale
    // measurement to clear. It used to run only while a builder
    // existed, so REMOVING a footer left its height behind and the
    // indicator kept floating above a bar that was no longer there.
    scheduleChromeMeasure(
      hasChrome: widget.headerBuilder != null || widget.footerBuilder != null,
    );
    final pageView = PageView.builder(
      controller: _ctrl,
      onPageChanged: _onPageChanged,
      scrollDirection: widget.scrollDirection,
      reverse: widget.reverse,
      physics: widget.physics,
      allowImplicitScrolling: widget.allowImplicitScrolling,
      padEnds: widget.padEnds,
      itemCount: _resolveItemCount(),
      itemBuilder: (ctx, rawIndex) {
        if (n == 0) return const SizedBox.shrink();
        final logical = widget.loop ? ((rawIndex % n) + n) % n : rawIndex;
        var built = widget.itemBuilder(ctx, widget.items[logical], logical);
        // Per-item dismiss — each page wraps in a Dismissible.
        // Caller's `onItemDismissed` MUST remove the item from the
        // items list synchronously so the dismissed widget leaves
        // the tree (Dismissible asserts otherwise).
        if (widget.swipeToDismiss && widget.onItemDismissed != null) {
          built = Dismissible(
            key: ValueKey(
              'global-page-view-dismiss-${identityHashCode(widget.items[logical])}',
            ),
            direction: switch (widget.swipeToDismissDirection) {
              SwipeDismissDirection.up => DismissDirection.up,
              SwipeDismissDirection.down => DismissDirection.down,
              SwipeDismissDirection.left => DismissDirection.endToStart,
              SwipeDismissDirection.right => DismissDirection.startToEnd,
            },
            onDismissed: (_) => widget.onItemDismissed!.call(logical),
            child: built,
          );
        }
        // Apply the configured page transition by listening to the
        // controller and recomputing pageFraction each frame for the
        // visible items. Cheap — only active during scroll because
        // PageView only rebuilds visible items.
        if (_rs.transition == PageTransition.slide) return built;
        return AnimatedBuilder(
          animation: _ctrl,
          builder: (innerCtx, _) {
            final page = _pageOr(rawIndex.toDouble());
            final fraction = rawIndex - page;
            return applyPageTransition(
              child: built,
              pageFraction: fraction,
              transition: _rs.transition,
              axis: widget.scrollDirection,
            );
          },
        );
      },
    );
    Widget content = pageView;

    // Background cross-fade — paint previous + current builder
    // output and lerp opacity by the controller's fractional page.
    if (widget.backgroundBuilder != null) {
      content = AnimatedBuilder(
        animation: _ctrl,
        builder: (ctx, _) {
          final raw = _pageOr(_currentLogical.toDouble());
          final fromIdx = raw.floor();
          final toIdx = raw.ceil();
          final t = (raw - fromIdx).clamp(0.0, 1.0);
          final fromLogical = widget.loop
              ? ((fromIdx % n) + n) % n
              : fromIdx.clamp(0, n - 1);
          final toLogical = widget.loop
              ? ((toIdx % n) + n) % n
              : toIdx.clamp(0, n - 1);
          return Stack(
            fit: StackFit.expand,
            children: [
              Opacity(
                opacity: 1 - t,
                child: widget.backgroundBuilder!(ctx, fromLogical),
              ),
              Opacity(
                opacity: t,
                child: widget.backgroundBuilder!(ctx, toLogical),
              ),
              Positioned.fill(child: pageView),
            ],
          );
        },
      );
    }

    // Story-mode tap halves + hold-to-pause overlay. Sits ABOVE the
    // page view but BELOW chrome (header/footer/indicator).
    // Off-screen hold. Only wrapped when there is a clock to hold —
    // a `VisibilityDetector` is not free, and a deck the reader turns
    // by hand has nothing to stop.
    if (widget.pauseWhenOffscreen && (widget.storyMode || widget.autoPlay)) {
      content = VisibilityDetector(
        key: ValueKey<String>('gpv_${identityHashCode(this)}'),
        onVisibilityChanged: (info) {
          if (!mounted) return;
          _setOffscreen(offscreen: info.visibleFraction == 0);
        },
        child: content,
      );
    }
    // The finger holds an AUTO-PLAYING deck too, not only a story: a
    // banner that turns the page under a thumb is the same complaint
    // in a different hat.
    if ((widget.storyMode && widget.storyPauseOnHold) || widget.autoPlay) {
      // A LISTENER, and outside the tap halves.
      //
      // The pause used to hang off `onLongPressStart` INSIDE the
      // tap-to-advance detectors, so it did nothing at all unless
      // `storyTapToAdvance` was also on — and a long press is not the
      // only way a reader stops a story. A drag between pages left the
      // clock running, so a segment could advance out from under the
      // finger mid-swipe.
      //
      // A `Listener` takes no part in the gesture arena, so the page
      // view keeps its drag and the tap halves keep their taps; this
      // only watches the pointer.
      content = Listener(
        onPointerDown: (_) => _pauseStory(),
        onPointerUp: (_) => _resumeStory(),
        onPointerCancel: (_) => _resumeStory(),
        child: content,
      );
    }
    if (widget.storyMode && widget.storyTapToAdvance) {
      content = Stack(
        fit: StackFit.expand,
        children: [
          Positioned.fill(child: content),
          if (widget.storyTapToAdvance)
            Positioned.fill(
              child: Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      behavior: HitTestBehavior.translucent,
                      onTap: () {
                        if (n == 0) return;
                        final target = widget.loop
                            ? (_currentLogical - 1 + n) % n
                            : (_currentLogical - 1).clamp(0, n - 1);
                        animateToPage(target);
                      },
                    ),
                  ),
                  Expanded(
                    child: GestureDetector(
                      behavior: HitTestBehavior.translucent,
                      onTap: () {
                        if (n == 0) return;
                        final target = widget.loop
                            ? (_currentLogical + 1) % n
                            : (_currentLogical + 1).clamp(0, n - 1);
                        animateToPage(target);
                      },
                    ),
                  ),
                ],
              ),
            )
          else if (widget.storyPauseOnHold)
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onLongPressStart: (_) => _pauseStory(),
                onLongPressEnd: (_) => _resumeStory(),
              ),
            ),
        ],
      );
    }

    // Pinch + dismiss wrap the INNER content only (page + bg +
    // story-tap). Chrome (indicator, header/footer, thumbnail) sits
    // OUTSIDE so it stays anchored when the user swipes-to-dismiss
    // and isn't zoomed when pinched.
    if (widget.pinchToZoom) {
      content = InteractiveViewer(
        minScale: 1,
        maxScale: widget.pinchToZoomMax,
        clipBehavior: Clip.hardEdge,
        child: content,
      );
    }
    // Indicator overlay — story mode replaces dots w/ a segmented
    // progress bar at the top; regular mode keeps the configured
    // bottom indicator.
    final wantsIndicator = widget.showIndicator && n > 1;
    if (wantsIndicator) {
      final overlay =
          widget.indicatorBuilder?.call(context, _currentLogical, n) ??
          (widget.storyMode
              ? _buildStoryIndicator(n)
              : AnimatedBuilder(
                  animation: _ctrl,
                  builder: (ctx, _) {
                    double? continuous;
                    if (_hasSinglePosition && _ctrl.position.haveDimensions) {
                      continuous = _continuousFor(
                        _pageOr(_currentLogical.toDouble()),
                        n,
                      );
                    }
                    return PageIndicatorOverlay(
                      style: _rs,
                      axis: widget.scrollDirection,
                      current: _currentLogical,
                      total: n,
                      continuousIndex: continuous,
                      onTap: (i) => animateToPage(i),
                      onHover: widget.hoverPeek ? _onIndicatorHover : null,
                    );
                  },
                ));
      content = Stack(
        alignment: widget.storyMode
            ? AlignmentDirectional.topCenter
            : _rs.indicatorAlignment,
        children: [
          Positioned.fill(child: content),
          Padding(
            // Clear of whatever sticky chrome shares this edge — the
            // thumbnail strip included.
            padding: chromeInset(
              _rs.indicatorPadding,
              extraBottom: widget.thumbnailBuilder != null
                  ? _rs.thumbStripHeight
                  : 0,
            ),
            child: overlay,
          ),
        ],
      );
    }

    // Header / footer overlay.
    if (widget.headerBuilder != null || widget.footerBuilder != null) {
      content = Stack(
        fit: StackFit.expand,
        children: [
          Positioned.fill(child: content),
          if (widget.headerBuilder != null)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: KeyedSubtree(
                key: headerKey,
                child: SafeArea(
                  bottom: false,
                  // Only where the deck actually reaches the edge —
                  // see `_atTopEdge`.
                  top: atTopEdge,
                  child: widget.headerBuilder!(context, _currentLogical, n),
                ),
              ),
            ),
          if (widget.footerBuilder != null)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: KeyedSubtree(
                key: footerKey,
                child: SafeArea(
                  top: false,
                  bottom: atBottomEdge,
                  child: widget.footerBuilder!(context, _currentLogical, n),
                ),
              ),
            ),
        ],
      );
    }

    // Thumbnail strip overlay (above the footer, below indicator).
    if (widget.thumbnailBuilder != null) {
      _thumbCtrl ??= ScrollController();
      content = Stack(
        fit: StackFit.expand,
        children: [
          Positioned.fill(child: content),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              top: false,
              // Same rule as the footer: the device's inset belongs to
              // whatever is actually AT the edge.
              bottom: atBottomEdge,
              child: SizedBox(
                height: _rs.thumbStripHeight,
                child: ListView.separated(
                  controller: _thumbCtrl,
                  scrollDirection: Axis.horizontal,
                  padding: EdgeInsets.symmetric(
                    horizontal: _rs.thumbStripPadding,
                    vertical: 6,
                  ),
                  itemCount: n,
                  separatorBuilder: (_, _) =>
                      const SizedBox(width: _kThumbSeparator),
                  itemBuilder: (ctx, i) => SizedBox(
                    width: _rs.thumbTileWidth,
                    child: GestureDetector(
                      onTap: () => animateToPage(i),
                      child: widget.thumbnailBuilder!(
                        ctx,
                        i,
                        i == _currentLogical,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      );
    }

    // Keyboard nav wrapper — Focus + Shortcuts intercepts arrow keys
    // and forwards them to animateToPage. Skip when not enabled to
    // avoid stealing focus from descendant inputs.
    if (widget.enableKeyboardNav) {
      content = Focus(
        focusNode: _keyboardFocus,
        // NOT autofocus. A page view that takes focus the moment it is
        // built steals it from whatever the reader was on — the same
        // theft the collections had, and a deck of pages is even more
        // likely to sit in the middle of a page that already had a
        // field focused.
        onKeyEvent: _onKey,
        child: content,
      );
    }

    // The whole deck is ONE node that says where the reader is and can
    // be moved. It had no semantics at all: a swipe is invisible to a
    // screen reader, so a page view was a wall of unreachable content
    // with no hint that there was more of it.
    return Semantics(
      container: true,
      // The SAME string the pagination bar uses — one phrase for
      // "where am I in a sequence", and it writes Arabic digits in
      // Arabic.
      label: ListStrings.pageOf(_currentLogical + 1, n),
      // ADJUSTABLE, like the dot indicator it shares its position
      // with: the arrows move a page, and the value says which.
      value: '${_currentLogical + 1}',
      increasedValue: '${(_currentLogical + 2).clamp(1, n)}',
      decreasedValue: '${_currentLogical.clamp(1, n)}',
      onIncrease: n > 1 ? () => _step(1) : null,
      onDecrease: n > 1 ? () => _step(-1) : null,
      child: content,
    );
  }

  /// Moves one page, wrapping when the deck loops.
  void _step(int delta) {
    final n = widget.items.length;
    if (n == 0) return;
    final target = widget.loop
        ? (_currentLogical + delta + n) % n
        : (_currentLogical + delta).clamp(0, n - 1);
    animateToPage(target);
  }

  KeyEventResult _onKey(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
      return KeyEventResult.ignored;
    }
    final n = widget.items.length;
    if (n == 0) return KeyEventResult.ignored;
    final isVertical = widget.scrollDirection == Axis.vertical;
    // MIRRORED. A horizontal deck in Arabic puts page 0 on the right
    // and advances leftward, so the arrow that means "next" is the
    // LEFT one — pressing right used to go forward there, against
    // both the content and the swipe that produced it. A vertical
    // deck has no reading direction and keeps its keys.
    final rtl = !isVertical && Directionality.of(context) == TextDirection.rtl;
    final forwardKey = isVertical
        ? LogicalKeyboardKey.arrowDown
        : (rtl ? LogicalKeyboardKey.arrowLeft : LogicalKeyboardKey.arrowRight);
    final backKey = isVertical
        ? LogicalKeyboardKey.arrowUp
        : (rtl ? LogicalKeyboardKey.arrowRight : LogicalKeyboardKey.arrowLeft);
    if (event.logicalKey == forwardKey) {
      _step(1);
      return KeyEventResult.handled;
    }
    if (event.logicalKey == backKey) {
      _step(-1);
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  /// Renders the story-mode segmented progress bar. Reads
  /// `_storyCtrl.value` for the active segment fill.
  Widget _buildStoryIndicator(int n) {
    final progress = _storyCtrl?.value ?? 0;
    return GlobalStoryIndicator(
      count: n,
      activeIndex: _currentLogical,
      progress: progress,
      onTap: (i) => animateToPage(i),
    );
  }
}
