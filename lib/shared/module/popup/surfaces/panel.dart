import 'package:flutter/material.dart';

import '../../progress/global_progress.dart';
import '../models/popup_models.dart';
import 'surface_base.dart';

/// Generic popover surface — wraps caller's child in the styled surface.
/// Use for forms, charts, color pickers, anything that isn't a menu list.
class GlobalPopupPanel extends StatelessWidget {
  const GlobalPopupPanel({
    super.key,
    required this.layout,
    required this.child,
    this.style,
    this.maxWidth,
    this.arrow,
  });

  final GlobalPopupLayout layout;
  final Widget child;
  final GlobalPopupSurfaceStyle? style;
  final double? maxWidth;
  final GlobalPopupArrow? arrow;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      child: GlobalPopupSurface(
        layout: layout,
        style: style,
        maxWidth: maxWidth,
        arrow: arrow,
        child: child,
      ),
    );
  }
}

/// Async-backed panel — shows [placeholder] until [future] resolves,
/// then swaps in the resolved widget. Errors fall back to [errorBuilder].
///
/// The surface smoothly animates its size as the contents swap from
/// placeholder → resolved (or → error), avoiding a jarring jump when
/// the resolved widget has different dimensions.
class GlobalPopupAsyncPanel extends StatelessWidget {
  const GlobalPopupAsyncPanel({
    super.key,
    required this.layout,
    required this.future,
    this.placeholder,
    this.errorBuilder,
    this.style,
    this.maxWidth,
    this.arrow,
    this.swapDuration = const Duration(milliseconds: 220),
    this.swapCurve = Curves.easeOutCubic,
  });

  final GlobalPopupLayout layout;
  final Future<Widget> future;
  final Widget? placeholder;
  final Widget Function(BuildContext, Object error)? errorBuilder;
  final GlobalPopupSurfaceStyle? style;
  final double? maxWidth;
  final GlobalPopupArrow? arrow;

  /// Duration of the resize / cross-fade between loading and resolved.
  final Duration swapDuration;
  final Curve swapCurve;

  @override
  Widget build(BuildContext context) {
    return GlobalPopupSurface(
      layout: layout,
      style: style,
      maxWidth: maxWidth,
      arrow: arrow,
      child: FutureBuilder<Widget>(
        future: future,
        builder: (ctx, snap) {
          final loading = snap.connectionState != ConnectionState.done;
          final placeholderWidget =
              placeholder ??
              Padding(
                padding: const EdgeInsets.all(20),
                child: Center(
                  child: SizedBox(
                    width: 22,
                    height: 22,
                    child: GlobalProgress.loading(
                      type: ProgressType.circular,
                      style: const ProgressStyle(thickness: 2),
                    ),
                  ),
                ),
              );
          final resolved = snap.hasError
              ? (errorBuilder?.call(ctx, snap.error!) ??
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text('Error: ${snap.error}'),
                    ))
              : (snap.data ?? const SizedBox.shrink());

          // AnimatedCrossFade interpolates size + opacity in lockstep,
          // so the surface resizes WHILE the new content fades in —
          // no "content appears then size catches up" lag.
          return AnimatedCrossFade(
            firstChild: placeholderWidget,
            secondChild: resolved,
            crossFadeState: loading
                ? CrossFadeState.showFirst
                : CrossFadeState.showSecond,
            duration: swapDuration,
            sizeCurve: swapCurve,
            firstCurve: swapCurve,
            secondCurve: swapCurve,
            alignment: Alignment.topCenter,
          );
        },
      ),
    );
  }
}
