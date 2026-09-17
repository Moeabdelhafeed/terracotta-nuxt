import 'package:flutter/material.dart';

import '../../../core/animations/animation_presets.dart';
import '../popup/popup.dart';

/// Source type for [GlobalVideo].
enum VideoSourceType { network, asset, file }

/// A playback speed the settings sheet can offer.
@immutable
/// A clock for the player: `2:05`, or `1:02:05` past an hour.
///
/// Hours appear only when there ARE hours — a two-minute clip reading
/// `0:02:05` is noise, and every player in the world drops it.
///
/// Shared by the seek badge, the thumbnail plate and the bottom bar's
/// clocks. It was a private method on the controls' state, which put it
/// out of reach of the widgets that were lifted out of that state.
String formatVideoDuration(Duration d) {
  final hours = d.inHours;
  final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
  final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
  return hours > 0 ? '$hours:$minutes:$seconds' : '$minutes:$seconds';
}

/// A named point in a film.
///
/// Chapters are a property of the CONTENT, so they are on the widget
/// beside the source rather than in the style bag — a theme cannot
/// know where the second act starts.
@immutable
class VideoChapter {
  const VideoChapter({required this.start, required this.title});

  /// Where it begins. The chapter runs until the next one starts, or
  /// until the end of the film.
  final Duration start;

  final String title;

  /// Where this sits on a timeline of [duration], as 0..1.
  ///
  /// Zero when the duration is unknown — mpv reports it a beat after
  /// the file opens, and a marker placed against a zero-length film
  /// would divide by it.
  double fractionOf(Duration duration) {
    final total = duration.inMilliseconds;
    if (total <= 0) return 0;
    return (start.inMilliseconds / total).clamp(0.0, 1.0);
  }

  /// The chapter covering [position], or null when there are none or
  /// the position falls before the first one starts.
  static VideoChapter? at(Duration position, List<VideoChapter> chapters) {
    VideoChapter? found;
    for (final c in chapters) {
      if (c.start > position) break;
      found = c;
    }
    return found;
  }
}

/// Where the transport — play, seek, previous / next — lives.
enum VideoTransportPlacement {
  /// Big, in the middle of the film. The standard mobile shape, and
  /// the one that survives a small player: a 48dp play button in the
  /// centre is the easiest target on screen.
  centered,

  /// In the bottom bar, before the clock. Reads like a desktop player,
  /// and leaves the film itself uncovered.
  ///
  /// The transport still does NOT fold into the overflow menu. Play is
  /// not a control anyone should have to open a menu for.
  bar,

  /// In the bottom bar, CENTRED, with the other controls spread to
  /// either side of it.
  ///
  /// The shape a music player uses: the thing you press most is in the
  /// middle of the row, where it can be found without looking, and
  /// everything else is pushed to the edges. Costs the same height as
  /// [bar] and reads as more deliberate on a wide player.
  barCentered,
}

/// Where the clock sits relative to the timeline.
enum VideoClockPlacement {
  /// Under the timeline, at the start of the control row.
  below,

  /// On the same row, before the timeline.
  beforeTimeline,

  /// On the same row, after the timeline.
  afterTimeline,

  /// Split across the row: position where the film began, duration
  /// where it ends. The shape every desktop player uses, and the one
  /// that makes a wide timeline readable — the two numbers sit at the
  /// ends they describe.
  split,
}

class PlaybackSpeed {
  const PlaybackSpeed(this.label, this.rate);

  final String label;
  final double rate;

  static const List<PlaybackSpeed> defaults = [
    PlaybackSpeed('0.25x', 0.25),
    PlaybackSpeed('0.5x', 0.5),
    PlaybackSpeed('0.75x', 0.75),
    PlaybackSpeed('1x', 1),
    PlaybackSpeed('1.25x', 1.25),
    PlaybackSpeed('1.5x', 1.5),
    PlaybackSpeed('2x', 2),
  ];
}

/// External subtitle or audio track.
@immutable
class SubtitleConfig {
  const SubtitleConfig({this.uri, this.data, this.title, this.language});

  final String? uri;
  final String? data;
  final String? title;
  final String? language;
}

/// Every hard-coded number the player uses.
///
/// The floor for [VideoStyle], and the one place to change a size
/// rather than hunting forty call sites for `28`.
abstract final class VideoDefaults {
  // ─── Frame ────────────────────────────────────────────────
  static const aspectRatio = 16 / 9;

  /// Used only when neither the caller nor the theme names a radius.
  static const fallbackRadius = 12.0;

  /// How much of the player has to be on screen before it counts as
  /// visible. Below it, `pauseOnOffscreen` and `pipOnOffscreen` fire.
  static const offscreenFraction = 0.3;

  // ─── Glyphs ───────────────────────────────────────────────
  static const iconSize = 28.0;
  static const playIconSize = 44.0;

  // ─── Seek bar ─────────────────────────────────────────────
  static const progressBarHeight = 4.0;
  static const thumbRadius = 7.0;

  // ─── Chrome ───────────────────────────────────────────────
  static const gradientHeight = 120.0;
  static const bottomBarPadding = EdgeInsets.symmetric(
    horizontal: 16,
    vertical: 8,
  );
  static const topBarPadding = EdgeInsets.symmetric(
    horizontal: 16,
    vertical: 12,
  );
  static const subtitlePadding = EdgeInsets.symmetric(
    horizontal: 16,
    vertical: 8,
  );

  /// The subtitle plate's corner. It was a bare `4` written twice.
  static const subtitleRadius = 4.0;

  /// How far the film must move before the position is reported again.
  static const positionReportInterval = Duration(seconds: 5);

  /// The GAP between two chapters on the timeline.
  ///
  /// Wide enough to read as a seam rather than a scratch: at two points
  /// the track looked like it had a rendering fault, not like it was
  /// divided. YouTube's is about this.
  static const chapterGap = 4.0;

  /// How long the next item in a playlist waits before playing itself.
  static const autoPlayNextDelay = Duration(seconds: 5);

  /// How far the picture can be pinched in.
  static const maxZoom = 4.0;

