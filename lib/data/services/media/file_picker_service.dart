// Dart imports:
import 'dart:io';

// Flutter imports:
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';

/// Arbitrary-file picker (PDFs, docs, archives, audio, custom types).
/// Complements [MediaPickerService] which covers gallery/camera
/// images + videos.
class FilePickerService {
  FilePickerService._();

  /// Pick a single file. Returns `null` if the user cancels.
  ///
  /// Pass [allowedExtensions] (lowercase, no dots — `['pdf', 'docx']`)
  /// along with `type: FileType.custom` to constrain the picker.
  static Future<File?> pickFile({
    FileType type = FileType.any,
    List<String>? allowedExtensions,
    bool withData = false,
  }) async {
    try {
      final result = await FilePicker.pickFiles(
        type: type,
        allowedExtensions: allowedExtensions,
        withData: withData,
      );
      final path = result?.files.single.path;
      return path == null ? null : File(path);
    } catch (e) {
      if (kDebugMode) debugPrint('[FilePickerService] pickFile failed: $e');
      return null;
    }
  }

  /// Pick multiple files. Returns an empty list on cancel / error.
  static Future<List<File>> pickMultipleFiles({
    FileType type = FileType.any,
    List<String>? allowedExtensions,
    bool withData = false,
  }) async {
    try {
      final result = await FilePicker.pickFiles(
        type: type,
        allowedExtensions: allowedExtensions,
        allowMultiple: true,
        withData: withData,
      );
      if (result == null) return [];
      return result.files
          .map((f) => f.path)
          .whereType<String>()
          .map(File.new)
          .toList();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[FilePickerService] pickMultipleFiles failed: $e');
      }
      return [];
    }
  }

  /// Prompt the user for a directory path. Unsupported on web/iOS —
  /// returns `null` there.
  static Future<String?> pickDirectory() async {
    try {
      return await FilePicker.getDirectoryPath();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[FilePickerService] pickDirectory failed: $e');
      }
      return null;
    }
  }

  /// Clear any lingering temporary files from previous picks — call
  /// in low-memory situations or on logout.
  static Future<void> clearCache() async {
    try {
      await FilePicker.clearTemporaryFiles();
    } catch (e) {
      if (kDebugMode) debugPrint('[FilePickerService] clearCache failed: $e');
    }
  }
}
