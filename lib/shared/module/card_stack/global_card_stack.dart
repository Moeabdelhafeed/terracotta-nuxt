import 'dart:math' as math;

import 'package:flutter/foundation.dart' show listEquals;
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart' show CustomSemanticsAction;
import 'package:flutter/services.dart'
    show
        HapticFeedback,
        HardwareKeyboard,
        KeyDownEvent,
        KeyEvent,
        KeyRepeatEvent,
        LogicalKeyboardKey;

import '../../../core/localization/strings/common_strings.dart';
import '../../../core/localization/strings/list_strings.dart';
import '../../../core/localization/strings/stack_strings.dart';
import '../empty_state/global_empty_state.dart';
import 'stack_models.dart';
import 'theme/stack_theme.dart';

export 'stack_models.dart';
export 'theme/stack_theme.dart';

/// Action emitted when the user taps the top card. Provided so
/// callers can build "tap to reveal" UI separate from the swipe
/// dismissal flow.
typedef CardStackTapHandler<T> = void Function(T item, int index);

/// Programmatic-control handle for [GlobalCardStack]. Pass into
/// the widget's `controller` to drive dismissal from outside —
/// useful when the caller renders custom "like / pass" buttons.
class GlobalCardStackController<T> extends ChangeNotifier {
  _GlobalCardStackState<T>? _state;

  void _attach(_GlobalCardStackState<T> state) {
    _state = state;
  }

  void _detach(_GlobalCardStackState<T> state) {
    if (_state == state) _state = null;
  }

  /// Dismiss the top card in the given direction with the same
  /// animation as a gesture-driven dismiss. No-op if the deck is
  /// empty or already dismissing.
  void dismiss(CardSwipeDirection direction) =>
      _state?.programmaticDismiss(direction);

  /// Undo the most recent dismissal — slides the previously-removed
  /// card back into the deck. No-op if nothing has been dismissed
  /// since `clearHistory()` was called.
  void undo() => _state?.undoLast();

  /// Drop the undo history. Call when you've consumed the cards
  /// elsewhere and no longer want users rewinding.
  void clearHistory() => _state?.clearHistory();

  bool get canUndo => _state?.canUndo ?? false;

  /// How many cards are left in the deck.
  int get remaining => _state?.remaining ?? 0;

  /// Internal: bumped by the state when deck mutates so any
  /// [Listenable] listeners (e.g. ValueListenableBuilder around
  /// [canUndo]) rebuild.
  void _bump() => notifyListeners();
}

/// Tinder-style swipeable card stack. The top card is gesture-
/// driven; underlying cards peek behind with a scale + offset.
/// Swiping past `swipeThreshold` — or FLICKING past `flingVelocity`
/// under it — dismisses the top card; anything less snaps back.
///
/// Distinct from `GlobalCarousel` / `GlobalPageView`: there's no
/// scroll axis, no PageController — every advance is a discrete
/// dismiss + reveal of the next card. And distinct from
/// `GlobalLayeredStack`, which draws the same depth but never
/// removes anything: this is a queue the reader CONSUMES, that one
/// is a pile they look at.
///
/// Visual configuration is the themeable bag [StackStyle], shared
/// with the layered stack —
/// `caller > GlobalStackTheme.style > StackStyle.defaults`.
class GlobalCardStack<T> extends StatefulWidget {
  const GlobalCardStack({
    required this.items,
    required this.itemBuilder,
    super.key,
    this.style = const StackStyle(),
    this.onSwipe,
    this.onDeckEmpty,
    this.onTap,
    this.controller,
    this.allowedDirections = const {
      CardSwipeDirection.left,
      CardSwipeDirection.right,
    },
    this.allowUndo = true,
    this.loop = false,
    this.semanticLabelBuilder,
    this.directionLabels = const {},
    this.onUndo,
    this.emptyBuilder,
    this.enableKeyboardNav = true,
  });

  /// Source deck. Top of the visible stack = `items.last`. Caller
  /// keeps ownership; widget never mutates this list directly.
  final List<T> items;

  /// Builds each visible card. Receives the item, its depth in the
  /// stack (0 = top, increasing downward), and the gesture's signed
  /// progress for the top card (`Offset(x, y)` in [-1..1] range).
  /// Non-top cards always receive `Offset.zero`.
  final Widget Function(
    BuildContext context,
    T item,
    int depth,
    Offset gesture,
  )
  itemBuilder;

