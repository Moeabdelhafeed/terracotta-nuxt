import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../../core/env/env.dart';
import '../../core/utils/loggers/logger.dart';

/// The four headers the Terracotta API demands on **every single
/// request**. Getting any of them wrong looks like a broken endpoint
/// rather than a missing header, which is why they live in one place
/// instead of at ninety-two call sites.
///
/// | Header | When | Missing → |
/// |---|---|---|
/// | `X-API-TOKEN` | always | **401** |
/// | `X-Device-Id` | always | **422** under `device_id` |
/// | `X-Platform`  | always | **422** under `platform` |
/// | `X-FCM-Token` | iOS/Android only | **422** under `fcm_token` |
///
/// The FCM one is the trap: it is required on `ios` and `android` and
/// *not* on `web`, so a mobile build with push not yet initialised 422s
/// on every call and reads like a server fault. We therefore send the
/// header whenever the platform is mobile, with an empty value if the
/// token has not arrived yet — the server wants the key present, and an
/// empty string is a truthful "this device has no push token".
///
/// `X-Device-Id` must be STABLE per install: guest carts, sessions and
/// push all key off it, and a guest who registers is promoted in place
/// by matching it. A value that changes between launches silently
/// orphans the customer's guest cart.
class TerracottaHeaders {
  const TerracottaHeaders._();

  static const apiToken = 'X-API-TOKEN';
  static const deviceId = 'X-Device-Id';
  static const platform = 'X-Platform';
  static const fcmToken = 'X-FCM-Token';

  /// `web`, `ios` or `android` — anything else is a 422.
  static String currentPlatform() {
    if (kIsWeb) return 'web';
    return switch (defaultTargetPlatform) {
      TargetPlatform.iOS || TargetPlatform.macOS => 'ios',
      TargetPlatform.android => 'android',
      // Windows/Linux have no mobile identity; `web` is the honest
      // answer and the only other value the server accepts.
      _ => 'web',
    };
  }

  static bool isMobile(String platform) =>
      platform == 'ios' || platform == 'android';
}

/// Stamps every outgoing request with the Terracotta headers.
///
/// [resolveDeviceId] and [resolveFcmToken] are injected rather than
/// looked up so this stays testable and so `ApiService` keeps its rule
/// of never reaching into `getIt` from the request path.
Interceptor createTerracottaHeadersInterceptor({
  required String Function() resolveDeviceId,
  required String Function() resolveFcmToken,
  String Function()? resolveApiToken,
}) => InterceptorsWrapper(
  onRequest: (options, handler) {
    final platform = TerracottaHeaders.currentPlatform();
    final token = (resolveApiToken ?? () => Env.apiXToken)();

    options.headers[TerracottaHeaders.apiToken] = token;
    options.headers[TerracottaHeaders.deviceId] = resolveDeviceId();
    options.headers[TerracottaHeaders.platform] = platform;

    if (TerracottaHeaders.isMobile(platform)) {
      options.headers[TerracottaHeaders.fcmToken] = resolveFcmToken();
    }

    if (token.isEmpty || token == 'fallback-token') {
      Logger.a.w(
        '[Terracotta] X-API-TOKEN is unset — every request will 401. '
        'Set API_X_TOKEN in .env.<flavor> and run `make env-sync-<flavor>`.',
      );
    }

    return handler.next(options);
  },
);
