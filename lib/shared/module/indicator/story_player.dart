import 'dart:async';

import 'package:flutter/material.dart';

/// Runs a story: which segment is playing, how far through it is, and
/// when to move on.
///
/// The bar itself only ever DREW a position — a caller had to run its
/// own timer, and every one of them wrote the same loop slightly
/// differently: a fixed tick, one duration for every segment, and no
/// way to hold it while something else happened.
///
/// ```dart
/// late final _story = StoryPlayerController(
///   vsync: this,
///   count: 4,
///   // A photo is quick; a video is as long as the video.
///   durations: const [
///     Duration(seconds: 3),
///     Duration(seconds: 8),
///     Duration(seconds: 3),
///     Duration(seconds: 5),
///   ],
///   onCompleted: () => Navigator.pop(context),
/// );
///
/// GlobalStoryIndicator.player(controller: _story)
/// ```
///
/// It ticks on the VSYNC rather than on a `Timer`, so the fill moves a
/// frame at a time instead of jumping in whatever step the timer's
/// period happened to be.
class StoryPlayerController extends ChangeNotifier {
  StoryPlayerController({
    required TickerProvider vsync,
    required this.count,
    this.duration = const Duration(seconds: 5),
    List<Duration>? durations,
    int initialIndex = 0,
    bool autoPlay = true,
    this.loop = false,
    this.onIndexChanged,
    this.onCompleted,
  }) : assert(count > 0, 'count must be > 0'),
       assert(
         durations == null || durations.length == count,
         'durations must have one entry per segment',
       ),
       _durations = durations,
       _index = initialIndex.clamp(0, count - 1) {
    _ticker = AnimationController(vsync: vsync, duration: durationOf(_index))
      ..addListener(notifyListeners)
      ..addStatusListener(_onStatus);
    if (autoPlay) play();
  }

  /// How many segments.
  final int count;

  /// What a segment lasts when [durations] does not say otherwise.
  final Duration duration;

  /// Per-segment durations — a photo is quick, a video is as long as
  /// the video.
  final List<Duration>? _durations;

  /// Whether finishing the last segment starts the first again.
  final bool loop;

  final ValueChanged<int>? onIndexChanged;

  /// Fires when the LAST segment finishes and [loop] is false.
  final VoidCallback? onCompleted;

  late final AnimationController _ticker;
  int _index;

  /// The pending auto-resume from [holdFor], held so it can be
  /// cancelled — a second hold, a manual `play`, or disposal.
  Timer? _hold;

  /// Whether it is MEANT to be running.
  ///
  /// Not the same as the ticker animating: a segment that has just
  /// finished is not animating, and asking the ticker was how the
  /// auto-advance stalled — it set up the next segment, checked
  /// "were we playing?", got false from a controller that had just
  /// completed, and left the story sitting on a full bar.
  bool _playing = false;

  int get index => _index;

  /// How far through the CURRENT segment, in `[0, 1]`.
  double get progress => _ticker.value;

  bool get isPlaying => _playing;

  /// Whether something is holding it — paused by [holdFor] rather than
  /// by [pause], so it will start again on its own.
  bool get isHeld => _hold?.isActive ?? false;

  Duration durationOf(int index) =>
      _durations?[index.clamp(0, count - 1)] ?? duration;

  void play() {
    _hold?.cancel();
    _hold = null;
    _playing = true;
    if (_ticker.isAnimating) return;
    _ticker.duration = durationOf(_index);
    // FROM WHERE IT STOPPED, not from the start: a pause that rewound
    // the segment would punish the reader for looking away.
    _ticker.forward();
    notifyListeners();
  }

  void pause() {
    _hold?.cancel();
    _hold = null;
    if (!_playing) return;
    _playing = false;
    _ticker.stop();
    notifyListeners();
  }

  /// Pauses, then starts again on its own after [duration].
  ///
  /// For an interruption that is not the reader taking over — a toast,
  /// a sheet, a tap that shows something briefly. A second call
  /// restarts the wait rather than stacking another one.
  void holdFor(Duration duration) {
    pause();
    _hold = Timer(duration, () {
      _hold = null;
      play();
    });
    // Held, not stopped: `isPlaying` stays false, but a `goTo` while
    // held still resumes, because the reader never asked it to stop.
    notifyListeners();
  }

  /// The next segment, or the end.
  void next() {
    if (_index >= count - 1) {
      if (loop) {
        goTo(0);
        return;
      }
      // Finished: the last segment stays full rather than snapping
      // back to empty.
      _playing = false;
      _ticker
        ..stop()
        ..value = 1;
      notifyListeners();
      onCompleted?.call();
      return;
    }
    goTo(_index + 1);
  }

  /// The previous segment.
  ///
  /// Part-way through one, it RESTARTS the current segment first —
  /// which is what every story reader expects from a back tap, and
  /// only goes back a segment when it is already near the start.
  void previous() {
    if (_ticker.value > 0.02 && _index >= 0) {
      goTo(_index);
      return;
    }
    goTo(_index == 0 ? 0 : _index - 1);
  }

  void goTo(int index, {bool resume = true}) {
    final target = index.clamp(0, count - 1);
    final wasPlaying = _playing || isHeld;
    _hold?.cancel();
    _hold = null;

    _index = target;
    _ticker
      ..stop()
      ..duration = durationOf(target)
      ..value = 0;
    onIndexChanged?.call(target);

    if (resume && wasPlaying) {
      _playing = true;
      _ticker.forward();
    }
    notifyListeners();
  }

  /// Back to the first segment, playing.
  void restart() {
    goTo(0);
    play();
  }

  void _onStatus(AnimationStatus status) {
    if (status != AnimationStatus.completed) return;
    // NOT here: a controller mutated from inside its own status
    // dispatch swallows the change, so the next segment was set up and
    // then never started. A microtask lands after the dispatch and
    // before the next frame.
    scheduleMicrotask(() {
      if (_disposed) return;
      next();
    });
  }

  bool _disposed = false;

  @override
  void dispose() {
    _disposed = true;
    _hold?.cancel();
    _ticker
      ..removeListener(notifyListeners)
      ..removeStatusListener(_onStatus)
      ..dispose();
    super.dispose();
  }
}
