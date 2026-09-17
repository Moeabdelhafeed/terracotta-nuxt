import 'dart:async';
import 'dart:io';

// ignore_for_file: experimental_member_use
// `StreamAudioSource` / `StreamAudioResponse` are tagged experimental
// in just_audio but are the only public way to feed raw bytes into a
// player. Pinned to v0.9.x in pubspec — re-evaluate on major bump.

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:just_audio/just_audio.dart';
import 'package:video_player/video_player.dart';

import '../../../core/audio/audio_band_extractor.dart';
import '../../../core/audio/audio_session_config.dart';
import '../../../core/audio/waveform_extractor.dart';
import '../../../core/utils/loggers/logger.dart';
import '../../../data/services/media/audio_player_manager.dart';
import 'audio_background.dart';
import 'audio_chrome.dart';
import 'audio_models.dart';
import 'audio_player_handle.dart';

export '../../../core/audio/audio_band_extractor.dart';
export '../../../core/audio/audio_visualizer_native.dart';
export '../../../core/audio/waveform_extractor.dart';
export '../../../data/services/media/audio_player_manager.dart';
export 'audio_background.dart';
export 'audio_chrome.dart';
export 'audio_controls.dart';
export 'audio_models.dart';
export 'audio_player_handle.dart';
export 'audio_shortcuts.dart';
export 'audio_visualizer.dart';
export 'audio_waveform.dart' show AudioWaveform;
export 'theme/audio_theme.dart';
export 'theme/visualizer_theme.dart';
export 'visualizer_models.dart';

/// Callback signature for [GlobalAudioPlayer.builder] — receives a
/// live handle the caller can use to drive playback / read state from
/// a fully custom layout.
typedef AudioPlayerBuilder =
    Widget Function(
      BuildContext context,
      AudioPlayerHandle handle,
    );

/// Visual variant for [GlobalAudioPlayer]. See variant constructors
/// for the exact UI each one renders.
enum AudioPlayerVariant {
  /// Single-row: play / pause, slider, duration. ~56dp tall. Good for
  /// list rows and bottom panels.
  compact,

  /// Waveform-first: play button + waveform-scrubber + duration row +
  /// controls (skip, speed, loop). Use for dedicated audio screens.
  full,

  /// Chat-bubble style: small play button + inline waveform + duration.
  /// Designed to live inside a message bubble.
  message,

  /// Caller-driven layout — provide [GlobalAudioPlayer.builder] and
  /// compose play / pause / waveform / visualizer / scrub UI from the
  /// supplied [AudioPlayerHandle].
  custom,
}

/// Reusable audio-player widget built on `just_audio` with:
///   * single-instance enforcement (configurable cap) via
///     [AudioPlayerManager],
///   * background-playback session config (Tier A) wired on first
///     mount,
///   * static waveform rendering (caller passes amplitude samples) +
///     hook for live-decoded waveforms via the `audio_waveforms`
///     plugin (see [GlobalAudioPlayer.withDecodedWaveform]),
///   * lifecycle-aware: pauses on app background unless told
///     otherwise; disposes the underlying player on widget unmount.
class GlobalAudioPlayer extends StatefulWidget {
  const GlobalAudioPlayer({
    super.key,
    this.source,
    this.variant = AudioPlayerVariant.full,
    this.style = const AudioStyle(),
    this.samples,
    this.autoPlay = false,
    this.initialPosition,
    this.nowPlaying,
    this.playlist,
    this.loopQueue = false,
    this.autoAdvance = true,
    this.onTrackChanged,
    this.onPositionChanged,
    this.onStateChanged,
    this.onCompleted,
    this.builder,
    this.autoDecodeWaveform = false,
    this.autoExtractBands = false,
    this.bandCount = 32,
    this.bandSnapshotsCount = 512,
    this.bandExtractor,
  }) : assert(
         variant != AudioPlayerVariant.custom || builder != null,
         'AudioPlayerVariant.custom requires a builder',
       ),
       assert(
         source != null || playlist != null,
         'GlobalAudioPlayer needs a source or a playlist',
       );

  /// Where to load the audio from, for a player with one thing to
  /// play. A [playlist] replaces it.
  final AudioSourceSpec? source;

  /// The first thing this player will open — the single [source], or
  /// the first item of the [playlist]. What the state dispatcher needs
  /// and the one place that knows both spellings.
  AudioSourceSpec get firstSource =>
      playlist?.isNotEmpty ?? false ? playlist!.first.source : source!;

  /// Visual layout — see [AudioPlayerVariant].
  final AudioPlayerVariant variant;

  /// Visual + behavioural overrides.
  final AudioStyle style;

  /// Where to start, for a player resuming something already begun.
  ///
  /// Applied ONCE, as the source is set — `just_audio` takes it there,
  /// so the clip opens AT the position rather than opening at zero and
  /// being told to move. The module deliberately does not persist it:
  /// `lib/shared/module` has no storage, so an app pairs this with
  /// [onPositionChanged] and keeps the value where it keeps everything
  /// else.
  final Duration? initialPosition;

  /// What this is, for whatever shows it outside the app.
  ///
  /// Handed to [AudioBackground] when an app has wired one — without
  /// it the player claims no lock screen, because a lock screen with
  /// nothing to say on it is worse than none.
  final AudioNowPlaying? nowPlaying;

  /// More than one thing to play, in order.
  ///
  /// A player without one is a queue of ONE internally — [source],
  /// [nowPlaying] and [samples] become its single item — so nothing
  /// downstream has two code paths to keep true. When this is given it
  /// WINS over those three, since each queue item carries its own.
  final List<AudioQueueItem>? playlist;

  /// Whether the end of the queue goes back to its start.
  ///
  /// A playlist someone put on loops; a run of voice notes does not.
  final bool loopQueue;

  /// Whether finishing one item starts the next.
  ///
  /// On, unlike the video module's — audio is the case where it is
  /// expected, and a queue that stopped between every track would need
  /// a press to do the one thing a queue is for. An armed sleep timer
  /// still BEATS it: someone who set one did not ask for another
  /// track.
  final bool autoAdvance;

