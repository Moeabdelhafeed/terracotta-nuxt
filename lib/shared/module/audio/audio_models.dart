import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'audio_background.dart';

/// Where the audio bytes come from.
///
/// `video*` kinds route through a `video_player`-backed implementation
/// internally — `just_audio` can't reliably demux video containers
/// (mp4/mov with H.264 + AAC) on iOS/macOS. Use these for sources
/// where you want only the audio track of a video file. Video frames
/// are decoded-and-discarded; no visual is rendered.
enum AudioSourceKind {
  url,
  asset,
  file,
  bytes,
  videoUrl,
  videoFile,
  videoAsset,
}

/// Polymorphic source. Factory constructors keep callers from caring
/// about [AudioSourceKind] until they need to.
@immutable
class AudioSourceSpec {
  const AudioSourceSpec._({
    required this.kind,
    required this.value,
    this.bytes,
  });

  factory AudioSourceSpec.url(String url) =>
      AudioSourceSpec._(kind: AudioSourceKind.url, value: url);

  factory AudioSourceSpec.asset(String path) =>
      AudioSourceSpec._(kind: AudioSourceKind.asset, value: path);

  factory AudioSourceSpec.file(String path) =>
      AudioSourceSpec._(kind: AudioSourceKind.file, value: path);

  factory AudioSourceSpec.bytes(Uint8List data, {String label = 'bytes'}) =>
      AudioSourceSpec._(
        kind: AudioSourceKind.bytes,
        value: label,
        bytes: data,
      );

  /// mp4/mov/mkv URL — only the audio track plays. Routed through
  /// `video_player` under the hood since `just_audio` can't demux
  /// these containers on iOS/macOS.
  factory AudioSourceSpec.videoUrl(String url) =>
      AudioSourceSpec._(kind: AudioSourceKind.videoUrl, value: url);

  factory AudioSourceSpec.videoFile(String path) =>
      AudioSourceSpec._(kind: AudioSourceKind.videoFile, value: path);

  factory AudioSourceSpec.videoAsset(String path) =>
      AudioSourceSpec._(kind: AudioSourceKind.videoAsset, value: path);

  final AudioSourceKind kind;
  final String value;
  final Uint8List? bytes;

  /// True when this source needs a video-capable backend.
  bool get isVideo =>
      kind == AudioSourceKind.videoUrl ||
      kind == AudioSourceKind.videoFile ||
      kind == AudioSourceKind.videoAsset;
}

/// Every hard-coded number the audio player uses.
///
/// The floor for [AudioStyle], and the one place to change a size
/// rather than hunting the widget for `44`. The numbers themselves are
/// unchanged from what the player already drew — this names them, it
/// does not redesign anything.
abstract final class AudioDefaults {
  // ─── Waveform ─────────────────────────────────────────────
  static const barWidth = 2.5;
  static const barSpacing = 1.5;
  static const barRadius = 1.5;
  static const waveformHeight = 56.0;

  /// The full variant gives the waveform more room than a compact one,
  /// whatever the bag says — it is the only thing on that row.
  static const fullWaveformMinHeight = 64.0;

  /// How close a reported position has to be to a seek target before
  /// the platform is believed again, and how long to wait at most.
  ///
  /// The tolerance is how close to the position playback was LEFT at
  /// a report has to be before it is treated as stale. Generous,
  /// because the clock keeps running while the seek is in flight.
  static const seekSettleTolerance = Duration(milliseconds: 400);
  static const seekSettleTimeout = Duration(seconds: 2);

  /// How many samples a waveform is reduced to. More is not more
  /// legible at these widths — it is just more work per frame.
  static const waveformSamples = 120;

  /// How far playback must move before the position is reported again.
  ///
  /// The ticker runs every frame and the other end of a position
  /// report is usually a write to disk.
  static const positionReportInterval = Duration(seconds: 5);

  /// How long the playhead takes to travel to a tapped position.
  ///
  /// Playback moves it a fraction of a bar per frame, which needs no
  /// animation at all — a seek moves it a third of the way across the
  /// widget in one frame, and that reads as a jump rather than as a
  /// move. Only a discontinuous change is animated.
  static const seekSweep = Duration(milliseconds: 260);