  /// What the sleep timer offers, in minutes. The last entry is
  /// "the end of this video", which is not a duration.
  static const sleepTimerMinutes = [15, 30, 45, 60];

  /// What "smaller" and "larger" do to the subtitle plate, and how far
  /// either can go. A reader who cannot read them is the reason this
  /// exists; a reader who covers the film with them is the reason it
  /// stops.
  static const subtitleScaleStep = 0.15;
  static const subtitleScaleMin = 0.7;
  static const subtitleScaleMax = 2.0;

  /// How far one press nudges the subtitles.
  static const subtitleOffsetStep = Duration(milliseconds: 500);

  /// The badges' shared rhythm.
  ///
  /// Only the numbers that REPEAT across badges are named. A one-off —
  /// the ripple's 24pt glyph, the level column's 36pt width — says
  /// what it is where it is used, and naming it would add a constant
  /// nobody else can reuse. These three are the ones that drifted:
  /// four separate `4 * scale`s, three `10 * scale`s and two
  /// `6 * scale`s across three badges that are meant to look related.
  static const badgePaddingH = 10.0;
  static const badgePaddingV = 4.0;
  static const badgeGap = 6.0;

  /// A text control's type size, against the glyph size beside it —
  /// `1.5x` has to read as the same weight as the icons it sits with.
  static const textControlFontFactor = 0.62;

  /// How much one arrow-key press moves the volume.
  static const keyboardVolumeStep = 5.0;

  /// How often a horizontal scrub moves the PICTURE, not just the
  /// badge.
  ///
  /// Seeking on every pixel of a drag is a decode per frame of finger
  /// movement, which stalls a network stream. Seeking only on release
  /// left the film frozen while the reader guessed from a clock. This
  /// is the cadence between: often enough to read as scrubbing, rare
  /// enough that mpv keeps up.
  static const liveScrubInterval = Duration(milliseconds: 180);

  /// The clock under the timeline, when the theme names no style.
  static const timeLabelFontSize = 12.0;

  // ─── Timing ───────────────────────────────────────────────
  static const autoHideDelay = Duration(seconds: 3);
  static const seekDuration = Duration(seconds: 10);
  static const doubleTapSeekDuration = Duration(seconds: 10);
  static const longPressSpeedRate = 2.0;

  /// How long a double-tap ripple and its counter stay up.
  static const doubleTapFlash = Duration(milliseconds: 500);
  static const doubleTapReset = Duration(milliseconds: 800);

  /// A scrub preview is a network round trip per frame — it waits for
  /// the finger to settle rather than firing on every pixel.
  static const thumbnailDebounce = Duration(milliseconds: 300);

  // ─── Overlay geometry ─────────────────────────────────────
  /// Controls are sized against a reference height, so a player in a
  /// list cell and a fullscreen one are not handed the same 28pt icon.
  static const scaleReferenceHeight = 220.0;
  static const scaleMin = 0.8;
  static const scaleMax = 1.5;

  static const badgeRadius = 8.0;
  static const seekBadgeRadius = 10.0;
  static const speedBadgeRadius = 14.0;
  static const thumbnailRadius = 6.0;

  /// The bar rhythm — ONE inset, top and bottom, so the title, the
  /// timeline, the clock and the controls all start on the same line.
  ///
  /// They were seven separate literals (`12`, `8`, `6`, `2`, …) spread
  /// through `build`, which is how the timeline ended up indented from
  /// the clock beneath it.
  static const barPaddingH = 12.0;

  /// Vertical breathing room inside a bar. The top bar used 8 and the
  /// bottom 6, for no reason either could give.
  static const barPaddingV = 8.0;

  /// Between the timeline and the clock row under it.
  static const barRowGap = 2.0;

  /// Between the subtitle and the timeline above it.
  static const barSubtitleGap = 6.0;

  /// How much taller than its track the timeline's DRAG TARGET is.
  ///
  /// Material's `Slider` reserves this itself, and reserves horizontal
  /// padding to match — which is what indented the track from the clock
  /// below it. The horizontal reservation is dropped and this is kept,
  /// because a three-point-tall drag target is not one.
  static const seekBarTouchPadding = 8.0;

  static const thumbnailWidth = 120.0;

  /// How far the scrub plate floats above the bottom bar's own inset.
  ///
  /// Measured from the bar's padding rather than the frame's edge, so
  /// it clears the seek bar in fullscreen too — where the bar sits on
  /// top of the home indicator's inset.
  static const thumbnailBottomGap = 54.0;
  static const bufferingSize = 28.0;
  static const bufferingThickness = 2.5;

  /// The gap BETWEEN two control glyphs, on top of their own boxes.
  ///
  /// Zero, and that is not an oversight. Every control is a
  /// `GlobalIconButton` with a 48dp touch target, so a 22pt glyph
  /// already carries thirteen points of clear space on each side —
  /// adding six or sixteen more on top of that spread the bar out
  /// twice over. The separation a reader sees IS the accessible
  /// target.
  static const controlGap = 0.0;

  /// The dead zone before a drag is read as horizontal or vertical.
  /// Below it the axis is a coin toss, and guessing wrong seeks when
  /// the reader meant to change the volume.
  static const dragAxisSlop = 1.5;

  /// How the settings menu is placed.
  ///
  /// `bottomEnd` because the button lives in the TOP bar, and because
  /// it is DIRECTIONAL — in Arabic the bar mirrors and a menu pinned
  /// "right" would open away from its button.
  ///
  /// Close-on-scroll is left ON. It was briefly turned off on a theory
  /// that a player reporting its dimensions a beat after mount
  /// (`VideoOutput.Resize`, 0x0 then 1280x720) moved the page's scroll
  /// position and dismissed the menu. Measured, that is not what
  /// happens: content grown above an anchor keeps the menu open, and it
  /// only closes once the anchor is pushed off screen — which is the
  /// popup doing the right thing.
  static const settingsMenu = GlobalPopupOptions(
    placement: GlobalPopupPlacement.bottomEnd,
  );

