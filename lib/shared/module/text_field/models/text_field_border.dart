import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';

/// Which visual state a border stroke is being resolved for.
enum TextFieldBorderState { enabled, focused, error, focusedError, disabled }

// ---------------------------------------------------------------------------
// TextFieldBorderSide — one state's stroke
// ---------------------------------------------------------------------------

/// A single border stroke (one visual state). Every field nullable so a
/// per-state side inherits unset fields from [TextFieldBorderStyle.base].
///
/// [gradient] overrides [color] when set — gradient strokes are painted via
/// a `CustomPaint` wrapper (Material's `OutlineInputBorder` only accepts a
/// solid color).
@immutable
class TextFieldBorderSide {
  const TextFieldBorderSide({this.color, this.gradient, this.width});

  final Color? color;
  final Gradient? gradient;
  final double? width;

  /// Stack resolution: [other] > this per field.
  TextFieldBorderSide mergedWith(TextFieldBorderSide? other) {
    if (other == null) return this;
    return TextFieldBorderSide(
      color: other.color ?? color,
      gradient: other.gradient ?? gradient,
      width: other.width ?? width,
    );
  }

  TextFieldBorderSide copyWith({
    Color? color,
    Gradient? gradient,
    double? width,
  }) {
    return TextFieldBorderSide(
      color: color ?? this.color,
      gradient: gradient ?? this.gradient,
      width: width ?? this.width,
    );
  }

  static TextFieldBorderSide? lerp(
    TextFieldBorderSide? a,
    TextFieldBorderSide? b,
    double t,
  ) {
    if (a == null && b == null) return null;
    if (a == null) return b;
    if (b == null) return a;
    return TextFieldBorderSide(
      color: Color.lerp(a.color, b.color, t),
      gradient: t < 0.5 ? a.gradient : b.gradient,
      width: lerpDouble(a.width, b.width, t),
    );
  }
}

// ---------------------------------------------------------------------------
// TextFieldBorderStyle — the per-state border bag
// ---------------------------------------------------------------------------

/// Structured border config: a [base] default applied to every state plus
/// per-state overrides. Resolution for a state = `base.mergedWith(state)`,
/// so callers set [base] once (color + width) and only override what
/// differs per state.
///
/// ```dart
/// TextFieldBorderStyle(
///   base: TextFieldBorderSide(color: outline, width: 1),
///   focused: TextFieldBorderSide(
///     gradient: LinearGradient(colors: [blue, purple]), width: 2,
///   ),
/// )
/// ```
@immutable
class TextFieldBorderStyle {
  const TextFieldBorderStyle({
    this.base,
    this.enabled,
    this.focused,
    this.error,
    this.focusedError,
    this.disabled,
  });

  /// General default for every state. Per-state sides override it field-by-field.
  final TextFieldBorderSide? base;
  final TextFieldBorderSide? enabled;
  final TextFieldBorderSide? focused;
  final TextFieldBorderSide? error;
  final TextFieldBorderSide? focusedError;
  final TextFieldBorderSide? disabled;

  /// Side for [state] = `base` overlaid by the state-specific side.
  TextFieldBorderSide sideFor(TextFieldBorderState state) {
    final specific = switch (state) {
      TextFieldBorderState.enabled => enabled,
      TextFieldBorderState.focused => focused,
      TextFieldBorderState.error => error,
      TextFieldBorderState.focusedError => focusedError ?? error,
      TextFieldBorderState.disabled => disabled,
    };
    return (base ?? const TextFieldBorderSide()).mergedWith(specific);
  }

  /// True when [state]'s resolved side draws a gradient stroke.
  bool hasGradient(TextFieldBorderState state) =>
      sideFor(state).gradient != null;

  /// True when any state draws a gradient stroke.
  bool get hasAnyGradient => TextFieldBorderState.values.any(hasGradient);

  /// Stack resolution: [other] > this. Per-state sides field-merge.
  TextFieldBorderStyle mergedWith(TextFieldBorderStyle? other) {
    if (other == null) return this;
    TextFieldBorderSide? merge(TextFieldBorderSide? a, TextFieldBorderSide? b) {
      if (a == null) return b;
      if (b == null) return a;
      return a.mergedWith(b);
    }

    return TextFieldBorderStyle(
      base: merge(base, other.base),
      enabled: merge(enabled, other.enabled),
      focused: merge(focused, other.focused),
      error: merge(error, other.error),
      focusedError: merge(focusedError, other.focusedError),
      disabled: merge(disabled, other.disabled),
    );
  }

  TextFieldBorderStyle copyWith({
    TextFieldBorderSide? base,
    TextFieldBorderSide? enabled,
    TextFieldBorderSide? focused,
    TextFieldBorderSide? error,
    TextFieldBorderSide? focusedError,
    TextFieldBorderSide? disabled,
  }) {
    return TextFieldBorderStyle(
      base: base ?? this.base,
      enabled: enabled ?? this.enabled,
      focused: focused ?? this.focused,
      error: error ?? this.error,
      focusedError: focusedError ?? this.focusedError,
      disabled: disabled ?? this.disabled,
    );
  }

  static TextFieldBorderStyle? lerp(
    TextFieldBorderStyle? a,
    TextFieldBorderStyle? b,
    double t,
  ) {
    if (a == null && b == null) return null;
    if (a == null) return b;
    if (b == null) return a;
    return TextFieldBorderStyle(
      base: TextFieldBorderSide.lerp(a.base, b.base, t),
      enabled: TextFieldBorderSide.lerp(a.enabled, b.enabled, t),
      focused: TextFieldBorderSide.lerp(a.focused, b.focused, t),
      error: TextFieldBorderSide.lerp(a.error, b.error, t),
      focusedError: TextFieldBorderSide.lerp(a.focusedError, b.focusedError, t),
      disabled: TextFieldBorderSide.lerp(a.disabled, b.disabled, t),
    );
  }
}

// ---------------------------------------------------------------------------
// ResolvedBorderSide — post-materialize, non-null color + width
// ---------------------------------------------------------------------------

/// A border side after merge + context fallback. [color] + [width] are
/// non-null; [gradient] (opt-in) and [paints] (resting-transparent rule)
/// stay as-is. Build code consumes this directly.
@immutable
class ResolvedBorderSide {
  const ResolvedBorderSide({
    required this.color,
    required this.width,
    required this.paints,
    this.gradient,
  });

  final Color color;
  final double width;
  final Gradient? gradient;

  /// Whether this side paints at all. The resting (enabled) side stays
  /// invisible unless a color or non-zero width was explicitly supplied —
  /// preserves the borderless default look.
  final bool paints;

  bool get hasGradient => gradient != null;
}