  /// What counts as discontinuous, as a fraction of the whole track.
  ///
  /// Playing forward at 1x covers far less than this per frame; any
  /// jump bigger than it came from a tap or a skip button.
  static const seekSweepThreshold = 0.02;

  /// A silent moment still gets a mark — a gap in the row reads as a
  /// rendering fault rather than as silence.
  static const minBarHeight = 2.0;

  /// Unplayed bars sit behind the played ones rather than beside them.
  static const unplayedBarOpacity = 0.65;

  // ─── Frame ────────────────────────────────────────────────
  static const compactHeight = 56.0;
  static const padding = EdgeInsets.all(16);
  static const radius = 16.0;

  // ─── Controls ─────────────────────────────────────────────
  static const playButtonSize = 64.0;
  static const playIconSize = 32.0;

  /// The glyph inside the play button, against the button's own size.
  static const playGlyphRatio = 0.55;
  static const circleButtonSize = 44.0;
  static const circleIconSize = 26.0;

  /// A transport glyph is not a filled button, so it carries less than
  /// full weight against the surface.
  static const controlIconOpacity = 0.85;

  static const chipIconSize = 16.0;
  static const chipFontSize = 12.0;
  static const chipLetterSpacing = 0.2;
  static const chipPadding = EdgeInsets.symmetric(
    horizontal: 12,
    vertical: 6,
  );

  /// An unselected chip is a surface tint rather than a colour.
  static const chipIdleOpacity = 0.08;

  // ─── Timeline ─────────────────────────────────────────────
  static const trackHeight = 3.0;
  static const thumbRadius = 6.0;
  static const timeFontSize = 11.0;

  /// The clock either side of the timeline reads as secondary.
  static const timeOpacity = 0.7;

  // ─── Compact ──────────────────────────────────────────────
  static const compactIconSize = 32.0;
  static const compactWaveformWidth = 140.0;
  static const compactWaveformHeight = 28.0;

  // ─── Behaviour ────────────────────────────────────────────
  static const skipSeconds = 15;

  /// What the speed control steps through.
  static const speeds = <double>[0.5, 0.75, 1, 1.25, 1.5, 2];

  /// How far into a track "previous" stops meaning the track before
  /// and starts meaning THIS one from the top.
  ///
  /// Every music player ever shipped does this, and the reason is that
  /// both are the same button: someone three seconds in pressed it to
  /// go back, someone a minute in pressed it to hear that bit again.
  static const previousRestartsAfter = Duration(seconds: 3);

  /// What the sleep control steps through, before "end of track" and
  /// back to off.
  static const sleepOptions = <Duration>[
    Duration(minutes: 15),
    Duration(minutes: 30),
    Duration(minutes: 60),
  ];

  /// The shape a player draws when it has no samples of its own.
  ///
  /// It lived on the chrome widget, which both backend states then
  /// reached into for it — a private field of a widget being read by
  /// two state classes is a number in the wrong place.
  static const flatWaveform = <double>[
    0.20,
    0.30,
    0.42,
    0.55,
    0.62,
    0.50,
    0.40,
    0.30,
    0.25,
    0.35,
    0.50,
    0.65,
    0.70,
    0.60,
    0.50,
    0.42,
    0.35,
    0.30,
    0.40,
    0.52,
    0.58,
    0.48,
    0.38,
    0.30,
    0.25,
    0.20,
    0.18,
    0.15,
  ];

  // ─── Spacing ──────────────────────────────────────────────
  static const gapXs = 6.0;
  static const gapSm = 8.0;
  static const gapMd = 10.0;
  static const gapLg = 16.0;
}

/// How the audio player LOOKS and which controls it offers.
///
/// Every field is nullable so the three sources layer without a
/// default clobbering a theme: `caller > GlobalAudioTheme.style >
/// AudioStyle.defaults`. Resolved once per build into a
/// [ResolvedAudioStyle].
///
/// It was half-nullable before — colours could be omitted but every
/// size and flag carried an inline default, so a theme could not set
/// one without every call site overriding it back. That is the same
/// shape `NavigationRailStyle` had, and the same reason it could not
/// be rebranded.
@immutable
class AudioStyle {
  const AudioStyle({
    this.accent,
    this.barColor,
    this.barWidth,
    this.barSpacing,
    this.barRadius,
    this.waveformHeight,
    this.controlsColor,
    this.showSpeed,
    this.showLoop,
    this.showSkip,
    this.showQueue,
    this.showSleepTimer,
    this.enableKeyboard,
    this.skipSeconds,
    this.speeds,
    this.sleepOptions,
    this.compactHeight,
    this.backgroundColor,
    this.gradient,
    this.padding,
    this.borderRadius,
    this.playButtonGradient,
    this.playButtonShadow,
    this.timeTextStyle,
  });

