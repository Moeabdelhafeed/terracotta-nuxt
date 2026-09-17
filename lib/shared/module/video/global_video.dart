import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:visibility_detector/visibility_detector.dart';

import '../../../core/bootstrap/bootstrap_system_chrome.dart';
import '../../../core/localization/strings/common_strings.dart';
import '../../../core/localization/strings/module_strings.dart';
import '../../../core/utils/loggers/logger.dart';
import '../../../data/services/media/video_player_manager.dart';
import '../icon/global_icon.dart';
import '../progress/global_progress.dart';
import 'theme/video_theme.dart';
import 'video_audio_output.dart';
import 'video_control_button.dart';
import 'video_controls.dart';
import 'video_handback.dart';
import 'video_models.dart';
import 'video_wakelock.dart';

export '../../../data/services/media/video_player_manager.dart';
export 'theme/video_theme.dart';
export 'video_controls.dart';
export 'video_models.dart';
export 'video_seek_bar.dart';

part 'video_fullscreen.dart';
part 'video_pip.dart';

/// A video player: a source, a frame, and a set of controls.
///
/// What the player IS lives on the widget — the source, the title, the
/// callbacks, the widgets it shows instead of film. How it LOOKS and
/// which chrome it offers lives in [style], so an app can say once that
/// none of its players take a swipe, or that all of them offer a
/// screenshot button.
class GlobalVideo extends StatefulWidget {
  const GlobalVideo({
    super.key,
    this.source,
    this.sourceType = VideoSourceType.network,
    this.playlist,
    this.playlistStartIndex = 0,
    this.style = const VideoStyle(),
    this.chapters = const [],
    this.onCastPressed,
    this.initialPosition,
    this.onPositionChanged,
    this.width,
    this.height,
    this.aspectRatio = VideoDefaults.aspectRatio,
    this.autoPlay = false,
    this.loop = false,
    this.muted = false,
    this.initialVolume = 100.0,
    this.initialRate = 1.0,
    this.initialPitch = 1.0,
    this.httpHeaders,
    this.title,
    this.semanticLabel,
    this.customTopBar,
    this.customBottomBar,
    this.poster,
    this.placeholder,
    this.errorWidget,
    this.overlay,
    this.externalSubtitle,
    this.externalAudio,
    this.onPlay,
    this.onPause,
    this.onComplete,
    this.onError,
    this.onScreenshot,
  });

  // ─── Source ────────────────────────────────────────────────
  final String? source;
  final VideoSourceType sourceType;
  final List<String>? playlist;
  final int playlistStartIndex;

  /// How it looks, and which chrome it offers.
  final VideoStyle style;

  /// Offer a cast button, and run this when it is pressed.
  ///
  /// A HOOK rather than an implementation: AirPlay and Cast are native
  /// route pickers, different on every platform, and a module that
  /// shipped one would be shipping a guess about which. The control
  /// appears only when an app has something for it to do.
  final VoidCallback? onCastPressed;

  /// Named points in the film, marked on the timeline and named in the
  /// scrub badge.
  ///
  /// On the WIDGET rather than in the style bag: where the second act
  /// starts is a property of the content, and a theme cannot know it.
  final List<VideoChapter> chapters;

  /// Where to start, for a player resuming something already begun.
  ///
  /// Applied ONCE, after the media opens. The module deliberately does
  /// not persist this itself — `lib/shared/module` has no storage — so
  /// an app pairs it with [onPositionChanged] and keeps the value
  /// wherever it keeps everything else.
  final Duration? initialPosition;

  /// Reports where the film has got to, at most once every
  /// [VideoDefaults.positionReportInterval].
  ///
  /// Throttled because the position stream fires several times a
  /// second and the other end of this is usually a write to disk.
  final ValueChanged<Duration>? onPositionChanged;

  // ─── Layout of THIS instance ───────────────────────────────
  final double? width;
  final double? height;
  final double? aspectRatio;

  // ─── Playback ──────────────────────────────────────────────
  final bool autoPlay;
  final bool loop;
  final bool muted;
  final double initialVolume;
  final double initialRate;
  final double initialPitch;
  final Map<String, String>? httpHeaders;

  // ─── Content ───────────────────────────────────────────────
  final String? title;

  /// What a reader hears instead of "video player". Defaults to the
  /// [title] when there is one — a page with four players all announcing
  /// themselves the same way says nothing about which is which.
  final String? semanticLabel;

  final Widget? customTopBar;
  final Widget? customBottomBar;
  final Widget? poster;
  final Widget? placeholder;
  final Widget? errorWidget;
  final Widget? overlay;

