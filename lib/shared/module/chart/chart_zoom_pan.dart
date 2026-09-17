import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'chart_models.dart';

/// Reusable zoom + pan wrapper for any chart widget.
///
/// Desktop / web (mouse):
/// - Hold Shift / Ctrl / Cmd, then drag with left-click to pan.
/// - Hold the same modifier + scroll wheel to zoom in/out.
/// - Without the modifier, the wheel + drag pass through so the
///   surrounding page can scroll normally.
/// - Double-click to reset zoom.
///
/// Touch:
/// - Pinch with two fingers to zoom.
/// - Drag with two fingers to pan.
/// - Single-finger drag pans (outer scrolling loses to scale).
/// - Double-tap to reset.
class ChartZoomPan extends StatefulWidget {
  const ChartZoomPan({
    required this.child,
    this.enabled = true,
    this.minScale = 1.0,
    this.maxScale = 10.0,
    this.wheelZoomStep = 0.12,
    super.key,
  });

  final Widget child;

  /// When false, returns [child] unchanged (no transform layer).
  final bool enabled;

  final double minScale;
  final double maxScale;

  /// Per-tick scale change for mouse wheel events (1.0 + step).
  final double wheelZoomStep;

  @override
  State<ChartZoomPan> createState() => _ChartZoomPanState();
}

class _ChartZoomPanState extends State<ChartZoomPan>
    with SingleTickerProviderStateMixin {
  // Transform state.
  double _scale = 1.0;
  Offset _translation = Offset.zero;

  // Scale gesture state.
  double _baseScale = 1.0;
  Offset _baseTranslation = Offset.zero;
  Offset _gestureStartFocal = Offset.zero;

  // Pan gesture state (single-pointer drag).
  Offset _panStart = Offset.zero;
  Offset _panBaseTranslation = Offset.zero;

  // Manual double-click tracking. Flutter web's DoubleTapGestureRecognizer
  // is unreliable in nested gesture stacks; track ourselves via Listener.
  DateTime? _lastTapTime;
  Offset _lastTapPos = Offset.zero;

  // Reset animation.
  late AnimationController _anim;
  Animation<double>? _scaleAnim;
  Animation<Offset>? _translationAnim;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
    )..addListener(_onAnimTick);
  }

  void _onAnimTick() {
    if (!mounted) return;
    setState(() {
      if (_scaleAnim != null) _scale = _scaleAnim!.value;
      if (_translationAnim != null) _translation = _translationAnim!.value;
    });
  }

  @override
  void dispose() {
    _anim
      ..removeListener(_onAnimTick)
      ..dispose();
    super.dispose();
  }

  static bool _modifierHeld() {
    final p = HardwareKeyboard.instance.logicalKeysPressed;
    return p.contains(LogicalKeyboardKey.shift) ||
        p.contains(LogicalKeyboardKey.shiftLeft) ||
        p.contains(LogicalKeyboardKey.shiftRight) ||
        p.contains(LogicalKeyboardKey.control) ||
        p.contains(LogicalKeyboardKey.controlLeft) ||
        p.contains(LogicalKeyboardKey.controlRight) ||
        p.contains(LogicalKeyboardKey.meta) ||
        p.contains(LogicalKeyboardKey.metaLeft) ||
        p.contains(LogicalKeyboardKey.metaRight);
  }

  void _resetZoom() {
    if (_scale == 1.0 && _translation == Offset.zero) return;
    _scaleAnim = Tween<double>(
      begin: _scale,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _anim, curve: Curves.easeOutCubic));
    _translationAnim = Tween<Offset>(
      begin: _translation,
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _anim, curve: Curves.easeOutCubic));
    _anim
      ..stop()
      ..forward(from: 0);
  }

  // ── pan (single-pointer) ────────────────────────────────
  void _onPanStart(DragStartDetails details) {
    _panStart = details.localPosition;
    _panBaseTranslation = _translation;
  }

  void _onPanUpdate(DragUpdateDetails details) {
    final delta = details.localPosition - _panStart;
    setState(() {
      _translation = _panBaseTranslation + delta;
    });
  }

  // ── scale (multi-pointer pinch) ─────────────────────────
  void _onScaleStart(ScaleStartDetails details) {
    _baseScale = _scale;
    _baseTranslation = _translation;
    _gestureStartFocal = details.localFocalPoint;
  }

  void _onScaleUpdate(ScaleUpdateDetails details) {
    final newScale = (_baseScale * details.scale).clamp(
      widget.minScale,
      widget.maxScale,
    );
    final focalDelta = details.localFocalPoint - _gestureStartFocal;
    final scaleFactor = newScale / _baseScale;
    final newTranslation =
        _baseTranslation +
        focalDelta -
        (_gestureStartFocal -
            (_gestureStartFocal - _baseTranslation) * scaleFactor +
            _baseTranslation -
            _gestureStartFocal);
    setState(() {
      _scale = newScale;
      _translation = newTranslation;
    });
  }

  // ── wheel zoom ──────────────────────────────────────────
  void _onPointerSignal(PointerSignalEvent event) {
    if (event is! PointerScrollEvent) return;
    if (!_modifierHeld()) return;
    // Claim via pointerSignalResolver — prevents the browser default
    // (page scroll) on web.
    GestureBinding.instance.pointerSignalResolver.register(
      event,
      (_) => _applyWheelZoom(event),
    );
  }

  void _applyWheelZoom(PointerScrollEvent event) {
    final factor = event.scrollDelta.dy > 0
        ? 1.0 / (1 + widget.wheelZoomStep)
        : 1 + widget.wheelZoomStep;
    final newScale = (_scale * factor).clamp(widget.minScale, widget.maxScale);
    if (newScale == _scale) return;
    final realFactor = newScale / _scale;
    final localPos = event.localPosition;
    final newTranslation = localPos - (localPos - _translation) * realFactor;
    setState(() {
      _scale = newScale;
      _translation = newTranslation;
    });
  }

  // ── manual double-click ─────────────────────────────────
  void _onPointerDown(PointerDownEvent event) {
    final now = DateTime.now();
    if (_lastTapTime != null &&
        now.difference(_lastTapTime!) < const Duration(milliseconds: 320) &&
        (event.localPosition - _lastTapPos).distance < 24) {
      _resetZoom();
      _lastTapTime = null;
      return;
    }
    _lastTapTime = now;
    _lastTapPos = event.localPosition;
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled) return widget.child;

    final transform = Matrix4.identity()
      ..translateByDouble(_translation.dx, _translation.dy, 0, 1)
      ..scaleByDouble(_scale, _scale, _scale, 1);

    return Listener(
      onPointerSignal: _onPointerSignal,
      onPointerDown: _onPointerDown,
      child: RawGestureDetector(
        behavior: HitTestBehavior.opaque,
        gestures: <Type, GestureRecognizerFactory>{
          // Single-pointer drag — gated on modifier for mouse,
          // always allowed for touch/stylus.
          _ConditionalPanRecognizer:
              GestureRecognizerFactoryWithHandlers<_ConditionalPanRecognizer>(
                () => _ConditionalPanRecognizer(),
                (recognizer) {
                  recognizer
                    ..onStart = _onPanStart
                    ..onUpdate = _onPanUpdate;
                },
              ),
          // Multi-pointer pinch — touch only (mouse can't pinch).
          _TouchOnlyScaleRecognizer:
              GestureRecognizerFactoryWithHandlers<_TouchOnlyScaleRecognizer>(
                () => _TouchOnlyScaleRecognizer(),
                (recognizer) {
                  recognizer
                    ..onStart = _onScaleStart
                    ..onUpdate = _onScaleUpdate;
                },
              ),
        },
        child: ClipRect(
          child: Transform(
            transform: transform,
            child: widget.child,
          ),
        ),
      ),
    );
  }
}

