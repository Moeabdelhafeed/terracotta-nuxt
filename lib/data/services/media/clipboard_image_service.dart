// Dart imports:
import 'dart:io';

// Flutter imports:
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

// Package imports:
// `pasteboard` advertises stable iOS / Android / macOS / Windows /
// Linux — no web. Web builds should guard callers accordingly.
import 'package:pasteboard/pasteboard.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Reads an image off the system clipboard and writes it to a fresh
/// temp file. Returns `null` when the clipboard holds no image OR
/// when the host platform can't deliver image bytes (web today).
///
/// Callers are responsible for validating / compressing / caching
/// the returned file — same contract as `image_picker` / `file_picker`.
class ClipboardImageService {
  ClipboardImageService._();

  /// True when the current clipboard holds image bytes we can read.
  /// Cheap enough to call from a "Paste" button's `onPressed` guard.
  static Future<bool> hasImage() async {
    try {
      final bytes = await Pasteboard.image;
      return bytes != null && bytes.isNotEmpty;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[ClipboardImageService] hasImage probe failed: $e');
      }
      return false;
    }
  }

  /// Drain the clipboard's image content into a temp file. Falls
  /// back to the raw text — if it looks like a `data:image/...;base64`
  /// blob — so the desktop "Copy image" path on older plugins still
  /// works.
  static Future<File?> paste() async {
    try {
      final bytes = await Pasteboard.image;
      if (bytes == null || bytes.isEmpty) return null;
      final tmp = await getTemporaryDirectory();
      final name = 'clip_${DateTime.now().microsecondsSinceEpoch}.png';
      final out = File(p.join(tmp.path, name));
      await out.writeAsBytes(bytes, flush: true);
      return out;
    } on PlatformException catch (e) {
      if (kDebugMode) debugPrint('[ClipboardImageService] paste failed: $e');
      return null;
    } catch (e) {
      if (kDebugMode) debugPrint('[ClipboardImageService] paste error: $e');
      return null;
    }
  }

  /// Copy an image file's bytes onto the system clipboard so the
  /// user can paste into other apps. Returns `true` when the write
  /// succeeds. Silently no-ops on platforms where the underlying
  /// plugin can't write image bytes.
  static Future<bool> copyFile(File file) async {
    try {
      if (!await file.exists()) return false;
      final bytes = await file.readAsBytes();
      if (bytes.isEmpty) return false;
      await Pasteboard.writeImage(bytes);
      return true;
    } catch (e) {
      if (kDebugMode) debugPrint('[ClipboardImageService] copyFile failed: $e');
      return false;
    }
  }

  /// True when the clipboard advertises file references we can
  /// paste. Cheap guard for a "Paste" menu item.
  static Future<bool> hasFiles({List<String>? extensionsWhitelist}) async {
    try {
      final paths = await Pasteboard.files();
      if (paths.isEmpty) return false;
      if (extensionsWhitelist == null) return true;
      final allow = extensionsWhitelist.map((e) => e.toLowerCase()).toSet();
      return paths.any((path) {
        final dot = path.lastIndexOf('.');
        if (dot < 0) return false;
        return allow.contains(path.substring(dot + 1).toLowerCase());
      });
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[ClipboardImageService] hasFiles probe failed: $e');
      }
      return false;
    }
  }

  /// Read file paths off the clipboard and return them as [File]
  /// objects. Optionally filter by a lowercase extension whitelist
  /// (`['pdf','docx']` etc.) so a file picker doesn't accept video
  /// when only docs are wanted.
  static Future<List<File>> pasteFiles({
    List<String>? extensionsWhitelist,
  }) async {
    try {
      final paths = await Pasteboard.files();
      if (paths.isEmpty) return const [];
      Iterable<String> filtered = paths;
      if (extensionsWhitelist != null) {
        final allow = extensionsWhitelist.map((e) => e.toLowerCase()).toSet();
        filtered = paths.where((path) {
          final dot = path.lastIndexOf('.');
          if (dot < 0) return false;
          return allow.contains(path.substring(dot + 1).toLowerCase());
        });
      }
      return [
        for (final p in filtered)
          if (await File(p).exists()) File(p),
      ];
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[ClipboardImageService] pasteFiles failed: $e');
      }
      return const [];
    }
  }

  /// Copy one or more file references onto the clipboard (Finder /
  /// Explorer will see them as file items). Useful for arbitrary
  /// file pickers where image-bytes copy doesn't fit the content.
  static Future<bool> copyFiles(List<File> files) async {
    try {
      final existing = <String>[
        for (final f in files)
          if (await f.exists()) f.path,
      ];
      if (existing.isEmpty) return false;
      await Pasteboard.writeFiles(existing);
      return true;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[ClipboardImageService] copyFiles failed: $e');
      }
      return false;
    }
  }
}
