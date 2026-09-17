import 'package:flutter/material.dart';
import 'package:flutter/services.dart'
    show KeyDownEvent, KeyEvent, KeyRepeatEvent, LogicalKeyboardKey;

import '../../../core/localization/strings/stack_strings.dart';
import '../card_stack/stack_models.dart';
import '../card_stack/theme/stack_theme.dart';

export '../card_stack/stack_models.dart' show StackPeekDirection, StackStyle;

/// Controller for [GlobalLayeredStack] — drives the currently-on-top
/// index. Caller can advance manually OR let the widget's
/// `tapToAdvance` cycle through.
///
/// It is told the deck's LENGTH and whether it loops, because a
/// controller that cannot count the deck cannot clamp or wrap: `next()`
/// used to walk the index past the end forever, and the widget clamped
/// on the way out — so coming back took as many `previous()` calls as
/// had overshot, and `loop` never wrapped for a controller at all.
class GlobalLayeredStackController extends ChangeNotifier {
  GlobalLayeredStackController({int initialIndex = 0}) : _index = initialIndex;

  int _index;
  int get currentIndex => _index;

  int _length = 0;
  bool _loop = false;

  /// Told by the widget on every build. Not a caller's to set.
  void bind({required int length, required bool loop}) {
    _length = length;
    _loop = loop;
    final clamped = _clamp(_index);
    if (clamped != _index) {
      _index = clamped;
      // A build is in flight — notifying now would mark a listener
      // dirty mid-build.
      WidgetsBinding.instance.addPostFrameCallback((_) => notifyListeners());
    }
  }

  int _clamp(int value) {
    if (_length <= 0) return 0;
    if (_loop) return value % _length;
    return value.clamp(0, _length - 1);
  }

  void set(int index) {
    final next = _clamp(index);
    if (_index == next) return;
    _index = next;
    notifyListeners();
  }

  void next() => set(_index + 1);
  void previous() => set(_index - 1);

  bool get canGoNext => _loop || _index < _length - 1;
  bool get canGoPrevious => _loop || _index > 0;
}

/// Visual stack of items — all positioned at the same point with
/// per-depth scale + peek offset. Caller controls which item is
/// "on top" via [current] or a [controller].
///
/// Distinct from `GlobalCardStack`, which is the same depth drawn
/// around a gesture that CONSUMES the deck: this one never removes
/// anything, so its index moves because the caller said so rather
/// than because a card left. Distinct too from `GlobalPageView`'s
/// `PageTransition`, which transforms pages during a scroll.
///
/// Visual configuration is the themeable bag [StackStyle], shared
/// with the card stack —
/// `caller > GlobalStackTheme.style > StackStyle.defaults`. The
/// swipe fields on that bag mean nothing here; there is no swipe.
class GlobalLayeredStack<T> extends StatefulWidget {
  const GlobalLayeredStack({
    required this.items,
    required this.itemBuilder,
    super.key,
    this.style = const StackStyle(),
    this.current = 0,
    this.controller,
    this.loop = false,
    this.tapToAdvance = false,
    this.semanticLabelBuilder,
    this.onIndexChanged,
    this.enableKeyboardNav = true,
  });

  final List<T> items;

  /// `(context, item, depth)` — `depth` is 0 for the top card and
  /// increments downward. Caller can vary opacity / decoration per
  /// depth on top of the built-in scale + peek offset.
  final Widget Function(BuildContext, T item, int depth) itemBuilder;

  /// How the pile is BUILT — depth, peek direction, timings.
  final StackStyle style;

  /// Index of the item on top. Ignored when [controller] is supplied
  /// (controller wins).
  final int current;

  /// Optional external controller. When non-null overrides [current].
  final GlobalLayeredStackController? controller;

  /// When `true`, advancing past the end wraps to index 0 (and vice
  /// versa). Otherwise indices clamp to `[0, items.length - 1]`.
  final bool loop;

