import 'package:flutter/material.dart';

import '../../../core/localization/strings/module_strings.dart';

import 'audio_models.dart';

/// Bar-waveform painter. Driven by a normalized amplitude array
/// (`samples` in 0..1) + a position fraction (0..1 = playhead). Bars
/// left of the playhead take the accent; bars right take the bar
/// colour, at reduced alpha.
///
/// It takes a RESOLVED bag. It used to take the caller's and answer
/// the leftover questions itself out of `Theme.of` — which put the
/// palette in two places and meant a waveform inside a themed player
/// could disagree with the player around it.
///
/// Static-only — for live decoded waveforms, use
/// `WaveformExtractor.fromSource(...)` and pass the resulting samples
/// in. The painter is unaware of the source.
class AudioWaveform extends StatefulWidget {
  const AudioWaveform({
    super.key,
    required this.samples,
    required this.progress,
    required this.style,
    this.onScrubStart,
    this.onScrubUpdate,
    this.onScrubEnd,
  });

  /// Normalized amplitudes (0..1). Sample count == bar count.
  final List<double> samples;

  /// 0..1 — fraction of the duration that has been played.
  final double progress;

  final ResolvedAudioStyle style;

  /// Tap or drag-end commits the seek. Use the start/update pair to
  /// drive a "scrubbing" preview without actually moving the player.
  /// This prevents the position stream from fighting the drag and
  /// causing visible glitches.
  final VoidCallback? onScrubStart;
  final ValueChanged<double>? onScrubUpdate;
  final ValueChanged<double>? onScrubEnd;

  @override
  State<AudioWaveform> createState() => _AudioWaveformState();
}

class _AudioWaveformState extends State<AudioWaveform>
    with SingleTickerProviderStateMixin {
  /// Sweeps the playhead to a tapped position.
  ///
  /// Playback moves it a fraction of a bar per frame and needs no help.
  /// A SEEK moves it a third of the way across in one frame, and that
  /// reads as a jump — the value was tracking correctly and nothing
  /// appeared to move, which is how it was reported.
  late final AnimationController _sweep = AnimationController(
    vsync: this,
    duration: AudioDefaults.seekSweep,
  );

  late double _shown = widget.progress;
  double _sweepFrom = 0;
  double _sweepTo = 0;

  @override
  void initState() {
    super.initState();
    _sweep.addListener(() {
      setState(() {
        _shown = _sweepFrom + (_sweepTo - _sweepFrom) * _sweep.value;
      });
    });
  }

  @override
  void didUpdateWidget(AudioWaveform old) {
    super.didUpdateWidget(old);
    final next = widget.progress;
    if (next == _shown) return;

    // Small steps are playback and are followed exactly — animating
    // those would make the playhead lag its own audio.
    if ((next - _shown).abs() < AudioDefaults.seekSweepThreshold) {
      _sweep.stop();
      setState(() => _shown = next);
      return;
    }
    _sweepFrom = _shown;
    _sweepTo = next;
    _sweep.forward(from: 0);
  }

  @override
  void dispose() {
    _sweep.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final samples = widget.samples;
    final style = widget.style;
    final onScrubStart = widget.onScrubStart;
    final onScrubUpdate = widget.onScrubUpdate;
    final onScrubEnd = widget.onScrubEnd;
    final progress = _shown;
    final paint = CustomPaint(
      painter: _WaveformPainter(
        samples: samples,
        progress: progress.clamp(0.0, 1.0),
        accent: style.accent,
        barColor: style.barColor,
        barWidth: style.barWidth,
        barSpacing: style.barSpacing,
        barRadius: style.barRadius,
      ),
      size: Size(double.infinity, style.waveformHeight),
    );

    // Decoration when it cannot be scrubbed: a picture of a sound is
    // not something to announce, and a reader tabbing through a page
    // should not meet it.
    if (onScrubUpdate == null && onScrubEnd == null) {
      return ExcludeSemantics(child: paint);
    }

    return Semantics(
      slider: true,
      label: AudioStrings.waveform,
      value: '${(progress.clamp(0.0, 1.0) * 100).round()}%',
      child: LayoutBuilder(
        builder: (_, c) {
          double fracFor(Offset local) =>
              c.maxWidth <= 0 ? 0 : (local.dx / c.maxWidth).clamp(0.0, 1.0);
          return GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTapDown: (d) {
              onScrubStart?.call();
              onScrubEnd?.call(fracFor(d.localPosition));
            },
            onHorizontalDragStart: (d) {
              onScrubStart?.call();
              onScrubUpdate?.call(fracFor(d.localPosition));
            },
            onHorizontalDragUpdate: (d) =>
                onScrubUpdate?.call(fracFor(d.localPosition)),
            onHorizontalDragEnd: (d) {
              // No localPosition on DragEndDetails; use last update value
              // recorded by the caller via onScrubUpdate.
              onScrubEnd?.call(-1); // sentinel: "use last update"
            },
            onHorizontalDragCancel: () => onScrubEnd?.call(-1),
            child: paint,
          );
        },
      ),
    );
  }
}

