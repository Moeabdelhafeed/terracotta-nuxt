// Dart imports:
import 'dart:io';

// Package imports:
import 'package:dio/dio.dart';
// Flutter imports:
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;

/// Progress callback. [sent] bytes of [total]; total is -1 when the
/// server doesn't report a content length up front.
typedef UploadProgress = void Function(int sent, int total);

/// Dual of [DownloadService] — POST/PUT files with progress + cancel.
/// Uses a dedicated [Dio] instance so interceptors on the main API
/// client don't rewrite upload URLs.
class UploadService {
  UploadService({Dio? dio}) : _dio = dio ?? Dio();

  final Dio _dio;

  /// Upload a single [file] as multipart/form-data.
  ///
  /// [fieldName] is the form field key the backend expects
  /// (defaults to `'file'`). Extra form fields go in [data]. Extra
  /// headers go in [headers].
  ///
  /// Pass a [cancelToken] to abort mid-upload:
  /// ```dart
  /// final token = CancelToken();
  /// UploadService().uploadFile(url: ..., file: ..., cancelToken: token);
  /// // later:
  /// token.cancel('user aborted');
  /// ```
  Future<Response<T>?> uploadFile<T>({
    required String url,
    required File file,
    String fieldName = 'file',
    Map<String, dynamic> data = const {},
    Map<String, String> headers = const {},
    String method = 'POST',
    UploadProgress? onProgress,
    CancelToken? cancelToken,
  }) async {
    try {
      final form = FormData.fromMap({
        ...data,
        fieldName: await MultipartFile.fromFile(
          file.path,
          filename: p.basename(file.path),
        ),
      });

      return await _dio.request<T>(
        url,
        data: form,
        cancelToken: cancelToken,
        onSendProgress: onProgress,
        options: Options(
          method: method,
          headers: headers,
          contentType: 'multipart/form-data',
        ),
      );
    } on DioException catch (e) {
      if (CancelToken.isCancel(e)) {
        if (kDebugMode) {
          debugPrint('[UploadService] upload canceled: ${e.message}');
        }
      } else if (kDebugMode) {
        debugPrint(
          '[UploadService] HTTP error: ${e.response?.statusCode} ${e.message}',
        );
      }
      return null;
    } catch (e) {
      if (kDebugMode) debugPrint('[UploadService] upload failed: $e');
      return null;
    }
  }

  /// Upload multiple files on the same request. All files share
  /// [fieldName] (appended as `fieldName[]` on the wire).
  Future<Response<T>?> uploadFiles<T>({
    required String url,
    required List<File> files,
    String fieldName = 'files',
    Map<String, dynamic> data = const {},
    Map<String, String> headers = const {},
    String method = 'POST',
    UploadProgress? onProgress,
    CancelToken? cancelToken,
  }) async {
    try {
      final parts = await Future.wait(
        files.map(
          (f) => MultipartFile.fromFile(f.path, filename: p.basename(f.path)),
        ),
      );
      final form = FormData.fromMap({
        ...data,
        fieldName: parts,
      });

      return await _dio.request<T>(
        url,
        data: form,
        cancelToken: cancelToken,
        onSendProgress: onProgress,
        options: Options(
          method: method,
          headers: headers,
          contentType: 'multipart/form-data',
        ),
      );
    } on DioException catch (e) {
      if (CancelToken.isCancel(e)) {
        if (kDebugMode) {
          debugPrint('[UploadService] upload canceled: ${e.message}');
        }
      } else if (kDebugMode) {
        debugPrint(
          '[UploadService] HTTP error: ${e.response?.statusCode} ${e.message}',
        );
      }
      return null;
    } catch (e) {
      if (kDebugMode) debugPrint('[UploadService] upload failed: $e');
      return null;
    }
  }
}
