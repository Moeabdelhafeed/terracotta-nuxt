// Dart imports:
import 'dart:io';

// Flutter imports:
import 'package:flutter/foundation.dart';
// Package imports:
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'media_picker_service.dart';

/// Image compression — wraps `flutter_image_compress` (native
/// platform channels: libjpeg-turbo on Android, ImageIO on iOS).
///
/// Replaces the previous hand-rolled `dart:ui` + PNG encoder pipeline
/// where the quality knob was a no-op (PNG is lossless).
///
/// Compressed files land in the platform temp directory — callers are
/// responsible for relocating or deleting them.
///
/// Picking is delegated to [MediaPickerService]; this service only
/// compresses. All failure paths return `null` — caller handles UI.
class ImageCompressionService {
  ImageCompressionService._();

  static const int maxFileSizeBytes = 2 * 1024 * 1024; // 2 MB
  static const int maxWidth = 1920;
  static const int maxHeight = 1920;
  static const int _initialQuality = 85;
  static const int _minQuality = 40;
  static const int _qualityStep = 10;

  /// Compress [imageFile] until it's ≤ [maxFileSizeBytes]. Returns
  /// the original file if it already meets the size cap, a new
  /// JPEG temp file otherwise, or the smallest candidate seen if no
  /// quality step hit the cap. Returns `null` on unrecoverable
  /// failure.
  static Future<File?> compressImage(File imageFile) async {
    try {
      if (await imageFile.length() <= maxFileSizeBytes) return imageFile;

      final tempDir = await getTemporaryDirectory();
      var quality = _initialQuality;
      File? best;

      while (quality >= _minQuality) {
        final outPath = p.join(
          tempDir.path,
          'compressed_${DateTime.now().millisecondsSinceEpoch}_q$quality.jpg',
        );

        final result = await FlutterImageCompress.compressAndGetFile(
          imageFile.absolute.path,
          outPath,
          quality: quality,
          format: CompressFormat.jpeg,
          minWidth: maxWidth,
          minHeight: maxHeight,
          keepExif: false,
        );

        if (result == null) break;
        final file = File(result.path);
        final size = await file.length();

        if (size <= maxFileSizeBytes) return file;

        // Too large — keep the smallest candidate so far and try
        // again at lower quality.
        if (best == null || size < await best.length()) {
          if (best != null && await best.exists()) await best.delete();
          best = file;
        } else {
          await file.delete();
        }

        quality -= _qualityStep;
      }

      return best ?? imageFile;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[ImageCompressionService] compressImage failed: $e');
      }
      return null;
    }
  }

  /// Re-encode the image as JPEG at near-lossless quality without
  /// copying EXIF tags — scrubs location / device / timestamp
  /// metadata that compression-by-size would otherwise preserve
  /// on files already under [maxFileSizeBytes]. Returns the
  /// original file on failure so the caller's flow doesn't break.
  static Future<File> stripExif(File imageFile) async {
    try {
      final tempDir = await getTemporaryDirectory();
      final outPath = p.join(
        tempDir.path,
        'stripped_${DateTime.now().millisecondsSinceEpoch}.jpg',
      );
      final result = await FlutterImageCompress.compressAndGetFile(
        imageFile.absolute.path,
        outPath,
        quality: 95,
        format: CompressFormat.jpeg,
        keepExif: false,
      );
      if (result == null) return imageFile;
      return File(result.path);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[ImageCompressionService] stripExif failed: $e');
      }
      return imageFile;
    }
  }

  /// Pick a single image via [MediaPickerService] then compress.
  /// Uses `imageQuality: 70` at pick time as a cheap first pass; the
  /// iterative re-compress only kicks in for files still above
  /// [maxFileSizeBytes].
  static Future<File?> pickAndCompressImage({
    required ImageSource source,
  }) async {
    final picked = await MediaPickerService.pickImage(
      source: source,
      maxWidth: maxWidth.toDouble(),
      maxHeight: maxHeight.toDouble(),
      imageQuality: 70,
    );
    if (picked == null) return null;
    return compressImage(picked);
  }

  /// Pick multiple images (gallery only) then compress in parallel.
  static Future<List<File>> pickAndCompressMultipleImages() async {
    final picked = await MediaPickerService.pickMultipleImages(
      maxWidth: maxWidth.toDouble(),
      maxHeight: maxHeight.toDouble(),
      imageQuality: _initialQuality,
    );
    if (picked.isEmpty) return [];

    final compressed = await Future.wait(picked.map(compressImage));
    return compressed.whereType<File>().toList();
  }
}
