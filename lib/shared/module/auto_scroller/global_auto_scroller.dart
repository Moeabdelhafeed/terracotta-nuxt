import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/semantics.dart' show CustomSemanticsAction;
import 'package:visibility_detector/visibility_detector.dart';

import '../../../core/localization/strings/common_strings.dart';
import 'auto_scroller_controller.dart';
import 'auto_scroller_models.dart';
import 'theme/auto_scroller_theme.dart';

export 'auto_scroller_controller.dart';
export 'auto_scroller_models.dart';
export 'theme/auto_scroller_theme.dart';

/// Builds the scrollable this widget drives.
///
/// [still] is the reader's reduced-motion answer, and it is here
/// because only the CALLER can act on it: a parked rail whose list was
/// given `NeverScrollableScrollPhysics` has put its content out of
/// reach of every gesture, and the module cannot reach into a
/// caller's widget to hand the physics back.
///
/// ```dart
/// builder: (ctx, ctrl, still) => ListView(
///   controller: ctrl,
///   physics: still ? null : const NeverScrollableScrollPhysics(),
///   ...
/// )
/// ```
typedef AutoScrollerBuilder =
    Widget Function(
      BuildContext context,
      ScrollController controller,
      bool still,
    );

/// How many copies of the content [GlobalAutoScroller.looping] builds.
///
/// The wrap is a jump of exactly ONE lap, which is invisible because
/// the pixels either side of it are the same pixels. The count only
/// decides how long the drive can run before it has to jump at all —
/// two hundred laps of a twenty-item rail is days.
const int _kLoopLaps = 200;

/// A tick longer than this did not happen — the drive was stopped and
/// something restarted the clock behind it.
///
/// `TickerMode` MUTES a ticker under a covered route rather than
/// stopping it, and `Ticker.elapsed` keeps counting real time while
/// muted, so returning to a route after three seconds handed the first
/// frame three seconds of travel (measured: 310 pixels at 100 px/s).
/// The hold path resets the clock itself; this catches every path that
/// cannot — mute, a debugger pause, a janked frame.
const Duration _kMaxTickDelta = Duration(milliseconds: 100);

/// Ambient scroll DRIVER. It owns no content: it hands a
/// [ScrollController] to a builder and advances that controller every
/// frame.
///
/// ```dart
/// GlobalAutoScroller(
///   builder: (ctx, controller, still) =>
///       GlobalList.static(scrollController: controller, ...),
/// )
/// ```
///
/// **Not the same thing as `GlobalMarquee`.** A marquee owns its child,
/// MEASURES it, and scrolls only when the content is actually
/// concealed — a title that fits stays still. This never measures: it
/// moves whatever the caller built, for as long as it is told to. And
/// neither is the page family's `autoPlay`, which jumps whole pages on
/// an interval rather than scrolling by pixels.
///
/// The caller MUST forward the controller to their scrollable.
/// Without that there is nothing to advance and this is an expensive
/// no-op.
///
/// Visual configuration is the themeable bag [AutoScrollerStyle] —
/// `caller > GlobalAutoScrollerTheme.style > AutoScrollerStyle.defaults`.
class GlobalAutoScroller extends StatefulWidget {
  const GlobalAutoScroller({
    required this.builder,
    this.style = const AutoScrollerStyle(),
    this.controller,
    this.autoScrollController,
    this.enabled = true,
    this.reverse = false,
    this.pauseWhenOffscreen = true,
    this.startOffset = 0,
    this.onEdge,
    this.semanticsLabel,
    super.key,
  }) : loopItemCount = null,
       loopItemExtent = null,
       loopItemBuilder = null,
       loopAxis = Axis.horizontal;

