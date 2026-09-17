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
import '../page_view/global_page_view.dart';
import '../page_view/page_chrome_insets.dart';

export '../indicator/global_story_indicator.dart';
export '../indicator/indicator_models.dart';
export '../page_view/page_view_models.dart';

typedef GlobalCarouselItemBuilder<T> =
    Widget Function(
      BuildContext context,
      T item,
      int index,
      double pageFraction,
    );

/// Multi-item peek carousel — built on [GlobalPageView] with
/// `viewportFraction < 1` so adjacent items peek into view. Adds:
///
/// * `autoAdvance` — interval-based page-jump (different from
///   `GlobalAutoScroller`'s continuous scroll).
/// * `loop` — wrap around at edges.
/// * `pageFraction` — fed into [itemBuilder] so tiles can scale /
///   fade based on distance from center (parallax / hero effects).
/// * Built-in indicator (inherited from [GlobalPageView]).
/// * Story mode (segmented progress + tap halves + hold-to-pause).
/// * Header / footer / background / thumbnail chrome slots.
/// * Keyboard nav (arrow keys jump page).
class GlobalCarousel<T> extends StatefulWidget {
  const GlobalCarousel({
    super.key,
    required this.items,
    required this.itemBuilder,
    this.viewportFraction = 0.85,
    this.controller,
    this.onPageChanged,
    this.scrollDirection = Axis.horizontal,
    this.physics,
    this.padEnds = true,
    this.loop = true,
    this.autoAdvance = false,
    this.autoAdvanceInterval,
    this.autoAdvanceCurve,
    this.autoAdvanceDuration,
    this.pauseOnInteraction = true,
    this.resumeDelay = const Duration(seconds: 2),
    this.showIndicator = true,
    this.style = const GlobalPageViewStyle(),
    this.indicatorBuilder,
    this.carouselController,
    this.pauseWhenOffscreen = true,
    this.storyMode = false,
    this.storyDefaultDuration = const Duration(seconds: 5),
    this.storyDurations,
    this.storyPauseOnHold = true,
    this.storyTapToAdvance = true,
    this.onStoryComplete,
    this.headerBuilder,
    this.footerBuilder,
    this.backgroundBuilder,
    this.thumbnailBuilder,
    this.enableKeyboardNav = false,
  });

  final List<T> items;

  /// Builds each item. `pageFraction` is the distance from the
  /// centered page in [-1, +1] range (clamped). 0 = centered.
  /// Use to scale / fade neighbours.
  final GlobalCarouselItemBuilder<T> itemBuilder;

  /// Portion of the viewport occupied per page. 0.85 = the
  /// neighbouring 7.5% peeks on each side. 1.0 = single page.
  final double viewportFraction;

  final PageController? controller;
  final void Function(int logicalPage)? onPageChanged;
  final Axis scrollDirection;
  final ScrollPhysics? physics;
  final bool padEnds;
  final bool loop;

  /// When `true`, advances one page every [autoAdvanceInterval].
  final bool autoAdvance;

  /// Falls through to `GlobalPageViewStyle.autoPlayInterval`, so a
  /// house sets the pace once. It was a baked-in four seconds while
  /// the page view's was a bag-driven five — one family, two answers.
  final Duration? autoAdvanceInterval;

  /// Falls through to `GlobalPageViewStyle.pageCurve`.
  final Curve? autoAdvanceCurve;

  /// Falls through to `GlobalPageViewStyle.pageDuration`, and so is
  /// zeroed by reduced motion.
  final Duration? autoAdvanceDuration;

  /// When `true`, pause auto-advance while the user is touching the
  /// carousel; resume [resumeDelay] after release.
  final bool pauseOnInteraction;
  final Duration resumeDelay;

  final bool showIndicator;
  final GlobalPageViewStyle style;
  final Widget Function(BuildContext context, int current, int total)?
  indicatorBuilder;

