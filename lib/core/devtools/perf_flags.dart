import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';

/// Live-mutable flags driving the framework's debug-overlay paints.
///
/// `MaterialApp` consumes the first four via [Listenable.merge] in
/// `MyApp` so flipping one rebuilds the app with the new rendering
/// options. The rendering-global flags (slow animations, repaint
/// rainbow, layout bounds) apply through their setters here — the
/// LATTER TWO need a reassemble after flipping (the caller schedules
/// it) because the framework only re-reads them on paint rebuilds.
/// Process-lifetime only — no disk persistence.
class PerfFlags {
  PerfFlags._();

  /// Renders the GPU/UI thread frame-time graphs over every frame.
  static final ValueNotifier<bool> showPerformanceOverlay = ValueNotifier<bool>(
    false,
  );

  /// Tints the raster cache so cached pictures + offscreen layers are
  /// visible at a glance. Useful when chasing fill-rate / re-raster
  /// regressions.
  static final ValueNotifier<bool> checkerboardRasterCacheImages =
      ValueNotifier<bool>(false);

  static final ValueNotifier<bool> checkerboardOffscreenLayers =
      ValueNotifier<bool>(false);

  /// Shows the semantics tree visualizer so a11y bugs are easier to
  /// spot without a screen reader.
  static final ValueNotifier<bool> showSemanticsDebugger = ValueNotifier<bool>(
    false,
  );

  /// ×5 [timeDilation] — inspect janky transitions frame by frame.
  static final ValueNotifier<bool> slowAnimations = ValueNotifier<bool>(false);

  /// [debugRepaintRainbowEnabled] — repaint regions cycle hue, so
  /// over-repainting (missing RepaintBoundary) jumps out.
  static final ValueNotifier<bool> repaintRainbow = ValueNotifier<bool>(false);

  /// [debugPaintSizeEnabled] — boxes, padding and baselines painted
  /// over everything.
  static final ValueNotifier<bool> layoutBounds = ValueNotifier<bool>(false);

  static void setSlowAnimations(bool value) {
    slowAnimations.value = value;
    timeDilation = value ? 5.0 : 1.0;
  }

  /// Caller must reassemble after this (deferred to post-frame).
  static void setRepaintRainbow(bool value) {
    repaintRainbow.value = value;
    debugRepaintRainbowEnabled = value;
  }

  /// Caller must reassemble after this (deferred to post-frame).
  static void setLayoutBounds(bool value) {
    layoutBounds.value = value;
    debugPaintSizeEnabled = value;
  }

  /// True when ANY perf debugging aid is active — feeds the overlay
  /// home's active-override strip.
  static bool get anyActive =>
      showPerformanceOverlay.value ||
      checkerboardRasterCacheImages.value ||
      checkerboardOffscreenLayers.value ||
      showSemanticsDebugger.value ||
      slowAnimations.value ||
      repaintRainbow.value ||
      layoutBounds.value;

  /// Convenience aggregate — passes any flag flip through to the
  /// MaterialApp `ValueListenableBuilder` + status listeners.
  static Listenable get listenable => Listenable.merge([
    showPerformanceOverlay,
    checkerboardRasterCacheImages,
    checkerboardOffscreenLayers,
    showSemanticsDebugger,
    slowAnimations,
    repaintRainbow,
    layoutBounds,
  ]);
}
