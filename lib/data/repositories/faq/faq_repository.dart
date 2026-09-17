import 'dart:convert';

import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../../../core/utils/loggers/logger.dart';
import '../../../shared/module/faq/faq_models.dart';

/// FAQ data source. Implement to wire a custom backend.
// ignore: one_member_abstracts
abstract class FaqRepository {
  /// Fetch the canonical FAQ payload. May surface errors via
  /// throwing — [TieredFaqRepository] falls back through every
  /// configured tier when one throws or returns empty.
  Future<FaqData> load();
}

/// In-memory repository — used as the static fallback tier when API
/// + Remote Config are unreachable. Also useful for tests + previews.
class InMemoryFaqRepository implements FaqRepository {
  const InMemoryFaqRepository(this._data);

  factory InMemoryFaqRepository.of({
    required List<FaqCategory> categories,
    required List<FaqEntry> entries,
  }) => InMemoryFaqRepository(
    FaqData(categories: categories, entries: entries),
  );

  final FaqData _data;

  @override
  Future<FaqData> load() async => _data;
}

/// HTTP repository — GETs a JSON endpoint that returns the
/// `FaqData.toJson()` shape.
class HttpFaqRepository implements FaqRepository {
  HttpFaqRepository({
    required this.url,
    this.headers,
    this.timeout = const Duration(seconds: 6),
    http.Client? client,
  }) : _client = client ?? http.Client();

  final String url;
  final Map<String, String>? headers;
  final Duration timeout;
  final http.Client _client;

  @override
  Future<FaqData> load() async {
    final resp = await _client
        .get(Uri.parse(url), headers: headers)
        .timeout(timeout);
    if (resp.statusCode >= 400) {
      throw Exception('FAQ HTTP ${resp.statusCode}');
    }
    final json = jsonDecode(resp.body);
    if (json is! Map<String, dynamic>) {
      throw const FormatException('FAQ payload not an object');
    }
    return FaqData.fromJson(json);
  }
}

/// Reads the FAQ payload from a single Firebase Remote Config key.
/// The value must be a JSON string matching `FaqData.toJson()`.
/// Defaults to key `faq_payload`.
class RemoteConfigFaqRepository implements FaqRepository {
  RemoteConfigFaqRepository({this.key = 'faq_payload'});

  final String key;

  @override
  Future<FaqData> load() async {
    final raw = FirebaseRemoteConfig.instance.getString(key);
    if (raw.isEmpty) {
      throw Exception('Remote Config key "$key" empty');
    }
    final json = jsonDecode(raw);
    if (json is! Map<String, dynamic>) {
      throw const FormatException(
        'Remote Config FAQ payload not an object',
      );
    }
    return FaqData.fromJson(json);
  }
}

/// Three-tier fallback repository:
///   1. **api** — fetches from a remote HTTP endpoint
///   2. **remoteConfig** — falls back to a Firebase RC JSON blob
///   3. **static** — falls back to a bundled in-memory dataset
///
/// Each tier is consulted in order. Any tier may throw (network /
/// parse / 4xx-5xx) — the next tier picks up. The first tier to
/// produce a non-empty [FaqData] wins. When all three fail, returns
/// [FaqData.empty] and logs a warning.
class TieredFaqRepository implements FaqRepository {
  TieredFaqRepository({
    this.api,
    this.remoteConfig,
    required this.staticFallback,
  });

  /// Primary tier — usually [HttpFaqRepository].
  final FaqRepository? api;

  /// Secondary tier — usually [RemoteConfigFaqRepository].
  final FaqRepository? remoteConfig;

  /// Tertiary tier — always present. Bundled with the app so
  /// offline-first launches still render something.
  final FaqRepository staticFallback;

  @override
  Future<FaqData> load() async {
    final tiers = <(String, FaqRepository?)>[
      ('api', api),
      ('remoteConfig', remoteConfig),
      ('static', staticFallback),
    ];
    for (final (name, repo) in tiers) {
      if (repo == null) continue;
      try {
        final data = await repo.load();
        if (!data.isEmpty) {
          if (kDebugMode) {
            Logger.m.d(
              '[Faq] loaded via tier=$name '
              '(${data.entries.length} entries, ${data.categories.length} categories)',
            );
          }
          return data;
        }
        if (kDebugMode) {
          Logger.m.d('[Faq] tier=$name returned empty; falling through');
        }
      } catch (e, st) {
        Logger.m.w(
          '[Faq] tier=$name threw — falling through',
          error: e,
          stackTrace: st,
        );
      }
    }
    Logger.m.w('[Faq] all tiers failed — returning empty payload');
    return FaqData.empty;
  }
}