  // ─── Opacity ──────────────────────────────────────────────
  /// The scrim behind the centre play button and the badges. Controls
  /// float over ARBITRARY pixels, so they carry their own contrast.
  static const badgeScrimOpacity = 0.54;
  static const buttonScrimOpacity = 0.38;
  static const trackOpacity = 0.24;
  static const bufferedOpacity = 0.38;
  static const timeLabelOpacity = 0.7;
  static const subtitleScrimOpacity = 0.67;
}

/// Reading what mpv reports.
///
/// The engine hands back a plain string, so the only thing to do with
/// it is match on the phrases it actually uses — kept in one place so a
/// change of wording is one edit rather than a hunt.
abstract final class VideoPlaybackIssue {
  /// Whether the device has no audio OUTPUT.
  ///
  /// Not a broken video: the film plays, and only the volume control
  /// has nothing to act on. Common on a simulator, and on a desktop
  /// with no default device selected — mpv repeats it on every loop,
  /// which is why the caller also de-duplicates.
  static bool isAudioDevice(String error) {
    final text = error.toLowerCase();
    return text.contains('audio device') ||
        text.contains('audio output') ||
        text.contains('no sound');
  }
}

/// Who is responsible for disposing a player.
///
/// The inline widget creates the player, and normally disposes it. But
/// it can be destroyed while its FULLSCREEN page is still on screen —
/// measured, with `wantKeepAlive` true, so it is not a sliver cull and
/// no amount of keep-alive prevents it. Whatever the reason the element
/// goes away, the page showing that player must not be left holding a
/// disposed one: that is the black picture with the frozen seek bar.
///
/// So ownership MOVES. If the inline widget dies first it hands the
/// player over and disposes nothing; the fullscreen page disposes it on
/// the way out instead. Exactly one of the two disposes, always.
class VideoOwnership {
  /// True once the inline widget has gone and handed the player over.
  bool orphaned = false;

  /// What the fullscreen page does with the player when it closes and
  /// the inline widget is already gone.
  ///
  /// Disposing was the obvious thing and it is what made leaving
  /// fullscreen look like a full reset — black frame, clip back to
  /// zero — because the widget that came back had to build a new
  /// engine. The inline widget sets this to park the player instead,
  /// for its replacement to claim. Null means dispose: nobody is
  /// coming back for it.
  void Function()? onOrphanedClose;
}

/// Everything about how a player LOOKS and which chrome it offers.
///
/// Every field is nullable so the three sources can be layered without
/// a default clobbering a theme: `caller > GlobalVideoTheme.style >
/// VideoStyle.defaults`. Resolved once per build into a
/// [ResolvedVideoStyle].
///
/// The `show*` and `enable*` flags live HERE rather than on the widget
/// on purpose. "Every video in this app offers a screenshot button" and
/// "no video in this app takes a swipe" are decisions about the app,
/// not about one clip, and a theme is the only place that can say them
/// once.
@immutable
class VideoStyle {
  const VideoStyle({
    this.borderRadius,
    this.backgroundColor,
    this.boxShadow,
    this.iconColor,
    this.iconSize,
    this.playIconSize,
    this.activeColor,
    this.bufferedColor,
    this.trackColor,
    this.thumbColor,
    this.thumbRadius,
    this.progressBarHeight,
    this.scrimColor,
    this.timeLabelStyle,
    this.titleStyle,
    this.subtitleStyle,
    this.subtitleBackground,
    this.subtitlePadding,
    this.bottomBarPadding,
    this.topBarPadding,
    this.gradientHeight,
    this.playIcon,
    this.pauseIcon,
    this.replayIcon,
    this.fullscreenIcon,
    this.exitFullscreenIcon,
    this.muteIcon,
    this.unmuteIcon,
    this.settingsIcon,
    this.fadeInDuration,
    this.fadeOutDuration,
    this.autoHideDelay,
    this.showControls,
    this.showFullscreenButton,
    this.showMuteButton,
    this.showSpeedButton,
    this.showSeekButtons,
    this.showTrackSelector,
    this.showScreenshotButton,
    this.speeds,
    this.seekDuration,
    this.enableDoubleTapSeek,
    this.keepScreenAwake,
    this.enableKeyboardShortcuts,
    this.autoPlayNext,
    this.showSpeedCycler,
    this.showSubtitleOffset,
    this.showAbLoop,
    this.showSleepTimer,
    this.showZoomToggle,
    this.showReplayButton,
    this.showChapterList,
    this.showSubtitleToggle,
    this.transportPlacement,
    this.clockPlacement,
    this.doubleTapSeekDuration,
    this.enableSwipeGestures,
    this.enableLongPressSpeed,
    this.longPressSpeedRate,
    this.enableThumbnailPreview,
    this.enableHorizontalDragSeek,
    this.pauseOnOffscreen,
    this.pipOnOffscreen,
    this.respectReducedMotion,
  });

  /// The floor. Colours are left null — they come from the palette
  /// during `resolve`, because a colour cannot be picked without a
  /// context.
  static const VideoStyle defaults = VideoStyle(
    iconSize: VideoDefaults.iconSize,
    playIconSize: VideoDefaults.playIconSize,
    thumbRadius: VideoDefaults.thumbRadius,
    progressBarHeight: VideoDefaults.progressBarHeight,
    subtitlePadding: VideoDefaults.subtitlePadding,
    bottomBarPadding: VideoDefaults.bottomBarPadding,
    topBarPadding: VideoDefaults.topBarPadding,
    gradientHeight: VideoDefaults.gradientHeight,
    playIcon: Icons.play_arrow_rounded,
    pauseIcon: Icons.pause_rounded,
    replayIcon: Icons.replay_rounded,
    fullscreenIcon: Icons.fullscreen_rounded,
    exitFullscreenIcon: Icons.fullscreen_exit_rounded,
    muteIcon: Icons.volume_off_rounded,
    unmuteIcon: Icons.volume_up_rounded,
    settingsIcon: Icons.settings_rounded,
    fadeInDuration: AppDurations.quick,
    fadeOutDuration: AppDurations.quick,
    autoHideDelay: VideoDefaults.autoHideDelay,
    showControls: true,
    showFullscreenButton: true,
    showMuteButton: true,
    showSpeedButton: true,
    showSeekButtons: false,
    showTrackSelector: false,
    showScreenshotButton: false,
    speeds: PlaybackSpeed.defaults,
    seekDuration: VideoDefaults.seekDuration,
    enableDoubleTapSeek: true,
    keepScreenAwake: true,
    enableKeyboardShortcuts: true,
    autoPlayNext: false,
    showSpeedCycler: false,
    showSubtitleOffset: false,
    showAbLoop: false,
    showSleepTimer: false,
    showZoomToggle: false,
    showReplayButton: false,
    showChapterList: false,
    showSubtitleToggle: false,
    transportPlacement: VideoTransportPlacement.centered,
    clockPlacement: VideoClockPlacement.below,
    doubleTapSeekDuration: VideoDefaults.doubleTapSeekDuration,
    enableSwipeGestures: true,
    enableLongPressSpeed: true,
    longPressSpeedRate: VideoDefaults.longPressSpeedRate,
    enableThumbnailPreview: false,
    enableHorizontalDragSeek: true,
    pauseOnOffscreen: false,
    pipOnOffscreen: false,
    respectReducedMotion: true,
  );

