import 'package:flutter/foundation.dart';

/// Drives a [GlobalRefreshable] from outside the widget tree.
///
/// A pull is the only way a reader can start a refresh, and it is not
/// the only reason one should happen: after a sign-in, from a toast's
/// "Retry", when the app comes back to the foreground, when
/// connectivity returns. None of those has a finger attached.
///
/// ```dart
/// final refresher = GlobalRefreshableController();
/// ...
/// GlobalRefreshable(controller: refresher, onRefresh: load, child: list);
/// ...
/// await refresher.refresh();
/// ```
///
/// A `ChangeNotifier`, so a caller can also just watch [isRefreshing]
/// to disable a button while the work runs.
class GlobalRefreshableController extends ChangeNotifier {
  Object? _owner;
  Future<void> Function()? _refresh;
  bool Function()? _isRefreshing;
  DateTime? Function()? _lastRefreshedAt;

  /// Whether the work is running right now.
  bool get isRefreshing => _isRefreshing?.call() ?? false;

  /// Whether a widget is listening. False before the first build and
  /// after the widget is gone.
  bool get isAttached => _owner != null;

  /// When the last refresh COMPLETED, or null if none has.
  DateTime? get lastRefreshedAt => _lastRefreshedAt?.call();

  /// Runs the refresh, showing the indicator exactly as a pull would.
  ///
  /// Completes when the work does — including the minimum show time,
  /// so `await`ing it and then popping the screen does not cut the
  /// indicator off mid-spin. A no-op when nothing is attached.
  Future<void> refresh() async => _refresh?.call();

  /// Wired by the widget's `initState` / `didUpdateWidget`.
  void attach({
    required Object owner,
    required Future<void> Function() onRefresh,
    required bool Function() isRefreshing,
    required DateTime? Function() lastRefreshedAt,
  }) {
    _owner = owner;
    _refresh = onRefresh;
    _isRefreshing = isRefreshing;
    _lastRefreshedAt = lastRefreshedAt;
  }

  /// Clears the wiring — but only when [owner] is still the current
  /// owner. A replaced State's deferred dispose must not tear down its
  /// successor's attachment, which is the same trap
  /// `GlobalDropdownController` documents.
  void detach({required Object owner}) {
    if (!identical(_owner, owner)) return;
    _owner = null;
    _refresh = null;
    _isRefreshing = null;
    _lastRefreshedAt = null;
  }

  /// Called by the widget whenever the state it exposes changes.
  void notify() => notifyListeners();
}

/// What a caller's own indicator is told about the pull in progress.
@immutable
class RefreshPull {
  const RefreshPull({
    required this.extent,
    required this.progress,
    required this.armed,
    required this.isRefreshing,
  });

  /// How far the pull has travelled, in points.
  final double extent;

  /// [extent] against the trigger distance, clamped to 0..1. What a
  /// scrubbing animation should be driven from.
  final double progress;

  /// Whether letting go NOW would refresh. Worth marking: it is the
  /// only thing the reader cannot work out for themselves.
  final bool armed;

  /// Whether the work is running.
  final bool isRefreshing;
}
