import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/a11y/semantics_extensions.dart';

/// Maps a key event to a stepper delta, or null when the key isn't a stepper
/// key. ↑ / ↓ nudge by [step]; PageUp / PageDown jump by 10×. Fires on key
/// DOWN and key REPEAT (hold-to-step).
num? stepperKeyDelta(KeyEvent event, num step) {
  if (event is! KeyDownEvent && event is! KeyRepeatEvent) return null;
  return switch (event.logicalKey) {
    LogicalKeyboardKey.arrowUp => step,
    LogicalKeyboardKey.arrowDown => -step,
    LogicalKeyboardKey.pageUp => step * 10,
    LogicalKeyboardKey.pageDown => -step * 10,
    _ => null,
  };
}

/// Shared keyboard / mouse-wheel / haptic / a11y wiring for the stepper
/// fields ([QuantityField], [MeasurementField]). The field supplies the
/// domain hooks (step size, bounds check, the raw apply, the announcement
/// text); this mixin routes every INTERACTIVE step (tap, key, wheel, repeat)
/// through one path so the tactile + spoken feedback is consistent.
///
/// - **Keyboard**: attaches `onKeyEvent` to [stepperFocusNode] so ↑/↓/PgUp/
///   PgDn step the value *before* the text editor consumes them (the focused
///   node's handler runs ahead of the default text-editing shortcuts).
/// - **Wheel**: [wrapWheel] claims a `PointerScrollEvent` via the pointer-
///   signal resolver — but only while the field is FOCUSED, so casual scroll
///   over the field doesn't hijack the page or nudge the value.
/// - **Haptics**: a light tick per step, a firmer bump when it hits a bound.
/// - **A11y**: announces the new value (skipped on hold-repeat to avoid
///   flooding the screen reader).
mixin StepperInteractionMixin<T extends StatefulWidget> on State<T> {
  FocusNode? _internalFocusNode;
  bool _stepperFocused = false;

  // ── Field-supplied hooks ──────────────────────────────────────────
  /// The caller's focus node, or null to let the mixin own one.
  FocusNode? get providedFocusNode;
  num get stepperStep;
  bool get stepperEnabled;
  bool get stepperHaptics;

  /// Can the value move in [delta]'s direction (not already at the bound)?
  bool stepperCanStep(num delta);

  /// Clamp + write + emit for [delta]. No haptic / announce — the mixin adds
  /// those around it.
  void stepperApply(num delta);

  /// The value to speak after a step, or null to stay silent.
  String? stepperAnnounceText();

  // ── Focus node (shared with the text field) ───────────────────────
  FocusNode get stepperFocusNode =>
      providedFocusNode ?? (_internalFocusNode ??= FocusNode());

  void initStepperInteractions() {
    stepperFocusNode
      ..onKeyEvent = _onKey
      ..addListener(_onFocusChange);
  }

  void disposeStepperInteractions() {
    stepperFocusNode.removeListener(_onFocusChange);
    // Detach our handler from a caller-owned node (our own node is disposed).
    if (providedFocusNode != null) providedFocusNode!.onKeyEvent = null;
    _internalFocusNode?.dispose();
  }

  void _onFocusChange() {
    final focused = stepperFocusNode.hasFocus;
    if (focused != _stepperFocused && mounted) {
      setState(() => _stepperFocused = focused);
    }
  }

  KeyEventResult _onKey(FocusNode node, KeyEvent event) {
    if (!mounted || !stepperEnabled) return KeyEventResult.ignored;
    final delta = stepperKeyDelta(event, stepperStep);
    if (delta == null) return KeyEventResult.ignored;
    stepInteractive(delta);
    return KeyEventResult.handled;
  }

  /// The single interactive-step path (tap / key / wheel). [announce] is
  /// false for hold-repeat ticks so the screen reader isn't flooded.
  void stepInteractive(num delta, {bool announce = true}) {
    if (!stepperCanStep(delta)) {
      if (stepperHaptics) HapticFeedback.mediumImpact(); // hit the wall
      return;
    }
    stepperApply(delta);
    if (stepperHaptics) HapticFeedback.selectionClick();
    if (announce && mounted) {
      final text = stepperAnnounceText();
      if (text != null) announceForAccessibility(context, text);
    }
  }

  /// Wraps [child] so a mouse wheel steps the value — but only while the
  /// field is focused, and claiming the signal so the page doesn't scroll.
  Widget wrapWheel(Widget child) {
    return Listener(
      onPointerSignal: (event) {
        if (!stepperEnabled || !_stepperFocused) return;
        if (event is PointerScrollEvent) {
          GestureBinding.instance.pointerSignalResolver.register(event, (e) {
            final scroll = e as PointerScrollEvent;
            stepInteractive(
              scroll.scrollDelta.dy < 0 ? stepperStep : -stepperStep,
            );
          });
        }
      },
      child: child,
    );
  }
}
