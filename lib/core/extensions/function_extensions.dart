import 'dart:async';

import 'package:flutter/foundation.dart';

/// Extension helpers that wrap a callback with `debounce` / `throttle`
/// behavior and return a new callback you can pass anywhere the
/// original type fits.
///
/// ## When to use these vs the [Debouncer] / [Throttler] classes
///
/// - **Extensions** — convenient for ad-hoc, single-use wrapping where
///   you don't have a stateful object to hang the timer on:
///   ```dart
///   GlobalButton(
///     onPressed: _submit.debounced(AppDurations.debounceShort),
///   )
///   ```
/// - **Classes** — preferred inside `State` / controllers because you
///   can dispose them on teardown. Extensions leak their internal
///   `Timer` if the wrapped callback itself outlives the widget that
///   created it. For anything that rebuilds, use a `Debouncer` /
///   `Throttler` field on the state.
///
/// ## Foot-gun warning
/// Each call to `.debounced()` / `.throttled()` allocates a fresh
/// timer closure — do **not** call them inside `build()`:
///
/// ```dart
///  ❌ wrong — new debouncer every build, defeats debouncing
/// onChanged: (v) => search.debounced(Duration(seconds: 1))()
///
///  ✅ right — hoist out of build
/// late final _search = search.debounced(Duration(seconds: 1));
/// onChanged: (_) => _search();
/// ```

// ─── VoidCallback ─────────────────────────────────────────────────────

extension VoidCallbackRateLimit on VoidCallback {
  /// Returns a new callback that runs `this` after [duration] of
  /// quiet. Repeated calls within the window cancel the previous
  /// pending call.
  VoidCallback debounced(Duration duration) {
    Timer? timer;
    return () {
      timer?.cancel();
      timer = Timer(duration, this);
    };
  }

  /// Returns a new callback that runs `this` at most once per
  /// [duration] (leading edge — fires immediately on the first call,
  /// drops subsequent calls inside the window).
  VoidCallback throttled(Duration duration) {
    DateTime? lastRun;
    return () {
      final now = DateTime.now();
      if (lastRun == null || now.difference(lastRun!) >= duration) {
        lastRun = now;
        this();
      }
    };
  }
}

// ─── ValueChanged<T> ──────────────────────────────────────────────────

extension ValueChangedRateLimit<T> on ValueChanged<T> {
  /// Debounced variant of [VoidCallbackRateLimit.debounced]; the
  /// argument from the latest call is the one that fires.
  ValueChanged<T> debounced(Duration duration) {
    Timer? timer;
    return (value) {
      timer?.cancel();
      timer = Timer(duration, () => this(value));
    };
  }

  /// Leading-edge throttled variant. The argument from the *first*
  /// call in each window is the one that fires.
  ValueChanged<T> throttled(Duration duration) {
    DateTime? lastRun;
    return (value) {
      final now = DateTime.now();
      if (lastRun == null || now.difference(lastRun!) >= duration) {
        lastRun = now;
        this(value);
      }
    };
  }
}

// ─── Single-arg Function<T> returning a value ─────────────────────────

extension FunctionT1RateLimit<T, R> on R Function(T) {
  /// Debounce a typed unary function. Trailing-edge: the last call's
  /// argument wins. Return value is discarded by necessity (we can't
  /// return the future's value synchronously).
  void Function(T) debouncedVoid(Duration duration) {
    Timer? timer;
    return (value) {
      timer?.cancel();
      timer = Timer(duration, () => this(value));
    };
  }
}
