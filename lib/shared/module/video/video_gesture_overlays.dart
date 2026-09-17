import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../../core/extensions/context_extensions.dart';
import '../../../core/localization/strings/module_strings.dart';
import '../progress/global_progress.dart';
import 'video_models.dart';

/// What a gesture on the film LOOKS like while it is happening.
///
/// Five badges, all of them transient, all of them driven by state the
/// gesture handlers own: the double-tap ripple, the long-press speed
/// pill, the volume / brightness column, the scrub clock and the
/// thumbnail. They lived inline in `VideoControls.build`, which is how
/// that method reached 787 lines.
///
/// Every one takes its numbers rather than reading them: `scale` comes
/// from `ResolvedVideoStyle.scaleFor(height)` and is applied to every
/// size here, because a badge on a list-cell player and one filling a
/// tablet cannot be the same 18 points.

/// The rewind / forward wash a double-tap leaves behind.
class VideoSeekRipple extends StatelessWidget {
  const VideoSeekRipple({
    required this.animation,
    required this.seconds,
    required this.isLeft,
    required this.style,
    required this.scale,
    required this.width,
    super.key,
  });

  final Animation<double> animation;

  /// How far the taps have seeked so far. Repeated taps accumulate, so
  /// this counts up while the ripple is still on screen.
  final int seconds;

  final bool isLeft;
  final ResolvedVideoStyle style;
  final double scale;

