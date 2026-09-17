// Dart imports:
import 'dart:io';

// Package imports:
import 'package:dio/dio.dart';
// Flutter imports:
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

// Project imports:
import '../../../core/utils/validators/validators.dart';

/// Static download helpers. Writes to the platform temp directory;
/// caller is responsible for relocating or cleaning up.
///
/// Uses a dedicated [Dio] — no interceptors, no auth. For downloads
/// that require your app's Authorization header, route through
/// `ApiService` instead.
class DownloadService {
  DownloadService._();

  static final Dio _dio = Dio();

  // ─── Single-file downloads ──────────────────────────────────────

  static Future<File?> downloadImageFromUrl(
    String imageUrl, {
    String? customFileName,
  }) {
    return _download(
      url: imageUrl,
      customFileName: customFileName,
      validate: Validators.isValidImageUrl,
      receiveTimeout: const Duration(seconds: 30),
      label: 'image',
    );
  }

  static Future<File?> downloadVideoFromUrl(
    String videoUrl, {
    String? customFileName,
  }) {
    return _download(
      url: videoUrl,
      customFileName: customFileName,
      validate: Validators.isValidVideoUrl,
      receiveTimeout: const Duration(seconds: 60),
      label: 'video',
    );
  }

  // ─── Batch downloads (parallel) ─────────────────────────────────

  static Future<List<File>> downloadImagesFromUrls(
    List<String> imageUrls, {
    List<String>? customFileNames,
  }) async {
    final results = await Future.wait([
      for (var i = 0; i < imageUrls.length; i++)
        downloadImageFromUrl(imageUrls[i], customFileName: customFileNames?[i]),
    ]);
    return results.whereType<File>().toList();
  }

  static Future<List<File>> downloadVideosFromUrls(
    List<String> videoUrls, {
    List<String>? customFileNames,
  }) async {
    final results = await Future.wait([
      for (var i = 0; i < videoUrls.length; i++)
        downloadVideoFromUrl(videoUrls[i], customFileName: customFileNames?[i]),
    ]);
    return results.whereType<File>().toList();
  }

  /// Mixed list: passes [File]s through if valid, downloads image/
  /// video URLs. Order is preserved. Parallelized via [Future.wait].
  static Future<List<File>> downloadMixed(
    List<DownloadItem> items, {
    List<String>? customFileNames,
  }) async {
    final futures = <Future<File?>>[];
    for (var i = 0; i < items.length; i++) {
      final item = items[i];
      final name = customFileNames?[i];
      futures.add(switch (item) {
        DownloadItemFile(file: final f) => _passthroughIfValid(f),
        DownloadItemImageUrl(url: final u) => downloadImageFromUrl(
          u,
          customFileName: name,
        ),
        DownloadItemVideoUrl(url: final u) => downloadVideoFromUrl(
          u,
          customFileName: name,
        ),
      });
    }
    final results = await Future.wait(futures);
    return results.whereType<File>().toList();
  }

  // ─── Internals ──────────────────────────────────────────────────

  static Future<File?> _download({
    required String url,
    required String? customFileName,
    required bool Function(String?) validate,
    required Duration receiveTimeout,
    required String label,
  }) async {
    try {
      if (!validate(url)) return null;
      final tempDir = await getTemporaryDirectory();
      final fileName =
          customFileName ??
          '${DateTime.now().millisecondsSinceEpoch}_${p.basename(url)}';
      final filePath = p.join(tempDir.path, fileName);
      final response = await _dio.get<List<int>>(
        url,
        options: Options(
          responseType: ResponseType.bytes,
          receiveTimeout: receiveTimeout,
          sendTimeout: const Duration(seconds: 30),
        ),
      );
      if (response.statusCode == 200 && response.data != null) {
        final file = File(filePath);
        await file.writeAsBytes(response.data!);
        if (await file.exists() && await file.length() > 0) return file;
        if (kDebugMode) {
          debugPrint('[DownloadService] Downloaded $label is empty: $filePath');
        }
      } else if (kDebugMode) {
        debugPrint(
          '[DownloadService] Failed to download $label from $url: ${response.statusCode}',
        );
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[DownloadService] Error downloading $label from $url: $e');
      }
    }
    return null;
  }

  static Future<File?> _passthroughIfValid(File f) async {
    if (await f.exists() && await f.length() > 0) return f;
    return null;
  }
}

/// Typed element for [DownloadService.downloadMixed]. Replaces the
/// previous `List<dynamic>` API so callers get compile-time checks.
sealed class DownloadItem {
  const DownloadItem();
}

final class DownloadItemFile extends DownloadItem {
  const DownloadItemFile(this.file);
  final File file;
}

final class DownloadItemImageUrl extends DownloadItem {
  const DownloadItemImageUrl(this.url);
  final String url;
}

final class DownloadItemVideoUrl extends DownloadItem {
  const DownloadItemVideoUrl(this.url);
  final String url;
}
