import '../error/app_exception.dart';
import '../types/result.dart';
import 'realtime_service.dart';

/// App-wide realtime facade. Wire up a [RealtimeService] at startup
/// and call the static helpers from anywhere — features stay
/// decoupled from the chosen vendor.
///
/// ```dart
/// // main.dart
/// Realtime.register(WebSocketRealtimeAdapter(url: 'wss://ws.example.com'));
/// await Realtime.connect();
///
/// // anywhere
/// final result = await Realtime.subscribe('orders');
/// result.onSuccess((channel) {
///   channel.on('order_updated').listen((event) => ...);
/// });
/// ```
///
/// Defaults to [NoOpRealtimeService] so calls are safe before
/// [register] runs.
class Realtime {
  Realtime._();

  static RealtimeService _service = NoOpRealtimeService();

  /// Global kill switch. When false, all methods short-circuit to the
  /// no-op service and [isConnected] is always false. Useful during
  /// tests or on consent-denied flows.
  static bool enabled = true;

  /// The active backend. Prefer the static helpers in feature code;
  /// only reach for this when you need adapter-specific APIs (e.g.
  /// `(Realtime.service as PusherRealtimeAdapter).triggerBatch(...)`).
  static RealtimeService get service => _service;

  /// Install [service] as the active backend. Disposes the previous
  /// one first — safe to call multiple times to swap implementations.
  static void register(RealtimeService service) {
    _service.dispose();
    _service = service;
  }

  /// Restore the no-op default. Handy in tests or after logout.
  static void reset() {
    _service.dispose();
    _service = NoOpRealtimeService();
  }

  // ─── Lifecycle ───────────────────────────────────────────────────

  static Future<Result<void, AppException>> connect() {
    if (!enabled) return Future.value(const Success(null));
    return _service.connect();
  }

  static Future<void> disconnect() => _service.disconnect();

  static Stream<ConnectionState> get connectionState =>
      _service.connectionState;

  static ConnectionState get currentState => _service.currentState;

  static bool get isConnected => enabled && _service.isConnected;

  // ─── Channels ────────────────────────────────────────────────────

  /// Subscribe to [name]. Returns a [Channel] handle you listen on.
  static Future<Result<Channel, AppException>> subscribe(
    String name, {
    AuthResolver? auth,
  }) {
    if (!enabled) return Future.value(Success(_DisabledChannel(name)));
    return _service.subscribe(name, auth: auth);
  }

  /// Client-originated publish. See [RealtimeService.publish] for
  /// caveats (not all backends support this).
  static Future<Result<void, AppException>> publish(
    String channel,
    String event,
    Map<String, dynamic> data,
  ) {
    if (!enabled) return Future.value(const Success(null));
    return _service.publish(channel, event, data);
  }
}

/// Returned by [Realtime.subscribe] when the facade is disabled. Same
/// shape as a real channel but produces no events.
class _DisabledChannel extends Channel {
  _DisabledChannel(this.name);

  @override
  final String name;

  @override
  Stream<RealtimeEvent> get events => const Stream.empty();

  @override
  Stream<RealtimeEvent> on(String eventName) => const Stream.empty();

  @override
  Stream<List<PresenceMember>> get presence => const Stream.empty();

  @override
  Future<void> unsubscribe() async {}
}
