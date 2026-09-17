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
import '../page_view/page_chrome_insets.dart';
import '../page_view/page_indicator_overlay.dart';
import '../page_view/page_view_controller.dart';
import '../page_view/page_view_models.dart';
import '../page_view/theme/page_view_theme.dart';

export '../indicator/global_story_indicator.dart';
export '../indicator/indicator_models.dart';
export '../page_view/page_view_controller.dart';
export '../page_view/page_view_models.dart'
    show GlobalPageViewStyle, PageIndicatorStyle;

typedef GlobalCarouselViewItemBuilder<T> =
    Widget Function(BuildContext context, T item, int index);

/// Wraps Flutter's [CarouselView.weighted] with a typed builder +
/// indicator overlay + chrome slots matching `GlobalPageView`'s
/// API surface.
///
/// `CarouselView.weighted` provides the "accordion" effect for
/// free: items scroll through a row of slots with non-uniform
/// flex weights — the slot at center is wide, edges are narrow.
/// As an item slides toward an edge it compresses, sliding into
/// the center it expands. No custom transform math needed.
///
/// Typical [flexWeights] patterns:
/// * `[1, 7]` — leading edge peek + dominant center (default).
/// * `[1, 7, 1]` — leading + trailing peek + dominant center.
/// * `[1, 8, 1]` — same shape, more dominant center.
/// * `[3, 5, 1]` — asymmetric carousel.
///
/// Loop mode is implemented by duplicating the children N times and
/// starting near the middle; on settle near either edge we jump back
/// to the middle so the user can keep scrolling in either direction
/// without hitting an end.
class GlobalCarouselView<T> extends StatefulWidget {
  const GlobalCarouselView({
    super.key,
    required this.items,
    required this.itemBuilder,
    this.flexWeights = const [1, 7, 1],
    this.itemSnapping = true,
    this.controller,
    this.onPageChanged,
    this.scrollDirection = Axis.horizontal,
    this.reverse = false,
    this.padding,
    this.elevation = 0,
    this.shape = const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
    this.backgroundColor = Colors.transparent,
    this.shrinkExtent = 0,
    this.onTap,
    this.showIndicator = true,
    this.style = const GlobalPageViewStyle(),
    this.indicatorBuilder,
    this.headerBuilder,
    this.footerBuilder,
    this.enableKeyboardNav = false,
    this.loop = false,
    this.autoPlay = false,
    this.autoPlayInterval,
    this.viewController,
    this.pauseWhenOffscreen = true,
    this.storyMode = false,
    this.storyDefaultDuration = const Duration(seconds: 5),
    this.storyDurations,
    this.storyPauseOnHold = true,
    this.storyTapToAdvance = true,
    this.onStoryComplete,
    this.thumbnailBuilder,
  });

  /// Source data; widget never mutates this list.
  final List<T> items;

  /// `(context, item, index)` builder for each carousel cell.
  final GlobalCarouselViewItemBuilder<T> itemBuilder;

  /// Slot weights. Length defines how many slots are visible; each
  /// integer is its proportional share of the viewport along the
  /// scroll axis.
  final List<int> flexWeights;

  /// When `true`, scroll snaps each item into the highest-weight
  /// slot on release.
  final bool itemSnapping;

  final CarouselController? controller;
  final void Function(int index)? onPageChanged;
  final Axis scrollDirection;
  final bool reverse;
  final EdgeInsets? padding;
  final double elevation;

  /// Background shape for each carousel cell. Default is a
  /// zero-radius rectangle so caller's tile content (which already
  /// supplies its own borders / radii) isn't double-clipped.
  /// Override with a `RoundedRectangleBorder` for the M3 default.
  final ShapeBorder shape;

  /// Cell background color. Default `Colors.transparent` so caller's
  /// content paints directly (CarouselView's own Material no longer
  /// shows behind it).
  final Color backgroundColor;

