import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

/// Single captured request/response pair held in the ring buffer.
///
/// Built by the [NetworkCaptureInterceptor] and consumed by the
/// debug-overlay network view. Mutable so the same instance can be
/// stamped at request time and again at response time without
/// allocating a fresh object.
class NetworkCaptureEntry {
  NetworkCaptureEntry({
    required this.id,
    required this.method,
    required this.url,
    required this.startedAt,
    this.requestHeaders = const {},
    this.requestBody,
    this.requestQuery,
  });

  /// Monotonic id — used as the key for tap navigation between list
  /// and detail panes.
  final int id;
  final String method;
  final String url;
  final DateTime startedAt;
  final Map<String, dynamic> requestHeaders;
  final Object? requestBody;
  final Map<String, dynamic>? requestQuery;

  // ─── Filled in on response / error ─────────────────────────
  int? statusCode;
  String? statusMessage;
  Map<String, dynamic>? responseHeaders;
  Object? responseBody;
  Duration? duration;
  String? errorType;
  String? errorMessage;

  bool get hasResponse => statusCode != null || errorType != null;

  /// `true` when the captured response was a network/transport error
  /// rather than a non-2xx HTTP response.
  bool get isError => errorType != null;

  /// Color bucket for status — green (2xx), amber (3xx/4xx),
  /// red (5xx / network error), grey (in-flight).
  StatusBucket get bucket {
    if (isError) return StatusBucket.error;
    final code = statusCode;
    if (code == null) return StatusBucket.pending;
    if (code >= 500) return StatusBucket.error;
    if (code >= 400) return StatusBucket.clientError;
    if (code >= 300) return StatusBucket.redirect;
    if (code >= 200) return StatusBucket.success;
    return StatusBucket.pending;
  }
}

enum StatusBucket { pending, success, redirect, clientError, error }

/// In-memory ring buffer + stream of captured network calls. Singleton
/// because the Dio interceptor is stateless and emits to a shared sink
/// the debug view subscribes to.
///
/// Holds at most [_kCap] entries. Web-safe — no disk involvement.
/// Disabled by default; [enabled] is flipped on by [ApiService] only
/// when debug capture is wanted (kDebugMode + override).
class NetworkCapture {
  NetworkCapture._();

  static const int _kCap = 100;

  static final List<NetworkCaptureEntry> _entries = [];
  static final StreamController<void> _changes =
      StreamController<void>.broadcast();
  static int _nextId = 0;

  /// Toggle capture without ripping out the interceptor — convenient
  /// when devs want to pause noise while reproducing a bug.
  static bool enabled = kDebugMode;

  static List<NetworkCaptureEntry> get entries =>
      List.unmodifiable(_entries.reversed);

  /// Fires once after every add or mutation. Listeners rebuild from
  /// [entries] — no payload to keep events cheap.
  static Stream<void> get changes => _changes.stream;

  static int nextId() => ++_nextId;

  static void add(NetworkCaptureEntry entry) {
    if (!enabled) return;
    _entries.add(entry);
    while (_entries.length > _kCap) {
      _entries.removeAt(0);
    }
    _emit();
  }

  /// Mutate-and-notify — the entry is already in the buffer; this just
  /// signals subscribers that fields have been filled in.
  static void touch() => _emit();

  static void clear() {
    _entries.clear();
    _emit();
  }

  static void _emit() {
    if (!_changes.isClosed) _changes.add(null);
  }
}

/// Dio interceptor that mirrors every request into [NetworkCapture].
///
/// Bodies are cloned via JSON encoding so the captured snapshot can't
/// be mutated by retries / interceptors that run after this one. Bodies
/// that don't JSON-encode fall back to `toString()`.
Interceptor createNetworkCaptureInterceptor() {
  return InterceptorsWrapper(
    onRequest: (options, handler) {
      if (NetworkCapture.enabled) {
        final entry = NetworkCaptureEntry(
          id: NetworkCapture.nextId(),
          method: options.method,
          url: '${options.baseUrl}${options.path}'.replaceAll(
            RegExp(r'(?<!:)//+'),
            '/',
          ),
          startedAt: DateTime.now(),
          requestHeaders: Map<String, dynamic>.from(options.headers),
          requestBody: _safeClone(options.data),
          requestQuery: options.queryParameters.isEmpty
              ? null
              : Map<String, dynamic>.from(options.queryParameters),
        );
        // Stash the entry on the request extras so onResponse / onError
        // can find it without us maintaining a second map keyed by URL.
        options.extra['_netCaptureEntry'] = entry;
        NetworkCapture.add(entry);
      }
      handler.next(options);
    },
    onResponse: (response, handler) {
      final entry =
          response.requestOptions.extra['_netCaptureEntry']
              as NetworkCaptureEntry?;
      if (entry != null) {
        entry.statusCode = response.statusCode;
        entry.statusMessage = response.statusMessage;
        entry.responseHeaders = _flattenHeaders(response.headers);
        entry.responseBody = _safeClone(response.data);
        entry.duration = DateTime.now().difference(entry.startedAt);
        NetworkCapture.touch();
      }
      handler.next(response);
    },
    onError: (err, handler) {
      final entry =
          err.requestOptions.extra['_netCaptureEntry'] as NetworkCaptureEntry?;
      if (entry != null) {
        entry.statusCode = err.response?.statusCode;
        entry.statusMessage = err.response?.statusMessage;
        entry.responseHeaders = err.response == null
            ? null
            : _flattenHeaders(err.response!.headers);
        entry.responseBody = _safeClone(err.response?.data);
        entry.duration = DateTime.now().difference(entry.startedAt);
        entry.errorType = err.type.name;
        entry.errorMessage = err.message ?? err.toString();
        NetworkCapture.touch();
      }
      handler.next(err);
    },
  );
}

/// Best-effort deep clone — JSON round-trip when possible so later
/// mutations don't bleed into the captured snapshot. Falls back to
/// `toString()` for non-encodable payloads (FormData, Uint8List, etc).
Object? _safeClone(Object? value) {
  if (value == null) return null;
  if (value is FormData) {
    return {
      'fields': value.fields.map((e) => '${e.key}=${e.value}').toList(),
      'files': value.files.map((e) => e.key).toList(),
    };
  }
  try {
    return jsonDecode(jsonEncode(value));
  } catch (_) {
    return value.toString();
  }
}

Map<String, dynamic> _flattenHeaders(Headers headers) {
  return {for (final k in headers.map.keys) k: headers.map[k]?.join(', ')};
}