  // ─── Presets ──────────────────────────────────────────────
  //
  // A preset is a NAMED BAG, not a mode. Everything here is a
  // decision about which controls exist and where they sit, which is
  // exactly what `VideoStyle` already carries — so a preset composes
  // with a theme and a per-call override like any other bag, and adds
  // no code path to keep true.
  //
  // What is NOT a preset is a different interaction model. A reel
  // pages between clips, taps to pause rather than to show chrome and
  // has no timeline at all; that is a widget that USES `GlobalVideo`,
  // the way the fullscreen page and the PiP window already do. Adding
  // it here as a flag would put an `if` through every build method in
  // the module.

  /// Just the film and a way to start it.
  ///
  /// For a card in a feed, or anywhere the player is not the reason
  /// the page exists. No gear, because with nothing else switched on
  /// it would open onto an empty menu.
  static const VideoStyle minimal = VideoStyle(
    showSeekButtons: false,
    showMuteButton: false,
    showScreenshotButton: false,
    showSpeedButton: false,
    showTrackSelector: false,
    enableDoubleTapSeek: false,
    enableSwipeGestures: false,
    enableLongPressSpeed: false,
    clockPlacement: VideoClockPlacement.split,
  );

  /// The player IS the page.
  ///
  /// Everything on, laid out like a desktop player, and the screen
  /// stays awake — which is the one thing a film watched end to end
  /// actually needs and the reason this is not just "all flags true".
  static const VideoStyle cinema = VideoStyle(
    showSeekButtons: true,
    showMuteButton: true,
    showFullscreenButton: true,
    showTrackSelector: true,
    showSpeedButton: true,
    showSpeedCycler: true,
    showSubtitleToggle: true,
    showSubtitleOffset: true,
    showChapterList: true,
    showZoomToggle: true,
    keepScreenAwake: true,
    transportPlacement: VideoTransportPlacement.bar,
    clockPlacement: VideoClockPlacement.split,
  );

  /// A lecture, a recording, anything watched to LEARN from.
  ///
  /// Speed and subtitles lead, because those are the two controls that
  /// get used constantly here, and the A–B loop is on because
  /// repeating a passage is the whole activity.
  static const VideoStyle lesson = VideoStyle(
    showSeekButtons: true,
    showSpeedCycler: true,
    showSpeedButton: true,
    showSubtitleToggle: true,
    showSubtitleOffset: true,
    showTrackSelector: true,
    showChapterList: true,
    showAbLoop: true,
    showFullscreenButton: true,
    keepScreenAwake: true,
    transportPlacement: VideoTransportPlacement.barCentered,
    clockPlacement: VideoClockPlacement.split,
  );

  // ─── Frame ────────────────────────────────────────────────
  final BorderRadius? borderRadius;
  final Color? backgroundColor;
  final List<BoxShadow>? boxShadow;

  // ─── Glyphs ───────────────────────────────────────────────
  final Color? iconColor;
  final double? iconSize;
  final double? playIconSize;

  // ─── Seek bar ─────────────────────────────────────────────
  final Color? activeColor;
  final Color? bufferedColor;
  final Color? trackColor;
  final Color? thumbColor;
  final double? thumbRadius;
  final double? progressBarHeight;

  /// Behind the badges, the centre button and the gradients. Controls
  /// float over arbitrary pixels and carry their own contrast.
  final Color? scrimColor;

  // ─── Type ─────────────────────────────────────────────────
  final TextStyle? timeLabelStyle;
  final TextStyle? titleStyle;
  final TextStyle? subtitleStyle;
  final Color? subtitleBackground;
  final EdgeInsets? subtitlePadding;

  // ─── Chrome ───────────────────────────────────────────────
  final EdgeInsets? bottomBarPadding;
  final EdgeInsets? topBarPadding;
  final double? gradientHeight;

  final IconData? playIcon;
  final IconData? pauseIcon;
  final IconData? replayIcon;
  final IconData? fullscreenIcon;
  final IconData? exitFullscreenIcon;
  final IconData? muteIcon;
  final IconData? unmuteIcon;
  final IconData? settingsIcon;

  // ─── Timing ───────────────────────────────────────────────
  final Duration? fadeInDuration;
  final Duration? fadeOutDuration;
  final Duration? autoHideDelay;

  // ─── Which chrome is offered ──────────────────────────────
  final bool? showControls;
  final bool? showFullscreenButton;
  final bool? showMuteButton;
  final bool? showSpeedButton;
  final bool? showSeekButtons;
  final bool? showTrackSelector;
  final bool? showScreenshotButton;
  final List<PlaybackSpeed>? speeds;
  final Duration? seekDuration;

  // ─── Gestures ─────────────────────────────────────────────
  final bool? enableDoubleTapSeek;

  /// Hold the screen on while this player is PLAYING. On by default —
  /// a paused or finished player never holds it.
  final bool? keepScreenAwake;

  /// Space, K, arrows, M, F, Escape. On by default: harmless without a
  /// keyboard, and the thing every player on a desktop is expected to
  /// answer to.
  final bool? enableKeyboardShortcuts;