  /// Tapping the top card advances to the next item. Useful for
  /// kiosk / story-board flows.
  ///
  /// It works WITH a controller now. The tap used to be gated on
  /// there not being one, so a caller who wired both got a pile that
  /// ignored every tap, with no assert and no hint.
  final bool tapToAdvance;

  /// Names the top item for a screen reader — `(item, index)`.
  final String Function(T item, int index)? semanticLabelBuilder;

  /// Fires whenever the item on top changes, however it changed — a
  /// tap, a key, a semantics action, or the controller.
  ///
  /// Without it, a caller who let `tapToAdvance` drive the pile had no
  /// way to know where it had got to short of owning a controller
  /// they did not otherwise need.
  final void Function(int index)? onIndexChanged;

  /// Whether the arrow keys move a layer. Focus is taken by TAB,
  /// never on mount.
  final bool enableKeyboardNav;

  @override
  State<GlobalLayeredStack<T>> createState() => _GlobalLayeredStackState<T>();
}

class _GlobalLayeredStackState<T> extends State<GlobalLayeredStack<T>> {
  late ResolvedStackStyle _rs;
  int _currentInternal = 0;

  final FocusNode _keyboardFocus = FocusNode(debugLabel: 'layered stack');

  int get _currentIndex {
    // Controller wins when supplied, falls back to widget-provided
    // current, and finally to internal counter (for tapToAdvance
    // when neither controller nor current is wired).
    final ctrl = widget.controller;
    if (ctrl != null) return ctrl.currentIndex;
    if (widget.tapToAdvance) return _currentInternal;
    return widget.current;
  }

  /// Whether anything can move the pile at all. A static pile is a
  /// picture: no focus, no adjustable actions, nothing for a reader
  /// to do — the same call the indicator and the stepper make.
  bool get _isInteractive => widget.controller != null || widget.tapToAdvance;

  @override
  void initState() {
    super.initState();
    _currentInternal = widget.current;
    widget.controller?.addListener(_onCtrlChange);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Here, not `initState`: the theme extension and
    // `disableAnimationsOf` are inherited reads.
    _rs = widget.style.resolve(context);
  }