/// How much of the bar at [barLeft] has been played, 0..1.
///
/// Pulled out of the painter because it is the whole of the decision
/// and none of the drawing — a painter cannot be asked what it did,
/// and this was rounded to a whole bar index for long enough to ship
/// as "the waveform is not animating".
@visibleForTesting
double barFillFraction({
  required double barLeft,
  required double barWidth,
  required double playedX,
}) {
  if (barWidth <= 0) return 0;
  return ((playedX - barLeft) / barWidth).clamp(0.0, 1.0);
}

class _WaveformPainter extends CustomPainter {
  _WaveformPainter({
    required this.samples,
    required this.progress,
    required this.accent,
    required this.barColor,
    required this.barWidth,
    required this.barSpacing,
    required this.barRadius,
  });

  final List<double> samples;
  final double progress;
  final Color accent;
  final Color barColor;
  final double barWidth;
  final double barSpacing;
  final double barRadius;

  @override
  void paint(Canvas canvas, Size size) {
    if (samples.isEmpty || size.width <= 0) return;
    final pitch = barWidth + barSpacing;
    final visibleBars = (size.width / pitch).floor();
    if (visibleBars <= 0) return;

    // Down/up-sample the input to match visible bar count so the
    // painter is independent of the source length.
    final resampled = _resample(samples, visibleBars);
    final mid = size.height / 2;

    // The playhead in PIXELS, not in whole bars.
    //
    // Rounding to a bar index meant the fill only moved when the
    // playhead crossed a whole bar — about once a second on a
    // thirty-second clip in a message bubble. It read as a waveform
    // that was not animating, punctuated by a bar flipping colour all
    // at once, which is exactly how it was reported.
    final playedX = size.width * progress.clamp(0.0, 1.0);

    final unplayed = Paint()
      ..color = barColor.withValues(alpha: AudioDefaults.unplayedBarOpacity);
    final played = Paint()..color = accent;
    final radius = Radius.circular(barRadius);

    for (var i = 0; i < resampled.length; i++) {
      final amp = resampled[i].clamp(0.0, 1.0);
      final h = (amp * size.height).clamp(
        AudioDefaults.minBarHeight,
        size.height,
      );
      final x = i * pitch;
      final rrect = RRect.fromRectAndRadius(
        Rect.fromLTWH(x, mid - h / 2, barWidth, h),
        radius,
      );

      final fill = barFillFraction(
        barLeft: x,
        barWidth: barWidth,
        playedX: playedX,
      );

      if (fill >= 1) {
        canvas.drawRRect(rrect, played);
        continue;
      }
      if (fill <= 0) {
        canvas.drawRRect(rrect, unplayed);
        continue;
      }

      // The bar the playhead is INSIDE grows from its own CENTRE,
      // over the time that bar represents.
      //
      // A horizontal wipe across a two-and-a-half point bar is not
      // something an eye can see: at forty bars over a three-minute
      // track each one is worth four seconds, and all of it happened
      // inside a sliver. Growing outwards uses the bar's whole height
      // to show the same thing, so the waveform reads as playing
      // rather than as a fill creeping along it.
      canvas.drawRRect(rrect, unplayed);
      final grown = h * Curves.easeOutCubic.transform(fill);
      if (grown <= 0) continue;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(x, mid - grown / 2, barWidth, grown),
          radius,
        ),
        played,
      );
    }
  }

  /// Simple linear resample — pulls one value per output bucket by
  /// taking the max in the source slice (perceived loudness reads
  /// better than mean for waveform displays).
  List<double> _resample(List<double> src, int targetLen) {
    if (src.length == targetLen) return src;
    final out = List<double>.filled(targetLen, 0);
    final stride = src.length / targetLen;
    for (var i = 0; i < targetLen; i++) {
      final start = (i * stride).floor();
      final end = ((i + 1) * stride).ceil().clamp(start + 1, src.length);
      var max = 0.0;
      for (var j = start; j < end; j++) {
        final v = src[j];
        if (v > max) max = v;
      }
      out[i] = max;
    }
    return out;
  }

  @override
  bool shouldRepaint(_WaveformPainter old) =>
      old.progress != progress ||
      old.samples != samples ||
      old.accent != accent ||
      old.barColor != barColor;
}
