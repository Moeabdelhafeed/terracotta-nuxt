import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;

import '../../../core/utils/loggers/logger.dart';
import 'markdown_source.dart';

/// What resolving a [MarkdownSource] produced.
///
/// A failure used to come back as the EMPTY STRING, and the widget
/// renders empty as `SizedBox.shrink()` — so a missing legal document,
/// a changelog the network never returned and a genuinely blank file
/// were the same blank screen, with nothing to retry and nothing said.
/// The legal screen and the FAQ both render through here.
@immutable
sealed class MarkdownLoadResult {
  const MarkdownLoadResult();
}

/// The body, which may legitimately be empty.
final class MarkdownLoaded extends MarkdownLoadResult {
  const MarkdownLoaded(this.body);
  final String body;
}

/// The source could not be read.
final class MarkdownLoadFailed extends MarkdownLoadResult {
  const MarkdownLoadFailed({required this.error, this.stackTrace});
  final Object error;
  final StackTrace? stackTrace;
}

/// Resolves a [MarkdownSource] to its body. URLs are cached in-memory
/// for the session.
class MarkdownLoader {
  MarkdownLoader({Dio? dio}) : _dio = dio ?? Dio();

  final Dio _dio;

  /// Bodies already read, keyed by source.
  ///
  /// STATIC, and that is the point. A loader is per-widget, so a
  /// per-instance cache did nothing for the case that actually shows:
  /// a document scrolled out of a lazy list is DISPOSED, and scrolling
  /// back builds a new widget, a new loader, and a fresh read — one
  /// frame of spinner, then the tall document, and everything below it
  /// jumps. Holding the body across instances makes a remount
  /// instant.
  ///
  /// Only successes go in. A cached failure is a failure that never
  /// retries.
  static final Map<String, String> _bodies = {};

  /// The cap. Documents are text, but a long session on a wiki-shaped
  /// screen should not grow forever; the oldest goes.
  static const _maxCached = 32;

  static void _remember(String key, String body) {
    if (_bodies.length >= _maxCached && !_bodies.containsKey(key)) {
      _bodies.remove(_bodies.keys.first);
    }
    _bodies[key] = body;
  }

  Future<MarkdownLoadResult> resolve(MarkdownSource source) async {
    return switch (source) {
      MarkdownInline(:final data) => MarkdownLoaded(data),
      MarkdownAsset(:final path) => _loadAsset(path),
      MarkdownFile(:final path) => _loadFile(path),
      MarkdownUrl(:final url) => _loadUrl(url),
      MarkdownFuture(:final loader) => _loadFuture(loader),
    };
  }

  Future<MarkdownLoadResult> _loadAsset(String path) async {
    final cached = _bodies['asset:$path'];
    if (cached != null) return MarkdownLoaded(cached);
    try {
      final body = await rootBundle.loadString(path);
      _remember('asset:$path', body);
      return MarkdownLoaded(body);
    } catch (e, st) {
      Logger.m.w('[Markdown] asset missing: $path', error: e, stackTrace: st);
      return MarkdownLoadFailed(error: e, stackTrace: st);
    }
  }

  Future<MarkdownLoadResult> _loadFile(String path) async {
    final cached = _bodies['file:$path'];
    if (cached != null) return MarkdownLoaded(cached);
    if (kIsWeb) {
      // `dart:io` File is unavailable on web — a fact about the
      // platform, not a failure to read anything.
      return MarkdownLoadFailed(
        error: UnsupportedError('file sources are unavailable on web'),
      );
    }
    try {
      final f = File(path);
      if (!await f.exists()) {
        return MarkdownLoadFailed(
          error: FileSystemException('no such file', path),
        );
      }
      final body = await f.readAsString();
      _remember('file:$path', body);
      return MarkdownLoaded(body);
    } catch (e, st) {
      Logger.m.w(
        '[Markdown] file read failed: $path',
        error: e,
        stackTrace: st,
      );
      return MarkdownLoadFailed(error: e, stackTrace: st);
    }
  }

  Future<MarkdownLoadResult> _loadUrl(String url) async {
    final cached = _bodies['url:$url'];
    if (cached != null) return MarkdownLoaded(cached);
    try {
      final res = await _dio.get<String>(
        url,
        options: Options(
          responseType: ResponseType.plain,
          headers: const {'Accept': 'text/markdown, text/plain'},
        ),
      );
      final body = res.data ?? '';
      // Only a SUCCESS is cached. A failure cached is a failure that
      // never retries, for the rest of the session.
      _remember('url:$url', body);
      return MarkdownLoaded(body);
    } catch (e, st) {
      Logger.m.w('[Markdown] url fetch failed: $url', error: e, stackTrace: st);
      return MarkdownLoadFailed(error: e, stackTrace: st);
    }
  }

  Future<MarkdownLoadResult> _loadFuture(
    Future<String> Function() loader,
  ) async {
    try {
      return MarkdownLoaded(await loader());
    } catch (e, st) {
      Logger.m.w('[Markdown] loader threw', error: e, stackTrace: st);
      // A caller's own loader threw. It used to take the whole
      // `FutureBuilder` down with it, since nothing caught it here.
      return MarkdownLoadFailed(error: e, stackTrace: st);
    }
  }

  /// Forgets every cached body.
  static void clearCache() => _bodies.clear();

  /// Forgets one source, so the next read goes back to it.
  static void invalidate(String key) => _bodies.remove(key);
}
