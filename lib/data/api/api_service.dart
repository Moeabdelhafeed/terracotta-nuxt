import 'dart:io';

import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:flutter/foundation.dart';

import '../../core/constants/enums/api/request_type.dart';
import '../../core/devtools/network_capture.dart';
import '../../core/devtools/network_sim.dart';
import '../../core/di/service_locator.dart';
import '../../core/error/app_exception.dart';
import '../../core/types/paginated_result.dart';
import '../../core/types/result.dart';
import '../../core/utils/api/api_cache.dart';
import '../../core/utils/api/api_constants.dart';
import '../../core/utils/loggers/logger.dart';
import '../blocs/auth/auth_bloc.dart';
import '../blocs/preferences/preferences_cubit.dart';
import '../models/api/envelope_list.dart';
import '../services/remote_config_service.dart';
import 'api_config.dart';
import 'api_interceptors.dart';
import 'api_response_handler.dart';
import 'method_override_interceptor.dart';
import 'query_boolean_interceptor.dart';
import 'terracotta_headers_interceptor.dart';

export '../../core/utils/api/api_constants.dart'
    show
        kApiTimeout,
        kApiUploadTimeout,
        kApiCacheDefaultTtl,
        ApiLogConfig,
        kApiLogDefault,
        kApiLogSilent,
        kApiLogVerbose;

// ---------------------------------------------------------------------------
// ApiService — singleton HTTP client with typed Result<T, AppException> returns.
// ---------------------------------------------------------------------------

