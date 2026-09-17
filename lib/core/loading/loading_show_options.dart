import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import 'loading_surface.dart';

/// Per-show overrides for a single token. Anything left null falls
/// back to the app-level [LoadingOptions].
///
/// Most callers only set [label]. Use the heavier overrides only when
/// a specific operation needs to look different (e.g. a long upload
/// shows a custom progress UI, a search uses a top-bar, etc.).
@immutable
class LoadingShowOptions {
  const LoadingShowOptions({
    this.label,
    this.style,
    this.spinner,
    this.cancellable,
    this.blockInput,
    this.appearAfter,
    this.minVisible,
    this.autoTimeout,
    this.tag,
    this.progress,
  });

  /// User-facing description. Shown beneath the spinner.
  final String? label;

  /// Override the visual style for this token only.
  final LoadingSurface? style;

  /// Replace the spinner widget for this show only.
  final Widget? spinner;

  /// When set, the overlay renders a Cancel button that calls this.
  /// The token still needs to be disposed by the caller after the
  /// underlying op honors the cancellation — that's how the overlay
  /// learns to dismiss.
  final VoidCallback? cancellable;

  /// Override [LoadingOptions] block-input behaviour. False allows
  /// input through (e.g. for top-bar variants).
  final bool? blockInput;

  final Duration? appearAfter;
  final Duration? minVisible;
  final Duration? autoTimeout;

  /// Free-form tag used for de-dupe / lookup. Two `show()`s with the
  /// same tag share a token (ref-count instead of stacking).
  final String? tag;

  /// Determinate progress driver. When set, the top-bar variant
  /// fills 0→1 according to this value; the scrim variant swaps the
  /// circular indicator for a determinate one. Listenable so callers
  /// can drive it from a `ValueNotifier<double>` / `AnimationController`
  /// without rebuilding the overlay.
  final ValueListenable<double>? progress;
}
