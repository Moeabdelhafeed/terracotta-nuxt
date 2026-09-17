import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/localization/strings/module_strings.dart';
import 'rating_models.dart';
import 'theme/rating_theme.dart';

export 'rating_models.dart';
export 'theme/rating_theme.dart';

/// Marks the focus ring, so a test can find it without matching on
/// `Container` — the hover wash mounts one per star.
const kRatingFocusRingKey = ValueKey<String>('rating-focus-ring');

/// Marks one star, in VALUE order: index 0 is always the first star of
/// the rating, whichever side of the screen it is drawn on.
ValueKey<String> ratingStarKey(int index) => ValueKey('rating-star-$index');

/// Marks the pop wrapper of star [index]. `ScaleTransition` alone is not
/// a usable finder — the settle scale mounts its own.
ValueKey<String> ratingPopKey(int index) => ValueKey('rating-pop-$index');

/// Marks the fill layer of star [index] — the rated glyph that fades in
/// over the outline.
ValueKey<String> ratingFillKey(int index) => ValueKey('rating-fill-$index');

// ---------------------------------------------------------------------------
// GlobalRating
// ---------------------------------------------------------------------------

/// A row of stars: read-only display, or tap / drag / keyboard input.
///
/// ```dart
/// GlobalRating(value: 4.5)                                  // display
/// GlobalRating(value: v, onChanged: (n) => setState(...))   // input
/// ```
///
/// Passing no [onChanged] is display mode — the row stops taking
/// pointers, keyboard focus and semantic actions in one move.
class GlobalRating extends StatefulWidget {
  const GlobalRating({
    required this.value,
    super.key,
    this.onChanged,
    this.count = RatingDefaults.count,
    this.precision = RatingPrecision.full,
    this.style = const RatingStyle(),
    this.enabled = true,
    this.clearable = false,
    this.autofocus = false,
    this.countLabel,
    this.onCountLabelTap,
    this.semanticLabel,
  }) : assert(count > 0, 'a rating needs at least one star');

  /// Current value, `0` to [count].
  final double value;

  /// Called on tap, drag or arrow key. Null means read-only.
  final ValueChanged<double>? onChanged;

  /// Number of stars.
  final int count;

  /// Step the value snaps to.
  final RatingPrecision precision;

  /// Themeable style bag. Merges over `GlobalRatingTheme`.
  final RatingStyle style;

  /// Whether the row accepts input. False dims it and drops it out of
  /// the focus order.
  final bool enabled;

  /// Whether tapping the current value clears it back to zero.
  final bool clearable;

  /// Whether the row takes keyboard focus on mount. Only meaningful in
  /// interactive mode — a display rating is not in the focus order at
  /// all.
  final bool autofocus;

  /// Trailing label — "4.5 (128 reviews)".
  final String? countLabel;

  /// Tap target on the label, for "see all reviews".
  final VoidCallback? onCountLabelTap;

  /// Spoken instead of the default rating label.
  final String? semanticLabel;

  @override
  State<GlobalRating> createState() => _GlobalRatingState();
}

class _GlobalRatingState extends State<GlobalRating> {
  double _dragValue = -1;
  bool _isDragging = false;
  bool _isFocused = false;
  int _hoveredIndex = -1;

  /// Star to pop, and a serial so the same index can pop twice.
  int _popIndex = -1;
  int _popSerial = 0;

  /// Set when THIS widget asked for a value. A value that arrives any
  /// other way — a server, a parent, a list scrolling into view — must
  /// not celebrate, or fifty rows pop as you scroll past them.
  double? _requested;

  /// Whether the current fill wave runs from the last star back.
  bool _staggerReversed = false;

  @override
  void didUpdateWidget(GlobalRating oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_same(oldWidget.value, widget.value)) return;

    // A fill wave runs forward; emptying runs backward, so clearing
    // reads as undoing rather than as a second, smaller rating.
    _staggerReversed = widget.value < oldWidget.value;

    // The pop is the answer to "did my tap register", so it only fires
    // for a value this widget asked for AND actually received.
    final requested = _requested;
    _requested = null;
    if (requested == null || !_same(requested, widget.value)) return;
    if (widget.value <= 0) return;

