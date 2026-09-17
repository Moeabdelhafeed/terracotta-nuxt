import 'dart:async';

import 'package:flutter/widgets.dart';

/// App lifecycle states — simpler names than Flutter's raw [AppLifecycleState].
enum AppLifecycle {
  /// App is in the foreground and visible.
  resumed,

  /// App is partially obscured (e.g. system dialog, split-screen).
  inactive,

  /// App is in the background.
  paused,

  /// App is being terminated (Android only).
  detached,

  /// App is hidden (e.g. minimized on desktop).
  hidden,
}

/// Observes app lifecycle changes (foreground/background/paused).
///
/// ```dart
/// // Start observing (call once at app init):
/// AppLifecycleUtils.init();
///
/// // Listen:
/// final sub = AppLifecycleUtils.onChange.listen((state) {
///   if (state == AppLifecycle.resumed) refreshData();
///   if (state == AppLifecycle.paused) savePendingChanges();
/// });
///
/// // Stop:
/// AppLifecycleUtils.dispose();
/// ```
class AppLifecycleUtils {
  AppLifecycleUtils._();

  static _LifecycleObserver? _observer;
  static final StreamController<AppLifecycle> _controller =
      StreamController<AppLifecycle>.broadcast();

  static AppLifecycle _current = AppLifecycle.resumed;

  /// Last known lifecycle state (defaults to [AppLifecycle.resumed]).
  ///
  /// Read-only. It was a public mutable static, so any code anywhere
  /// could assign a state the app was not in, and the stream would
  /// not have said so.
  static AppLifecycle get current => _current;

  /// Stream of lifecycle changes.
  static Stream<AppLifecycle> get onChange => _controller.stream;

  /// Start observing. Safe to call multiple times.
  static void init() {
    if (_observer != null) return;
    _observer = _LifecycleObserver((state) {
      _current = state;
      if (!_controller.isClosed) _controller.add(state);
    });
    WidgetsBinding.instance.addObserver(_observer!);
  }

  /// Stop observing.
  ///
  /// The stream stays OPEN and [init] can start it again — the doc
  /// used to promise it was closed, which would have made this a
  /// one-way door for every listener in the app. A broadcast
  /// controller that is closed cannot be reopened, and there is
  /// exactly one of these for the process.
  static void dispose() {
    if (_observer == null) return;
    WidgetsBinding.instance.removeObserver(_observer!);
    _observer = null;
  }

  static bool get isInForeground => current == AppLifecycle.resumed;
  static bool get isInBackground =>
      current == AppLifecycle.paused || current == AppLifecycle.hidden;
}

// ---------------------------------------------------------------------------
// Internal observer
// ---------------------------------------------------------------------------

class _LifecycleObserver extends WidgetsBindingObserver {
  _LifecycleObserver(this.onState);
  final void Function(AppLifecycle) onState;

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    onState(switch (state) {
      AppLifecycleState.resumed => AppLifecycle.resumed,
      AppLifecycleState.inactive => AppLifecycle.inactive,
      AppLifecycleState.paused => AppLifecycle.paused,
      AppLifecycleState.detached => AppLifecycle.detached,
      AppLifecycleState.hidden => AppLifecycle.hidden,
    });
  }
}
