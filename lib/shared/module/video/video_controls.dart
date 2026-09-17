import 'dart:async';

import 'dart:typed_data';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:media_kit/media_kit.dart';
import 'package:screen_brightness/screen_brightness.dart';

import '../../../core/extensions/context_extensions.dart';
import '../../../core/localization/strings/module_strings.dart';
import '../../../core/utils/layout/bar_fit.dart';
import '../popup/popup.dart';
import '../progress/global_progress.dart';
import '../toast/global_toast.dart';
import 'theme/video_theme.dart';
import 'video_audio_output.dart';
import 'video_bar_budget.dart';
import 'video_control_button.dart';
import 'video_gesture_overlays.dart';
import 'video_models.dart';
import 'video_seek_bar.dart';
import 'video_settings_menu.dart';
import 'video_shortcuts.dart';

/// One optional control on the bar.
///
/// It knows how to be a BUTTON and how to be a MENU ITEM, because it
/// has to be whichever one the available width allows. Anything that
/// can only be one of those is not a member of this list.
///
/// One control, one slot. `barFit` takes group sizes because the PDF
/// viewer has a zoom PAIR that is meaningless split in half; nothing
/// here is paired, so nothing here claims two.
@immutable
class _VideoBarControl {
  const _VideoBarControl({
    required this.value,
    required this.icon,
    required this.label,
    required this.onTap,
    this.text,
  });

  /// Drawn INSTEAD of the glyph on the bar, for a control whose value
  /// is the thing worth showing. The menu still uses [icon].
  final String? text;

  /// What the menu hands back when this is picked from the overflow.
  /// Prefixed so it cannot collide with a speed or a track.
  final String value;

  final IconData icon;
  final String label;
  final VoidCallback? onTap;
}

/// Custom video controls overlay with gesture support.
class VideoControls extends StatefulWidget {
  const VideoControls({
    super.key,
    required this.player,
    this.style = const VideoStyle(),
    this.title,
    this.onFullscreenToggle,
    this.isFullscreen = false,
    this.customTopBar,
    this.customBottomBar,
    this.onScreenshot,
    this.showPlaylistButtons = false,
    this.onLock,
    this.chapters = const [],
    this.onCastPressed,
    this.onZoomChanged,
    this.zoomController,
    this.onZoomScaleChanged,
    this.hasNext = false,
    this.hasPrevious = false,
    this.onNext,
    this.onPrevious,
    this.onDismissDrag,
    this.onDismissDragEnd,
  });

  final Player player;

  /// Which chrome to offer and how it looks. Resolved once per build.
  final VideoStyle style;
  final String? title;
  final VoidCallback? onFullscreenToggle;
  final bool isFullscreen;
  final Widget? customTopBar, customBottomBar;
  final ValueChanged<Uint8List>? onScreenshot;
  final bool showPlaylistButtons, hasNext, hasPrevious;
  final VoidCallback? onNext, onPrevious;

  /// Named points in the film, marked on the timeline.
  final List<VideoChapter> chapters;

  /// Offer a cast button, and run this when it is pressed.
  ///
  /// A HOOK rather than an implementation: AirPlay and Cast are native
  /// route pickers, different on every platform, and a module that
  /// shipped one would be shipping a guess about which. The control
  /// appears only when an app has something for it to do.
  final VoidCallback? onCastPressed;

  /// Told when the picture switches between fitting and filling.
  final ValueChanged<bool>? onZoomChanged;

  /// The transform a pinch drives.
  ///
  /// Owned by whoever owns the picture — the fullscreen page — because
  /// the controls sit ABOVE it and are the only thing that can see the
  /// fingers. Null means this player does not zoom, and then a pinch
  /// is just a two-fingered nothing.
  final TransformationController? zoomController;

  /// The scale after a pinch, so the page can gate its own panning.
  final ValueChanged<double>? onZoomScaleChanged;

  /// Freezes the control layer entirely. Fullscreen only — an inline
  /// player is small and already surrounded by a page that takes taps.
  final VoidCallback? onLock;

  /// mpv could not open an audio device. The film still plays; the
  /// volume control is the only thing with nothing to act on.
  final ValueChanged<double>?
  onDismissDrag; // reports vertical offset for drag-to-dismiss
  final void Function(double velocity)?
  onDismissDragEnd; // reports end velocity

  @override
  State<VideoControls> createState() => _VideoControlsState();
}