  /// Fires with the new index whenever the queue moves.
  final ValueChanged<int>? onTrackChanged;

  /// Reports where playback has got to, at most once every
  /// [AudioDefaults.positionReportInterval].
  ///
  /// Throttled because the ticker runs every frame and the other end
  /// of a position report is usually a write to disk.
  final ValueChanged<Duration>? onPositionChanged;

  /// Pre-computed waveform amplitudes (0..1). Optional — when null,
  /// the player draws a flat fallback bar.
  final List<double>? samples;

  /// Start playing as soon as the widget mounts + source resolves.
  final bool autoPlay;

  /// Snapshot fires on every position / state change.
  final ValueChanged<AudioStateSnapshot>? onStateChanged;

  /// Fires once when playback hits the end (looping resets, so this
  /// only fires when loop is off).
  final VoidCallback? onCompleted;

  /// Required when [variant] is [AudioPlayerVariant.custom]. Receives
  /// a live handle to drive the player from any layout the caller
  /// chooses.
  final AudioPlayerBuilder? builder;

  /// When true and [samples] is null, the player decodes the source
  /// into amplitude data on init via [WaveformExtractor]. URLs are
  /// downloaded to a temp cache once; assets / files extract directly.
  final bool autoDecodeWaveform;

  /// When true, the player pre-computes a [BandSnapshots] timeline
  /// for the source via [bandExtractor] (default
  /// [SyntheticBandExtractor]) and emits the snapshot for the current
  /// playhead each frame on [AudioPlayerHandle.bandStream]. Cheap to
  /// consume per-frame — extraction happens once on load.
  final bool autoExtractBands;

  /// Bands per snapshot. Matches the visualizer's `barCount` for
  /// pixel-perfect mapping, or pick any number — the visualizer
  /// resamples as needed.
  final int bandCount;

  /// Number of snapshots across the track. 512 ≈ ~one snapshot every
  /// 250ms for a 2-min song. Bump higher for finer time resolution.
  final int bandSnapshotsCount;

  /// Override the default [SyntheticBandExtractor]. Swap in a real-FFT
  /// extractor once you wire a PCM decoder.
  final AudioBandExtractor? bandExtractor;

  // Dispatcher picks a state class per source kind — sole "logic"
  // is a read of widget config, no side effects.
  @override
  State<GlobalAudioPlayer> createState() =>
      // ignore: no_logic_in_create_state
      firstSource.isVideo
      ? _VideoBackedAudioPlayerState()
      : _AudioBackedAudioPlayerState();
}