  /// A rail whose wrap is SEAMLESS.
  ///
  /// [AutoScrollLoopMode.wrap] jumps back to the start, and that jump
  /// is visible — the content at the end and the content at the
  /// beginning are different pixels. A ticker that reads as endless
  /// needs the content REPEATED, and a driver that owns no content
  /// cannot repeat it. This constructor owns just enough of it to:
  /// it builds the list itself, [_kLoopLaps] copies of it, and wraps
  /// by exactly one lap — a jump between two identical frames.
  ///
  /// [itemExtent] is required rather than measured. `ListView.builder`
  /// ESTIMATES `maxScrollExtent` from the items it has built so far,
  /// and that estimate moves as the drive scrolls; a lap computed
  /// from a moving number is a lap that does not line up. With an
  /// extent the arithmetic is exact.
  ///
  /// [AutoScrollerStyle.loopMode] does not apply — this deck has no
  /// end to reach.
  const GlobalAutoScroller.looping({
    required int itemCount,
    required double itemExtent,
    required IndexedWidgetBuilder itemBuilder,
    Axis scrollDirection = Axis.horizontal,
    this.style = const AutoScrollerStyle(),
    this.controller,
    this.autoScrollController,
    this.enabled = true,
    this.reverse = false,
    this.pauseWhenOffscreen = true,
    this.startOffset = 0,
    this.onEdge,
    this.semanticsLabel,
    super.key,
  }) : assert(itemCount > 0, 'a looping rail needs something to loop'),
       assert(itemExtent > 0, 'itemExtent must be a real size'),
       loopItemCount = itemCount,
       loopItemExtent = itemExtent,
       loopItemBuilder = itemBuilder,
       loopAxis = scrollDirection,
       builder = _unusedBuilder;

  static Widget _unusedBuilder(BuildContext _, ScrollController _, bool _) =>
      const SizedBox.shrink();

  /// Builds the scrollable child with the controller this widget
  /// drives. Forward it, or nothing moves.
  final AutoScrollerBuilder builder;

  final AutoScrollerStyle style;

  /// An external `ScrollController` to drive instead of making one —
  /// for a caller that already has one for snapping or restoration.
  final ScrollController? controller;

  /// Holds and releases the drive from outside the tree.
  final GlobalAutoScrollerController? autoScrollController;

  /// A plain on / off switch. Distinct from the controller's hold:
  /// this is the caller's configuration, that is a temporary grip.
  final bool enabled;

  /// Runs from the end toward the start.
  final bool reverse;

  /// Whether the drive stops while it is scrolled out of view.
  ///
  /// `TickerMode` only covers a covered ROUTE, so an ambient rail
  /// still built and merely off screen went on burning a frame a tick
  /// for something nobody could see.
  final bool pauseWhenOffscreen;

  /// Where the scroll starts on first attach.
  final double startOffset;

  /// Fires when the drive reaches an end — once per arrival, whatever
  /// the loop mode does next. For rotating the content behind an
  /// endless rail, or for logging that a `stop` run finished.
  final void Function(AutoScrollEdge edge)? onEdge;

  /// Names the rail for a screen reader. The pause / resume actions
  /// are published whether or not this is set; a name only makes them
  /// easier to find.
  final String? semanticsLabel;

  // ─── .looping only ──────────────────────────────────────────
  final int? loopItemCount;
  final double? loopItemExtent;
  final IndexedWidgetBuilder? loopItemBuilder;
  final Axis loopAxis;

  bool get isLooping => loopItemBuilder != null;

  @override
  State<GlobalAutoScroller> createState() => _GlobalAutoScrollerState();
}