/// Centralized HTTP client built on Dio.
///
/// **Features:**
/// - Automatic retry on transient failures (timeouts, 503)
/// - 401 token refresh with request replay
/// - CancelToken for in-flight cancellation
/// - Request deduplication (identical concurrent GETs share one call)
/// - In-memory LRU cache with configurable TTL
/// - File download with progress
/// - Global error handler callback
/// - Mock mode for UI development without a backend
/// - Custom interceptor hooks
/// - Request throttle (max concurrent limit)
///
/// Every public method returns `AsyncResult<T>` (i.e.
/// `Future<Result<T, AppException>>`). Pattern-match on the result or
/// chain with `map` / `flatMap` / `onSuccess` / `onFailure` — see
/// `core/types/result.dart`.
///
/// ```dart
/// final result = await ApiService().get<User>('/users/1', fromJson: User.fromJson);
/// final message = result.when(
///   success: (u) => 'Hello ${u.name}',
///   failure: (e) => 'Error: ${e.message}',
/// );
/// ```
class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;

  late Dio _dio;

  static String baseUrl = BaseApiConstants.baseUrl;
  static bool logRequests = true;
  static bool logResponses = true;

  /// What to do with a 401, handed the request that got one.
  ///
  /// Return a fresh bearer to have the request replayed with it; return
  /// null to let the failure through. Terracotta has NO refresh token,
  /// so it always answers null and uses this to end the dead session —
  /// see `SessionExpiry`.
  static Future<String?> Function(RequestOptions request)? onTokenExpired;

  /// Global error callback — fires for every failed request.
  static void Function(AppException error)? onError;

  /// When true, all requests return mock responses instead of hitting
  /// the network.
  ///
  /// **Live override**: the debug overlay's mock-mode toggle drives
  /// `DebugOverlayPrefs.mockMode` and the boot wiring registers a
  /// listener that mirrors the value here. Keep this static so legacy
  /// call sites (e.g. test setups) still work.
  static bool useMock = false;

  /// Custom mock handler. If set, it takes priority over [_mockRegistry].
  /// Return `Result.success(<raw data>)` or `Result.failure(<AppException>)`.
  static Result<Object?, AppException> Function(
    String endpoint,
    RequestType type,
  )?
  mockHandler;

  /// Mock registry — multiple API classes register their mocks here.
  /// Key format: `"METHOD:endpoint"` (e.g. `"GET:users/1"`) or `"*:endpoint"` (any method).
  static final Map<String, _MockEntry> _mockRegistry = {};

  /// Register a mock response for an endpoint + HTTP method.
  /// If [type] is null, matches any HTTP method for this endpoint.
  ///
  /// ```dart
  /// ApiService.registerMock(
  ///   endpoint: '/users/1',
  ///   type: RequestType.get,
  ///   data: {'id': 1, 'name': 'Mock User'},
  /// );
  /// ```
  static void registerMock({
    required String endpoint,
    RequestType? type,
    Object? data,
    int statusCode = 200,
    String? message,
    bool success = true,
  }) {
    final key = '${type?.name.toUpperCase() ?? '*'}:$endpoint';
    _mockRegistry[key] = _MockEntry(
      data: data,
      statusCode: statusCode,
      message: message,
      success: success,
    );
  }

  /// Remove all registered mocks.
  static void clearMocks() => _mockRegistry.clear();

  /// Read-only inventory (`METHOD:endpoint` → status/success) — the
  /// debug overlay's mock tool lists what's covered.
  static Map<String, ({int statusCode, bool success})> get mockInventory => {
    for (final e in _mockRegistry.entries)
      e.key: (statusCode: e.value.statusCode, success: e.value.success),
  };

  /// Add custom interceptors (analytics, feature flags, A/B testing headers).
  static final List<Interceptor> customInterceptors = [];

  // ─── Internal state ───────────────────────────────────────

  final ApiRequestCache _cache = ApiRequestCache();
  final ApiRequestDeduplicator _dedup = ApiRequestDeduplicator();
  final ApiRequestThrottle _throttle = ApiRequestThrottle();

  ApiService._internal() {
    _initializeDio();
  }

  /// Reinitialize Dio (e.g. after changing [baseUrl]).
  /// The configured Dio, for tests that need to drive a real response
  /// through the real interceptor chain.
  @visibleForTesting
  Dio get debugDio => _dio;

  void reinitialize() {
    _dio.close();
    _dedup.clear();
    _cache.clear();
    _initializeDio();
  }

  void _initializeDio() {
    var effectiveBaseUrl = baseUrl;
    try {
      Uri.parse(effectiveBaseUrl);
      if (!effectiveBaseUrl.startsWith('http')) effectiveBaseUrl = '';
    } catch (_) {
      effectiveBaseUrl = '';
    }

    _dio = Dio(
      BaseOptions(
        baseUrl: effectiveBaseUrl,
        connectTimeout: kApiTimeout,
        receiveTimeout: kApiTimeout,
        validateStatus: (status) => status != null && status < 600,
        responseType: ResponseType.plain,
        contentType: 'application/json',
        headers: <String, dynamic>{
          'X-API-TOKEN': RemoteConfigService.apiToken,
          'Accept-Language': _resolveLanguageCode(),
          'Accept': 'application/json',
        },
      ),
    );

    if (kDebugMode) {
      _dio.httpClientAdapter = IOHttpClientAdapter(
        createHttpClient: () {
          final client = HttpClient();
          // Only for local dev servers with self-signed certs.
          client.badCertificateCallback = (cert, host, port) => true;
          return client;
        },
      );
    }

    _dio.interceptors.addAll([
      // FIRST: the four headers the Terracotta API requires on every
      // request. Missing X-API-TOKEN is a 401; missing X-Device-Id,
      // X-Platform or (on mobile) X-FCM-Token is a 422 that reads like
      // a broken endpoint.
      createTerracottaHeadersInterceptor(
        resolveDeviceId: _resolveDeviceId,
        resolveFcmToken: _resolveFcmToken,
      ),
      createAuthInterceptor(
        resolveToken: _resolveToken,
        resolveLanguageCode: _resolveLanguageCode,
        // Read at ERROR time, not here. `_instance` is a `static
        // final` built on first touch, which is before bootstrap gets
        // to assign the hook — captured directly, the interceptor
        // holds the null it had at init and no 401 is ever handled.
        onTokenExpired: (request) async => onTokenExpired?.call(request),
        dio: _dio,
      ),
      // A query string carries text, and Laravel's `boolean` rule
      // refuses the word `false`. Rewrites a flag to 1 / 0 before
      // anything downstream reads the query.
      createQueryBooleanInterceptor(),
      // MUST sit before retry: a retried request has to already be
      // the POST the host accepts, not the PUT it silently drops.
      createMethodOverrideInterceptor(),
      createRetryInterceptor(dio: _dio),
      createMaintenanceInterceptor(),
      ...customInterceptors,
      // Network simulator (artificial latency / forced failures) and
      // capture for the debug overlay's network inspector. Both sit
      // AFTER retry/auth so capture records the final attempt only,
      // not every intermediate retry. Gated by `kDebugMode` so prod
      // builds skip the work entirely.
      if (kDebugMode) createNetworkSimInterceptor(),
      if (kDebugMode) createNetworkCaptureInterceptor(),
      if (kDebugMode)
        createLoggingInterceptor(
          shouldLogRequests: () => logRequests,
          shouldLogResponses: () => logResponses,
        ),
    ]);
  }

  // ═══════════════════════════════════════════════════════════
  // PUBLIC API — single-object responses
  // ═══════════════════════════════════════════════════════════

  AsyncResult<T> get<T>(
    String endpoint, {
    Map<String, dynamic>? queryParameters,
    Map<String, String>? headers,
    required T Function(Map<String, dynamic>) fromJson,
    Duration? timeout,
    CancelToken? cancelToken,
    Duration? cacheTtl,
    bool deduplicate = true,
    bool? logRequest,
    bool? logResponse,
  }) => _request<T>(
    endpoint: endpoint,
    type: RequestType.get,
    parser: (r) => handleSingleResponse<T>(r, fromJson),
    queryParameters: queryParameters,
    headers: headers,
    timeout: timeout,
    cancelToken: cancelToken,
    cacheTtl: cacheTtl,
    deduplicate: deduplicate,
    logRequest: logRequest,
    logResponse: logResponse,
  );

  AsyncResult<T> post<T>(
    String endpoint, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    Map<String, String>? headers,
    required T Function(Map<String, dynamic>) fromJson,
    Duration? timeout,
    CancelToken? cancelToken,
    void Function(int, int)? onSendProgress,
    bool? logRequest,
    bool? logResponse,
  }) => _request<T>(
    endpoint: endpoint,
    type: RequestType.post,
    parser: (r) => handleSingleResponse<T>(r, fromJson),
    data: data,
    queryParameters: queryParameters,
    headers: headers,
    timeout: timeout,
    cancelToken: cancelToken,
    onSendProgress: onSendProgress,
    logRequest: logRequest,
    logResponse: logResponse,
  );

  AsyncResult<T> put<T>(
    String endpoint, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    Map<String, String>? headers,
    required T Function(Map<String, dynamic>) fromJson,
    Duration? timeout,
    CancelToken? cancelToken,
    bool? logRequest,
    bool? logResponse,
  }) => _request<T>(
    endpoint: endpoint,
    type: RequestType.put,
    parser: (r) => handleSingleResponse<T>(r, fromJson),
    data: data,
    queryParameters: queryParameters,
    headers: headers,
    timeout: timeout,
    cancelToken: cancelToken,
    logRequest: logRequest,
    logResponse: logResponse,
  );

  AsyncResult<T> patch<T>(
    String endpoint, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    Map<String, String>? headers,
    required T Function(Map<String, dynamic>) fromJson,
    Duration? timeout,
    CancelToken? cancelToken,
    bool? logRequest,
    bool? logResponse,
  }) => _request<T>(
    endpoint: endpoint,
    type: RequestType.patch,
    parser: (r) => handleSingleResponse<T>(r, fromJson),
    data: data,
    queryParameters: queryParameters,
    headers: headers,
    timeout: timeout,
    cancelToken: cancelToken,
    logRequest: logRequest,
    logResponse: logResponse,
  );

  AsyncResult<T> delete<T>(
    String endpoint, {
    Map<String, dynamic>? queryParameters,
    Map<String, String>? headers,
    required T Function(Map<String, dynamic>) fromJson,
    Duration? timeout,
    CancelToken? cancelToken,
    bool? logRequest,
    bool? logResponse,
  }) => _request<T>(
    endpoint: endpoint,
    type: RequestType.delete,
    parser: (r) => handleSingleResponse<T>(r, fromJson),
    queryParameters: queryParameters,
    headers: headers,
    timeout: timeout,
    cancelToken: cancelToken,
    logRequest: logRequest,
    logResponse: logResponse,
  );

  // ═══════════════════════════════════════════════════════════
  // PUBLIC API — list responses
  // ═══════════════════════════════════════════════════════════

  AsyncResult<List<T>> getList<T>(
    String endpoint, {
    Map<String, dynamic>? queryParameters,
    Map<String, String>? headers,
    required T Function(Map<String, dynamic>) fromJson,
    Duration? timeout,
    CancelToken? cancelToken,
    Duration? cacheTtl,
    bool? logRequest,
    bool? logResponse,
  }) => _request<List<T>>(
    endpoint: endpoint,
    type: RequestType.get,
    parser: (r) => handleListResponse<T>(r, fromJson),
    queryParameters: queryParameters,
    headers: headers,
    timeout: timeout,
    cancelToken: cancelToken,
    cacheTtl: cacheTtl,
    logRequest: logRequest,
    logResponse: logResponse,
  );

  /// A list response, keeping the envelope's own `meta` — see
  /// [EnvelopeList]. Use it only where the endpoint sends one; every
  /// other list wants [getList].
  AsyncResult<EnvelopeList<T>> getListWithMeta<T>(
    String endpoint, {
    Map<String, dynamic>? queryParameters,
    Map<String, String>? headers,
    required T Function(Map<String, dynamic>) fromJson,
    Duration? timeout,
    CancelToken? cancelToken,
    Duration? cacheTtl,
    bool? logRequest,
    bool? logResponse,
  }) => _request<EnvelopeList<T>>(
    endpoint: endpoint,
    type: RequestType.get,
    parser: (r) => handleListWithMetaResponse<T>(r, fromJson),
    queryParameters: queryParameters,
    headers: headers,
    timeout: timeout,
    cancelToken: cancelToken,
    cacheTtl: cacheTtl,
    logRequest: logRequest,
    logResponse: logResponse,
  );

  AsyncResult<EnvelopeOne<T>> getSingleWithMeta<T>(
    String endpoint, {
    Map<String, dynamic>? queryParameters,
    Map<String, String>? headers,
    required T Function(Map<String, dynamic>) fromJson,
    Duration? timeout,
    CancelToken? cancelToken,
    Duration? cacheTtl,
    bool? logRequest,
    bool? logResponse,
  }) => _request<EnvelopeOne<T>>(
    endpoint: endpoint,
    type: RequestType.get,
    parser: (r) => handleSingleWithMetaResponse<T>(r, fromJson),
    queryParameters: queryParameters,
    headers: headers,
    timeout: timeout,
    cancelToken: cancelToken,
    cacheTtl: cacheTtl,
    logRequest: logRequest,
    logResponse: logResponse,
  );

  AsyncResult<List<T>> postList<T>(
    String endpoint, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    Map<String, String>? headers,
    required T Function(Map<String, dynamic>) fromJson,
    Duration? timeout,
    CancelToken? cancelToken,
    bool? logRequest,
    bool? logResponse,
  }) => _request<List<T>>(
    endpoint: endpoint,
    type: RequestType.post,
    parser: (r) => handleListResponse<T>(r, fromJson),
    data: data,
    queryParameters: queryParameters,
    headers: headers,
    timeout: timeout,
    cancelToken: cancelToken,
    logRequest: logRequest,
    logResponse: logResponse,
  );

  // ═══════════════════════════════════════════════════════════
  // PUBLIC API — paginated responses
  // ═══════════════════════════════════════════════════════════

  AsyncResult<PaginatedResult<T>> getPaginated<T>(
    String endpoint, {
    Map<String, dynamic>? queryParameters,
    Map<String, String>? headers,
    required T Function(Map<String, dynamic>) fromJson,
    Duration? timeout,
    CancelToken? cancelToken,
    bool? logRequest,
    bool? logResponse,
  }) => _request<PaginatedResult<T>>(
    endpoint: endpoint,
    type: RequestType.get,
    parser: (r) => handlePaginatedResponse<T>(r, fromJson),
    queryParameters: queryParameters,
    headers: headers,
    timeout: timeout,
    cancelToken: cancelToken,
    logRequest: logRequest,
    logResponse: logResponse,
  );

  AsyncResult<PaginatedResult<T>> postPaginated<T>(
    String endpoint, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    Map<String, String>? headers,
    required T Function(Map<String, dynamic>) fromJson,
    Duration? timeout,
    CancelToken? cancelToken,
    bool? logRequest,
    bool? logResponse,
  }) => _request<PaginatedResult<T>>(
    endpoint: endpoint,
    type: RequestType.post,
    parser: (r) => handlePaginatedResponse<T>(r, fromJson),
    data: data,
    queryParameters: queryParameters,
    headers: headers,
    timeout: timeout,
    cancelToken: cancelToken,
    logRequest: logRequest,
    logResponse: logResponse,
  );

  // ═══════════════════════════════════════════════════════════
  // PUBLIC API — download
  // ═══════════════════════════════════════════════════════════

  /// Download a file to [savePath] with optional progress.
  AsyncResult<void> download(
    String endpoint,
    String savePath, {
    Map<String, dynamic>? queryParameters,
    Map<String, String>? headers,
    CancelToken? cancelToken,
    Duration? timeout,
    void Function(int received, int total)? onProgress,
  }) async {
    try {
      await _dio.download(
        endpoint,
        savePath,
        queryParameters: queryParameters,
        options: Options(
          headers: headers,
          receiveTimeout: timeout ?? kApiUploadTimeout,
        ),
        cancelToken: cancelToken,
        onReceiveProgress: onProgress,
      );
      return const Result.success(null);
    } catch (e, st) {
      final err = AppException.fromError(e, st);
      onError?.call(err);
      return Result<void, AppException>.failure(err);
    }
  }

  /// Clear the response cache.
  void clearCache() => _cache.clear();

  /// Live response-cache entry count — debug overlay inspector.
  int get cacheEntryCount => _cache.length;

  /// Invalidate a specific cache entry.
  void invalidateCache(
    String endpoint, {
    Map<String, dynamic>? queryParameters,
  }) {
    _cache.invalidate(ApiRequestCache.key(endpoint, queryParameters));
  }

  /// Static error wrapper — catches anything the inner [apiCall] forgets
  /// to turn into a `Result`. Rarely needed because every public method
  /// above already returns a `Result` and never throws.
  static AsyncResult<T> call<T>(
    AsyncResult<T> Function() apiCall, {
    String? context,
  }) async {
    try {
      return await apiCall();
    } catch (e, st) {
      final ctx = context ?? 'API call';
      Logger.a.e('$ctx: $e', stackTrace: st);
      final err = AppException.fromError(e, st);
      onError?.call(err);
      return Result<T, AppException>.failure(err);
    }
  }

  void dispose() {
    _dio.close();
    _dedup.clear();
    _cache.clear();
  }

  // ═══════════════════════════════════════════════════════════
  // UNIFIED REQUEST
  // ═══════════════════════════════════════════════════════════

  Future<Result<T, AppException>> _request<T>({
    required String endpoint,
    required RequestType type,
    required Result<T, AppException> Function(Response response) parser,
    Map<String, dynamic>? queryParameters,
    Object? data,
    Map<String, String>? headers,
    Duration? timeout,
    CancelToken? cancelToken,
    void Function(int, int)? onSendProgress,
    void Function(int, int)? onReceiveProgress,
    Duration? cacheTtl,
    bool deduplicate = false,
    bool? logRequest,
    bool? logResponse,
  }) async {
    // ─── Mock mode ───────────────────────────────────────
    if (useMock) {
      final mocked = _resolveMock<T>(endpoint, type);
      if (kDebugMode) {
        final shouldLog = logRequest ?? logRequests;
        if (shouldLog) {
          Logger.a.i(
            '[MOCK] ${type.name.toUpperCase()} $endpoint${queryParameters != null ? '?$queryParameters' : ''}',
          );
        }
      }
      if (mocked case Failure(:final error)) onError?.call(error);
      return mocked;
    }

    // ─── Cache check (GET only) ──────────────────────────
    final isGet = type == RequestType.get;
    final cacheKey = isGet
        ? ApiRequestCache.key(endpoint, queryParameters)
        : null;

    if (isGet && cacheKey != null) {
      final cached = _cache.get(cacheKey);
      if (cached is Result<T, AppException>) return cached;
    }

    // ─── Deduplication (GET only) ────────────────────────
    if (isGet && deduplicate && cacheKey != null) {
      final pending = _dedup.get(cacheKey);
      if (pending != null) {
        try {
          final response = await pending;
          return parser(response);
        } catch (e, st) {
          return Result<T, AppException>.failure(AppException.fromError(e, st));
        }
      }
    }

    // ─── Throttle ────────────────────────────────────────
    await _throttle.acquire();

    try {
      final isFormData = data is FormData;
      final options = Options(
        headers: headers,
        responseType: ResponseType.plain,
        method: type.name.toUpperCase(),
        contentType: isFormData ? 'multipart/form-data' : 'application/json',
        extra: <String, dynamic>{
          'logRequest': logRequest,
          'logResponse': logResponse,
        },
      );

      if (timeout != null) {
        options.sendTimeout = timeout;
        options.receiveTimeout = timeout;
      }

      final future = _dio.request(
        endpoint,
        data: data,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
        onSendProgress: onSendProgress,
        onReceiveProgress: onReceiveProgress,
      );

      if (isGet && deduplicate && cacheKey != null) {
        _dedup.register(cacheKey, future);
      }

      final response = await future;

      if (cacheKey != null) _dedup.remove(cacheKey);

      final result = parser(response);

      if (isGet && result.isSuccess && cacheTtl != null && cacheKey != null) {
        _cache.put(cacheKey, result, cacheTtl);
      }

      if (result case Failure(:final error)) onError?.call(error);

      return result;
    } catch (e, st) {
      if (cacheKey != null) _dedup.remove(cacheKey);
      final err = AppException.fromError(e, st);
      if (err is UnknownException) {
        Logger.a.e('Unexpected error', error: e, stackTrace: st);
      }
      onError?.call(err);
      return Result<T, AppException>.failure(err);
    } finally {
      _throttle.release();
    }
  }

  Result<T, AppException> _resolveMock<T>(String endpoint, RequestType type) {
    if (mockHandler != null) {
      return mockHandler!(endpoint, type).map((data) => data as T);
    }
    final entry =
        _mockRegistry['${type.name.toUpperCase()}:$endpoint'] ??
        _mockRegistry['*:$endpoint'];
    if (entry == null) {
      // No mock registered — treat as a successful empty response.
      return Result<T, AppException>.success(null as T);
    }
    if (entry.success) return Result<T, AppException>.success(entry.data as T);
    return Result<T, AppException>.failure(_mockError(entry));
  }

  AppException _mockError(_MockEntry entry) {
    final msg = entry.message ?? 'Mock error';
    final code = entry.statusCode.toString();
    if (entry.statusCode == 401 || entry.statusCode == 403) {
      return AuthException(message: msg, code: code);
    }
    if (entry.statusCode == 404) {
      return NotFoundException(message: msg, code: code);
    }
    if (entry.statusCode >= 500) {
      return ServerException(message: msg, code: code);
    }
    return ValidationException(message: msg, code: code);
  }

  // ═══════════════════════════════════════════════════════════
  // HELPERS
  // ═══════════════════════════════════════════════════════════

  String _resolveLanguageCode() {
    try {
      if (getIt.isRegistered<PreferencesCubit>()) {
        final code = getIt<PreferencesCubit>().state.language.locale;
        if (code.isNotEmpty) return code;
      }
    } catch (_) {}
    try {
      final code = PlatformDispatcher.instance.locale.languageCode;
      if (code.isNotEmpty) return code;
    } catch (_) {}
    return 'en';
  }

  /// A STABLE per-install id. Guest carts, sessions and push all key
  /// off it, and a guest who registers is promoted in place by matching
  /// it — so a value that changes between launches silently orphans the
  /// customer's guest cart.
  ///
  /// Seeded once by `DeviceInfoUtils.getDeviceId()` during bootstrap and
  /// cached here, because the request path must stay synchronous.
  static String _cachedDeviceId = '';

  /// Called from `bootstrap()` once the device info is available.
  static void seedDeviceId(String id) {
    if (id.isNotEmpty) _cachedDeviceId = id;
  }

  String _resolveDeviceId() => _cachedDeviceId;

  /// The FCM token, or an empty string when push has not registered
  /// yet. The header must still be PRESENT on mobile — the server wants
  /// the key, and empty is a truthful "no push token on this device".
  String _resolveFcmToken() {
    try {
      if (getIt.isRegistered<AuthBloc>()) {
        // NOT state-gated. The API rejects an empty `X-FCM-Token` with a
        // 422 on every mobile request, and guest browsing — the shop,
        // the gallery, the workshops — is unauthenticated by design.
        return getIt<AuthBloc>().fcmToken;
      }
    } catch (_) {}
    return '';
  }

  String _resolveToken() {
    try {
      if (getIt.isRegistered<AuthBloc>()) {
        final bloc = getIt<AuthBloc>();
        final pending = bloc.pendingToken;
        if (pending.isNotEmpty) return pending;
        final bearer = bloc.bearerToken;
        if (bearer.isNotEmpty) return bearer;
      }
    } catch (_) {}
    return '';
  }
}

// ---------------------------------------------------------------------------
// _MockEntry — internal registry entry
// ---------------------------------------------------------------------------

class _MockEntry {
  const _MockEntry({
    this.data,
    this.statusCode = 200,
    this.message,
    this.success = true,
  });

  final Object? data;
  final int statusCode;
  final String? message;
  final bool success;
}
