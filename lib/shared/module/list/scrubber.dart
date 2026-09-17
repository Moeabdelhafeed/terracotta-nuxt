import 'dart:math' as math;

import 'package:flutter/gestures.dart' show EagerGestureRecognizer;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'
    show KeyDownEvent, KeyRepeatEvent, LogicalKeyboardKey;

import '../../../core/extensions/theme_colors_extension.dart';
import '../../../core/localization/strings/list_strings.dart';
import '../../../core/tokens/extensions.dart';
import 'scrubber_models.dart';

// ───────────────────────────────────────────────────────────────
// A-Z scrubber overlay (for grouped lists and grids)
// ───────────────────────────────────────────────────────────────

/// The size one mark is drawn at.
const double _kLabelFontSize = 10;

/// Right-side strip of section keys. Drag finger over to jump to
/// the corresponding section. The widget receives the ordered set
/// of section keys + a callback that takes the index of the FIRST
/// item in the tapped section so the parent can scroll there.
class GlobalScrubber extends StatefulWidget {
  const GlobalScrubber({
    required this.keys,
    required this.onJump,
    required this.placement,
  });

  final List<Object> keys;
  final Future<void> Function(Object key) onJump;
  final ScrubberPlacement placement;

  @override
  State<GlobalScrubber> createState() => _GlobalScrubberState();
}

class _GlobalScrubberState extends State<GlobalScrubber> {
  Object? _hover;

  /// Whether a finger is on the strip right now.
  bool _held = false;

  /// Where it is, along the strip — the centre of the magnification.
  double? _touch;

  /// Where the KEYBOARD is. Separate from [_hover], which follows a
  /// finger: a reader arrowing down the strip has no finger on it.
  int _focused = -1;

  late final FocusNode _focusNode = FocusNode(
    debugLabel: 'GlobalScrubber',
    // ON THE NODE, not on a `Focus` wrapper. The wrapper that makes
    // the strip reachable by Tab owns the node, so a nested `Focus`
    // with its own `onKeyEvent` never saw a key — the event goes to
    // whichever node has focus, which is this one.
    onKeyEvent: _onKey,
  );

  /// How much the letter under the finger grows.
  static const double _magnifyBoost = 1.1;

  /// How far the swell reaches, as a multiple of the gap between two
  /// letters.
  ///
  /// Proportional rather than a fixed number of points: a strip of
  /// four letters spaces them a hundred points apart and a strip of
  /// twenty-six spaces them fifteen, so any constant reach either
  /// swells the whole strip or none of the neighbours.
  static const double _magnifySlots = 1.6;

  /// The padding between the strip's edge and its first mark, on the
  /// axis the marks run along.
  static const double _stripPad = 6;

  static const double _restingThickness = 22;
  static const double _heldThickness = 30;

  /// The room one label needs before the strip has to start dropping
  /// some.
  ///
  /// SCALED by the reader's text setting. It was a flat fourteen —
  /// which is exactly what a ten-point letter measures at 100%, and
  /// nineteen at 130%. A strip that budgeted fourteen either way put
  /// twenty-three marks in room for seventeen and overflowed its own
  /// Column by a hundred points. The 1.5 is slack on top of the
  /// measured ratio, because a font the app has not seen may sit
  /// taller again in its line box.
  double _labelExtent(BuildContext context) =>
      MediaQuery.textScalerOf(context).scale(_kLabelFontSize) * 1.5;

  bool get _horizontal => widget.placement.isHorizontal;

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  /// The labels that fit, and a dot for every run they stand in for.
  ///
  /// Twenty-six letters in a two-hundred-point strip is eight points a
  /// letter — they overlapped, and the strip became unreadable exactly
  /// when it was most needed. Sampling keeps the ends and the spacing
  /// honest; the dots say something was left out, which is what iOS
  /// does with the same problem.
  List<int> _visibleIndices(double usable, double labelExtent) {
    final total = widget.keys.length;
    if (total == 0) return const [];
    final room = (usable / labelExtent).floor();
    if (room >= total) return [for (var i = 0; i < total; i++) i];
    // Half the room goes to the DOTS that stand between the letters —
    // a mark is a mark, and rendering a dot per skipped key was how
    // twenty-six letters still overflowed a strip with room for
    // fourteen marks.
    final letters = (room / 2).floor();
    if (letters <= 2) return [0, total - 1];
    final step = (total - 1) / (letters - 1);
    final out = <int>{};
    for (var i = 0; i < letters; i++) {
      out.add((i * step).round().clamp(0, total - 1));
    }
    return out.toList()..sort();
  }

