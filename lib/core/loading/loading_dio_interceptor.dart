import 'package:dio/dio.dart';

import 'loading_cubit.dart';
import 'loading_show_options.dart';
import 'loading_token.dart';

/// Opt-in Dio interceptor — automatically shows the loading overlay
/// while a request is in flight.
///
/// **Disabled by default.** Mount with `enabled: true` to activate
/// app-wide, or leave default and mark individual requests via
/// `Options(extra: {'showLoader': true})`.
///
/// Examples:
///
/// ```dart
/// // Per-request opt-in (recommended)
/// dio.post('/save',
///   data: payload,
///   options: Options(extra: {
///     'showLoader': true,
///     'loaderLabel': 'Saving',
///   }),
/// );
///
/// // App-wide auto-show (be careful — silent polling will flash)
/// dio.interceptors.add(
///   LoadingDioInterceptor(
///     cubit: getIt<LoadingCubit>(),
///     enabled: true,
///   ),
/// );
/// ```
///
/// Per-request override keys (in `RequestOptions.extra`):
/// - `showLoader` (bool) — force show / hide regardless of [enabled]
/// - `loaderLabel` (String) — label shown beneath the spinner
/// - `loaderTag` (String) — pass to dedupe overlapping requests
class LoadingDioInterceptor extends Interceptor {
  LoadingDioInterceptor({
    required this.cubit,
    this.enabled = false,
    this.shouldShow,
  });

  final LoadingCubit cubit;

  /// Master switch. False (default) means only requests that opt in
  /// via `extra['showLoader'] = true` trigger the overlay.
  final bool enabled;

  /// Optional predicate — for finer-grained control than
  /// per-request flags. Called when [enabled] is true and no per-request
  /// `showLoader` override is set.
  final bool Function(RequestOptions options)? shouldShow;

  static const String _kTokenKey = '__loadingToken';

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (_resolveShow(options)) {
      final tag = options.extra['loaderTag'] as String?;
      final label = options.extra['loaderLabel'] as String?;
      final token = cubit.show(LoadingShowOptions(label: label, tag: tag));
      options.extra[_kTokenKey] = token;
    }
    handler.next(options);
  }

  @override
  void onResponse(
    Response<dynamic> response,
    ResponseInterceptorHandler handler,
  ) {
    _disposeToken(response.requestOptions);
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    _disposeToken(err.requestOptions);
    handler.next(err);
  }

  bool _resolveShow(RequestOptions options) {
    final perReq = options.extra['showLoader'];
    if (perReq is bool) return perReq;
    if (!enabled) return false;
    if (shouldShow != null) return shouldShow!(options);
    return true;
  }

  void _disposeToken(RequestOptions options) {
    final token = options.extra[_kTokenKey];
    if (token is LoadingToken) {
      token.dispose();
      options.extra.remove(_kTokenKey);
    }
  }
}
