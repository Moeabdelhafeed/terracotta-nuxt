import 'package:flutter/foundation.dart';

/// Which tabs the reader has been through, so BACK has somewhere to go.
///
/// Every tab is a top-level `GoRoute` and `TerracottaNavBar` switches
/// them with `context.go`, which REPLACES the stack rather than growing
/// it. That is deliberate — pushing tabs would build a pile the reader
/// has to back out of one at a time — but it left the system back
/// button with nothing to pop: three taps into the app, on «ورشاتنا»,
/// back closed it.
///
/// So the trail is kept here instead. It is not the navigator's stack
/// and must not be confused with it: a PUSHED page (a product, a
/// booking) pops normally and never reaches this.
///
/// In memory, like every other launch-scoped thing in the app. A trail
/// restored from disk would send the reader back through a session
/// they do not remember having.
abstract final class TabHistory {
  static final _trail = <String>[];

  /// How far back the trail may go.
  ///
  /// Deep enough that a real wander is remembered, shallow enough that
  /// back is never a long way out. Past this the oldest is dropped:
  /// the alternative is a reader tapping back eleven times.
  static const _limit = 8;

  /// Whether back has somewhere to go.
  static bool get isEmpty => _trail.isEmpty;

  /// Records the tab being LEFT.
  ///
  /// Called with the path the reader is on, at the moment they choose
  /// another — so the trail is where they have been, not where they
  /// are.
  ///
  /// A tab already in the trail is MOVED rather than repeated: home →
  /// shop → home → shop would otherwise leave four entries and four
  /// taps of back, when what the reader did was change their mind
  /// twice.
  static void leaving(String path) {
    _trail.remove(path);
    _trail.add(path);
    if (_trail.length > _limit) _trail.removeAt(0);
  }

  /// The tab to go back to, or null when there is none — in which case
  /// back belongs to the platform and should close the app.
  static String? back() => _trail.isEmpty ? null : _trail.removeLast();

  /// The trail, for a test that needs to read it.
  @visibleForTesting
  static List<String> get trail => List.unmodifiable(_trail);

  /// A fresh launch.
  @visibleForTesting
  static void reset() => _trail.clear();
}

/// TWO BACKS TO LEAVE.
///
/// Android's back at the bottom of the stack closes the app, and on a
/// gesture-navigation phone that is a swipe from the edge of a screen
/// somebody is reading — easy to do by accident, and the app is gone
/// with whatever was half-filled in it.
///
/// So the first one ARMS instead: it is swallowed, the reader is told,
/// and a second within [window] leaves. Anything else — a tap, another
/// tab, time passing — disarms it.
///
/// The guard also turns the PREDICTIVE animation off for that gesture,
/// which is the point of `canPop: false` at the call site: a back that
/// is going to be swallowed must not first peel the app away to show
/// the launcher behind it, or the reader is told "swipe again" over a
/// screen that already looks like it left.
abstract final class ExitGuard {
  /// How long the first back stays good for. Long enough to read the
  /// line, short enough that a swipe a minute later is not "again".
  static const window = Duration(seconds: 2);

  static DateTime? _armedAt;

  /// Whether a second back right now should leave.
  static bool get isArmed {
    final at = _armedAt;
    if (at == null) return false;
    if (DateTime.now().difference(at) > window) {
      _armedAt = null;
      return false;
    }
    return true;
  }

  /// The first back. Answers false, having taken the gesture.
  static void arm() => _armedAt = DateTime.now();

  /// Anything that means the reader is staying.
  static void disarm() => _armedAt = null;

  @visibleForTesting
  static void debugReset() => _armedAt = null;
}
