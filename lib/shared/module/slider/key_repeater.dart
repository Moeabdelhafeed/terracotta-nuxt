import 'dart:async';

import 'package:flutter/foundation.dart';

/// Holds an arrow key down and keeps going.
///
/// Flutter only forwards a `KeyRepeatEvent` when the PLATFORM decides
/// to repeat, and it does not on every one — so a reader holding an
/// arrow on a dial got exactly one step and then nothing, which reads
/// as the control being stuck. Driving the repeat here means the same
/// behaviour everywhere.
///
/// It ACCELERATES: crossing a three-minute timeline one fiftieth at a
/// time is a long hold, and a constant rate makes the fine end useless
/// or the coarse end unreachable.
class KeyRepeater {
  KeyRepeater({
    this.delay = const Duration(milliseconds: 400),
    this.interval = const Duration(milliseconds: 55),
    this.accelerateAfter = 12,
    this.maxMultiplier = 6,
  });

  /// How long a key must be held before it starts repeating. Below
  /// this a deliberate single tap would fire twice.
  final Duration delay;

  /// Between repeats once it has started.
  final Duration interval;

  /// How many repeats at the base rate before it speeds up.
  final int accelerateAfter;

  /// The most it will ever multiply a step by.
  final int maxMultiplier;

  Timer? _timer;
  int _ticks = 0;

  /// Whether a key is currently being held.
  bool get isRunning => _timer != null;

  /// Fires [onTick] with a step MULTIPLIER, starting after [delay].
  ///
  /// The caller has already acted once on the key-down; this is only
  /// what follows.
  void start(void Function(int multiplier) onTick) {
    stop();
    _ticks = 0;
    _timer = Timer(delay, () {
      _timer = Timer.periodic(interval, (_) {
        _ticks++;
        onTick(_multiplier);
      });
    });
  }

  int get _multiplier {
    if (_ticks <= accelerateAfter) return 1;
    final extra = (_ticks - accelerateAfter) ~/ accelerateAfter + 1;
    return extra > maxMultiplier ? maxMultiplier : extra;
  }

  void stop() {
    _timer?.cancel();
    _timer = null;
    _ticks = 0;
  }

  @mustCallSuper
  void dispose() => stop();
}