  // ─── Tracks ────────────────────────────────────────────────
  final SubtitleConfig? externalSubtitle;
  final SubtitleConfig? externalAudio;

  // ─── Callbacks ─────────────────────────────────────────────
  final VoidCallback? onPlay;
  final VoidCallback? onPause;
  final VoidCallback? onComplete;
  final ValueChanged<String>? onError;
  final ValueChanged<Uint8List>? onScreenshot;

  // ─── Factories ─────────────────────────────────────────────
  //
  // Thin on purpose. They name the SOURCE and nothing else, because
  // every knob they used to forward now lives in `style` — the old
  // `.network` took thirty-one parameters and passed all of them
  // straight through.

  factory GlobalVideo.network(
    String url, {
    Key? key,
    VideoStyle style = const VideoStyle(),
    List<VideoChapter> chapters = const [],
    VoidCallback? onCastPressed,
    Duration? initialPosition,
    ValueChanged<Duration>? onPositionChanged,
    double? width,
    double? height,
    double? aspectRatio = VideoDefaults.aspectRatio,
    bool autoPlay = false,
    bool loop = false,
    bool muted = false,
    Map<String, String>? httpHeaders,
    String? title,
    String? semanticLabel,
    Widget? poster,
    Widget? placeholder,
    Widget? errorWidget,
    Widget? overlay,
    Widget? customTopBar,
    Widget? customBottomBar,
    SubtitleConfig? externalSubtitle,
    VoidCallback? onPlay,
    VoidCallback? onPause,
    VoidCallback? onComplete,
    ValueChanged<String>? onError,
    ValueChanged<Uint8List>? onScreenshot,
  }) => GlobalVideo(
    key: key,
    source: url,
    style: style,
    chapters: chapters,
    onCastPressed: onCastPressed,
    initialPosition: initialPosition,
    onPositionChanged: onPositionChanged,
    width: width,
    height: height,
    aspectRatio: aspectRatio,
    autoPlay: autoPlay,
    loop: loop,
    muted: muted,
    httpHeaders: httpHeaders,
    title: title,
    semanticLabel: semanticLabel,
    poster: poster,
    placeholder: placeholder,
    errorWidget: errorWidget,
    overlay: overlay,
    customTopBar: customTopBar,
    customBottomBar: customBottomBar,
    externalSubtitle: externalSubtitle,
    onPlay: onPlay,
    onPause: onPause,
    onComplete: onComplete,
    onError: onError,
    onScreenshot: onScreenshot,
  );

  factory GlobalVideo.playlist(
    List<String> urls, {
    Key? key,
    int startIndex = 0,
    VideoStyle style = const VideoStyle(),
    List<VideoChapter> chapters = const [],
    VoidCallback? onCastPressed,
    Duration? initialPosition,
    ValueChanged<Duration>? onPositionChanged,
    double? width,
    double? height,
    double? aspectRatio = VideoDefaults.aspectRatio,
    bool autoPlay = false,
    bool loop = false,
    bool muted = false,
    String? title,
    String? semanticLabel,
    Widget? poster,
    VoidCallback? onComplete,
  }) => GlobalVideo(
    key: key,
    playlist: urls,
    playlistStartIndex: startIndex,
    style: style,
    chapters: chapters,
    onCastPressed: onCastPressed,
    initialPosition: initialPosition,
    onPositionChanged: onPositionChanged,
    width: width,
    height: height,
    aspectRatio: aspectRatio,
    autoPlay: autoPlay,
    loop: loop,
    muted: muted,
    title: title,
    semanticLabel: semanticLabel,
    poster: poster,
    onComplete: onComplete,
  );

  factory GlobalVideo.asset(
    String assetPath, {
    Key? key,
    VideoStyle style = const VideoStyle(),
    List<VideoChapter> chapters = const [],
    VoidCallback? onCastPressed,
    Duration? initialPosition,
    ValueChanged<Duration>? onPositionChanged,
    double? width,
    double? height,
    double? aspectRatio = VideoDefaults.aspectRatio,
    bool autoPlay = false,
    bool loop = false,
    bool muted = false,
    String? title,
    String? semanticLabel,
    Widget? poster,
    Widget? placeholder,
  }) => GlobalVideo(
    key: key,
    source: assetPath,
    sourceType: VideoSourceType.asset,
    style: style,
    chapters: chapters,
    onCastPressed: onCastPressed,
    initialPosition: initialPosition,
    onPositionChanged: onPositionChanged,
    width: width,
    height: height,
    aspectRatio: aspectRatio,
    autoPlay: autoPlay,
    loop: loop,
    muted: muted,
    title: title,
    semanticLabel: semanticLabel,
    poster: poster,
    placeholder: placeholder,
  );