  /// Play the next item in a playlist when this one ends, after a
  /// countdown the reader can stop.
  ///
  /// OFF by default, unlike the rest of these. Autoplay nobody asked
  /// for is the single most complained-about behaviour a player has,
  /// so an app opts into it rather than out of it.
  final bool? autoPlayNext;

  /// A tappable `1x` on the bar that steps through [speeds] and wraps.
  ///
  /// OFF by default: it is a second way to reach something the gear
  /// already offers, and a bar that shows every route to everything is
  /// the crowding the overflow exists to prevent. Apps where speed is
  /// used constantly — lectures, recordings — turn it on.
  final bool? showSpeedCycler;

  /// Nudges subtitles earlier or later, for a file whose
  /// subtitles do not match its audio.
  final bool? showSubtitleOffset;

  /// Marks two points and loops between them. For practice:
  /// a bar of music, a line of a language, a move.
  final bool? showAbLoop;

  /// Stops playback after a while, or at the end of this
  /// video. For anything watched in bed.
  final bool? showSleepTimer;

  /// Switches the picture between fitting the frame and
  /// filling it — the letterbox toggle every player has.
  final bool? showZoomToggle;

  /// Back to the start without dragging the timeline there.
  final bool? showReplayButton;

  /// A jump list of the chapters. Only ever shown when the
  /// widget was actually given some.
  final bool? showChapterList;

  /// A one-tap subtitles on / off, for a player whose
  /// audience switches them constantly. The track list in the gear
  /// still exists and still chooses WHICH.
  final bool? showSubtitleToggle;

  /// Where the transport lives. See [VideoTransportPlacement].
  final VideoTransportPlacement? transportPlacement;

  /// Where the clock sits. See [VideoClockPlacement].
  final VideoClockPlacement? clockPlacement;
  final Duration? doubleTapSeekDuration;
  final bool? enableSwipeGestures;
  final bool? enableLongPressSpeed;
  final double? longPressSpeedRate;
  final bool? enableThumbnailPreview;
  final bool? enableHorizontalDragSeek;

  // ─── Off-screen behaviour ─────────────────────────────────
  final bool? pauseOnOffscreen;
  final bool? pipOnOffscreen;

  /// Whether the controls' fade is skipped when the platform asks for
  /// reduced motion. The VIDEO is the content and is never touched —
  /// only the chrome that animates over it.
  final bool? respectReducedMotion;

  /// Field-by-field override: anything `other` says wins, anything it
  /// leaves null keeps this bag's answer.
  VideoStyle mergedWith(VideoStyle? other) {
    if (other == null) return this;
    return VideoStyle(
      borderRadius: other.borderRadius ?? borderRadius,
      backgroundColor: other.backgroundColor ?? backgroundColor,
      boxShadow: other.boxShadow ?? boxShadow,
      iconColor: other.iconColor ?? iconColor,
      iconSize: other.iconSize ?? iconSize,
      playIconSize: other.playIconSize ?? playIconSize,
      activeColor: other.activeColor ?? activeColor,
      bufferedColor: other.bufferedColor ?? bufferedColor,
      trackColor: other.trackColor ?? trackColor,
      thumbColor: other.thumbColor ?? thumbColor,
      thumbRadius: other.thumbRadius ?? thumbRadius,
      progressBarHeight: other.progressBarHeight ?? progressBarHeight,
      scrimColor: other.scrimColor ?? scrimColor,
      timeLabelStyle: other.timeLabelStyle ?? timeLabelStyle,
      titleStyle: other.titleStyle ?? titleStyle,
      subtitleStyle: other.subtitleStyle ?? subtitleStyle,
      subtitleBackground: other.subtitleBackground ?? subtitleBackground,
      subtitlePadding: other.subtitlePadding ?? subtitlePadding,
      bottomBarPadding: other.bottomBarPadding ?? bottomBarPadding,
      topBarPadding: other.topBarPadding ?? topBarPadding,
      gradientHeight: other.gradientHeight ?? gradientHeight,
      playIcon: other.playIcon ?? playIcon,
      pauseIcon: other.pauseIcon ?? pauseIcon,
      replayIcon: other.replayIcon ?? replayIcon,
      fullscreenIcon: other.fullscreenIcon ?? fullscreenIcon,
      exitFullscreenIcon: other.exitFullscreenIcon ?? exitFullscreenIcon,
      muteIcon: other.muteIcon ?? muteIcon,
      unmuteIcon: other.unmuteIcon ?? unmuteIcon,
      settingsIcon: other.settingsIcon ?? settingsIcon,
      fadeInDuration: other.fadeInDuration ?? fadeInDuration,
      fadeOutDuration: other.fadeOutDuration ?? fadeOutDuration,
      autoHideDelay: other.autoHideDelay ?? autoHideDelay,
      showControls: other.showControls ?? showControls,
      showFullscreenButton: other.showFullscreenButton ?? showFullscreenButton,
      showMuteButton: other.showMuteButton ?? showMuteButton,
      showSpeedButton: other.showSpeedButton ?? showSpeedButton,
      showSeekButtons: other.showSeekButtons ?? showSeekButtons,
      showTrackSelector: other.showTrackSelector ?? showTrackSelector,
      showScreenshotButton: other.showScreenshotButton ?? showScreenshotButton,
      speeds: other.speeds ?? speeds,
      seekDuration: other.seekDuration ?? seekDuration,
      enableDoubleTapSeek: other.enableDoubleTapSeek ?? enableDoubleTapSeek,
      keepScreenAwake: other.keepScreenAwake ?? keepScreenAwake,
      enableKeyboardShortcuts:
          other.enableKeyboardShortcuts ?? enableKeyboardShortcuts,
      autoPlayNext: other.autoPlayNext ?? autoPlayNext,
      showSpeedCycler: other.showSpeedCycler ?? showSpeedCycler,
      showSubtitleOffset: other.showSubtitleOffset ?? showSubtitleOffset,
      showAbLoop: other.showAbLoop ?? showAbLoop,
      showSleepTimer: other.showSleepTimer ?? showSleepTimer,
      showZoomToggle: other.showZoomToggle ?? showZoomToggle,
      showReplayButton: other.showReplayButton ?? showReplayButton,
      showChapterList: other.showChapterList ?? showChapterList,
      showSubtitleToggle: other.showSubtitleToggle ?? showSubtitleToggle,
      transportPlacement: other.transportPlacement ?? transportPlacement,
      clockPlacement: other.clockPlacement ?? clockPlacement,
      doubleTapSeekDuration:
          other.doubleTapSeekDuration ?? doubleTapSeekDuration,
      enableSwipeGestures: other.enableSwipeGestures ?? enableSwipeGestures,
      enableLongPressSpeed: other.enableLongPressSpeed ?? enableLongPressSpeed,
      longPressSpeedRate: other.longPressSpeedRate ?? longPressSpeedRate,
      enableThumbnailPreview:
          other.enableThumbnailPreview ?? enableThumbnailPreview,
      enableHorizontalDragSeek:
          other.enableHorizontalDragSeek ?? enableHorizontalDragSeek,
      pauseOnOffscreen: other.pauseOnOffscreen ?? pauseOnOffscreen,
      pipOnOffscreen: other.pipOnOffscreen ?? pipOnOffscreen,
      respectReducedMotion: other.respectReducedMotion ?? respectReducedMotion,
    );
  }