  /// The floor. Colours are absent on purpose — they resolve from the
  /// palette at build time so they track role, brightness and
  /// saturation, which a constant cannot.
  static const AudioStyle defaults = AudioStyle(
    barWidth: AudioDefaults.barWidth,
    barSpacing: AudioDefaults.barSpacing,
    barRadius: AudioDefaults.barRadius,
    waveformHeight: AudioDefaults.waveformHeight,
    showSpeed: true,
    showLoop: true,
    showSkip: true,
    showQueue: true,
    showSleepTimer: false,
    enableKeyboard: true,
    skipSeconds: AudioDefaults.skipSeconds,
    speeds: AudioDefaults.speeds,
    sleepOptions: AudioDefaults.sleepOptions,
    compactHeight: AudioDefaults.compactHeight,
    padding: AudioDefaults.padding,
  );

  // ─── Presets ──────────────────────────────────────────────
  //
  // A preset is a NAMED BAG. Everything it decides — which controls
  // exist, how the bars look — is what `AudioStyle` already carries,
  // so it merges with a theme and loses to a per-call override like
  // any other bag and adds no code path to keep true.

  /// A voice note in a chat bubble.
  ///
  /// Nothing but play and the wave: a message is read at one speed and
  /// heard once, so speed, loop and skip are three controls that would
  /// never be pressed. Thin bars, because the whole thing is 140
  /// points wide.
  static const AudioStyle voiceNote = AudioStyle(
    showSpeed: false,
    showLoop: false,
    showSkip: false,
    barWidth: 2,
    barSpacing: 1.5,
  );

  /// A podcast or an audiobook.
  ///
  /// Speed and skip lead, because those are the two controls that get
  /// used constantly here — and the skip is THIRTY seconds, which is
  /// an ad break rather than a missed word.
  static const AudioStyle spokenWord = AudioStyle(
    showSpeed: true,
    showSkip: true,
    showLoop: false,
    skipSeconds: 30,
    speeds: [0.75, 1, 1.25, 1.5, 1.75, 2],
  );

  /// A track on a music screen.
  ///
  /// Loop matters and speed does not — nobody listens to music at
  /// 1.5×, and a control nobody presses is a control in the way.
  static const AudioStyle music = AudioStyle(
    showLoop: true,
    showSkip: true,
    showSpeed: false,
    barWidth: 3,
    barSpacing: 2,
    waveformHeight: 72,
  );

  /// Played waveform and playhead. Falls back to the palette primary.
  final Color? accent;

  /// Unplayed waveform bars. Falls back to the palette outline.
  final Color? barColor;

  final double? barWidth;
  final double? barSpacing;
  final double? barRadius;
  final double? waveformHeight;

  /// Transport glyphs. Falls back to the palette's primary text.
  final Color? controlsColor;

  final bool? showSpeed;
  final bool? showLoop;
  final bool? showSkip;

  /// Previous / next, and only when there IS a queue — a pair of
  /// arrows over a single clip are two controls that cannot do
  /// anything. On by default for that reason: it costs nothing to a
  /// player that has one track.
  final bool? showQueue;

  /// Off by default, alone among these. A sleep timer belongs to a
  /// podcast app and to nothing else, and a control nobody presses is
  /// a control in the way.
  final bool? showSleepTimer;

  /// Whether the player answers the keyboard.
  ///
  /// On, and safe in a list: focus follows the POINTER, so the keys
  /// reach the player being looked at rather than all fifteen of them.
  /// A page that binds the space bar itself turns this off.
  final bool? enableKeyboard;

  final int? skipSeconds;

  /// What the speed control steps through, in order. It WRAPS, so the
  /// last entry is followed by the first.
  final List<double>? speeds;

  /// What the sleep control steps through, in order.
  final List<Duration>? sleepOptions;

  /// Height of the `compact` variant.
  final double? compactHeight;