  /// The player's width — the wash covers 40% of it, from one edge.
  final double width;

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: animation,
    builder: (_, _) => Positioned(
      left: isLeft ? 0 : null,
      right: isLeft ? null : 0,
      top: 0,
      bottom: 0,
      width: width * 0.4,
      child: Opacity(
        opacity: animation.value,
        child: Container(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: isLeft ? Alignment.centerLeft : Alignment.centerRight,
              radius: 0.8,
              colors: [style.trackColor, Colors.transparent],
            ),
          ),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isLeft
                      ? Icons.fast_rewind_rounded
                      : Icons.fast_forward_rounded,
                  color: style.iconColor,
                  size: 24 * scale,
                ),
                SizedBox(height: 2 * scale),
                Text(
                  '${seconds.abs()}s',
                  style: TextStyle(
                    color: style.iconColor,
                    fontSize:
                        (context.textTheme.labelSmall?.fontSize ?? 11) * scale,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

/// The pill saying the film is running fast while a finger is held.
class VideoSpeedBadge extends StatelessWidget {
  const VideoSpeedBadge({
    required this.rate,
    required this.style,
    required this.scale,
    required this.top,
    super.key,
  });

  final double rate;
  final ResolvedVideoStyle style;
  final double scale;

  /// How far down to sit.
  ///
  /// It was a flat `8 * scale`, which put it behind the title while the
  /// chrome was up — so holding to speed up looked like it had done
  /// nothing. The caller passes the top bar's height when the bar is
  /// showing.
  final double top;

  @override
  Widget build(BuildContext context) => Positioned(
    top: top,
    left: 0,
    right: 0,
    child: Center(
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: VideoDefaults.badgePaddingH * scale,
          vertical: VideoDefaults.badgePaddingV * scale,
        ),
        decoration: BoxDecoration(
          color: style.scrimColor,
          borderRadius: BorderRadius.circular(
            VideoDefaults.speedBadgeRadius * scale,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.fast_forward_rounded,
              color: style.iconColor,
              size: 14 * scale,
            ),
            SizedBox(width: VideoDefaults.badgePaddingV * scale),
            Text(
              '${rate}x',
              style: TextStyle(
                color: style.iconColor,
                fontSize:
                    (context.textTheme.labelSmall?.fontSize ?? 11) * scale,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

/// The volume / brightness column a vertical swipe drives.
///
/// It stands on the side the gesture is about — volume on the right,
/// brightness on the left — and INSIDE the housing inset, because in
/// fullscreen the notch is on one of those edges.
class VideoLevelBadge extends StatelessWidget {
  const VideoLevelBadge({
    required this.isVolume,
    required this.value,
    required this.style,
    required this.scale,
    required this.height,
    required this.safePadding,
    super.key,
  });

  final bool isVolume;

  /// 0–100. The bar reads it as a fraction, the label as a percentage.
  final double value;

  final ResolvedVideoStyle style;
  final double scale;

  /// The player's height — the bar takes 35% of it.
  final double height;

  final EdgeInsets safePadding;

  @override
  Widget build(BuildContext context) => Positioned(
    top: 0,
    bottom: 0,
    left: isVolume ? null : (12 + safePadding.left),
    right: isVolume ? (12 + safePadding.right) : null,
    child: Center(
      child: Container(
        width: 36 * scale,
        padding: EdgeInsets.symmetric(
          vertical: VideoDefaults.badgePaddingH * scale,
        ),
        decoration: BoxDecoration(
          color: style.scrimColor,
          borderRadius: BorderRadius.circular(
            VideoDefaults.badgeRadius * scale,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isVolume ? Icons.volume_up_rounded : Icons.brightness_6_rounded,
              color: style.iconColor,
              size: 18 * scale,
            ),
            SizedBox(height: VideoDefaults.badgeGap * scale),
            SizedBox(
              width: VideoDefaults.badgePaddingV * scale,
              height: height * 0.35,
              child: CustomPaint(
                painter: VideoLevelBarPainter(
                  value: value / 100,
                  activeColor: style.iconColor,
                  bgColor: style.trackColor,
                ),
              ),
            ),
            SizedBox(height: VideoDefaults.badgeGap * scale),
            SizedBox(
              width: 32 * scale,
              child: Text(
                '${value.round()}%',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: style.iconColor,
                  fontSize:
                      (context.textTheme.labelSmall?.fontSize ?? 11) * scale,
                  fontWeight: FontWeight.w600,
                  // Otherwise the column jitters as the digits change.
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

/// The clock a horizontal scrub shows: where it lands, and by how much.
class VideoSeekBadge extends StatelessWidget {
  const VideoSeekBadge({
    required this.startMs,
    required this.currentMs,
    required this.style,
    required this.scale,
    super.key,
  });

  /// Where the finger went down, and where it is now.
  final double startMs;
  final double currentMs;

  final ResolvedVideoStyle style;
  final double scale;

  @override
  Widget build(BuildContext context) {
    final delta =
        Duration(milliseconds: currentMs.toInt()) -
        Duration(milliseconds: startMs.toInt());
    final sign = delta.isNegative ? '-' : '+';
    final magnitude = delta.isNegative ? -delta : delta;

    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      bottom: 0,
      child: Center(
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: 16 * scale,
            vertical: VideoDefaults.badgePaddingH * scale,
          ),
          decoration: BoxDecoration(
            color: style.scrimColor,
            borderRadius: BorderRadius.circular(
              VideoDefaults.seekBadgeRadius * scale,
            ),
          ),
          // The sign leads, and bidi would move it: `-` and `+` are
          // neutrals, so an RTL paragraph puts them on the far side of
          // the clock they belong to.
          child: Directionality(
            textDirection: TextDirection.ltr,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  formatVideoDuration(
                    Duration(milliseconds: currentMs.toInt()),
                  ),
                  style: TextStyle(
                    color: style.iconColor,
                    fontSize:
                        (context.textTheme.titleLarge?.fontSize ?? 20) * scale,
                    fontWeight: FontWeight.w700,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
                SizedBox(height: VideoDefaults.badgePaddingV * scale),
                Text(
                  '$sign${formatVideoDuration(magnitude)}',
                  style: TextStyle(
                    color: delta.isNegative
                        ? Colors.redAccent
                        : Colors.greenAccent,
                    fontSize:
                        (context.textTheme.bodySmall?.fontSize ?? 12) * scale,
                    fontWeight: FontWeight.w600,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// The frame under the scrub, with its timestamp.
///
/// It rides the seek fraction and is CLAMPED to the player's edges, so
/// near either end it stops following rather than hanging off the side.
class VideoThumbnailPreview extends StatelessWidget {
  const VideoThumbnailPreview({
    required this.bytes,
    required this.thumbnailMs,
    required this.seekMs,
    required this.duration,
    required this.style,
    required this.scale,
    required this.width,
    required this.barPadding,
    super.key,
  });

  /// Null while the frame is still being fetched — a scrub preview is a
  /// network round trip, so the plate shows a spinner rather than
  /// nothing.
  final Uint8List? bytes;

  /// The time the FRAME is of, which lags the finger by a debounce.
  final double thumbnailMs;

  /// Where the finger is, which is what the plate follows.
  final double seekMs;

  final Duration duration;
  final ResolvedVideoStyle style;
  final double scale;

  /// The player's width.
  final double width;

  /// Where the SEEK BAR actually is — the bottom bar's own padding,
  /// including the housing inset in fullscreen.
  ///
  /// It used to assume a symmetric `12 * scale`, which is true inline
  /// and wrong in fullscreen: the bar is inset by up to 62 points on
  /// the notch side, so the plate drifted that far from the point
  /// under the finger. The `bottom` is the bar's height, for the same
  /// reason.
  final EdgeInsets barPadding;

  @override
  Widget build(BuildContext context) {
    final plateWidth = VideoDefaults.thumbnailWidth * scale;
    final total = duration.inMilliseconds.toDouble();
    final fraction = total > 0 ? (seekMs / total).clamp(0.0, 1.0) : 0.5;
    final available = width - barPadding.left - barPadding.right;
    final ideal = barPadding.left + available * fraction - plateWidth / 2;
    // Clamped so it stops following near either end rather than hanging
    // off the side. `clampDouble` order matters when the player is
    // narrower than the plate — the max can fall below the min.
    final maxLeft = width - plateWidth - barPadding.right;
    final left = maxLeft <= barPadding.left
        ? (width - plateWidth) / 2
        : ideal.clamp(barPadding.left, maxLeft);

    return Positioned(
      bottom: barPadding.bottom,
      left: left,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(
            VideoDefaults.thumbnailRadius * scale,
          ),
          boxShadow: [BoxShadow(color: style.scrimColor, blurRadius: 6)],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (bytes != null)
              Image.memory(
                bytes!,
                width: plateWidth,
                height: plateWidth * 9 / 16,
                fit: BoxFit.cover,
                // Holds the last frame while the next one decodes,
                // instead of blinking on every debounce.
                gaplessPlayback: true,
                errorBuilder: (_, _, _) =>
                    SizedBox(width: plateWidth, height: plateWidth * 9 / 16),
              )
            else
              Container(
                width: plateWidth,
                height: plateWidth * 9 / 16,
                color: style.scrimColor,
                child: Center(
                  child: SizedBox(
                    width: 16,
                    height: 16,
                    child: GlobalProgress.loading(
                      type: ProgressType.circular,
                      style: ProgressStyle(
                        thickness: 2,
                        color: style.iconColor.withValues(alpha: 0.54),
                      ),
                    ),
                  ),
                ),
              ),
            Container(
              width: plateWidth,
              padding: EdgeInsets.symmetric(vertical: 3 * scale),
              color: style.scrimColor.withValues(alpha: 0.87),
              child: Text(
                formatVideoDuration(
                  Duration(milliseconds: thumbnailMs.toInt()),
                ),
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: style.iconColor,
                  fontSize:
                      (context.textTheme.labelSmall?.fontSize ?? 11) * scale,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Paints a vertical bar that fills from the BOTTOM.
class VideoLevelBarPainter extends CustomPainter {
  VideoLevelBarPainter({
    required this.value,
    required this.activeColor,
    required this.bgColor,
  });

  final double value;
  final Color activeColor;
  final Color bgColor;

  @override
  void paint(Canvas canvas, Size size) {
    final r = size.width / 2;
    canvas.drawRRect(
      RRect.fromRectAndRadius(Offset.zero & size, Radius.circular(r)),
      Paint()..color = bgColor,
    );
    final activeHeight = size.height * value.clamp(0.0, 1.0);
    if (activeHeight > 0) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(
            0,
            size.height - activeHeight,
            size.width,
            activeHeight,
          ),
          Radius.circular(r),
        ),
        Paint()..color = activeColor,
      );
    }
  }

  @override
  bool shouldRepaint(VideoLevelBarPainter old) => old.value != value;
}

/// The card that offers to play the next item, and counts down to it.
///
/// A countdown rather than an immediate jump, and a countdown with a
/// stop on it: autoplay that cannot be refused is the single most
/// complained-about behaviour a player has. Both buttons are real —
/// one plays now, one stops the clock — and doing nothing plays next,
/// which is the only reason the card is worth showing at all.
class VideoUpNextCard extends StatelessWidget {
  const VideoUpNextCard({
    required this.secondsLeft,
    required this.style,
    required this.scale,
    required this.onPlayNow,
    required this.onCancel,
    super.key,
  });

  final int secondsLeft;
  final ResolvedVideoStyle style;
  final double scale;
  final VoidCallback onPlayNow;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) => Positioned.fill(
    child: Center(
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: VideoDefaults.barPaddingH * scale,
          vertical: VideoDefaults.barPaddingV * scale,
        ),
        decoration: BoxDecoration(
          color: style.scrimColor,
          borderRadius: BorderRadius.circular(
            VideoDefaults.seekBadgeRadius * scale,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '${VideoStrings.upNext} · $secondsLeft',
              style: TextStyle(
                color: style.iconColor,
                fontSize:
                    (context.textTheme.titleSmall?.fontSize ?? 14) * scale,
                fontWeight: FontWeight.w700,
              ),
            ),
            SizedBox(height: VideoDefaults.barPaddingV * scale),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Named, not just glyphs: this is the one surface where
                // a wrong guess starts the next film.
                _UpNextAction(
                  label: VideoStrings.cancelAutoplay,
                  onTap: onCancel,
                  style: style,
                  scale: scale,
                ),
                SizedBox(width: VideoDefaults.barPaddingH * scale),
                _UpNextAction(
                  label: VideoStrings.playNow,
                  onTap: onPlayNow,
                  style: style,
                  scale: scale,
                  filled: true,
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}

class _UpNextAction extends StatelessWidget {
  const _UpNextAction({
    required this.label,
    required this.onTap,
    required this.style,
    required this.scale,
    this.filled = false,
  });

  final String label;
  final VoidCallback onTap;
  final ResolvedVideoStyle style;
  final double scale;
  final bool filled;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: label,
    excludeSemantics: true,
    child: GestureDetector(
      onTap: onTap,
      child: Container(
        // The 48dp floor is kept here, unlike the bar's controls: this
        // is a choice with consequences, not a glyph beside four others.
        constraints: const BoxConstraints(
          minHeight: kMinInteractiveDimension,
        ),
        alignment: Alignment.center,
        padding: EdgeInsets.symmetric(
          horizontal: VideoDefaults.barPaddingH * scale,
        ),
        decoration: BoxDecoration(
          color: filled ? style.activeColor : Colors.transparent,
          border: filled ? null : Border.all(color: style.iconColor),
          borderRadius: BorderRadius.circular(
            VideoDefaults.badgeRadius * scale,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: style.iconColor,
            fontSize: (context.textTheme.labelLarge?.fontSize ?? 14) * scale,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    ),
  );
}