  VideoStyle copyWith({
    BorderRadius? borderRadius,
    Color? backgroundColor,
    List<BoxShadow>? boxShadow,
    Color? iconColor,
    double? iconSize,
    double? playIconSize,
    Color? activeColor,
    Color? bufferedColor,
    Color? trackColor,
    Color? thumbColor,
    double? thumbRadius,
    double? progressBarHeight,
    Color? scrimColor,
    TextStyle? timeLabelStyle,
    TextStyle? titleStyle,
    TextStyle? subtitleStyle,
    Color? subtitleBackground,
    EdgeInsets? subtitlePadding,
    EdgeInsets? bottomBarPadding,
    EdgeInsets? topBarPadding,
    double? gradientHeight,
    IconData? playIcon,
    IconData? pauseIcon,
    IconData? replayIcon,
    IconData? fullscreenIcon,
    IconData? exitFullscreenIcon,
    IconData? muteIcon,
    IconData? unmuteIcon,
    IconData? settingsIcon,
    Duration? fadeInDuration,
    Duration? fadeOutDuration,
    Duration? autoHideDelay,
    bool? showControls,
    bool? showFullscreenButton,
    bool? showMuteButton,
    bool? showSpeedButton,
    bool? showSeekButtons,
    bool? showTrackSelector,
    bool? showScreenshotButton,
    List<PlaybackSpeed>? speeds,
    Duration? seekDuration,
    bool? enableDoubleTapSeek,
    bool? keepScreenAwake,
    bool? enableKeyboardShortcuts,
    bool? autoPlayNext,
    bool? showSpeedCycler,
    bool? showSubtitleOffset,
    bool? showAbLoop,
    bool? showSleepTimer,
    bool? showZoomToggle,
    bool? showReplayButton,
    bool? showChapterList,
    bool? showSubtitleToggle,
    VideoTransportPlacement? transportPlacement,
    VideoClockPlacement? clockPlacement,
    Duration? doubleTapSeekDuration,
    bool? enableSwipeGestures,
    bool? enableLongPressSpeed,
    double? longPressSpeedRate,
    bool? enableThumbnailPreview,
    bool? enableHorizontalDragSeek,
    bool? pauseOnOffscreen,
    bool? pipOnOffscreen,
    bool? respectReducedMotion,
  }) => VideoStyle(
    borderRadius: borderRadius ?? this.borderRadius,
    backgroundColor: backgroundColor ?? this.backgroundColor,
    boxShadow: boxShadow ?? this.boxShadow,
    iconColor: iconColor ?? this.iconColor,
    iconSize: iconSize ?? this.iconSize,
    playIconSize: playIconSize ?? this.playIconSize,
    activeColor: activeColor ?? this.activeColor,
    bufferedColor: bufferedColor ?? this.bufferedColor,
    trackColor: trackColor ?? this.trackColor,
    thumbColor: thumbColor ?? this.thumbColor,
    thumbRadius: thumbRadius ?? this.thumbRadius,
    progressBarHeight: progressBarHeight ?? this.progressBarHeight,
    scrimColor: scrimColor ?? this.scrimColor,
    timeLabelStyle: timeLabelStyle ?? this.timeLabelStyle,
    titleStyle: titleStyle ?? this.titleStyle,
    subtitleStyle: subtitleStyle ?? this.subtitleStyle,
    subtitleBackground: subtitleBackground ?? this.subtitleBackground,
    subtitlePadding: subtitlePadding ?? this.subtitlePadding,
    bottomBarPadding: bottomBarPadding ?? this.bottomBarPadding,
    topBarPadding: topBarPadding ?? this.topBarPadding,
    gradientHeight: gradientHeight ?? this.gradientHeight,
    playIcon: playIcon ?? this.playIcon,
    pauseIcon: pauseIcon ?? this.pauseIcon,
    replayIcon: replayIcon ?? this.replayIcon,
    fullscreenIcon: fullscreenIcon ?? this.fullscreenIcon,
    exitFullscreenIcon: exitFullscreenIcon ?? this.exitFullscreenIcon,
    muteIcon: muteIcon ?? this.muteIcon,
    unmuteIcon: unmuteIcon ?? this.unmuteIcon,
    settingsIcon: settingsIcon ?? this.settingsIcon,
    fadeInDuration: fadeInDuration ?? this.fadeInDuration,
    fadeOutDuration: fadeOutDuration ?? this.fadeOutDuration,
    autoHideDelay: autoHideDelay ?? this.autoHideDelay,
    showControls: showControls ?? this.showControls,
    showFullscreenButton: showFullscreenButton ?? this.showFullscreenButton,
    showMuteButton: showMuteButton ?? this.showMuteButton,
    showSpeedButton: showSpeedButton ?? this.showSpeedButton,
    showSeekButtons: showSeekButtons ?? this.showSeekButtons,
    showTrackSelector: showTrackSelector ?? this.showTrackSelector,
    showScreenshotButton: showScreenshotButton ?? this.showScreenshotButton,
    speeds: speeds ?? this.speeds,
    seekDuration: seekDuration ?? this.seekDuration,
    enableDoubleTapSeek: enableDoubleTapSeek ?? this.enableDoubleTapSeek,
    keepScreenAwake: keepScreenAwake ?? this.keepScreenAwake,
    enableKeyboardShortcuts:
        enableKeyboardShortcuts ?? this.enableKeyboardShortcuts,
    autoPlayNext: autoPlayNext ?? this.autoPlayNext,
    showSpeedCycler: showSpeedCycler ?? this.showSpeedCycler,
    showSubtitleOffset: showSubtitleOffset ?? this.showSubtitleOffset,
    showAbLoop: showAbLoop ?? this.showAbLoop,
    showSleepTimer: showSleepTimer ?? this.showSleepTimer,
    showZoomToggle: showZoomToggle ?? this.showZoomToggle,
    showReplayButton: showReplayButton ?? this.showReplayButton,
    showChapterList: showChapterList ?? this.showChapterList,
    showSubtitleToggle: showSubtitleToggle ?? this.showSubtitleToggle,
    transportPlacement: transportPlacement ?? this.transportPlacement,
    clockPlacement: clockPlacement ?? this.clockPlacement,
    doubleTapSeekDuration: doubleTapSeekDuration ?? this.doubleTapSeekDuration,
    enableSwipeGestures: enableSwipeGestures ?? this.enableSwipeGestures,
    enableLongPressSpeed: enableLongPressSpeed ?? this.enableLongPressSpeed,
    longPressSpeedRate: longPressSpeedRate ?? this.longPressSpeedRate,
    enableThumbnailPreview:
        enableThumbnailPreview ?? this.enableThumbnailPreview,
    enableHorizontalDragSeek:
        enableHorizontalDragSeek ?? this.enableHorizontalDragSeek,
    pauseOnOffscreen: pauseOnOffscreen ?? this.pauseOnOffscreen,
    pipOnOffscreen: pipOnOffscreen ?? this.pipOnOffscreen,
    respectReducedMotion: respectReducedMotion ?? this.respectReducedMotion,
  );
}

