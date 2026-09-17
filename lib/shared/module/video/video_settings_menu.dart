import 'package:media_kit/media_kit.dart';

import '../../../core/localization/strings/module_strings.dart';
import '../popup/popup.dart';
import 'video_models.dart';

/// What the settings menu OFFERS and what a choice from it MEANS.
///
/// Lifted out of `VideoControls` because both halves are pure — the
/// items are a function of what the track has, and applying one is a
/// dispatch on its value — while the widget around them cannot be
/// built under `flutter_test` at all. This is the part of the menu that
/// can be tested, so it is the part that is separable.
///
/// Values are prefixed strings rather than a sealed type because
/// `GlobalPopupMenuItem` is generic over the value and the popup
/// returns it verbatim; the prefixes are the only contract between the
/// two halves, and they are checked in both directions by the tests.
class VideoSettings {
  const VideoSettings._();

  /// Speed values carry their rate: `sp_1.5`.
  static const speedPrefix = 'sp_';

  /// Audio values carry the track id: `au_2`.
  static const audioPrefix = 'au_';

  /// Video-track values carry the track id: `vid_1`.
  static const videoPrefix = 'vid_';

  /// Subtitle values carry the track id: `sub_3`.
  static const subtitlePrefix = 'sub_';

  /// Turning subtitles off, which is not a track.
  static const subtitlesOff = 'sub_off';

  /// The menu for a track, or an EMPTY list when it has nothing to
  /// offer — which is what disables the gear rather than opening a
  /// blank sheet.
  ///
  /// `auto` and `no` are dropped from both track lists. They are
  /// libmpv's placeholders, not things to choose, and counting them is
  /// what would make a file with one audio track look like it had
  /// three.
  /// Takes the three flags it needs rather than the whole
  /// `ResolvedVideoStyle`: that bag has no `copyWith` and forty-odd
  /// required fields, so asking for it would make this untestable —
  /// which is the reason the logic was lifted out here at all.
  static List<GlobalPopupMenuItem<String>> itemsFor({
    required bool showSpeedButton,
    required bool showTrackSelector,
    required List<PlaybackSpeed> speeds,
    required double rate,
    required List<AudioTrack> audioTracks,
    required List<SubtitleTrack> subtitleTracks,
    List<VideoTrack> videoTracks = const [],
    AudioTrack? currentAudioTrack,
    SubtitleTrack? currentSubtitleTrack,
    VideoTrack? currentVideoTrack,
  }) {
    final items = <GlobalPopupMenuItem<String>>[];

    if (showSpeedButton) {
      items.add(
        GlobalPopupMenuItem<String>.section(VideoStrings.playbackSpeed),
      );
      for (final sp in speeds) {
        items.add(
          GlobalPopupMenuItem<String>(
            value: '$speedPrefix${sp.rate}',
            label: sp.label,
            toggled: rate == sp.rate,
          ),
        );
      }
    }

    // Quality first: it is the one people open this menu looking for.
    final video = videoTracks.where((t) => isRealTrackId(t.id));
    if (showTrackSelector && video.length > 1) {
      if (items.isNotEmpty) items.add(GlobalPopupMenuItem<String>.divider());
      items.add(GlobalPopupMenuItem<String>.section(VideoStrings.quality));
      for (final t in video) {
        items.add(
          GlobalPopupMenuItem<String>(
            value: '$videoPrefix${t.id}',
            label: describeVideoTrack(t),
            toggled: currentVideoTrack?.id == t.id,
          ),
        );
      }
    }

    final audio = audioTracks.where((t) => isRealTrackId(t.id));
    // One track is not a choice, so it is not offered.
    if (showTrackSelector && audio.length > 1) {
      if (items.isNotEmpty) items.add(GlobalPopupMenuItem<String>.divider());
      items.add(GlobalPopupMenuItem<String>.section(VideoStrings.audioTrack));
      for (final t in audio) {
        items.add(
          GlobalPopupMenuItem<String>(
            value: '$audioPrefix${t.id}',
            label: t.title ?? t.language ?? t.id,
            toggled: currentAudioTrack?.id == t.id,
          ),
        );
      }
    }

    // REAL tracks, not `subtitleTracks.isNotEmpty`: `auto` and `no`
    // are on every file, so that offered a Subtitles section holding
    // nothing but the Off it was already on.
    final subtitles = subtitleTracks.where((t) => isRealTrackId(t.id));
    if (showTrackSelector && subtitles.isNotEmpty) {
      if (items.isNotEmpty) items.add(GlobalPopupMenuItem<String>.divider());
      items.add(GlobalPopupMenuItem<String>.section(VideoStrings.subtitles));
      // Off leads, and it is selected when the current track is one of
      // libmpv's placeholders — those mean "nothing chosen", not a
      // subtitle the reader picked.
      final off =
          currentSubtitleTrack == null ||
          !isRealTrackId(currentSubtitleTrack.id);
      items.add(
        GlobalPopupMenuItem<String>(
          value: subtitlesOff,
          label: VideoStrings.off,
          toggled: off,
        ),
      );
      for (final t in subtitles) {
        items.add(
          GlobalPopupMenuItem<String>(
            value: '$subtitlePrefix${t.id}',
            label: t.title ?? t.language ?? t.id,
            toggled: currentSubtitleTrack?.id == t.id,
          ),
        );
      }
    }

    return items;
  }

