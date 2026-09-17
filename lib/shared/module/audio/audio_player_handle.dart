import 'audio_models.dart';
import 'audio_shortcuts.dart';

/// Public handle exposed to [GlobalAudioPlayer.builder]. Lets callers
/// drive playback + scrubbing from a fully custom layout.
///
/// It IS an [AudioShortcutTarget] — the keys touch seven of these
/// methods, and naming that slice separately is what lets the key map
/// be tested without a player that will not build under
/// `flutter_test`.
abstract class AudioPlayerHandle implements AudioShortcutTarget {
  AudioStateSnapshot get state;
  Stream<AudioStateSnapshot> get stateStream;

  /// Approximate amplitude (0..1) emitted ~20Hz. Backed by the
  /// player's current position indexed into the decoded waveform when
  /// available, else the static fallback curve. Zero when paused. For
  /// real per-band FFT, wire a native plugin and pass its stream to
  /// `GlobalAudioVisualizer` directly instead.
  Stream<double> get amplitudeStream;

  /// Per-frame multi-band snapshot. Emits a `List<double>` of length
  /// equal to the player's `bandCount` only when
  /// [GlobalAudioPlayer.autoExtractBands] is enabled (otherwise the
  /// stream stays idle). Drives `GlobalAudioVisualizer.bandStream`
  /// for true-content visualizations.
  Stream<List<double>> get bandStream;

  /// 0..1 fraction. Mirrors the slider / waveform progress.
  double get progress;

  /// Effective amplitude samples — decoded when available, else
  /// caller-supplied / fallback. Useful when wiring a custom waveform.
  List<double> get samples;

  Future<void> play();
  Future<void> pause();
  @override
  Future<void> toggle();
  Future<void> seekFraction(double f);
  @override
  Future<void> skip(int seconds);
  @override
  Future<void> cycleSpeed();
  @override
  Future<void> toggleLoop();
  Future<void> setSpeed(double s);

  void scrubStart();
  void scrubUpdate(double f);
  Future<void> scrubEnd(double f);

  /// Which item of the queue is playing, and how many there are.
  ///
  /// A player with no queue reports `0` of `1` — a single clip is a
  /// queue of one, so nothing downstream needs to ask which it is.
  int get trackIndex;
  int get trackCount;

  /// Moves to the next item, if there is one.
  @override
  Future<void> next();

  /// Moves to the previous item — or restarts THIS one, when playback
  /// is more than [AudioDefaults.previousRestartsAfter] in. See
  /// [AudioQueue.previousRestarts].
  @override
  Future<void> previous();

  /// When playback stops on its own, if at all.
  AudioSleep get sleep;

  /// Arms, re-arms or cancels that. Re-arming restarts the clock.
  void setSleep(AudioSleep value);

  /// Why the last load failed, or null. Shown beside the retry so the
  /// reader is told what went wrong rather than just that something
  /// did.
  String? get errorMessage;

  /// Loads the source again after a failure.
  ///
  /// `errored` used to be terminal: it was set in two places and
  /// cleared in none, so a clip that failed once showed an error glyph
  /// for the life of the widget and every control refused. A failed
  /// load is usually a network that came back.
  Future<void> retry();
}
