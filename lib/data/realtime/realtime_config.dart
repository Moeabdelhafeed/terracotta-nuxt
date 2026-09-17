import '../../core/realtime/realtime.dart';
import '../../core/realtime/realtime_adapters.dart';
import '../../core/realtime/realtime_service.dart';
import '../services/remote_config_service.dart';

/// Realtime equivalent of `BaseApiConstants` in `api_config.dart` —
/// one place to pick the adapter and resolve the connection URL.
///
/// Call from `main.dart` during bootstrap:
/// ```dart
/// Realtime.register(RealtimeConfig.buildAdapter());
/// await Realtime.connect();
/// ```
///
/// Change the adapter selection here (e.g. switch between WebSocket,
/// Pusher, Ably) without touching feature code — call sites talk to
/// the [Realtime] facade and never know which backend is serving them.
class RealtimeConfig {
  const RealtimeConfig._();

  /// URL for the default raw-WebSocket adapter. Pulled from Remote
  /// Config so it can be flipped without a release (dev → staging →
  /// prod). Falls back to a local dev URL when Remote Config hasn't
  /// loaded yet.
  static String get websocketUrl {
    // TODO(template): add a `websocket_url` key to RemoteConfigService
    // alongside `base_url`. Until then we derive from the API base.
    final base = RemoteConfigService.baseUrl;
    // http(s)://api.example.com → ws(s)://api.example.com/ws
    final wsBase = base
        .replaceFirst(RegExp(r'^https'), 'wss')
        .replaceFirst(RegExp(r'^http'), 'ws');
    return '$wsBase/ws';
  }

  /// Build the active realtime adapter. Swap the `return` to switch
  /// backends — everything past this line is backend-agnostic.
  ///
  /// ```dart
  /// // Default — raw WebSocket
  /// return WebSocketRealtimeAdapter(url: websocketUrl);
  ///
  /// // Or Pusher (once you've added pusher_channels_flutter + filled
  /// // in the adapter):
  /// return PusherRealtimeAdapter(
  ///   apiKey: RemoteConfigService.pusherKey,
  ///   cluster: 'eu',
  ///   authEndpoint: '${RemoteConfigService.baseUrl}/broadcasting/auth',
  /// );
  /// ```
  static RealtimeService buildAdapter() {
    return WebSocketRealtimeAdapter(url: websocketUrl);
  }
}