  /// [along] is measured from the strip's edge; [usable] is the room
  /// the marks are actually laid out in, which is that edge minus the
  /// padding at both ends.
  void _handle(double along, double usable) {
    if (widget.keys.isEmpty) return;
    if (usable <= 0) return;
    final ratio = ((along - _stripPad) / usable).clamp(0.0, 0.9999);
    final idx = (ratio * widget.keys.length).floor();
    setState(() => _touch = along);
    final key = widget.keys[idx];
    if (key != _hover) {
      setState(() => _hover = key);
      widget.onJump(key);
    }
  }

  void _release() {
    setState(() {
      _held = false;
      _hover = null;
      _touch = null;
    });
  }

  void _setHeld(bool held) {
    if (_held == held) return;
    setState(() => _held = held);
  }

  /// Moves the keyboard cursor and jumps with it.
  void _moveFocus(int delta) {
    if (widget.keys.isEmpty) return;
    final next = (_focused < 0 ? 0 : _focused + delta).clamp(
      0,
      widget.keys.length - 1,
    );
    if (next == _focused) return;
    setState(() => _focused = next);
    widget.onJump(widget.keys[next]);
  }

  void _jumpTo(int index) {
    if (widget.keys.isEmpty) return;
    final i = index.clamp(0, widget.keys.length - 1);
    setState(() => _focused = i);
    widget.onJump(widget.keys[i]);
  }

  /// How much the mark at position [ordinal] of [count] is swollen.
  double _scaleForMark(int ordinal, int count, double usable) {
    if (count == 0) return 1;
    final touch = _touch;
    if (touch == null) return 1;
    final slot = usable / count;
    // The marks start AFTER the padding, so a centre measured from the
    // strip's edge has to start there too — otherwise the swell sits
    // six points off the finger.
    final centre = _stripPad + (ordinal + 0.5) * slot;
    final distance = (touch - centre).abs();
    final radius = slot * _magnifySlots;
    if (radius <= 0 || distance >= radius) return 1;
    // Cosine falloff: flat at the peak, flat at the edges, and no
    // corner in between — a linear ramp reads as a wedge.
    final t = distance / radius;
    return 1 + _magnifyBoost * (math.cos(t * math.pi) + 1) / 2;
  }

