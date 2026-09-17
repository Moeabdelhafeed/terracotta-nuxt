import 'dart:async';

import 'package:flutter/foundation.dart';

/// Cap the frequency at which an action can run — "at most once per
/// [duration]". Calls in between are dropped (leading edge) or
/// coalesced into a trailing invocation.
///
/// Canonical use cases:
///  - scroll handlers: react to position changes every 100 ms at most
///  - drag/pan events: update state no faster than 30 fps
///  - realtime telemetry: batch writes to at most one per 500 ms
///
/// ```dart
/// final _scroll = Throttler(duration: AppDurations.micro);
///
/// onScroll: () => _scroll.run(() => _updateParallax()),
///
/// @override
/// void dispose() {
///   _scroll.dispose();
///   super.dispose();
/// }
/// ```
///
/// ## Leading vs trailing
///
/// - [run] — **leading edge**. Fires the first call immediately, then
///   ignores anything for [duration]. Best when the *first* event of
///   a burst matters most (scroll start, tap ripple).
/// - [runTrailing] — **trailing edge**. Waits for a quiet moment
///   inside the window, then fires the latest call. Best when the
///   *final* value of a burst matters most (drag end snap, last
///   keystroke).
///
/// Compare with [Debouncer], which waits for silence before firing
/// the latest call — throttle is for "cap the rate", debounce is for
/// "wait until they're done."
class Throttler {
  Throttler({required this.duration});

  /// Minimum gap between successive actions.
  final Duration duration;

  DateTime? _lastRun;
  Timer? _trailingTimer;
  VoidCallback? _pendingTrailing;

  /// **Leading-edge** throttle. Runs [action] immediately on the first
  /// call; subsequent calls within [duration] of the last run are
  /// dropped.
  void run(VoidCallback action) {
    final now = DateTime.now();
    if (_lastRun == null || now.difference(_lastRun!) >= duration) {
      _lastRun = now;
      action();
    }
  }

  /// **Trailing-edge** throttle. Captures the latest [action]; fires
  /// it once [duration] has elapsed since the last call. Each new
  /// call refreshes the action — so you always get the most recent
  /// value.
  void runTrailing(VoidCallback action) {
    _pendingTrailing = action;
    _trailingTimer ??= Timer(duration, () {
      _trailingTimer = null;
      final pending = _pendingTrailing;
      _pendingTrailing = null;
      if (pending != null) {
        _lastRun = DateTime.now();
        pending();
      }
    });
  }

  /// Whether a trailing action is queued.
  bool get hasPending => _pendingTrailing != null;

  /// Reset all state — clears the leading-edge timestamp and any
  /// trailing queue. Useful at phase boundaries (navigate away, new
  /// session, …).
  void cancel() {
    _trailingTimer?.cancel();
    _trailingTimer = null;
    _pendingTrailing = null;
    _lastRun = null;
  }

  void dispose() => cancel();
}
