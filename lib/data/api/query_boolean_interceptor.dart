import 'package:dio/dio.dart';

/// Sends a boolean QUERY parameter as `1` / `0`.
///
/// **Laravel's `boolean` rule does not accept the word `false`.** It
/// takes `true`, `false`, `1`, `0`, `"1"` and `"0"` — and a query
/// string can only carry text, so a Dart `false` arrives as the string
/// `"false"` and the request is refused:
///
/// ```
/// GET /api/workshops/3/price?with_celebration=false&use_wallet=false
/// 422  {"with_celebration": ["The with celebration field must be
///       true or false."]}
/// ```
///
/// That 422 is what priced a workshop booking at nothing: the checkout
/// quotes with both flags on every load, so the quote never landed, the
/// screen fell back to «٠٫٠٠» and «تأكيد والدفع» stayed disabled — a
/// paint-your-piece booking could not be paid for at all. Verified live
/// on 2026-09-08 against `dev-cms`; the same request with `1` / `0`
/// answers with the real total.
///
/// **Only the QUERY.** A POST body is JSON, where `false` is a real
/// boolean and the server reads it correctly — rewriting it there would
/// send a number where a flag is declared.
///
/// Nested maps and lists are walked too, because `products[0][...]`
/// style parameters go out as a nested structure and a flag could
/// appear inside one.
Interceptor createQueryBooleanInterceptor() => InterceptorsWrapper(
  onRequest: (options, handler) {
    if (options.queryParameters.isNotEmpty) {
      options.queryParameters = Map<String, dynamic>.from(
        _walk(options.queryParameters) as Map,
      );
    }
    return handler.next(options);
  },
);

/// `true` → `1`, `false` → `0`, everything else untouched.
Object? _walk(Object? value) => switch (value) {
  final bool flag => flag ? 1 : 0,
  final Map<String, dynamic> map => {
    for (final entry in map.entries) entry.key: _walk(entry.value),
  },
  final List<dynamic> list => [for (final item in list) _walk(item)],
  _ => value,
};