class _GlobalAutoScrollerState extends State<GlobalAutoScroller>
    with SingleTickerProviderStateMixin {
  late ResolvedAutoScrollerStyle _rs;

  late ScrollController _ctrl;
  bool _ownsCtrl = false;
  late Ticker _ticker;
  Duration _lastTickAt = Duration.zero;

  /// Set when a `stop` loop has reached the end. Only [restart] and a
  /// rebuild clear it.
  bool _finished = false;

  /// Live direction — flips when `bounce` hits an edge.
  bool _runningReverse = false;

  /// Which edge [onEdge] last reported, so an arrival is announced
  /// once rather than every frame a `stop` sits there.
  AutoScrollEdge? _reportedEdge;

  // ─── What is holding the drive ─────────────────────────────
  // Five flags rather than one, because they overlap: a finger can go
  // down while the rail is off screen, and lifting it must not start
  // something nobody can see.
  bool _heldByPointer = false;
  bool _heldByHover = false;
  bool _heldByOffscreen = false;
  bool _heldByCaller = false;

  /// The READER's own hold, through the semantics action. Separate
  /// from the caller's on purpose: a screen that resumes its rail
  /// programmatically must not undo the reader's decision to stop it.
  bool _heldByReader = false;

  /// Cleared once [AutoScrollerStyle.startDelay] has passed.
  bool _startDelayDone = false;
  Timer? _startTimer;

  /// Releases [_heldByPointer] after the reader lets go.
  ///
  /// A cancellable TIMER, not `Future.delayed`: a future cannot be
  /// called off, so every touch scheduled another and each one held
  /// the State alive until it fired.
  Timer? _resumeTimer;

  bool get _held =>
      _heldByPointer ||
      _heldByHover ||
      _heldByOffscreen ||
      _heldByCaller ||
      _heldByReader;

  /// Whether the drive is actually advancing.
  bool get _running =>
      widget.enabled &&
      _startDelayDone &&
      !_held &&
      !_finished &&
      _rs.speed > 0;

  /// One lap of a `.looping` rail, in pixels. Exact, because
  /// `itemExtent` is given rather than estimated.
  double get _lapExtent => widget.loopItemCount! * widget.loopItemExtent!;

  double get _loopSeed => _lapExtent * (_kLoopLaps ~/ 2);

  @override
  void initState() {
    super.initState();
    final initial = widget.isLooping
        ? _loopSeed + widget.startOffset
        : widget.startOffset;
    _ctrl = widget.controller ?? ScrollController(initialScrollOffset: initial);
    _ownsCtrl = widget.controller == null;
    _runningReverse = widget.reverse;
    _ticker = createTicker(_onTick);
    _attach(widget.autoScrollController);
    if (widget.isLooping && !_ownsCtrl) {
      // A caller's controller cannot be seeded before it has a
      // position, so it is seeded on the first frame instead.
      WidgetsBinding.instance.addPostFrameCallback((_) => _seedLoop(initial));
    }
    // The ticker is NOT started here: whether it should run at all
    // depends on the resolved speed, and the bag is resolved in
    // `didChangeDependencies`, which runs after this.
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Here, not `initState`: the theme extension,
    // `disableAnimationsOf` and `accessibleNavigationOf` are all
    // inherited reads.
    _rs = widget.style.resolve(context);
    _syncStartDelay();
    _syncAccessibleHold();
    _syncTicker();
  }

  @override
  void didUpdateWidget(GlobalAutoScroller old) {
    super.didUpdateWidget(old);
    if (old.style != widget.style) {
      _rs = widget.style.resolve(context);
      _syncStartDelay();
      _syncAccessibleHold();
    }
    if (old.autoScrollController != widget.autoScrollController) {
      old.autoScrollController?.detach(owner: this);
      _attach(widget.autoScrollController);
    }
    if (old.reverse != widget.reverse) _runningReverse = widget.reverse;
    if (old.enabled != widget.enabled) _finished = false;
    _syncTicker();
  }

  @override
  void dispose() {
    widget.autoScrollController?.detach(owner: this);
    _resumeTimer?.cancel();
    _startTimer?.cancel();
    _ticker.dispose();
    if (_ownsCtrl) _ctrl.dispose();
    super.dispose();
  }

  void _seedLoop(double offset) {
    if (!mounted || !_hasSinglePosition) return;
    if (_ctrl.offset >= _lapExtent) return;
    _ctrl.jumpTo(offset.clamp(0.0, _ctrl.position.maxScrollExtent));
  }

  void _attach(GlobalAutoScrollerController? controller) {
    controller?.attach(
      owner: this,
      setPaused: ({required bool paused}) {
        if (_heldByCaller == paused) return;
        _heldByCaller = paused;
        _syncTicker();
        controller.notify();
      },
      isRunning: () => _running,
      isPaused: () => _heldByCaller,
      restart: () {
        _finished = false;
        _reportedEdge = null;
        _runningReverse = widget.reverse;
        if (_hasSinglePosition) {
          _ctrl.jumpTo(
            widget.isLooping
                ? _loopSeed
                : widget.reverse
                ? _ctrl.position.maxScrollExtent
                : _ctrl.position.minScrollExtent,
          );
        }
        _syncTicker();
        controller.notify();
      },
    );
  }

  /// A screen reader walks content at its own pace, and a rail moving
  /// underneath it cannot be read — nor stopped, since a reader has no
  /// finger on the glass to hold it with.
  void _syncAccessibleHold() {
    final held =
        _rs.pauseWhenAccessibleNavigation &&
        MediaQuery.accessibleNavigationOf(context);
    if (_heldByAccessible == held) return;
    _heldByAccessible = held;
  }

  bool _heldByAccessible = false;

  void _syncStartDelay() {
    if (_rs.startDelay <= Duration.zero) {
      _startTimer?.cancel();
      _startDelayDone = true;
      return;
    }
    if (_startDelayDone || _startTimer != null) return;
    _startTimer = Timer(_rs.startDelay, () {
      if (!mounted) return;
      _startDelayDone = true;
      _syncTicker();
    });
  }

  /// The ONE place the ticker is started or stopped.
  void _syncTicker() {
    final shouldRun = _running && !_heldByAccessible;
    if (shouldRun && !_ticker.isActive) {
      // Reset the clock, or the first tick after a hold advances by
      // however long the hold lasted — a rail that was paused for a
      // minute jumped a minute's worth of pixels on release.
      _lastTickAt = Duration.zero;
      _ticker.start();
    } else if (!shouldRun && _ticker.isActive) {
      _ticker.stop();
    }
  }

  /// `ScrollController.position` asserts with more than one attached
  /// view, and a builder that rebuilds into a different tree shape
  /// briefly has two.
  bool get _hasSinglePosition => _ctrl.positions.length == 1;

  void _onTick(Duration elapsed) {
    if (!_running) {
      _lastTickAt = elapsed;
      return;
    }
    var delta = elapsed - _lastTickAt;
    _lastTickAt = elapsed;
    // A gap this long is a STALL, not travel — see [_kMaxTickDelta].
    if (delta > _kMaxTickDelta) delta = _kMaxTickDelta;
    final seconds = delta.inMicroseconds / 1000000.0;
    if (seconds <= 0 || !_hasSinglePosition) return;
    final pos = _ctrl.position;
    if (!pos.hasContentDimensions) return;

    final heading = _runningReverse ? -1 : 1;
    // The distance to the edge being APPROACHED — the only one the
    // easing is about.
    final toEdge = _runningReverse
        ? pos.pixels - pos.minScrollExtent
        : pos.maxScrollExtent - pos.pixels;
    // Never near a wrap: `wrap` teleports, and slowing into a
    // teleport advertises it. `.looping` has no edge at all.
    final ease = (widget.isLooping || _rs.loopMode == AutoScrollLoopMode.wrap)
        ? 1.0
        : _rs.easeFactorAt(toEdge);

    var next = pos.pixels + _rs.speed * ease * seconds * heading;

    if (widget.isLooping) {
      pos.jumpTo(_normalizeLap(next, pos));
      return;
    }

    if (next >= pos.maxScrollExtent) {
      _reportEdge(AutoScrollEdge.end);
      switch (_rs.loopMode) {
        case AutoScrollLoopMode.wrap:
          next = pos.minScrollExtent;
        case AutoScrollLoopMode.bounce:
          _runningReverse = true;
          next = pos.maxScrollExtent;
        case AutoScrollLoopMode.stop:
          _finished = true;
          next = pos.maxScrollExtent;
      }
    } else if (next <= pos.minScrollExtent) {
      _reportEdge(AutoScrollEdge.start);
      switch (_rs.loopMode) {
        case AutoScrollLoopMode.wrap:
          next = pos.maxScrollExtent;
        case AutoScrollLoopMode.bounce:
          _runningReverse = false;
          next = pos.minScrollExtent;
        case AutoScrollLoopMode.stop:
          _finished = true;
          next = pos.minScrollExtent;
      }
    } else {
      _reportedEdge = null;
    }

    pos.jumpTo(next);
    if (_finished) {
      _syncTicker();
      widget.autoScrollController?.notify();
    }
  }

  /// Keeps a looping rail inside the middle laps.
  ///
  /// The correction is exactly one lap, so the pixels before and after
  /// it are the same pixels and the jump cannot be seen.
  double _normalizeLap(double next, ScrollPosition pos) {
    final min = pos.minScrollExtent;
    final max = pos.maxScrollExtent;
    var value = next;
    while (value > max - _lapExtent) {
      value -= _lapExtent;
    }
    while (value < min + _lapExtent) {
      value += _lapExtent;
    }
    return value.clamp(min, max);
  }

  void _reportEdge(AutoScrollEdge edge) {
    if (_reportedEdge == edge) return;
    _reportedEdge = edge;
    widget.onEdge?.call(edge);
  }

  void _setHold(void Function() apply) {
    apply();
    _syncTicker();
    widget.autoScrollController?.notify();
  }

  void _setPointerHeld({required bool held}) {
    if (_heldByPointer == held) return;
    _setHold(() => _heldByPointer = held);
  }

  void _onPointerDown(PointerDownEvent _) {
    if (!_rs.pauseOnInteraction) return;
    _resumeTimer?.cancel();
    _setPointerHeld(held: true);
  }

  void _onPointerRelease() {
    if (!_rs.pauseOnInteraction) return;
    _resumeTimer?.cancel();
    _resumeTimer = Timer(_rs.resumeDelay, () {
      if (mounted) _setPointerHeld(held: false);
    });
  }

  void _setHoverHeld({required bool held}) {
    if (!_rs.pauseOnHover || _heldByHover == held) return;
    // No resume delay on the way out: the pointer has LEFT, which is
    // unambiguous in a way a lifted finger is not.
    _setHold(() => _heldByHover = held);
  }

  void _toggleReaderHold() => _setHold(() => _heldByReader = !_heldByReader);

  @override
  Widget build(BuildContext context) {
    var content = widget.isLooping ? _buildLoopingList() : _buildChild();

    content = Listener(
      onPointerDown: _onPointerDown,
      onPointerUp: (_) => _onPointerRelease(),
      onPointerCancel: (_) => _onPointerRelease(),
      child: content,
    );

    if (_rs.pauseOnHover) {
      content = MouseRegion(
        onEnter: (_) => _setHoverHeld(held: true),
        onExit: (_) => _setHoverHeld(held: false),
        child: content,
      );
    }

    // WCAG 2.2.2: content that moves by itself for more than five
    // seconds needs a mechanism to stop it, and a finger hold that
    // resumes on its own is not one for a reader with no finger on the
    // glass. Nothing is published when there is nothing moving.
    if (_rs.speed > 0 && widget.enabled) {
      content = Semantics(
        label: widget.semanticsLabel,
        customSemanticsActions: <CustomSemanticsAction, VoidCallback>{
          CustomSemanticsAction(
            label: _heldByReader ? CommonStrings.resume : CommonStrings.pause,
          ): _toggleReaderHold,
        },
        child: content,
      );
    }

    if (widget.pauseWhenOffscreen) {
      content = VisibilityDetector(
        key: ValueKey<String>('gas_${identityHashCode(this)}'),
        onVisibilityChanged: (info) {
          if (!mounted) return;
          final offscreen = info.visibleFraction == 0;
          if (_heldByOffscreen == offscreen) return;
          _setHold(() => _heldByOffscreen = offscreen);
        },
        child: content,
      );
    }
    return content;
  }

  Widget _buildChild() => widget.builder(context, _ctrl, _rs.still);

  Widget _buildLoopingList() => ListView.builder(
    controller: _ctrl,
    scrollDirection: widget.loopAxis,
    itemExtent: widget.loopItemExtent,
    itemCount: widget.loopItemCount! * _kLoopLaps,
    // A parked rail hands its physics back, or reduced motion would
    // put the content past the fold out of reach of every gesture.
    physics: _rs.still ? null : const NeverScrollableScrollPhysics(),
    itemBuilder: (ctx, i) =>
        widget.loopItemBuilder!(ctx, i % widget.loopItemCount!),
  );
}