  /// Solid surface behind the full variant. Ignored when [gradient] is
  /// set.
  final Color? backgroundColor;

  /// Gradient surface behind the full variant. Wins over
  /// [backgroundColor] when both are given.
  final Gradient? gradient;

  final EdgeInsets? padding;
  final BorderRadius? borderRadius;

  /// Fills the play button instead of the flat accent.
  final Gradient? playButtonGradient;

  /// Pair with [playButtonGradient] for the glow look.
  final List<BoxShadow>? playButtonShadow;

  /// Overrides the clock either side of the timeline.
  final TextStyle? timeTextStyle;

  /// [other] wins field by field. Null means "did not say", which is
  /// what lets a caller override one thing without restating a theme.
  AudioStyle mergedWith(AudioStyle? other) {
    if (other == null) return this;
    return AudioStyle(
      accent: other.accent ?? accent,
      barColor: other.barColor ?? barColor,
      barWidth: other.barWidth ?? barWidth,
      barSpacing: other.barSpacing ?? barSpacing,
      barRadius: other.barRadius ?? barRadius,
      waveformHeight: other.waveformHeight ?? waveformHeight,
      controlsColor: other.controlsColor ?? controlsColor,
      showSpeed: other.showSpeed ?? showSpeed,
      showLoop: other.showLoop ?? showLoop,
      showSkip: other.showSkip ?? showSkip,
      showQueue: other.showQueue ?? showQueue,
      showSleepTimer: other.showSleepTimer ?? showSleepTimer,
      enableKeyboard: other.enableKeyboard ?? enableKeyboard,
      skipSeconds: other.skipSeconds ?? skipSeconds,
      speeds: other.speeds ?? speeds,
      sleepOptions: other.sleepOptions ?? sleepOptions,
      compactHeight: other.compactHeight ?? compactHeight,
      backgroundColor: other.backgroundColor ?? backgroundColor,
      gradient: other.gradient ?? gradient,
      padding: other.padding ?? padding,
      borderRadius: other.borderRadius ?? borderRadius,
      playButtonGradient: other.playButtonGradient ?? playButtonGradient,
      playButtonShadow: other.playButtonShadow ?? playButtonShadow,
      timeTextStyle: other.timeTextStyle ?? timeTextStyle,
    );
  }

  AudioStyle copyWith({
    Color? accent,
    Color? barColor,
    double? barWidth,
    double? barSpacing,
    double? barRadius,
    double? waveformHeight,
    Color? controlsColor,
    bool? showSpeed,
    bool? showLoop,
    bool? showSkip,
    bool? showQueue,
    bool? showSleepTimer,
    bool? enableKeyboard,
    int? skipSeconds,
    List<double>? speeds,
    List<Duration>? sleepOptions,
    double? compactHeight,
    Color? backgroundColor,
    Gradient? gradient,
    EdgeInsets? padding,
    BorderRadius? borderRadius,
    Gradient? playButtonGradient,
    List<BoxShadow>? playButtonShadow,
    TextStyle? timeTextStyle,
  }) => AudioStyle(
    accent: accent ?? this.accent,
    barColor: barColor ?? this.barColor,
    barWidth: barWidth ?? this.barWidth,
    barSpacing: barSpacing ?? this.barSpacing,
    barRadius: barRadius ?? this.barRadius,
    waveformHeight: waveformHeight ?? this.waveformHeight,
    controlsColor: controlsColor ?? this.controlsColor,
    showSpeed: showSpeed ?? this.showSpeed,
    showLoop: showLoop ?? this.showLoop,
    showSkip: showSkip ?? this.showSkip,
    showQueue: showQueue ?? this.showQueue,
    showSleepTimer: showSleepTimer ?? this.showSleepTimer,
    enableKeyboard: enableKeyboard ?? this.enableKeyboard,
    skipSeconds: skipSeconds ?? this.skipSeconds,
    speeds: speeds ?? this.speeds,
    sleepOptions: sleepOptions ?? this.sleepOptions,
    compactHeight: compactHeight ?? this.compactHeight,
    backgroundColor: backgroundColor ?? this.backgroundColor,
    gradient: gradient ?? this.gradient,
    padding: padding ?? this.padding,
    borderRadius: borderRadius ?? this.borderRadius,
    playButtonGradient: playButtonGradient ?? this.playButtonGradient,
    playButtonShadow: playButtonShadow ?? this.playButtonShadow,
    timeTextStyle: timeTextStyle ?? this.timeTextStyle,
  );

