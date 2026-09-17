import 'dart:convert';

import 'package:dio/dio.dart';
import '../../core/di/service_locator.dart';
import '../../core/maintenance/maintenance_cubit.dart';
import '../../core/utils/api/api_constants.dart';
import '../../core/utils/loggers/logger.dart';

// ---------------------------------------------------------------------------
// Auth interceptor
// ---------------------------------------------------------------------------

/// Adds Authorization + Accept-Language headers.
/// Handles 401 token refresh with automatic request replay.
///
/// [onTokenExpired] is handed the request that 401'd, because what to do
/// about one depends entirely on which it was: an API with no refresh
/// token — Terracotta — answers null and uses the callback to end the
/// dead session instead, and it can only tell a dead session from a
/// wrong password by looking at the path.
InterceptorsWrapper createAuthInterceptor({
  required String Function() resolveToken,
  required String Function() resolveLanguageCode,
  required Future<String?> Function(RequestOptions request)? onTokenExpired,
  required Dio dio,
}) => InterceptorsWrapper(
  onRequest: (options, handler) async {
    options.headers['Accept-Language'] = resolveLanguageCode();
    final token = resolveToken();
    if (token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  },
  // A 401 arrives HERE, not in `onError`.
  //
  // `ApiService` sets `validateStatus: status < 600`, so Dio treats
  // every status as a successful response and hands the envelope to the
  // caller to read `success` from. Nothing is thrown, `onError` never
  // runs, and a hook wired only to that path handles no 401 in this app
  // at all — which is exactly what happened: the app kept a dead token,
  // kept showing a cached profile, and failed one auth-only screen at a
  // time with no explanation.
  onResponse: (response, handler) async {
    if (response.statusCode == 401 && onTokenExpired != null) {
      final replayed = await _replay(
        response.requestOptions,
        onTokenExpired,
        dio,
      );
      if (replayed != null) return handler.resolve(replayed);
    }
    handler.next(response);
  },
  // Kept for a host that DOES throw on a 401 — a timeout wrapper, a
  // caller that narrowed `validateStatus`, a different base URL.
  onError: (error, handler) async {
    if (error.response?.statusCode == 401 && onTokenExpired != null) {
      final replayed = await _replay(error.requestOptions, onTokenExpired, dio);
      if (replayed != null) return handler.resolve(replayed);
    }
    handler.next(error);
  },
);

/// Offer the 401 to [onTokenExpired] and, if it answers with a fresh
/// bearer, send the request again with it. Null means let the failure
/// through — which is every time on an API with no refresh token.
///
/// The replay is marked so a second 401 cannot ask again: without that,
/// a hook that keeps answering the same dead token loops forever.
Future<Response<dynamic>?> _replay(
  RequestOptions request,
  Future<String?> Function(RequestOptions request) onTokenExpired,
  Dio dio,
) async {
  if (request.extra['_authReplayed'] == true) return null;
  try {
    final newToken = await onTokenExpired(request);
    if (newToken == null || newToken.isEmpty) return null;
    request
      ..extra['_authReplayed'] = true
      ..headers['Authorization'] = 'Bearer $newToken';
    return await dio.fetch(request);
  } catch (e) {
    Logger.a.e('Token refresh failed: $e');
    return null;
  }
}

// ---------------------------------------------------------------------------
// Retry interceptor
// ---------------------------------------------------------------------------

/// Auto-retries idempotent requests (GET, DELETE) on transient failures.
/// Uses linear backoff: delay * attemptNumber.
InterceptorsWrapper createRetryInterceptor({
  required Dio dio,
}) => InterceptorsWrapper(
  onError: (error, handler) async {
    final isRetryable =
        error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.sendTimeout ||
        error.type == DioExceptionType.receiveTimeout ||
        error.type == DioExceptionType.connectionError ||
        (error.response?.statusCode == 503);

    final isIdempotent =
        error.requestOptions.method == 'GET' ||
        error.requestOptions.method == 'DELETE';

    final attempt = (error.requestOptions.extra['_retryAttempt'] as int?) ?? 0;

    if (isRetryable && isIdempotent && attempt < kApiMaxRetries) {
      final delay = kApiRetryDelay * (attempt + 1);
      await Future.delayed(delay);

      error.requestOptions.extra['_retryAttempt'] = attempt + 1;
      Logger.a.w(
        'Retrying ${error.requestOptions.uri} (attempt ${attempt + 1}/$kApiMaxRetries)',
      );

      try {
        final response = await dio.fetch(error.requestOptions);
        return handler.resolve(response);
      } catch (e) {
        return handler.next(error);
      }
    }

    handler.next(error);
  },
);

// ---------------------------------------------------------------------------
// Maintenance interceptor
// ---------------------------------------------------------------------------

/// Watches every response for 503 Service Unavailable. When seen,
/// flips `MaintenanceCubit.markApiUnavailable` so the gate appears
/// mid-session. Any successful (2xx) response clears the flag so the
/// app exits maintenance once the backend recovers.
///
/// Honors `Retry-After` header (seconds) — populates the screen's
/// ETA so users get a sensible countdown.
InterceptorsWrapper createMaintenanceInterceptor() => InterceptorsWrapper(
  onResponse: (response, handler) {
    final status = response.statusCode ?? 0;
    if (status >= 200 && status < 300) {
      _maintenanceCubit()?.clearApiUnavailable();
    }
    handler.next(response);
  },
  onError: (error, handler) {
    if (error.response?.statusCode == 503) {
      final retryAfter = _parseRetryAfter(error.response);
      _maintenanceCubit()?.markApiUnavailable(retryAfter: retryAfter);
    }
    handler.next(error);
  },
);

MaintenanceCubit? _maintenanceCubit() {
  if (!getIt.isRegistered<MaintenanceCubit>()) return null;
  return getIt<MaintenanceCubit>();
}

Duration? _parseRetryAfter(Response? response) {
  final raw = response?.headers.value('retry-after');
  if (raw == null || raw.isEmpty) return null;
  // RFC 7231 allows delta-seconds or HTTP-date. Only delta-seconds
  // is supported here so the parser stays web-safe (HTTP-date parser
  // lives in dart:io which doesn't compile on web).
  final seconds = int.tryParse(raw);
  if (seconds != null) return Duration(seconds: seconds);
  final date = DateTime.tryParse(raw);
  if (date != null) {
    final delta = date.difference(DateTime.now());
    return delta.isNegative ? null : delta;
  }
  return null;
}

// ---------------------------------------------------------------------------
// Logging interceptor
// ---------------------------------------------------------------------------

/// Logs requests, responses, and errors in debug mode.
/// Respects per-request and global log flags.
InterceptorsWrapper createLoggingInterceptor({
  required bool Function() shouldLogRequests,
  required bool Function() shouldLogResponses,
}) => InterceptorsWrapper(
  onRequest: (options, handler) {
    options.extra['_startTime'] = DateTime.now();
    final shouldLog =
        (options.extra['logRequest'] as bool?) ?? shouldLogRequests();
    if (shouldLog) _logRequest(options);
    handler.next(options);
  },
  onResponse: (response, handler) {
    final shouldLog =
        (response.requestOptions.extra['logResponse'] as bool?) ??
        shouldLogResponses();
    final isSuccess =
        (response.statusCode ?? 0) >= 200 && (response.statusCode ?? 0) < 300;
    if (!isSuccess || shouldLog) _logResponse(response);
    handler.next(response);
  },
  onError: (error, handler) {
    _logError(error);
    handler.next(error);
  },
);

int? _elapsedMs(RequestOptions options) {
  final start = options.extra['_startTime'];
  if (start is! DateTime) return null;
  return DateTime.now().difference(start).inMilliseconds;
}

// ---------------------------------------------------------------------------
// Logging helpers
// ---------------------------------------------------------------------------

void _logRequest(RequestOptions options) {
  try {
    final headers = Map<String, dynamic>.from(options.headers);
    for (final key in headers.keys.toList()) {
      if (kSensitiveHeaders.contains(key.toLowerCase())) headers[key] = '***';
    }
    headers.removeWhere(
      (k, _) => kExcludedLogHeaders.contains(k.toLowerCase()),
    );

    final buf = StringBuffer('[>] ${options.method} ${options.uri}');
    if (headers.isNotEmpty) buf.write('\n  Headers: ${_toJson(headers)}');
    final body = _prepareBodyForLog(options.data);
    if (body != null) buf.write('\n  Body: ${_toJson(body)}');
    if (options.queryParameters.isNotEmpty) {
      buf.write('\n  Query: ${_toJson(options.queryParameters)}');
    }
    Logger.a.i(buf.toString());
  } catch (e) {
    Logger.a.e('Log request failed: $e');
  }
}

void _logResponse(Response response) {
  try {
    final status = response.statusCode ?? 0;
    final tag = status < 300 ? '+' : '-';
    dynamic body = response.data;
    if (body is String) {
      try {
        body = jsonDecode(body);
      } catch (_) {}
    }
    final buf = StringBuffer('[$tag] $status ${response.requestOptions.uri}');
    final elapsed = _elapsedMs(response.requestOptions);
    if (elapsed != null) buf.write('\n[t] ${elapsed}ms');
    buf.write('\n  ${_toJson(body)}');
    Logger.a.i(buf.toString());
  } catch (e) {
    Logger.a.e('Log response failed: $e');
  }
}

void _logError(DioException error) {
  try {
    final buf = StringBuffer(
      '[!] ${error.response?.statusCode ?? 'N/A'} ${error.requestOptions.uri}',
    );
    final elapsed = _elapsedMs(error.requestOptions);
    if (elapsed != null) buf.write('\n[t] ${elapsed}ms');
    buf.write('\n  Type: ${error.type}\n  Message: ${error.message}');
    Logger.a.e(buf.toString());
  } catch (_) {}
}

dynamic _prepareBodyForLog(dynamic data) {
  if (data == null) return null;
  if (data is FormData) {
    final map = <String, dynamic>{};
    for (final e in data.fields) {
      map[e.key] = e.value;
    }
    for (final e in data.files) {
      map[e.key] = 'File(${e.value.filename}, ${e.value.length}b)';
    }
    return map;
  }
  return data;
}

/// Public entry point to the smart-truncating JSON formatter below.
/// Useful for showcase / tooling code that wants to produce log-shaped
/// output without going through a real HTTP request.
String formatApiLogJson(dynamic data) => _toJson(data);

/// Encodes [data] as pretty JSON with **per-subset** middle-truncation:
/// - Each string longer than [kApiLogMaxStringLength] is middle-truncated
///   independently — one huge field won't eat a sibling's budget.
/// - Each array longer than [kApiLogMaxArrayItems] keeps its first/last
///   halves with a `... +N truncated ...` marker between them.
/// - As a last-resort safety net, the final string is middle-truncated
///   if it still exceeds [kApiLogTotalCeiling].
String _toJson(dynamic data) {
  if (data == null) return 'null';
  try {
    final prepared = _prepareForLog(data);
    var result = const JsonEncoder.withIndent('  ').convert(prepared);
    // Replace the array-truncation sentinel with a bare, unquoted marker.
    result = result.replaceAllMapped(
      _arrayMarkerPattern,
      (m) => '... +${m.group(1)} truncated ...',
    );
    if (result.length <= kApiLogTotalCeiling) return result;
    // Ceiling hit — final middle-truncate.
    const half = kApiLogTotalCeiling ~/ 2;
    final cut = result.length - half * 2;
    return '${result.substring(0, half)}\n... +$cut chars truncated ...\n${result.substring(result.length - half)}';
  } catch (_) {
    return data.toString();
  }
}

/// Sentinel used inside [_prepareForLog] to mark array elisions. It survives
/// JSON encoding as a quoted string, then we un-quote it with
/// [_arrayMarkerPattern] before returning.
const String _arrayMarkerPrefix = '__ARRAY_TRUNCATED_';
final _arrayMarkerPattern = RegExp(r'"__ARRAY_TRUNCATED_(\d+)__"');

/// Recursively builds a log-safe copy of [value] with strings and arrays
/// middle-truncated to their configured limits. Each subtree is budgeted
/// independently — no total counter, no sibling starvation.
dynamic _prepareForLog(dynamic value) {
  if (value is String) {
    if (value.length <= kApiLogMaxStringLength) return value;
    const half = kApiLogMaxStringLength ~/ 2;
    final cut = value.length - half * 2;
    return '${value.substring(0, half)} ... +$cut chars ... ${value.substring(value.length - half)}';
  }
  if (value is List) {
    if (value.length <= kApiLogMaxArrayItems) {
      return value.map(_prepareForLog).toList();
    }
    const half = kApiLogMaxArrayItems ~/ 2;
    final cut = value.length - half * 2;
    return [
      ...value.take(half).map(_prepareForLog),
      '$_arrayMarkerPrefix${cut}__',
      ...value.skip(value.length - half).map(_prepareForLog),
    ];
  }
  if (value is Map) {
    return value.map((k, v) => MapEntry(k, _prepareForLog(v)));
  }
  return value;
}