  /// Story mode: replaces the dot indicator with a segmented
  /// progress bar at the top + auto-advances on segment fill.
  final bool storyMode;
  final Duration storyDefaultDuration;
  final List<Duration>? storyDurations;
  final bool storyPauseOnHold;
  final bool storyTapToAdvance;
  final VoidCallback? onStoryComplete;

  final Widget Function(BuildContext, int current, int total)? headerBuilder;
  final Widget Function(BuildContext, int current, int total)? footerBuilder;

  /// Background widget cross-faded between pages. Caller returns a
  /// per-page background; we lerp opacity by `PageController.page`.
  final Widget Function(BuildContext, int logicalIndex)? backgroundBuilder;

  /// Thumbnail strip overlay (one tile per page). Tap to jump pages.
  final Widget Function(BuildContext, int logicalIndex, bool isActive)?
  thumbnailBuilder;

  /// When `true`, arrow keys jump page (left/right horizontal,
  /// up/down vertical).
  final bool enableKeyboardNav;

  /// Drives the carousel in LOGICAL items from outside the tree — the
  /// same controller the page view takes, because it is the same
  /// question. Flutter's `PageController` counts VIRTUAL pages, and a
  /// looping carousel starts a thousand laps in.
  final GlobalPageViewController? carouselController;

  /// Whether a story or an auto-advance stops while the carousel is
  /// scrolled out of view.
  final bool pauseWhenOffscreen;

  @override
  State<GlobalCarousel<T>> createState() => GlobalCarouselState<T>();
}