  /// Chapter values carry the INDEX: `chap_2`.
  static const chapterPrefix = 'chap_';

  /// Sleep values carry minutes, or `off` / `end`.
  static const sleepPrefix = 'sleep_';

  /// Subtitle-delay values carry a direction: `-`, `+`, or `0`.
  static const subtitleOffsetPrefix = 'suboff_';

  /// Jump straight to a chapter.
  ///
  /// The caller decides whether to ask at all — an empty section is a
  /// promise the film cannot keep, and a list of chapters is not a
  /// glyph, which is why this is a menu and not a bar control.
  static List<GlobalPopupMenuItem<String>> chapterItems({
    required List<VideoChapter> chapters,
    VideoChapter? current,
  }) {
    if (chapters.isEmpty) return const [];
    return [
      GlobalPopupMenuItem<String>.section(VideoStrings.chapters),
      for (var i = 0; i < chapters.length; i++)
        GlobalPopupMenuItem<String>(
          value: '$chapterPrefix$i',
          label:
              '${formatVideoDuration(chapters[i].start)}  '
              '${chapters[i].title}',
          toggled: identical(chapters[i], current),
        ),
      GlobalPopupMenuItem<String>.divider(),
    ];
  }

  /// Stop after a while, or at the end of this video.
  static List<GlobalPopupMenuItem<String>> sleepTimerItems({
    required bool running,
    required bool atEnd,
  }) => [
    GlobalPopupMenuItem<String>.section(VideoStrings.sleepTimer),
    GlobalPopupMenuItem<String>(
      value: '${sleepPrefix}off',
      label: VideoStrings.sleepOff,
      toggled: !running,
    ),
    for (final minutes in VideoDefaults.sleepTimerMinutes)
      GlobalPopupMenuItem<String>(
        value: '$sleepPrefix$minutes',
        label: VideoStrings.sleepMinutes(minutes),
      ),
    GlobalPopupMenuItem<String>(
      value: '${sleepPrefix}end',
      label: VideoStrings.sleepAtEnd,
      toggled: atEnd,
    ),
    GlobalPopupMenuItem<String>.divider(),
  ];

  /// Nudge the subtitles earlier or later.
  static List<GlobalPopupMenuItem<String>> subtitleOffsetItems({
    required Duration offset,
  }) => [
    GlobalPopupMenuItem<String>.section(
      // The current offset goes in the HEADING rather than beside each
      // button: it is one value, and repeating it three times is three
      // places for it to be wrong.
      offset == Duration.zero
          ? VideoStrings.subtitleDelay
          : '${VideoStrings.subtitleDelay}  '
                '${offset.isNegative ? '-' : '+'}'
                '${formatVideoDuration(offset.abs())}',
    ),
    GlobalPopupMenuItem<String>(
      value: '$subtitleOffsetPrefix-',
      label: VideoStrings.subtitleEarlier,
    ),
    GlobalPopupMenuItem<String>(
      value: '$subtitleOffsetPrefix+',
      label: VideoStrings.subtitleLater,
    ),
    GlobalPopupMenuItem<String>(
      value: '${subtitleOffsetPrefix}0',
      label: VideoStrings.subtitleInSync,
      toggled: offset == Duration.zero,
    ),
    GlobalPopupMenuItem<String>.divider(),
  ];