/// Pan recognizer gated by input source:
/// - Mouse: only accepts pointer if a modifier (Shift/Ctrl/Cmd) is held.
/// - Touch / stylus: always accepts.
class _ConditionalPanRecognizer extends PanGestureRecognizer {
  _ConditionalPanRecognizer();

  @override
  void addAllowedPointer(PointerDownEvent event) {
    if (event.kind == PointerDeviceKind.mouse) {
      if (!_ChartZoomPanState._modifierHeld()) return;
    }
    super.addAllowedPointer(event);
  }
}

/// Scale recognizer that only accepts touch / stylus pointers.
/// Mouse pinch isn't physically possible — keeps pan + scale on
/// separate paths so single-finger touch drag still pans (via
/// scale recognizer's focal-point tracking).
class _TouchOnlyScaleRecognizer extends ScaleGestureRecognizer {
  _TouchOnlyScaleRecognizer();

  @override
  void addAllowedPointer(PointerDownEvent event) {
    if (event.kind == PointerDeviceKind.mouse) return;
    super.addAllowedPointer(event);
  }
}

/// Optionally wrap [child] with a [ChartZoomPan] when [style.enableZoom]
/// is true. Charts call this in their outer build returns to opt in.
Widget wrapZoomPan(Widget child, ChartStyle style) {
  if (!style.enableZoom) return child;
  return ChartZoomPan(child: child);
}