  /// How the deck is BUILT — depth, timings, the swipe's thresholds.
  final StackStyle style;

  /// Fires when a card is dismissed. `direction` is the side the
  /// card flew toward. `index` is the position in [items] before
  /// removal.
  final void Function(T item, int index, CardSwipeDirection direction)? onSwipe;

  /// Fires once when the deck becomes empty.
  final VoidCallback? onDeckEmpty;

  /// Fires on top-card tap (release without exceeding the slop
  /// distance). Skipped on drag gestures.
  final CardStackTapHandler<T>? onTap;

  /// External handle for programmatic dismiss + undo. Optional.
  final GlobalCardStackController<T>? controller;

  /// Restrict swipe directions. Drags toward filtered axes still
  /// move the card visually, but won't dismiss past the threshold.
  final Set<CardSwipeDirection> allowedDirections;

  /// Enable [GlobalCardStackController.undo]. When `true`, dismissed
  /// items are kept in an internal history stack.
  final bool allowUndo;

  /// When `true`, a dismissed card is re-inserted at the BOTTOM of
  /// the deck instead of removed. Deck size stays constant; users
  /// can swipe forever. `onDeckEmpty` never fires, and nothing is
  /// recorded for undo — the card is still in the deck, so putting
  /// it back would deal a second copy of it.
  final bool loop;

  /// Names the top card for a screen reader — `(item, index)`.
  ///
  /// Without one the node says only its position in the deck, which
  /// tells a reader there is a card but not what is on it.
  final String Function(T item, int index)? semanticLabelBuilder;

  /// Fires when a dismissal is rewound, with the card that came back.
  ///
  /// `onSwipe` had no opposite, so a caller that sent a request when a
  /// card left had no hook to call it off.
  final void Function(T item, int index, CardSwipeDirection direction)? onUndo;

  /// Drawn when the deck runs out.
  ///
  /// It used to be a blank box — `SizedBox.expand()` and nothing else —
  /// on the one screen in the app where running out is the EXPECTED
  /// ending. The default is the app's own empty state.
  final WidgetBuilder? emptyBuilder;

  /// Whether arrow keys deal the top card.
  ///
  /// A swipe deck reached by swipe alone is unusable with a keyboard,
  /// which on desktop and web is most of the ways in. Focus is taken
  /// by TAB, never on mount.
  final bool enableKeyboardNav;

  /// Renames a swipe for a screen reader.
  ///
  /// The default labels say the GESTURE (`Swipe left`), which is the
  /// only honest thing a module can say — it has no idea what left
  /// means on this screen. A caller does: `Pass`, `Save for later`,
  /// `Archive`. This is where the meaning goes.
  final Map<CardSwipeDirection, String> directionLabels;

  @override
  State<GlobalCardStack<T>> createState() => _GlobalCardStackState<T>();
}