  /// Subtitle values carry a direction: `-`, `+`, or `0`.
  static const subtitleSizePrefix = 'subsize_';

  /// Make the subtitles bigger or smaller.
  ///
  /// Separate from the delay even though both are a pair of nudges and
  /// a reset: one is about whether they can be READ and the other
  /// about whether they are in TIME with the film. A reader reaching
  /// for one is not reaching for the other.
  static List<GlobalPopupMenuItem<String>> subtitleSizeItems({
    required double scale,
  }) => [
    GlobalPopupMenuItem<String>.section(
      scale == 1
          ? VideoStrings.subtitleSize
          : '${VideoStrings.subtitleSize}  ${(scale * 100).round()}%',
    ),
    GlobalPopupMenuItem<String>(
      value: '$subtitleSizePrefix-',
      label: VideoStrings.subtitleSmaller,
      enabled: scale > VideoDefaults.subtitleScaleMin,
    ),
    GlobalPopupMenuItem<String>(
      value: '$subtitleSizePrefix+',
      label: VideoStrings.subtitleLarger,
      enabled: scale < VideoDefaults.subtitleScaleMax,
    ),
    GlobalPopupMenuItem<String>(
      value: '${subtitleSizePrefix}0',
      label: VideoStrings.subtitleNormalSize,
      toggled: scale == 1,
    ),
    GlobalPopupMenuItem<String>.divider(),
  ];

  /// Runs the choice [value] against [player].
  ///
  /// Every call goes through [run] rather than awaiting the player
  /// directly, so the caller keeps its "is the engine still alive"
  /// guard in one place — a menu selection can land after the widget
  /// has gone.
  static void apply(
    String value, {
    required Player player,
    required List<AudioTrack> audioTracks,
    required List<SubtitleTrack> subtitleTracks,
    required void Function(Future<void> Function() action) run,
    List<VideoTrack> videoTracks = const [],
  }) {
    if (value.startsWith(speedPrefix)) {
      final rate = double.tryParse(value.substring(speedPrefix.length));
      if (rate != null) run(() => player.setRate(rate));
      return;
    }
    if (value.startsWith(videoPrefix)) {
      final id = value.substring(videoPrefix.length);
      final track = videoTracks.firstWhere(
        (t) => t.id == id,
        orElse: VideoTrack.auto,
      );
      run(() => player.setVideoTrack(track));
      return;
    }
    if (value.startsWith(audioPrefix)) {
      final id = value.substring(audioPrefix.length);
      final track = audioTracks.firstWhere(
        (t) => t.id == id,
        orElse: AudioTrack.auto,
      );
      run(() => player.setAudioTrack(track));
      return;
    }
    // Before the general subtitle prefix, which also matches it.
    //
    // Both orders happen to end at `SubtitleTrack.no` — the other one
    // by failing a lookup for a track called "off" and taking the
    // fallback — so this is directness rather than a fixed bug, and no
    // test can tell them apart.
    if (value == subtitlesOff) {
      run(() => player.setSubtitleTrack(SubtitleTrack.no()));
      return;
    }
    if (value.startsWith(subtitlePrefix)) {
      final id = value.substring(subtitlePrefix.length);
      final track = subtitleTracks.firstWhere(
        (t) => t.id == id,
        orElse: SubtitleTrack.no,
      );
      run(() => player.setSubtitleTrack(track));
    }
  }

  /// What a video track is CALLED in the menu.
  ///
  /// mpv gives a title only sometimes, so the height is the fallback —
  /// "720p" is what a reader is looking for, and the raw id ("2") says
  /// nothing about quality at all.
  static String describeVideoTrack(VideoTrack track) {
    final height = track.h;
    if (height != null && height > 0) return '${height}p';
    return track.title ?? track.language ?? track.id;
  }

  /// `auto` and `no` are libmpv's placeholders, not choices.
  ///
  /// Keyed on the id because `AudioTrack` and `SubtitleTrack` share no
  /// supertype that carries one.
  static bool isRealTrackId(String id) => id != 'auto' && id != 'no';
}
