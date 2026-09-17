// Dart imports:
import 'dart:io';

// Flutter imports:
import 'package:flutter/foundation.dart';

// Package imports:
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:video_thumbnail/video_thumbnail.dart';

/// Extracts a JPEG thumbnail from a video at a given offset. Used
/// by the video picker to replace the generic play icon with the
/// selected frame, and by the trimmer sheet to let the user pick
/// their own cover frame.
class VideoThumbnailService {
  VideoThumbnailService._();

  /// Decode a single thumbnail at [timeMs] (ms into the clip).
  /// Returns the saved file, or `null` on decode failure.
  static Future<File?> at(
    String videoPath, {
    int timeMs = 0,
    int maxWidth = 512,
    int quality = 75,
  }) async {
    try {
      final tmp = await getTemporaryDirectory();
      final outName = 'thumb_${DateTime.now().microsecondsSinceEpoch}.jpg';
      final outPath = p.join(tmp.path, outName);
      final result = await VideoThumbnail.thumbnailFile(
        video: videoPath,
        thumbnailPath: outPath,
        imageFormat: ImageFormat.JPEG,
        timeMs: timeMs,
        maxWidth: maxWidth,
        quality: quality,
      );
      if (result == null) return null;
      return File(result);
    } catch (e) {
      if (kDebugMode) debugPrint('[VideoThumbnailService] at failed: $e');
      return null;
    }
  }
}
