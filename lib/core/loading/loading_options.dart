import 'package:flutter/material.dart';

/// App-level configuration for [LoadingOverlay]. Pass once at mount
/// time. All fields have safe defaults — you only override what you
/// need.
///
/// Per-show overrides live on [LoadingShowOptions] (see
/// `loading_show_options.dart`).
@immutable
class LoadingOptions {
  const LoadingOptions({
    this.appearAfter = const Duration(milliseconds: 200),
    this.minVisible = const Duration(milliseconds: 400),
    this.autoTimeout = const Duration(seconds: 30),
    this.contentBuilder,
    this.barrierDismissible = false,
    this.onTimeout,
  });

  /// Wait this long before the overlay actually appears. Skips
  /// rendering for fast ops — no flash.
  final Duration appearAfter;

  /// Once visible, stay at least this long. Avoids flicker for ops
  /// that finish slightly after [appearAfter].
  final Duration minVisible;

  /// Hard cap. If a token is still alive after this, log a warning
  /// and force-dispose. Catches forgotten `dispose()` calls.
  final Duration autoTimeout;

  /// Total override for the overlay's centered content. Receives the
  /// active `label`, optional `cancel` callback, and a builder for
  /// the default spinner so you can compose. Use when the default
  /// scrim layout doesn't fit (e.g. video splash, animated illustration,
  /// progress with a percent).
  final Widget Function(
    BuildContext context,
    String? label,
    VoidCallback? cancel,
    WidgetBuilder defaultSpinner,
  )?
  contentBuilder;

  /// If true, tapping outside the spinner dismisses the topmost token.
  /// Off by default — most apps want hard blocking.
  final bool barrierDismissible;

  /// Called when a token outlives [autoTimeout] and is force-disposed.
  ///
  /// The sweep already logs a warning, and a warning in a debug
  /// console is not a report — a leaked token in the wild is a
  /// spinner nobody can dismiss, and this is the hook that gets it to
  /// Crashlytics. It is handed the token's own label and tag, which
  /// is what identifies the caller that forgot `dispose()`.
  final void Function(String? label, String? tag)? onTimeout;

  LoadingOptions copyWith({
    Duration? appearAfter,
    Duration? minVisible,
    Duration? autoTimeout,
    Widget Function(
      BuildContext context,
      String? label,
      VoidCallback? cancel,
      WidgetBuilder defaultSpinner,
    )?
    contentBuilder,
    bool? barrierDismissible,
    void Function(String? label, String? tag)? onTimeout,
  }) {
    return LoadingOptions(
      appearAfter: appearAfter ?? this.appearAfter,
      minVisible: minVisible ?? this.minVisible,
      autoTimeout: autoTimeout ?? this.autoTimeout,
      contentBuilder: contentBuilder ?? this.contentBuilder,
      barrierDismissible: barrierDismissible ?? this.barrierDismissible,
      onTimeout: onTimeout ?? this.onTimeout,
    );
  }
}
