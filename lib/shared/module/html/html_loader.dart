import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;

import '../../../core/utils/loggers/logger.dart';
import 'html_source.dart';

/// Resolves an [HtmlSource] to its body string. URLs cached in-memory
/// per session. Mirrors `MarkdownLoader` — duplicated rather than
/// generalized so the markdown module stays self-contained.
class HtmlLoader {
  HtmlLoader({Dio? dio}) : _dio = dio ?? Dio();

  final Dio _dio;
  final Map<String, String> _urlCache = {};

  Future<String> resolve(HtmlSource source) async {
    return switch (source) {
      HtmlInline(:final data) => data,
      HtmlAsset(:final path) => _loadAsset(path),
      HtmlFile(:final path) => _loadFile(path),
      HtmlUrl(:final url) => _loadUrl(url),
      HtmlFuture(:final loader) => loader(),
    };
  }

  Future<String> _loadAsset(String path) async {
    try {
      return await rootBundle.loadString(path);
    } catch (e) {
      Logger.m.w('[Html] asset missing: $path: $e');
      return '';
    }
  }

  Future<String> _loadFile(String path) async {
    if (kIsWeb) return '';
    try {
      final f = File(path);
      if (!await f.exists()) return '';
      return f.readAsString();
    } catch (e) {
      Logger.m.w('[Html] file read failed: $path: $e');
      return '';
    }
  }

  Future<String> _loadUrl(String url) async {
    final cached = _urlCache[url];
    if (cached != null) return cached;
    try {
      final res = await _dio.get<String>(
        url,
        options: Options(
          responseType: ResponseType.plain,
          headers: const {'Accept': 'text/html, text/plain'},
        ),
      );
      final body = res.data ?? '';
      _urlCache[url] = body;
      return body;
    } catch (e) {
      Logger.m.w('[Html] url fetch failed: $url: $e');
      return '';
    }
  }

  void clearCache() => _urlCache.clear();
}
