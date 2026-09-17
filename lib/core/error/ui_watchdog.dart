import 'dart:async';
import 'dart:isolate';

import 'package:flutter/foundation.dart';

import '../utils/loggers/logger.dart';

/// Reports when the UI isolate stops running its event loop.
///
/// ## Why this exists
///
/// Every error path in this app assumes an ERROR: `FlutterError.onError`,
/// `PlatformDispatcher.onError`, `GlobalErrorBoundary`, `ErrorStorm`,
/// `CrashReporter`. All of them need something to be thrown.
///
/// A hang throws nothing. A loop that re-enters itself through the
/// microtask queue — the classic one is a scroll animation whose
/// completion callback starts the next animation, which completes the
/// previous one — never returns to the event loop. No frames, no
/// timers, no exception, and therefore not one line in the log. The app
/// is simply dead, and the only evidence is that it stopped. That is
/// the worst failure mode this codebase has: total silence about the
/// most disruptive thing that can happen.
///
/// This closes it. A second isolate is told the UI isolate is alive
/// once a second; when the beats stop, it says so. It can, because it
/// is not the isolate that is stuck.
///
/// ## What it can and cannot tell you
///
/// It reports the stall, how long it has lasted, and the last
/// [breadcrumb] set before the lights went out — enough to name the
/// screen and usually the interaction. It cannot produce a Dart stack
/// for the blocked isolate: that needs the VM service, and attaching to
/// it from here would cost far more than this is worth. Pair it with
/// the debugger's "pause isolate" when you need the exact frame.
///
/// Debug and profile only. Release builds neither spawn the isolate nor
/// run the timer.
abstract final class UiWatchdog {
  /// How often the UI isolate reports in.
  static const beatEvery = Duration(seconds: 1);

  /// Silence past this is a stall worth reporting. Long enough that a
  /// slow frame, a big image decode or a debugger breakpoint does not
  /// trip it.
  static const stallAfter = Duration(seconds: 4);

  /// Where the app thinks it is. Sent with every beat, so the report
  /// after a freeze can name it. Set it from a route observer, a long
  /// operation, or anything else worth being the last word.
  static String breadcrumb = 'boot';

  static bool _started = false;
  static Timer? _beat;
  static SendPort? _port;
  static Isolate? _isolate;

  /// Spawns the watchdog and starts beating. Safe to call twice.
  static Future<void> start() async {
    if (_started || kReleaseMode) return;
    _started = true;

    final handshake = ReceivePort();
    try {
      _isolate = await Isolate.spawn(
        _watch,
        handshake.sendPort,
        debugName: 'ui-watchdog',
      );
    } on Object catch (e) {
      // A watchdog that cannot start must not be the reason the app
      // does not.
      _started = false;
      handshake.close();
      Logger.m.w('[UiWatchdog] not started: $e');
      return;
    }

    _port = await handshake.first as SendPort;
    handshake.close();

    _beat = Timer.periodic(beatEvery, (_) => _port?.send(breadcrumb));
    _port?.send(breadcrumb);
    Logger.m.i(
      '[UiWatchdog] watching — a stall over '
      '${stallAfter.inSeconds}s will be reported from a second isolate',
    );
  }

  /// Stops beating and kills the watchdog.
  static Future<void> stop() async {
    _beat?.cancel();
    _beat = null;
    _port = null;
    _isolate?.kill(priority: Isolate.immediate);
    _isolate = null;
    _started = false;
  }

  // ─── The other isolate ─────────────────────────────────────

  /// Runs in the spawned isolate. Nothing here may touch app state —
  /// statics are per-isolate, so `Logger`, `getIt` and every singleton
  /// this app has are absent and would be re-initialized rather than
  /// shared.
  static void _watch(SendPort reply) {
    final inbox = ReceivePort();
    reply.send(inbox.sendPort);

    final detector = StallDetector(stallAfter: stallAfter, at: DateTime.now());

    inbox.listen((message) {
      final recovery = detector.beat(
        DateTime.now(),
        message is String ? message : null,
      );
      if (recovery != null) _say(recovery);
    });

    Timer.periodic(const Duration(milliseconds: 500), (timer) {
      final now = DateTime.now();
      // The app is gone — a hot restart leaves the old watchdog with a
      // dead port. Exit rather than accumulate one per restart.
      if (detector.isAbandoned(now)) {
        timer.cancel();
        inbox.close();
        return;
      }
      final report = detector.check(now);
      if (report != null) _say(report);
    });
  }

  /// The watchdog isolate has no logger — every static in this app
  /// belongs to the isolate that created it. `print` is the only
  /// channel out, and this is the one place it is correct.
  static void _say(String message) {
    // ignore: avoid_print
    print('[UiWatchdog] $message');
  }
}

// ---------------------------------------------------------------------------
// StallDetector
// ---------------------------------------------------------------------------

/// The watchdog's decision, with the clock passed in.
///
/// Split out so it can be tested at all: everything around it is an
/// isolate and a wall clock, and a test for "does it notice a four
/// second freeze" would otherwise have to take four seconds and read
/// another isolate's stdout.
class StallDetector {
  StallDetector({required this.stallAfter, required DateTime at})
    : _lastBeat = at;

  /// Silence longer than this is a stall.
  final Duration stallAfter;

  /// A port that has been dead this long belongs to an app that is
  /// gone — a hot restart, usually.
  static const abandonedAfter = Duration(seconds: 90);

  DateTime _lastBeat;
  String _note = 'boot';
  bool _stalled = false;
  bool _everBeat = false;

  bool get isStalled => _stalled;

  /// Records a sign of life. Returns a report if this ENDS a stall.
  String? beat(DateTime at, String? note) {
    _lastBeat = at;
    _everBeat = true;
    if (note != null) _note = note;
    if (!_stalled) return null;
    _stalled = false;
    return 'recovered — the UI isolate is running again. Whatever ran '
        'between the last beat and now blocked the event loop.';
  }

  /// Returns a report when there is something to say, else null.
  String? check(DateTime now) {
    final silent = now.difference(_lastBeat);
    if (silent < stallAfter) return null;
    if (_stalled) return 'still stalled — ${silent.inSeconds}s, at: $_note';
    _stalled = true;
    return 'THE UI THREAD IS STUCK.\n'
        '  No beat for ${silent.inSeconds}s. Last known position: $_note\n'
        '  Nothing was thrown, so no error handler saw this: the event '
        'loop is not running.\n'
        '  Look for a callback that re-enters itself — an animation '
        'whose completion starts the next one, a `setState` from a '
        'layout callback, an unbounded `while`.';
  }

  /// Whether the watched app has stopped existing rather than stalled.
  bool isAbandoned(DateTime now) =>
      _everBeat && now.difference(_lastBeat) > abandonedAfter;
}