  @override
  void didUpdateWidget(GlobalLayeredStack<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.style != widget.style) _rs = widget.style.resolve(context);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller?.removeListener(_onCtrlChange);
      widget.controller?.addListener(_onCtrlChange);
    }
    if (widget.current != oldWidget.current && widget.controller == null) {
      _currentInternal = widget.current;
    }
  }

  @override
  void dispose() {
    widget.controller?.removeListener(_onCtrlChange);
    _keyboardFocus.dispose();
    super.dispose();
  }

  void _onCtrlChange() {
    setState(() {});
    widget.onIndexChanged?.call(widget.controller!.currentIndex);
  }

  void _step(int delta) {
    final ctrl = widget.controller;
    if (ctrl != null) {
      ctrl.set(ctrl.currentIndex + delta);
      return;
    }
    final n = widget.items.length;
    if (n == 0) return;
    final raw = _currentInternal + delta;
    final next = widget.loop ? (raw % n + n) % n : raw.clamp(0, n - 1);
    if (next == _currentInternal) return;
    setState(() => _currentInternal = next);
    widget.onIndexChanged?.call(next);
  }

  void _advance() => _step(1);

  /// The arrows move a LAYER.
  ///
  /// The horizontal pair mirrors in Arabic, where the pile is read the
  /// other way; the vertical pair does not — up and down have no
  /// reading direction. Same split the page family and the card stack
  /// make.
  KeyEventResult _onKey(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
      return KeyEventResult.ignored;
    }
    final rtl = Directionality.of(context) == TextDirection.rtl;
    final key = event.logicalKey;
    final forward = rtl
        ? LogicalKeyboardKey.arrowLeft
        : LogicalKeyboardKey.arrowRight;
    final back = rtl
        ? LogicalKeyboardKey.arrowRight
        : LogicalKeyboardKey.arrowLeft;

    if (key == forward || key == LogicalKeyboardKey.arrowDown) {
      _step(1);
      return KeyEventResult.handled;
    }
    if (key == back || key == LogicalKeyboardKey.arrowUp) {
      _step(-1);
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    final n = widget.items.length;
    if (n == 0) return const SizedBox.expand();
    widget.controller?.bind(length: n, loop: widget.loop);
    final direction = Directionality.of(context);
    final current = _currentIndex.clamp(0, n - 1);
    // Render the visible layers BACK to FRONT so the top renders
    // last (i.e. on top of the stack).
    final maxLayers = _rs.visibleDepth.clamp(1, n);
    final children = <Widget>[];
    for (var depth = maxLayers - 1; depth >= 0; depth--) {
      // Map the visual depth to an actual item index. If `loop` is
      // off, layers beyond the deck end are skipped.
      var itemIdx = current + depth;
      if (itemIdx >= n) {
        if (!widget.loop) continue;
        itemIdx = itemIdx % n;
      }
      final scale = _rs.scaleAt(depth.toDouble());
      final opacity = _rs.opacityAt(depth.toDouble());
      final offset = _rs.peekAt(depth, direction);
      final isTop = depth == 0;
      final cardChild = widget.itemBuilder(
        context,
        widget.items[itemIdx],
        depth,
      );
      // One AnimatedContainer carries the whole transform. There used
      // to be an `AnimatedSlide` above this with `offset: Offset.zero`
      // hard-coded — a widget that animated nothing, wrapped around
      // every card of every pile.
      final shifted = AnimatedContainer(
        duration: _rs.duration,
        curve: _rs.curve,
        transform: Matrix4.identity()
          ..translateByDouble(offset.dx, offset.dy, 0, 1)
          ..scaleByDouble(scale, scale, 1, 1),
        transformAlignment: Alignment.center,
        child: AnimatedOpacity(
          duration: _rs.duration,
          curve: _rs.curve,
          opacity: opacity,
          child: cardChild,
        ),
      );
      // Use Positioned.fill so each card stretches to the Stack's
      // bounds — caller's tile then gets the full width/height to
      // lay out against (Center was shrinking children to their
      // intrinsic content size, producing the narrow-card look).
      children.add(
        Positioned.fill(
          child: isTop && widget.tapToAdvance
              ? GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: _advance,
                  child: shifted,
                )
              : IgnorePointer(
                  ignoring: !isTop,
                  // Only the top item is reachable, so only the top
                  // item is announced.
                  child: isTop ? shifted : ExcludeSemantics(child: shifted),
                ),
        ),
      );
    }

    final caller = widget.semanticLabelBuilder?.call(
      widget.items[current],
      current,
    );
    final position = StackStrings.layerOf(current + 1, n);
    Widget stack = Stack(fit: StackFit.expand, children: children);

    if (widget.enableKeyboardNav && _isInteractive) {
      // Only when something can actually move it — a pile nothing can
      // drive is a picture, and a picture does not take a tab stop.
      // NOT autofocus, ever.
      stack = Focus(
        focusNode: _keyboardFocus,
        onKeyEvent: _onKey,
        child: stack,
      );
    }

    if (!_isInteractive) {
      // A report, not a control.
      return Semantics(
        container: true,
        label: caller == null ? position : '$caller. $position',
        child: stack,
      );
    }

    final canNext = widget.loop || current < n - 1;
    final canPrevious = widget.loop || current > 0;
    // An ADJUSTABLE needs value / increasedValue / decreasedValue
    // together or Flutter asserts — the same contract the dot
    // indicator's row follows.
    return Semantics(
      container: true,
      label: caller,
      value: position,
      increasedValue: canNext
          ? StackStrings.layerOf(
              widget.loop && current + 1 >= n ? 1 : current + 2,
              n,
            )
          : position,
      decreasedValue: canPrevious
          ? StackStrings.layerOf(
              widget.loop && current == 0 ? n : current,
              n,
            )
          : position,
      onIncrease: canNext ? _advance : null,
      onDecrease: canPrevious ? () => _step(-1) : null,
      child: stack,
    );
  }
}
