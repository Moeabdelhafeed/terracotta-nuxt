import 'package:flutter/foundation.dart';

/// Keeps the screen awake while something is PLAYING.
///
/// A film is the one kind of content someone watches without touching
/// the device, so the idle timer is measuring the wrong thing: the
/// screen dims halfway through and then locks.
///
/// Counted rather than a flag, because a page holds several players and
/// the last one to pause must not switch the screen off under one that
/// is still going. Releasing what was never acquired is ignored — a
/// widget disposed mid-playback would otherwise take the count
/// negative and leave the wakelock stuck on for the rest of the
/// session.
class VideoWakelock {
  const VideoWakelock._();

  static int _holders = 0;

  /// How the screen is actually held on.
  ///
  /// Wired in `bootstrap` to `SystemUiUtils.toggleWakelock`. It is a
  /// seam rather than a direct call because `lib/shared/module` must
  /// not reach the device layer — and because it leaves the module
  /// inert until an app opts in, which is what keeps a widget test
  /// from touching a platform channel.
  static Future<void> Function(bool enable)? setEnabled;

  /// How many players are currently keeping the screen on.
  @visibleForTesting
  static int get holders => _holders;

  /// Called when a player starts.
  static void acquire() {
    _holders++;
    if (_holders == 1) setEnabled?.call(true);
  }

  /// Called when one pauses, ends, or goes away.
  static void release() {
    if (_holders == 0) return;
    _holders--;
    if (_holders == 0) setEnabled?.call(false);
  }

  /// Drops every hold. For tests, and for a hard reset.
  @visibleForTesting
  static void reset() {
    _holders = 0;
    setEnabled?.call(false);
  }
}