/// A [VideoStyle] with every question answered.
///
/// Materialized ONCE per build so no widget below re-derives
/// `style.x ?? palette.y` at each use.
@immutable
class ResolvedVideoStyle {
  const ResolvedVideoStyle({
    required this.borderRadius,
    required this.backgroundColor,
    required this.boxShadow,
    required this.iconColor,
    required this.iconSize,
    required this.playIconSize,
    required this.activeColor,
    required this.bufferedColor,
    required this.trackColor,
    required this.thumbColor,
    required this.thumbRadius,
    required this.progressBarHeight,
    required this.scrimColor,
    required this.timeLabelStyle,
    required this.titleStyle,
    required this.subtitleStyle,
    required this.subtitleBackground,
    required this.subtitlePadding,
    required this.bottomBarPadding,
    required this.topBarPadding,
    required this.gradientHeight,
    required this.playIcon,
    required this.pauseIcon,
    required this.replayIcon,
    required this.fullscreenIcon,
    required this.exitFullscreenIcon,
    required this.muteIcon,
    required this.unmuteIcon,
    required this.settingsIcon,
    required this.fadeInDuration,
    required this.fadeOutDuration,
    required this.autoHideDelay,
    required this.showControls,
    required this.showFullscreenButton,
    required this.showMuteButton,
    required this.showSpeedButton,
    required this.showSeekButtons,
    required this.showTrackSelector,
    required this.showScreenshotButton,
    required this.speeds,
    required this.seekDuration,
    required this.enableDoubleTapSeek,
    required this.keepScreenAwake,
    required this.enableKeyboardShortcuts,
    required this.autoPlayNext,
    required this.showSpeedCycler,
    required this.showSubtitleOffset,
    required this.showAbLoop,
    required this.showSleepTimer,
    required this.showZoomToggle,
    required this.showReplayButton,
    required this.showChapterList,
    required this.showSubtitleToggle,
    required this.transportPlacement,
    required this.clockPlacement,
    required this.doubleTapSeekDuration,
    required this.enableSwipeGestures,
    required this.enableLongPressSpeed,
    required this.longPressSpeedRate,
    required this.enableThumbnailPreview,
    required this.enableHorizontalDragSeek,
    required this.pauseOnOffscreen,
    required this.pipOnOffscreen,
    required this.respectReducedMotion,
  });

  final BorderRadius? borderRadius;
  final Color backgroundColor;
  final List<BoxShadow>? boxShadow;
  final Color iconColor;
  final double iconSize;
  final double playIconSize;
  final Color activeColor;
  final Color bufferedColor;
  final Color trackColor;
  final Color thumbColor;
  final double thumbRadius;
  final double progressBarHeight;
  final Color scrimColor;
  final TextStyle? timeLabelStyle;
  final TextStyle? titleStyle;
  final TextStyle? subtitleStyle;
  final Color subtitleBackground;
  final EdgeInsets subtitlePadding;
  final EdgeInsets bottomBarPadding;
  final EdgeInsets topBarPadding;
  final double gradientHeight;
  final IconData playIcon;
  final IconData pauseIcon;
  final IconData replayIcon;
  final IconData fullscreenIcon;
  final IconData exitFullscreenIcon;
  final IconData muteIcon;
  final IconData unmuteIcon;
  final IconData settingsIcon;
  final Duration fadeInDuration;
  final Duration fadeOutDuration;
  final Duration autoHideDelay;
  final bool showControls;
  final bool showFullscreenButton;
  final bool showMuteButton;
  final bool showSpeedButton;
  final bool showSeekButtons;
  final bool showTrackSelector;
  final bool showScreenshotButton;
  final List<PlaybackSpeed> speeds;
  final Duration seekDuration;
  final bool enableDoubleTapSeek;
  final bool keepScreenAwake;
  final bool enableKeyboardShortcuts;
  final bool autoPlayNext;
  final bool showSpeedCycler;
  final bool showSubtitleOffset;
  final bool showAbLoop;
  final bool showSleepTimer;
  final bool showZoomToggle;
  final bool showReplayButton;
  final bool showChapterList;
  final bool showSubtitleToggle;
  final VideoTransportPlacement transportPlacement;
  final VideoClockPlacement clockPlacement;
  final Duration doubleTapSeekDuration;
  final bool enableSwipeGestures;
  final bool enableLongPressSpeed;
  final double longPressSpeedRate;
  final bool enableThumbnailPreview;
  final bool enableHorizontalDragSeek;
  final bool pauseOnOffscreen;
  final bool pipOnOffscreen;
  final bool respectReducedMotion;

