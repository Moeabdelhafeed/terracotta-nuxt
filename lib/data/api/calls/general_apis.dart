import 'package:dio/dio.dart';

import '../../../core/constants/enums/api/request_type.dart';
import '../../../core/types/result.dart';
import '../../models/common/language/language.dart';
import '../api_service.dart';
import '../endpoints/general_endpoints.dart';

/// General API calls (settings, languages, translations).
///
/// Every method returns an `AsyncResult<...>` — pattern-match at the call site.
class GeneralApis {
  GeneralApis._();

  // ─── Per-endpoint log flags ───────────────────────────────

  static ApiLogConfig logGetSettings = kApiLogVerbose;
  static ApiLogConfig logGetLanguages = kApiLogVerbose;
  static ApiLogConfig logGetTranslations = kApiLogVerbose;
  static ApiLogConfig logAddTranslation = kApiLogVerbose;

  // ─── Mock setup ───────────────────────────────────────────

  /// Register mock responses for all endpoints in this class.
  /// Call once at app init when [ApiService.useMock] is true.
  static void installMocks() {
    ApiService.registerMock(
      endpoint: GeneralApiConstants.settings,
      type: RequestType.get,
      data: {
        'theme': 'dark',
        'notifications': true,
        'language': 'en',
      },
    );
    ApiService.registerMock(
      endpoint: GeneralApiConstants.languages,
      type: RequestType.get,
      data: [
        {'code': 'en', 'name': 'English'},
        {'code': 'ar', 'name': 'Arabic'},
        {'code': 'es', 'name': 'Spanish'},
      ],
    );
    ApiService.registerMock(
      endpoint: GeneralApiConstants.translations,
      type: RequestType.get,
      data: {
        'app_name': 'Flutter Base App',
        'welcome': 'Welcome',
        'logout': 'Logout',
      },
    );
  }

  // ─── API methods ──────────────────────────────────────────

  static AsyncResult<Map<String, dynamic>> getSettings({
    CancelToken? cancelToken,
    Duration? timeout,
  }) => ApiService.call(
    () => ApiService().get<Map<String, dynamic>>(
      GeneralApiConstants.settings,
      fromJson: (json) => json,
      logRequest: logGetSettings.request,
      logResponse: logGetSettings.response,
      cancelToken: cancelToken,
      timeout: timeout,
    ),
  );

  static AsyncResult<List<Language>> getLanguages({
    CancelToken? cancelToken,
    Duration? timeout,
  }) => ApiService.call(
    () => ApiService().getList<Language>(
      GeneralApiConstants.languages,
      fromJson: Language.fromJson,
      logRequest: logGetLanguages.request,
      logResponse: logGetLanguages.response,
      cancelToken: cancelToken,
      timeout: timeout,
    ),
  );

  static AsyncResult<Map<String, dynamic>> getTranslations({
    String? group,
    CancelToken? cancelToken,
    Duration? timeout,
  }) => ApiService.call(
    () => ApiService().get<Map<String, dynamic>>(
      GeneralApiConstants.translations,
      queryParameters: {'group': group ?? 'app'},
      fromJson: (json) => json,
      logRequest: logGetTranslations.request,
      logResponse: logGetTranslations.response,
      cancelToken: cancelToken,
      timeout: timeout,
    ),
  );

  static AsyncResult<Map<String, dynamic>> addTranslation({
    required String key,
    required String defaultValue,
    CancelToken? cancelToken,
    Duration? timeout,
  }) => ApiService.call(
    () => ApiService().post<Map<String, dynamic>>(
      GeneralApiConstants.translations,
      data: {
        'group': 'app',
        'key': key,
        'default': defaultValue,
      },
      fromJson: (json) => json,
      logRequest: logAddTranslation.request,
      logResponse: logAddTranslation.response,
      cancelToken: cancelToken,
      timeout: timeout,
    ),
  );

  // ─── Bulk-add missing translations (debug dev-tool) ──────────────────
  //
  // Stub for a future backend endpoint that accepts many (key,
  // defaultValue) pairs in a single round trip. Consumed by
  // `RemoteTranslations.flushMissingKeys` once the backend ships it.
  //
  // Proposed contract:
  //   POST {base}/translations/bulk-add
  //   body: { "group": "app",
  //           "translations": { "key1": "default1", "key2": "default2" } }
  //   returns: the full updated translation map (same shape as
  //            getTranslations).
  //
  // When implemented, uncomment the body below and flip the bulk block
  // in `RemoteTranslations.flushMissingKeys` from comments to code.
  //
  // static AsyncResult<Map<String, dynamic>> addTranslationsBulk(
  //   Map<String, String> entries, {
  //   CancelToken? cancelToken,
  //   Duration? timeout,
  // }) => ApiService.call(
  //   () => ApiService().post<Map<String, dynamic>>(
  //     '${GeneralApiConstants.translations}/bulk-add',
  //     data: { 'group': 'app', 'translations': entries },
  //     fromJson: (json) => json,
  //     cancelToken: cancelToken,
  //     timeout: timeout,
  //   ),
  // );
}
