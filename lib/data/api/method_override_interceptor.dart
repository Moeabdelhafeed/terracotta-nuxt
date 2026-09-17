import 'package:dio/dio.dart';

import '../../core/utils/loggers/logger.dart';

/// Turns PUT / PATCH / DELETE into a POST carrying the real verb.
///
/// **The Terracotta production host blocks real PUT, PATCH and DELETE
/// requests — they never reach the application.** This is the single
/// easiest thing to get wrong on this backend: every write works
/// perfectly against a local Laravel and then silently stops working
/// once the app points at production.
///
/// The API docs, the OpenAPI spec and the screen-to-API mapping all
/// show the TRUE verb, because that is what the endpoint is. Sending it
/// that way fails. So the conversion happens here, once, instead of at
/// sixty call sites that each have to remember:
///
/// ```
/// PUT /api/addresses/12          →   POST /api/addresses/12
///                                    X-HTTP-Method-Override: PUT
/// ```
///
/// A `_method` query parameter is sent as well as the header. They are
/// equivalent server-side, and the query string is the one a proxy
/// cannot strip — belt and braces, because a stripped header here means
/// a delete that reads as a create.
///
/// GET and POST pass through untouched.
const _overrideHeader = 'X-HTTP-Method-Override';
const _overrideQueryKey = '_method';

const _rewritten = {'PUT', 'PATCH', 'DELETE'};

Interceptor createMethodOverrideInterceptor() => InterceptorsWrapper(
  onRequest: (options, handler) {
    final verb = options.method.toUpperCase();
    if (!_rewritten.contains(verb)) {
      return handler.next(options);
    }

    options
      ..method = 'POST'
      ..headers[_overrideHeader] = verb
      ..queryParameters = {
        ...options.queryParameters,
        _overrideQueryKey: verb,
      };

    Logger.a.d('[MethodOverride] $verb ${options.path} sent as POST');
    return handler.next(options);
  },
);
