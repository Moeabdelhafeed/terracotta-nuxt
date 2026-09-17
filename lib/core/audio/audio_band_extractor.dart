import 'dart:math' as math;

import 'package:flutter/foundation.dart';

import '../../shared/module/audio/audio_models.dart';
import '../utils/loggers/logger.dart';
import 'waveform_extractor.dart';

/// Pre-computed multi-band timeline for a track. `bands[t][b]` is the
/// 0..1 magnitude of band `b` at timestamp index `t`.
@immutable
class BandSnapshots {
  const BandSnapshots({
    required this.bands,
    required this.duration,
    required this.bandCount,
  });

  /// `[timestampIndex][bandIndex]`. Length = number of timestamps.
  final List<List<double>> bands;

  /// Duration the timeline covers — used to map a playhead Duration
  /// into a snapshot index.
  final Duration duration;

  final int bandCount;

  /// Nearest snapshot for the given playhead. Cheap O(1) lookup —
  /// callers should call this per frame, not search.
  List<double> at(Duration playhead) {
    if (bands.isEmpty || duration <= Duration.zero) {
      return List<double>.filled(bandCount, 0);
    }
    final frac = playhead.inMicroseconds / duration.inMicroseconds;
    final clamped = frac < 0 ? 0.0 : (frac > 1 ? 1.0 : frac);
    final idx = (clamped * (bands.length - 1)).round();
    return bands[idx];
  }
}

/// Pluggable extractor — produces a [BandSnapshots] timeline from an
/// [AudioSourceSpec]. Default ships [SyntheticBandExtractor] which is
/// pure Dart + cross-platform; swap in [DecoderBandExtractor] (or
/// your own) once you wire a PCM decoder for true FFT bands.
// ignore: one_member_abstracts
abstract class AudioBandExtractor {
  Future<BandSnapshots?> extract(
    AudioSourceSpec source, {
    int bandCount = 32,
    int timestampsCount = 512,
  });
}

/// Cross-platform band extractor that reuses [WaveformExtractor]'s
/// amplitude output (which already runs through `audio_waveforms`'
/// native decode) and derives per-band values via a bank of
/// band-shaped responses over the amplitude envelope.
///
/// **Not** a true per-frequency FFT — it can't be, because we don't
/// have raw PCM. But it pulls from real audio content, varies per
/// band, and is consistent across web / desktop / mobile.
///
/// What each band index represents (low → high):
///   - bass bins: smoothed local-mean of the envelope (slow response)
///   - mid bins:  windowed energy (RMS-like)
///   - treble bins: local derivative magnitude (peaks on transients)
///
/// Each band also gets a position-coupled LFO so adjacent bins differ
/// even when the envelope is flat — same trick the live driver uses,
/// but baked into the timeline.
class SyntheticBandExtractor implements AudioBandExtractor {
  const SyntheticBandExtractor();

  @override
  Future<BandSnapshots?> extract(
    AudioSourceSpec source, {
    int bandCount = 32,
    int timestampsCount = 512,
  }) async {
    // Pull a high-resolution amplitude waveform — more buckets = more
    // detail per snapshot.
    final wf = await WaveformExtractor.extract(source, samples: 1024);
    if (wf == null || wf.isEmpty) {
      Logger.m.w('[SyntheticBandExtractor] waveform extract failed');
      return null;
    }

    final len = wf.length;
    final out = List<List<double>>.generate(
      timestampsCount,
      (_) => List<double>.filled(bandCount, 0),
    );
    final rng = math.Random(42);
    final bandPhase = List<double>.generate(
      bandCount,
      (_) => rng.nextDouble() * math.pi * 2,
    );
    final bandFreq = List<double>.generate(
      bandCount,
      // Band index drives frequency: low bands wiggle slowly, high
      // bands wiggle fast — mirrors a real spectrum's character.
      (i) => 1.5 + (i / bandCount) * 18.0,
    );

    for (var ti = 0; ti < timestampsCount; ti++) {
      final pos = ti / (timestampsCount - 1); // 0..1
      final srcIdx = pos * (len - 1);
      final t = ti / 60.0; // pretend each timestamp is 1/60s

      for (var bi = 0; bi < bandCount; bi++) {
        final bandPos = bi / (bandCount - 1); // 0..1, low→high

        // Window radius shrinks as band index rises — bass averages
        // a wider neighbourhood, treble looks at a tight window for
        // transients.
        final radius = (1 - bandPos) * 64 + 4;
        final low = (srcIdx - radius).clamp(0, len - 1).toInt();
        final high = (srcIdx + radius).clamp(0, len - 1).toInt();

        // Local mean = bass character.
        double sum = 0;
        double maxVal = 0;
        for (var j = low; j <= high; j++) {
          final v = wf[j];
          sum += v;
          if (v > maxVal) maxVal = v;
        }
        final span = (high - low + 1).clamp(1, len);
        final mean = sum / span;

        // Local derivative magnitude = treble character.
        final pIdx = srcIdx.toInt().clamp(1, len - 2);
        final deriv = (wf[pIdx + 1] - wf[pIdx - 1]).abs();

        // Blend the three characters by band position.
        final bass = mean;
        final mid = maxVal;
        final treble = deriv * 6; // amplify — derivatives are tiny
        final blend = bandPos < 0.33
            ? bass
            : (bandPos < 0.66
                  ? mid * 0.8 + bass * 0.2
                  : treble * 0.7 + mid * 0.3);

        // LFO so adjacent bins read different magnitudes even when
        // the underlying blend is similar.
        final osc = 0.55 + 0.45 * math.sin(t * bandFreq[bi] + bandPhase[bi]);
        out[ti][bi] = (blend * osc).clamp(0.0, 1.0);
      }
    }

    // Duration is unknown to the extractor — caller should set this
    // from the player's reported duration. We stash a sentinel and
    // let the player overwrite it.
    return BandSnapshots(
      bands: out,
      duration: Duration.zero, // overwritten by caller
      bandCount: bandCount,
    );
  }
}

/// Stub — real per-frequency FFT path. Requires raw PCM access, which
/// neither `just_audio` nor `audio_waveforms` exposes cross-platform.
///
/// To complete:
///   1. Add a PCM decoder (`ffmpeg_kit_flutter_new` for cross-platform,
///      heavy ~50MB binary; `wav` package for WAV-only; or per-
///      platform native bridges).
///   2. Decode source → mono PCM16 → Float32 normalized.
///   3. Slice into windows of `pcmSampleRate / framesPerSec` samples.
///   4. Hann-window each slice, run FFT via `fftea` package.
///   5. Magnitude-bucket the FFT bins into `bandCount` logarithmic
///      bands (matches human pitch perception).
///   6. Normalize per snapshot.
///
/// Until then, calls to [extract] fall through to
/// [SyntheticBandExtractor] so callers don't crash.
class DecoderBandExtractor implements AudioBandExtractor {
  const DecoderBandExtractor();

  @override
  Future<BandSnapshots?> extract(
    AudioSourceSpec source, {
    int bandCount = 32,
    int timestampsCount = 512,
  }) async {
    // TODO(audio): wire ffmpeg/wav decoder + fftea FFT here.
    return const SyntheticBandExtractor().extract(
      source,
      bandCount: bandCount,
      timestampsCount: timestampsCount,
    );
  }
}
