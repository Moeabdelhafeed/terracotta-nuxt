import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'key_repeater.dart';
import 'slider_models.dart';
import 'slider_style.dart';
import 'theme/slider_theme.dart';

/// A span picked over something you can SEE.
///
/// A video trimmer's filmstrip, a waveform, a night's sleep stages, a
/// chart. What makes it a different widget from `GlobalSlider.range`
/// is that the track is CONTENT the caller draws: the handles frame
/// it, dim what falls outside, and never cover it.
///
/// The value axis is whatever the caller says — seconds, samples,
/// minutes past midnight. It is reported as a record rather than
/// `RangeValues` for the same reason the circular one is: nothing here
/// wants a type that asserts an order it may not be told about.
class GlobalTrimSlider extends StatefulWidget {
  const GlobalTrimSlider({
    super.key,
    required this.min,
    required this.max,
    required this.values,
    required this.onChanged,
    this.background,
    this.playhead,
    this.onPlayheadChanged,
    this.minSpan,
    this.maxSpan,
    this.height = defaultHeight,
    this.keyboardStep,
    this.autofocus = false,
    this.focusNode,
    this.showDragReadout = true,
    this.enabled = true,
    this.valueFormatter,
    this.semanticLabel,
    this.onChangeStart,
    this.onChangeEnd,
    this.style,
  }) : assert(min < max, 'min ($min) must be below max ($max)'),
       assert(
         minSpan == null || maxSpan == null || minSpan <= maxSpan,
         'minSpan ($minSpan) cannot exceed maxSpan ($maxSpan)',
       );

  /// A film strip's usual height.
  static const double defaultHeight = 64;

  final double min;
  final double max;

  /// The selected span. `start` is always the earlier end.
  final ({double start, double end}) values;
  final ValueChanged<({double start, double end})> onChanged;

  /// What the span is drawn OVER — thumbnails, a waveform, a chart.
  ///
  /// It is laid out edge to edge under the handles, so the caller can
  /// hand it a `Row` of images or a `CustomPaint` without knowing
  /// where the handles are.
  final Widget? background;

  /// A separate marker for "where playback is", independent of the
  /// span. Null draws none.
  final double? playhead;

  /// Called when the playhead is SCRUBBED — a drag that starts on it,
  /// or a tap inside the span.
  ///
  /// Null makes the playhead a read-only marker.
  final ValueChanged<double>? onPlayheadChanged;

  /// The shortest span the handles may make.
  ///
  /// Without one, a trimmer can be closed to zero and the reader is
  /// left holding two handles on top of each other with no way to tell
  /// them apart.
  final double? minSpan;

  /// The longest — a story clip capped at 60 seconds.
  final double? maxSpan;

  final double height;

  /// How far one arrow key moves a handle. Null is a fiftieth of the
  /// range — small enough to trim a 20-second clip to the frame,
  /// coarse enough to cross a three-minute one without holding the key
  /// down all day.
  final double? keyboardStep;

  final bool autofocus;
  final FocusNode? focusNode;

  /// The pill that says what the span is WHILE it is being changed.
  ///
  /// A trimmer with no readout is a picture of a decision the reader
  /// cannot check: two handles on a filmstrip say where, and nothing
  /// says how long.
  final bool showDragReadout;

  final bool enabled;

  /// How a value READS, in the span's label and the announcements.
  final String Function(double)? valueFormatter;

  final String? semanticLabel;

  final ValueChanged<double>? onChangeStart;
  final ValueChanged<double>? onChangeEnd;

  final SliderStyle? style;

  @override
  State<GlobalTrimSlider> createState() => _GlobalTrimSliderState();
}

/// What a drag — or the keyboard — is holding.
enum TrimTarget {
  /// The earlier end.
  start,

  /// The later end.
  end,

  /// The whole window, sliding without changing length.
  span,

  /// The playback marker, which never leaves the span.
  playhead,
}

class _GlobalTrimSliderState extends State<GlobalTrimSlider> {
  ResolvedSliderStyle _style = ResolvedSliderStyle.fallback;

  TrimTarget? _grab;

  /// What the arrow keys move. Null until the widget is focused.
  TrimTarget? _keyTarget;

  bool _focused = false;