class _AudioBackedAudioPlayerState extends State<GlobalAudioPlayer>
    with WidgetsBindingObserver, SingleTickerProviderStateMixin
    implements AudioPlayerHandle {
  late final AudioPlayer _player;
  StreamSubscription<PlayerState>? _stateSub;
  StreamSubscription<Duration>? _posSub;
  StreamSubscription<Duration?>? _durSub;
  StreamSubscription<ProcessingState>? _processingSub;

  final _stateController = StreamController<AudioStateSnapshot>.broadcast();
  final _amplitudeController = StreamController<double>.broadcast();
  final _bandController = StreamController<List<double>>.broadcast();
  BandSnapshots? _bandSnapshots;
  Ticker? _positionTicker;

  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;
  Duration _buffered = Duration.zero;

  /// Last position value reported by `_player.position` and the
  /// wall-clock instant we observed it. just_audio's getter doesn't
  /// interpolate uniformly across platforms (macOS/iOS often only
  /// emit ~1Hz), so we extrapolate locally between platform updates
  /// using these two fields.
  Duration _stampedPosition = Duration.zero;
  Stopwatch? _stampElapsed;

  /// Where the last seek was aimed, until the platform agrees it got
  /// there. See `AudioScrub.trustReport` — without this the ticker
  /// believes the stale position the platform reports for a few frames
  /// after a seek, and the clock visibly jumps back.
  Duration? _seekTarget;

  /// Where playback was when that seek was issued — a report still
  /// sitting here is the stale one.
  Duration _seekFrom = Duration.zero;
  final _sinceSeek = Stopwatch();

  /// Publishes the position extrapolated from [anchor].
  ///
  /// Both the ordinary path and the one that is ignoring a stale
  /// report end here, so a frame spent waiting for a seek to land
  /// still moves the clock rather than freezing it.
  void _tickFrom(Duration anchor) {
    Duration interp;
    if (_playing && !_errored) {
      final since = _stampElapsed!.elapsedMicroseconds;
      interp = anchor + Duration(microseconds: (since * _speed).round());
      if (_duration > Duration.zero && interp > _duration) interp = _duration;
    } else {
      interp = anchor;
    }
    if (interp == _position) return;
    setState(() => _position = interp);
    _reportPosition();
    _emit();
    _emitAmplitude();
    _emitBands();
  }

  /// Which scrub is the CURRENT one.
  ///
  /// `scrubEnd` awaits a seek, so two of them overlap: a tap fires
  /// `onTapDown` and the drag recogniser cancels around it, and the
  /// one that started FIRST can finish LAST. It then released its own
  /// stale target over the newer one — measured, 0.305 became 0.487
  /// became 0.305 again, which is the flash.
  int _scrubGeneration = 0;

  /// Tells the caller where playback has got to, at most once every
  /// `positionReportInterval` — the ticker runs every frame and the
  /// other end of this is usually a write to disk.
  void _reportPosition() {
    final report = widget.onPositionChanged;
    if (report == null) return;
    final shown = _shownPosition;
    final last = _lastReported;
    if (last != null &&
        (shown - last).abs() < AudioDefaults.positionReportInterval) {
      return;
    }
    _lastReported = shown;
    report(shown);
  }

  /// Claims the lock screen, once there is a duration to show on it.
  void _attachBackground() => _background.attach(
    nowPlaying: _current.nowPlaying,
    controls: AudioRemoteControls(
      play: play,
      pause: pause,
      seek: (at) async {
        _armSeek(at);
        await _player.seek(at);
      },
      skipForward: () => skip(AudioDefaults.skipSeconds),
      skipBackward: () => skip(-AudioDefaults.skipSeconds),
    ),
  );

  /// Aims a seek, and stops trusting the platform until it lands.
  void _armSeek(Duration target) {
    _seekFrom = _position;
    _seekTarget = target;
    _sinceSeek
      ..reset()
      ..start();
    _stampedPosition = target;
    _stampElapsed
      ?..reset()
      ..start();
  }

  bool _playing = false;
  bool _loading = true;
  bool _errored = false;
  String? _errorMessage;

  /// The last position handed to `onPositionChanged`.
  Duration? _lastReported;

  /// This player's hold on the lock screen. Inert until an app wires
  /// [AudioBackground].
  final _background = AudioBackgroundLink();

  /// The queue, which a player without one still has: a single clip
  /// is a queue of one, so no code below asks which it is.
  late final List<AudioQueueItem> _items;
  int _index = 0;

  AudioQueueItem get _current => _items[_index];

  /// When playback stops on its own.
  AudioSleep _sleep = AudioSleep.off;
  Timer? _sleepTimer;
  double _speed = 1.0;
  bool _looping = false;

  /// Decoded amplitudes from [WaveformExtractor]. Wins over
  /// [widget.samples] when set.
  List<double>? _decodedSamples;

  /// Scrub-preview state — while the user drags the slider / waveform
  /// we display this fraction instead of the live player position so
  /// the player's position stream can't fight the drag.
  double? _scrubFrac;

  static const _speeds = [0.5, 1.0, 1.25, 1.5, 2.0];

  List<double> get _effectiveSamples =>
      _decodedSamples ?? _current.samples ?? AudioDefaults.flatWaveform;

  @override
  void initState() {
    super.initState();
    _items = _queueFor(widget);
    WidgetsBinding.instance.addObserver(this);
    _player = AudioPlayer();
    AudioPlayerManager.instance.register(_player);
    unawaited(_init());
  }

  void _emitAmplitude() {
    if (_amplitudeController.isClosed) return;
    if (!_playing) {
      _amplitudeController.add(0);
      return;
    }
    final s = _effectiveSamples;
    if (s.isEmpty) {
      _amplitudeController.add(0);
      return;
    }
    final idx = (progress * (s.length - 1)).round().clamp(0, s.length - 1);
    _amplitudeController.add(s[idx]);
  }

  void _emitBands() {
    if (_bandController.isClosed) return;
    final snap = _bandSnapshots;
    if (snap == null) return;
    _bandController.add(snap.at(_position));
  }

  Future<void> _init() async {
    try {
      // Idempotent — first player to mount configures the session
      // for the whole app.
      await configureAudioSession();
      if (!mounted) return;
      await _setSource();
      if (!mounted) return;
      _wireStreams();
      _attachBackground();
      if (widget.autoDecodeWaveform && _current.samples == null) {
        unawaited(_decodeWaveform());
      }
      if (widget.autoExtractBands) {
        unawaited(_extractBands());
      }
      if (widget.autoPlay) {
        await _player.play();
      }
    } catch (e, st) {
      Logger.m.e(
        '[GlobalAudioPlayer:audio] init failed for '
        '${_current.source.kind.name}=${_current.source.value} :: $e',
        error: e,
        stackTrace: st,
      );
      if (!mounted) return;
      setState(() {
        _errored = true;
        _errorMessage = e.toString();
        _loading = false;
      });
    }
  }

  @override
  String? get errorMessage => _errorMessage;

  @override
  Future<void> retry() async {
    if (!_errored) return;
    setState(() {
      _errored = false;
      _errorMessage = null;
      _loading = true;
    });
    await _init();
  }

  Future<void> _decodeWaveform() async {
    final at = _index;
    final out = await WaveformExtractor.extract(_current.source, samples: 120);
    // The queue may have moved while this decoded. A shared cache
    // makes that FASTER, not impossible, and the bug it would cause is
    // the previous track's waveform drawn under this one.
    if (!mounted || out == null || at != _index) return;
    setState(() => _decodedSamples = out);
  }

  Future<void> _extractBands() async {
    final extractor = widget.bandExtractor ?? const SyntheticBandExtractor();
    final at = _index;
    final snap = await extractor.extract(
      _current.source,
      bandCount: widget.bandCount,
      timestampsCount: widget.bandSnapshotsCount,
    );
    if (!mounted || snap == null || at != _index) return;
    // BandSnapshots ships with a sentinel duration — overwrite with
    // the player's real duration so playhead lookup maps correctly.
    _bandSnapshots = BandSnapshots(
      bands: snap.bands,
      duration: _duration > Duration.zero ? _duration : snap.duration,
      bandCount: snap.bandCount,
    );
  }

  Future<void> _setSource({bool resume = true}) async {
    // `initialPosition` is handed to the SETTER, not seeked to
    // afterwards: just_audio opens the clip there, where a seek issued
    // after opening races the load and is dropped.
    // Only the item the player STARTS on resumes: the ones after it
    // are new listenings, and dropping every one at the same offset
    // would be nonsense.
    final at = resume ? widget.initialPosition : null;
    final source = _current.source;
    switch (source.kind) {
      case AudioSourceKind.url:
        await _player.setUrl(source.value, initialPosition: at);
      case AudioSourceKind.asset:
        await _player.setAsset(source.value, initialPosition: at);
      case AudioSourceKind.file:
        await _player.setFilePath(source.value, initialPosition: at);
      case AudioSourceKind.bytes:
        await _player.setAudioSource(
          _BytesSource(source.bytes!),
          initialPosition: at,
        );
      case AudioSourceKind.videoUrl:
      case AudioSourceKind.videoFile:
      case AudioSourceKind.videoAsset:
        // Should never land here — dispatcher in createState routes
        // video sources to _VideoBackedAudioPlayerState.
        throw StateError(
          'Video source kind ${source.kind} requires the video '
          'backend; this state is audio-only.',
        );
    }
  }

  void _wireStreams() {
    _stateSub = _player.playerStateStream.listen((s) {
      if (!mounted) return;
      // Re-anchor the interpolation stopwatch on every play/pause
      // transition so paused wall-time doesn't leak into the next
      // play burst.
      if (s.playing != _playing) {
        // Only when there is no seek in flight. A pause that lands
        // while a seek is settling would otherwise re-stamp from the
        // position the seek was leaving.
        final reported = _player.position;
        final trusted = AudioScrub.trustReport(
          reported: reported,
          seekTarget: _seekTarget,
          seekFrom: _seekFrom,
          sinceSeek: _sinceSeek.elapsed,
        );
        if (trusted) {
          _stampedPosition = reported;
          _stampElapsed?.reset();
        }
      }
      setState(() {
        _playing = s.playing;
        _loading =
            s.processingState == ProcessingState.loading ||
            s.processingState == ProcessingState.buffering;
      });
      _emit();
      if (s.processingState == ProcessingState.completed && !_looping) {
        _onTrackComplete();
      }
    });
    // 60Hz position ticker. just_audio's `position` getter is not
    // uniformly interpolated across platforms (macOS/iOS often only
    // report ~1Hz), so we cache the latest platform value + a
    // Stopwatch from that instant and extrapolate locally each frame.
    _stampElapsed = Stopwatch()..start();
    _positionTicker = createTicker((_) {
      if (!mounted) return;
      final reported = _player.position;
      final trusted = AudioScrub.trustReport(
        reported: reported,
        seekTarget: _seekTarget,
        seekFrom: _seekFrom,
        sinceSeek: _sinceSeek.elapsed,
      );
      if (!trusted) {
        // Still the position we seeked AWAY from. Keep extrapolating
        // from the target instead of jumping back to it.
        _tickFrom(_stampedPosition);
        return;
      }
      _seekTarget = null;
      if (reported != _stampedPosition) {
        _stampedPosition = reported;
        _stampElapsed!
          ..reset()
          ..start();
      }
      _tickFrom(_stampedPosition);
    })..start();
    _durSub = _player.durationStream.listen((d) {
      if (!mounted || d == null) return;
      setState(() => _duration = d);
    });
    _processingSub = _player.processingStateStream.listen((p) {
      if (!mounted) return;
      // Track buffered tail separately from position so the scrubber
      // can show a "loaded but not played yet" bar.
      _buffered = _player.bufferedPosition;
      if (p == ProcessingState.ready) {
        setState(() => _loading = false);
      }
    });
  }

  void _emit() {
    final snapshot = AudioStateSnapshot(
      // The SHOWN position, so a visualizer or a caller's own clock
      // cannot disagree with the waveform beside it.
      position: _shownPosition,
      duration: _duration,
      buffered: _buffered,
      playing: _playing,
      loading: _loading,
      errored: _errored,
      speed: _speed,
      looping: _looping,
    );
    widget.onStateChanged?.call(snapshot);
    _background.report(snapshot.position, playing: _playing);
    if (!_stateController.isClosed) _stateController.add(snapshot);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Background playback is enabled via UIBackgroundModes/Android
    // foreground service — no auto-pause here. The audio_session
    // handles interruptions (calls, other apps requesting focus).
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _sleepTimer?.cancel();
    _background.detach();
    _positionTicker?.dispose();
    _stateSub?.cancel();
    _posSub?.cancel();
    _durSub?.cancel();
    _processingSub?.cancel();
    _stateController.close();
    _amplitudeController.close();
    _bandController.close();
    AudioPlayerManager.instance.unregister(_player);
    _player.dispose();
    super.dispose();
  }

  // ─── AudioPlayerHandle implementation ────────────────────────

  @override
  AudioStateSnapshot get state => AudioStateSnapshot(
    // The SHOWN position — a caller reading the handle directly must
    // not see a value the waveform beside it is refusing to draw.
    position: _shownPosition,
    duration: _duration,
    buffered: _buffered,
    playing: _playing,
    loading: _loading,
    errored: _errored,
    speed: _speed,
    looping: _looping,
  );

  @override
  Stream<AudioStateSnapshot> get stateStream => _stateController.stream;

  @override
  Stream<double> get amplitudeStream => _amplitudeController.stream;

  @override
  Stream<List<double>> get bandStream => _bandController.stream;

  @override
  List<double> get samples => _effectiveSamples;

  @override
  Future<void> play() async {
    if (_errored) return;
    await _player.play();
  }

  @override
  Future<void> pause() async {
    if (_errored) return;
    await _player.pause();
  }

  @override
  Future<void> toggle() async {
    if (_errored) return;
    if (_playing) {
      await _player.pause();
    } else {
      await _player.play();
    }
  }

  @override
  Future<void> seekFraction(double f) async {
    if (_duration == Duration.zero) return;
    final landed = AudioScrub.positionFor(f, _duration);
    _armSeek(landed);
    await _player.seek(landed);
  }

  // ─── The queue ───────────────────────────────────────────────

  @override
  int get trackIndex => _index;

  @override
  int get trackCount => _items.length;

  @override
  Future<void> next() async {
    final i = AudioQueue.nextIndex(
      index: _index,
      count: _items.length,
      wrap: widget.loopQueue,
    );
    if (i == null) return;
    await _goTo(i);
  }

  @override
  Future<void> previous() async {
    // One button, two meanings — see `AudioQueue.previousRestarts`.
    // Far enough in, or nowhere to go, and it restarts THIS one.
    if (AudioQueue.previousRestarts(_shownPosition)) {
      await seekFraction(0);
      return;
    }
    final i = AudioQueue.previousIndex(
      index: _index,
      count: _items.length,
      wrap: widget.loopQueue,
    );
    if (i == null) {
      await seekFraction(0);
      return;
    }
    await _goTo(i);
  }

  // ─── The sleep timer ─────────────────────────────────────────

  @override
  AudioSleep get sleep => _sleep;

  @override
  void setSleep(AudioSleep value) {
    _sleepTimer?.cancel();
    _sleepTimer = null;
    if (mounted) setState(() => _sleep = value);
    final after = value.after;
    if (after != null) {
      _sleepTimer = Timer(after, () {
        if (!mounted) return;
        unawaited(pause());
        setState(() => _sleep = AudioSleep.off);
        _emit();
      });
    }
    _emit();
  }

  /// What the end of a track means.
  ///
  /// The order is the point: an armed sleep timer BEATS auto-advance,
  /// because whoever set one did not ask for another track.
  void _onTrackComplete() {
    widget.onCompleted?.call();
    if (_sleep.atEndOfTrack) {
      unawaited(pause());
      setSleep(AudioSleep.off);
      return;
    }
    if (!widget.autoAdvance) return;
    final i = AudioQueue.nextIndex(
      index: _index,
      count: _items.length,
      wrap: widget.loopQueue,
    );
    if (i != null) unawaited(_goTo(i));
  }

  /// Moves the queue, and rebuilds everything that belonged to the
  /// item being left — its waveform, its bands, its lock screen and
  /// its clock. Keeping any of them is how the previous track's
  /// waveform ends up under this one.
  Future<void> _goTo(int i) async {
    if (i < 0 || i >= _items.length || i == _index) return;
    final wasPlaying = _playing;
    _background.detach();
    _seekTarget = null;
    _lastReported = null;
    setState(() {
      _index = i;
      _position = Duration.zero;
      _stampedPosition = Duration.zero;
      _duration = Duration.zero;
      _buffered = Duration.zero;
      _decodedSamples = null;
      _bandSnapshots = null;
      _scrubFrac = null;
      _loading = true;
      _errored = false;
      _errorMessage = null;
    });
    widget.onTrackChanged?.call(i);
    try {
      await _setSource(resume: false);
    } catch (e, st) {
      Logger.m.e(
        '[GlobalAudioPlayer:audio] queue item $i failed :: $e',
        error: e,
        stackTrace: st,
      );
      if (!mounted) return;
      setState(() {
        _errored = true;
        _errorMessage = e.toString();
        _loading = false;
      });
      return;
    }
    if (!mounted) return;
    setState(() => _loading = false);
    _stampElapsed
      ?..reset()
      ..start();
    _attachBackground();
    if (widget.autoDecodeWaveform && _current.samples == null) {
      unawaited(_decodeWaveform());
    }
    if (widget.autoExtractBands) unawaited(_extractBands());
    if (wasPlaying) await _player.play();
    _emit();
  }

  @override
  Future<void> skip(int seconds) async {
    final next = _position + Duration(seconds: seconds);
    final clamped = next < Duration.zero
        ? Duration.zero
        : (next > _duration ? _duration : next);
    _armSeek(clamped);
    await _player.seek(clamped);
  }

  @override
  Future<void> cycleSpeed() async {
    final idx = _speeds.indexOf(_speed);
    final next = _speeds[(idx + 1) % _speeds.length];
    await setSpeed(next);
  }

  @override
  Future<void> setSpeed(double s) async {
    await _player.setSpeed(s);
    if (!mounted) return;
    setState(() => _speed = s);
    _emit();
  }

  @override
  Future<void> toggleLoop() async {
    final next = !_looping;
    await _player.setLoopMode(next ? LoopMode.one : LoopMode.off);
    if (!mounted) return;
    setState(() => _looping = next);
    _emit();
  }

  /// Live fraction backing the slider / waveform. When the user is
  /// scrubbing this short-circuits to the in-flight drag value so the
  /// player's position stream doesn't yank the thumb back during the
  /// gesture.
  @override
  double get progress {
    if (_scrubFrac != null) return _scrubFrac!.clamp(0.0, 1.0);
    if (_duration.inMilliseconds == 0) return 0;
    return (_shownPosition.inMilliseconds / _duration.inMilliseconds).clamp(
      0.0,
      1.0,
    );
  }

  /// The position to SHOW, which is not always the one last written.
  ///
  /// Guarding the ticker was not enough. Several things write
  /// `_position` — the ticker, a play/pause transition re-stamping
  /// from the platform, the end of a scrub — and every one of them can
  /// pick up the stale position the platform reports for a few frames
  /// after a seek. Guarding each write means every future write has to
  /// remember; guarding the READ means none of them do.
  ///
  /// So while a seek is in flight, a position that contradicts where
  /// it was aimed is not shown. That is the whole of the flash:
  /// tapping second 10 while playing second 20 showed 10, then 20, then
  /// 10 again.
  Duration get _shownPosition {
    final target = _seekTarget;
    if (target == null) return _position;
    return AudioScrub.trustReport(
          reported: _position,
          seekTarget: target,
          seekFrom: _seekFrom,
          sinceSeek: _sinceSeek.elapsed,
        )
        ? _position
        : target;
  }

  @override
  void scrubStart() {
    setState(() => _scrubFrac = progress);
  }

  @override
  void scrubUpdate(double f) {
    setState(() => _scrubFrac = f);
  }

  @override
  Future<void> scrubEnd(double f) async {
    // -1 sentinel from waveform's drag-end (no localPosition there);
    // use whatever update value we last buffered.
    final target = AudioScrub.target(
      reported: f,
      buffered: _scrubFrac,
      progress: progress,
    );

    // HOLD the visual at the target across the seek.
    //
    // Clearing it first put `progress` back on the old position for as
    // long as the engine took to move — so a tap at 80% left the bar
    // sitting at 20%, creeping forward under the ticker, and then
    // snapping across when the player finally reported. Reported as
    // the progress not animating correctly on a tap.
    // A drag-end with nothing buffered is not a seek: the recogniser
    // is cancelling a gesture that never became one, which happens on
    // every tap.
    if (!AudioScrub.isSeek(reported: f, buffered: _scrubFrac)) {
      return;
    }
    final generation = ++_scrubGeneration;
    setState(() => _scrubFrac = target);
    await seekFraction(target);
    if (!mounted) return;
    // SUPERSEDED. A tap fires `onTapDown` and the drag recogniser
    // cancels around it, so two of these overlap — and the one that
    // started first can finish last. Releasing here would publish this
    // call's target over the newer one's, which is the flash:
    // measured, 0.305 became 0.487 became 0.305 again.
    if (generation != _scrubGeneration) {
      return;
    }

    // `seekFraction` armed the guard, so the ticker is already
    // extrapolating from the target rather than from whatever the
    // platform is still reporting. This just lets the hold go.
    setState(() {
      _position = AudioScrub.positionFor(target, _duration);
      _scrubFrac = null;
    });
  }

  @override
  Widget build(BuildContext context) =>
      AudioPlayerChrome(handle: this, player: widget);
}

