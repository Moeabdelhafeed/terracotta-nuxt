import 'dart:io';

import 'package:audio_waveforms/audio_waveforms.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

import '../../shared/module/audio/audio_models.dart';
import '../utils/loggers/logger.dart';
import 'waveform_cache.dart';

/// Decodes amplitude samples from an [AudioSourceSpec] using the
/// `audio_waveforms` plugin. The plugin only reads from local file
/// paths, so URLs / assets / bytes are materialized to a temp file
/// first (cached by source hash so repeated decodes are cheap).
class WaveformExtractor {
  WaveformExtractor._();

  /// Returns normalized amplitudes (0..1) of length [samples]. Null
  /// when extraction fails — callers should fall back to a static
  /// curve.
  ///
  /// Deduplicated and cached by [WaveformCache]: the same source at
  /// the same resolution is decoded once per session however many
  /// players ask for it, including when they all ask in one frame.
  static Future<List<double>?> extract(
    AudioSourceSpec spec, {
    int samples = 120,
  }) => WaveformCache.resolve(
    cacheKey(spec, samples),
    () => _decode(spec, samples),
  );

  /// What makes two requests the SAME decode.
  ///
  /// The sample count is in it because it changes the answer — a
  /// 120-bar waveform is not a 512-bar one downsampled. Bytes are
  /// keyed by their hash, since the source string is empty for them.
  @visibleForTesting
  static String cacheKey(AudioSourceSpec spec, int samples) {
    final id = spec.kind == AudioSourceKind.bytes
        ? 'bytes#${spec.bytes?.length ?? 0}#${spec.bytes.hashCode}'
        : spec.value;
    return '${spec.kind.name}|$id|$samples';
  }

  static Future<List<double>?> _decode(
    AudioSourceSpec spec,
    int samples,
  ) async {
    try {
      final localPath = await _materialize(spec);
      if (localPath == null) return null;

      final controller = PlayerController();
      final raw = await controller.waveformExtraction.extractWaveformData(
        path: localPath,
        noOfSamples: samples,
      );
      controller.dispose();
      if (raw.isEmpty) return null;

      var max = 0.0;
      for (final v in raw) {
        final a = v.abs();
        if (a > max) max = a;
      }
      if (max == 0) return null;
      return [for (final v in raw) (v.abs() / max).clamp(0.0, 1.0)];
    } catch (e, st) {
      Logger.m.w('[WaveformExtractor] failed', error: e, stackTrace: st);
      return null;
    }
  }

  static Future<String?> _materialize(AudioSourceSpec spec) async {
    final tmp = await getTemporaryDirectory();
    switch (spec.kind) {
      case AudioSourceKind.file:
      case AudioSourceKind.videoFile:
        return spec.value;

      case AudioSourceKind.asset:
      case AudioSourceKind.videoAsset:
        final ext = _ext(spec.value, fallback: 'mp3');
        final out = File('${tmp.path}/wf_asset_${spec.value.hashCode}.$ext');
        if (!await out.exists()) {
          final data = await rootBundle.load(spec.value);
          await out.writeAsBytes(
            data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes),
          );
        }
        return out.path;

      case AudioSourceKind.url:
      case AudioSourceKind.videoUrl:
        final ext = _ext(Uri.parse(spec.value).path, fallback: 'mp4');
        final out = File('${tmp.path}/wf_url_${spec.value.hashCode}.$ext');
        if (!await out.exists()) {
          final resp = await http.get(Uri.parse(spec.value));
          if (resp.statusCode >= 400) return null;
          await out.writeAsBytes(resp.bodyBytes);
        }
        return out.path;

      case AudioSourceKind.bytes:
        final out = File('${tmp.path}/wf_bytes_${spec.value.hashCode}.mp3');
        if (!await out.exists()) {
          await out.writeAsBytes(spec.bytes ?? Uint8List(0));
        }
        return out.path;
    }
  }

  static String _ext(String path, {required String fallback}) {
    final dot = path.lastIndexOf('.');
    if (dot < 0 || dot == path.length - 1) return fallback;
    final ext = path.substring(dot + 1).toLowerCase();
    return ext.length > 4 ? fallback : ext;
  }
}