class GlobalCarouselState<T> extends State<GlobalCarousel<T>>
    with SingleTickerProviderStateMixin, PageChromeInsets<GlobalCarousel<T>> {
  /// The resolved page-family bag — see `GlobalPageViewStyle`.
  late ResolvedPageViewStyle _rs;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Here, not `initState`: the theme extension and
    // `disableAnimationsOf` are inherited reads.
    _rs = widget.style.resolve(context);
    if (widget.autoAdvance && _advanceTimer == null) _startTimer();
  }

  late PageController _ctrl;
  bool _ownsCtrl = false;
  Timer? _advanceTimer;

  /// Releases [_interacting] after the reader lets go — cancellable,
  /// so a torn-down carousel takes it with it.
  Timer? _resumeTimer;

  /// Held while the carousel is off screen, and while the caller says
  /// so. `_interacting` is the third, and it already existed.
  bool _pausedByOffscreen = false;
  bool _pausedByCaller = false;
  bool _interacting = false;
  double _pageFraction = 0;
  int _currentLogical = 0;

  // ─── Story-mode state ──────────────────────────────────────
  AnimationController? _storyCtrl;
  bool _storyPaused = false;
  bool _storyCompleteFired = false;

  // ─── Thumbnail strip ────────────────────────────────────
  ScrollController? _thumbCtrl;
  int _thumbLastTarget = -1;
  static const double _kThumbTileWidth = 64;
  static const double _kThumbStripPad = 12;
  static const double _kThumbSeparator = 6;

  final FocusNode _keyboardFocus = FocusNode(debugLabel: 'GlobalCarousel');

  static const int _loopOriginMultiplier = 1000;
  int get _loopOrigin => widget.items.length * _loopOriginMultiplier;

  Duration _storyDurationFor(int logicalIndex) {
    final list = widget.storyDurations;
    if (list != null && logicalIndex >= 0 && logicalIndex < list.length) {
      return list[logicalIndex];
    }
    return widget.storyDefaultDuration;
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
    if (mounted) setState(() {});
  }

  void _pauseStory() {
    if (!widget.storyMode || _storyCtrl == null || _storyPaused) return;
    _storyPaused = true;
    _storyCtrl!.stop();
  }

  void _resumeStory() {
    if (!widget.storyMode || _storyCtrl == null || !_storyPaused) return;
    _storyPaused = false;
    _storyCtrl!.forward();
  }

  void _centerThumbnail() {
    final ctrl = _thumbCtrl;
    if (ctrl == null || !ctrl.hasClients || widget.items.isEmpty) return;
    if (_thumbLastTarget == _currentLogical) return;
    _thumbLastTarget = _currentLogical;
    final viewport = ctrl.position.viewportDimension;
    const tileStride = _kThumbTileWidth + _kThumbSeparator;
    final activeCenter =
        _kThumbStripPad + _currentLogical * tileStride + _kThumbTileWidth / 2;
    final desiredOffset = (activeCenter - viewport / 2).clamp(
      ctrl.position.minScrollExtent,
      ctrl.position.maxScrollExtent,
    );
    // The BAG's duration — zero under reduced motion, which
    // `animateTo` treats as a jump.
    ctrl.animateTo(
      desiredOffset,
      duration: _rs.thumbScrollDuration,
      curve: _rs.pageCurve,
    );
  }

  @override
  void initState() {
    super.initState();
    _ctrl =
        widget.controller ??
        PageController(
          initialPage: widget.loop ? _loopOrigin : 0,
          viewportFraction: widget.viewportFraction,
        );
    _ownsCtrl = widget.controller == null;
    _ctrl.addListener(_onPageScroll);
    _attach(widget.carouselController);
    // The timer is NOT started here: its interval can come from the
    // bag, and the bag is resolved in `didChangeDependencies`, which
    // runs after this. Reading it here threw
    // `LateInitializationError` for any carousel that did not set
    // `autoAdvanceInterval` itself — the same trap the page view's
    // story controller fell into.
    if (widget.storyMode && widget.items.isNotEmpty) _initStoryCtrl();
  }

  void _attach(GlobalPageViewController? controller) {
    controller?.attach(
      owner: this,
      animateToPage: animateToPage,
      jumpToPage: jumpToPage,
      step: _step,
      page: () => _currentLogical,
      count: () => widget.items.length,
      setAutoPlayPaused: ({required bool paused}) {
        if (_pausedByCaller == paused) return;
        _pausedByCaller = paused;
        if (paused) {
          _storyCtrl?.stop();
        } else if (widget.storyMode && !_storyPaused) {
          _storyCtrl?.forward();
        }
        controller.notify();
      },
      autoPlayPaused: () => _pausedByCaller,
    );
  }

  @override
  void didUpdateWidget(GlobalCarousel<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.carouselController != oldWidget.carouselController) {
      oldWidget.carouselController?.detach(owner: this);
      _attach(widget.carouselController);
    }
    if (widget.autoAdvance != oldWidget.autoAdvance) {
      if (widget.autoAdvance) {
        _startTimer();
      } else {
        _advanceTimer?.cancel();
      }
    }
    if (widget.autoAdvanceInterval != oldWidget.autoAdvanceInterval) {
      _advanceTimer?.cancel();
      if (widget.autoAdvance) _startTimer();
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
    widget.carouselController?.detach(owner: this);
    _advanceTimer?.cancel();
    _resumeTimer?.cancel();
    _ctrl.removeListener(_onPageScroll);
    if (_ownsCtrl) _ctrl.dispose();
    _storyCtrl?.dispose();
    _thumbCtrl?.dispose();
    _keyboardFocus.dispose();
    super.dispose();
  }

  /// Whether the controller has exactly ONE attached view.
  ///
  /// `ScrollController.position` asserts with more than one, and a
  /// carousel briefly has two whenever the `Stack` around it changes
  /// depth — adding a header or a footer is enough. `hasClients` is
  /// not the same question.
  bool get _hasSinglePosition => _ctrl.positions.length == 1;

  /// Whether the page in progress is being turned by a FINGER. A swipe
  /// already has the page moving under the thumb, so the tick is for
  /// the changes a finger did not make.
  bool get _draggedByFinger =>
      _hasSinglePosition && _ctrl.position.isScrollingNotifier.value;

  void _maybeTick() {
    if (!_rs.enableHaptic || _draggedByFinger) return;
    HapticFeedback.selectionClick();
  }

  /// One page on or back, wrapping when the carousel loops.
  void _step(int delta) {
    final n = widget.items.length;
    if (n == 0) return;
    final target = widget.loop
        ? (_currentLogical + delta + n) % n
        : (_currentLogical + delta).clamp(0, n - 1);
    animateToPage(target);
  }

  void _startTimer() {
    _advanceTimer?.cancel();
    _advanceTimer = Timer.periodic(
      widget.autoAdvanceInterval ?? _rs.autoPlayInterval,
      (_) {
        if (!mounted ||
            _interacting ||
            _pausedByOffscreen ||
            _pausedByCaller ||
            !_hasSinglePosition ||
            widget.items.isEmpty) {
          return;
        }
        final current = _ctrl.page?.round() ?? 0;
        _ctrl.animateToPage(
          current + 1,
          duration: widget.autoAdvanceDuration ?? _rs.pageDuration,
          curve: widget.autoAdvanceCurve ?? _rs.pageCurve,
        );
      },
    );
  }

  void _onPageScroll() {
    if (!_hasSinglePosition) return;
    final page = _ctrl.page ?? 0;
    final fraction = page - page.round();
    if ((fraction - _pageFraction).abs() > 0.001) {
      setState(() => _pageFraction = fraction);
    }
  }

  void _onPointerDown(PointerDownEvent _) {
    if (widget.pauseOnInteraction) _interacting = true;
  }

  void _onPointerUp(PointerUpEvent _) {
    if (!widget.pauseOnInteraction) return;
    // A cancellable TIMER, not `Future.delayed`. A future cannot be
    // called off: every touch scheduled another, each one holding the
    // State alive until it fired, and a carousel that is touched a
    // lot — which is the only kind there is — accumulated them. The
    // `mounted` check stopped the crash and not the leak.
    _resumeTimer?.cancel();
    _resumeTimer = Timer(widget.resumeDelay, () {
      if (mounted) _interacting = false;
    });
  }

  double _pageFractionFor(int rawIndex) {
    if (!_ctrl.hasClients) return 0;
    final page = _ctrl.page ?? rawIndex.toDouble();
    return (rawIndex - page).clamp(-1.0, 1.0);
  }

  int? _resolveItemCount() {
    if (widget.items.isEmpty) return 0;
    return widget.loop ? null : widget.items.length;
  }

  void _onPageChanged(int rawIndex) {
    if (widget.items.isEmpty) return;
    final n = widget.items.length;
    final logical = widget.loop ? ((rawIndex % n) + n) % n : rawIndex;
    if (logical != _currentLogical) {
      setState(() => _currentLogical = logical);
      widget.onPageChanged?.call(logical);
      widget.carouselController?.notify();
      _maybeTick();
      if (widget.storyMode) _resetStoryCtrl();
      if (widget.thumbnailBuilder != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) => _centerThumbnail());
      }
    }
  }

  /// Animate to logical page (handles loop virtual mapping).
  Future<void> animateToPage(
    int logicalPage, {
    Duration? duration,
    Curve curve = Curves.easeOutCubic,
  }) {
    if (!_hasSinglePosition) return Future.value();
    // The bag's, so reduced motion zeroes it — `animateToPage` treats
    // zero as a jump, and the pages still change.
    final d = duration ?? widget.autoAdvanceDuration ?? _rs.pageDuration;
    final n = widget.items.length;
    if (widget.loop && n > 0) {
      final currentVirtual = _ctrl.page?.round() ?? _loopOrigin;
      final currentLog = ((currentVirtual % n) + n) % n;
      final delta = logicalPage - currentLog;
      return _ctrl.animateToPage(
        currentVirtual + delta,
        duration: d,
        curve: curve,
      );
    }
    return _ctrl.animateToPage(logicalPage, duration: d, curve: curve);
  }

  void jumpToPage(int logicalPage) {
    if (!_hasSinglePosition) return;
    final n = widget.items.length;
    if (widget.loop && n > 0) {
      final currentVirtual = _ctrl.page?.round() ?? _loopOrigin;
      final currentLog = ((currentVirtual % n) + n) % n;
      final delta = logicalPage - currentLog;
      _ctrl.jumpToPage(currentVirtual + delta);
    } else {
      _ctrl.jumpToPage(logicalPage);
    }
  }

  @override
  Widget build(BuildContext context) {
    scheduleChromeMeasure(
      hasChrome: widget.headerBuilder != null || widget.footerBuilder != null,
    );
    final n = widget.items.length;
    if (n == 0) return const SizedBox.expand();
    final pageView = PageView.builder(
      controller: _ctrl,
      onPageChanged: _onPageChanged,
      scrollDirection: widget.scrollDirection,
      physics: widget.physics,
      padEnds: widget.padEnds,
      itemCount: _resolveItemCount(),
      itemBuilder: (ctx, rawIndex) {
        final logical = widget.loop ? ((rawIndex % n) + n) % n : rawIndex;
        final fraction = _pageFractionFor(rawIndex);
        final built = widget.itemBuilder(
          ctx,
          widget.items[logical],
          logical,
          fraction,
        );
        if (_rs.transition == PageTransition.slide) return built;
        return applyPageTransition(
          child: built,
          pageFraction: fraction,
          transition: _rs.transition,
          axis: widget.scrollDirection,
        );
      },
    );
    Widget content = Listener(
      onPointerDown: _onPointerDown,
      onPointerUp: _onPointerUp,
      onPointerCancel: (_) => _onPointerUp(const PointerUpEvent()),
      child: pageView,
    );

    // Background cross-fade.
    if (widget.backgroundBuilder != null) {
      content = AnimatedBuilder(
        animation: _ctrl,
        builder: (ctx, _) {
          // `positions.length`, not `hasClients`: a controller with
          // two attached views asserts on `.position`, and a page view
          // briefly has two whenever the Stack around it changes depth.
          final raw =
              _ctrl.positions.length == 1 && _ctrl.position.haveDimensions
              ? (_ctrl.page ?? _currentLogical.toDouble())
              : _currentLogical.toDouble();
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
              Positioned.fill(
                child: Listener(
                  onPointerDown: _onPointerDown,
                  onPointerUp: _onPointerUp,
                  onPointerCancel: (_) => _onPointerUp(const PointerUpEvent()),
                  child: pageView,
                ),
              ),
            ],
          );
        },
      );
    }

    // Story tap halves + hold overlay.
    if (widget.storyMode &&
        (widget.storyTapToAdvance || widget.storyPauseOnHold)) {
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
                        final target = widget.loop
                            ? (_currentLogical - 1 + n) % n
                            : (_currentLogical - 1).clamp(0, n - 1);
                        animateToPage(target);
                      },
                      onLongPressStart: widget.storyPauseOnHold
                          ? (_) => _pauseStory()
                          : null,
                      onLongPressEnd: widget.storyPauseOnHold
                          ? (_) => _resumeStory()
                          : null,
                    ),
                  ),
                  Expanded(
                    child: GestureDetector(
                      behavior: HitTestBehavior.translucent,
                      onTap: () {
                        final target = widget.loop
                            ? (_currentLogical + 1) % n
                            : (_currentLogical + 1).clamp(0, n - 1);
                        animateToPage(target);
                      },
                      onLongPressStart: widget.storyPauseOnHold
                          ? (_) => _pauseStory()
                          : null,
                      onLongPressEnd: widget.storyPauseOnHold
                          ? (_) => _resumeStory()
                          : null,
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

    // Indicator overlay (story → segmented bar, else dots/numbered).
    final wantsIndicator = widget.showIndicator && n > 1;
    if (wantsIndicator) {
      final overlay =
          widget.indicatorBuilder?.call(context, _currentLogical, n) ??
          (widget.storyMode
              ? GlobalStoryIndicator(
                  count: n,
                  activeIndex: _currentLogical,
                  progress: _storyCtrl?.value ?? 0,
                  onTap: (i) => animateToPage(i),
                )
              : AnimatedBuilder(
                  animation: _ctrl,
                  builder: (ctx, _) {
                    double? continuous;
                    if (_ctrl.positions.length == 1 &&
                        _ctrl.position.haveDimensions) {
                      final raw = _ctrl.page ?? _currentLogical.toDouble();
                      continuous = widget.loop ? ((raw % n) + n) % n : raw;
                    }
                    return PageIndicatorOverlay(
                      style: _rs,
                      axis: widget.scrollDirection,
                      current: _currentLogical,
                      total: n,
                      continuousIndex: continuous,
                      onTap: (i) => animateToPage(i),
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
            // Clear of whatever sticky chrome shares this edge. The
            // header and the footer are OVERLAYS aligned against the
            // same box, so without this the footer bar drew straight
            // over the dots — the page view's bug, in its siblings'
            // identical code.
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

    // Header / footer.
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
                  // Only where the deck actually reaches the edge.
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

    // Thumbnail strip.
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
              child: SizedBox(
                height: 76,
                child: ListView.separated(
                  controller: _thumbCtrl,
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(
                    horizontal: _kThumbStripPad,
                    vertical: 6,
                  ),
                  itemCount: n,
                  separatorBuilder: (_, _) =>
                      const SizedBox(width: _kThumbSeparator),
                  itemBuilder: (ctx, i) => SizedBox(
                    width: _kThumbTileWidth,
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

    // Keyboard nav.
    if (widget.enableKeyboardNav) {
      content = Focus(
        focusNode: _keyboardFocus,
        // NOT autofocus. A carousel that takes focus the moment it is
        // built steals it from whatever the reader was on, and a
        // carousel is usually one thing among many on a page.
        onKeyEvent: _onKey,
        child: content,
      );
    }

    // Held while nobody can see it. `TickerMode` only covers a covered
    // ROUTE, so a carousel merely scrolled out of view went on turning
    // pages — the same call `GlobalAnimation.pauseWhenOffscreen` makes.
    // Only wrapped when there IS a clock: a `VisibilityDetector` is
    // not free.
    if (widget.pauseWhenOffscreen && (widget.storyMode || widget.autoAdvance)) {
      content = VisibilityDetector(
        key: ValueKey<String>('gcar_${identityHashCode(this)}'),
        onVisibilityChanged: (info) {
          if (!mounted) return;
          final offscreen = info.visibleFraction == 0;
          if (_pausedByOffscreen == offscreen) return;
          _pausedByOffscreen = offscreen;
          if (offscreen) {
            _storyCtrl?.stop();
          } else if (widget.storyMode && !_storyPaused) {
            _storyCtrl?.forward();
          }
          widget.carouselController?.notify();
        },
        child: content,
      );
    }

    // ONE node for the whole carousel. It had none: a swipe is
    // invisible to a screen reader, so this was a wall of unreachable
    // content with no hint that there was more of it.
    return Semantics(
      container: true,
      label: ListStrings.pageOf(_currentLogical + 1, n),
      value: '${_currentLogical + 1}',
      increasedValue: '${(_currentLogical + 2).clamp(1, n)}',
      decreasedValue: '${_currentLogical.clamp(1, n)}',
      onIncrease: n > 1 ? () => _step(1) : null,
      onDecrease: n > 1 ? () => _step(-1) : null,
      child: content,
    );
  }

  KeyEventResult _onKey(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
      return KeyEventResult.ignored;
    }
    final n = widget.items.length;
    if (n == 0) return KeyEventResult.ignored;
    final isVertical = widget.scrollDirection == Axis.vertical;
    // MIRRORED. A horizontal carousel in Arabic puts item 0 on the
    // right and advances leftward, so the arrow that means "next" is
    // the LEFT one. A vertical one keeps its keys: up and down have no
    // reading direction.
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
}