  factory GlobalVideo.file(
    String filePath, {
    Key? key,
    VideoStyle style = const VideoStyle(),
    List<VideoChapter> chapters = const [],
    VoidCallback? onCastPressed,
    Duration? initialPosition,
    ValueChanged<Duration>? onPositionChanged,
    double? width,
    double? height,
    double? aspectRatio = VideoDefaults.aspectRatio,
    bool autoPlay = false,
    bool loop = false,
    bool muted = false,
    String? title,
    String? semanticLabel,
    Widget? poster,
    Widget? placeholder,
  }) => GlobalVideo(
    key: key,
    source: filePath,
    sourceType: VideoSourceType.file,
    style: style,
    chapters: chapters,
    onCastPressed: onCastPressed,
    initialPosition: initialPosition,
    onPositionChanged: onPositionChanged,
    width: width,
    height: height,
    aspectRatio: aspectRatio,
    autoPlay: autoPlay,
    loop: loop,
    muted: muted,
    title: title,
    semanticLabel: semanticLabel,
    poster: poster,
    placeholder: placeholder,
  );

  @override
  State<GlobalVideo> createState() => GlobalVideoState();
}

/// A player and its texture, parked between the widget that died and
/// the widget that replaces it.
class _ParkedVideo {
  const _ParkedVideo(this.player, this.controller);

  final Player player;
  final VideoController controller;
}

/// Where a fullscreen page leaves a player whose inline widget died
/// while the page was up. One slot, because one player comes back from
/// fullscreen at a time.
final HandbackSlot<_ParkedVideo> _videoHandback = HandbackSlot<_ParkedVideo>(
  onExpire: (parked) {
    try {
      parked.player.dispose();
    } catch (_) {}
  },
);