  /// Drives the repeat while an arrow is held — the platform's own
  /// `KeyRepeatEvent` is not delivered everywhere.
  final _repeat = KeyRepeater();

  /// Where inside the span the finger landed, so dragging the whole
  /// span does not snap its start to the fingertip.
  double _grabOffset = 0;

  ({double start, double end}) _values = (start: 0, end: 0);
  double? _playhead;

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
  void didUpdateWidget(GlobalTrimSlider old) {
    super.didUpdateWidget(old);
    if (widget.values != old.values || widget.playhead != old.playhead) {
      _sync();
    }
  }

  void _sync() {
    final lo = widget.values.start.clamp(widget.min, widget.max);
    final hi = widget.values.end.clamp(widget.min, widget.max);
    // Ordered on the way in: a caller who hands over an inverted pair
    // gets a span, not a negative one.
    _values = (start: math.min(lo, hi), end: math.max(lo, hi));
    _playhead = widget.playhead?.clamp(widget.min, widget.max);
  }

  double get _span => widget.max - widget.min;

  double _fractionOf(double v) =>
      SliderMath.fraction(v, min: widget.min, max: widget.max);

  double _valueAt(double dx, double width) {
    final inset = _style.trimHandleWidth;
    final usable = width - inset * 2;
    if (usable <= 0) return widget.min;
    final t = ((dx - inset) / usable).clamp(0.0, 1.0);
    return widget.min + _span * t;
  }

  double _xOf(double value, double width) {
    final inset = _style.trimHandleWidth;
    return inset + (width - inset * 2) * _fractionOf(value);
  }

  // ─── Gestures ──────────────────────────────────────────────

  TrimTarget _grabFor(double dx, double width) {
    final startX = _xOf(_values.start, width);
    final endX = _xOf(_values.end, width);
    // A handle's grab zone is its own width plus a margin, because a
    // 10-point bar is not a target: the two handles of a closed span
    // are otherwise impossible to tell apart under a fingertip.
    final reach = _style.trimHandleWidth + _style.trimHandleTouchSlop;

    if ((dx - startX).abs() <= reach) return TrimTarget.start;
    if ((dx - endX).abs() <= reach) return TrimTarget.end;
    if (widget.onPlayheadChanged != null &&
        _playhead != null &&
        (dx - _xOf(_playhead!, width)).abs() <= reach) {
      return TrimTarget.playhead;
    }
    // Inside the span, and the caller wants a scrub: that is what a
    // tap on the film means in every editor.
    if (dx > startX && dx < endX) {
      return widget.onPlayheadChanged != null
          ? TrimTarget.playhead
          : TrimTarget.span;
    }
    return TrimTarget.span;
  }

  void _onDown(double dx, double width) {
    if (!widget.enabled) return;
    _grab = _grabFor(dx, width);
    // Whatever the finger just grabbed is what the arrows move next —
    // otherwise a reader who drags a handle then reaches for the
    // keyboard moves a different one.
    _keyTarget = _grab;
    _grabOffset = _valueAt(dx, width) - _values.start;
    widget.onChangeStart?.call(_valueAt(dx, width));
    _apply(dx, width, initial: true);
  }

  void _onMove(double dx, double width) {
    if (!widget.enabled || _grab == null) return;
    _apply(dx, width);
  }

  void _onUp() {
    if (_grab == null) return;
    widget.onChangeEnd?.call(
      switch (_grab!) {
        TrimTarget.start => _values.start,
        TrimTarget.end => _values.end,
        TrimTarget.playhead => _playhead ?? _values.start,
        TrimTarget.span => _values.start,
      },
    );
    // Through `setState`: the readout is drawn from `_grab`, and
    // clearing it without a rebuild left the pill on screen after the
    // finger came off.
    setState(() => _grab = null);
  }

  void _apply(double dx, double width, {bool initial = false}) {
    final v = _valueAt(dx, width);

    switch (_grab!) {
      case TrimTarget.playhead:
        final next = v.clamp(_values.start, _values.end);
        setState(() => _playhead = next);
        widget.onPlayheadChanged?.call(next);

      case TrimTarget.start:
        _emit((start: v, end: _values.end), movedStart: true);

      case TrimTarget.end:
        _emit((start: _values.start, end: v), movedStart: false);

      case TrimTarget.span:
        if (initial) return;
        // The whole window slides, keeping its LENGTH — and stops at
        // the ends rather than being squashed against them.
        final length = _values.end - _values.start;
        var start = v - _grabOffset;
        start = start.clamp(widget.min, widget.max - length);
        _emit((start: start, end: start + length), movedStart: true);
    }
  }