    setState(() {
      _popIndex = (widget.value.ceil() - 1).clamp(0, widget.count - 1);
      _popSerial++;
    });
  }

  bool get _isInteractive => widget.enabled && widget.onChanged != null;

  double get _displayValue => _isDragging ? _dragValue : widget.value;

  double get _max => widget.count.toDouble();

  // ─── Pointer position → value ──────────────────────────────

  /// Turns a local x into a rating.
  ///
  /// [rs] and [rtl] come from the caller because both are already
  /// resolved in `build`, and re-reading the style per pointer event
  /// would resolve the whole bag on every drag frame.
  double _valueAt(double localX, ResolvedRatingStyle rs, bool rtl) {
    final width = rs.widthFor(widget.count);
    // In RTL the Row lays star 0 at the RIGHT edge, so a raw pixel
    // offset counts the stars backwards. Without this, tapping the
    // first star an Arabic reader sees gave five.
    final x = rtl ? width - localX : localX;
    return (x / rs.itemExtent).clamp(0.0, _max);
  }

  // ─── Interaction ───────────────────────────────────────────

  void _commit(double next, {bool selection = false}) {
    final rs = _resolve();
    _requested = next;
    if (rs.enableHaptic) {
      selection
          ? HapticFeedback.selectionClick()
          : HapticFeedback.lightImpact();
    }
    widget.onChanged!(next);
  }

  bool _same(double a, double b) => (a - b).abs() < RatingDefaults.epsilon;

  void _handleTapUp(TapUpDetails details, ResolvedRatingStyle rs, bool rtl) {
    if (!_isInteractive) return;
    final value = widget.precision.snapUp(
      _valueAt(details.localPosition.dx, rs, rtl),
    );

    if (widget.clearable && _same(value, widget.value)) {
      _commit(0);
      return;
    }
    if (!_same(value, widget.value)) _commit(value);
  }

  void _handleDragStart(
    DragStartDetails details,
    ResolvedRatingStyle rs,
    bool rtl,
  ) {
    if (!_isInteractive) return;
    setState(() {
      _isDragging = true;
      _dragValue = widget.precision.snapUp(
        _valueAt(details.localPosition.dx, rs, rtl),
      );
    });
  }

  void _handleDragUpdate(
    DragUpdateDetails details,
    ResolvedRatingStyle rs,
    bool rtl,
  ) {
    if (!_isInteractive || !_isDragging) return;
    final next = widget.precision.snapUp(
      _valueAt(details.localPosition.dx, rs, rtl),
    );
    if (_same(next, _dragValue)) return;
    setState(() => _dragValue = next);
    // A tick per step crossed, not per pixel — this is the one gesture
    // where the haptic IS the feedback, since the finger covers the
    // stars it is choosing.
    if (rs.enableHaptic) HapticFeedback.selectionClick();
  }

  void _handleDragEnd(DragEndDetails details) {
    if (!_isInteractive || !_isDragging) return;
    final landed = _dragValue;
    setState(() => _isDragging = false);
    if (_same(landed, widget.value)) return;
    _requested = landed;
    widget.onChanged!(landed);
  }

  // ─── Keyboard ──────────────────────────────────────────────

  void _nudge(double delta) {
    if (!_isInteractive) return;
    final next = (widget.value + delta).clamp(0.0, _max);
    if (!_same(next, widget.value)) _commit(next, selection: true);
  }

  void _increment() => _nudge(widget.precision.step);
  void _decrement() => _nudge(-widget.precision.step);

  // ─── Build ─────────────────────────────────────────────────

  ResolvedRatingStyle _resolve() => widget.style.resolve(
    context,
    disableAnimations: MediaQuery.disableAnimationsOf(context),
  );

  @override
  Widget build(BuildContext context) {
    final rs = _resolve();
    final rtl = Directionality.of(context) == TextDirection.rtl;

    Widget content = GestureDetector(
      onTapUp: _isInteractive ? (d) => _handleTapUp(d, rs, rtl) : null,
      onHorizontalDragStart: _isInteractive
          ? (d) => _handleDragStart(d, rs, rtl)
          : null,
      onHorizontalDragUpdate: _isInteractive
          ? (d) => _handleDragUpdate(d, rs, rtl)
          : null,
      onHorizontalDragEnd: _isInteractive ? _handleDragEnd : null,
      behavior: HitTestBehavior.opaque,
      child: AnimatedOpacity(
        opacity: widget.enabled ? 1.0 : rs.disabledOpacity,
        duration: rs.animationDuration,
        child: _buildStars(rs),
      ),
    );

    if (_isInteractive) content = _buildKeyboard(content, rs);
    if (widget.countLabel != null) content = _withLabel(content, rs);

    return Semantics(
      slider: true,
      enabled: _isInteractive,
      label: widget.semanticLabel ?? RatingStrings.semanticLabel,
      value: RatingStrings.valueOutOf(_format(widget.value), widget.count),
      increasedValue: widget.value < _max
          ? RatingStrings.valueOutOf(
              _format(
                (widget.value + widget.precision.step).clamp(0.0, _max),
              ),
              widget.count,
            )
          : null,
      decreasedValue: widget.value > 0
          ? RatingStrings.valueOutOf(
              _format(
                (widget.value - widget.precision.step).clamp(0.0, _max),
              ),
              widget.count,
            )
          : null,
      onIncrease: _isInteractive && widget.value < _max ? _increment : null,
      onDecrease: _isInteractive && widget.value > 0 ? _decrement : null,
      child: ExcludeSemantics(child: content),
    );
  }

  /// Whole values read as "4", not "4.0" — screen readers say every
  /// character of the latter.
  String _format(double v) =>
      v == v.roundToDouble() ? v.toInt().toString() : v.toString();

  /// Index the dragging finger is currently over, or -1.
  int get _draggedIndex =>
      _isDragging ? (_dragValue.ceil() - 1).clamp(0, widget.count - 1) : -1;

  Widget _buildStars(ResolvedRatingStyle rs) {
    final value = _displayValue;
    final staggering = _staggerReversed ? rs.staggerClear : rs.staggerFill;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < widget.count; i++) ...[
          // Directional: `EdgeInsets.only(right:)` put the gap on the
          // wrong side of every star in Arabic.
          if (i > 0) SizedBox(width: rs.spacing),
          MouseRegion(
            onEnter: _isInteractive
                ? (_) => setState(() => _hoveredIndex = i)
                : null,
            onExit: _isInteractive
                ? (_) => setState(() => _hoveredIndex = -1)
                : null,
            cursor: _isInteractive
                ? SystemMouseCursors.click
                : SystemMouseCursors.basic,
            child: AnimatedContainer(
              key: ratingStarKey(i),
              duration: rs.animationDuration,
              curve: rs.animationCurve,
              decoration: BoxDecoration(
                color: _hoveredIndex == i && _isInteractive
                    ? rs.hoverColor
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(rs.hoverRadius),
              ),
              child: _StarSlot(
                index: i,
                rs: rs,
                fraction: (value - i).clamp(0.0, 1.0),
                // A drag is live, so it must never be delayed — the
                // stagger is for a value that ARRIVES, not one the
                // finger is currently choosing.
                delay: staggering && !_isDragging
                    ? rs.staggerDelay(
                        i,
                        widget.count,
                        reversed: _staggerReversed,
                      )
                    : Duration.zero,
                popSerial: rs.selectPop && _popIndex == i ? _popSerial : 0,
                lifted: rs.dragLift && _draggedIndex == i,
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _withLabel(Widget stars, ResolvedRatingStyle rs) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      stars,
      SizedBox(width: rs.countLabelSpacing),
      GestureDetector(
        onTap: widget.onCountLabelTap,
        child: Text(widget.countLabel!, style: rs.countLabelStyle),
      ),
    ],
  );

  Widget _buildKeyboard(Widget child, ResolvedRatingStyle rs) {
    // Arrow keys follow the READING direction: in Arabic the row runs
    // right to left, so left-arrow has to raise the rating or the keys
    // fight the layout.
    final rtl = Directionality.of(context) == TextDirection.rtl;

    return Actions(
      actions: <Type, Action<Intent>>{
        _IncrementIntent: CallbackAction<_IncrementIntent>(
          onInvoke: (_) {
            _increment();
            return null;
          },
        ),
        _DecrementIntent: CallbackAction<_DecrementIntent>(
          onInvoke: (_) {
            _decrement();
            return null;
          },
        ),
      },
      child: Shortcuts(
        shortcuts: <ShortcutActivator, Intent>{
          const SingleActivator(LogicalKeyboardKey.arrowUp):
              const _IncrementIntent(),
          const SingleActivator(LogicalKeyboardKey.arrowDown):
              const _DecrementIntent(),
          const SingleActivator(LogicalKeyboardKey.arrowRight): rtl
              ? const _DecrementIntent()
              : const _IncrementIntent(),
          const SingleActivator(LogicalKeyboardKey.arrowLeft): rtl
              ? const _IncrementIntent()
              : const _DecrementIntent(),
        },
        child: Focus(
          autofocus: widget.autofocus && _isInteractive,
          canRequestFocus: _isInteractive,
          onFocusChange: (v) => setState(() => _isFocused = v),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              child,
              if (_isFocused)
                Positioned.fill(
                  child: IgnorePointer(
                    child: DecoratedBox(
                      key: kRatingFocusRingKey,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(rs.focusRadius),
                        border: Border.all(
                          color: rs.focusColor,
                          width: RatingDefaults.focusRingWidth,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Keyboard intents ────────────────────────────────────────

class _IncrementIntent extends Intent {
  const _IncrementIntent();
}

class _DecrementIntent extends Intent {
  const _DecrementIntent();
}

// ---------------------------------------------------------------------------
// One star's motion
// ---------------------------------------------------------------------------

/// Owns everything that MOVES about a single star: the delay before it
/// takes a new fill, the pop when the user picks it, and the lift while
/// a finger is over it.
///
/// Separate from [_RatingIcon] so the painting stays stateless — the
/// icon renders a fraction and knows nothing about how that fraction
/// arrived.
class _StarSlot extends StatefulWidget {
  const _StarSlot({
    required this.index,
    required this.rs,
    required this.fraction,
    required this.delay,
    required this.popSerial,
    required this.lifted,
  });

  final int index;
  final ResolvedRatingStyle rs;

  /// Where this star is HEADED. What it currently shows may lag by
  /// [delay].
  final double fraction;

  /// How long to wait before taking [fraction]. Zero for everything
  /// except a staggered wave.
  final Duration delay;

  /// Bumped each time this star should pop. Zero means never.
  final int popSerial;

  /// Whether a dragging finger is over this star.
  final bool lifted;

  @override
  State<_StarSlot> createState() => _StarSlotState();
}

class _StarSlotState extends State<_StarSlot>
    with SingleTickerProviderStateMixin {
  late AnimationController _pop;
  late Animation<double> _popScale;
  late double _shown = widget.fraction;
  Timer? _pending;

  @override
  void initState() {
    super.initState();
    _pop = AnimationController(vsync: this, duration: widget.rs.popDuration);
    _buildPopTween();
  }

  /// Up fast, down slower — the asymmetry is what reads as a settle
  /// rather than a twitch.
  void _buildPopTween() {
    _popScale = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(
          begin: 1.0,
          end: widget.rs.selectPopScale,
        ).chain(CurveTween(curve: Curves.easeOut)),
        weight: RatingDefaults.popRiseFraction,
      ),
      TweenSequenceItem(
        tween: Tween(
          begin: widget.rs.selectPopScale,
          end: 1.0,
        ).chain(CurveTween(curve: Curves.easeOutBack)),
        weight: RatingDefaults.popFallFraction,
      ),
    ]).animate(_pop);
  }

  @override
  void didUpdateWidget(_StarSlot oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.rs.popDuration != widget.rs.popDuration) {
      _pop.duration = widget.rs.popDuration;
    }
    if (oldWidget.rs.selectPopScale != widget.rs.selectPopScale) {
      _buildPopTween();
    }

    if (oldWidget.fraction != widget.fraction) _scheduleFill();

    if (widget.popSerial != 0 && widget.popSerial != oldWidget.popSerial) {
      _pop.forward(from: 0);
    }
  }

  void _scheduleFill() {
    _pending?.cancel();
    if (widget.delay == Duration.zero) {
      setState(() => _shown = widget.fraction);
      return;
    }
    _pending = Timer(widget.delay, () {
      if (mounted) setState(() => _shown = widget.fraction);
    });
  }

  @override
  void dispose() {
    _pending?.cancel();
    _pop.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final rs = widget.rs;
    final isFull = _shown >= 1 - RatingDefaults.epsilon;
    final isEmpty = _shown <= RatingDefaults.epsilon;

    final settle = isFull
        ? 1.0
        : (isEmpty ? RatingDefaults.emptyScale : RatingDefaults.partialScale);

    return AnimatedScale(
      scale: settle * (widget.lifted ? rs.dragLiftScale : 1.0),
      duration: rs.animationDuration,
      curve: rs.animationCurve,
      child: ScaleTransition(
        key: ratingPopKey(widget.index),
        scale: _popScale,
        child: _RatingIcon(rs: rs, fraction: _shown, index: widget.index),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// One star
// ---------------------------------------------------------------------------

class _RatingIcon extends StatelessWidget {
  const _RatingIcon({
    required this.rs,
    required this.fraction,
    required this.index,
  });

  final ResolvedRatingStyle rs;

  /// How much of THIS star is filled, 0 to 1.
  final double fraction;

  final int index;

  @override
  Widget build(BuildContext context) {
    final isFull = fraction >= 1 - RatingDefaults.epsilon;
    final isEmpty = fraction <= RatingDefaults.epsilon;

    // An exact half with a custom half widget is the one case the
    // layering cannot serve — the caller supplied the glyph itself.
    if (!isFull &&
        !isEmpty &&
        (fraction - 0.5).abs() < RatingDefaults.epsilon &&
        rs.halfRatedWidget != null) {
      return _shadowed(rs.halfRatedWidget!, rs.ratedShadow);
    }

    // The outline is ALWAYS painted and the fill fades in over it. It
    // used to swap one glyph for the other on the frame the value
    // landed, so only the scale animated and the star itself snapped.
    final outline =
        rs.unratedWidget ??
        Icon(rs.unratedIcon, size: rs.size, color: rs.unratedColor);

    final fill = ClipRect(
      clipper: _FractionClipper(
        fraction: fraction,
        rtl: Directionality.of(context) == TextDirection.rtl,
      ),
      child: _rated(isFull ? rs.ratedColor : rs.halfRatedColor),
    );

    return _shadowed(
      SizedBox(
        width: rs.size,
        height: rs.size,
        child: Stack(
          fit: StackFit.expand,
          children: [
            outline,
            AnimatedOpacity(
              key: ratingFillKey(index),
              opacity: isEmpty ? 0 : 1,
              duration: rs.fillCrossfade ? rs.animationDuration : Duration.zero,
              curve: rs.animationCurve,
              child: fill,
            ),
          ],
        ),
      ),
      isEmpty ? rs.shadow : rs.ratedShadow,
    );
  }

  Widget _shadowed(Widget child, List<BoxShadow>? shadow) {
    if (shadow == null) {
      return SizedBox(width: rs.size, height: rs.size, child: child);
    }
    return SizedBox(
      width: rs.size,
      height: rs.size,
      child: DecoratedBox(
        decoration: BoxDecoration(boxShadow: shadow, shape: BoxShape.circle),
        child: child,
      ),
    );
  }

  Widget _rated(Color color) {
    final icon =
        rs.ratedWidget ?? Icon(rs.ratedIcon, size: rs.size, color: color);
    if (rs.ratedGradient == null) return icon;
    return ShaderMask(
      shaderCallback: (bounds) => rs.ratedGradient!.createShader(bounds),
      blendMode: BlendMode.srcATop,
      child: icon,
    );
  }
}

/// Clips to a horizontal fraction of the child, filling from the start
/// edge — left in LTR, right in RTL.
class _FractionClipper extends CustomClipper<Rect> {
  const _FractionClipper({required this.fraction, this.rtl = false});

  final double fraction;
  final bool rtl;

  @override
  Rect getClip(Size size) => rtl
      ? Rect.fromLTRB(size.width * (1 - fraction), 0, size.width, size.height)
      : Rect.fromLTRB(0, 0, size.width * fraction, size.height);

  @override
  bool shouldReclip(_FractionClipper old) =>
      old.fraction != fraction || old.rtl != rtl;
}
