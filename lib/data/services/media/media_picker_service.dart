// Dart imports:
import 'dart:io';

// Flutter imports:
import 'package:flutter/foundation.dart';
// Package imports:
import 'package:image_picker/image_picker.dart';

/// Gallery + camera pickers for images and videos. Stateless wrapper
/// around `image_picker`. Returns `null` / empty list on cancel or
/// failure — callers decide whether to surface UI feedback.
class MediaPickerService {
  MediaPickerService._();

  static final ImagePicker _picker = ImagePicker();

  static Future<File?> pickImage({
    ImageSource source = ImageSource.gallery,
    double? maxWidth,
    double? maxHeight,
    int? imageQuality,
  }) async {
    try {
      final image = await _picker.pickImage(
        source: source,
        maxWidth: maxWidth,
        maxHeight: maxHeight,
        imageQuality: imageQuality,
      );
      return image == null ? null : File(image.path);
    } catch (e) {
      if (kDebugMode) debugPrint('[MediaPickerService] pickImage failed: $e');
      return null;
    }
  }

  /// [limit] enforces a cap in the native gallery picker (image_picker
  /// 1.1+). When the platform doesn't honor the limit (older iOS, web),
  /// callers should trim the returned list themselves.
  static Future<List<File>> pickMultipleImages({
    double? maxWidth,
    double? maxHeight,
    int? imageQuality,
    int? limit,
  }) async {
    try {
      final images = await _picker.pickMultiImage(
        maxWidth: maxWidth,
        maxHeight: maxHeight,
        imageQuality: imageQuality,
        limit: limit,
      );
      return images.map((x) => File(x.path)).toList();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[MediaPickerService] pickMultipleImages failed: $e');
      }
      return [];
    }
  }

  static Future<File?> pickVideo({
    ImageSource source = ImageSource.gallery,
    Duration? maxDuration,
  }) async {
    try {
      final video = await _picker.pickVideo(
        source: source,
        maxDuration: maxDuration,
      );
      return video == null ? null : File(video.path);
    } catch (e) {
      if (kDebugMode) debugPrint('[MediaPickerService] pickVideo failed: $e');
      return null;
    }
  }

  /// [limit] caps selection in the native video picker when supported.
  static Future<List<File>> pickMultipleVideos({
    Duration? maxDuration,
    int? limit,
  }) async {
    try {
      final videos = await _picker.pickMultiVideo(
        maxDuration: maxDuration,
        limit: limit,
      );
      return videos.map((x) => File(x.path)).toList();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[MediaPickerService] pickMultipleVideos failed: $e');
      }
      return [];
    }
  }
}