  /// Applies the span rules, then reports.
  ///
  /// The end that did NOT move is the one that gives way: dragging the
  /// start past a `minSpan` pushes the end along rather than refusing,
  /// which is what a trimmer at its floor should feel like.
  void _emit(({double start, double end}) raw, {required bool movedStart}) {
    final next = _resolveSpan(raw, movedStart: movedStart);
    if (next == _values) return;

    final minSpan = widget.minSpan;
    final maxSpan = widget.maxSpan;
    if (_style.enableHaptic &&
        (next.start == widget.min ||
            next.end == widget.max ||
            (minSpan != null && (next.end - next.start) == minSpan) ||
            (maxSpan != null && (next.end - next.start) == maxSpan))) {
      // At an end or against a limit — the one place a trimmer has
      // anything to say through a fingertip.
      HapticFeedback.selectionClick();
    }
    setState(() => _values = next);
    widget.onChanged(next);
  }

  /// The span rules, with nothing reported and nothing set.
  ///
  /// Pure, because the semantics node has to say what an increase
  /// WOULD read before the reader commits to it — and because the
  /// framework asserts that a node carrying `value` and an increase
  /// action carries `increasedValue` too.
  ({double start, double end}) _resolveSpan(
    ({double start, double end}) raw, {
    required bool movedStart,
  }) {
    var start = raw.start.clamp(widget.min, widget.max);
    var end = raw.end.clamp(widget.min, widget.max);

    // Crossed over: the handles SWAP rather than inverting the span.
    if (start > end) {
      final t = start;
      start = end;
      end = t;
      movedStart = !movedStart;
    }

    final minSpan = widget.minSpan;
    if (minSpan != null && end - start < minSpan) {
      if (movedStart) {
        start = math.min(start, widget.max - minSpan);
        end = start + minSpan;
      } else {
        end = math.max(end, widget.min + minSpan);
        start = end - minSpan;
      }
    }

    final maxSpan = widget.maxSpan;
    if (maxSpan != null && end - start > maxSpan) {
      if (movedStart) {
        end = start + maxSpan;
      } else {
        start = end - maxSpan;
      }
    }

    return (start: start, end: end);
  }

  /// What the span would read after one step in [direction].
  ({double start, double end}) _preview(int direction) {
    final delta = _keyStep * direction;
    return switch (_keyTarget ?? TrimTarget.start) {
      TrimTarget.start => _resolveSpan(
        (start: _values.start + delta, end: _values.end),
        movedStart: true,
      ),
      TrimTarget.end => _resolveSpan(
        (start: _values.start, end: _values.end + delta),
        movedStart: false,
      ),
      TrimTarget.span => () {
        final length = _values.end - _values.start;
        final start = (_values.start + delta).clamp(
          widget.min,
          widget.max - length,
        );
        return (start: start, end: start + length);
      }(),
      // Scrubbing does not change the span.
      TrimTarget.playhead => _values,
    };
  }

  // ─── Build ─────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    _style = (widget.style ?? const SliderStyle()).resolve(context);

    String say(double v) =>
        widget.valueFormatter?.call(v) ?? v.toStringAsFixed(1);

    String spanText(({double start, double end}) v) =>
        '${say(v.start)} – ${say(v.end)}';

    final readout = spanText(_values);