  /// A context-free bag, used ONLY until the real one resolves.
  ///
  /// `initState` runs before `didChangeDependencies`, and it starts the
  /// auto-hide timer — which reads this. A `late` field made that an
  /// ordering trap that threw `LateInitializationError` on the first
  /// frame of every player, and no unit test could catch it because the
  /// engine will not start under `flutter_test`. A real default makes
  /// the trap impossible instead of documenting it.
  ///
  /// Nothing painted from this is ever SEEN: `didChangeDependencies`
  /// runs before the first build, so the accent below is replaced by
  /// the palette's before a frame exists.
  static const ResolvedVideoStyle fallback = ResolvedVideoStyle(
    borderRadius: null,
    backgroundColor: Colors.black,
    boxShadow: null,
    iconColor: Colors.white,
    iconSize: VideoDefaults.iconSize,
    playIconSize: VideoDefaults.playIconSize,
    activeColor: Colors.white,
    bufferedColor: Color(0x61FFFFFF),
    trackColor: Color(0x3DFFFFFF),
    thumbColor: Colors.white,
    thumbRadius: VideoDefaults.thumbRadius,
    progressBarHeight: VideoDefaults.progressBarHeight,
    scrimColor: Color(0x8A000000),
    timeLabelStyle: null,
    titleStyle: null,
    subtitleStyle: null,
    subtitleBackground: Color(0xAB000000),
    subtitlePadding: VideoDefaults.subtitlePadding,
    bottomBarPadding: VideoDefaults.bottomBarPadding,
    topBarPadding: VideoDefaults.topBarPadding,
    gradientHeight: VideoDefaults.gradientHeight,
    playIcon: Icons.play_arrow_rounded,
    pauseIcon: Icons.pause_rounded,
    replayIcon: Icons.replay_rounded,
    fullscreenIcon: Icons.fullscreen_rounded,
    exitFullscreenIcon: Icons.fullscreen_exit_rounded,
    muteIcon: Icons.volume_off_rounded,
    unmuteIcon: Icons.volume_up_rounded,
    settingsIcon: Icons.settings_rounded,
    fadeInDuration: AppDurations.quick,
    fadeOutDuration: AppDurations.quick,
    autoHideDelay: VideoDefaults.autoHideDelay,
    showControls: true,
    showFullscreenButton: true,
    showMuteButton: true,
    showSpeedButton: true,
    showSeekButtons: false,
    showTrackSelector: false,
    showScreenshotButton: false,
    speeds: PlaybackSpeed.defaults,
    seekDuration: VideoDefaults.seekDuration,
    enableDoubleTapSeek: true,
    keepScreenAwake: true,
    enableKeyboardShortcuts: true,
    autoPlayNext: false,
    showSpeedCycler: false,
    showSubtitleOffset: false,
    showAbLoop: false,
    showSleepTimer: false,
    showZoomToggle: false,
    showReplayButton: false,
    showChapterList: false,
    showSubtitleToggle: false,
    transportPlacement: VideoTransportPlacement.centered,
    clockPlacement: VideoClockPlacement.below,
    doubleTapSeekDuration: VideoDefaults.doubleTapSeekDuration,
    enableSwipeGestures: true,
    enableLongPressSpeed: true,
    longPressSpeedRate: VideoDefaults.longPressSpeedRate,
    enableThumbnailPreview: false,
    enableHorizontalDragSeek: true,
    pauseOnOffscreen: false,
    pipOnOffscreen: false,
    respectReducedMotion: true,
  );

  /// The fade, once reduced motion has had its say.
  ///
  /// Only the CHROME is stilled. Pausing the video itself would be
  /// reading the setting as "no moving pictures", which is not what it
  /// asks for — the film is the content.
  Duration fadeIn({required bool reduceMotion}) =>
      respectReducedMotion && reduceMotion ? Duration.zero : fadeInDuration;

  Duration fadeOut({required bool reduceMotion}) =>
      respectReducedMotion && reduceMotion ? Duration.zero : fadeOutDuration;

  /// Whether the auto-hide clock should be running.
  ///
  /// A pure function because `VideoControls` cannot be built under
  /// `flutter_test` — `media_kit` will not start — and this rule has
  /// already been got wrong once. It is the only part of the auto-hide
  /// that can be tested at all, so it is worth having separately.
  ///
  /// Three reasons not to arm it, and each is someone who is not idle:
  /// a paused player is waiting for the reader, a finger on the seek
  /// bar is mid-scrub, and an open menu is being read.
  static bool shouldAutoHide({
    required bool playing,
    required bool dragging,
    required bool menuOpen,
  }) => playing && !dragging && !menuOpen;

  /// What the play button should show the INSTANT it is tapped.
  ///
  /// Pure, so the one rule with an edge case in it can be tested: a
  /// finished video replays rather than toggling, so the tap that
  /// follows "completed" always means PLAYING, never pausing.
  static bool playingAfterTap({
    required bool playing,
    required bool completed,
  }) => completed || !playing;

  /// Controls are sized against a reference height so a player in a
  /// list cell and a fullscreen one are not handed the same 28pt icon.
  static double scaleFor(double height) =>
      (height / VideoDefaults.scaleReferenceHeight).clamp(
        VideoDefaults.scaleMin,
        VideoDefaults.scaleMax,
      );
}