  @override
  bool operator ==(Object other) =>
      other is AudioStyle &&
      other.accent == accent &&
      other.barColor == barColor &&
      other.barWidth == barWidth &&
      other.barSpacing == barSpacing &&
      other.barRadius == barRadius &&
      other.waveformHeight == waveformHeight &&
      other.controlsColor == controlsColor &&
      other.showSpeed == showSpeed &&
      other.showLoop == showLoop &&
      other.showSkip == showSkip &&
      other.showQueue == showQueue &&
      other.showSleepTimer == showSleepTimer &&
      other.enableKeyboard == enableKeyboard &&
      other.skipSeconds == skipSeconds &&
      other.compactHeight == compactHeight &&
      other.backgroundColor == backgroundColor &&
      other.gradient == gradient &&
      other.padding == padding &&
      other.borderRadius == borderRadius &&
      other.timeTextStyle == timeTextStyle;

  @override
  int get hashCode => Object.hash(
    accent,
    barColor,
    barWidth,
    barSpacing,
    barRadius,
    waveformHeight,
    controlsColor,
    showSpeed,
    showLoop,
    showSkip,
    showQueue,
    showSleepTimer,
    enableKeyboard,
    skipSeconds,
    compactHeight,
    backgroundColor,
    gradient,
    padding,
    borderRadius,
    timeTextStyle,
  );
}

/// An [AudioStyle] with every question answered.
///
/// Built once per build by `style.resolve(context)`. Nothing downstream
/// takes a nullable field or reaches for `Theme.of` — the widget used
/// to do both, which is how a player ended up drawing `Colors.white`
/// on a light surface.
@immutable
class ResolvedAudioStyle {
  const ResolvedAudioStyle({
    required this.accent,
    required this.barColor,
    required this.barWidth,
    required this.barSpacing,
    required this.barRadius,
    required this.waveformHeight,
    required this.controlsColor,
    required this.surfaceColor,
    required this.showSpeed,
    required this.showLoop,
    required this.showSkip,
    required this.showQueue,
    required this.showSleepTimer,
    required this.enableKeyboard,
    required this.skipSeconds,
    required this.speeds,
    required this.sleepOptions,
    required this.compactHeight,
    required this.padding,
    required this.borderRadius,
    required this.timeTextStyle,
    this.backgroundColor,
    this.gradient,
    this.playButtonGradient,
    this.playButtonShadow,
  });

  final Color accent;
  final Color barColor;
  final double barWidth;
  final double barSpacing;
  final double barRadius;
  final double waveformHeight;
  final Color controlsColor;

  /// What the player is drawn ON — used for the glyph that sits inside
  /// the accent-filled play button, which has to contrast with the
  /// ACCENT rather than with the page.
  final Color surfaceColor;

  final bool showSpeed;
  final bool showLoop;
  final bool showSkip;
  final bool showQueue;
  final bool showSleepTimer;
  final bool enableKeyboard;
  final int skipSeconds;
  final List<double> speeds;
  final List<Duration> sleepOptions;
  final double compactHeight;
  final EdgeInsets padding;
  final BorderRadius borderRadius;
  final TextStyle timeTextStyle;

  final Color? backgroundColor;
  final Gradient? gradient;
  final Gradient? playButtonGradient;
  final List<BoxShadow>? playButtonShadow;

  /// The same bag at a different waveform height.
  ///
  /// The compact and message variants draw a shorter waveform than the
  /// full one, and that is the ONLY thing they change. A `copyWith` on
  /// the resolved bag would invite restating anything; this says the
  /// one thing that varies.
  ResolvedAudioStyle forWaveformHeight(double height) => ResolvedAudioStyle(
    accent: accent,
    barColor: barColor,
    barWidth: barWidth,
    barSpacing: barSpacing,
    barRadius: barRadius,
    waveformHeight: height,
    controlsColor: controlsColor,
    surfaceColor: surfaceColor,
    showSpeed: showSpeed,
    showLoop: showLoop,
    showSkip: showSkip,
    showQueue: showQueue,
    showSleepTimer: showSleepTimer,
    enableKeyboard: enableKeyboard,
    skipSeconds: skipSeconds,
    speeds: speeds,
    sleepOptions: sleepOptions,
    compactHeight: compactHeight,
    padding: padding,
    borderRadius: borderRadius,
    timeTextStyle: timeTextStyle,
    backgroundColor: backgroundColor,
    gradient: gradient,
    playButtonGradient: playButtonGradient,
    playButtonShadow: playButtonShadow,
  );