    return Semantics(
      container: true,
      enabled: widget.enabled,
      label: widget.semanticLabel,
      value: readout,
      increasedValue: spanText(_preview(1)),
      decreasedValue: spanText(_preview(-1)),
      // A ring has no left and right; a TIMELINE does, so this one gets
      // the two actions that match its axis.
      onIncrease: widget.enabled ? () => _nudge(1) : null,
      onDecrease: widget.enabled ? () => _nudge(-1) : null,
      child: Focus(
        focusNode: widget.focusNode,
        autofocus: widget.autofocus,
        canRequestFocus: widget.enabled,
        onFocusChange: (has) => setState(() {
          // A key held while focus moves away would otherwise repeat
          // for ever — nothing is left to hear the key-up.
          if (!has) _repeat.stop();
          _focused = has;
          // Focus lands on the START handle, which is where a reader
          // trimming from the top of a clip is going anyway.
          _keyTarget = has ? (_keyTarget ?? TrimTarget.start) : null;
        }),
        onKeyEvent: _onKey,
        child: ExcludeSemantics(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final width = constraints.hasBoundedWidth
                  ? constraints.maxWidth
                  : 320.0;

              return SizedBox(
                width: width,
                height: widget.height,
                child: RawGestureDetector(
                  behavior: HitTestBehavior.opaque,
                  gestures: <Type, GestureRecognizerFactory>{
                    // The same arena problem the ring has, for the same
                    // reason: a trimmer lives in a scrolling editor and
                    // a horizontal drag would otherwise be up for grabs
                    // between this and a page view.
                    _TrimPanRecognizer:
                        GestureRecognizerFactoryWithHandlers<
                          _TrimPanRecognizer
                        >(
                          () => _TrimPanRecognizer(),
                          (r) {
                            r.onTrimDown = (p) => _onDown(p.dx, width);
                            r.onTrimUpdate = (p) => _onMove(p.dx, width);
                            r.onTrimEnd = _onUp;
                          },
                        ),
                  },
                  child: Stack(
                    children: [
                      if (widget.background != null)
                        Positioned.fill(
                          // Inset by the handles, so the content the
                          // reader is trimming is never underneath one.
                          left: _style.trimHandleWidth,
                          right: _style.trimHandleWidth,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(
                              _style.containerRadius,
                            ),
                            // Dimmed with the frame. The painter fades
                            // what IT draws, and a bright filmstrip
                            // under a greyed-out frame reads as the
                            // one live thing on the strip.
                            child: widget.enabled
                                ? widget.background
                                : Opacity(
                                    opacity: _style.disabledOpacity,
                                    child: widget.background,
                                  ),
                          ),
                        ),
                      Positioned.fill(
                        child: CustomPaint(
                          painter: _TrimPainter(
                            style: _style,
                            startFraction: _fractionOf(_values.start),
                            endFraction: _fractionOf(_values.end),
                            playheadFraction: _playhead == null
                                ? null
                                : _fractionOf(_playhead!),
                            enabled: widget.enabled,
                            focusedHandle: _focused ? _keyTarget : null,
                          ),
                        ),
                      ),
                      if (widget.showDragReadout && _grab != null)
                        _buildReadout(context, width, say),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  /// The pill that appears WHILE a handle is moving.
  ///
  /// It sits inside the span rather than above the widget: a trimmer
  /// is usually the bottom strip of an editor, and a bubble hanging
  /// off its top edge lands on the frame the reader is looking at.
  Widget _buildReadout(
    BuildContext context,
    double width,
    String Function(double) say,
  ) {
    // What the reader is actually changing: a handle says its own
    // value, the whole span says its LENGTH, the playhead says where
    // playback is.
    final text = switch (_grab!) {
      TrimTarget.start => say(_values.start),
      TrimTarget.end => say(_values.end),
      TrimTarget.playhead => say(_playhead ?? _values.start),
      TrimTarget.span => say(_values.end - _values.start),
    };

    final anchor = switch (_grab!) {
      TrimTarget.start => _values.start,
      TrimTarget.end => _values.end,
      TrimTarget.playhead => _playhead ?? _values.start,
      TrimTarget.span => (_values.start + _values.end) / 2,
    };

    return Positioned(
      left: 0,
      right: 0,
      top: 0,
      bottom: 0,
      child: IgnorePointer(
        child: Align(
          // -1..1 across the box, so the pill follows the handle and
          // clamps itself at the ends instead of running off.
          alignment: Alignment(
            (_xOf(anchor, width) / width * 2 - 1).clamp(-1.0, 1.0),
            0,
          ),
          child: Container(
            padding: _style.valueBadgePadding,
            decoration: BoxDecoration(
              color: _style.activeColor,
              borderRadius: BorderRadius.circular(_style.valueBadgeRadius),
            ),
            child: Text(
              text,
              style: _style.valueStyle.copyWith(
                color: _style.trimGripColor,
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Left is EARLIER, whatever the language.
  ///
  /// The strip is a TIMELINE — the frames were shot in that order —
  /// and the content under it does not mirror, so neither does this.
  /// It is the argument the video seek bar already makes.
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

    if (key == LogicalKeyboardKey.arrowRight) {
      _nudge(1);
      _repeat.start(_nudge);
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.arrowLeft) {
      _nudge(-1);
      _repeat.start((m) => _nudge(-m));
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.home) {
      _keyed(widget.min);
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.end) {
      _keyed(widget.max);
      return KeyEventResult.handled;
    }
    // Space or Tab CYCLES what the arrows move. Three or four separate
    // traversal stops inside one strip is not navigation.
    if (key == LogicalKeyboardKey.space ||
        key == LogicalKeyboardKey.tab ||
        key == LogicalKeyboardKey.enter) {
      setState(() => _keyTarget = _nextTarget());
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  TrimTarget _nextTarget() {
    final order = <TrimTarget>[
      TrimTarget.start,
      TrimTarget.end,
      TrimTarget.span,
      if (widget.onPlayheadChanged != null) TrimTarget.playhead,
    ];
    final at = order.indexOf(_keyTarget ?? TrimTarget.start);
    return order[(at + 1) % order.length];
  }

  double get _keyStep => widget.keyboardStep ?? _span / 50;

  /// [direction] carries the MULTIPLIER too: a held key accelerates,
  /// so `3` is three steps forward rather than a third argument.
  void _nudge(int direction) {
    final target = _keyTarget ?? TrimTarget.start;
    final delta = _keyStep * direction;

    switch (target) {
      case TrimTarget.start:
        _emit(
          (start: _values.start + delta, end: _values.end),
          movedStart: true,
        );
      case TrimTarget.end:
        _emit(
          (start: _values.start, end: _values.end + delta),
          movedStart: false,
        );
      case TrimTarget.span:
        final length = _values.end - _values.start;
        final start = (_values.start + delta).clamp(
          widget.min,
          widget.max - length,
        );
        _emit((start: start, end: start + length), movedStart: true);
      case TrimTarget.playhead:
        final next = ((_playhead ?? _values.start) + delta).clamp(
          _values.start,
          _values.end,
        );
        setState(() => _playhead = next);
        widget.onPlayheadChanged?.call(next);
    }
  }

  /// Puts the keyboard's target at an absolute value.
  void _keyed(double v) {
    switch (_keyTarget ?? TrimTarget.start) {
      case TrimTarget.start:
        _emit((start: v, end: _values.end), movedStart: true);
      case TrimTarget.end:
        _emit((start: _values.start, end: v), movedStart: false);
      case TrimTarget.span:
        final length = _values.end - _values.start;
        final start = v.clamp(widget.min, widget.max - length);
        _emit((start: start, end: start + length), movedStart: true);
      case TrimTarget.playhead:
        final next = v.clamp(_values.start, _values.end);
        setState(() => _playhead = next);
        widget.onPlayheadChanged?.call(next);
    }
  }
}

/// The frame, the dimming, the two handles and the playhead.
class _TrimPainter extends CustomPainter {
  const _TrimPainter({
    required this.style,
    required this.startFraction,
    required this.endFraction,
    required this.playheadFraction,
    required this.enabled,
    required this.focusedHandle,
  });

  final ResolvedSliderStyle style;
  final double startFraction;
  final double endFraction;
  final double? playheadFraction;
  final bool enabled;

  /// Which handle the KEYBOARD is on, or null when nothing is focused.
  final TrimTarget? focusedHandle;

  Color _dim(Color c) =>
      enabled ? c : c.withValues(alpha: c.a * style.disabledOpacity);

  @override
  void paint(Canvas canvas, Size size) {
    final handle = style.trimHandleWidth;
    final usable = size.width - handle * 2;
    if (usable <= 0) return;

    final left = handle + usable * startFraction;
    final right = handle + usable * endFraction;
    // What falls OUTSIDE the span is dimmed rather than hidden: the
    // reader is choosing from the whole strip and has to see what
    // they are leaving out.
    final scrim = Paint()..color = _dim(style.trimScrimColor);
    canvas.drawRect(Rect.fromLTRB(0, 0, left, size.height), scrim);
    canvas.drawRect(
      Rect.fromLTRB(right, 0, size.width, size.height),
      scrim,
    );

    // The frame is drawn as four SOLID pieces — two bars and two
    // rails — never as one rectangle with the middle punched out.
    // `BlendMode.clear` does not respect widget layers: the
    // background sits in the SAME layer as this painter, so clearing
    // the middle erased the film the reader is trimming and left a
    // white hole. That was the "middle part is not visible" bug.
    final frame = Paint()..color = _dim(style.activeColor);
    final r = style.containerRadius;

    // Left bar, with only its outer corners rounded so it meets the
    // rails square.
    canvas.drawRRect(
      RRect.fromLTRBAndCorners(
        left - handle,
        0,
        left,
        size.height,
        topLeft: Radius.circular(r),
        bottomLeft: Radius.circular(r),
      ),
      frame,
    );
    canvas.drawRRect(
      RRect.fromLTRBAndCorners(
        right,
        0,
        right + handle,
        size.height,
        topRight: Radius.circular(r),
        bottomRight: Radius.circular(r),
      ),
      frame,
    );
    // The rails, spanning between the two bars.
    canvas.drawRect(
      Rect.fromLTRB(left, 0, right, style.trimRailHeight),
      frame,
    );
    canvas.drawRect(
      Rect.fromLTRB(
        left,
        size.height - style.trimRailHeight,
        right,
        size.height,
      ),
      frame,
    );

    // The grip lines that say a bar is draggable, and the focus ring
    // that says which one the arrows will move.
    final grip = Paint()
      ..color = _dim(style.trimGripColor)
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;
    for (final entry in [
      (x: left - handle / 2, isStart: true),
      (x: right + handle / 2, isStart: false),
    ]) {
      canvas.drawLine(
        Offset(entry.x, size.height * 0.32),
        Offset(entry.x, size.height * 0.68),
        grip,
      );
      if (focusedHandle == null) continue;
      final lit = switch (focusedHandle!) {
        TrimTarget.start => entry.isStart,
        TrimTarget.end => !entry.isStart,
        TrimTarget.span => true,
        TrimTarget.playhead => false,
      };
      if (!lit) continue;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTRB(
            entry.x - handle / 2 - 2,
            -2,
            entry.x + handle / 2 + 2,
            size.height + 2,
          ),
          Radius.circular(r + 2),
        ),
        Paint()
          ..color = _dim(style.activeColor).withValues(alpha: 0.6)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      );
    }

    final t = playheadFraction;
    if (t == null) return;
    final x = handle + usable * t;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
          x - style.trimPlayheadWidth / 2,
          0,
          style.trimPlayheadWidth,
          size.height,
        ),
        Radius.circular(style.trimPlayheadWidth / 2),
      ),
      Paint()..color = _dim(style.trimPlayheadColor),
    );
  }

  @override
  bool shouldRepaint(_TrimPainter old) =>
      old.startFraction != startFraction ||
      old.endFraction != endFraction ||
      old.playheadFraction != playheadFraction ||
      old.enabled != enabled ||
      old.focusedHandle != focusedHandle;
}

/// Claims a horizontal drag the moment it lands, for the same reason
/// the ring's does: a trimmer lives inside something that scrolls.
class _TrimPanRecognizer extends OneSequenceGestureRecognizer {
  ValueChanged<Offset>? onTrimDown;
  ValueChanged<Offset>? onTrimUpdate;
  VoidCallback? onTrimEnd;

  int? _pointer;

  @override
  String get debugDescription => 'trim pan';

  @override
  void addAllowedPointer(PointerDownEvent event) {
    _pointer = event.pointer;
    startTrackingPointer(event.pointer, event.transform);
    resolve(GestureDisposition.accepted);
    onTrimDown?.call(event.localPosition);
  }

  @override
  void handleEvent(PointerEvent event) {
    if (event.pointer != _pointer) return;
    if (event is PointerMoveEvent) {
      onTrimUpdate?.call(event.localPosition);
      return;
    }
    if (event is PointerUpEvent || event is PointerCancelEvent) {
      onTrimEnd?.call();
      stopTrackingPointer(event.pointer);
      _pointer = null;
    }
  }

  @override
  void didStopTrackingLastPointer(int pointer) => _pointer = null;
}