class GlobalVideoState extends State<GlobalVideo>
    with TickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  /// Stays alive while its fullscreen page is up.
  ///
  /// Fullscreen forces landscape, which REFLOWS the page underneath —
  /// and a `ShowcasePage` builds its children through a
  /// `SliverList.builder`, which culls what the new viewport no longer
  /// reaches. The card was being culled, this State disposed, and
  /// `dispose` disposes the player the fullscreen page is showing. That
  /// is the black picture with the FROZEN seek bar: not a texture
  /// problem, a destroyed player. Coming back rebuilt the widget with a
  /// fresh player, which is why it always "recovered".
  ///
  /// Scoped to fullscreen deliberately. Keeping every player alive
  /// forever would defeat the culling that stops a page of them
  /// exhausting the device — see the known gap in this module's
  /// CLAUDE.md.
  @override
  bool get wantKeepAlive => _isFullscreen;
  late final Player _player;
  late final VideoController _controller;
  bool _initialized = false;
  bool _hasError = false;
  bool _hasStarted = false;
  bool _isFullscreen = false;
  bool _wasPlayingBeforeOffscreen = false;
  bool _disposed = false;
  int _playlistIndex = 0;
  int _playlistLength = 0;

  // PiP state
  OverlayEntry? _pipEntry;
  bool _pipActive = false;
  final GlobalKey _videoKey = GlobalKey();

  /// Who disposes the player while a fullscreen page is up.
  final _ownership = VideoOwnership();

  /// Captured when the fullscreen page is pushed, because `dispose`
  /// cannot ask the element tree for one.
  NavigatorState? _fullscreenNavigator;

  /// The last error mpv reported, so a repeat is not logged again.
  String? _lastError;

  // Stream subscriptions — stored for proper cancellation
  final List<StreamSubscription> _subs = [];

  /// Public access to the underlying player (for programmatic control).
  /// The engine, started on demand.
  ///
  /// A caller reaching for the player wants one, so asking is enough to
  /// start it — otherwise this would hand back an uninitialised field.
  Player get player {
    _startEngine();
    return _player;
  }

  bool get _isPlayerAlive {
    if (_disposed || !_engineStarted) return false;
    try {
      _player.state;
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> _safe(Future<void> Function() fn) async {
    if (!_isPlayerAlive) return;
    try {
      await fn();
    } catch (_) {}
  }

  @override
  void initState() {
    super.initState();
    // No engine is created here — that is `_startEngine`, and it waits
    // to be seen. But a player parked by a widget that died while its
    // fullscreen page was up is not a new engine, it is the SAME one,
    // still playing, at the position the user left it. Claiming it now
    // rather than waiting to be seen is what makes leaving fullscreen
    // look like the page coming back instead of the clip restarting.
    final parked = _videoHandback.claim(_handbackKey);
    if (parked != null) _adopt(parked);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _refreshKeepAwake();
  }

  @override
  void didUpdateWidget(GlobalVideo oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.style != oldWidget.style) _refreshKeepAwake();
  }

  /// What a parked player is filed under. Empty when there is nothing
  /// stable to file it under, which means it is never parked.
  String get _handbackKey => widget.source ?? widget.playlist?.first ?? '';

  /// Takes over a player that is already open and already playing.
  ///
  /// Everything `_startEngine` does EXCEPT create and open: the state
  /// that `_openMedia` would have set on the way through is seeded from
  /// the player itself, because the streams only report changes and
  /// this one already happened.
  void _adopt(_ParkedVideo parked) {
    _engineStarted = true;
    _player = parked.player;
    _controller = parked.controller;
    _initialized = true;
    _hasStarted = true;
    _playlistIndex = _player.state.playlist.index;
    _playlistLength = _player.state.playlist.medias.length;
    VideoPlayerManager.instance.register(_player);
    _setupListeners();
  }

  /// The visibility detector's identity, fixed for the life of the
  /// STATE rather than derived from the widget.
  ///
  /// It used to be built from the source string and the widget's own
  /// identity hash, and a
  /// rebuilt `GlobalVideo` is a NEW instance with a new identity hash —
  /// so the key changed on every rebuild, the element could not be
  /// updated, and the whole subtree under it was torn down and mounted
  /// again. On a hot reload that remount ran while the controls'
  /// `LayoutBuilder` was in `performLayout`, and the seek bar's
  /// `Slider` — which parks its value indicator in an `OverlayPortal` —
  /// had its deferred layout box adopted mid-layout:
  /// "A _RenderDeferredLayoutBox was mutated in
  /// _RenderLayoutBuilder.performLayout", followed by a storm of
  /// GlobalKey retake assertions as `_videoKey` was dragged through the
  /// same rebuild.
  ///
  /// It also threw away the texture and started mpv again each time,
  /// which is the opposite of what the lazy start is for.
  final Key _visibilityKey = UniqueKey();

  /// The last position handed to `onPositionChanged`.
  Duration? _lastReportedPosition;

  /// Whether the inline picture FILLS its frame rather than fitting
  /// it. The fullscreen page keeps its own — they are different frames
  /// and a reader who crops one has not asked about the other.
  bool _filling = false;

  /// Whether THIS player is currently holding the screen awake.
  ///
  /// Tracked per player rather than read back from the counter: the
  /// stream reports the same value more than once, and a second
  /// `acquire` for one player would leave a hold nothing releases.
  bool _awake = false;

  void _holdScreenAwake(bool playing) {
    final wanted = playing && _keepScreenAwake;
    if (wanted == _awake) return;
    _awake = wanted;
    wanted ? VideoWakelock.acquire() : VideoWakelock.release();
  }

  /// Whether the RESOLVED style says to hold the screen on.
  ///
  /// Cached rather than resolved on demand: this is read from an mpv
  /// stream, which arrives between frames when there is no context to
  /// resolve with. Reading the caller's bag directly was the shortcut,
  /// and it silently ignored `GlobalVideoTheme` — an app that turned
  /// this off house-wide still held the screen on.
  ///
  /// Refreshed wherever the answer can change: the theme
  /// (`didChangeDependencies`) and the caller's bag
  /// (`didUpdateWidget`).
  bool _keepScreenAwake = true;

  void _refreshKeepAwake() {
    final resolved = widget.style.resolve(context).keepScreenAwake;
    if (resolved == _keepScreenAwake) return;
    _keepScreenAwake = resolved;
    // A player already running under a theme that has just turned this
    // off must let the screen go.
    _holdScreenAwake(_playingNow && resolved);
  }

  /// Whether mpv currently reports playback, asked rather than tracked
  /// — `_awake` is what this widget DID, not what the player is doing.
  bool get _playingNow {
    if (!_engineStarted) return false;
    try {
      return _player.state.playing;
    } catch (_) {
      return false;
    }
  }

  /// Whether mpv has been started for this widget.
  bool _engineStarted = false;

  /// Creates the player, and does it LATE.
  ///
  /// One mpv instance per mounted widget was the single most expensive
  /// thing this module did. `VideoPlayerManager` caps how many players
  /// PLAY; it never capped how many EXIST, so a page of fifteen cards
  /// stood up fifteen engines — fifteen textures, fifteen audio-device
  /// attempts, fifteen things for a hot restart to tear down — before
  /// anyone had scrolled to the second one.
  ///
  /// Now the engine starts when the widget is first SEEN. Until then
  /// the widget shows its poster or placeholder, which is what it
  /// showed during loading anyway, so nothing looks different — a
  /// player that is off screen simply does not exist yet.
  ///
  /// Called from the visibility detector, and from `player` for a
  /// caller that reaches for the engine directly.
  void _startEngine() {
    if (_engineStarted || _disposed) return;
    _engineStarted = true;
    _player = Player();
    _controller = VideoController(_player);
    VideoPlayerManager.instance.register(_player);
    _setupListeners();
    _openMedia();
  }

  void _setupListeners() {
    _subs.add(
      _player.stream.playing.listen((playing) {
        if (_disposed) return;
        if (playing && !_hasStarted) {
          _hasStarted = true;
          if (mounted) setState(() {});
        }
        // A film is watched without touching the device, so the idle
        // timer is measuring the wrong thing — the screen used to dim
        // halfway through and then lock.
        _holdScreenAwake(playing);
        if (playing) {
          widget.onPlay?.call();
        } else {
          widget.onPause?.call();
        }
      }),
    );

    _subs.add(
      _player.stream.completed.listen((completed) {
        if (completed && !_disposed) widget.onComplete?.call();
      }),
    );

    _subs.add(
      _player.stream.error.listen((error) {
        if (error.isEmpty || _disposed) return;

        // mpv re-reports the same failure on every loop. A simulator
        // with no audio output emitted "Could not open/initialize audio
        // device" once every eight seconds, for every player on the
        // page, forever — which buries everything else in the log.
        // Per player for ordinary errors; the audio-device one is
        // device-wide and logs itself once, below.
        if (error != _lastError && !VideoPlaybackIssue.isAudioDevice(error)) {
          _lastError = error;
          Logger.m.w('[Video] $error');
        } else if (VideoPlaybackIssue.isAudioDevice(error) &&
            !VideoAudioOutput.unavailable.value) {
          Logger.m.w('[Video] $error');
        }

        widget.onError?.call(error);

        // No audio OUTPUT is not a broken video. The film plays; only
        // the volume control has nothing to act on, so it says so
        // instead of pretending it works. Common on a simulator and on
        // a desktop with no default device.
        if (VideoPlaybackIssue.isAudioDevice(error)) {
          // Device-wide, so every player learns it from the first one
          // that finds out — including the ones in fullscreen and PiP,
          // which had no way to hear about it before.
          if (VideoAudioOutput.report()) _stopTryingAudio();
          return;
        }

        if (error.contains('Failed to open') && mounted) {
          setState(() => _hasError = true);
        }
      }),
    );

    if (widget.onPositionChanged != null) {
      _subs.add(
        _player.stream.position.listen((position) {
          if (_disposed) return;
          // Throttled: the stream fires several times a second and the
          // other end of this is usually a write to disk.
          final last = _lastReportedPosition;
          if (last != null &&
              (position - last).abs() < VideoDefaults.positionReportInterval) {
            return;
          }
          _lastReportedPosition = position;
          widget.onPositionChanged?.call(position);
        }),
      );
    }

    _subs.add(
      _player.stream.playlist.listen((pl) {
        if (mounted && !_disposed) {
          setState(() {
            _playlistIndex = pl.index;
            _playlistLength = pl.medias.length;
          });
        }
      }),
    );
  }

  Future<void> _openMedia() async {
    try {
      Playable playable;

      if (widget.playlist != null && widget.playlist!.isNotEmpty) {
        playable = Playlist(
          widget.playlist!
              .map(
                (url) => Media(
                  url,
                  httpHeaders: widget.httpHeaders,
                  // Only the item the playlist STARTS on resumes; the
                  // ones after it are new viewings.
                  start: url == widget.playlist![widget.playlistStartIndex]
                      ? widget.initialPosition
                      : null,
                ),
              )
              .toList(),
          index: widget.playlistStartIndex,
        );
      } else if (widget.source != null) {
        final uri = switch (widget.sourceType) {
          VideoSourceType.network => widget.source!,
          VideoSourceType.asset => 'asset://${widget.source!}',
          VideoSourceType.file => widget.source!,
        };
        // `start` rather than a seek after opening. mpv is told where
        // to begin and opens THERE; a seek issued straight after
        // `open` raced the file being loaded and was dropped, which is
        // why resume reported 0:20 and played from zero.
        playable = Media(
          uri,
          httpHeaders: widget.httpHeaders,
          start: widget.initialPosition,
        );
      } else {
        return;
      }

      await _player.open(playable, play: widget.autoPlay);
      if (widget.loop) await _player.setPlaylistMode(PlaylistMode.loop);
      if (widget.muted) await _player.setVolume(0);
      if (widget.initialVolume != 100.0 && !widget.muted) {
        await _player.setVolume(widget.initialVolume);
      }
      if (widget.initialRate != 1.0) await _player.setRate(widget.initialRate);
      if (widget.initialPitch != 1.0) {
        await _player.setPitch(widget.initialPitch);
      }

      if (widget.externalSubtitle != null) {
        final sub = widget.externalSubtitle!;
        if (sub.uri != null) {
          await _player.setSubtitleTrack(
            SubtitleTrack.uri(
              sub.uri!,
              title: sub.title,
              language: sub.language,
            ),
          );
        } else if (sub.data != null) {
          await _player.setSubtitleTrack(
            SubtitleTrack.data(
              sub.data!,
              title: sub.title,
              language: sub.language,
            ),
          );
        }
      }

      if (widget.externalAudio?.uri != null) {
        await _player.setAudioTrack(
          AudioTrack.uri(
            widget.externalAudio!.uri!,
            title: widget.externalAudio!.title,
            language: widget.externalAudio!.language,
          ),
        );
      }

      if (mounted) setState(() => _initialized = true);
    } catch (e) {
      debugPrint('GlobalVideo open error: $e');
      widget.onError?.call(e.toString());
      if (mounted) setState(() => _hasError = true);
    }
  }

  @override
  void dispose() {
    _disposed = true;
    for (final sub in _subs) {
      sub.cancel();
    }
    _subs.clear();
    _removePip();
    // Pop an open fullscreen page, so it is not left showing a player
    // that is about to be disposed.
    //
    // Through a CAPTURED navigator, not `Navigator.of(context)`. By the
    // time this runs the element is defunct, and reading `context` here
    // throws "this widget has been unmounted" — which is exactly the
    // error the playground probe hit doing the same thing. The `try`
    // around it meant this never worked and never said so.
    //
    // With keep-alive in place this is a backstop rather than the fix:
    // a host that disables automatic keep-alives can still cull the
    // widget, and closing the page beats leaving a black one up.
    //
    // Destroyed while its fullscreen page is still up: HAND THE PLAYER
    // OVER rather than disposing it, and leave the page alone.
    //
    // This happens with `wantKeepAlive` true — measured — so it is not
    // a sliver cull and keep-alive cannot prevent it. Rather than keep
    // hunting for what destroys the element, the player stops caring:
    // whoever is SHOWING it owns it. The page disposes it on the way
    // out instead, and exactly one of the two always does.
    //
    // Popping the page here was the old answer and it was the wrong
    // one. It is what made the button look like it opened fullscreen
    // and immediately came back.
    // An engine that never started has nothing to unregister, nothing
    // to dispose, and no page to hand anything to.
    // Whatever happens to the player, this widget stops holding the
    // screen on.
    _holdScreenAwake(false);
    if (_engineStarted) {
      VideoPlayerManager.instance.unregister(_player);
      if (_isFullscreen) {
        _ownership.orphaned = true;
        // And tell the page to PARK it rather than dispose it, so the
        // widget that replaces this one keeps the same engine at the
        // same position. Captured, because by then this state is gone.
        final key = _handbackKey;
        if (key.isNotEmpty) {
          final parked = _ParkedVideo(_player, _controller);
          _ownership.onOrphanedClose = () => _videoHandback.park(key, parked);
        }
      } else {
        _player.dispose();
      }
    }
    _fullscreenNavigator = null;
    super.dispose();
  }

  // ─── Fullscreen ────────────────────────────────────────────

  void _toggleFullscreen() {
    if (!_isPlayerAlive) return;
    if (_isFullscreen) {
      Navigator.of(context).pop();
    } else {
      // Auto-play on fullscreen if not playing
      _safe(() async {
        if (!_player.state.playing) await _player.play();
      });
      setState(() => _isFullscreen = true);
      updateKeepAlive();
      _fullscreenNavigator = Navigator.of(context);
      _fullscreenNavigator!.push(
        PageRouteBuilder(
          opaque: true,
          pageBuilder: (context, anim, secondAnim) => FadeTransition(
            opacity: anim,
            child: _FullscreenVideoPage(
              chapters: widget.chapters,
              onCastPressed: widget.onCastPressed,
              controller: _controller,
              player: _player,
              ownership: _ownership,
              style: widget.style,
              title: widget.title,
              onScreenshot: widget.onScreenshot,
              // Deferred, because this fires from the page's `dispose`
              // — which runs during UNMOUNT, when the tree is locked.
              // A `setState` there throws "setState() called when
              // widget tree was locked", and the throw left
              // `_isFullscreen` stuck TRUE. Everything after that
              // followed from the stuck flag: the inline `Video` never
              // came back (black until a rotation rebuilt it), and the
              // next press of the fullscreen button took the
              // `if (_isFullscreen)` branch and POPPED instead of
              // pushing, which looked like the button doing nothing.
              onExit: _leaveFullscreen,
              hasNext:
                  _playlistLength > 1 && _playlistIndex < _playlistLength - 1,
              hasPrevious: _playlistLength > 1 && _playlistIndex > 0,
              onNext: () => _safe(() => _player.next()),
              onPrevious: () => _safe(() => _player.previous()),
              showPlaylistButtons: _playlistLength > 1,
            ),
          ),
          transitionDuration: const Duration(milliseconds: 250),
          reverseTransitionDuration: const Duration(milliseconds: 200),
        ),
      );
    }
  }

  // ─── PiP (Picture-in-Picture) ──────────────────────────────

  void _showPip() {
    if (_pipActive || !_hasStarted || !_isPlayerAlive) return;
    _pipActive = true;
    // Get the video's screen-space rect for morph animation
    Rect? sourceRect;
    final rb = _videoKey.currentContext?.findRenderObject() as RenderBox?;
    if (rb != null && rb.attached) {
      final pos = rb.localToGlobal(Offset.zero);
      sourceRect = pos & rb.size;
    }

    _pipEntry = OverlayEntry(
      builder: (_) => _PipOverlay(
        player: _player,
        controller: _controller,
        style: widget.style,
        onClose: () {
          _removePip();
          if (_isPlayerAlive) _player.pause();
        },
        onDismiss: _removePip,
        onFullscreen: () {
          _removePip();
          _toggleFullscreen();
        },
        sourceRect: sourceRect,
        onStateCreated: (state) => _pipState = state,
      ),
    );
    Overlay.of(context, rootOverlay: true).insert(_pipEntry!);
  }

  void _removePip({bool animate = false}) {
    if (!_pipActive) return;
    if (animate && _pipState != null) {
      // Get current video rect for reverse morph
      Rect? targetRect;
      final rb = _videoKey.currentContext?.findRenderObject() as RenderBox?;
      if (rb != null && rb.attached) {
        final pos = rb.localToGlobal(Offset.zero);
        targetRect = pos & rb.size;
      }
      _pipState!.animateOut(targetRect, () {
        _pipEntry?.remove();
        _pipEntry = null;
        _pipActive = false;
        _pipState = null;
      });
    } else {
      _pipEntry?.remove();
      _pipEntry = null;
      _pipActive = false;
      _pipState = null;
    }
  }

  _PipOverlayState? _pipState;

  // ─── Visibility ────────────────────────────────────────────

  void _onVisibilityChanged(VisibilityInfo info) {
    final visible = info.visibleFraction > VideoDefaults.offscreenFraction;

    // First sighting starts the engine. Everything below needs one.
    if (visible) _startEngine();
    if (_isFullscreen || !_isPlayerAlive) return;

    final rs = widget.style.resolve(context);
    if (!visible && _player.state.playing) {
      _wasPlayingBeforeOffscreen = true;
      if (rs.pipOnOffscreen) {
        _showPip();
      } else if (rs.pauseOnOffscreen) {
        _player.pause();
      }
    } else if (visible && _wasPlayingBeforeOffscreen) {
      if (_pipActive) _removePip(animate: true);
      _wasPlayingBeforeOffscreen = false;
      if (_isPlayerAlive && !_player.state.playing) _player.play();
    }
  }

  // ─── Screenshot (public API) ───────────────────────────────

  /// Puts the flag back, on a frame where that is legal.
  ///
  /// The fullscreen page reports its exit from `dispose`, which the
  /// framework runs while unmounting — the tree is locked and no
  /// element may be marked dirty. Waiting for the end of the frame is
  /// the whole fix.
  void _leaveFullscreen() {
    _fullscreenNavigator = null;
    if (!mounted) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_isFullscreen) return;
      setState(() => _isFullscreen = false);
      updateKeepAlive();
    });
  }

  /// Tells mpv to stop opening an audio device once it has failed.
  ///
  /// It does not give up on its own: the same failure came back on
  /// every loop, once every eight seconds, from every player on the
  /// page. Retrying an output that is not there is not going to find
  /// one — a simulator has none, and a desktop with no default device
  /// has none until the reader changes that, which restarting the app
  /// covers.
  ///
  /// `ao=null` is mpv's own "decode audio, output it nowhere", so the
  /// film keeps its timing and the video keeps playing.
  Future<void> _stopTryingAudio() async {
    final platform = _player.platform;
    if (platform is! NativePlayer) return;
    try {
      await platform.setProperty('ao', 'null');
    } catch (_) {
      // Best effort. If mpv will not take the property the only cost
      // is the log line we already de-duplicate.
    }
  }

  Future<Uint8List?> takeScreenshot({String format = 'image/png'}) async {
    if (!_isPlayerAlive) return null;
    return await _player.screenshot(format: format);
  }

  // ─── Build ─────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    // Required by AutomaticKeepAliveClientMixin.
    super.build(context);

    // Materialized ONCE per build: nothing below re-derives
    // `style.x ?? palette.y` at each use.
    final rs = widget.style.resolve(context);
    final radius =
        rs.borderRadius ?? BorderRadius.circular(VideoDefaults.fallbackRadius);

    Widget content;
    if (_hasError) {
      content = widget.errorWidget ?? _buildDefaultError();
    } else if (!_initialized) {
      content = widget.placeholder ?? _buildDefaultPlaceholder();
    } else {
      content = Stack(
        fit: StackFit.expand,
        children: [
          if (!_hasStarted && widget.poster != null) widget.poster!,
          // ONE `Video` per controller, ever.
          //
          // A `VideoController` owns a single texture, and two `Video`
          // widgets pointing at it do not share — the fullscreen page
          // came up pitch black while the inline player it was pushed
          // from sat behind it, still holding the texture, because an
          // opaque route does not unmount what it covers.
          //
          // The inline one stands down while the fullscreen page has
          // it, and takes it back on the way out.
          if ((_hasStarted || widget.poster == null) && !_isFullscreen)
            Video(
              controller: _controller,
              controls: NoVideoControls,
              // media_kit draws its OWN subtitles on top of the
              // texture, so the film carried two copies of every line:
              // theirs mid-frame in a fixed style, ours in the bar. And
              // theirs painted an empty plate between cues.
              //
              // Ours stays because it is the themeable one — it reads
              // `subtitleStyle`, sits with the bar, moves when the bar
              // appears and disappears when there is nothing to say.
              subtitleViewConfiguration: const SubtitleViewConfiguration(
                visible: false,
              ),
              fill: Colors.transparent,
              // Fill CROPS to the frame, fit letterboxes it. The
              // fullscreen page keeps its own answer: they are
              // different frames, and cropping one is not a request
              // about the other.
              fit: _filling ? BoxFit.cover : BoxFit.contain,
            ),
          if (rs.showControls)
            VideoControls(
              chapters: widget.chapters,
              onCastPressed: widget.onCastPressed,
              onZoomChanged: (filling) => setState(() => _filling = filling),
              player: _player,
              style: widget.style,
              title: widget.title,
              onFullscreenToggle: _toggleFullscreen,
              customTopBar: widget.customTopBar,
              customBottomBar: widget.customBottomBar,
              onScreenshot: widget.onScreenshot,
              showPlaylistButtons: _playlistLength > 1,
              hasNext: _playlistIndex < _playlistLength - 1,
              hasPrevious: _playlistIndex > 0,
              onNext: () {
                if (_isPlayerAlive) _player.next();
              },
              onPrevious: () {
                if (_isPlayerAlive) _player.previous();
              },
            ),
          if (widget.overlay != null) widget.overlay!,
        ],
      );
    }

    Widget result = Container(
      key: _videoKey,
      width: widget.width,
      height: widget.height,
      decoration: BoxDecoration(
        color: rs.backgroundColor,
        borderRadius: radius,
        boxShadow: rs.boxShadow,
      ),
      clipBehavior: Clip.antiAlias,
      child: content,
    );

    if (widget.aspectRatio != null && widget.height == null) {
      result = AspectRatio(aspectRatio: widget.aspectRatio!, child: result);
    }

    // ALWAYS wired now, not just for pause / PiP: this is what tells
    // the widget it has been SEEN, and therefore when to start mpv.
    result = VisibilityDetector(
      key: _visibilityKey,
      onVisibilityChanged: _onVisibilityChanged,
      child: result,
    );

    // ONE node for the whole player, and the buttons inside it are its
    // children — a reader jumping by control should find the player and
    // then its controls, not eight loose buttons floating over film.
    //
    // The label falls back to the title because a page with four
    // players all announcing "video player" has said nothing about
    // which is which.
    return Semantics(
      container: true,
      explicitChildNodes: true,
      label: widget.semanticLabel ?? widget.title ?? VideoStrings.player,
      child: result,
    );
  }

  Widget _buildDefaultPlaceholder() => Center(
    child: GlobalProgress.loading(
      type: ProgressType.circular,
      style: const ProgressStyle(color: Colors.white54, thickness: 3),
    ),
  );

  Widget _buildDefaultError() => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.error_outline, size: 40, color: Colors.red.shade300),
        const SizedBox(height: 8),
        Text(
          VideoStrings.loadFailed,
          style: const TextStyle(color: Colors.white70, fontSize: 14),
        ),
      ],
    ),
  );
}