  /// The next sleep setting after [current], wrapping.
  ///
  /// One control rather than a menu, for the same reason the speed
  /// control is one: this is a chip on a row, and a menu would be a
  /// surface to place, dismiss and theme for four values. The cycle
  /// ends at "end of track" and then at off, so there is always a way
  /// back out by pressing the same thing.
  AudioSleep nextSleep(AudioSleep current) {
    final after = current.after;
    if (after != null) {
      final i = sleepOptions.indexWhere((d) => d == after);
      if (i >= 0 && i + 1 < sleepOptions.length) {
        return AudioSleep.after(sleepOptions[i + 1]);
      }
      return AudioSleep.endOfTrack;
    }
    if (current.atEndOfTrack) return AudioSleep.off;
    if (sleepOptions.isEmpty) return AudioSleep.endOfTrack;
    return AudioSleep.after(sleepOptions.first);
  }

  /// The next speed after [current], wrapping.
  ///
  /// A speed control that stops at the fastest strands anyone who
  /// overshoots. Pure, because it is the one part of the speed control
  /// that can be tested without an engine.
  double nextSpeed(double current) {
    if (speeds.isEmpty) return current;
    final i = speeds.indexWhere((s) => s == current);
    return speeds[(i + 1) % speeds.length];
  }
}

/// The two decisions a scrub makes, without the engine around them.
///
/// Both backends had these inline and identical, and the one that
/// matters — what a tap actually means — could not be tested at all
/// because the states need a real player to build.
abstract final class AudioScrub {
  /// What fraction a scrub is aiming at.
  ///
  /// The waveform's drag-END has no local position (Flutter's
  /// `DragEndDetails` carries none), so it reports `-1` meaning "use
  /// the last value you were given". A tap reports a real fraction.
  /// Anything out of range is clamped rather than refused: a drag that
  /// leaves the widget is a normal thing to do.
  static double target({
    required double reported,
    required double? buffered,
    required double progress,
  }) {
    final raw = reported < 0 ? (buffered ?? progress) : reported;
    return raw.clamp(0.0, 1.0);
  }

  /// Whether a position the platform just reported can be believed.
  ///
  /// After a seek the platform keeps reporting the OLD position for a
  /// few frames — `seek()` resolving means the command was accepted,
  /// not that the clock has moved. Anything that shows every report
  /// then draws the target, the old position, and the target again. At
  /// sixty frames a second that is a flash, reported as exactly that:
  /// "it goes to 10, back to 20 for a split second, then back to 10".
  ///
  /// A report is stale when it is still sitting at [seekFrom] — where
  /// playback was LEFT. Judging it by distance from the target instead
  /// looks equivalent and is not: a moment after landing, playback has
  /// legitimately moved on from the target, and a rule written that way
  /// starts rejecting the truth and freezes the clock until it gives
  /// up.
  ///
  /// [sinceSeek] ends the standoff, because a seek the engine silently
  /// refused must not freeze the clock forever.
  static bool trustReport({
    required Duration reported,
    required Duration? seekTarget,
    required Duration seekFrom,
    required Duration sinceSeek,
  }) {
    if (seekTarget == null) return true;
    if (sinceSeek >= AudioDefaults.seekSettleTimeout) return true;
    // A seek that barely moves has nothing to be confused about — and
    // rejecting reports near its own target would reject all of them.
    if ((seekTarget - seekFrom).abs() <= AudioDefaults.seekSettleTolerance) {
      return true;
    }
    return (reported - seekFrom).abs() > AudioDefaults.seekSettleTolerance;
  }

  /// Whether a reported scrub-end is a seek at all.
  ///
  /// The waveform's `GestureDetector` ends a drag with `-1` — Flutter's
  /// `DragEndDetails` carries no local position — meaning "use the last
  /// value you were given". With nothing buffered there was no drag to
  /// end: the recogniser is cancelling a gesture that never became one,
  /// which happens on every tap, and treating it as a seek issues a
  /// second one to wherever the playhead already is.
  static bool isSeek({required double reported, required double? buffered}) =>
      reported >= 0 || buffered != null;

