import 'package:flutter/material.dart';

import '../slider/slider_shapes.dart';
import 'video_models.dart';

/// The timeline, and the one part of the player that does NOT mirror.
///
/// Split out of the controls so it can be tested at all: `VideoControls`
/// needs a `media_kit` `Player`, which will not start under
/// `flutter_test`, and this needed a test — the RTL bug it exists to
/// prevent shipped once already.
///
/// A `Slider` mirrors under `Directionality.rtl`. Measured, tapping the
/// far RIGHT of an Arabic seek bar returned `0.0` where the same tap in
/// English returned `1.0`: the reader who aimed at the end of the film
/// jumped to its start.
///
/// That behaviour is right for a value that reads like text and wrong
/// for a TIMELINE. Time runs one way, the frames were shot in that
/// order, and every player that ships in Arabic — YouTube, Netflix —
/// leaves the timeline running left to right. Pinning it is also what
/// keeps the rest of the gestures honest: the double-tap halves and
/// drag-to-seek are physical (left is back, drag right goes forward)
/// and would contradict a mirrored bar.
class VideoSeekBar extends StatelessWidget {
  const VideoSeekBar({
    required this.position,
    required this.duration,
    required this.buffered,
    required this.style,
    required this.scale,
    required this.dragging,
    super.key,
    this.chapters = const [],
    this.loopStart,
    this.loopEnd,
    this.onChangeStart,
    this.onChanged,
    this.onChangeEnd,
  });

  final Duration position;
  final Duration duration;
  final Duration buffered;
  final ResolvedVideoStyle style;

  /// Sized against the frame, like every other control.
  final double scale;

  /// Fattens the thumb while a finger is on it.
  final bool dragging;

  /// Marked on the track, so the shape of the film is visible before
  /// anyone scrubs into it.
  final List<VideoChapter> chapters;

  /// The A–B loop, drawn ON the timeline.
  ///
  /// Without this the feature reads as broken: two taps a second apart
  /// make a one-second loop, which is correct and looks like a player
  /// stuck on the last moment. Showing the span is what makes the two
  /// taps mean something — reported before this existed.
  final Duration? loopStart;
  final Duration? loopEnd;

  final ValueChanged<double>? onChangeStart;
  final ValueChanged<double>? onChanged;
  final ValueChanged<double>? onChangeEnd;

  @override
  Widget build(BuildContext context) {
    final total = duration.inMilliseconds.toDouble();
    final pos = position.inMilliseconds.toDouble();
    final buf = buffered.inMilliseconds.toDouble();
    final accent = style.activeColor;

    final track = Directionality(
      textDirection: TextDirection.ltr,
      child: SliderTheme(
        data: SliderTheme.of(context).copyWith(
          trackHeight: style.progressBarHeight * scale,
          activeTrackColor: accent,
          inactiveTrackColor: style.trackColor,
          secondaryActiveTrackColor: style.bufferedColor,
          thumbColor: style.thumbColor,
          thumbShape: RoundSliderThumbShape(
            enabledThumbRadius:
                (dragging ? style.thumbRadius + 2 : style.thumbRadius) * scale,
          ),
          overlayShape: RoundSliderOverlayShape(overlayRadius: 10 * scale),
          overlayColor: accent.withValues(alpha: 0.2),
          // Chapters replace the TRACK rather than being painted over
          // it. Gaps drawn on top left the pieces running together
          // under the thumb; this makes each chapter its own bar.
          trackShape: chapters.isEmpty
              ? null
              : SliderSegmentedTrackShape(
                  bounds: <double>[
                    0,
                    for (final c in chapters)
                      if (c.fractionOf(duration) > 0 &&
                          c.fractionOf(duration) < 1)
                        c.fractionOf(duration),
                    1,
                  ]..sort(),
                  gap: VideoDefaults.chapterGap * scale,
                  inactiveColor: style.trackColor,
                  // NOTHING reserved at the ends: the timeline runs
                  // the full width so it lines up with the clock and
                  // the controls under it, and the thumb overhangs
                  // into the bar's own inset instead.
                  endInset: 0,
                  trackRadius: (style.progressBarHeight * scale) / 2,
                  // A TIMELINE does not mirror, and the whole bar is
                  // already pinned left-to-right above.
                  rtl: false,
                ),
        ),
        child: Slider(
          // NO horizontal padding, so the track runs the full width of
          // the bar and its ends line up with the clock and the
          // controls. Material reserves the thumb's width there by
          // default, which indented the timeline from everything under
          // it — visible, and the thing that made the bar look
          // untidy. The thumb overhangs into the bar's own inset
          // instead, which is wider than the thumb.
          //
          // Vertical is KEPT: it is the drag target, and the track is
          // three points tall.
          padding: EdgeInsets.symmetric(
            vertical: VideoDefaults.seekBarTouchPadding * scale,
          ),
          value: total > 0 ? pos.clamp(0, total) : 0,
          max: total > 0 ? total : 1,
          secondaryTrackValue: total > 0 ? buf.clamp(0, total) : 0,
          onChangeStart: onChangeStart,
          onChanged: onChanged ?? (_) {},
          onChangeEnd: onChangeEnd,
        ),
      ),
    );

    if (loopStart == null || duration <= Duration.zero) return track;

    return Stack(
      alignment: Alignment.center,
      children: [
        track,
        Positioned.fill(
          child: IgnorePointer(
            child: CustomPaint(
              painter: _LoopRegionPainter(
                start: loopStart!.inMilliseconds / total,
                end: loopEnd == null ? null : loopEnd!.inMilliseconds / total,
                color: accent,
                trackHeight: style.progressBarHeight * scale,
                markerWidth: VideoDefaults.chapterGap * scale,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Shows where an A–B loop starts and ends.
///
/// A tick while only A is marked, a band once B is: the half-set state
/// is the one that needed showing most, because a reader who has
/// pressed once has no other way to know the button did anything.
class _LoopRegionPainter extends CustomPainter {
  _LoopRegionPainter({
    required this.start,
    required this.end,
    required this.color,
    required this.trackHeight,
    required this.markerWidth,
  });

  final double start;

  /// Null until B is marked.
  final double? end;

  final Color color;
  final double trackHeight;
  final double markerWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final top = (size.height - trackHeight) / 2;
    // Taller than the track, so the marks read as brackets around the
    // timeline rather than as another piece of it.
    final height = trackHeight * 2.4;
    final y = top - (height - trackHeight) / 2;
    final paint = Paint()..color = color;

    void tick(double fraction) {
      final x = (size.width * fraction.clamp(0.0, 1.0)) - markerWidth / 2;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(x, y, markerWidth, height),
          Radius.circular(markerWidth / 2),
        ),
        paint,
      );
    }

    final b = end;
    if (b != null) {
      canvas.drawRect(
        Rect.fromLTRB(
          size.width * start.clamp(0.0, 1.0),
          y,
          size.width * b.clamp(0.0, 1.0),
          y + height,
        ),
        Paint()..color = color.withValues(alpha: 0.28),
      );
      tick(b);
    }
    tick(start);
  }

  @override
  bool shouldRepaint(_LoopRegionPainter old) =>
      old.start != start || old.end != end || old.color != color;
}
