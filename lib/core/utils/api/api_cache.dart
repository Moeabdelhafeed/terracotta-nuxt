import 'dart:async';

import 'package:dio/dio.dart';

import 'api_constants.dart';

// ---------------------------------------------------------------------------
// Request cache — in-memory LRU with TTL
// ---------------------------------------------------------------------------

/// In-memory LRU cache for GET responses.
class ApiRequestCache {
  final Map<String, ApiCacheEntry> _cache = {};

  /// Live entry count (expired entries included until next read) —
  /// surfaced by the debug overlay's cache inspector.
  int get length => _cache.length;

  /// Get a cached response, or null if missing/expired.
  dynamic get(String key) {
    final entry = _cache[key];
    if (entry == null) return null;
    if (entry.isExpired) {
      _cache.remove(key);
      return null;
    }
    return entry.response;
  }

  /// Store a response with the given TTL.
  void put(String key, dynamic response, Duration ttl) {
    if (_cache.length >= kApiCacheMaxSize) {
      _cache.remove(_cache.keys.first);
    }
    _cache[key] = ApiCacheEntry(response, DateTime.now().add(ttl));
  }

  /// Remove a specific entry.
  void invalidate(String key) => _cache.remove(key);

  /// Clear all entries.
  void clear() => _cache.clear();

  /// Build a cache key from endpoint + query params.
  static String key(String endpoint, Map<String, dynamic>? query) {
    final q = query != null
        ? Uri(
            queryParameters: query.map((k, v) => MapEntry(k, v.toString())),
          ).query
        : '';
    return '$endpoint?$q';
  }
}

// ---------------------------------------------------------------------------
// Request deduplication — concurrent identical GETs share one Future
// ---------------------------------------------------------------------------

/// Prevents duplicate concurrent requests to the same endpoint.
class ApiRequestDeduplicator {
  final Map<String, Future<Response>> _pending = {};

  /// Returns an existing pending Future for [key], or null.
  Future<Response>? get(String key) => _pending[key];

  /// Register a pending request.
  void register(String key, Future<Response> future) => _pending[key] = future;

  /// Remove a completed/failed request.
  void remove(String key) => _pending.remove(key);

  /// Clear all pending entries.
  void clear() => _pending.clear();
}

// ---------------------------------------------------------------------------
// Request throttle — limits max concurrent requests
// ---------------------------------------------------------------------------

/// Limits the number of concurrent HTTP requests.
class ApiRequestThrottle {
  int _active = 0;
  final List<Completer<void>> _queue = [];

  /// Wait for a slot. Returns immediately if under the limit.
  Future<void> acquire() async {
    if (_active < kApiMaxConcurrent) {
      _active++;
      return;
    }
    final completer = Completer<void>();
    _queue.add(completer);
    return completer.future;
  }

  /// Release a slot and unblock the next queued request.
  void release() {
    _active--;
    if (_queue.isNotEmpty) {
      _active++;
      _queue.removeAt(0).complete();
    }
  }
}
