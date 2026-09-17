import 'dart:math' as math;

import 'package:flutter/foundation.dart' show listEquals;
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'circular_slider_math.dart';
import 'key_repeater.dart';
import 'slider_style.dart';
import 'theme/slider_theme.dart';

/// A value on a RING.
///
/// [GlobalCircularSlider] takes one value; [GlobalCircularSlider.range]
/// takes two and paints the arc between them — a bedtime and a wake-up,
/// a shift, a window.
///
/// Where the ring starts and how far it runs is
/// [CircularSliderGeometry]: a full turn from twelve o'clock
/// ([CircularSliderGeometry.top]), a gauge with a gap at the bottom,
/// a half-circle arc, or any angles the caller names — including a
/// NEGATIVE sweep, which counts anticlockwise.
class GlobalCircularSlider extends StatefulWidget {
  const GlobalCircularSlider({
    super.key,
    required this.min,
    required this.max,
    required double this.value,
    required ValueChanged<double> this.onChanged,
    this.geometry = CircularSliderGeometry.gauge,
    this.divisions,
    this.enabled = true,
    this.valueFormatter,
    this.semanticFormatter,
    this.semanticLabel,
    this.centerBuilder,
    this.thumbBuilder,
    this.trackMarks = const [],
    this.segments = const [],
    this.autofocus = false,
    this.focusNode,
    this.style,
    this.onChangeStart,
    this.onChangeEnd,
  }) : rangeValues = null,
       onRangeChanged = null,
       assert(min < max, 'min ($min) must be below max ($max)'),
       assert(
         divisions == null || divisions > 0,
         'divisions must be positive; null is a continuous dial',
       );

  /// Two thumbs, and the arc between them.
  ///
  /// On a CLOSED dial the span may WRAP: a night that runs 22:00 to
  /// 06:00 is the eight hours through midnight, not the sixteen the
  /// other way, so `start > end` is a legal span rather than an
  /// inverted one. `RangeValues` cannot say that — it asserts its start
  /// is not above its end — so the pair is a record.
  const GlobalCircularSlider.range({
    super.key,
    required this.min,
    required this.max,
    required ({double start, double end}) this.rangeValues,
    required ValueChanged<({double start, double end})> this.onRangeChanged,
    this.geometry = CircularSliderGeometry.top,
    this.divisions,
    this.enabled = true,
    this.valueFormatter,
    this.semanticFormatter,
    this.semanticLabel,
    this.centerBuilder,
    this.thumbBuilder,
    this.trackMarks = const [],
    this.segments = const [],
    this.autofocus = false,
    this.focusNode,
    this.style,
    this.onChangeStart,
    this.onChangeEnd,
  }) : value = null,
       onChanged = null,
       assert(min < max, 'min ($min) must be below max ($max)'),
       assert(
         divisions == null || divisions > 0,
         'divisions must be positive; null is a continuous dial',
       );

  final double min;
  final double max;

  final double? value;
  final ({double start, double end})? rangeValues;

  final ValueChanged<double>? onChanged;
  final ValueChanged<({double start, double end})>? onRangeChanged;

  /// Where the scale begins and how far it runs.
  ///
  /// A single value defaults to the GAUGE — a gap at the bottom, so
  /// the two ends of the scale are visibly two ends. A range defaults
  /// to the full turn, because a range that cannot wrap is a bar.
  final CircularSliderGeometry geometry;

  final int? divisions;
  final bool enabled;

  final String Function(double)? valueFormatter;

  /// What a reader HEARS, when that should differ from what it says.
  final String Function(double)? semanticFormatter;

  final String? semanticLabel;

  /// What goes in the hole: a duration, a price, a readout.
  ///
  /// It is a builder rather than a widget so it can read the live
  /// value mid-drag without the caller rebuilding the whole dial.
  final Widget Function(BuildContext context, double start, double end)?
  centerBuilder;

  /// Draws a thumb. `isStart` is false for the single slider's thumb
  /// and for a range's end.
  ///
  /// This is how a bed and a sun get onto the ring.
  final Widget Function(BuildContext context, bool isStart)? thumbBuilder;

  /// Values to mark on the ring — a scale, an hour, a threshold.
  final List<double> trackMarks;

