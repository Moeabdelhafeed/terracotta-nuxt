import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';

import '../../../../core/extensions/theme_colors_extension.dart';
import '../video_models.dart';

/// App-wide defaults for [GlobalVideo].
///
/// The rebrand hook: set the seek-bar accent, the glyph set and which
/// chrome every player in the app offers, once, here.
@immutable
class GlobalVideoTheme extends ThemeExtension<GlobalVideoTheme> {
  const GlobalVideoTheme({this.style});

  final VideoStyle? style;

  static GlobalVideoTheme? maybeOf(BuildContext context) =>
      Theme.of(context).extension<GlobalVideoTheme>();

  @override
  GlobalVideoTheme copyWith({VideoStyle? style}) =>
      GlobalVideoTheme(style: style ?? this.style);

  @override
  GlobalVideoTheme lerp(ThemeExtension<GlobalVideoTheme>? other, double t) {
    if (other is! GlobalVideoTheme) return this;
    return GlobalVideoTheme(style: _lerpStyle(style, other.style, t));
  }

  /// Continuous fields interpolate; discrete ones snap at the midpoint.
  ///
  /// Half a fullscreen button is not a glyph, and a control that is
  /// half-offered is not a control — those are picked, not blended.
  static VideoStyle? _lerpStyle(VideoStyle? a, VideoStyle? b, double t) {
    if (a == null && b == null) return null;
    final pick = t < 0.5 ? a : b;
    return VideoStyle(
      borderRadius: BorderRadius.lerp(a?.borderRadius, b?.borderRadius, t),
      backgroundColor: Color.lerp(a?.backgroundColor, b?.backgroundColor, t),
      boxShadow: BoxShadow.lerpList(a?.boxShadow, b?.boxShadow, t),
      iconColor: Color.lerp(a?.iconColor, b?.iconColor, t),
      iconSize: lerpDouble(a?.iconSize, b?.iconSize, t),
      playIconSize: lerpDouble(a?.playIconSize, b?.playIconSize, t),
      activeColor: Color.lerp(a?.activeColor, b?.activeColor, t),
      bufferedColor: Color.lerp(a?.bufferedColor, b?.bufferedColor, t),
      trackColor: Color.lerp(a?.trackColor, b?.trackColor, t),
      thumbColor: Color.lerp(a?.thumbColor, b?.thumbColor, t),
      thumbRadius: lerpDouble(a?.thumbRadius, b?.thumbRadius, t),
      progressBarHeight: lerpDouble(
        a?.progressBarHeight,
        b?.progressBarHeight,
        t,
      ),
      scrimColor: Color.lerp(a?.scrimColor, b?.scrimColor, t),
      timeLabelStyle: TextStyle.lerp(a?.timeLabelStyle, b?.timeLabelStyle, t),
      titleStyle: TextStyle.lerp(a?.titleStyle, b?.titleStyle, t),
      subtitleStyle: TextStyle.lerp(a?.subtitleStyle, b?.subtitleStyle, t),
      subtitleBackground: Color.lerp(
        a?.subtitleBackground,
        b?.subtitleBackground,
        t,
      ),
      subtitlePadding: EdgeInsets.lerp(
        a?.subtitlePadding,
        b?.subtitlePadding,
        t,
      ),
      bottomBarPadding: EdgeInsets.lerp(
        a?.bottomBarPadding,
        b?.bottomBarPadding,
        t,
      ),
      topBarPadding: EdgeInsets.lerp(a?.topBarPadding, b?.topBarPadding, t),
      gradientHeight: lerpDouble(a?.gradientHeight, b?.gradientHeight, t),
      longPressSpeedRate: lerpDouble(
        a?.longPressSpeedRate,
        b?.longPressSpeedRate,
        t,
      ),
      playIcon: pick?.playIcon,
      pauseIcon: pick?.pauseIcon,
      replayIcon: pick?.replayIcon,
      fullscreenIcon: pick?.fullscreenIcon,
      exitFullscreenIcon: pick?.exitFullscreenIcon,
      muteIcon: pick?.muteIcon,
      unmuteIcon: pick?.unmuteIcon,
      settingsIcon: pick?.settingsIcon,
      fadeInDuration: pick?.fadeInDuration,
      fadeOutDuration: pick?.fadeOutDuration,
      autoHideDelay: pick?.autoHideDelay,
      showControls: pick?.showControls,
      showFullscreenButton: pick?.showFullscreenButton,
      showMuteButton: pick?.showMuteButton,
      showSpeedButton: pick?.showSpeedButton,
      showSeekButtons: pick?.showSeekButtons,
      showTrackSelector: pick?.showTrackSelector,
      showScreenshotButton: pick?.showScreenshotButton,
      speeds: pick?.speeds,
      seekDuration: pick?.seekDuration,
      enableDoubleTapSeek: pick?.enableDoubleTapSeek,
      doubleTapSeekDuration: pick?.doubleTapSeekDuration,
      enableSwipeGestures: pick?.enableSwipeGestures,
      enableLongPressSpeed: pick?.enableLongPressSpeed,
      enableThumbnailPreview: pick?.enableThumbnailPreview,
      enableHorizontalDragSeek: pick?.enableHorizontalDragSeek,
      pauseOnOffscreen: pick?.pauseOnOffscreen,
      pipOnOffscreen: pick?.pipOnOffscreen,
      respectReducedMotion: pick?.respectReducedMotion,
    );
  }
}

