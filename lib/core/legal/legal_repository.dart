import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:path_provider/path_provider.dart';

import '../../data/api/api_config.dart';
import '../../data/services/remote_config_service.dart';
import '../utils/loggers/logger.dart';
import 'legal_content.dart';
import 'legal_page.dart';

/// Fetches a [LegalPage]'s content using the source-resolution chain:
///
/// 1. **Backend HTML** (only when `legal_source_mode == 'backend'`
///    and `legal_<slug>_endpoint_html` is set).
/// 2. **Remote Markdown** from `legal_<slug>_url_md`.
/// 3. **Cached Markdown** — last successful remote-md fetch saved to
///    the app cache directory.
/// 4. **Bundled Markdown** — `assets/legal/<slug>.md`.
///
/// The first non-empty step wins. Successful remote-md fetches refresh
/// the cache; the cache only seeds itself from a previous successful
/// remote fetch (never from the bundled asset).
class LegalRepository {
  LegalRepository({Dio? dio}) : _dio = dio ?? Dio();

  final Dio _dio;

  Future<LegalContent?> load(LegalPage page) async {
    // Disabled pages return null so the screen can render a "not
    // available" state without trying any of the network steps.
    if (!RemoteConfigService.legalEnabled(page.slug)) return null;

    // Open-source licenses are rendered by Flutter's built-in
    // LicensePage — the route widget special-cases this enum value
    // and never calls into the repo.
    if (page == LegalPage.licenses) return null;

    final mode = RemoteConfigService.legalSourceMode;

    if (mode == 'backend') {
      final html = await _fetchBackendHtml(page);
      if (html != null) {
        return LegalContent(
          kind: LegalContentKind.html,
          origin: LegalContentOrigin.backend,
          body: html,
        );
      }
    }

    final remote = await _fetchRemoteMarkdown(page);
    if (remote != null) {
      // Side effect: update local cache for offline use.
      unawaited(_writeCache(page, remote));
      return LegalContent(
        kind: LegalContentKind.markdown,
        origin: LegalContentOrigin.remoteMarkdown,
        body: remote,
      );
    }

    final cached = await _readCache(page);
    if (cached != null) {
      return LegalContent(
        kind: LegalContentKind.markdown,
        origin: LegalContentOrigin.cache,
        body: cached,
      );
    }

    final bundled = await _readBundled(page);
    if (bundled != null) {
      return LegalContent(
        kind: LegalContentKind.markdown,
        origin: LegalContentOrigin.bundled,
        body: bundled,
      );
    }

    return null;
  }

  // ─── Backend HTML ────────────────────────────────────────

  Future<String?> _fetchBackendHtml(LegalPage page) async {
    final endpoint = RemoteConfigService.legalEndpointHtml(page.slug);
    if (endpoint.isEmpty) return null;
    final url = endpoint.startsWith('http')
        ? endpoint
        : '${BaseApiConstants.baseUrl.replaceAll(RegExp(r'/$'), '')}'
              '${endpoint.startsWith('/') ? endpoint : '/$endpoint'}';
    try {
      final res = await _dio.get<String>(
        url,
        options: Options(
          responseType: ResponseType.plain,
          headers: const {'Accept': 'text/html, text/plain'},
        ),
      );
      final body = res.data;
      if (body == null || body.isEmpty) return null;
      return body;
    } catch (e) {
      Logger.m.w('[Legal] backend HTML fetch failed for ${page.slug}: $e');
      return null;
    }
  }

  // ─── Remote Markdown ─────────────────────────────────────

  Future<String?> _fetchRemoteMarkdown(LegalPage page) async {
    final url = RemoteConfigService.legalUrlMd(page.slug);
    if (url.isEmpty) return null;
    try {
      final res = await _dio.get<String>(
        url,
        options: Options(
          responseType: ResponseType.plain,
          headers: const {'Accept': 'text/markdown, text/plain'},
        ),
      );
      final body = res.data;
      if (body == null || body.isEmpty) return null;
      return body;
    } catch (e) {
      Logger.m.w('[Legal] remote MD fetch failed for ${page.slug}: $e');
      return null;
    }
  }

  // ─── Cache ───────────────────────────────────────────────

  Future<File?> _cacheFile(LegalPage page) async {
    try {
      final dir = await getApplicationCacheDirectory();
      final legalDir = Directory('${dir.path}/legal');
      if (!await legalDir.exists()) {
        await legalDir.create(recursive: true);
      }
      return File('${legalDir.path}/${page.slug}.md');
    } catch (e) {
      Logger.m.w('[Legal] cache dir unavailable: $e');
      return null;
    }
  }

  Future<void> _writeCache(LegalPage page, String body) async {
    final file = await _cacheFile(page);
    if (file == null) return;
    try {
      await file.writeAsString(body, flush: true);
    } catch (e) {
      Logger.m.w('[Legal] cache write failed: $e');
    }
  }

  Future<String?> _readCache(LegalPage page) async {
    final file = await _cacheFile(page);
    if (file == null) return null;
    try {
      if (!await file.exists()) return null;
      final body = await file.readAsString();
      if (body.isEmpty) return null;
      return body;
    } catch (e) {
      Logger.m.w('[Legal] cache read failed: $e');
      return null;
    }
  }

  // ─── Bundled ─────────────────────────────────────────────

  Future<String?> _readBundled(LegalPage page) async {
    try {
      return await rootBundle.loadString(page.bundledAssetPath);
    } catch (e) {
      Logger.m.w('[Legal] bundled asset missing for ${page.slug}: $e');
      return null;
    }
  }
}