  /// Where the ring is CUT, in value space.
  ///
  /// The bar's `segments`, bent round: each span between two
  /// boundaries is its own arc, so a dial with acts, tiers or shifts
  /// reads as several arcs handing the thumb between them. The gap is
  /// `style.segmentGap`, in POINTS along the ring rather than in
  /// degrees, so it looks the same on a big dial and a small one.
  final List<double> segments;

  /// Whether it takes focus when it appears.
  final bool autofocus;

  final FocusNode? focusNode;

  final SliderStyle? style;
  final ValueChanged<double>? onChangeStart;
  final ValueChanged<double>? onChangeEnd;

  bool get _isRange => rangeValues != null;

  @override
  State<GlobalCircularSlider> createState() => _GlobalCircularSliderState();
}

class _GlobalCircularSliderState extends State<GlobalCircularSlider> {
  ResolvedSliderStyle _style = ResolvedSliderStyle.fallback;

  /// Which thumb the current drag owns.
  ///
  /// Decided ONCE, when the finger goes down. Re-deciding every frame
  /// makes the two thumbs swap under a fast drag: the moment one
  /// passes the other, "nearest" becomes the one being left behind.
  bool? _draggingStart;

  int? _lastDivision;

  /// Which thumb the KEYBOARD is driving, on a range.
  ///
  /// A ring has two thumbs and one focus node: tabbing to a second
  /// node would put a traversal stop inside a control the reader
  /// thinks of as one thing. Space or Enter swaps which one the arrows
  /// move, and the focus ring says which that is.
  bool _keyOnStart = false;

  bool _focused = false;

  /// Drives the repeat while an arrow is held. The platform's own
  /// `KeyRepeatEvent` is not delivered everywhere, so a held key
  /// stepped once and stopped.
  final _repeat = KeyRepeater();

  double _value = 0;
  ({double start, double end}) _range = (start: 0, end: 0);

  @override
  void initState() {
    super.initState();
    _sync();
  }