/// `caller > theme > defaults`, then colours.
extension VideoStyleResolve on VideoStyle {
  ResolvedVideoStyle resolve(BuildContext context) {
    final merged = VideoStyle.defaults
        .mergedWith(GlobalVideoTheme.maybeOf(context)?.style)
        .mergedWith(this);
    const floor = VideoStyle.defaults;

    // The controls float over ARBITRARY pixels — a frame of film, not a
    // surface this app painted — so they do NOT take the palette's text
    // colours. White on a scrim is the only pairing that holds over
    // both a snowfield and a night scene, which is why every player
    // ever shipped uses it. The ACCENT is the exception: it is brand,
    // it sits on the same scrim, and it is what a rebrand wants to
    // change.
    final primary = context.primaryColors;

    return ResolvedVideoStyle(
      borderRadius: merged.borderRadius,
      backgroundColor: merged.backgroundColor ?? Colors.black,
      boxShadow: merged.boxShadow,
      iconColor: merged.iconColor ?? Colors.white,
      iconSize: merged.iconSize ?? floor.iconSize!,
      playIconSize: merged.playIconSize ?? floor.playIconSize!,
      activeColor: merged.activeColor ?? primary.primary,
      bufferedColor:
          merged.bufferedColor ??
          Colors.white.withValues(alpha: VideoDefaults.bufferedOpacity),
      trackColor:
          merged.trackColor ??
          Colors.white.withValues(alpha: VideoDefaults.trackOpacity),
      thumbColor: merged.thumbColor ?? merged.activeColor ?? primary.primary,
      thumbRadius: merged.thumbRadius ?? floor.thumbRadius!,
      progressBarHeight: merged.progressBarHeight ?? floor.progressBarHeight!,
      scrimColor:
          merged.scrimColor ??
          Colors.black.withValues(alpha: VideoDefaults.badgeScrimOpacity),
      timeLabelStyle: merged.timeLabelStyle,
      titleStyle: merged.titleStyle,
      subtitleStyle: merged.subtitleStyle,
      subtitleBackground:
          merged.subtitleBackground ??
          Colors.black.withValues(alpha: VideoDefaults.subtitleScrimOpacity),
      subtitlePadding: merged.subtitlePadding ?? floor.subtitlePadding!,
      bottomBarPadding: merged.bottomBarPadding ?? floor.bottomBarPadding!,
      topBarPadding: merged.topBarPadding ?? floor.topBarPadding!,
      gradientHeight: merged.gradientHeight ?? floor.gradientHeight!,
      playIcon: merged.playIcon ?? floor.playIcon!,
      pauseIcon: merged.pauseIcon ?? floor.pauseIcon!,
      replayIcon: merged.replayIcon ?? floor.replayIcon!,
      fullscreenIcon: merged.fullscreenIcon ?? floor.fullscreenIcon!,
      exitFullscreenIcon:
          merged.exitFullscreenIcon ?? floor.exitFullscreenIcon!,
      muteIcon: merged.muteIcon ?? floor.muteIcon!,
      unmuteIcon: merged.unmuteIcon ?? floor.unmuteIcon!,
      settingsIcon: merged.settingsIcon ?? floor.settingsIcon!,
      fadeInDuration: merged.fadeInDuration ?? floor.fadeInDuration!,
      fadeOutDuration: merged.fadeOutDuration ?? floor.fadeOutDuration!,
      autoHideDelay: merged.autoHideDelay ?? floor.autoHideDelay!,
      showControls: merged.showControls ?? floor.showControls!,
      showFullscreenButton:
          merged.showFullscreenButton ?? floor.showFullscreenButton!,
      showMuteButton: merged.showMuteButton ?? floor.showMuteButton!,
      showSpeedButton: merged.showSpeedButton ?? floor.showSpeedButton!,
      showSeekButtons: merged.showSeekButtons ?? floor.showSeekButtons!,
      showTrackSelector: merged.showTrackSelector ?? floor.showTrackSelector!,
      showScreenshotButton:
          merged.showScreenshotButton ?? floor.showScreenshotButton!,
      speeds: merged.speeds ?? floor.speeds!,
      seekDuration: merged.seekDuration ?? floor.seekDuration!,
      enableDoubleTapSeek:
          merged.enableDoubleTapSeek ?? floor.enableDoubleTapSeek!,
      keepScreenAwake: merged.keepScreenAwake ?? floor.keepScreenAwake!,
      enableKeyboardShortcuts:
          merged.enableKeyboardShortcuts ?? floor.enableKeyboardShortcuts!,
      autoPlayNext: merged.autoPlayNext ?? floor.autoPlayNext!,
      showSpeedCycler: merged.showSpeedCycler ?? floor.showSpeedCycler!,
      showSubtitleToggle:
          merged.showSubtitleToggle ?? floor.showSubtitleToggle!,
      showChapterList: merged.showChapterList ?? floor.showChapterList!,
      showReplayButton: merged.showReplayButton ?? floor.showReplayButton!,
      showZoomToggle: merged.showZoomToggle ?? floor.showZoomToggle!,
      showSleepTimer: merged.showSleepTimer ?? floor.showSleepTimer!,
      showAbLoop: merged.showAbLoop ?? floor.showAbLoop!,
      showSubtitleOffset:
          merged.showSubtitleOffset ?? floor.showSubtitleOffset!,
      transportPlacement:
          merged.transportPlacement ?? floor.transportPlacement!,
      clockPlacement: merged.clockPlacement ?? floor.clockPlacement!,
      doubleTapSeekDuration:
          merged.doubleTapSeekDuration ?? floor.doubleTapSeekDuration!,
      enableSwipeGestures:
          merged.enableSwipeGestures ?? floor.enableSwipeGestures!,
      enableLongPressSpeed:
          merged.enableLongPressSpeed ?? floor.enableLongPressSpeed!,
      longPressSpeedRate:
          merged.longPressSpeedRate ?? floor.longPressSpeedRate!,
      enableThumbnailPreview:
          merged.enableThumbnailPreview ?? floor.enableThumbnailPreview!,
      enableHorizontalDragSeek:
          merged.enableHorizontalDragSeek ?? floor.enableHorizontalDragSeek!,
      pauseOnOffscreen: merged.pauseOnOffscreen ?? floor.pauseOnOffscreen!,
      pipOnOffscreen: merged.pipOnOffscreen ?? floor.pipOnOffscreen!,
      respectReducedMotion:
          merged.respectReducedMotion ?? floor.respectReducedMotion!,
    );
  }
}
