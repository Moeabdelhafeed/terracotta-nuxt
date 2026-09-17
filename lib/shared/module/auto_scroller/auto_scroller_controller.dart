import 'package:flutter/foundation.dart';

/// Holds and releases a [GlobalAutoScroller] from outside the tree.
///
/// The drive already stops for a finger and for being scrolled off
/// screen. This is for the reasons only the screen knows: a dialog is
/// up, a video in the rail is playing, the reader has opened a menu
/// over it.
///
/// A `ChangeNotifier`, so a caller can watch [isRunning] to drive its
/// own play / pause control.
class GlobalAutoScrollerController extends ChangeNotifier {
  Object? _owner;
  void Function({required bool paused})? _setPaused;
  bool Function()? _isRunning;
  bool Function()? _isPaused;
  VoidCallback? _restart;

  /// Whether the drive is advancing right now. False while anything is
  /// holding it, and false when nothing is attached.
  bool get isRunning => _isRunning?.call() ?? false;

  /// Whether THIS controller is the thing holding it. A drive stopped
  /// by a finger or by being off screen is not "paused" in this sense.
  bool get isPaused => _isPaused?.call() ?? false;

  bool get isAttached => _owner != null;

  void pause() => _setPaused?.call(paused: true);

  void resume() => _setPaused?.call(paused: false);

  /// Starts again from the beginning of the scrollable, which is what
  /// `AutoScrollLoopMode.stop` leaves no other way back from.
  void restart() => _restart?.call();

  void attach({
    required Object owner,
    required void Function({required bool paused}) setPaused,
    required bool Function() isRunning,
    required bool Function() isPaused,
    required VoidCallback restart,
  }) {
    _owner = owner;
    _setPaused = setPaused;
    _isRunning = isRunning;
    _isPaused = isPaused;
    _restart = restart;
  }

  /// Clears the wiring — but only when [owner] is still the current
  /// owner. A replaced State's deferred dispose must not tear down its
  /// successor's attachment.
  void detach({required Object owner}) {
    if (!identical(_owner, owner)) return;
    _owner = null;
    _setPaused = null;
    _isRunning = null;
    _isPaused = null;
    _restart = null;
  }

  void notify() => notifyListeners();
}