  @override
  void dispose() {
    _repeat.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(GlobalCircularSlider old) {
    super.didUpdateWidget(old);
    if (widget.value != old.value || widget.rangeValues != old.rangeValues) {
      _sync();
    }
  }

  void _sync() {
    _value = (widget.value ?? widget.min).clamp(widget.min, widget.max);
    _range = widget.rangeValues ?? (start: widget.min, end: widget.max);
  }

  double _fraction(double v) =>
      CircularSliderMath.fraction(v, min: widget.min, max: widget.max);

  /// [GlobalCircularSlider.segments] as fractions, both ends included.
  ///
  /// Empty when nobody named an interior seam — one arc is not a
  /// segmented ring. A CLOSED dial's two ends are the same point, so
  /// its first and last segments are one arc across the seam; that is
  /// left alone rather than special-cased, because a dial whose seam
  /// is invisible has no ends to speak of anyway.
  List<double> get _segmentBounds {
    if (widget.segments.isEmpty) return const [];
    final inner =
        widget.segments
            .map(_fraction)
            .where((f) => f > 0 && f < 1)
            .toSet()
            .toList()
          ..sort();
    return inner.isEmpty ? const [] : <double>[0, ...inner, 1];
  }

  void _haptic(double v) {
    if (!_style.enableHaptic) return;
    final divisions = widget.divisions;
    if (divisions == null) return;
    final step = (_fraction(v) * divisions).round();
    if (step == _lastDivision) return;
    _lastDivision = step;
    HapticFeedback.selectionClick();
  }

  // ─── Gestures ──────────────────────────────────────────────

  /// The value a local point asks for, or null when the point is off
  /// the ring or in an open dial's gap.
  double? _valueAt(Offset local, Size size) {
    final centre = Offset(size.width / 2, size.height / 2);
    final radius = _radiusFor(size);
    final distance = (local - centre).distance;

    // A finger nearer the middle than the ring is not aiming at the
    // ring — on a dial with a readout in the hole, that is a tap on
    // the readout.
    const slop = SliderDefaults.ringTouchSlop;
    if (distance < radius - slop || distance > radius + slop) return null;

    return CircularSliderMath.valueForOffset(
      local,
      centre: centre,
      geometry: widget.geometry,
      min: widget.min,
      max: widget.max,
      divisions: widget.divisions,
    );
  }

  double _radiusFor(Size size) =>
      (math.min(size.width, size.height) - _style.ringThickness) / 2 -
      _style.ringThumbRadius;

  void _onDown(Offset local, Size size) {
    if (!widget.enabled) return;
    final v = _valueAt(local, size);
    if (v == null) return;

    if (widget._isRange) {
      _draggingStart = CircularSliderMath.startThumbIsNearer(
        _fraction(v),
        startFraction: _fraction(_range.start),
        endFraction: _fraction(_range.end),
        closed: widget.geometry.isClosed,
      );
      widget.onChangeStart?.call(
        _draggingStart! ? _range.start : _range.end,
      );
    } else {
      _draggingStart = false;
      widget.onChangeStart?.call(_value);
    }
    _apply(v);
  }

  void _onMove(Offset local, Size size) {
    if (!widget.enabled || _draggingStart == null) return;
    final v = _valueAt(local, size);
    if (v == null) return;
    _apply(v);
  }

  void _onUp() {
    if (_draggingStart == null) return;
    widget.onChangeEnd?.call(
      widget._isRange ? (_draggingStart! ? _range.start : _range.end) : _value,
    );
    _draggingStart = null;
    _lastDivision = null;
  }

  void _apply(double v) {
    _haptic(v);
    if (!widget._isRange) {
      setState(() => _value = v);
      widget.onChanged?.call(v);
      return;
    }
    final next = _draggingStart!
        ? (start: v, end: _range.end)
        : (start: _range.start, end: v);
    setState(() => _range = next);
    widget.onRangeChanged?.call(next);
  }

  // ─── Build ─────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    _style = (widget.style ?? const SliderStyle()).resolve(context);

    final start = widget._isRange ? _range.start : widget.min;
    final end = widget._isRange ? _range.end : _value;

    String say(double v) =>
        widget.semanticFormatter?.call(v) ??
        widget.valueFormatter?.call(v) ??
        v.toStringAsFixed(widget.divisions == null ? 1 : 0);

    final announced = say(end);
    // A node carrying `value` AND an increase action must say what
    // increasing WOULD read — the framework asserts on the pair, and a
    // reader is entitled to know before committing to the gesture.
    final step = _nudgeStep;
    final increased = say((end + step).clamp(widget.min, widget.max));
    final decreased = say((end - step).clamp(widget.min, widget.max));

    // `Semantics` OUTSIDE `Focus`, not the other way round: a `Focus`
    // introduces a node of its own, and with it on top the reader
    // reached that one first and the dial's label, value and actions
    // were a level down where nothing looked for them.
    return Semantics(
      container: true,
      slider: true,
      enabled: widget.enabled,
      label: widget.semanticLabel,
      value: announced,
      increasedValue: increased,
      decreasedValue: decreased,
      // A ring has no left and right, so a reader gets the two actions
      // that DO mean something on it. Without them the dial is
      // unreachable without a pointer.
      onIncrease: widget.enabled ? () => _nudge(1) : null,
      onDecrease: widget.enabled ? () => _nudge(-1) : null,
      child: Focus(
        focusNode: widget.focusNode,
        autofocus: widget.autofocus,
        canRequestFocus: widget.enabled,
        onFocusChange: (has) {
          // A key held while focus moves away would otherwise repeat
          // for ever — nothing is left to hear the key-up.
          if (!has) _repeat.stop();
          setState(() => _focused = has);
        },
        onKeyEvent: _onKey,
        child: ExcludeSemantics(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final side = constraints.hasBoundedWidth
                  ? math.min(
                      constraints.maxWidth,
                      constraints.hasBoundedHeight
                          ? constraints.maxHeight
                          : _style.ringDiameter,
                    )
                  : _style.ringDiameter;
              final size = Size(side, side);

              // CENTRED in whatever box it was given. Tight constraints
              // are passed straight through by `LayoutBuilder`, so an
              // oval box keeps its own size — the RING is square inside
              // it rather than stretched to fill.
              return Center(
                child: SizedBox(
                  width: side,
                  height: side,
                  child: RawGestureDetector(
                    behavior: HitTestBehavior.opaque,
                    gestures: <Type, GestureRecognizerFactory>{
                      // A plain `GestureDetector` LOSES a vertical drag
                      // to an enclosing scroll view: both enter the
                      // arena and the scrollable's recognizer wins on
                      // the vertical axis, so the dial went dead
                      // wherever a thumb sat near the top or the bottom
                      // of the ring and the page scrolled instead. This
                      // one claims the pointer the moment it lands ON
                      // the ring and declines it otherwise — the page
                      // still scrolls from the hole, from the corners,
                      // and from everywhere that is not the track.
                      _RingPanRecognizer:
                          GestureRecognizerFactoryWithHandlers<
                            _RingPanRecognizer
                          >(
                            () => _RingPanRecognizer(),
                            (r) {
                              r.isOnRing = (local) =>
                                  _valueAt(local, size) != null;
                              r.onRingDown = (p) => _onDown(p, size);
                              r.onRingUpdate = (p) => _onMove(p, size);
                              r.onRingEnd = _onUp;
                            },
                          ),
                    },
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        CustomPaint(
                          size: size,
                          painter: _RingPainter(
                            style: _style,
                            geometry: widget.geometry,
                            startFraction: _fraction(start),
                            endFraction: _fraction(end),
                            isRange: widget._isRange,
                            enabled: widget.enabled,
                            markFractions: [
                              for (final m in widget.trackMarks) _fraction(m),
                            ],
                            thumbRadius: _style.ringThumbRadius,
                            drawThumbs: widget.thumbBuilder == null,
                            segmentBounds: _segmentBounds,
                            // Only while the keyboard is actually on
                            // it — a ring wearing a halo nobody put
                            // there reads as selected.
                            focusOnStart: widget._isRange ? _keyOnStart : null,
                            focused: _focused,
                          ),
                        ),
                        if (widget.centerBuilder != null)
                          // Inside the ring, never under it.
                          Padding(
                            padding: EdgeInsets.all(
                              _style.ringThickness + _style.ringThumbRadius,
                            ),
                            child: Center(
                              // Dimmed with the ring. The painter
                              // dims what IT draws, and a readout
                              // sitting at full strength inside a
                              // greyed-out dial reads as the one live
                              // thing on it.
                              child: _dimmed(
                                widget.centerBuilder!(context, start, end),
                              ),
                            ),
                          ),
                        if (widget.thumbBuilder != null) ...[
                          if (widget._isRange)
                            _positioned(size, start, isStart: true),
                          _positioned(size, end, isStart: false),
                        ],
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  /// A ring has no left and right that mean anything, so BOTH axes
  /// step it: up or right is clockwise, down or left is
  /// anticlockwise. It does NOT mirror in Arabic — a dial turns the
  /// way a clock does in every language, which is the argument the
  /// time picker's own face makes.
  KeyEventResult _onKey(FocusNode node, KeyEvent event) {
    if (!widget.enabled) return KeyEventResult.ignored;

    if (event is KeyUpEvent) {
      _repeat.stop();
      return KeyEventResult.ignored;
    }
    // The platform's own repeat is swallowed: this drives its own, so
    // acting on both would double every step where the platform does
    // send them.
    if (event is KeyRepeatEvent) return KeyEventResult.handled;
    if (event is! KeyDownEvent) return KeyEventResult.ignored;

    final key = event.logicalKey;

    if (key == LogicalKeyboardKey.arrowUp ||
        key == LogicalKeyboardKey.arrowRight) {
      _nudge(1);
      _repeat.start((m) => _nudge(m));
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.arrowDown ||
        key == LogicalKeyboardKey.arrowLeft) {
      _nudge(-1);
      _repeat.start((m) => _nudge(-m));
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.home) {
      _setKeyed(widget.min);
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.end) {
      _setKeyed(widget.max);
      return KeyEventResult.handled;
    }
    // A range has two thumbs and one focus node: a second traversal
    // stop inside a control the reader thinks of as ONE thing is
    // worse than a key that swaps which thumb the arrows move.
    if (widget._isRange &&
        (key == LogicalKeyboardKey.space ||
            key == LogicalKeyboardKey.enter ||
            key == LogicalKeyboardKey.tab)) {
      setState(() => _keyOnStart = !_keyOnStart);
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  /// Puts the keyboard's thumb at an absolute value.
  void _setKeyed(double v) {
    if (!widget._isRange) {
      setState(() => _value = v);
      widget.onChanged?.call(v);
      widget.onChangeEnd?.call(v);
      return;
    }
    final next = _keyOnStart
        ? (start: v, end: _range.end)
        : (start: _range.start, end: v);
    setState(() => _range = next);
    widget.onRangeChanged?.call(next);
    widget.onChangeEnd?.call(v);
  }

  /// Fades a caller's widget with the rest of a disabled dial.
  Widget _dimmed(Widget child) => widget.enabled
      ? child
      : Opacity(opacity: _style.disabledOpacity, child: child);

  Widget _positioned(Size size, double value, {required bool isStart}) {
    final centre = Offset(size.width / 2, size.height / 2);
    final p = CircularSliderMath.offsetFor(
      value,
      min: widget.min,
      max: widget.max,
      geometry: widget.geometry,
      centre: centre,
      radius: _radiusFor(size),
    );
    final r = _style.ringThumbRadius;
    return Positioned(
      left: p.dx - r,
      top: p.dy - r,
      width: r * 2,
      height: r * 2,
      child: Center(
        child: _dimmed(widget.thumbBuilder!(context, isStart)),
      ),
    );
  }

  /// One step for a reader, or 5% of the scale on a continuous dial.
  double get _nudgeStep => widget.divisions == null
      ? (widget.max - widget.min) / 20
      : (widget.max - widget.min) / widget.divisions!;

  void _nudge(int direction) {
    final step = _nudgeStep * direction.abs();
    direction = direction.isNegative ? -1 : 1;
    if (!widget._isRange) {
      _setKeyed(_step(_value, step * direction));
      return;
    }
    _setKeyed(
      _step(_keyOnStart ? _range.start : _range.end, step * direction),
    );
  }

  /// One step from [from].
  ///
  /// A CLOSED dial WRAPS rather than stopping: midnight is one step
  /// past 23:45, and a keyboard that stopped there could not reach the
  /// early hours at all without going the long way round.
  double _step(double from, double delta) {
    final next = from + delta;
    if (!widget.geometry.isClosed) {
      return next.clamp(widget.min, widget.max);
    }
    final span = widget.max - widget.min;
    return widget.min + ((next - widget.min) % span + span) % span;
  }
}

/// The ring, its filled arc, its marks and — unless the caller builds
/// its own — its thumbs.
class _RingPainter extends CustomPainter {
  const _RingPainter({
    required this.style,
    required this.geometry,
    required this.startFraction,
    required this.endFraction,
    required this.isRange,
    required this.enabled,
    required this.markFractions,
    required this.thumbRadius,
    required this.drawThumbs,
    required this.segmentBounds,
    required this.focused,
    this.focusOnStart,
  });

  final ResolvedSliderStyle style;
  final CircularSliderGeometry geometry;
  final double startFraction;
  final double endFraction;
  final bool isRange;
  final bool enabled;
  final List<double> markFractions;
  final double thumbRadius;
  final bool drawThumbs;

  /// Seams, as fractions, both ends included. Empty means one arc.
  final List<double> segmentBounds;

  final bool focused;

  /// On a range, which thumb the keyboard is driving. Null on a single
  /// dial, where there is only one.
  final bool? focusOnStart;

  Color _dim(Color c) =>
      enabled ? c : c.withValues(alpha: c.a * style.disabledOpacity);

  @override
  void paint(Canvas canvas, Size size) {
    final centre = Offset(size.width / 2, size.height / 2);
    final radius =
        (math.min(size.width, size.height) - style.ringThickness) / 2 -
        thumbRadius;
    if (radius <= 0) return;

    final rect = Rect.fromCircle(center: centre, radius: radius);
    final cap = style.ringCapped ? StrokeCap.round : StrokeCap.butt;

    final base = Paint()
      ..color = _dim(style.inactiveColor)
      ..style = PaintingStyle.stroke
      ..strokeWidth = style.ringThickness
      ..strokeCap = cap;

    // The gap is in POINTS along the ring, converted to radians here,
    // so a seam looks the same on a 120-point dial and a 320-point
    // one. A fixed ANGLE would be a hairline on the small one and a
    // canyon on the big one.
    final gapAngle = style.segmentGap / radius;
    // Half the ring's thickness, as an angle at this radius — what a
    // round cap adds beyond the arc it finishes.
    final capAngle = style.ringThickness / 2 / radius;

    // Every arc to draw, in FRACTION space, with the seams already
    // taken out. One entry when nothing is segmented.
    final spans = _paddedSpans(gapAngle, capAngle);

    for (final s in spans) {
      canvas.drawArc(rect, _angleAt(s.a), _sweepBetween(s.a, s.b), false, base);
    }

    final active = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = style.ringThickness
      ..strokeCap = cap;
    if (style.trackGradient != null) {
      active.shader = style.trackGradient!.createShader(rect);
    } else {
      active.color = _dim(style.activeColor);
    }

    // The fill is drawn PER SEGMENT, clipped to each one.
    //
    // It used to be drawn whole and the seams cut back out of it with
    // `BlendMode.clear` — which took each filled segment's round CAPS
    // with them, so a segmented ring's fill ended flat and short of
    // its own arc. Intersecting instead means every filled piece gets
    // the same cap the empty one under it has.
    for (final seg in spans) {
      for (final fill in _fillSpans()) {
        final a = math.max(seg.a, fill.a);
        final b = math.min(seg.b, fill.b);
        if (b <= a) continue;
        canvas.drawArc(rect, _angleAt(a), _sweepBetween(a, b), false, active);
      }
    }

    for (final m in markFractions) {
      // A mark in a SEAM is a dot floating in a hole. The commonest
      // way to get one is to mark the same values the ring is cut at,
      // which is the first thing anyone tries — and the dot then sits
      // dead centre of the gap looking like debris.
      if (spans.isNotEmpty && !spans.any((s) => m >= s.a && m <= s.b)) {
        continue;
      }
      final angle = geometry.startAngle + geometry.sweepAngle * m;
      final p = Offset(
        centre.dx + radius * math.cos(angle),
        centre.dy + radius * math.sin(angle),
      );
      final inSpan = CircularSliderMath.spanContains(
        m,
        start: isRange ? startFraction : 0.0,
        end: endFraction,
        closed: geometry.isClosed,
      );
      canvas.drawCircle(
        p,
        style.tickStyle.radius,
        Paint()
          ..color = _dim(
            inSpan ? style.tickStyle.activeColor : style.tickStyle.color,
          ),
      );
    }

    if (!drawThumbs) return;
    if (isRange) {
      _paintThumb(
        canvas,
        centre,
        radius,
        startFraction,
        ring: focused && focusOnStart == true,
      );
    }
    _paintThumb(
      canvas,
      centre,
      radius,
      endFraction,
      ring: focused && focusOnStart != true,
    );
  }

  /// The angle a fraction of the scale sits at.
  double _angleAt(double t) => geometry.startAngle + geometry.sweepAngle * t;

  double _sweepBetween(double a, double b) => geometry.sweepAngle * (b - a);

  /// Every arc of the ring, in FRACTION space, with half a seam taken
  /// off each side of every interior boundary — and none off the outer
  /// ends, so an open ring still starts and finishes where the reader
  /// expects.
  ///
  /// The seam allowance includes the CAP: a round cap hangs half the
  /// ring's thickness past the arc it finishes, and unaccounted for
  /// the two caps of a seam grew towards each other until they met.
  ///
  /// On a CLOSED dial the first and last boundary are the SAME point,
  /// so the seam between them is interior like any other — it was the
  /// one seam with no gap at all.
  List<({double a, double b})> _paddedSpans(double gapAngle, double capAngle) {
    if (segmentBounds.isEmpty) return const [(a: 0.0, b: 1.0)];

    final total = geometry.sweepAngle.abs();
    if (total == 0) return const [];
    final capInset = style.ringCapped ? capAngle : 0.0;
    // Angles converted to fractions of the sweep, so everything below
    // is one comparison rather than two coordinate systems.
    final padT = (gapAngle / 2 + capInset) / total;
    final closed = geometry.isClosed;

    final spans = <({double a, double b})>[];
    for (var i = 0; i < segmentBounds.length - 1; i++) {
      final isFirst = i == 0;
      final isLast = i == segmentBounds.length - 2;
      final a = segmentBounds[i] + ((isFirst && !closed) ? 0 : padT);
      final b = segmentBounds[i + 1] - ((isLast && !closed) ? 0 : padT);
      if (b > a) spans.add((a: a, b: b));
    }
    return spans;
  }

  /// The filled part, as one or two non-wrapping intervals.
  ///
  /// Two when a closed dial's range runs through the seam — 22:00 to
  /// 06:00 is the eight hours through midnight, and as a single
  /// interval it would be the sixteen the other way.
  List<({double a, double b})> _fillSpans() {
    final from = isRange ? startFraction : 0.0;
    final to = endFraction;
    if (from <= to) return [(a: from, b: to)];
    if (geometry.isClosed) {
      return [(a: from, b: 1.0), (a: 0.0, b: to)];
    }
    return [(a: to, b: from)];
  }

  void _paintThumb(
    Canvas canvas,
    Offset centre,
    double radius,
    double t, {
    bool ring = false,
  }) {
    final angle = geometry.startAngle + geometry.sweepAngle * t;
    final p = Offset(
      centre.dx + radius * math.cos(angle),
      centre.dy + radius * math.sin(angle),
    );
    canvas.drawCircle(
      p + SliderDefaults.shadowOffset,
      thumbRadius,
      Paint()
        ..color = _dim(
          style.containerBorderColor.withValues(
            alpha: SliderDefaults.shadowOpacity,
          ),
        )
        ..maskFilter = const MaskFilter.blur(
          BlurStyle.normal,
          SliderDefaults.shadowBlur,
        ),
    );
    canvas.drawCircle(p, thumbRadius, Paint()..color = _dim(style.thumbColor));
    canvas.drawCircle(
      p,
      thumbRadius,
      Paint()
        ..color = _dim(style.activeColor)
        ..style = PaintingStyle.stroke
        ..strokeWidth = SliderDefaults.thumbBorderWidth,
    );

    if (!ring) return;
    // Says which thumb the arrow keys are about to move — a state
    // neither the selection nor the value carries.
    canvas.drawCircle(
      p,
      thumbRadius + 4,
      Paint()
        ..color = _dim(style.activeColor).withValues(alpha: 0.5)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.startFraction != startFraction ||
      old.endFraction != endFraction ||
      old.geometry != geometry ||
      old.enabled != enabled ||
      old.drawThumbs != drawThumbs ||
      old.focused != focused ||
      old.focusOnStart != focusOnStart ||
      !listEquals(old.segmentBounds, segmentBounds) ||
      !listEquals(old.markFractions, markFractions);
}

/// A drag that claims the pointer as soon as it lands on the ring.
///
/// The problem it solves is the gesture ARENA, not the maths. A dial
/// inside a scrolling page puts its pan recognizer up against the
/// scroll view's vertical drag recognizer; the scrollable wins, and
/// the dial stops responding exactly where a reader is most likely to
/// grab it — near the top and bottom of the ring, where the tangent
/// runs the same way the page scrolls. Reported from a real page.
///
/// Winning the arena unconditionally would be worse: the whole square
/// box would then swallow every vertical drag, and a dial in a list
/// would pin the page. So it accepts ON the ring and rejects anywhere
/// else — the hole, the corners, the gap of an open gauge.
class _RingPanRecognizer extends OneSequenceGestureRecognizer {
  /// Whether a local point is on the track.
  bool Function(Offset local)? isOnRing;

  ValueChanged<Offset>? onRingDown;
  ValueChanged<Offset>? onRingUpdate;
  VoidCallback? onRingEnd;

  int? _pointer;

  @override
  String get debugDescription => 'ring pan';

  @override
  void addAllowedPointer(PointerDownEvent event) {
    if (isOnRing?.call(event.localPosition) != true) {
      // Not ours. Resolving as rejected lets the scrollable have it
      // straight away rather than after a slop threshold.
      resolve(GestureDisposition.rejected);
      return;
    }
    _pointer = event.pointer;
    startTrackingPointer(event.pointer, event.transform);
    // Immediately: waiting for the drag to exceed touch slop hands the
    // scrollable a chance to claim it first.
    resolve(GestureDisposition.accepted);
    onRingDown?.call(event.localPosition);
  }

  @override
  void handleEvent(PointerEvent event) {
    if (event.pointer != _pointer) return;
    if (event is PointerMoveEvent) {
      onRingUpdate?.call(event.localPosition);
      return;
    }
    if (event is PointerUpEvent || event is PointerCancelEvent) {
      onRingEnd?.call();
      stopTrackingPointer(event.pointer);
      _pointer = null;
    }
  }

  @override
  void didStopTrackingLastPointer(int pointer) {
    _pointer = null;
  }
}