class _GlobalCardStackState<T> extends State<GlobalCardStack<T>>
    with TickerProviderStateMixin {
  late ResolvedStackStyle _rs;

  /// Working copy of the deck. Removed cards are popped from the
  /// end (top of stack). Caller's `items` is rebuilt-from when
  /// [didUpdateWidget] sees a new instance.
  late List<T> _deck;

  /// Undo history — `(item, indexAtRemoval, directionFlownToward)`.
  final List<_DismissedRecord<T>> _history = [];

  /// Gesture state for the top card. `_drag` accumulates pointer
  /// delta from the gesture start; `Offset.zero` when idle.
  Offset _drag = Offset.zero;

  /// Snap-back animation. Drives `_drag` from current value to
  /// `Offset.zero` after release if below threshold.
  late AnimationController _snapCtrl;
  Animation<Offset>? _snapAnim;

  /// Fly-away animation. Drives `_drag` from release value past
  /// the edge before the card is popped from the deck.
  late AnimationController _flyCtrl;
  Animation<Offset>? _flyAnim;
  CardSwipeDirection? _flyDirection;

  final FocusNode _keyboardFocus = FocusNode(debugLabel: 'card stack');

  @override
  void initState() {
    super.initState();
    _deck = List<T>.from(widget.items);
    // Durations come from the bag, which needs the context — so the
    // controllers are created bare and timed in
    // `didChangeDependencies`. Reading `_rs` here is the
    // LateInitializationError the page family and the carousel both
    // shipped.
    _snapCtrl = AnimationController(vsync: this)..addListener(_handleSnapTick);
    _flyCtrl = AnimationController(vsync: this)
      ..addListener(_handleFlyTick)
      ..addStatusListener(_handleFlyStatus);
    widget.controller?._attach(this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _rs = widget.style.resolve(context);
    _syncDurations();
  }

  @override
  void didUpdateWidget(GlobalCardStack<T> old) {
    super.didUpdateWidget(old);
    if (old.style != widget.style) {
      _rs = widget.style.resolve(context);
      _syncDurations();
    }
    // By VALUE, not by identity. A caller who builds their list in
    // `build()` — the normal thing — handed over a new instance every
    // frame, so any unrelated rebuild anywhere up the tree put the
    // dismissed cards back and wiped the undo history. Measured: an
    // unrelated `setState` took the deck from 2 back to 3.
    if (!listEquals(old.items, widget.items)) {
      // Caller swapped the deck. Reset gesture + history.
      _deck = List<T>.from(widget.items);
      _drag = Offset.zero;
      _snapCtrl.stop();
      _flyCtrl.stop();
      _flyDirection = null;
      _history.clear();
    }
    if (old.controller != widget.controller) {
      old.controller?._detach(this);
      widget.controller?._attach(this);
    }
  }

  void _syncDurations() {
    _snapCtrl.duration = _rs.snapDuration;
    _flyCtrl.duration = _rs.dismissDuration;
  }

  @override
  void dispose() {
    widget.controller?._detach(this);
    _keyboardFocus.dispose();
    _snapCtrl.dispose();
    _flyCtrl.dispose();
    super.dispose();
  }

  bool get canUndo =>
      widget.allowUndo && _rs.undoLimit > 0 && _history.isNotEmpty;
  int get remaining => _deck.length;

  // ─── Snap-back ─────────────────────────────────────────────

  void _handleSnapTick() {
    if (_snapAnim == null) return;
    setState(() => _drag = _snapAnim!.value);
  }

  void _startSnapBack() {
    if (_rs.still) {
      // Zero-duration controllers never tick, so there would be no
      // frame to put the card back on.
      setState(() => _drag = Offset.zero);
      return;
    }
    _snapAnim = Tween<Offset>(begin: _drag, end: Offset.zero).animate(
      CurvedAnimation(parent: _snapCtrl, curve: _rs.curve),
    );
    _snapCtrl
      ..reset()
      ..forward();
  }

  // ─── Fly-away dismiss ──────────────────────────────────────

  void _handleFlyTick() {
    if (_flyAnim == null) return;
    setState(() => _drag = _flyAnim!.value);
  }

  void _handleFlyStatus(AnimationStatus status) {
    if (status != AnimationStatus.completed) return;
    _finalizeDismiss();
  }

  /// Commits the dismissal: pops the top card, fires callbacks,
  /// optionally re-inserts at bottom for loop mode. Called from
  /// the fly-out completion handler AND from `_onDragStart` when
  /// the user kicks off a new swipe before the previous fly-out
  /// has finished — lets them chain swipes back-to-back.
  void _finalizeDismiss() {
    final dir = _flyDirection;
    if (dir == null || _deck.isEmpty) {
      _flyDirection = null;
      return;
    }
    final removedIndex = _deck.length - 1;
    final removed = _deck.removeLast();
    // NOT recorded when looping: the card is going straight back to
    // the bottom of the deck, so an undo would insert a SECOND copy
    // of an item that never left. The deck grew by one every time.
    if (widget.allowUndo && !widget.loop && _rs.undoLimit > 0) {
      _history.add(
        _DismissedRecord(
          item: removed,
          indexAtRemoval: removedIndex,
          direction: dir,
        ),
      );
      // The oldest falls off the end — a triage session that dealt a
      // thousand cards used to keep every one of them.
      if (_history.length > _rs.undoLimit) _history.removeAt(0);
    }
    widget.onSwipe?.call(removed, removedIndex, dir);
    if (widget.loop) {
      _deck.insert(0, removed);
    } else if (_deck.isEmpty) {
      widget.onDeckEmpty?.call();
    }
    setState(() {
      _drag = Offset.zero;
      _flyDirection = null;
    });
    widget.controller?._bump();
  }

  Offset _exitTargetFor(CardSwipeDirection dir, Size box) {
    final width = box.width;
    final height = box.height;
    switch (dir) {
      case CardSwipeDirection.left:
        return Offset(-width * 1.5, _drag.dy);
      case CardSwipeDirection.right:
        return Offset(width * 1.5, _drag.dy);
      case CardSwipeDirection.up:
        return Offset(_drag.dx, -height * 1.5);
      case CardSwipeDirection.down:
        return Offset(_drag.dx, height * 1.5);
    }
  }

  void _startFly(CardSwipeDirection dir, Size box) {
    _flyDirection = dir;
    if (_rs.enableHaptic) HapticFeedback.selectionClick();
    if (_rs.still) {
      // No travel to animate — the card is simply gone.
      _finalizeDismiss();
      return;
    }
    _flyAnim = Tween<Offset>(
      begin: _drag,
      end: _exitTargetFor(dir, box),
    ).animate(CurvedAnimation(parent: _flyCtrl, curve: _rs.curve));
    _flyCtrl
      ..reset()
      ..forward();
  }

  Size get _boxSize =>
      (context.findRenderObject() as RenderBox?)?.size ?? const Size(360, 480);

  void programmaticDismiss(CardSwipeDirection direction) {
    if (_deck.isEmpty || _flyCtrl.isAnimating) return;
    // Seed gesture so the fly animation has a sensible start vector.
    switch (direction) {
      case CardSwipeDirection.left:
        _drag = Offset(-_rs.swipeThreshold, 0);
      case CardSwipeDirection.right:
        _drag = Offset(_rs.swipeThreshold, 0);
      case CardSwipeDirection.up:
        _drag = Offset(0, -_rs.swipeThreshold);
      case CardSwipeDirection.down:
        _drag = Offset(0, _rs.swipeThreshold);
    }
    _startFly(direction, _boxSize);
  }

  void undoLast() {
    if (!canUndo) return;
    final record = _history.removeLast();
    setState(() {
      _deck.insert(record.indexAtRemoval, record.item);
      _drag = Offset.zero;
    });
    widget.onUndo?.call(record.item, record.indexAtRemoval, record.direction);
    widget.controller?._bump();
  }

  void clearHistory() {
    _history.clear();
    widget.controller?._bump();
  }

  // ─── Drag handling ─────────────────────────────────────────

  bool get _allowsHorizontal =>
      widget.allowedDirections.contains(CardSwipeDirection.left) ||
      widget.allowedDirections.contains(CardSwipeDirection.right);
  bool get _allowsVertical =>
      widget.allowedDirections.contains(CardSwipeDirection.up) ||
      widget.allowedDirections.contains(CardSwipeDirection.down);

  void _onDragStart(DragStartDetails _) {
    _snapCtrl.stop();
    // Mid-fly: short-circuit the still-running fly animation,
    // commit the dismissal NOW, and let the new gesture target
    // the freshly-promoted top card. Without this, the user has
    // to wait ~`dismissDuration` between swipes.
    if (_flyCtrl.isAnimating) {
      _flyCtrl.stop();
      _finalizeDismiss();
    }
  }

  void _onHorizontalDragUpdate(DragUpdateDetails details) {
    setState(() => _drag += Offset(details.delta.dx, 0));
  }

  void _onVerticalDragUpdate(DragUpdateDetails details) {
    setState(() => _drag += Offset(0, details.delta.dy));
  }

  void _onPanUpdate(DragUpdateDetails details) {
    setState(() => _drag += details.delta);
  }

  void _onDragEnd(DragEndDetails details) {
    if (_flyCtrl.isAnimating) return;
    final dir = _resolveDismissDirection(details.velocity.pixelsPerSecond);
    if (dir != null) {
      _startFly(dir, _boxSize);
    } else {
      _startSnapBack();
    }
  }

  /// Picks an axis-locked GestureDetector based on
  /// `allowedDirections`. When only horizontal swipes are allowed,
  /// vertical drags pass through to the parent (e.g. a vertical
  /// ShowcasePage scroll). Same for vertical-only mode.
  Widget _buildTopGestureWrap(Widget child) {
    if (_allowsHorizontal && !_allowsVertical) {
      return GestureDetector(
        behavior: HitTestBehavior.opaque,
        onHorizontalDragStart: _onDragStart,
        onHorizontalDragUpdate: _onHorizontalDragUpdate,
        onHorizontalDragEnd: _onDragEnd,
        child: child,
      );
    }
    if (_allowsVertical && !_allowsHorizontal) {
      return GestureDetector(
        behavior: HitTestBehavior.opaque,
        onVerticalDragStart: _onDragStart,
        onVerticalDragUpdate: _onVerticalDragUpdate,
        onVerticalDragEnd: _onDragEnd,
        child: child,
      );
    }
    // Both axes allowed — fall back to pan (claims both axes; any
    // surrounding scroll on either axis will conflict).
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onPanStart: _onDragStart,
      onPanUpdate: _onPanUpdate,
      onPanEnd: _onDragEnd,
      child: child,
    );
  }

  /// Which way the card leaves, if it leaves at all.
  ///
  /// Distance OR speed: a short, fast FLICK is the gesture people
  /// make once they know a deck, and distance alone snapped every
  /// one of them back.
  CardSwipeDirection? _resolveDismissDirection(Offset velocity) {
    final dx = _drag.dx;
    final dy = _drag.dy;
    final absDx = dx.abs();
    final absDy = dy.abs();
    final farEnough =
        absDx >= _rs.swipeThreshold || absDy >= _rs.swipeThreshold;
    final fastEnough =
        velocity.dx.abs() >= _rs.flingVelocity ||
        velocity.dy.abs() >= _rs.flingVelocity;
    if (!farEnough && !fastEnough) return null;
    // A flick decides its axis by SPEED; a drag by how far it went.
    // Reading the drag on a flick picks the wrong axis whenever the
    // finger drifted more than it travelled.
    final horizontal = (!farEnough && fastEnough)
        ? velocity.dx.abs() > velocity.dy.abs()
        : absDx > absDy;
    final CardSwipeDirection candidate;
    if (horizontal) {
      final sign = (!farEnough && fastEnough) ? velocity.dx : dx;
      candidate = sign > 0 ? CardSwipeDirection.right : CardSwipeDirection.left;
    } else {
      final sign = (!farEnough && fastEnough) ? velocity.dy : dy;
      candidate = sign > 0 ? CardSwipeDirection.down : CardSwipeDirection.up;
    }
    return widget.allowedDirections.contains(candidate) ? candidate : null;
  }

  // ─── Keyboard ──────────────────────────────────────────────

  /// Arrow keys deal the top card; Ctrl / Cmd + Z rewinds one.
  ///
  /// The horizontal pair MIRRORS in Arabic — a deck there is dealt the
  /// other way, so the arrow that means "the right-hand action" is the
  /// LEFT one. The vertical pair does not: up and down have no reading
  /// direction. Same split the page family's arrows make.
  KeyEventResult _onKey(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
      return KeyEventResult.ignored;
    }
    if (_deck.isEmpty) return KeyEventResult.ignored;

    final key = event.logicalKey;
    if (key == LogicalKeyboardKey.keyZ &&
        (HardwareKeyboard.instance.isControlPressed ||
            HardwareKeyboard.instance.isMetaPressed)) {
      if (!canUndo) return KeyEventResult.ignored;
      undoLast();
      return KeyEventResult.handled;
    }

    final rtl = Directionality.of(context) == TextDirection.rtl;
    CardSwipeDirection? dir;
    if (key == LogicalKeyboardKey.arrowLeft) {
      dir = rtl ? CardSwipeDirection.right : CardSwipeDirection.left;
    } else if (key == LogicalKeyboardKey.arrowRight) {
      dir = rtl ? CardSwipeDirection.left : CardSwipeDirection.right;
    } else if (key == LogicalKeyboardKey.arrowUp) {
      dir = CardSwipeDirection.up;
    } else if (key == LogicalKeyboardKey.arrowDown) {
      dir = CardSwipeDirection.down;
    }
    if (dir == null || !widget.allowedDirections.contains(dir)) {
      return KeyEventResult.ignored;
    }
    programmaticDismiss(dir);
    return KeyEventResult.handled;
  }

  // ─── Semantics ─────────────────────────────────────────────

  String _labelFor(CardSwipeDirection dir) {
    final custom = widget.directionLabels[dir];
    if (custom != null) return custom;
    switch (dir) {
      case CardSwipeDirection.left:
        return StackStrings.swipeLeft;
      case CardSwipeDirection.right:
        return StackStrings.swipeRight;
      case CardSwipeDirection.up:
        return StackStrings.swipeUp;
      case CardSwipeDirection.down:
        return StackStrings.swipeDown;
    }
  }

  /// A swipe is not a gesture assistive tech can make, and this deck
  /// has no other affordance at all — so without these a screen
  /// reader met a wall of cards it could neither read the count of
  /// nor act on. The same argument the list's swipe actions and the
  /// refreshable's pull both made.
  Map<CustomSemanticsAction, VoidCallback> _semanticActions() {
    final actions = <CustomSemanticsAction, VoidCallback>{};
    for (final dir in CardSwipeDirection.values) {
      if (!widget.allowedDirections.contains(dir)) continue;
      actions[CustomSemanticsAction(label: _labelFor(dir))] = () =>
          programmaticDismiss(dir);
    }
    if (canUndo) {
      actions[CustomSemanticsAction(label: CommonStrings.undo)] = undoLast;
    }
    return actions;
  }

  // ─── Build ─────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    if (_deck.isEmpty) return _buildEmpty(context);
    final direction = Directionality.of(context);
    final topIndex = _deck.length - 1;
    final caller = widget.semanticLabelBuilder?.call(_deck[topIndex], topIndex);
    final position = StackStrings.cardOf(1, _deck.length);

    Widget deck = LayoutBuilder(
      builder: (ctx, c) {
        final size = Size(c.maxWidth, c.maxHeight);
        return Stack(
          // Clip.none so rotated / scaled cards don't lose corners
          // when their bounding box extends past the Stack bounds
          // mid-rotation.
          clipBehavior: Clip.none,
          alignment: Alignment.center,
          fit: StackFit.expand,
          children: _buildStackChildren(size, direction),
        );
      },
    );

    if (widget.enableKeyboardNav) {
      // NOT autofocus. A deck that takes focus the moment it is built
      // steals it from whatever the reader was on — the theft the
      // collections, the page family and both carousels all shipped.
      deck = Focus(focusNode: _keyboardFocus, onKeyEvent: _onKey, child: deck);
    }

    return Semantics(
      container: true,
      label: caller == null ? position : '$caller. $position',
      customSemanticsActions: _semanticActions(),
      child: deck,
    );
  }

  /// The deck ran out. It used to be a blank box, on the one screen in
  /// the app where running out is the EXPECTED ending.
  Widget _buildEmpty(BuildContext context) =>
      widget.emptyBuilder?.call(context) ??
      GlobalEmptyState(
        title: ListStrings.emptyTitle,
        icon: Icons.inbox_outlined,
        variant: EmptyStateVariant.compact,
      );

  List<Widget> _buildStackChildren(Size size, TextDirection direction) {
    final top = _deck.length - 1;
    // Render one EXTRA slot beyond visibleDepth as a "pending"
    // (invisible) card. When the deck advances + this card
    // promotes into the visible window, its opacity + transform
    // animate up smoothly instead of popping in.
    final fromBottom = (top - _rs.visibleDepth).clamp(0, top);
    final dragProgress = (_drag.distance / _rs.swipeThreshold).clamp(0.0, 1.0);
    final result = <Widget>[];
    for (var idx = fromBottom; idx <= top; idx++) {
      final depthFromTop = top - idx;
      final isTop = depthFromTop == 0;
      // True when this slot is the "pending" one beyond the visible
      // window. Renders at the deepest visible scale/offset but
      // opacity 0 — exists so it can animate in when promoted.
      final isPending = depthFromTop >= _rs.visibleDepth;
      final dragNorm = isTop
          ? Offset(
              _drag.dx / _rs.swipeThreshold,
              _drag.dy / _rs.swipeThreshold,
            )
          : Offset.zero;
      // Visual depth: behind + pending cards advance with drag in
      // lockstep with the top card's swipe progress. Pending card
      // starts parked at `visibleDepth` (invisible) and steps up to
      // `visibleDepth - 1` (deepest visible position) as
      // dragProgress reaches 1.
      final visualDepth = isTop
          ? 0.0
          : (depthFromTop - dragProgress).clamp(0.0, depthFromTop.toDouble());
      final scale = _rs.scaleAt(visualDepth);
      // The peek direction is the BAG's now, and mirrors for the
      // reading direction — it used to be a bare vertical offset, so
      // a deck could not fan the way the layered stack could.
      final peek = _rs.peekAt(1, direction) * visualDepth;
      final rotationRadians = isTop
          ? (_drag.dx / size.width) * (_rs.maxRotationDegrees * math.pi / 180)
          : 0.0;
      final translate = isTop ? _drag : peek;
      // Pending opacity ramps with dragProgress so the bottom card
      // fades in as the top card travels its swipe distance. After
      // dismiss commits, deck shrinks + this card promotes to a
      // visible slot (opacity stays at 1 via the AnimatedOpacity's
      // last value).
      final opacity = isPending ? dragProgress : _rs.opacityAt(visualDepth);
      final child = widget.itemBuilder(
        context,
        _deck[idx],
        depthFromTop,
        dragNorm,
      );
      // Add tap detection only for the top card.
      final tappable = isTop && widget.onTap != null
          ? GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () {
                // Suppress tap if a drag is in progress (drag distance > slop).
                if (_drag.distance > 4) return;
                widget.onTap!(_deck[idx], idx);
              },
              child: child,
            )
          : child;
      // Identity-stable key so when a card promotes from `depth N`
      // to `depth N-1` (top card swiped + deck shrinks), Flutter
      // keeps the same Element + the implicit animations
      // (AnimatedContainer scale/translate) engage.
      final cardKey = ValueKey<int>(identityHashCode(_deck[idx]));
      // While the user is actively dragging, both top and behind
      // cards track the drag instantly (no animation lag — `_drag`
      // updates every frame). When dragging stops (`_drag == zero`),
      // behind cards use `snapDuration` so deck advances / snap-back
      // / dismiss animate smoothly.
      final isDragging = _drag != Offset.zero;
      final duration = (isTop || isDragging) ? Duration.zero : _rs.snapDuration;
      result.add(
        AnimatedOpacity(
          key: cardKey,
          opacity: opacity,
          duration: duration,
          curve: _rs.curve,
          child: AnimatedContainer(
            duration: duration,
            curve: _rs.curve,
            transform: Matrix4.identity()
              ..translateByDouble(translate.dx, translate.dy, 0, 1)
              ..scaleByDouble(scale, scale, 1, 1),
            transformAlignment: Alignment.center,
            child: isTop
                ? _buildTopGestureWrap(
                    // The tilt is applied SEPARATELY from the scale,
                    // and about a point below the card. Folding it
                    // into the transform above would pivot the scale
                    // about that point too, which is a card growing
                    // out of the floor. A card rotating about its own
                    // centre reads as being twisted; a real deck
                    // pivots near where a thumb would be, so the top
                    // swings further than the bottom.
                    Transform.rotate(
                      angle: rotationRadians,
                      alignment: Alignment(0, _rs.rotationAnchorY),
                      child: tappable,
                    ),
                  )
                : IgnorePointer(
                    ignoring: isPending || !isTop,
                    // A card BEHIND the top one is not reachable and
                    // not readable; announcing all three would read
                    // the deck out three cards at a time.
                    child: ExcludeSemantics(child: tappable),
                  ),
          ),
        ),
      );
    }
    return result;
  }
}

/// Internal record of a dismissed card so [GlobalCardStackController]
/// can undo. Snapshot of the item + where it sat + which way it left.
class _DismissedRecord<T> {
  const _DismissedRecord({
    required this.item,
    required this.indexAtRemoval,
    required this.direction,
  });

  final T item;
  final int indexAtRemoval;
  final CardSwipeDirection direction;
}
