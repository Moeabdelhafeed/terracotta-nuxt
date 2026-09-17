import 'dart:async';

import 'package:flutter/scheduler.dart';

/// Per-frame timing sample held in the ring buffer. Sums build + raster
/// duration into [total] for graphing convenience.
class FrameSample {
  FrameSample(FrameTiming timing)
    : buildMs = timing.buildDuration.inMicroseconds / 1000,
      rasterMs = timing.rasterDuration.inMicroseconds / 1000,
      totalMs = timing.totalSpan.inMicroseconds / 1000;

  final double buildMs;
  final double rasterMs;
  final double totalMs;
}

/// Lazy ring buffer over [SchedulerBinding.addTimingsCallback]. Caps
/// at [_kCap] samples — enough for a sparkline + percentile stats.
/// First subscriber starts the callback; all unsubscribers stop it.
class FrameTimings {
  FrameTimings._();

  // ~3s of history at 60fps (1.5s at 120) — enough to catch a jank
  // burst and still cheap to paint.
  static const int _kCap = 180;
  static final List<FrameSample> _samples = [];
  static final StreamController<void> _changes =
      StreamController<void>.broadcast(onListen: _attach, onCancel: _detach);
  static int _listenerCount = 0;

  /// Newest-first snapshot.
  static List<FrameSample> get samples => List.unmodifiable(_samples.reversed);

  /// Fires after every batch of frame timings is appended.
  static Stream<void> get changes => _changes.stream;

  /// Drop the buffer (the timings callback keeps feeding new frames).
  static void clear() {
    _samples.clear();
    if (!_changes.isClosed) _changes.add(null);
  }

  static void _attach() {
    _listenerCount++;
    if (_listenerCount == 1) {
      SchedulerBinding.instance.addTimingsCallback(_onTimings);
    }
  }

  static void _detach() {
    _listenerCount = (_listenerCount - 1).clamp(0, 1 << 30);
    if (_listenerCount == 0) {
      SchedulerBinding.instance.removeTimingsCallback(_onTimings);
    }
  }

  static void _onTimings(List<FrameTiming> timings) {
    if (timings.isEmpty) return;
    for (final t in timings) {
      _samples.add(FrameSample(t));
    }
    while (_samples.length > _kCap) {
      _samples.removeAt(0);
    }
    if (!_changes.isClosed) _changes.add(null);
  }
}
