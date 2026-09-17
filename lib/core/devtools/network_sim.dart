import 'dart:async';

import 'package:dio/dio.dart';

import '../../data/stores/debug_overlay_prefs.dart';

/// Debug interceptor that piggybacks on [DebugOverlayPrefs] to inject
/// artificial latency + periodic failures into Dio. Lets devs test
/// loading / retry / offline UI without a flaky backend.
///
/// Off when both `latencyMs` and `failEveryN` are zero. When the
/// counter ticks past `failEveryN`, the next request is short-circuited
/// with an [DioException] carrying `failStatus` so the app's normal
/// error path runs.
class NetworkSim {
  NetworkSim._();

  static int _counter = 0;

  /// When true, the next forced failure also disarms the simulator
  /// (failEveryN → 0). Lets tools schedule a single failure — e.g. the
  /// auth view's "force next request 401" — without leaving the sim
  /// armed behind the dev's back.
  static bool oneShot = false;

  /// Reset the rolling fail counter. Useful from the UI when the dev
  /// changes the trigger frequency mid-session.
  static void resetCounter() => _counter = 0;
}

/// Construct the simulator interceptor. Sits AFTER auth/retry +
/// network capture so the captured snapshot reflects the simulated
/// outcome.
Interceptor createNetworkSimInterceptor() {
  return InterceptorsWrapper(
    onRequest: (options, handler) async {
      final latency = DebugOverlayPrefs.netSimLatencyMs.value;
      if (latency > 0) {
        await Future<void>.delayed(Duration(milliseconds: latency));
      }
      final failEvery = DebugOverlayPrefs.netSimFailEveryN.value;
      if (failEvery > 0) {
        NetworkSim._counter++;
        if (NetworkSim._counter % failEvery == 0) {
          final status = DebugOverlayPrefs.netSimFailStatus.value;
          if (NetworkSim.oneShot) {
            NetworkSim.oneShot = false;
            DebugOverlayPrefs.setNetSim(failEveryN: 0);
          }
          // 0 / negative = synthesize a connection-timeout error
          // (matches how Dio surfaces real network outages, which is
          // what most dev-time retry tests want to exercise).
          if (status <= 0) {
            handler.reject(
              DioException(
                requestOptions: options,
                type: DioExceptionType.connectionTimeout,
                message: '[NetworkSim] forced timeout',
              ),
            );
            return;
          }
          handler.reject(
            DioException(
              requestOptions: options,
              response: Response<dynamic>(
                requestOptions: options,
                statusCode: status,
                statusMessage: '[NetworkSim] forced $status',
                data: '[NetworkSim] forced $status',
              ),
              type: DioExceptionType.badResponse,
              message: '[NetworkSim] forced $status',
            ),
          );
          return;
        }
      }
      handler.next(options);
    },
  );
}