class _VideoControlsState extends State<VideoControls>
    with TickerProviderStateMixin {
  bool _visible = true;
  Timer? _hideTimer;
  bool _dragging = false;
  double _dragValue = 0;
  bool _disposed = false;

  late final List<StreamSubscription> _subs;
  bool _playing = false, _completed = false, _buffering = false;
  Duration _position = Duration.zero,
      _duration = Duration.zero,
      _buffered = Duration.zero;
  double _volume = 100.0, _rate = 1.0;
  List<AudioTrack> _audioTracks = [];
  List<SubtitleTrack> _subtitleTracks = [];
  List<VideoTrack> _videoTracks = [];
  AudioTrack? _currentAudioTrack;
  SubtitleTrack? _currentSubtitleTrack;
  VideoTrack? _currentVideoTrack;
  String _subtitle = '';

  // Double-tap
  int _dtSeekSecs = 0;
  Timer? _dtResetTimer;
  bool _dtLeft = false;
  late AnimationController _dtAnimCtrl;
  late Animation<double> _dtAnim;

  // Pan gesture (direction detection)
  bool _panDecided = false; // whether direction has been determined
  bool _panIsHorizontal = false;

  // Vertical swipe (brightness / volume)
  /// Whether the DEVICE has an audio output, read from
  /// `VideoAudioOutput` rather than passed in.
  ///
  /// It used to be a constructor parameter, which meant the inline
  /// player was guarded and the fullscreen page and PiP were not — and
  /// the flag can flip a second after a player starts, long after any
  /// of them were built.
  bool get _noAudioDevice => VideoAudioOutput.unavailable.value;

  bool _swiping = false, _swipeIsVol = false;
  double _swipeVal = 0, _brightness = 0.5;

  // Horizontal drag seek
  bool _hDragging = false;
  double _hDragStartMs = 0; // position when drag started
  double _hDragCurrentMs = 0; // current seek target

  // Dismiss drag
  bool _dismissing = false;
  double _dismissOffset = 0;

  // Long-press
  bool _lpActive = false;
  double _lpOrigRate = 1.0;

  // Thumbnail
  Uint8List? _thumbBytes;
  double _thumbMs = 0;
  bool _showThumb = false;
  Timer? _thumbDebounce;
  static const _maxThumbCacheSize = 30;
  final Map<int, Uint8List> _thumbCache = {}; // keyed by second, LRU eviction

  /// Resolved ONCE per dependency change, not per gesture.
  ///
  /// It lives on the state rather than inside `build` because the
  /// gesture handlers and the auto-hide timer read it too, and those
  /// run between builds.
  ///
  /// NOT `late`. `initState` starts the auto-hide timer and that reads
  /// this, but `didChangeDependencies` — the only place a style CAN be
  /// resolved, because it needs the inherited theme — runs after it.
  /// A `late` field turned that ordering into a
  /// `LateInitializationError` on the first frame of every player.
  ResolvedVideoStyle _rs = ResolvedVideoStyle.fallback;
  bool _reduceMotion = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _rs = widget.style.resolve(context);
    _reduceMotion = MediaQuery.disableAnimationsOf(context);
  }

  @override
  void didUpdateWidget(VideoControls oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.style != widget.style) {
      _rs = widget.style.resolve(context);
    }
  }

  @override
  void initState() {
    super.initState();
    // The discovery lands up to a second after a player starts, so
    // controls that are already built have to hear about it.
    VideoAudioOutput.unavailable.addListener(_onAudioOutputChanged);
    // SEEDED from the player, not waited for.
    //
    // Every one of these arrives on a stream that only emits when it
    // CHANGES, so a controls instance built after the media opened
    // hears nothing until something moves. That is every instance
    // except the first: the fullscreen page and the PiP window both
    // build their own controls over a player that is already running.
    //
    // The track lists were the visible half of it — a subtitle toggle
    // that was on the inline bar and missing in fullscreen, because
    // `tracks` had been reported once, before that page existed.
    final state = widget.player.state;
    _playing = state.playing;
    _completed = state.completed;
    _buffering = state.buffering;
    _position = state.position;
    _duration = state.duration;
    _buffered = state.buffer;
    _volume = state.volume;
    _rate = state.rate;
    _audioTracks = state.tracks.audio;
    _subtitleTracks = state.tracks.subtitle;
    _videoTracks = state.tracks.video;
    _currentAudioTrack = state.track.audio;
    _currentSubtitleTrack = state.track.subtitle;
    _currentVideoTrack = state.track.video;

    _subs = [
      widget.player.stream.playing.listen((v) => _u(() => _playing = v)),
      widget.player.stream.completed.listen(
        (v) => _u(() {
          _completed = v;
          if (v) {
            _showCtrls();
            // "At the end of this video" is not a clock — it waits for
            // exactly this, and it beats auto-play-next, because a
            // reader who set a sleep timer did not ask for another one.
            if (_sleepAtEnd) {
              setState(() => _sleepAtEnd = false);
              _safe(() => widget.player.pause());
            } else {
              _startAutoPlayNext();
            }
          } else {
            _cancelAutoPlayNext();
          }
        }),
      ),
      widget.player.stream.position.listen((v) {
        _u(() => _position = v);
        _enforceAbLoop(v);
      }),
      widget.player.stream.duration.listen((v) => _u(() => _duration = v)),
      widget.player.stream.buffer.listen((v) => _u(() => _buffered = v)),
      widget.player.stream.volume.listen((v) => _u(() => _volume = v)),
      widget.player.stream.rate.listen((v) => _u(() => _rate = v)),
      widget.player.stream.buffering.listen((v) => _u(() => _buffering = v)),
      widget.player.stream.tracks.listen(
        (t) => _u(() {
          _audioTracks = t.audio;
          _subtitleTracks = t.subtitle;
          _videoTracks = t.video;
        }),
      ),
      widget.player.stream.track.listen(
        (t) => _u(() {
          _currentAudioTrack = t.audio;
          _currentSubtitleTrack = t.subtitle;
          _currentVideoTrack = t.video;
        }),
      ),
      widget.player.stream.subtitle.listen(
        // TRIMMED, because mpv reports a LIST of lines and the gap
        // between two cues arrives as blank ones. Joining those gives
        // `"\n"`, which is not empty — so the plate drew itself around
        // nothing, which is the box that kept appearing between lines.
        (s) => _u(() => _subtitle = s.join('\n').trim()),
      ),
    ];

    _dtAnimCtrl = AnimationController(
      vsync: this,
      duration: VideoDefaults.doubleTapFlash,
    );
    _dtAnim = Tween<double>(
      begin: 1.0,
      end: 0.0,
    ).animate(CurvedAnimation(parent: _dtAnimCtrl, curve: Curves.easeOut));

    _initBrightness();
    _startHide();
  }

  Future<void> _initBrightness() async {
    try {
      _brightness = await ScreenBrightness.instance.application;
    } catch (_) {}
  }

  void _u(VoidCallback fn) {
    if (mounted && !_disposed) setState(fn);
  }

  bool get _alive {
    try {
      widget.player.state;
      return true;
    } catch (_) {
      return false;
    }
  }

  @override
  void dispose() {
    _disposed = true;
    VideoAudioOutput.unavailable.removeListener(_onAudioOutputChanged);
    for (final s in _subs) {
      s.cancel();
    }
    _hideTimer?.cancel();
    _sleepTimer?.cancel();
    _autoNextTimer?.cancel();
    _liveScrubTimer?.cancel();
    _dtResetTimer?.cancel();
    _dtAnimCtrl.dispose();
    _thumbDebounce?.cancel();
    super.dispose();
  }

  /// True while the settings menu is up.
  ///
  /// A FLAG rather than a one-shot cancel, because several things
  /// re-arm the clock — the `completed` stream calls `_showCtrls`, and
  /// so does the end of a seek — and any of them would have hidden the
  /// bar out from under an open menu again.
  bool _menuOpen = false;

  void _startHide() {
    _hideTimer?.cancel();
    if (!ResolvedVideoStyle.shouldAutoHide(
      playing: _playing,
      dragging: _dragging,
      menuOpen: _menuOpen,
    )) {
      return;
    }
    _hideTimer = Timer(_rs.autoHideDelay, () {
      if (!mounted) return;
      if (!ResolvedVideoStyle.shouldAutoHide(
        playing: _playing,
        dragging: _dragging,
        menuOpen: _menuOpen,
      )) {
        return;
      }
      setState(() => _visible = false);
    });
  }

  void _showCtrls() {
    setState(() => _visible = true);
    _startHide();
  }

  void _toggleCtrls() {
    // The only OTHER way the bar goes away, and the flag has to hold
    // here too: a tap that reaches the player while the menu is up
    // would otherwise hide the bar out from under it, which is the
    // whole failure this flag exists to stop.
    if (_visible && !_menuOpen) {
      setState(() => _visible = false);
      _hideTimer?.cancel();
    } else {
      _showCtrls();
    }
  }

  /// Safe player call wrapper — all media_kit methods are async internally,
  /// so we must await them to catch assertions thrown inside synchronized locks.
  Future<void> _safe(Future<void> Function() fn) async {
    if (!_alive) return;
    try {
      await fn();
    } catch (_) {}
  }

  /// Flips the glyph NOW and lets the engine catch up.
  ///
  /// Every piece of state here is fed by an mpv stream, which is the
  /// right source of truth and the wrong thing to wait for: the icon
  /// used to change only once the native player had echoed the new
  /// state back, so a tap felt like it had been ignored for as long as
  /// that round trip took. The stream still has the last word — it
  /// arrives a beat later and overwrites this — so a call the engine
  /// refuses corrects itself instead of leaving a lying glyph.
  void _togglePlay() {
    final replaying = _completed;
    setState(() {
      _playing = ResolvedVideoStyle.playingAfterTap(
        playing: _playing,
        completed: replaying,
      );
      if (replaying) _completed = false;
    });
    _safe(() async {
      if (replaying) {
        await widget.player.seek(Duration.zero);
        await widget.player.play();
      } else {
        await widget.player.playOrPause();
      }
    });
    _showCtrls();
  }

  void _seekBy(Duration d) {
    _safe(() async {
      final t = _position + d;
      await widget.player.seek(
        t < Duration.zero ? Duration.zero : (t > _duration ? _duration : t),
      );
    });
  }

  /// There is no output to mute, and saying so beats a control that
  /// does nothing when pressed.
  // ─── Up next ───────────────────────────────────────────────

  /// Seconds left before the next item plays itself, or null when
  /// nothing is counting.
  int? _autoNextIn;
  Timer? _autoNextTimer;

  /// Starts the countdown, if there is something to count towards.
  ///
  /// A countdown is only honest when there IS a next item and the
  /// caller has said it may run — an autoplay nobody asked for is the
  /// single most complained-about behaviour a player has.
  void _startAutoPlayNext() {
    if (!_rs.autoPlayNext || !widget.hasNext || widget.onNext == null) return;
    if (_autoNextTimer != null) return;
    setState(
      () => _autoNextIn = VideoDefaults.autoPlayNextDelay.inSeconds,
    );
    _autoNextTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      final left = (_autoNextIn ?? 1) - 1;
      if (left > 0) {
        setState(() => _autoNextIn = left);
        return;
      }
      _cancelAutoPlayNext();
      widget.onNext?.call();
    });
  }

  void _cancelAutoPlayNext() {
    _autoNextTimer?.cancel();
    _autoNextTimer = null;
    if (_autoNextIn != null && mounted) setState(() => _autoNextIn = null);
  }

  /// The timeline, with the clock wherever the bag puts it.
  ///
  /// Returns the ROWS of the bottom bar above the control row, because
  /// `below` is one child and every other placement is one row holding
  /// both — a single widget would have to be a `Column` with an empty
  /// slot in it.
  List<Widget> _timelineRow(
    ResolvedVideoStyle st, {
    required Color primary,
    required double scale,
    required double fontSize,
  }) {
    final timeline = _buildSeekBar(primary, st, scale);
    final gap = SizedBox(width: VideoDefaults.barPaddingH * scale);

    return switch (st.clockPlacement) {
      VideoClockPlacement.below => [timeline],
      VideoClockPlacement.beforeTimeline => [
        Row(
          children: [
            _clock(_elapsedAndTotal, st, fontSize),
            gap,
            Expanded(child: timeline),
          ],
        ),
      ],
      VideoClockPlacement.afterTimeline => [
        Row(
          children: [
            Expanded(child: timeline),
            gap,
            _clock(_elapsedAndTotal, st, fontSize),
          ],
        ),
      ],
      // Each number at the end it describes.
      VideoClockPlacement.split => [
        Row(
          children: [
            _clock(formatVideoDuration(_elapsed), st, fontSize),
            gap,
            Expanded(child: timeline),
            gap,
            _clock(formatVideoDuration(_duration), st, fontSize),
          ],
        ),
      ],
    };
  }

  /// Where the film has got to — the DRAG's position while one is in
  /// progress, since that is what the reader is asking about.
  Duration get _elapsed =>
      _dragging ? Duration(milliseconds: _dragValue.toInt()) : _position;

  String get _elapsedAndTotal =>
      '${formatVideoDuration(_elapsed)} / ${formatVideoDuration(_duration)}';

  /// A clock, pinned LTR.
  ///
  /// Under bidi the slash is a neutral and an RTL paragraph reorders
  /// the two numbers around it, so an Arabic reader was shown the total
  /// first and read it as the position. The colons in `1:02:15` are
  /// neutrals too.
  Widget _clock(String text, ResolvedVideoStyle st, double fontSize) {
    final base =
        st.timeLabelStyle ??
        TextStyle(
          color: st.iconColor.withValues(alpha: VideoDefaults.timeLabelOpacity),
          fontSize: fontSize,
        );
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Text(
        text,
        // TABULAR figures, or the clock changes width as the digits
        // change and the timeline beside it grows and shrinks a pixel
        // at a time — a 1 is narrower than a 0 in most faces, so a
        // clock ticking past :10 visibly moved the slider. Applied over
        // whatever the theme gave, rather than instead of it.
        style: base.copyWith(
          fontFeatures: const [FontFeature.tabularFigures()],
        ),
      ),
    );
  }

  /// Play, seek and previous / next, in reading order.
  ///
  /// One list for both placements — centred over the film and inline in
  /// the bar are the same controls at different sizes, and building
  /// them twice is how the two drift apart.
  ///
  /// [playSz] is the big centre button; in the bar everything takes
  /// [iconSz], because a 44-point play button in a 36-point row is a
  /// row with a lump in it.
  List<Widget> _transportControls(
    ResolvedVideoStyle st, {
    required double iconSz,
    required double playSz,
    required double scale,
    bool compact = false,
    bool playLeads = false,
  }) {
    final size = compact ? _barIconSize(iconSz) : iconSz + 2;
    final gap = SizedBox(width: VideoDefaults.controlGap * scale);
    return [
      // Shown whenever there IS a playlist, disabled at its ends. These
      // used to appear and vanish with `hasPrevious` / `hasNext`, so
      // the transport shuffled sideways on every track change and the
      // button being aimed at moved.
      if (widget.showPlaylistButtons) ...[
        VideoControlButton(
          icon: Icons.skip_previous_rounded,
          size: size,
          color: st.iconColor,
          label: VideoStrings.previous,
          onTap: widget.hasPrevious ? widget.onPrevious : null,
          compactTarget: compact,
        ),
        gap,
      ],
      // Play LEADS only where the row is read left to right and the
      // control being reached for should be the first thing the eye
      // lands on. Anywhere the transport is CENTRED — over the film or
      // in the middle of the bar — rewind comes first, because the
      // point of centring is that PLAY is in the middle, and a group
      // that starts with play puts it off to one side of its own
      // centre. Which is exactly what it did.
      if (st.showSeekButtons && !playLeads) ...[
        VideoControlButton(
          icon: Icons.replay_10_rounded,
          size: size,
          color: st.iconColor,
          label: VideoStrings.seekBack(st.seekDuration.inSeconds),
          onTap: () => _seekBy(-st.seekDuration),
          compactTarget: compact,
        ),
        gap,
      ],
      VideoPlayPauseButton(
        playing: _playing,
        completed: _completed,
        replayIcon: st.replayIcon,
        size: compact ? size : playSz,
        color: st.iconColor,
        label: _completed
            ? VideoStrings.replay
            : _playing
            ? VideoStrings.pause
            : VideoStrings.play,
        onTap: _togglePlay,
        // No scrim disc inline: the bar is already a scrim, and a disc
        // on a disc reads as a button stuck to the background.
        background: compact
            ? null
            : Colors.black.withValues(alpha: VideoDefaults.buttonScrimOpacity),
        compactTarget: compact,
      ),
      if (st.showSeekButtons && playLeads) ...[
        gap,
        VideoControlButton(
          icon: Icons.replay_10_rounded,
          size: size,
          color: st.iconColor,
          label: VideoStrings.seekBack(st.seekDuration.inSeconds),
          onTap: () => _seekBy(-st.seekDuration),
          compactTarget: compact,
        ),
      ],
      if (st.showSeekButtons) ...[
        gap,
        VideoControlButton(
          icon: Icons.forward_10_rounded,
          size: size,
          color: st.iconColor,
          label: VideoStrings.seekForward(st.seekDuration.inSeconds),
          onTap: () => _seekBy(st.seekDuration),
          compactTarget: compact,
        ),
      ],
      if (widget.showPlaylistButtons) ...[
        gap,
        VideoControlButton(
          icon: Icons.skip_next_rounded,
          size: size,
          color: st.iconColor,
          label: VideoStrings.next,
          onTap: widget.hasNext ? widget.onNext : null,
          compactTarget: compact,
        ),
      ],
    ];
  }

  /// The control that never folds into the menu.
  ///
  /// Fullscreen was last in the list, so it was the FIRST thing the
  /// fit dropped — a player with eight controls switched on had no way
  /// into fullscreen except a menu, which is not where anyone looks
  /// for it. It is the control that changes every other one, so it
  /// keeps its slot and stays at the END of the row where it has
  /// always been.
  List<_VideoBarControl> _pinnedTrailing(ResolvedVideoStyle st) => [
    if (st.showFullscreenButton)
      _VideoBarControl(
        value: 'ctl_fullscreen',
        icon: widget.isFullscreen ? st.exitFullscreenIcon : st.fullscreenIcon,
        label: widget.isFullscreen
            ? VideoStrings.exitFullscreen
            : VideoStrings.enterFullscreen,
        onTap: widget.onFullscreenToggle,
      ),
  ];

  /// How many bar slots the inline transport takes, so the trailing
  /// controls are fitted into what is actually left.
  int get _inlineTransportSlots {
    if (_rs.transportPlacement == VideoTransportPlacement.centered) return 0;
    var count = 1;
    if (widget.showPlaylistButtons) count += 2;
    if (_rs.showSeekButtons) count += 2;
    return count;
  }

  /// Whether a REAL subtitle track is showing.
  bool get _subtitlesOn =>
      _currentSubtitleTrack != null &&
      VideoSettings.isRealTrackId(_currentSubtitleTrack!.id);

  /// The subtitle line, at whatever size the reader has asked for.
  ///
  /// One builder for both plates — the one in the bar and the one that
  /// stands in for it when the bar is hidden. They were the same
  /// eleven lines twice, and a size control that reached only one of
  /// them would look broken exactly half the time.
  Widget _subtitlePlate(
    ResolvedVideoStyle st,
    BuildContext context,
    double scale,
  ) {
    final base =
        st.subtitleStyle ??
        TextStyle(
          color: st.iconColor,
          fontSize: (context.textTheme.bodyMedium?.fontSize ?? 14) * scale,
        );

    return IgnorePointer(
      // The plate is CONTENT, and a decorated box takes the pointer. A
      // long line grows the bar upwards until it reaches the centre
      // transport, and every tap that landed on the text was eaten by
      // it — the play button was right there and would not answer.
      // Same rule as the scrims: only controls absorb.
      child: Container(
        // The reader's size applies to the BOX as well as the glyphs.
        // Scaling one and not the other is what put a 200% line in a
        // 100% plate with its descenders against the edge.
        padding: st.subtitlePadding * scale * _subtitleScale,
        decoration: BoxDecoration(
          color: st.subtitleBackground,
          borderRadius: BorderRadius.circular(
            VideoDefaults.subtitleRadius * scale * _subtitleScale,
          ),
        ),
        child: Text(
          _subtitle,
          style: base.copyWith(
            fontSize: (base.fontSize ?? 14) * _subtitleScale,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  /// The chapter the film is IN, or the one being scrubbed towards.
  ///
  /// Follows the drag rather than the playhead while a scrub is in
  /// progress: the reader is asking where they are about to land, and
  /// the answer is what the timeline is being read for.
  VideoChapter? get _currentChapter {
    if (widget.chapters.isEmpty) return null;
    final at = _hDragging
        ? Duration(milliseconds: _hDragCurrentMs.toInt())
        : (_dragging ? Duration(milliseconds: _dragValue.toInt()) : _position);
    return VideoChapter.at(at, widget.chapters);
  }

  /// What a control that did not fit should DO when picked from the
  /// menu, keyed by the value the menu will hand back.
  ///
  /// Rebuilt every frame with the bar, because which controls overflow
  /// depends on the width the frame was given.
  final Map<String, VoidCallback> _overflowActions = {};

  /// The auxiliary controls, in the order they earn their place.
  ///
  /// Everything here is OPTIONAL chrome — the transport in the middle
  /// is not, and never moves. Adding a control is appending one entry:
  /// it takes a slot on the bar while there is room and folds into the
  /// gear's menu when there is not.
  List<_VideoBarControl> _trailingGroups(
    ResolvedVideoStyle st,
    double iconSz,
  ) => [
    if (st.showScreenshotButton)
      _VideoBarControl(
        value: 'ctl_screenshot',
        icon: Icons.camera_alt_rounded,
        label: VideoStrings.screenshot,
        onTap: _screenshot,
      ),
    if (st.showMuteButton)
      _VideoBarControl(
        value: 'ctl_mute',
        icon: _noAudioDevice
            ? Icons.volume_off_rounded
            : (_volume > 0 ? st.unmuteIcon : st.muteIcon),
        label: _noAudioDevice
            ? VideoStrings.noAudioDevice
            : (_volume > 0 ? VideoStrings.mute : VideoStrings.unmute),
        onTap: _noAudioDevice ? _reportNoAudio : _toggleMute,
      ),
    if (st.showSubtitleToggle && _realSubtitleTracks.isNotEmpty)
      _VideoBarControl(
        value: 'ctl_subtitles',
        icon: _subtitlesOn
            ? Icons.closed_caption_rounded
            : Icons.closed_caption_off_rounded,
        label: VideoStrings.subtitlesToggle(on: _subtitlesOn),
        onTap: _toggleSubtitles,
      ),
    if (st.showReplayButton)
      _VideoBarControl(
        value: 'ctl_replay',
        icon: Icons.restart_alt_rounded,
        label: VideoStrings.replayFromStart,
        onTap: _replayFromStart,
      ),
    if (st.showZoomToggle)
      _VideoBarControl(
        value: 'ctl_zoom',
        icon: _filling
            ? Icons.fullscreen_exit_rounded
            : Icons.aspect_ratio_rounded,
        label: VideoStrings.zoomToggle(filling: _filling),
        onTap: _toggleZoom,
      ),
    if (st.showAbLoop)
      _VideoBarControl(
        value: 'ctl_loop',
        icon: _loopB != null ? Icons.repeat_on_rounded : Icons.repeat_rounded,
        label: _abLoopLabel,
        onTap: _cycleAbLoop,
      ),
    if (widget.onCastPressed != null)
      _VideoBarControl(
        value: 'ctl_cast',
        icon: Icons.cast_rounded,
        label: VideoStrings.castToScreen,
        onTap: widget.onCastPressed,
      ),
    if (st.showSpeedCycler)
      _VideoBarControl(
        value: 'ctl_speed',
        icon: Icons.speed_rounded,
        label: VideoStrings.playbackSpeed,
        onTap: _cycleSpeed,
        // A speed is worth READING, so this one wears its value
        // instead of a glyph. It still folds into the menu as an
        // ordinary item when the bar runs out of room.
        text: _speedLabel,
      ),
    // Fullscreen only, and last: it is the control that takes the
    // others away, so it should not push one of them into the menu.
    if (widget.onLock != null)
      _VideoBarControl(
        value: 'ctl_lock',
        icon: Icons.lock_outline_rounded,
        label: VideoStrings.lockScreen,
        onTap: widget.onLock,
      ),
  ];

  /// The controls the current width has room for, as buttons.
  ///
  /// Filled by `_fitTrailingControls` at the top of `build`, before
  /// either bar is built: the gear that holds the overflow lives in the
  /// TOP bar and the controls it holds live in the BOTTOM one, so the
  /// decision cannot wait for either to be laid out.
  // ─── The extra controls ────────────────────────────────────

  /// Where an A–B loop starts, once one has been marked.
  Duration? _loopA;

  /// And where it ends. With both set the film loops between them.
  Duration? _loopB;

  /// Counts down to a pause, or null when nothing is set.
  Timer? _sleepTimer;

  /// True when the timer is "at the end of this video" rather than a
  /// duration — that one is not a clock, it waits for `completed`.
  bool _sleepAtEnd = false;

  /// How far subtitles are shifted from the audio.
  Duration _subtitleOffset = Duration.zero;

  /// How big the subtitle plate is drawn, against the resolved style.
  double _subtitleScale = 1;

  void _nudgeSubtitleSize(double by) {
    setState(
      () => _subtitleScale = by == 0
          ? 1
          : (_subtitleScale + by).clamp(
              VideoDefaults.subtitleScaleMin,
              VideoDefaults.subtitleScaleMax,
            ),
    );
    _showCtrls();
  }

  /// Whether the picture is FILLING the frame rather than fitting it.
  bool _filling = false;

  /// The subtitle tracks a reader could actually choose.
  ///
  /// `auto` and `no` are libmpv's placeholders and are present on every
  /// file, including files with no subtitles at all. Counting them is
  /// what made the toggle appear on a film that had none — and then do
  /// nothing when pressed, because there was nothing to turn on.
  List<SubtitleTrack> get _realSubtitleTracks =>
      _subtitleTracks.where((t) => VideoSettings.isRealTrackId(t.id)).toList();

  void _toggleSubtitles() {
    if (_subtitlesOn) {
      _safe(() => widget.player.setSubtitleTrack(SubtitleTrack.no()));
      return;
    }
    // Back on means the first real track: "off" forgot which one was
    // chosen, and the gear is where a reader picks a different one.
    final first = _realSubtitleTracks.firstOrNull;
    if (first == null) return;
    _safe(() => widget.player.setSubtitleTrack(first));
  }

  void _replayFromStart() {
    _safe(() async {
      await widget.player.seek(Duration.zero);
      await widget.player.play();
    });
    _showCtrls();
  }

  void _toggleZoom() {
    setState(() => _filling = !_filling);
    widget.onZoomChanged?.call(_filling);
    _showCtrls();
  }

  /// Marks A, then B, then clears — one control for the whole cycle,
  /// because three separate buttons for one loop is a bar nobody reads.
  void _cycleAbLoop() {
    setState(() {
      if (_loopA == null) {
        _loopA = _position;
      } else if (_loopB == null) {
        // B before A is a loop the reader drew backwards, not an
        // error: take it as the pair they meant.
        final a = _loopA!;
        if (_position > a) {
          _loopB = _position;
        } else {
          _loopA = _position;
          _loopB = a;
        }
      } else {
        _loopA = null;
        _loopB = null;
      }
    });
    _showCtrls();
  }

  String get _abLoopLabel => _loopA == null
      ? VideoStrings.loopSetA
      : (_loopB == null ? VideoStrings.loopSetB : VideoStrings.loopClear);

  /// Sends the film back to A when it passes B.
  void _enforceAbLoop(Duration position) {
    final a = _loopA;
    final b = _loopB;
    if (a == null || b == null || position < b) return;
    _safe(() => widget.player.seek(a));
  }

  void _setSleepTimer(int? minutes, {bool atEnd = false}) {
    _sleepTimer?.cancel();
    _sleepTimer = null;
    setState(() => _sleepAtEnd = atEnd);
    if (atEnd || minutes == null) return;
    _sleepTimer = Timer(Duration(minutes: minutes), () {
      if (mounted) _safe(() => widget.player.pause());
    });
  }

  void _nudgeSubtitles(Duration by) {
    final next = by == Duration.zero ? Duration.zero : _subtitleOffset + by;
    setState(() => _subtitleOffset = next);
    // Straight to mpv: `Player` has no `setSubtitleDelay`, and
    // `sub-delay` is the property that does it — in SECONDS, which is
    // why this is not just the Duration.
    final platform = widget.player.platform;
    if (platform is NativePlayer) {
      _safe(
        () => platform.setProperty(
          'sub-delay',
          (next.inMilliseconds / 1000).toString(),
        ),
      );
    }
    _showCtrls();
  }

  /// The size every control in the bar is drawn at.
  ///
  /// One number, because a transport button and a mute button sitting
  /// in the same row at different sizes reads as a mistake — and it
  /// was two: the transport took `iconSz - 2` and everything else
  /// `iconSz - 6`.
  double _barIconSize(double iconSz) => iconSz - 2;

  /// The controls the current width has room for, already SPLIT by
  /// which side of the row they belong to.
  ///
  /// Split by the fit rather than after it: each side is its own box,
  /// half the row wide, and cutting a list that was fitted against the
  /// whole row in two puts more into one half than it can hold.
  List<_VideoBarControl> _leftControls = const [];
  List<_VideoBarControl> _rightControls = const [];

  /// Reserved, and always at the end. See `_pinnedTrailing`.
  List<_VideoBarControl> _pinned = const [];

  /// Decides which optional controls are buttons and which are menu
  /// items, for the width this frame was given.
  void _fitTrailingControls({
    required ResolvedVideoStyle st,
    required double iconSz,
    required double scale,
    required double barWidth,
    required double clockWidth,
  }) {
    _overflowActions.clear();
    _leftControls = const [];
    _rightControls = const [];
    final groups = _trailingGroups(st, iconSz);
    _pinned = _pinnedTrailing(st);
    if (groups.isEmpty) return;

    final size = _barIconSize(iconSz);
    final gap = VideoDefaults.controlGap * scale;
    final unit = size * VideoControlButton.bareFactor + gap;

    // A text control is as wide as its TEXT. Counting it as one
    // glyph-width overflowed the row the moment the speed read `1.25x`
    // instead of `1x`. Rounded UP: a slot too many costs a control, a
    // slot too few costs the layout.
    int slotsOf(_VideoBarControl g) =>
        g.text == null ? 1 : (_textControlWidth(g.text!, size) / unit).ceil();

    // The transport, plus the gap separating it from what follows.
    // `controlGap` is zero by design, so `unit` carries no spacing at
    // all — this is the only gap in the row, and leaving it out of the
    // budget offered a slot that was already spent.
    final barGap = VideoDefaults.barPaddingH * scale;
    final transportWidth = _inlineTransportSlots == 0
        ? 0.0
        : _inlineTransportSlots * unit + barGap;
    // A reserved control is not offered to the fit at all.
    final pinnedWidth = _pinned.length * unit;

    if (st.transportPlacement == VideoTransportPlacement.barCentered) {
      // Each SIDE is its own box, half the row wide. Fitting the whole
      // list against the whole row and then cutting it in two put more
      // into one half than that half could hold — which is the
      // six-pixel overflow that survived measuring the text, because
      // the width was never the problem: the SPLIT was.
      final budget = VideoBarBudget.splitCluster(
        barWidth: barWidth,
        transportWidth: transportWidth,
        pinnedWidth: pinnedWidth,
        clockWidth: clockWidth,
        clockGap: barGap,
      );
      final left = _fitInto(
        groups,
        budget: budget.left,
        unit: unit,
        slotsOf: slotsOf,
      );
      final rest = groups.where((g) => !left.contains(g)).toList();
      final right = _fitInto(
        rest,
        budget: budget.right,
        unit: unit,
        slotsOf: slotsOf,
      );
      _leftControls = left;
      _rightControls = right;
      _recordOverflow(groups, {...left, ...right});
      return;
    }

    final shown = _fitInto(
      groups,
      budget: VideoBarBudget.singleCluster(
        barWidth: barWidth,
        transportWidth: transportWidth,
        pinnedWidth: pinnedWidth,
        clockWidth: clockWidth,
      ).single,
      unit: unit,
      slotsOf: slotsOf,
    );
    // One cluster, at the end of the row.
    _rightControls = shown;
    _recordOverflow(groups, shown.toSet());
  }

  /// The controls from [groups] that fit in [budget].
  List<_VideoBarControl> _fitInto(
    List<_VideoBarControl> groups, {
    required double budget,
    required double unit,
    required int Function(_VideoBarControl) slotsOf,
  }) {
    final shown = barFit(
      budget: budget,
      slots: [for (final g in groups) slotsOf(g)],
      unit: unit,
    );
    return [for (final i in shown) groups[i]];
  }

  /// Everything that did not fit is reachable from the gear instead.
  void _recordOverflow(
    List<_VideoBarControl> groups,
    Set<_VideoBarControl> shown,
  ) {
    for (final g in groups) {
      if (!shown.contains(g) && g.onTap != null) {
        _overflowActions[g.value] = g.onTap!;
      }
    }
  }

  /// The row under the timeline.
  ///
  /// Three shapes, one for each transport placement. The clock leads
  /// whenever it lives here at all; what follows depends on where the
  /// transport is.
  Widget _controlRow(
    ResolvedVideoStyle st, {
    required double iconSz,
    required double playSz,
    required double scale,
    required double fontSize,
  }) {
    final clock = st.clockPlacement == VideoClockPlacement.below
        ? _clock(_elapsedAndTotal, st, fontSize)
        : null;
    final transport = _transportControls(
      st,
      iconSz: iconSz,
      playSz: playSz,
      scale: scale,
      compact: true,
      playLeads: st.transportPlacement == VideoTransportPlacement.bar,
    );
    final gap = SizedBox(width: VideoDefaults.barPaddingH * scale);

    switch (st.transportPlacement) {
      case VideoTransportPlacement.centered:
        return Row(
          children: [
            if (clock != null) clock,
            const Spacer(),
            ..._controlWidgets(
              [..._rightControls, ..._pinned],
              st,
              iconSz: iconSz,
              scale: scale,
            ),
          ],
        );

      case VideoTransportPlacement.bar:
        // The transport comes BEFORE the clock: it is what the reader
        // reaches for, and the clock is what they read.
        return Row(
          children: [
            ...transport,
            gap,
            if (clock != null) clock,
            const Spacer(),
            ..._controlWidgets(
              [..._rightControls, ..._pinned],
              st,
              iconSz: iconSz,
              scale: scale,
            ),
          ],
        );

      case VideoTransportPlacement.barCentered:
        // Already split by the FIT — each side was measured against
        // its own half of the row.
        //
        // Two EQUAL flex sides, not two `Spacer`s around the middle.
        // A spacer divides what is left over, so four controls on one
        // side and one on the other pushed the transport off centre —
        // it was centred in the gap rather than in the row. Equal flex
        // puts it in the middle of the bar whatever the sides hold.
        return Row(
          children: [
            Expanded(
              child: Row(
                children: [
                  if (clock != null) ...[clock, gap],
                  ..._controlWidgets(
                    _leftControls,
                    st,
                    iconSz: iconSz,
                    scale: scale,
                  ),
                ],
              ),
            ),
            ...transport,
            Expanded(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: _controlWidgets(
                  [..._rightControls, ..._pinned],
                  st,
                  iconSz: iconSz,
                  scale: scale,
                ),
              ),
            ),
          ],
        );
    }
  }

  /// Builds [controls] into a row's children, gaps and all.
  List<Widget> _controlWidgets(
    List<_VideoBarControl> controls,
    ResolvedVideoStyle st, {
    required double iconSz,
    required double scale,
  }) {
    final size = _barIconSize(iconSz);
    final out = <Widget>[];
    for (final g in controls) {
      if (out.isNotEmpty) {
        out.add(SizedBox(width: VideoDefaults.controlGap * scale));
      }
      out.add(
        g.text == null
            ? VideoControlButton(
                icon: g.icon,
                size: size,
                color: st.iconColor,
                label: g.label,
                onTap: g.onTap,
                compactTarget: true,
              )
            : VideoTextControl(
                text: g.text!,
                label: g.label,
                color: st.iconColor,
                fontSize: size * VideoDefaults.textControlFontFactor,
                onTap: g.onTap,
              ),
      );
    }
    return out;
  }

  /// How wide a `VideoTextControl` will be, including its padding.
  ///
  /// Measured for the same reason the clock is: `1x` and `1.25x` are
  /// not the same width, and a fit that assumes they are is a fit that
  /// overflows as soon as the value changes.
  double _textControlWidth(String text, double size) {
    final fontSize = size * VideoDefaults.textControlFontFactor;
    final painter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(fontSize: fontSize, fontWeight: FontWeight.w700),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    return painter.width + fontSize * 0.8;
  }

  /// How wide the clock actually is, rather than a guess.
  ///
  /// The trailing controls are fitted against what is left of the bar
  /// after it, and `0:15 / 2:30` and `1:02:15 / 2:14:30` are not the
  /// same width — a guess that suits one crowds the other.
  double _clockWidth(TextStyle style, String text) {
    final painter = TextPainter(
      // The SAME style the clock is DRAWN with, tabular figures
      // included. Measuring proportional digits and rendering tabular
      // ones under-counts by a few points in most faces — which is the
      // size of the overflow this kept producing.
      text: TextSpan(
        text: text,
        style: style.copyWith(
          fontFeatures: const [FontFeature.tabularFigures()],
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    return painter.width;
  }

  void _onAudioOutputChanged() {
    if (mounted) setState(() {});
  }

  void _reportNoAudio() {
    GlobalToast.i(VideoStrings.noAudioDevice);
    _showCtrls();
  }

  void _toggleMute() {
    // Optimistic for the same reason as `_togglePlay`.
    final target = _volume > 0 ? 0.0 : 100.0;
    setState(() => _volume = target);
    _safe(() => widget.player.setVolume(target));
    _showCtrls();
  }

  Future<void> _screenshot() async {
    await _safe(() async {
      final b = await widget.player.screenshot(format: 'image/png');
      if (b != null) widget.onScreenshot?.call(b);
    });
  }

  // ─── Double-tap ────────────────────────────────────────────

  // ─── Tap, timed by hand ────────────────────────────────────

  /// Where and when the last tap landed, for double-tap detection.
  Offset? _lastTapAt;
  DateTime? _lastTapTime;
  Offset? _downAt;
  DateTime? _downTime;

  /// The chrome toggles on the FIRST tap rather than waiting to see
  /// whether a second one is coming.
  ///
  /// `GestureDetector` cannot do this. A double-tap recogniser in the
  /// arena holds every single tap for `kDoubleTapTimeout` before it can
  /// win, so show/hide was 300ms late whenever double-tap seek was on —
  /// which felt like a tap being ignored, and the impatient second tap
  /// then became a double-tap and seeked instead.
  ///
  /// A `Listener` sees pointers without joining the arena, which is
  /// safe HERE and nowhere else: this layer sits UNDER the chrome, and
  /// a `Stack` stops hit-testing at the first child that reports a hit,
  /// so a pointer that lands on a control never reaches this at all.
  void _onPointerDown(PointerDownEvent e) {
    _downAt = e.localPosition;
    _downTime = DateTime.now();
  }

  void _onPointerUp(PointerUpEvent e, BoxConstraints c) {
    final downAt = _downAt;
    final downTime = _downTime;
    _downAt = null;
    _downTime = null;
    if (downAt == null || downTime == null) return;

    // A drag, a hold, or a gesture already claimed by something else is
    // not a tap. The recogniser did this for us; now we do it.
    if (_swiping || _hDragging || _dismissing || _lpActive) return;
    if ((e.localPosition - downAt).distance > kTouchSlop) return;
    final held = DateTime.now().difference(downTime);
    if (held > kLongPressTimeout) return;

    final now = DateTime.now();
    final last = _lastTapTime;
    final lastAt = _lastTapAt;
    final isSecond =
        _rs.enableDoubleTapSeek &&
        last != null &&
        lastAt != null &&
        now.difference(last) < kDoubleTapTimeout &&
        (e.localPosition - lastAt).distance < kDoubleTapSlop;

    if (isSecond) {
      _lastTapTime = null;
      _lastTapAt = null;
      _seekFromTap(e.localPosition, c);
      return;
    }

    _lastTapTime = now;
    _lastTapAt = e.localPosition;
    _toggleCtrls();
  }

  void _seekFromTap(Offset at, BoxConstraints c) {
    if (!_rs.enableDoubleTapSeek || !_alive) return;
    final left = at.dx < c.maxWidth / 2;
    final secs = _rs.doubleTapSeekDuration.inSeconds;
    setState(() {
      _dtSeekSecs = (left == _dtLeft && _dtSeekSecs != 0)
          ? _dtSeekSecs + (left ? -secs : secs)
          : (left ? -secs : secs);
      _dtLeft = left;
    });
    _seekBy(Duration(seconds: left ? -secs : secs));
    // The first tap of the pair already toggled the chrome. Seeking is
    // a thing worth seeing the result of, so it ends up shown either
    // way — which is what `_seekBy` does.
    _dtAnimCtrl.forward(from: 0);
    _dtResetTimer?.cancel();
    _dtResetTimer = Timer(VideoDefaults.doubleTapReset, () {
      if (mounted) setState(() => _dtSeekSecs = 0);
    });
  }

  // ─── Pan (direction-aware: vertical = brightness/volume, horizontal = seek) ──

  /// True while two fingers are on the picture.
  bool _pinching = false;

  void _onScaleStart(ScaleStartDetails d) {
    _pinching = d.pointerCount > 1 && widget.zoomController != null;
    if (_pinching) {
      _pinchStartScale = _currentZoom;
      return;
    }
    _panStart(const BoxConstraints());
  }

  double _pinchStartScale = 1;

  double get _currentZoom =>
      widget.zoomController?.value.getMaxScaleOnAxis() ?? 1;

  void _onScaleUpdate(ScaleUpdateDetails d, BoxConstraints c) {
    final zoom = widget.zoomController;
    if (_pinching && zoom != null) {
      final next = (_pinchStartScale * d.scale).clamp(
        1.0,
        VideoDefaults.maxZoom,
      );
      zoom.value = Matrix4.identity()
        ..translateByDouble(d.localFocalPoint.dx, d.localFocalPoint.dy, 0, 1)
        ..scaleByDouble(next, next, next, 1)
        ..translateByDouble(-d.localFocalPoint.dx, -d.localFocalPoint.dy, 0, 1);
      widget.onZoomScaleChanged?.call(next);
      return;
    }
    // A single finger on a ZOOMED picture moves the picture. Only
    // then: at 1x that drag is seek, volume and brightness, and taking
    // it for panning would trade three gestures for one.
    if (zoom != null && _currentZoom > 1.01) {
      zoom.value = zoom.value.clone()
        ..translateByDouble(d.focalPointDelta.dx, d.focalPointDelta.dy, 0, 1);
      return;
    }
    if (!_rs.enableSwipeGestures && !_rs.enableHorizontalDragSeek) return;
    _panUpdate(d.focalPointDelta, d.localFocalPoint, c);
  }

  void _onScaleEnd(ScaleEndDetails d) {
    if (_pinching) {
      _pinching = false;
      return;
    }
    // A scale gesture reports velocity as a scalar; the dismiss drag
    // wants the VERTICAL one, and `pointerCount` is gone by now, so
    // the sign comes from where the fingers were heading.
    _panEnd(dismissVelocity: d.velocity.pixelsPerSecond.dy);
  }

  void _panStart(BoxConstraints c) {
    _panDecided = false;
    _panIsHorizontal = false;
  }

  void _panUpdate(Offset delta, Offset localPosition, BoxConstraints c) {
    if (!_alive) return;

    // Decide direction on first significant movement
    if (!_panDecided) {
      final dx = delta.dx.abs();
      final dy = delta.dy.abs();
      // Below the slop the axis is a coin toss, and guessing wrong seeks
      // when the reader meant to change the volume.
      if (dx < VideoDefaults.dragAxisSlop && dy < VideoDefaults.dragAxisSlop) {
        return;
      }
      _panDecided = true;
      _panIsHorizontal = dx > dy;

      if (_panIsHorizontal && _rs.enableHorizontalDragSeek) {
        _hDragging = true;
        _hDragStartMs = _position.inMilliseconds.toDouble();
        _hDragCurrentMs = _hDragStartMs;
        _hideTimer?.cancel();
      } else if (!_panIsHorizontal) {
        // Vertical drag: center third = dismiss (in fullscreen), sides = brightness/volume
        final third = c.maxWidth / 3;
        final x = localPosition.dx;
        final isCenter = x > third && x < third * 2;

        if (isCenter && widget.onDismissDrag != null) {
          _dismissing = true;
          _dismissOffset = 0;
        } else if (_rs.enableSwipeGestures) {
          final isVolume = x > c.maxWidth / 2;
          // Same guard the mute button carries. Without it the bar
          // moved, the percentage counted and nothing changed — which
          // is worse than saying so, and the button already says so.
          if (isVolume && _noAudioDevice) {
            _reportNoAudio();
          } else {
            _swiping = true;
            _swipeIsVol = isVolume;
            _swipeVal = isVolume ? _volume : _brightness * 100;
          }
        }
      }
      return;
    }

    // Horizontal drag seek
    if (_panIsHorizontal && _hDragging) {
      final totalMs = _duration.inMilliseconds.toDouble();
      if (totalMs <= 0) return;
      final seekDelta = delta.dx / c.maxWidth * totalMs;
      setState(() {
        _hDragCurrentMs = (_hDragCurrentMs + seekDelta).clamp(0.0, totalMs);
      });
      if (_rs.enableThumbnailPreview) _requestThumb(_hDragCurrentMs);
      _liveScrub(_hDragCurrentMs);
      return;
    }

    // Dismiss drag
    if (_dismissing) {
      _dismissOffset += delta.dy;
      widget.onDismissDrag?.call(_dismissOffset);
      return;
    }

    // Vertical swipe (brightness / volume)
    if (!_panIsHorizontal && _swiping) {
      final step = -delta.dy / c.maxHeight * 150;
      setState(() => _swipeVal = (_swipeVal + step).clamp(0.0, 100.0));
      if (_swipeIsVol) {
        _safe(() => widget.player.setVolume(_swipeVal));
      } else {
        _brightness = _swipeVal / 100;
        try {
          ScreenBrightness.instance.setApplicationScreenBrightness(_brightness);
        } catch (_) {}
      }
    }
  }

  /// Moves the PICTURE while a scrub is in progress, on a leash.
  ///
  /// The badge and the thumbnail plate both said where the drag would
  /// land, and the film behind them stayed on the frame it started on —
  /// so the one thing actually being scrubbed was the only thing not
  /// showing it. The exact seek still fires on release; this is the
  /// preview.
  void _liveScrub(double ms) {
    if (_liveScrubTimer != null) return;
    _safe(() => widget.player.seek(Duration(milliseconds: ms.toInt())));
    _liveScrubTimer = Timer(VideoDefaults.liveScrubInterval, () {
      _liveScrubTimer = null;
    });
  }

  Timer? _liveScrubTimer;

  void _panEnd({double dismissVelocity = 0}) {
    if (_hDragging) {
      _safe(
        () =>
            widget.player.seek(Duration(milliseconds: _hDragCurrentMs.toInt())),
      );
      setState(() => _hDragging = false);
      _thumbDebounce?.cancel();
      _thumbDebounce = null;
      _showThumb = false;
      _thumbBytes = null;
      _startHide();
    }
    if (_dismissing) {
      _dismissing = false;
      widget.onDismissDragEnd?.call(dismissVelocity);
    }
    if (_swiping) setState(() => _swiping = false);
    _panDecided = false;
  }

  // ─── Long-press ────────────────────────────────────────────

  void _lpStart() {
    if (!_rs.enableLongPressSpeed || !_alive || !_playing) return;
    _lpOrigRate = _rate;
    _lpActive = true;
    _safe(() => widget.player.setRate(_rs.longPressSpeedRate));
    setState(() {});
  }

  void _lpEnd() {
    if (!_lpActive) return;
    _safe(() => widget.player.setRate(_lpOrigRate));
    _lpActive = false;
    setState(() {});
  }

  // ─── Thumbnail ─────────────────────────────────────────────

  void _requestThumb(double ms) {
    if (!_rs.enableThumbnailPreview || !_alive) return;
    final sec = (ms / 1000).round();
    setState(() {
      _thumbMs = ms;
      _showThumb = true;
    });

    // Use cached frame if available
    if (_thumbCache.containsKey(sec)) {
      setState(() => _thumbBytes = _thumbCache[sec]);
      return;
    }

    _thumbDebounce?.cancel();
    _thumbDebounce = Timer(VideoDefaults.thumbnailDebounce, () async {
      if (!mounted) return;
      try {
        if (!_alive) return;
        final bytes = await widget.player.screenshot(format: 'image/jpeg');
        if (bytes != null && mounted) {
          // Evict oldest entries if cache is full
          while (_thumbCache.length >= _maxThumbCacheSize) {
            _thumbCache.remove(_thumbCache.keys.first);
          }
          _thumbCache[sec] = bytes;
          setState(() => _thumbBytes = bytes);
        }
      } catch (_) {}
    });
  }

  // ─── Build ─────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) => VideoShortcuts(
    enabled: _rs.enableKeyboardShortcuts,
    // Fullscreen takes focus on arrival: it IS the page, so there is
    // nothing else the keys could be meant for.
    autofocus: widget.isFullscreen,
    onCommand: _runCommand,
    child: _buildControls(context),
  );

  void _runCommand(VideoCommand command) {
    if (!_alive) return;
    // Every one of these is something a control does, so the chrome
    // comes back to show it happened — a key press with no visible
    // result reads as a key that did nothing.
    _showCtrls();
    switch (command) {
      case VideoCommand.playPause:
        _togglePlay();
      case VideoCommand.seekBack:
        _seekBy(-_rs.seekDuration);
      case VideoCommand.seekForward:
        _seekBy(_rs.seekDuration);
      case VideoCommand.volumeUp:
        _nudgeVolume(VideoDefaults.keyboardVolumeStep);
      case VideoCommand.volumeDown:
        _nudgeVolume(-VideoDefaults.keyboardVolumeStep);
      case VideoCommand.mute:
        if (_noAudioDevice) {
          _reportNoAudio();
        } else {
          _toggleMute();
        }
      case VideoCommand.fullscreen:
        widget.onFullscreenToggle?.call();
      case VideoCommand.exitFullscreen:
        if (widget.isFullscreen) widget.onFullscreenToggle?.call();
    }
  }

  /// Steps to the next speed and WRAPS.
  ///
  /// A cycler is only worth having if it comes back — a control that
  /// stops at 2x strands anyone who overshoots, and the way back is
  /// then the menu they were avoiding. The list is the same
  /// `_rs.speeds` the menu offers, so the two can never disagree.
  void _cycleSpeed() {
    final speeds = _rs.speeds;
    if (speeds.isEmpty) return;
    final current = speeds.indexWhere((s) => s.rate == _rate);
    final next = speeds[(current + 1) % speeds.length];
    setState(() => _rate = next.rate);
    _safe(() => widget.player.setRate(next.rate));
    _showCtrls();
  }

  /// How the cycler LABELS the speed it is on.
  ///
  /// The bag's own label when there is one — an app that calls it
  /// "Normal" should not be overruled — and `1.5x` when there is not.
  String get _speedLabel {
    for (final s in _rs.speeds) {
      if (s.rate == _rate) return s.label;
    }
    return '${_rate}x';
  }

  void _nudgeVolume(double by) {
    if (_noAudioDevice) {
      _reportNoAudio();
      return;
    }
    final next = (_volume + by).clamp(0.0, 100.0);
    setState(() => _volume = next);
    _safe(() => widget.player.setVolume(next));
  }

  Widget _buildControls(BuildContext context) {
    final st = _rs;
    final primary = st.activeColor;

    return LayoutBuilder(
      builder: (context, c) {
        // Scale factor: 1.0 at 220px height, scales proportionally for smaller/larger players
        final scale = ResolvedVideoStyle.scaleFor(c.maxHeight);
        // In fullscreen immersive mode, padding is zeroed. Use viewPadding which always reflects physical insets.
        final safePad = widget.isFullscreen
            ? MediaQuery.of(context).viewPadding
            : EdgeInsets.zero;
        final iconSz = st.iconSize * scale;
        final playSz = st.playIconSize * scale;
        final fontSize = VideoDefaults.timeLabelFontSize * scale;

        // What the top bar occupies, for anything that has to sit clear
        // of it.
        final topBarHeight =
            safePad.top +
            VideoDefaults.barPaddingV * 2 * scale +
            (iconSz - 6) * VideoControlButton.bareFactor;

        // Before either bar is built — see `_barControls`.
        _fitTrailingControls(
          st: st,
          iconSz: iconSz,
          scale: scale,
          barWidth:
              c.maxWidth -
              safePad.left -
              safePad.right -
              VideoDefaults.barPaddingH * 2 * scale,
          // Only when the clock is actually IN the control row. Any
          // other placement puts it on the timeline's row, where it
          // costs the controls nothing.
          clockWidth: st.clockPlacement == VideoClockPlacement.below
              ? _clockWidth(
                  st.timeLabelStyle ??
                      TextStyle(
                        color: st.iconColor.withValues(
                          alpha: VideoDefaults.timeLabelOpacity,
                        ),
                        fontSize: fontSize,
                      ),
                  _elapsedAndTotal,
                )
              : 0,
        );

        // The film's gestures sit BEHIND the chrome, not around it.
        //
        // Wrapping the whole stack put the player's double-tap recogniser
        // in the same arena as every button inside it. A tap resolves at
        // pointer-UP, a double-tap resolves on the second pointer-DOWN —
        // so tapping play twice quickly let the double-tap win the second
        // one and seek ten seconds instead. Reported exactly that way.
        //
        // As a sibling underneath, a control that is hit absorbs the
        // pointer and the layer below is never in the arena at all. When
        // the chrome is hidden its `IgnorePointer` lets everything
        // through, which is what makes tap-to-show still work.
        return Stack(
          children: [
            Positioned.fill(
              child: Listener(
                // Taps are timed by hand — see `_onPointerUp`. The
                // detector below keeps the gestures that DO need an
                // arena: a pan and a long press have to be able to win
                // one against a scrolling page.
                onPointerDown: _onPointerDown,
                onPointerUp: (e) => _onPointerUp(e, c),
                child: GestureDetector(
                  // SCALE, not pan. Flutter refuses both on one
                  // detector, and this layer is opaque and sits above
                  // the picture — so an `InteractiveViewer` underneath
                  // never saw a pinch at all, which is why zoom did
                  // nothing. One recogniser owns every finger here and
                  // decides what the gesture is.
                  onScaleStart: _onScaleStart,
                  onScaleUpdate: (d) => _onScaleUpdate(d, c),
                  onScaleEnd: _onScaleEnd,
                  onLongPressStart: _rs.enableLongPressSpeed
                      ? (_) => _lpStart()
                      : null,
                  onLongPressEnd: _rs.enableLongPressSpeed
                      ? (_) => _lpEnd()
                      : null,
                  behavior: HitTestBehavior.opaque,
                ),
              ),
            ),
            Stack(
              children: [
                if (_buffering)
                  Center(
                    child: SizedBox(
                      width: VideoDefaults.bufferingSize * scale,
                      height: VideoDefaults.bufferingSize * scale,
                      child: GlobalProgress.loading(
                        type: ProgressType.circular,
                        style: ProgressStyle(
                          color: st.iconColor,
                          thickness: 2.5,
                        ),
                      ),
                    ),
                  ),

                // Subtitle when hidden
                if (_subtitle.isNotEmpty && !_visible)
                  Positioned(
                    bottom: VideoDefaults.barPaddingV * scale,
                    left: VideoDefaults.barPaddingH * scale,
                    right: VideoDefaults.barPaddingH * scale,
                    child: Center(
                      child: _subtitlePlate(st, context, scale),
                    ),
                  ),

                // Double-tap ripple
                if (_dtSeekSecs != 0)
                  VideoSeekRipple(
                    animation: _dtAnim,
                    seconds: _dtSeekSecs,
                    isLeft: _dtLeft,
                    style: st,
                    scale: scale,
                    width: c.maxWidth,
                  ),

                // Long-press speed
                if (_lpActive)
                  VideoSpeedBadge(
                    rate: _rs.longPressSpeedRate,
                    style: st,
                    scale: scale,
                    // Clear of the top bar when the top bar is there.
                    top: _visible
                        ? topBarHeight + VideoDefaults.barPaddingV * scale
                        : VideoDefaults.barPaddingV * scale + safePad.top,
                  ),

                // Vertical swipe: volume or brightness
                if (_swiping)
                  VideoLevelBadge(
                    isVolume: _swipeIsVol,
                    value: _swipeVal,
                    style: st,
                    scale: scale,
                    height: c.maxHeight,
                    safePadding: safePad,
                  ),

                // Horizontal drag seek
                if (_hDragging)
                  VideoSeekBadge(
                    startMs: _hDragStartMs,
                    currentMs: _hDragCurrentMs,
                    style: st,
                    scale: scale,
                  ),

                // Controls overlay
                AnimatedOpacity(
                  opacity: _visible ? 1.0 : 0.0,
                  duration: _visible
                      ? st.fadeIn(reduceMotion: _reduceMotion)
                      : st.fadeOut(reduceMotion: _reduceMotion),
                  child: IgnorePointer(
                    ignoring: !_visible,
                    child: Stack(
                      children: [
                        // The scrims are DECORATION, and a decorated
                        // box takes the pointer. Measured: a tap on the
                        // top strip never reached the film layer, so a
                        // swipe or a hold that began anywhere near an
                        // edge did nothing while the chrome was up —
                        // reported exactly that way. Only CONTROLS may
                        // absorb.
                        Positioned(
                          top: 0,
                          left: 0,
                          right: 0,
                          // `Positioned` must stay the Stack's direct
                          // child — it is parent data for the stack, so
                          // the ignore goes INSIDE it.
                          child: IgnorePointer(
                            child: Container(
                              height: st.gradientHeight * scale,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [st.scrimColor, Colors.transparent],
                                ),
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          bottom: 0,
                          left: 0,
                          right: 0,
                          // `Positioned` must stay the Stack's direct
                          // child — it is parent data for the stack, so
                          // the ignore goes INSIDE it.
                          child: IgnorePointer(
                            child: Container(
                              height: st.gradientHeight * scale,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.bottomCenter,
                                  end: Alignment.topCenter,
                                  colors: [st.scrimColor, Colors.transparent],
                                ),
                              ),
                            ),
                          ),
                        ),

                        // Top bar
                        if (widget.customTopBar != null)
                          Positioned(
                            top: 0,
                            left: 0,
                            right: 0,
                            child: widget.customTopBar!,
                          )
                        else
                          Positioned(
                            top: 0,
                            left: 0,
                            right: 0,
                            child: Padding(
                              // The GRADIENT still reaches the edge; only the
                              // CONTENT sits inside the inset. That is the rule the
                              // rest of the app follows, and in immersive fullscreen
                              // `viewPadding` is the one that still reports the
                              // housing — `padding` is zeroed there.
                              //
                              // `MyApp` has already un-mirrored the landscape notch,
                              // so this is the real side rather than 62 points given
                              // up on both.
                              padding: EdgeInsets.only(
                                left:
                                    VideoDefaults.barPaddingH * scale +
                                    safePad.left,
                                right:
                                    VideoDefaults.barPaddingH * scale +
                                    safePad.right,
                                top:
                                    VideoDefaults.barPaddingV * scale +
                                    safePad.top,
                                bottom: VideoDefaults.barPaddingV * scale,
                              ),
                              child: Row(
                                children: [
                                  if (widget.title != null)
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            widget.title!,
                                            style:
                                                st.titleStyle ??
                                                TextStyle(
                                                  color: st.iconColor,
                                                  fontSize:
                                                      (context
                                                              .textTheme
                                                              .bodyMedium
                                                              ?.fontSize ??
                                                          14) *
                                                      scale,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          // Where the reader IS, under
                                          // what they are watching. A
                                          // chaptered film that never
                                          // says which chapter is on
                                          // has marked its timeline for
                                          // nothing.
                                          if (_currentChapter != null)
                                            Text(
                                              _currentChapter!.title,
                                              style: TextStyle(
                                                color: st.iconColor.withValues(
                                                  alpha: VideoDefaults
                                                      .timeLabelOpacity,
                                                ),
                                                fontSize: fontSize,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                        ],
                                      ),
                                    ),
                                  const Spacer(),
                                  if (_rs.showTrackSelector ||
                                      _rs.showSpeedButton) ...[
                                    SizedBox(
                                      width: VideoDefaults.controlGap * scale,
                                    ),
                                    _settingsMenu(st, iconSz),
                                  ],
                                ],
                              ),
                            ),
                          ),

                        // The transport, unless it has moved into
                        // the bar. It is NOT part of `_barControls`:
                        // those fold into the menu when the bar runs
                        // out of room, and play is not a control
                        // anyone should have to open a menu for.
                        if (st.transportPlacement ==
                            VideoTransportPlacement.centered)
                          Center(
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: _transportControls(
                                st,
                                iconSz: iconSz,
                                playSz: playSz,
                                scale: scale,
                              ),
                            ),
                          ),

                        // Bottom bar
                        if (widget.customBottomBar != null)
                          Positioned(
                            bottom: 0,
                            left: 0,
                            right: 0,
                            child: widget.customBottomBar!,
                          )
                        else
                          Positioned(
                            bottom: 0,
                            left: 0,
                            right: 0,
                            child: Padding(
                              padding: EdgeInsets.only(
                                left:
                                    VideoDefaults.barPaddingH * scale +
                                    safePad.left,
                                right:
                                    VideoDefaults.barPaddingH * scale +
                                    safePad.right,
                                top: VideoDefaults.barPaddingV * scale,
                                bottom:
                                    VideoDefaults.barPaddingV * scale +
                                    safePad.bottom,
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (_subtitle.isNotEmpty) ...[
                                    Center(
                                      child: _subtitlePlate(
                                        st,
                                        context,
                                        scale,
                                      ),
                                    ),
                                    SizedBox(
                                      height:
                                          VideoDefaults.barSubtitleGap * scale,
                                    ),
                                  ],
                                  ..._timelineRow(
                                    st,
                                    primary: primary,
                                    scale: scale,
                                    fontSize: fontSize,
                                  ),
                                  SizedBox(
                                    height: VideoDefaults.barRowGap * scale,
                                  ),
                                  _controlRow(
                                    st,
                                    iconSz: iconSz,
                                    playSz: playSz,
                                    scale: scale,
                                    fontSize: fontSize,
                                  ),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),

                // Up next — over the chrome, because it is the thing
                // being asked about and the bars are behind it.
                if (_autoNextIn != null)
                  VideoUpNextCard(
                    secondsLeft: _autoNextIn!,
                    style: st,
                    scale: scale,
                    onPlayNow: () {
                      _cancelAutoPlayNext();
                      widget.onNext?.call();
                    },
                    onCancel: _cancelAutoPlayNext,
                  ),

                // Scrub preview.
                //
                // AFTER the chrome, so it paints on top of it. As a
                // sibling before, it was drawn UNDER the bottom bar —
                // the thing it is a preview of.
                if (_showThumb && (_dragging || _hDragging))
                  VideoThumbnailPreview(
                    bytes: _thumbBytes,
                    thumbnailMs: _thumbMs,
                    seekMs: _hDragging ? _hDragCurrentMs : _dragValue,
                    duration: _duration,
                    style: st,
                    scale: scale,
                    width: c.maxWidth,
                    barPadding: EdgeInsets.only(
                      left: VideoDefaults.barPaddingH * scale + safePad.left,
                      right: VideoDefaults.barPaddingH * scale + safePad.right,
                      bottom:
                          VideoDefaults.thumbnailBottomGap * scale +
                          safePad.bottom,
                    ),
                  ),
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _buildSeekBar(Color primary, ResolvedVideoStyle st, double scale) =>
      VideoSeekBar(
        chapters: widget.chapters,
        loopStart: _loopA,
        loopEnd: _loopB,
        position: _dragging
            ? Duration(milliseconds: _dragValue.toInt())
            : _position,
        duration: _duration,
        buffered: _buffered,
        style: st,
        scale: scale,
        dragging: _dragging,
        onChangeStart: (v) {
          _dragging = true;
          _dragValue = v;
          _hideTimer?.cancel();
          if (_rs.enableThumbnailPreview) _requestThumb(v);
        },
        onChanged: (v) {
          setState(() => _dragValue = v);
          if (_rs.enableThumbnailPreview) _requestThumb(v);
        },
        onChangeEnd: (v) {
          _thumbDebounce?.cancel();
          _thumbDebounce = null;
          _dragging = false;
          _showThumb = false;
          _thumbBytes = null;
          _safe(() => widget.player.seek(Duration(milliseconds: v.toInt())));
          _startHide();
        },
      );

  /// The settings menu, built by the POPUP engine rather than by hand.
  ///
  /// It used to call `GlobalPopup.showAt` with a `GlobalPopupLayout`
  /// fabricated on the spot — `isAbove: false`, `isFlipping: false`,
  /// `anchorSize: Size.zero` — which is the engine's job, and saying it
  /// by hand is saying it wrong. A menu that can never flip runs off
  /// the bottom of a player near the foot of the page, and one told its
  /// anchor is a zero-sized point cannot line up with the button it
  /// belongs to.
  ///
  /// `GlobalPopup.menu` takes the anchor as a WIDGET and computes the
  /// layout, so flipping, edge-clamping and content sizing all come for
  /// free — and the menu matches every other popup in the app.
  Widget _settingsMenu(ResolvedVideoStyle st, double iconSz) {
    final items = _settingsItems();
    return GlobalPopup.menu<String>(
      // The bar must not hide out from under the menu. It does not
      // fade WITH it — the popup renders in the overlay, measured — but
      // when the bar went, the tap that brought it back landed OUTSIDE
      // the menu and dismissed it, which looks exactly like a menu that
      // closed itself.
      onOpen: () {
        _menuOpen = true;
        _hideTimer?.cancel();
        if (!_visible) setState(() => _visible = true);
      },
      onClose: () {
        _menuOpen = false;
        _showCtrls();
      },
      // The popup owns the gesture, so the glyph carries no `onTap` —
      // but it must still look live.
      anchor: VideoControlButton(
        icon: st.settingsIcon,
        size: iconSz - 4,
        color: st.iconColor,
        label: VideoStrings.settings,
        enabled: items.isNotEmpty,
        compactTarget: true,
        // The popup opens this by itself — measured, a button with its
        // own callback does not swallow the gesture. It carries one
        // anyway because a `GlobalIconButton` with no `onPressed` draws
        // itself as DISABLED, which is what put a dull ring round the
        // gear, and keeping the bar up is a true thing for it to do.
        onTap: _showCtrls,
      ),
      enabled: items.isNotEmpty,
      items: items,
      onSelected: _applySetting,
      options: VideoDefaults.settingsMenu,
    );
  }

  /// What the menu offers: the controls that did not fit on the bar,
  /// then the track's own settings.
  ///
  /// Controls lead because they are ACTIONS and the rest are choices —
  /// and because a control that has just left the bar is the thing the
  /// reader was looking for.
  List<GlobalPopupMenuItem<String>> _settingsItems() {
    final groups = _trailingGroups(_rs, _rs.iconSize);
    final overflowed = [
      for (final g in groups)
        if (_overflowActions.containsKey(g.value))
          GlobalPopupMenuItem<String>(
            value: g.value,
            label: g.label,
            icon: g.icon,
          ),
    ];
    // Things that are only ever a menu — a list of chapters or a set of
    // durations is not a glyph, and putting it on the bar would mean
    // inventing one.
    final sections = [
      ..._chapterItems(),
      ..._sleepTimerItems(),
      ..._subtitleSizeItems(),
      ..._subtitleOffsetItems(),
      ..._trackSettingsItems(),
    ];
    if (overflowed.isEmpty) return sections;
    return [
      ...overflowed,
      if (sections.isNotEmpty) GlobalPopupMenuItem<String>.divider(),
      ...sections,
    ];
  }

  List<GlobalPopupMenuItem<String>> _chapterItems() =>
      !_rs.showChapterList || widget.chapters.isEmpty
      ? const []
      : VideoSettings.chapterItems(
          chapters: widget.chapters,
          current: _currentChapter,
        );

  List<GlobalPopupMenuItem<String>> _sleepTimerItems() => !_rs.showSleepTimer
      ? const []
      : VideoSettings.sleepTimerItems(
          running: _sleepTimer != null || _sleepAtEnd,
          atEnd: _sleepAtEnd,
        );

  List<GlobalPopupMenuItem<String>> _subtitleSizeItems() =>
      !_rs.showSubtitleOffset || _realSubtitleTracks.isEmpty
      ? const []
      : VideoSettings.subtitleSizeItems(scale: _subtitleScale);

  List<GlobalPopupMenuItem<String>> _subtitleOffsetItems() =>
      !_rs.showSubtitleOffset || _realSubtitleTracks.isEmpty
      ? const []
      : VideoSettings.subtitleOffsetItems(offset: _subtitleOffset);

  List<GlobalPopupMenuItem<String>> _trackSettingsItems() =>
      VideoSettings.itemsFor(
        showSpeedButton: _rs.showSpeedButton,
        showTrackSelector: _rs.showTrackSelector,
        speeds: _rs.speeds,
        rate: _rate,
        audioTracks: _audioTracks,
        subtitleTracks: _subtitleTracks,
        videoTracks: _videoTracks,
        currentAudioTrack: _currentAudioTrack,
        currentSubtitleTrack: _currentSubtitleTrack,
        currentVideoTrack: _currentVideoTrack,
      );

  void _applySetting(String v) {
    if (!_alive) return;
    // A control that overflowed off the bar, rather than a setting.
    final control = _overflowActions[v];
    if (control != null) {
      control();
      return;
    }
    if (v.startsWith('chap_')) {
      final i = int.tryParse(v.substring(5));
      if (i != null && i < widget.chapters.length) {
        _safe(() => widget.player.seek(widget.chapters[i].start));
      }
      return;
    }
    if (v == 'sleep_off') {
      _setSleepTimer(null);
      return;
    }
    if (v == 'sleep_end') {
      _setSleepTimer(null, atEnd: true);
      return;
    }
    if (v.startsWith('sleep_')) {
      _setSleepTimer(int.tryParse(v.substring(6)));
      return;
    }
    if (v.startsWith(VideoSettings.subtitleSizePrefix)) {
      final dir = v.substring(VideoSettings.subtitleSizePrefix.length);
      _nudgeSubtitleSize(
        dir == '0'
            ? 0
            : (dir == '+' ? 1 : -1) * VideoDefaults.subtitleScaleStep,
      );
      return;
    }
    if (v == 'suboff_0') {
      _nudgeSubtitles(Duration.zero);
      return;
    }
    if (v == 'suboff_-') {
      _nudgeSubtitles(-VideoDefaults.subtitleOffsetStep);
      return;
    }
    if (v == 'suboff_+') {
      _nudgeSubtitles(VideoDefaults.subtitleOffsetStep);
      return;
    }
    VideoSettings.apply(
      v,
      player: widget.player,
      audioTracks: _audioTracks,
      subtitleTracks: _subtitleTracks,
      videoTracks: _videoTracks,
      run: _safe,
    );
  }
}