  /// Minimum size an item shrinks to at the edge slots. 0 = item
  /// fully disappears off the edge.
  final double shrinkExtent;

  /// Tap handler invoked with the tapped LOGICAL item index.
  final void Function(int index)? onTap;

  final bool showIndicator;
  final GlobalPageViewStyle style;
  final Widget Function(BuildContext, int current, int total)? indicatorBuilder;
  final Widget Function(BuildContext, int current, int total)? headerBuilder;
  final Widget Function(BuildContext, int current, int total)? footerBuilder;
  final bool enableKeyboardNav;

  /// Turns to the next item by itself every [autoPlayInterval].
  ///
  /// The page view has `autoPlay` and the carousel has `autoAdvance`;
  /// this was the sibling that could only move itself in story mode.
  /// It holds while a finger is down, while the carousel is off
  /// screen, and while the controller says so — and on a deck that
  /// does not [loop] it stops at the last item rather than rewinding.
  final bool autoPlay;

  /// Falls through to `GlobalPageViewStyle.autoPlayInterval`, so one
  /// house setting paces all three.
  final Duration? autoPlayInterval;

  /// Drives the carousel in LOGICAL items from outside the tree — the
  /// same controller the page view and the carousel take.
  final GlobalPageViewController? viewController;

  /// Whether a story stops while the carousel is scrolled out of view.
  final bool pauseWhenOffscreen;

  /// When `true`, the carousel wraps around at edges. Implemented
  /// by duplicating children + recentering on settle.
  final bool loop;

  /// Story mode: replaces the dot indicator with a segmented
  /// progress bar at the top + auto-advances on segment fill.
  final bool storyMode;
  final Duration storyDefaultDuration;
  final List<Duration>? storyDurations;
  final bool storyPauseOnHold;
  final bool storyTapToAdvance;
  final VoidCallback? onStoryComplete;

  /// Thumbnail strip overlay (one tile per LOGICAL page). Tap to
  /// jump pages.
  final Widget Function(BuildContext, int logicalIndex, bool isActive)?
  thumbnailBuilder;

  @override
  State<GlobalCarouselView<T>> createState() => _GlobalCarouselViewState<T>();
}

