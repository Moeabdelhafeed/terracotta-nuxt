import 'dart:async';

import 'package:flutter/foundation.dart';

/// Delay running an action until a quiet window has passed. Every call
/// inside the window resets the timer — only the most recent call
/// survives to fire.
///
/// Canonical use cases:
///  - search-as-you-type: fire the API call after the user stops
///    typing for 300 ms, not on every keystroke
///  - window resize handlers: re-layout once the drag settles
///  - form auto-save: save 1 s after the last edit
///
/// ```dart
/// final _search = Debouncer(duration: AppDurations.debounceShort);
///
/// onChanged: (value) => _search.run(() => api.search(value)),
///
/// @override
/// void dispose() {
///   _search.dispose();   // cancels any pending action
///   super.dispose();
/// }
/// ```
///
/// Compare with [Throttler], which caps *frequency* rather than
/// waiting for silence.
class Debouncer {
  Debouncer({required this.duration});

  /// Quiet period required before [run]'s action fires.
  final Duration duration;

  Timer? _timer;

  /// Schedule [action] to run after [duration] of inactivity. Any
  /// further [run] call inside the window cancels the previous pending
  /// action.
  void run(VoidCallback action) {
    _timer?.cancel();
    _timer = Timer(duration, action);
  }

  /// Whether an action is queued and waiting to fire.
  bool get isPending => _timer?.isActive ?? false;

  /// Cancel any queued action without running it.
  void cancel() {
    _timer?.cancel();
    _timer = null;
  }

  /// Fire the pending action immediately instead of waiting out the
  /// timer. No-op if nothing is queued.
  ///
  /// Note: the action is passed to [run], so its closure is what we
  /// invoke here. If you need `flush` semantics you must retain a
  /// reference to the action yourself — this implementation is
  /// intentionally minimal. Prefer `cancel() + action()` at the call
  /// site if you need that control.
  void dispose() => cancel();
}
