import '../../../core/realtime/realtime_service.dart';
import '../../../core/utils/loggers/logger.dart';
import '../../api/api_service.dart';

/// Default [AuthResolver] that matches the Laravel Echo / Pusher
/// convention — `POST /broadcasting/auth` with the channel name,
/// returns `{auth: "<signature>", channel_data?: "..."}`.
///
/// 90% of Flutter apps using private / presence channels hit exactly
/// this endpoint. Pass it straight into
/// [RealtimeService.subscribe] for any channel that needs auth:
///
/// ```dart
/// await Realtime.subscribe('private-orders.42', auth: broadcastingAuth);
/// ```
///
/// For backends that use a different shape (Ably token-request flow,
/// custom signing endpoints, JWTs in headers), write your own
/// [AuthResolver] — this is a default, not a contract.
///
/// ## Endpoint contract (if you're implementing the backend)
/// - **Path**: `POST {baseUrl}/broadcasting/auth`
/// - **Body**: `{"channel_name": "private-orders.42"}`
/// - **Response**: flat map of strings handed verbatim to the
///   underlying adapter. Pusher / Laravel Echo expects `auth` and
///   optionally `channel_data`.
Future<Map<String, String>> broadcastingAuth(String channelName) async {
  final result = await ApiService.call(
    () => ApiService().post<Map<String, dynamic>>(
      '/broadcasting/auth',
      data: {'channel_name': channelName},
      fromJson: (json) => json,
    ),
  );
  return result.when(
    success: (data) => data.map((k, v) => MapEntry(k, v.toString())),
    failure: (error) {
      Logger.m.w(
        '[Realtime] broadcastingAuth failed for "$channelName": ${error.message}',
      );
      // Return empty map — subscription attempts with no auth will
      // fail server-side, which is the right behavior. Throwing here
      // would propagate into the adapter's subscription flow.
      return const <String, String>{};
    },
  );
}