// ─── Bytes source shim ─────────────────────────────────────────

/// `just_audio` doesn't ship a raw-bytes source publicly; this wraps
/// the bytes via the `StreamAudioSource` extension point.
class _BytesSource extends StreamAudioSource {
  _BytesSource(this._bytes);
  final Uint8List _bytes;

  @override
  Future<StreamAudioResponse> request([int? start, int? end]) async {
    final s = start ?? 0;
    final e = end ?? _bytes.length;
    return StreamAudioResponse(
      sourceLength: _bytes.length,
      contentLength: e - s,
      offset: s,
      stream: Stream.value(_bytes.sublist(s, e)),
      contentType: 'audio/mpeg',
    );
  }
}

// ─── Video-backed state ───────────────────────────────────────
//
// Uses video_player for mp4/mov/mkv containers that just_audio can't
// demux on iOS/macOS. Video frames are decoded-and-discarded; no
// visual mounted. Implements the same AudioPlayerHandle interface so
// the shell chrome is identical.
class _VideoBackedAudioPlayerState extends State<GlobalAudioPlayer>
    with SingleTickerProviderStateMixin
    implements AudioPlayerHandle {
  // NOT final: a retry and a queue move each build a new one, because
  // `video_player` cannot re-open a controller.
  late VideoPlayerController _controller;
  Ticker? _positionTicker;

  final _stateController = StreamController<AudioStateSnapshot>.broadcast();
  final _amplitudeController = StreamController<double>.broadcast();
  final _bandController = StreamController<List<double>>.broadcast();
  BandSnapshots? _bandSnapshots;

  /// Where the last seek was aimed, until the controller agrees it got
  /// there — see `AudioScrub.trustReport`.
  Duration? _seekTarget;
  Duration _seekFrom = Duration.zero;
  final _sinceSeek = Stopwatch();

  /// See the audio-backed state — `scrubEnd` overlaps with itself.
  int _scrubGeneration = 0;

  /// Whether the end has already been reported. `video_player` has no
  /// completion event — it just stops with the position at the
  /// duration, and says so on every listener call after that.
  bool _completed = false;

  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;
  bool _playing = false;
  bool _loading = true;
  bool _errored = false;
  String? _errorMessage;

  /// The last position handed to `onPositionChanged`.
  Duration? _lastReported;

  /// This player's hold on the lock screen. Inert until an app wires
  /// [AudioBackground].
  final _background = AudioBackgroundLink();

  /// The queue, which a player without one still has: a single clip
  /// is a queue of one, so no code below asks which it is.
  late final List<AudioQueueItem> _items;
  int _index = 0;

  AudioQueueItem get _current => _items[_index];

  /// When playback stops on its own.
  AudioSleep _sleep = AudioSleep.off;
  Timer? _sleepTimer;
  double _speed = 1.0;
  bool _looping = false;

  List<double>? _decodedSamples;
  double? _scrubFrac;

  static const _speeds = [0.5, 1.0, 1.25, 1.5, 2.0];

  List<double> get _effectiveSamples =>
      _decodedSamples ?? _current.samples ?? AudioDefaults.flatWaveform;

  @override
  void initState() {
    super.initState();
    _items = _queueFor(widget);
    _controller = _buildController(_current.source);
    unawaited(_init());
  }

  VideoPlayerController _buildController(AudioSourceSpec spec) {
    switch (spec.kind) {
      case AudioSourceKind.videoUrl:
        return VideoPlayerController.networkUrl(Uri.parse(spec.value));
      case AudioSourceKind.videoFile:
        return VideoPlayerController.file(File(spec.value));
      case AudioSourceKind.videoAsset:
        return VideoPlayerController.asset(spec.value);
      // Non-video kinds shouldn't land here (dispatcher routes them
      // to the audio backend) — fall back to network as a guard.
      // ignore: no_default_cases
      default:
        return VideoPlayerController.networkUrl(Uri.parse(spec.value));
    }
  }

  Future<void> _init({bool resume = true, bool play = false}) async {
    try {
      await _controller.initialize();
      if (!mounted) return;
      // `video_player` has no initial-position setter, so this one
      // does seek — after `initialize`, which is when it is safe.
      // Only the item the player STARTS on resumes.
      final at = resume ? widget.initialPosition : null;
      if (at != null && at > Duration.zero) {
        await _controller.seekTo(at);
        if (!mounted) return;
      }
      setState(() {
        _duration = _controller.value.duration;
        _position = at ?? Duration.zero;
        _loading = false;
      });
      _controller.addListener(_onControllerUpdate);
      _attachBackground();

      if (widget.autoDecodeWaveform && _current.samples == null) {
        unawaited(_decodeWaveform());
      }
      if (widget.autoExtractBands) {
        unawaited(_extractBands());
      }
      if (widget.autoPlay || play) {
        await _controller.play();
        if (!mounted) return;
      }

      _positionTicker = createTicker((_) {
        if (!mounted) return;
        final p = _controller.value.position;
        // The same stale report the audio backend guards against: for
        // a few frames after a seek the controller still answers with
        // the position it was seeked AWAY from.
        if (!AudioScrub.trustReport(
          reported: p,
          seekTarget: _seekTarget,
          seekFrom: _seekFrom,
          sinceSeek: _sinceSeek.elapsed,
        )) {
          return;
        }
        _seekTarget = null;
        if (p == _position) return;
        setState(() => _position = p);
        _reportPosition();
        _emit();
        _emitAmplitude();
        _emitBands();
      });
      unawaited(_positionTicker!.start());
    } catch (e, st) {
      Logger.m.e(
        '[GlobalAudioPlayer:video] init failed for '
        '${_current.source.kind.name}=${_current.source.value} :: $e',
        error: e,
        stackTrace: st,
      );
      if (!mounted) return;
      setState(() {
        _errored = true;
        _errorMessage = e.toString();
        _loading = false;
      });
    }
  }

  /// See the audio-backed state.
  void _attachBackground() => _background.attach(
    nowPlaying: _current.nowPlaying,
    controls: AudioRemoteControls(
      play: play,
      pause: pause,
      seek: (at) async {
        _seekTarget = at;
        _seekFrom = _position;
        _sinceSeek
          ..reset()
          ..start();
        await _controller.seekTo(at);
      },
      skipForward: () => skip(AudioDefaults.skipSeconds),
      skipBackward: () => skip(-AudioDefaults.skipSeconds),
    ),
  );

  /// See the audio-backed state.
  void _reportPosition() {
    final report = widget.onPositionChanged;
    if (report == null) return;
    final shown = _shownPosition;
    final last = _lastReported;
    if (last != null &&
        (shown - last).abs() < AudioDefaults.positionReportInterval) {
      return;
    }
    _lastReported = shown;
    report(shown);
  }

  @override
  String? get errorMessage => _errorMessage;

  @override
  Future<void> retry() async {
    if (!_errored) return;
    // A fresh controller: `video_player` cannot re-initialise one that
    // failed, and reusing it fails again for the reason it already
    // failed.
    setState(() {
      _errored = false;
      _errorMessage = null;
      _loading = true;
    });
    _positionTicker?.dispose();
    _positionTicker = null;
    _controller.removeListener(_onControllerUpdate);
    unawaited(_controller.dispose());
    _controller = _buildController(_current.source);
    await _init();
  }

  void _onControllerUpdate() {
    if (!mounted) return;
    final v = _controller.value;
    final newPlaying = v.isPlaying;
    if (newPlaying != _playing) {
      setState(() => _playing = newPlaying);
      _emit();
    }
    final ended =
        _duration > Duration.zero && v.position >= _duration && !v.isPlaying;
    if (ended && !_completed) {
      _completed = true;
      _onTrackComplete();
    } else if (!ended && _completed) {
      _completed = false;
    }
    if (v.hasError && !_errored) {
      setState(() {
        _errored = true;
        _errorMessage = v.errorDescription;
      });
      Logger.m.e(
        '[GlobalAudioPlayer:video] controller error: '
        '${v.errorDescription}',
      );
    }
  }

  void _emit() {
    final snap = state;
    widget.onStateChanged?.call(snap);
    _background.report(snap.position, playing: _playing);
    if (!_stateController.isClosed) _stateController.add(snap);
  }

  void _emitAmplitude() {
    if (_amplitudeController.isClosed) return;
    if (!_playing) {
      _amplitudeController.add(0);
      return;
    }
    final s = _effectiveSamples;
    if (s.isEmpty) {
      _amplitudeController.add(0);
      return;
    }
    final idx = (progress * (s.length - 1)).round().clamp(0, s.length - 1);
    _amplitudeController.add(s[idx]);
  }

  void _emitBands() {
    if (_bandController.isClosed) return;
    final snap = _bandSnapshots;
    if (snap == null) return;
    _bandController.add(snap.at(_position));
  }

  Future<void> _decodeWaveform() async {
    final at = _index;
    final out = await WaveformExtractor.extract(_current.source, samples: 120);
    // The queue may have moved while this decoded. A shared cache
    // makes that FASTER, not impossible, and the bug it would cause is
    // the previous track's waveform drawn under this one.
    if (!mounted || out == null || at != _index) return;
    setState(() => _decodedSamples = out);
  }

  Future<void> _extractBands() async {
    final extractor = widget.bandExtractor ?? const SyntheticBandExtractor();
    final at = _index;
    final snap = await extractor.extract(
      _current.source,
      bandCount: widget.bandCount,
      timestampsCount: widget.bandSnapshotsCount,
    );
    if (!mounted || snap == null || at != _index) return;
    _bandSnapshots = BandSnapshots(
      bands: snap.bands,
      duration: _duration > Duration.zero ? _duration : snap.duration,
      bandCount: snap.bandCount,
    );
  }

  @override
  void dispose() {
    _sleepTimer?.cancel();
    _background.detach();
    _positionTicker?.dispose();
    _controller.removeListener(_onControllerUpdate);
    _controller.dispose();
    _stateController.close();
    _amplitudeController.close();
    _bandController.close();
    super.dispose();
  }

  // ─── AudioPlayerHandle ──────────────────────────────────────

  @override
  AudioStateSnapshot get state => AudioStateSnapshot(
    position: _shownPosition,
    duration: _duration,
    // video_player doesn't surface a buffered tail.
    buffered: _shownPosition,
    playing: _playing,
    loading: _loading,
    errored: _errored,
    speed: _speed,
    looping: _looping,
  );

  @override
  Stream<AudioStateSnapshot> get stateStream => _stateController.stream;

  @override
  Stream<double> get amplitudeStream => _amplitudeController.stream;

  @override
  Stream<List<double>> get bandStream => _bandController.stream;

  @override
  List<double> get samples => _effectiveSamples;

  @override
  Future<void> play() async {
    if (_errored) return;
    await _controller.play();
  }

  @override
  Future<void> pause() async {
    if (_errored) return;
    await _controller.pause();
  }

  @override
  Future<void> toggle() async {
    if (_errored) return;
    if (_playing) {
      await _controller.pause();
    } else {
      await _controller.play();
    }
  }

  @override
  Future<void> seekFraction(double f) async {
    if (_duration == Duration.zero) return;
    final landed = AudioScrub.positionFor(f, _duration);
    _seekTarget = landed;
    _seekFrom = _position;
    _sinceSeek
      ..reset()
      ..start();
    _completed = false;
    setState(() => _position = landed);
    await _controller.seekTo(landed);
  }

  // ─── The queue ───────────────────────────────────────────────

  @override
  int get trackIndex => _index;

  @override
  int get trackCount => _items.length;

  @override
  Future<void> next() async {
    final i = AudioQueue.nextIndex(
      index: _index,
      count: _items.length,
      wrap: widget.loopQueue,
    );
    if (i == null) return;
    await _goTo(i);
  }

  @override
  Future<void> previous() async {
    // One button, two meanings — see `AudioQueue.previousRestarts`.
    // Far enough in, or nowhere to go, and it restarts THIS one.
    if (AudioQueue.previousRestarts(_shownPosition)) {
      await seekFraction(0);
      return;
    }
    final i = AudioQueue.previousIndex(
      index: _index,
      count: _items.length,
      wrap: widget.loopQueue,
    );
    if (i == null) {
      await seekFraction(0);
      return;
    }
    await _goTo(i);
  }

  // ─── The sleep timer ─────────────────────────────────────────

  @override
  AudioSleep get sleep => _sleep;

  @override
  void setSleep(AudioSleep value) {
    _sleepTimer?.cancel();
    _sleepTimer = null;
    if (mounted) setState(() => _sleep = value);
    final after = value.after;
    if (after != null) {
      _sleepTimer = Timer(after, () {
        if (!mounted) return;
        unawaited(pause());
        setState(() => _sleep = AudioSleep.off);
        _emit();
      });
    }
    _emit();
  }

  /// What the end of a track means.
  ///
  /// The order is the point: an armed sleep timer BEATS auto-advance,
  /// because whoever set one did not ask for another track.
  void _onTrackComplete() {
    widget.onCompleted?.call();
    if (_sleep.atEndOfTrack) {
      unawaited(pause());
      setSleep(AudioSleep.off);
      return;
    }
    if (!widget.autoAdvance) return;
    final i = AudioQueue.nextIndex(
      index: _index,
      count: _items.length,
      wrap: widget.loopQueue,
    );
    if (i != null) unawaited(_goTo(i));
  }

  /// The same move as the audio backend's, plus a NEW controller.
  /// `video_player` opens one source and keeps it; there is no
  /// equivalent of `setUrl` on a live controller.
  Future<void> _goTo(int i) async {
    if (i < 0 || i >= _items.length || i == _index) return;
    final wasPlaying = _playing;
    _background.detach();
    _positionTicker?.dispose();
    _positionTicker = null;
    _controller.removeListener(_onControllerUpdate);
    unawaited(_controller.dispose());
    setState(() {
      _index = i;
      _position = Duration.zero;
      _duration = Duration.zero;
      _decodedSamples = null;
      _bandSnapshots = null;
      _scrubFrac = null;
      _loading = true;
      _errored = false;
      _errorMessage = null;
    });
    _seekTarget = null;
    _lastReported = null;
    _completed = false;
    widget.onTrackChanged?.call(i);
    _controller = _buildController(_current.source);
    await _init(resume: false, play: wasPlaying);
  }

  @override
  Future<void> skip(int seconds) async {
    final next = _position + Duration(seconds: seconds);
    final clamped = next < Duration.zero
        ? Duration.zero
        : (next > _duration ? _duration : next);
    await _controller.seekTo(clamped);
  }

  @override
  Future<void> cycleSpeed() async {
    final idx = _speeds.indexOf(_speed);
    final next = _speeds[(idx + 1) % _speeds.length];
    await setSpeed(next);
  }

  @override
  Future<void> setSpeed(double s) async {
    await _controller.setPlaybackSpeed(s);
    if (!mounted) return;
    setState(() => _speed = s);
    _emit();
  }

  @override
  Future<void> toggleLoop() async {
    final next = !_looping;
    await _controller.setLooping(next);
    if (!mounted) return;
    setState(() => _looping = next);
    _emit();
  }

  @override
  double get progress {
    if (_scrubFrac != null) return _scrubFrac!.clamp(0.0, 1.0);
    if (_duration.inMilliseconds == 0) return 0;
    return (_shownPosition.inMilliseconds / _duration.inMilliseconds).clamp(
      0.0,
      1.0,
    );
  }

  /// The position to SHOW, which is not always the one last written.
  ///
  /// Guarding the ticker was not enough. Several things write
  /// `_position` — the ticker, a play/pause transition re-stamping
  /// from the platform, the end of a scrub — and every one of them can
  /// pick up the stale position the platform reports for a few frames
  /// after a seek. Guarding each write means every future write has to
  /// remember; guarding the READ means none of them do.
  ///
  /// So while a seek is in flight, a position that contradicts where
  /// it was aimed is not shown. That is the whole of the flash:
  /// tapping second 10 while playing second 20 showed 10, then 20, then
  /// 10 again.
  Duration get _shownPosition {
    final target = _seekTarget;
    if (target == null) return _position;
    return AudioScrub.trustReport(
          reported: _position,
          seekTarget: target,
          seekFrom: _seekFrom,
          sinceSeek: _sinceSeek.elapsed,
        )
        ? _position
        : target;
  }

  @override
  void scrubStart() => setState(() => _scrubFrac = progress);

  @override
  void scrubUpdate(double f) => setState(() => _scrubFrac = f);

  @override
  Future<void> scrubEnd(double f) async {
    final target = AudioScrub.target(
      reported: f,
      buffered: _scrubFrac,
      progress: progress,
    );
    // Held across the seek, for the same reason as the audio-backed
    // state: dropping it first shows the OLD position until the engine
    // catches up, which reads as a tap that did not take.
    if (!AudioScrub.isSeek(reported: f, buffered: _scrubFrac)) return;
    final generation = ++_scrubGeneration;
    setState(() => _scrubFrac = target);
    await seekFraction(target);
    if (!mounted || generation != _scrubGeneration) return;
    setState(() {
      _position = AudioScrub.positionFor(target, _duration);
      _scrubFrac = null;
    });
  }

  @override
  Widget build(BuildContext context) =>
      AudioPlayerChrome(handle: this, player: widget);
}

/// The queue a player is working through.
///
/// A player given no [GlobalAudioPlayer.playlist] gets one of ONE,
/// built from the single-source parameters — so every path below
/// indexes a queue and none of them asks whether there is one.
List<AudioQueueItem> _queueFor(GlobalAudioPlayer w) {
  final list = w.playlist;
  if (list != null && list.isNotEmpty) return list;
  return [
    AudioQueueItem(
      source: w.source!,
      nowPlaying: w.nowPlaying,
      samples: w.samples,
    ),
  ];
}