  /// Where [fraction] lands in a track of [duration].
  static Duration positionFor(double fraction, Duration duration) => Duration(
    milliseconds: (duration.inMilliseconds * fraction.clamp(0.0, 1.0)).round(),
  );
}

/// Plays-state snapshot exposed to UI without leaking just_audio types.
@immutable
class AudioStateSnapshot {
  const AudioStateSnapshot({
    required this.position,
    required this.duration,
    required this.buffered,
    required this.playing,
    required this.loading,
    required this.errored,
    required this.speed,
    required this.looping,
  });

  final Duration position;
  final Duration duration;
  final Duration buffered;
  final bool playing;
  final bool loading;
  final bool errored;
  final double speed;
  final bool looping;
}

/// One entry in a player's queue.
///
/// It carries its own metadata and its own waveform because those are
/// per TRACK, not per player: a queue whose lock-screen title never
/// changed would name the first track for the whole session, and a
/// queue sharing one set of samples would draw the first track's
/// waveform under every one after it.
@immutable
class AudioQueueItem {
  const AudioQueueItem({required this.source, this.nowPlaying, this.samples});

  final AudioSourceSpec source;

  /// What to show outside the app while THIS item plays.
  final AudioNowPlaying? nowPlaying;

  /// Pre-computed amplitudes for this item, if the caller has them.
  final List<double>? samples;
}

/// Where a queue goes next.
///
/// Pure, and separate from the player, because every one of these
/// rules is a decision someone can disagree with and none of them can
/// be tested through an engine that will not start under
/// `flutter_test`.
abstract final class AudioQueue {
  /// The item after [index], or null when there is nowhere to go.
  ///
  /// [wrap] is what an app decides: a playlist someone put on loops,
  /// a set of voice notes does not.
  static int? nextIndex({
    required int index,
    required int count,
    bool wrap = false,
  }) {
    if (count <= 0) return null;
    if (index + 1 < count) return index + 1;
    return wrap && count > 1 ? 0 : null;
  }

  /// The item before [index], or null.
  static int? previousIndex({
    required int index,
    required int count,
    bool wrap = false,
  }) {
    if (count <= 0) return null;
    if (index - 1 >= 0) return index - 1;
    return wrap && count > 1 ? count - 1 : null;
  }

  /// Whether "previous" means THIS track from the top.
  ///
  /// Past [AudioDefaults.previousRestartsAfter] it does. Both meanings
  /// live on one button, and which one someone wanted is answered by
  /// how far in they are.
  static bool previousRestarts(Duration position) =>
      position >= AudioDefaults.previousRestartsAfter;
}

/// When to stop playing on its own.
///
/// Three states in one value rather than a `Duration?` plus a flag:
/// the two cannot both be set, and a pair of fields that must not
/// disagree is a pair of fields that eventually will.
@immutable
class AudioSleep {
  const AudioSleep._(this.after, {this.atEndOfTrack = false});

  /// Nothing armed.
  static const AudioSleep off = AudioSleep._(null);

  /// Stop when the current track finishes.
  static const AudioSleep endOfTrack = AudioSleep._(null, atEndOfTrack: true);

  /// Stop after a wall-clock delay.
  const AudioSleep.after(Duration this.after) : atEndOfTrack = false;

  /// How long from arming, or null.
  final Duration? after;

  /// Whether this waits for the track to end rather than a clock.
  ///
  /// It is not a countdown: a clock set to "the rest of this" would be
  /// wrong the moment anyone seeked.
  final bool atEndOfTrack;

  /// Whether anything will stop playback.
  bool get isArmed => after != null || atEndOfTrack;

  @override
  bool operator ==(Object other) =>
      other is AudioSleep &&
      other.after == after &&
      other.atEndOfTrack == atEndOfTrack;

  @override
  int get hashCode => Object.hash(after, atEndOfTrack);

  @override
  String toString() => after != null
      ? 'AudioSleep.after($after)'
      : (atEndOfTrack ? 'AudioSleep.endOfTrack' : 'AudioSleep.off');
}