class _GlobalCarouselViewState<T> extends State<GlobalCarouselView<T>>
    with
        SingleTickerProviderStateMixin,
        PageChromeInsets<GlobalCarouselView<T>> {
  /// The resolved page-family bag — see `GlobalPageViewStyle`.
  late ResolvedPageViewStyle _rs;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Here, not `initState`: the theme extension and
    // `disableAnimationsOf` are inherited reads.
    _rs = widget.style.resolve(context);
    // The auto-play timer wants the resolved interval, so it starts
    // here rather than in `initState`.
    _syncClock();
  }

  late CarouselController _ctrl;
  bool _ownsCtrl = false;
  int _current = 0;

  /// Whether the controller has exactly ONE attached view — see the
  /// note in `_maybeClampOnSettle`.
  bool get _hasSinglePosition => _ctrl.positions.length == 1;

  /// Held while nobody can see the carousel, while a finger is down,
  /// and while the caller says so. Three flags rather than one because
  /// they overlap: a finger can go down while the carousel is off
  /// screen, and lifting it must not start something nobody can see.
  bool _pausedByOffscreen = false;
  bool _pausedByCaller = false;
  bool _pausedByPointer = false;

  Timer? _autoPlayTimer;

  bool get _clockHeld =>
      _pausedByOffscreen || _pausedByCaller || _pausedByPointer;

  /// The ONE place the auto-play timer and the story clock are turned
  /// on or off.
  void _syncClock() {
    if (_clockHeld) {
      _storyCtrl?.stop();
      _autoPlayTimer?.cancel();
      _autoPlayTimer = null;
      return;
    }
    if (widget.storyMode && _storyCtrl != null && !_storyPaused) {
      _storyCtrl!.forward();
    }
    if (widget.autoPlay && !widget.storyMode && _autoPlayTimer == null) {
      _autoPlayTimer = Timer.periodic(
        widget.autoPlayInterval ?? _rs.autoPlayInterval,
        (_) {
          if (!mounted || _clockHeld) return;
          final n = widget.items.length;
          if (n < 2) return;
          // A deck that does not loop STOPS at the end: a strip that
          // rewinds itself reads as a bug.
          if (!widget.loop && _current >= n - 1) {
            _autoPlayTimer?.cancel();
            _autoPlayTimer = null;
            return;
          }
          _step(1);
        },
      );
    }
  }

  void _setPointerHeld({required bool held}) {
    if (_pausedByPointer == held) return;
    _pausedByPointer = held;
    _syncClock();
  }

  /// Whether a finger is turning the page right now.
  bool get _draggedByFinger =>
      _hasSinglePosition && _ctrl.position.isScrollingNotifier.value;

  void _maybeTick() {
    if (!_rs.enableHaptic || _draggedByFinger) return;
    HapticFeedback.selectionClick();
  }

  /// One item on or back, wrapping when the carousel loops.
  void _step(int delta) {
    final n = widget.items.length;
    if (n == 0) return;
    animateToPage(
      widget.loop
          ? (_current + delta + n) % n
          : (_current + delta).clamp(0, n - 1),
    );
  }

  void _attach(GlobalPageViewController? controller) {
    controller?.attach(
      owner: this,
      animateToPage: animateToPage,
      jumpToPage: (page) => animateToPage(page, duration: Duration.zero),
      step: _step,
      page: () => _current,
      count: () => widget.items.length,
      setAutoPlayPaused: ({required bool paused}) {
        if (_pausedByCaller == paused) return;
        _pausedByCaller = paused;
        _syncClock();
        controller.notify();
      },
      autoPlayPaused: () => _pausedByCaller,
    );
  }

  double _continuousIndex = 0;

  // ─── Loop ──────────────────────────────────────
  /// Number of copies in the virtual children list when [loop] is
  /// true. Small enough to keep build cheap; large enough that
  /// reaching either edge requires intentional scrolling.
  static const int _loopFactor = 11;
  int get _virtualCount =>
      widget.loop ? widget.items.length * _loopFactor : widget.items.length;
  int get _loopOrigin => widget.items.length * (_loopFactor ~/ 2);

  // ─── Story mode ────────────────────────────────
  AnimationController? _storyCtrl;
  bool _storyPaused = false;
  bool _storyCompleteFired = false;

  // ─── Thumbnail strip ───────────────────────────
  ScrollController? _thumbCtrl;
  int _thumbLastTarget = -1;
  static const double _kThumbTileWidth = 64;
  static const double _kThumbStripPad = 12;
  static const double _kThumbSeparator = 6;

  final FocusNode _keyboardFocus = FocusNode(debugLabel: 'GlobalCarouselView');

  Duration _storyDurationFor(int logicalIndex) {
    final list = widget.storyDurations;
    if (list != null && logicalIndex >= 0 && logicalIndex < list.length) {
      return list[logicalIndex];
    }
    return widget.storyDefaultDuration;
  }

  void _initStoryCtrl() {
    final duration = _storyDurationFor(_current);
    _storyCtrl = AnimationController(vsync: this, duration: duration)
      ..addStatusListener(_onStoryStatus)
      ..addListener(_onStoryTick);
    _storyCtrl!.forward();
  }

  void _resetStoryCtrl() {
    if (_storyCtrl == null) return;
    _storyCtrl!.duration = _storyDurationFor(_current);
    _storyCtrl!
      ..reset()
      ..forward();
    _storyCompleteFired = false;
  }

  void _onStoryStatus(AnimationStatus status) {
    if (status != AnimationStatus.completed) return;
    final n = widget.items.length;
    if (n == 0) return;
    final atEnd = !widget.loop && _current >= n - 1;
    if (atEnd) {
      if (!_storyCompleteFired) {
        _storyCompleteFired = true;
        widget.onStoryComplete?.call();
      }
      return;
    }
    animateToPage(widget.loop ? (_current + 1) % n : _current + 1);
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
    if (_thumbLastTarget == _current) return;
    _thumbLastTarget = _current;
    final viewport = ctrl.position.viewportDimension;
    const tileStride = _kThumbTileWidth + _kThumbSeparator;
    final activeCenter =
        _kThumbStripPad + _current * tileStride + _kThumbTileWidth / 2;
    final desiredOffset = (activeCenter - viewport / 2).clamp(
      ctrl.position.minScrollExtent,
      ctrl.position.maxScrollExtent,
    );
    ctrl.animateTo(
      desiredOffset,
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  void initState() {
    super.initState();
    _ctrl =
        widget.controller ??
        CarouselController(initialItem: widget.loop ? _loopOrigin : 0);
    _ownsCtrl = widget.controller == null;
    _ctrl.addListener(_onScroll);
    _attach(widget.viewController);
    if (widget.storyMode && widget.items.isNotEmpty) _initStoryCtrl();
  }

  @override
  void didUpdateWidget(GlobalCarouselView<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.viewController != widget.viewController) {
      oldWidget.viewController?.detach(owner: this);
      _attach(widget.viewController);
    }
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller?.removeListener(_onScroll);
      _ctrl.removeListener(_onScroll);
      _ctrl =
          widget.controller ??
          CarouselController(initialItem: widget.loop ? _loopOrigin : 0);
      _ownsCtrl = widget.controller == null;
      _ctrl.addListener(_onScroll);
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
    widget.viewController?.detach(owner: this);
    _autoPlayTimer?.cancel();
    _ctrl.removeListener(_onScroll);
    if (_ownsCtrl) _ctrl.dispose();
    _storyCtrl?.dispose();
    _thumbCtrl?.dispose();
    _keyboardFocus.dispose();
    super.dispose();
  }

  /// Schedules a one-shot clamp on the next idle frame — if the
  /// scroll position settles past `maxScrollExtent` (CarouselView's
  /// asymmetric overscroll bug at the trailing edge), jump it back
  /// to bounds. Doesn't interfere with the bounce animation itself,
  /// so the fling still feels springy.
  bool _settleClampScheduled = false;
  void _maybeClampOnSettle() {
    if (_settleClampScheduled) return;
    // `positions.length`, not `hasClients`: `.position` asserts with
    // more than one attached view, and this carousel briefly has two
    // whenever the `Stack` around it changes depth.
    if (!_hasSinglePosition) return;
    final pos = _ctrl.position;
    if (pos.maxScrollExtent <= 0) return;
    if (pos.pixels <= pos.maxScrollExtent + 0.5) return;
    _settleClampScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _settleClampScheduled = false;
      if (!mounted || !_hasSinglePosition) return;
      final p = _ctrl.position;
      final scrolling = p.isScrollingNotifier.value;
      if (!scrolling && p.pixels > p.maxScrollExtent + 0.5) {
        _ctrl.jumpTo(p.maxScrollExtent);
      } else if (scrolling && p.pixels > p.maxScrollExtent + 0.5) {
        _maybeClampOnSettle();
      }
    });
  }

  /// If looping and the position is near either virtual edge, jump
  /// back to the equivalent slot in the middle so the user can keep
  /// scrolling either direction. Only runs once scroll has settled.
  bool _loopRecenterScheduled = false;
  void _maybeRecenterLoop() {
    if (!widget.loop) return;
    if (_loopRecenterScheduled) return;
    if (!_hasSinglePosition) return;
    final pos = _ctrl.position;
    final n = widget.items.length;
    final virtualN = _virtualCount;
    if (n == 0 || virtualN <= 0 || pos.maxScrollExtent <= 0) return;
    final stride = pos.maxScrollExtent / (virtualN - 1).clamp(1, virtualN);
    final virtualPos = pos.pixels / stride;
    // Only recenter when within `n` items of either virtual edge.
    final tooLow = virtualPos < n.toDouble();
    final tooHigh = virtualPos > (virtualN - 1 - n).toDouble();
    if (!tooLow && !tooHigh) return;
    _loopRecenterScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loopRecenterScheduled = false;
      if (!mounted || !_hasSinglePosition) return;
      final p = _ctrl.position;
      if (p.isScrollingNotifier.value) {
        _maybeRecenterLoop();
        return;
      }
      final s = p.maxScrollExtent / (virtualN - 1).clamp(1, virtualN);
      final vp = p.pixels / s;
      // Snap to the same logical slot but in the middle copy.
      final logical = ((vp.round() % n) + n) % n;
      final targetVirtual = _loopOrigin + logical;
      final targetOffset = targetVirtual * s;
      _ctrl.jumpTo(targetOffset.clamp(0, p.maxScrollExtent));
    });
  }

  void _onScroll() {
    if (!_ctrl.hasClients || widget.items.isEmpty) return;
    final n = widget.items.length;
    final virtualN = _virtualCount;
    if (n <= 1) return;
    final maxExtent = _ctrl.position.maxScrollExtent;
    if (maxExtent <= 0) return;
    _maybeClampOnSettle();
    _maybeRecenterLoop();
    // Map scroll offset → virtual index → logical index.
    //
    // The framework's OWN arithmetic, replicated: a carousel position
    // works out its leading item as
    // `pixels / (viewport * weights.first / weights.sum)`, and
    // `animateToItem` targets the largest-weight slot. Deriving the
    // index from `maxScrollExtent / (n - 1)` instead assumed the last
    // item sits at the end of the scroll — true only when one item
    // fills the viewport — so a uniform-weight deck reported item 4
    // for a scroll that had reached item 2.
    final viewport = _ctrl.position.viewportDimension;
    if (viewport <= 0) return;
    final weights = widget.flexWeights;
    final weightSum = weights.isEmpty
        ? 1
        : weights.fold<int>(0, (sum, w) => sum + w);
    final fraction = weights.isEmpty ? 1.0 : weights.first / weightSum;
    final slot = viewport * fraction;
    if (slot <= 0) return;
    final leading = (_ctrl.offset < 0 ? 0.0 : _ctrl.offset) / slot;
    // NO hero offset. `animateToItem` already leaves its target as
    // the LEADING item — the slot arithmetic is on its side of the
    // fence — so adding the hero slot here counted it twice and every
    // weighted landing read one high.
    final virtualPos = leading.clamp(0.0, (virtualN - 1).toDouble());
    final logicalContinuous = ((virtualPos % n) + n) % n;
    final next = logicalContinuous.round() % n;
    if (next != _current ||
        (logicalContinuous - _continuousIndex).abs() > 0.001) {
      setState(() {
        _continuousIndex = logicalContinuous;
        if (next != _current) {
          _current = next;
          widget.onPageChanged?.call(next);
          widget.viewController?.notify();
          _maybeTick();
          if (widget.storyMode) _resetStoryCtrl();
          if (widget.thumbnailBuilder != null) {
            WidgetsBinding.instance.addPostFrameCallback(
              (_) => _centerThumbnail(),
            );
          }
        }
      });
    }
  }

  /// Animate to the LOGICAL page index. In loop mode, finds the
  /// nearest virtual cell to minimize animation distance.
  /// [duration] and [curve] default to the resolved bag, so a house
  /// sets the pace once — and reduced motion zeroes them.
  ///
  /// Driven BY ITEM, not by a pixel offset.
  ///
  /// It used to compute an offset from `maxScrollExtent` — and that
  /// extent MOVES while the carousel scrolls, because a weighted
  /// layout resizes as the hero slot grows and the peeks shrink (533
  /// to 178 on a five-item deck, measured). The offset was right for
  /// the extent it was computed from and meant a different item by the
  /// time it arrived: asking for item 1 landed on item 3, and the
  /// readback divided by the NEW extent, so the two disagreed by
  /// construction. `CarouselController.animateToItem` knows the
  /// weights and does the arithmetic against the layout it actually
  /// has.
  Future<void> animateToPage(
    int target, {
    Duration? duration,
    Curve? curve,
  }) async {
    duration ??= _rs.pageDuration;
    curve ??= _rs.pageCurve;
    if (!_hasSinglePosition || widget.items.isEmpty) return;
    final n = widget.items.length;
    if (n <= 1) return;
    final clamped = target.clamp(0, n - 1);
    if (!widget.loop) {
      await _ctrl.animateToItem(clamped, duration: duration, curve: curve);
      return;
    }
    // Looping rides a virtual list, so the ITEM asked for is the
    // nearest virtual slot showing that logical index — otherwise a
    // wrap would rewind the whole strip.
    final virtualN = _virtualCount;
    final maxExtent = _ctrl.position.maxScrollExtent;
    if (maxExtent <= 0) return;
    final stride = maxExtent / (virtualN - 1).clamp(1, virtualN);
    final currentVirtual = (_ctrl.offset / stride).round();
    final currentLogical = ((currentVirtual % n) + n) % n;
    final targetVirtual = (currentVirtual + (clamped - currentLogical)).clamp(
      0,
      virtualN - 1,
    );
    await _ctrl.animateToItem(
      targetVirtual,
      duration: duration,
      curve: curve,
    );
  }

  void jumpToPage(int target) {
    if (!_ctrl.hasClients || widget.items.isEmpty) return;
    final n = widget.items.length;
    final virtualN = _virtualCount;
    if (n <= 1) return;
    final maxExtent = _ctrl.position.maxScrollExtent;
    if (maxExtent <= 0) return;
    final clamped = target.clamp(0, n - 1);
    final stride = maxExtent / (virtualN - 1).clamp(1, virtualN);
    if (widget.loop) {
      final targetVirtual = _loopOrigin + clamped;
      _ctrl.jumpTo(targetVirtual * stride);
    } else {
      _ctrl.jumpTo((clamped / (n - 1)) * maxExtent);
    }
  }

  @override
  Widget build(BuildContext context) {
    scheduleChromeMeasure(
      hasChrome: widget.headerBuilder != null || widget.footerBuilder != null,
    );
    final n = widget.items.length;
    if (n == 0) return const SizedBox.expand();
    return _buildBody(context, n);
  }

  Widget _buildBody(BuildContext context, int n) {
    final virtualN = _virtualCount;
    Widget body = CarouselView.weighted(
      controller: _ctrl,
      flexWeights: widget.flexWeights,
      scrollDirection: widget.scrollDirection,
      reverse: widget.reverse,
      padding: widget.padding,
      elevation: widget.elevation,
      shape: widget.shape,
      backgroundColor: widget.backgroundColor,
      itemSnapping: widget.itemSnapping,
      shrinkExtent: widget.shrinkExtent,
      onTap: widget.onTap == null
          ? null
          : (rawIndex) {
              final logical = widget.loop ? ((rawIndex % n) + n) % n : rawIndex;
              widget.onTap!(logical);
            },
      children: [
        for (var i = 0; i < virtualN; i++)
          widget.itemBuilder(context, widget.items[i % n], i % n),
      ],
    );

    // Story tap halves + hold overlay.
    if (widget.storyMode &&
        (widget.storyTapToAdvance || widget.storyPauseOnHold)) {
      body = Stack(
        fit: StackFit.expand,
        children: [
          Positioned.fill(child: body),
          if (widget.storyTapToAdvance)
            Positioned.fill(
              child: Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      behavior: HitTestBehavior.translucent,
                      onTap: () {
                        final target = widget.loop
                            ? (_current - 1 + n) % n
                            : (_current - 1).clamp(0, n - 1);
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
                            ? (_current + 1) % n
                            : (_current + 1).clamp(0, n - 1);
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

    // Indicator overlay.
    if (widget.showIndicator && n > 1) {
      final overlay =
          widget.indicatorBuilder?.call(context, _current, n) ??
          (widget.storyMode
              ? GlobalStoryIndicator(
                  count: n,
                  activeIndex: _current,
                  progress: _storyCtrl?.value ?? 0,
                  onTap: (i) => animateToPage(i),
                )
              : PageIndicatorOverlay(
                  style: _rs,
                  axis: widget.scrollDirection,
                  current: _current,
                  total: n,
                  continuousIndex: _continuousIndex,
                  onTap: (i) => animateToPage(i),
                ));
      body = Stack(
        alignment: widget.storyMode
            ? AlignmentDirectional.topCenter
            : _rs.indicatorAlignment,
        children: [
          Positioned.fill(child: body),
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
      body = Stack(
        fit: StackFit.expand,
        children: [
          Positioned.fill(child: body),
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
                  child: widget.headerBuilder!(context, _current, n),
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
                  child: widget.footerBuilder!(context, _current, n),
                ),
              ),
            ),
        ],
      );
    }

    // Thumbnail strip.
    if (widget.thumbnailBuilder != null) {
      _thumbCtrl ??= ScrollController();
      body = Stack(
        fit: StackFit.expand,
        children: [
          Positioned.fill(child: body),
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
                      child: widget.thumbnailBuilder!(ctx, i, i == _current),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      );
    }

    if (widget.enableKeyboardNav) {
      body = Focus(
        focusNode: _keyboardFocus,
        // NOT autofocus — it stole focus from whatever the reader was
        // on the moment the carousel was built.
        onKeyEvent: _onKey,
        child: body,
      );
    }

    // A finger holds an auto-playing strip too — a carousel that turns
    // under a thumb is the same complaint as a story that does.
    if (widget.autoPlay || (widget.storyMode && widget.storyPauseOnHold)) {
      body = Listener(
        onPointerDown: (_) => _setPointerHeld(held: true),
        onPointerUp: (_) => _setPointerHeld(held: false),
        onPointerCancel: (_) => _setPointerHeld(held: false),
        child: body,
      );
    }

    if (widget.pauseWhenOffscreen && (widget.storyMode || widget.autoPlay)) {
      body = VisibilityDetector(
        key: ValueKey<String>('gcv_${identityHashCode(this)}'),
        onVisibilityChanged: (info) {
          if (!mounted) return;
          final offscreen = info.visibleFraction == 0;
          if (_pausedByOffscreen == offscreen) return;
          _pausedByOffscreen = offscreen;
          _syncClock();
        },
        child: body,
      );
    }

    // ONE node for the whole carousel — it had none, and a swipe is
    // invisible to a screen reader.
    final count = widget.items.length;
    return Semantics(
      container: true,
      label: ListStrings.pageOf(_current + 1, count),
      value: '${_current + 1}',
      increasedValue: '${(_current + 2).clamp(1, count)}',
      decreasedValue: '${_current.clamp(1, count)}',
      onIncrease: count > 1 ? () => _step(1) : null,
      onDecrease: count > 1 ? () => _step(-1) : null,
      child: body,
    );
  }

  KeyEventResult _onKey(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
      return KeyEventResult.ignored;
    }
    final n = widget.items.length;
    if (n == 0) return KeyEventResult.ignored;
    final isVertical = widget.scrollDirection == Axis.vertical;
    // MIRRORED — a horizontal carousel in Arabic advances leftward, so
    // LEFT is "next". A vertical one keeps its keys.
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
