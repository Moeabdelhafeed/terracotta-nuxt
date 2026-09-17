import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../utils/loggers/logger.dart';

/// Issues a HEAD probe to a known reliable URL. Returns true when the
/// host responded with any 2xx/3xx within [timeout]. Anything else
/// (timeout, DNS fail, 5xx, exception) returns false.
///
/// The probe URL is the cubit's responsibility — usually
/// [ConnectivityConfig.probeUrl] (default `gstatic.com/generate_204`).
class ConnectivityProbe {
  ConnectivityProbe({Dio? dio}) : _dio = dio ?? Dio();

  final Dio _dio;

  Future<bool> ping({
    required String url,
    required Duration timeout,
  }) async {
    if (url.isEmpty) return true; // disabled = trust connectivity_plus
    // Web: most third-party probe URLs (gstatic, cloudflare, etc.)
    // reject CORS preflights from arbitrary origins, so the HEAD ping
    // always fails with `XMLHttpRequest onError` and screams in the
    // console. Skip the probe on web — connectivity_plus's
    // `navigator.onLine` becomes the source of truth, even though
    // it's coarser than mobile. See `ConnectivityCubit` for the
    // surrounding strategy + the README note.
    if (kIsWeb) return true;
    try {
      final res = await _dio.head<void>(
        url,
        options: Options(
          // `sendTimeout` is invalid on web for bodyless requests —
          // skipped entirely now that web short-circuits, but we
          // still drop it for HEAD on mobile too (no body to send).
          receiveTimeout: timeout,
          followRedirects: true,
          validateStatus: (s) => s != null && s >= 200 && s < 400,
          // Ensure no auth interceptors leak into a public probe.
          extra: const {'logRequest': false, 'logResponse': false},
        ),
      );
      return (res.statusCode ?? 500) < 400;
    } catch (e) {
      Logger.m.d('[Connectivity] probe failed: $e');
      return false;
    }
  }
}