  KeyEventResult _onKey(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
      return KeyEventResult.ignored;
    }
    final forward = _horizontal
        ? LogicalKeyboardKey.arrowRight
        : LogicalKeyboardKey.arrowDown;
    final back = _horizontal
        ? LogicalKeyboardKey.arrowLeft
        : LogicalKeyboardKey.arrowUp;
    if (event.logicalKey == forward) {
      _moveFocus(1);
      return KeyEventResult.handled;
    }
    if (event.logicalKey == back) {
      _moveFocus(-1);
      return KeyEventResult.handled;
    }
    if (event.logicalKey == LogicalKeyboardKey.home) {
      _jumpTo(0);
      return KeyEventResult.handled;
    }
    if (event.logicalKey == LogicalKeyboardKey.end) {
      _jumpTo(widget.keys.length - 1);
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    final active = _held || _focused >= 0;
    return LayoutBuilder(
      builder: (ctx, c) {
        final extent = _horizontal ? c.maxWidth : c.maxHeight;
        // What the Column is handed, not what the strip occupies: the
        // padding is inside the box the marks have to fit in.
        final usable = math.max(0.0, extent - _stripPad * 2);
        final visible = _visibleIndices(usable, _labelExtent(ctx));
        // One mark per letter shown, plus ONE dot for each run
        // skipped between them — not one per skipped key.
        final marks = <int?>[];
        for (var n = 0; n < visible.length; n++) {
          if (n > 0 && visible[n] - visible[n - 1] > 1) marks.add(null);
          marks.add(visible[n]);
        }
        final labels = [
          for (var n = 0; n < marks.length; n++)
            _ScrubberLabel(
              text: marks[n] == null ? '·' : '${widget.keys[marks[n]!]}',
              // Scaled by where the mark SITS, not by which key it
              // stands for — once the strip is sampled the two are
              // different, and the swell has to follow the finger.
              scale: _scaleForMark(n, marks.length, usable),
              active:
                  marks[n] != null &&
                  (_hover == widget.keys[marks[n]!] || _focused == marks[n]),
            ),
        ];
        return Semantics(
          container: true,
          label: ListStrings.sectionIndex,
          child: FocusableActionDetector(
            focusNode: _focusNode,
            // A real focus stop. `Focus` alone was not reliably in the
            // traversal order inside the list's own scope, so Tab
            // never reached the strip.
            onFocusChange: (has) {
              if (!has) setState(() => _focused = -1);
            },
            child: RawGestureDetector(
              // EAGER. The strip sits over a scroll view, and a drag
              // along it is exactly what that scroll view wants — the
              // gesture arena handed the pointer to the list, so the
              // page scrolled under the finger instead of the strip
              // tracking it. An eager recogniser claims the arena on
              // contact, before anyone else can compete.
              gestures: <Type, GestureRecognizerFactory>{
                EagerGestureRecognizer:
                    GestureRecognizerFactoryWithHandlers<
                      EagerGestureRecognizer
                    >(EagerGestureRecognizer.new, (_) {}),
              },
              child: Listener(
                behavior: HitTestBehavior.opaque,
                onPointerDown: (e) {
                  _focusNode.requestFocus();
                  _setHeld(true);
                  _handle(
                    _horizontal ? e.localPosition.dx : e.localPosition.dy,
                    usable,
                  );
                },
                onPointerMove: (e) => _handle(
                  _horizontal ? e.localPosition.dx : e.localPosition.dy,
                  usable,
                ),
                onPointerUp: (_) => _release(),
                onPointerCancel: (_) => _release(),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  curve: Curves.easeOutCubic,
                  width: _horizontal
                      ? null
                      : (active ? _heldThickness : _restingThickness),
                  height: _horizontal
                      ? (active ? _heldThickness : _restingThickness)
                      : null,
                  alignment: Alignment.center,
                  padding: _horizontal
                      ? const EdgeInsets.symmetric(horizontal: _stripPad)
                      : const EdgeInsets.symmetric(vertical: _stripPad),
                  decoration: BoxDecoration(
                    // The strip LIFTS while it is engaged, so the
                    // control says so rather than leaving the reader
                    // to infer it from one letter changing colour.
                    color: active
                        ? context.primaryColors.primary.withValues(
                            alpha: 0.10,
                          )
                        : const Color(0x00000000),
                    borderRadius: BorderRadius.circular(context.radii.full),
                  ),
                  child: _horizontal
                      ? Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: labels,
                        )
                      : Column(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: labels,
                        ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// One mark on the strip — a section's letter, or a dot standing in
/// for the run the strip had no room to name.
class _ScrubberLabel extends StatelessWidget {
  const _ScrubberLabel({
    required this.text,
    required this.scale,
    required this.active,
  });

  final String text;
  final double scale;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return AnimatedScale(
      duration: const Duration(milliseconds: 120),
      curve: Curves.easeOutCubic,
      scale: scale,
      child: Text(
        text,
        style: TextStyle(
          fontSize: _kLabelFontSize,
          fontWeight: FontWeight.w700,
          color: active
              ? context.primaryColors.primary
              : context.textColors.primary.withValues(alpha: 0.6),
        ),
      ),
    );
  }
}

/// Lays [strip] over [child] on the edge [placement] names.
///
/// Shared by `GlobalList` and `GlobalGrid` — the strip is the same
/// control on both, and the grid's own copy had drifted a year behind
/// (no keyboard, no magnification, and a `GestureDetector` the scroll
/// view won the arena against).
Widget scrubberOverlay({
  required Widget child,
  required Widget strip,
  required ScrubberPlacement placement,
}) {
  return Stack(
    children: [
      Positioned.fill(child: child),
      // `start` and `end` are DIRECTIONAL, so the strip lands under
      // the thumb in Arabic too; `top` and `bottom` lay it across.
      switch (placement) {
        ScrubberPlacement.end => PositionedDirectional(
          end: 0,
          top: 0,
          bottom: 0,
          child: strip,
        ),
        ScrubberPlacement.start => PositionedDirectional(
          start: 0,
          top: 0,
          bottom: 0,
          child: strip,
        ),
        ScrubberPlacement.top => Positioned(
          left: 0,
          right: 0,
          top: 0,
          child: strip,
        ),
        ScrubberPlacement.bottom => Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: strip,
        ),
      },
    ],
  );
}
